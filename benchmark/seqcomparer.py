#!/usr/bin/env python3

# python code to compare fasta sequences
import os
import glob
import hashlib
import collections
import uuid
import json
import psutil
import itertools
import pickle


class seqComparer:
    def __init__(
        self,
        reference,
        NCompressionCutoff,
        maxNs,
        snpCeiling,
        persistenceDir=None,
        persistenceStore=["localmemory"],
        startAfresh=False,
        debugMode=False,
        excludeFile=None,
    ):

        """instantiates the sequence comparer.

        reference is a string consisting of the reference sequence.
        This is required because, as a data compression technique,
        only differences from the reference are stored.

        persistenceStore is one or more of
            'localmemory' (stores on disc as backup, and in local memory);
            'tofile' - to the persistenceDir;

        persistenceDir is a directory into which the parsed sequences will be written; required if persistenceStore is either 'localmemory' or 'tofile'.
        startAfresh=True causes the persistence store to be emptied, which is useful for benchmarking.

        excludeFile contains a list of bases which should not be considered at all in the sequence comparisons.  Any bases which are always N should be added to this list.
        Not doing so will substantially degrade the algorithm's performance.

        If debugMode==True, the server will only load 500 samples.


        If the number of Ns are more than maxNs, no data from the sequence is stored.
        If the number of Ns exceeds nCompressionCutoff, Ns are stored not as single base positions but as ranges.  This markedly reduces memory
        usage if the Ns are in long blocks, but slows the comparison rate from about 5,000 per second to about 150/second.

        Results > snpCeiling are not returned or stored.

        David Wyllie, University of Oxford, Jan 2017

        - to run unit tests, do
        python -m unittest seqComparer
        """
        # store snpCeiling.
        self.snpCeiling = snpCeiling

        # check the nature of persistence store; if it is a single item, store that as a list.
        if type(persistenceStore) is str:
            persistenceStore = [persistenceStore]  # make it a list
        self.persistenceStore = persistenceStore  # what is used to store sequences

        # sequences with more than maxNs Ns will be considered invalid and their details (apart from their invalidity) will not be stored.
        self.maxNs = maxNs

        self.NCompressionCutoff = NCompressionCutoff

        # check composition of the reference.
        self.reference = str(reference)  # if passed a Bio.Seq object, coerce to string.
        letters = collections.Counter(self.reference)
        if len(set(letters.keys()) - set(["A", "C", "G", "T"]) ) > 0:
            raise TypeError(
                "Reference sequence supplied contains characters other than ACTG: {0}".format(
                    letters
                )
            )

        ## verify that the storage systems stated are ready for use.
        # check the existence of the persistenceDir and make it if it does not exist.
        self.persistenceDir = persistenceDir
        if "localmemory" in self.persistenceStore or "tofile" in self.persistenceStore:
            if persistenceDir is not None:
                self.persistenceDir = os.path.join(persistenceDir)
                if not os.path.exists(self.persistenceDir):
                    os.makedirs(self.persistenceDir)

        # load the excluded bases
        self.excluded = set()
        if excludeFile is not None:
            with open(excludeFile, "rt") as f:
                rows = f.readlines()
            for row in rows:
                self.excluded.add(int(row))
            print("Excluded {0} positions.".format(len(self.excluded)))

        # define what is included
        self.included = set(range(len(self.reference))) - self.excluded

        # initialise pairwise sequences for comparison.
        self._refresh()

        # empty out stores if appropriate (e.g. for benchmarking)
        for this_persistenceStore in self.persistenceStore:
            if startAfresh is True:
                if this_persistenceStore == "localmemory":
                    self.seqProfile = {}
                    self.emptyPersistenceDir()
                elif this_persistenceStore == "tofile":
                    self.emptyPersistenceDir()
                else:
                    raise TypeError(
                        "Do not know how to use {0} as a persistence mechanism.".format(
                            this_persistenceStore
                        )
                    )

        # load the signatures into memory if directed to do so.
        self.seqProfile = {}
        if "localmemory" in self.persistenceStore:
            if self.persistenceDir is not None:
                print("Loading profiles of existing samples")
                for (i, filepath) in enumerate(
                    glob.glob(os.path.join(self.persistenceDir, "*.pickle"))
                ):  # DirProfile if just profiles
                    guid = os.path.basename(filepath)

                    if i % 500 == 0:
                        print("Starting up; Loaded {0}; please wait".format(i))

                    if debugMode is True and i > 500:
                        break
                    with open(filepath, "rb") as f:
                        # remove the .pickle suffix
                        guid = os.path.basename(filepath).replace(".pickle", "")
                        self.seqProfile[guid] = pickle.load(f)

        # initiate object used to track memory
        self.memtracker = psutil.Process(os.getpid())

    def _refresh(self):
        self.seq1 = None
        self.seq2 = None
        self.seq1md5 = None
        self.seq2md5 = None

    def emptyPersistenceDir(self):
        """deletes all *.pickle files in the persistence directory"""
        if self.persistenceDir is not None:
            i = 0
            for (i, pickleFile) in enumerate(
                glob.glob(os.path.join(self.persistenceDir, "*.pickle"))
            ):
                os.unlink(pickleFile)
            print("Emptied persistence directory, removing {0} files.".format(i))

    def iscachedinram(self, guid):
        """returns true or false depending whether we have a local copy of the refCompressed representation of a sequence (name=guid) in this machine"""
        if guid in self.seqProfile.keys():
            return True
        else:
            return False

    def guidscachedinram(self):
        """returns all guids with sequence profiles currently in this machine"""
        retVal = set()
        for item in self.seqProfile.keys():
            retVal.add(item)
        return retVal

    def iscachedtofile(self, guid):
        """returns true or false depending whether we have a compressed copy on disc (name=guid) in this machine"""
        expectedFilename = os.path.join(self.persistenceDir, "{0}.pickle".format(guid))
        return os.path.exists(expectedFilename)

    def guidscachedtofile(self):
        """returns all guids with sequence profiles currently in this machine"""
        guids = set()
        cachedfiles = glob.glob(os.path.join(self.persistenceDir, "*.pickle"))
        for cachedfile in cachedfiles:
            guid = os.path.basename(cachedfile).replace(".pickle", "")
            guids.add(guid)

        return guids

    def _guid(self):
        """returns a guid"""
        return str(uuid.uuid1())

    def memoryInfo(self):
        """returns information about memory usage by the machine"""
        return self.memtracker.memory_info()

    def _delta(self, x):
        """returns the difference between two numbers in a tuple x"""
        return x[1] - x[0]

    def _ranges(self, i):
        """converts a set or list of integers, i,  into a list of tuples defining the start and stop positions
        of continuous blocks of integers.

        e.g. [0,1,2,3,4,6,7]  --> [(0,4),(6,7)]

        This is derived from the approach here:
        http://stackoverflow.com/questions/4628333/converting-a-list-of-integers-into-range-in-python

        """
        i = sorted(i)
        tups = [t for t in enumerate(i)]

        for a, b in itertools.groupby(tups, self._delta):
            b = list(b)
            yield (b[0][1], b[-1][1])

    def excluded_hash(self):
        """returns a string containing the number of nt excluded, and a hash of their positions.
        This is useful for version tracking"""
        el = sorted(list(self.excluded))
        len_l = len(el)
        h = hashlib.md5()
        h.update(json.dumps(el).encode("utf-8"))
        md5_l = h.hexdigest()
        return "Excl {0} nt [{1}]".format(len_l, md5_l)

    def compress(self, sequence):
        """reads a string sequence and extracts position - genome information from it.
        returns a dictionary consisting of zero-indexed positions of non-reference bases."""
        if not len(sequence) == len(self.reference):
            raise TypeError("sequence must of the same length as reference")

        # we consider - characters to be the same as N
        sequence = sequence.replace("-", "N")

        # we only record differences relative to to refSeq.
        # anything the same as the refSeq is not recorded.
        diffDict = {
            "A": set([]),
            "C": set([]),
            "T": set([]),
            "G": set([]),
            "N": set([]),
        }

        for i in self.included:  # for the bases we need to compress
            if not sequence[i] == self.reference[i]:
                diffDict[sequence[i]].add(i)

        if len(diffDict["N"]) > self.maxNs:
            # we store it, but not with sequence details if is invalid
            diffDict = {"invalid": 1}
        else:
            diffDict["invalid"] = 0

        return diffDict

    def persist(self, refCompressedSequence, method, guid=None, **kwargs):
        """persists the refCompressedSequence to the location chosen, as stated in 'method'.
        Method is ignored.  Only option implemented is  'localmemory'"""
        ## check that sequence is indeed a dictionary

        if refCompressedSequence is None:
            raise TypeError("refCompressed sequence cannot be None")
        if not type(refCompressedSequence) == dict:
            raise TypeError(
                ".persist method needs to be passed a dictionary as generated by .compress() method."
            )

        if type(method) == str:
            # then we convert to a list;
            method = [method]

        if guid is None:
            # assign
            guid = self._guid()

        self.seqProfile[guid] = refCompressedSequence
               
        return guid

    def load_fromfile(self, guid):
        """loads a picked object from file"""
        if self.persistenceDir is not None:
            filepath = os.path.join(self.persistenceDir, "{0}.pickle".format(guid))
            with open(filepath, "rb") as f:
                return pickle.load(
                    f
                )  # will raise an error if it does not exist; could trap, but what would we raise?
        else:
            raise TypeError("Cannot recovery from file when presistenceDir is not set")

    def load(self, guid, method="localmemory"):
        """recovers the full reference- compressed object denoted by the guid on the sequence"""
        if method == "tofile":
            return self.load_fromfile(guid)
        elif method == "localmemory":
            return self.seqProfile[guid]

    def setComparator1(self, sequence):
        self.seq1 = self.compress(sequence)

    def setComparator2(self, sequence):
        self.seq2 = self.compress(sequence)

    def _setStats(self, sortedset1, sortedset2):
        """compares sortedset1, which contains a series of ranges {(0,1) (10,11)}
        with         sortedset2, which also contains  ranges       {(1,2)}

        returns *
        * the number of elements in sortedset1  4
        * the number of elements in sortedset2  2
        * the number of elements in the union of sortedset1 and sortedset2 5
        * sortedSet1 {0,1}
        * sortedSet2 {10,11}
        * the union of sorted set1 and sortedset2   {0,1,2,10,11)}

        """

        if type(sortedset1) == set and type(sortedset2) == set:
            # then we can just use a standard set union operation.
            retVal = sortedset1 | sortedset2
            return (
                len(sortedset1),
                len(sortedset2),
                len(retVal),
                sortedset1,
                sortedset2,
                retVal,
            )

        raise TypeError("was not passed two sets")

    def countDifferences_byKey(self, keyPair, cutoff=None):
        """compares the in memory refCompressed sequences at
        self.seqProfile[key1] and self.seqProfile[key2]
        uses Algorithm 'one', below.
        Returns the number of SNPs between self.seq1 and self.seq2, and, if it is less than cutoff,
        the number of Ns in the two sequences and the union of their positions.
        Typical computational time is less than 0.5 msec."""

        if not type(keyPair) is tuple:
            raise TypeError(
                "Wanted tuple keyPair, but got keyPair={0} with type {1}".format(
                    keyPair, type(keyPair)
                )
            )
        if not len(keyPair) == 2:
            raise TypeError(
                "Wanted a keyPair with two elements, but got {0}".format(keyPair)
            )

        ## test the keys exist
        (key1, key2) = keyPair
        if key1 not in self.seqProfile.keys():
            raise KeyError(
                "Key1={0} does not exist in the in-memory store.".format(key1)
            )
        if key2 not in self.seqProfile.keys():
            raise KeyError(
                "Key1={0} does not exist in the in-memory store.".format(key1)
            )

        # if cutoff is not specified, we use snpCeiling
        if cutoff is None:
            cutoff = self.snpCeiling

        ## do the computation
        # if either sequence is considered invalid (e.g. high Ns) then we report no neighbours.
        self.seq1 = self.seqProfile[key1]
        self.seq2 = self.seqProfile[key2]
        nDiff = self.countDifferences(cutoff=cutoff)

        if nDiff is None:
            return (key1, key2, nDiff, None, None, None, None, None, None)
        elif nDiff <= cutoff:
            (n1, n2, nboth, N1pos, N2pos, Nbothpos) = self._setStats(
                self.seq1["N"], self.seq2["N"]
            )
            return (key1, key2, nDiff, n1, n2, nboth, N1pos, N2pos, Nbothpos)
        else:
            return (key1, key2, nDiff, None, None, None, None, None, None)

    def getDifferences(self, cutoff=None):
        """returns the positions of difference between self.seq1 and self.seq2.
        these are set with self.setComparator1 and 2 respectively.
        Returns a set containing the positions of SNPs between self.seq1 and self.seq2.

        If there are no differences, will return an empty set.
        If either sequence is invalid, will return None."""

        # if either sequence is invalid, return None
        if self.seq1["invalid"] + self.seq2["invalid"] > 0:
            return None

        # compute positions which differ;
        differing_positions = set()
        for nucleotide in ["C", "G", "A", "T"]:

            # we do not consider differences relative to the reference if the other nucleotide is an N
            nonN_seq1 = self.seq1[nucleotide] - self.seq2["N"]
            nonN_seq2 = self.seq2[nucleotide] - self.seq1["N"]
            differing_positions = differing_positions | (nonN_seq1 ^ nonN_seq2)
        return differing_positions

    def countDifferences(self, cutoff=None):
        """compares self.seq1 with self.seq2;
        these are set with self.setComparator1 and 2 respectively.
        Returns the number of SNPs between self.seq1 and self.seq2.

        rate about 10,000+ per second depending on hardware."""
        # if cutoff is not specified, we use snpCeiling
        if cutoff is None:
            cutoff = self.snpCeiling

        # compute positions which differ;
        differing_positions = self.getDifferences()

        if differing_positions is None:  # one or other calculation is invalid
            return None
        else:
            nDiff = len(differing_positions)

            if nDiff > cutoff:
                return None
            else:
                return nDiff

