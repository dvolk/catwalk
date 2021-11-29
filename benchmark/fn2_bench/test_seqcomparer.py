#!/usr/bin/env python3

# python code to compare fasta sequences
import unittest
import os
import glob
import hashlib
import collections
import uuid
import json
import psutil
import itertools
import pickle
from seqcomparer import seqComparer

class test_seqComparer_init1(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            persistenceStore="localmemory",
            startAfresh=False,
        )


class test_seqComparer_init2(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            persistenceStore="localmemory",
            startAfresh=True,
        )


class test_seqComparer_init5(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            persistenceStore="tofile",
            startAfresh=False,
        )


class test_seqComparer_init6(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            persistenceStore="tofile",
            startAfresh=True,
        )


class test_seqComparer_1(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )
        self.assertEqual(sc.reference, refSeq)


class test_seqComparer_2(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"

        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )

        with self.assertRaises(TypeError):
            sc.compress(sequence="AC")


class test_seqComparer_3(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )
        retVal = sc.compress(sequence="ACTG")
        self.assertEqual(
            retVal,
            {
                "G": set([]),
                "A": set([]),
                "C": set([]),
                "T": set([]),
                "N": set([]),
                "invalid": 0,
            },
        )


class test_seqComparer_4(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"

        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )

        retVal = sc.compress(sequence="ACTN")
        self.assertEqual(
            retVal,
            {
                "G": set([]),
                "A": set([]),
                "C": set([]),
                "T": set([]),
                "N": set([3]),
                "invalid": 0,
            },
        )


class test_seqComparer_5(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )
        retVal = sc.compress(sequence="ACT-")
        self.assertEqual(
            retVal,
            {
                "G": set([]),
                "A": set([]),
                "C": set([]),
                "T": set([]),
                "N": set([3]),
                "invalid": 0,
            },
        )


class test_seqComparer_6(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"

        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )

        retVal = sc.compress(sequence="TCT-")
        self.assertEqual(
            retVal,
            {
                "G": set([]),
                "A": set([]),
                "C": set([]),
                "T": set([0]),
                "N": set([3]),
                "invalid": 0,
            },
        )


class test_seqComparer_7(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"

        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )
        retVal = sc.compress(sequence="ATT-")
        self.assertEqual(
            retVal,
            {
                "G": set([]),
                "A": set([]),
                "C": set([]),
                "T": set([1]),
                "N": set([3]),
                "invalid": 0,
            },
        )


class test_seqComparer_8(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )

        sc.setComparator1(sequence="ACTG")
        sc.setComparator2(sequence="ACTG")


class test_seqComparer_9(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )
        sc.setComparator1(sequence="ACTG")
        sc.setComparator2(sequence="ACTG")
        self.assertEqual(sc.countDifferences(), 0)


class test_seqComparer_10(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )
        sc.setComparator1(sequence="TTTG")
        sc.setComparator2(sequence="ACTG")
        self.assertEqual(sc.countDifferences(), 2)


class test_seqComparer_11(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )
        sc.setComparator1(sequence="TTTG")
        sc.setComparator2(sequence="NNTG")
        self.assertEqual(sc.countDifferences(), 0)


class test_seqComparer_12(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )

        sc.setComparator2(sequence="TTTG")
        sc.setComparator1(sequence="NNTG")
        self.assertEqual(sc.countDifferences(), 0)


class test_seqComparer_13(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )
        sc.setComparator2(sequence="TTTG")
        sc.setComparator1(sequence="--TG")
        self.assertEqual(sc.countDifferences(), 0)


class test_seqComparer_14(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )
        sc.setComparator2(sequence="TTAA")
        sc.setComparator1(sequence="--AG")
        self.assertEqual(sc.countDifferences(), 1)


class test_seqComparer_15(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )
        sc.setComparator1(sequence="TTAA")
        sc.setComparator2(sequence="--AG")
        self.assertEqual(sc.countDifferences(), 1)


class test_seqComparer_16(unittest.TestCase):
    """tests the comparison of two sequences where both differ from the reference."""

    def runTest(self):
        # generate compressed sequences
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            reference=refSeq,
            startAfresh=True,
            snpCeiling=10,
        )

        sc.seq1 = sc.compress("AAAA")
        sc.seq2 = sc.compress("CCCC")
        self.assertEqual(sc.countDifferences(), 4)


class test_seqComparer_17(unittest.TestCase):
    """tests the comparison of two sequences where one is invalid."""

    def runTest(self):
        # generate compressed sequences
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=2,
            reference=refSeq,
            startAfresh=True,
            snpCeiling=10,
        )

        sc.seq1 = sc.compress("NNNN")  # invalid
        sc.seq2 = sc.compress("ACGT")
        self.assertEqual(sc.countDifferences(), None)


class test_seqComparer_18(unittest.TestCase):
    """tests the comparison of two sequences where one is invalid."""

    def runTest(self):
        # generate compressed sequences
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=2,
            reference=refSeq,
            startAfresh=True,
            snpCeiling=10,
        )

        sc.seq1 = sc.compress("NNNN")  # invalid
        sc.seq2 = sc.compress("NNNN")  # invalid
        self.assertEqual(sc.countDifferences(), None)


class test_seqComparer_24(unittest.TestCase):
    """tests N compression"""

    def runTest(self):

        refSeq = "ACTGTTAATTTTTTTTTGGGGGGGGGGGGAA"
        sc = seqComparer(
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
            NCompressionCutoff=10000,
        )

        retVal = sc.compress(sequence="ACTGTTAANNNNNNNNTGGGGGGGGGGGGAA")
        self.assertEqual(
            retVal,
            {
                "G": set([]),
                "A": set([]),
                "C": set([]),
                "T": set([]),
                "N": set([8, 9, 10, 11, 12, 13, 14, 15]),
                "invalid": 0,
            },
        )
        retVal = sc.compress(sequence="NNTGTTAANNNNNNNNTGGGGGGGGGGGGAA")
        self.assertEqual(
            retVal,
            {
                "G": set([]),
                "A": set([]),
                "C": set([]),
                "T": set([]),
                "N": set([0, 1, 8, 9, 10, 11, 12, 13, 14, 15]),
                "invalid": 0,
            },
        )


class test_seqComparer_23a(unittest.TestCase):
    """tests N compression"""

    def runTest(self):

        refSeq = "ACTGTTAATTTTTTTTTGGGGGGGGGGGGAA"
        sc = seqComparer(
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
            NCompressionCutoff=100000,
        )

        retVal = sc.compress(sequence="ACTGTTAATTTTTTTTTGGGGGGGGGGGGAA")
        self.assertEqual(
            retVal,
            {
                "G": set([]),
                "A": set([]),
                "C": set([]),
                "T": set([]),
                "N": set(),
                "invalid": 0,
            },
        )


class test_seqComparer_25(unittest.TestCase):
    """tests N compression"""

    def runTest(self):

        refSeq = "ACTGTTAATTTTTTTTTGGGGGGGGGGGGAA"
        sc = seqComparer(
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
            NCompressionCutoff=0,
        )

        Ns = [0, 1, 2, 3, 4, 5, 6, 9, 10]

        retVal = list(sc._ranges(Ns))
        self.assertEqual(retVal, [(0, 6), (9, 10)])


class test_seqComparer_26(unittest.TestCase):
    """tests N compression"""

    def runTest(self):

        refSeq = "ACTGTTAATTTTTTTTTGGGGGGGGGGGGAA"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )

        Ns = []

        retVal = list(sc._ranges(Ns))
        self.assertEqual(retVal, [])


class test_seqComparer_27(unittest.TestCase):
    """tests N compression"""

    def runTest(self):

        refSeq = "ACTGTTAATTTTTTTTTGGGGGGGGGGGGAA"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            startAfresh=True,
        )

        Ns = [1]

        retVal = list(sc._ranges(Ns))
        self.assertEqual(retVal, [(1, 1)])


class test_seqComparer_29(unittest.TestCase):
    """tests _setStats"""

    def runTest(self):

        refSeq = "ACTGTTAATTTTTTTTTGGGGGGGGGGGGAA"
        sc = seqComparer(
            maxNs=1e8,
            snpCeiling=20,
            reference=refSeq,
            NCompressionCutoff=0,
            startAfresh=True,
        )
        compressedObj1 = sc.compress(sequence="GGGGTTAANNNNNNNNNGGGGGAAAAGGGAA")
        compressedObj2 = sc.compress(sequence="ACTGTTAATTTTTTTTTNNNNNNNNNNNNNN")
        (n1, n2, nall, rv1, rv2, retVal) = sc._setStats(
            compressedObj1["N"], compressedObj2["N"]
        )
        self.assertEqual(
            retVal,
            set(
                [
                    8,
                    9,
                    10,
                    11,
                    12,
                    13,
                    14,
                    15,
                    16,
                    17,
                    18,
                    19,
                    20,
                    21,
                    22,
                    23,
                    24,
                    25,
                    26,
                    27,
                    28,
                    29,
                    30,
                ]
            ),
        )

        compressedObj1 = sc.compress(sequence="GGGGTTAANNNNNNNNTGGGGGAAAAGGGAA")
        compressedObj2 = sc.compress(sequence="ACTGTTAATTTTTTTTTNNNNNNNNNNNNNN")
        (n1, n2, nall, rv1, rv2, retVal) = sc._setStats(
            compressedObj1["N"], compressedObj2["N"]
        )
        self.assertEqual(
            retVal,
            set(
                [
                    8,
                    9,
                    10,
                    11,
                    12,
                    13,
                    14,
                    15,
                    17,
                    18,
                    19,
                    20,
                    21,
                    22,
                    23,
                    24,
                    25,
                    26,
                    27,
                    28,
                    29,
                    30,
                ]
            ),
        )

        compressedObj1 = sc.compress(sequence="NNNGTTAANNNNNNNNTGGGGGAAAAGGGAA")
        compressedObj2 = sc.compress(sequence="ACTGTTAATTTTTTTTTNNNNNNNNNNNNNN")
        (n1, n2, nall, rv1, rv2, retVal) = sc._setStats(
            compressedObj1["N"], compressedObj2["N"]
        )
        self.assertEqual(
            retVal,
            set(
                [
                    0,
                    1,
                    2,
                    8,
                    9,
                    10,
                    11,
                    12,
                    13,
                    14,
                    15,
                    17,
                    18,
                    19,
                    20,
                    21,
                    22,
                    23,
                    24,
                    25,
                    26,
                    27,
                    28,
                    29,
                    30,
                ]
            ),
        )

        compressedObj1 = sc.compress(sequence="NNNGTTAANNNNNNNNTGGGGGAAAAGGGAA")
        compressedObj2 = sc.compress(sequence="ACTNNNNNTTTTTTTTTNNNNNNNNNNNNNN")
        (n1, n2, nall, rv1, rv2, retVal) = sc._setStats(
            compressedObj1["N"], compressedObj2["N"]
        )
        self.assertEqual(
            retVal,
            set(
                [
                    0,
                    1,
                    2,
                    3,
                    4,
                    5,
                    6,
                    7,
                    8,
                    9,
                    10,
                    11,
                    12,
                    13,
                    14,
                    15,
                    17,
                    18,
                    19,
                    20,
                    21,
                    22,
                    23,
                    24,
                    25,
                    26,
                    27,
                    28,
                    29,
                    30,
                ]
            ),
        )


class test_seqComparer_30(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            reference=refSeq,
            startAfresh=True,
            snpCeiling=1,
        )
        sc.setComparator1(sequence="ACTG")
        sc.setComparator2(sequence="ACTG")


class test_seqComparer_31(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            reference=refSeq,
            startAfresh=True,
            snpCeiling=1,
        )
        sc.setComparator1(sequence="ACTG")
        sc.setComparator2(sequence="ACTG")
        self.assertEqual(sc.countDifferences(), 0)


class test_seqComparer_32(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            reference=refSeq,
            startAfresh=True,
            snpCeiling=1,
        )
        sc.setComparator1(sequence="TTTG")
        sc.setComparator2(sequence="ACTG")
        self.assertEqual(sc.countDifferences(), None)


class test_seqComparer_33(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            reference=refSeq,
            startAfresh=True,
            snpCeiling=1,
        )
        sc.setComparator1(sequence="TTTG")
        sc.setComparator2(sequence="NNTG")
        self.assertEqual(sc.countDifferences(), 0)


class test_seqComparer_34(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            reference=refSeq,
            startAfresh=True,
            snpCeiling=1,
        )
        sc.setComparator2(sequence="TTTG")
        sc.setComparator1(sequence="NNTG")
        self.assertEqual(sc.countDifferences(), 0)


class test_seqComparer_34b(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            reference=refSeq,
            startAfresh=True,
            snpCeiling=1,
        )
        sc.setComparator2(sequence="TTTG")
        sc.setComparator1(sequence="--TG")
        self.assertEqual(sc.countDifferences(), 0)


class test_seqComparer_35(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            reference=refSeq,
            startAfresh=True,
            snpCeiling=1,
        )
        sc.setComparator2(sequence="TTAA")
        sc.setComparator1(sequence="--AG")
        self.assertEqual(sc.countDifferences(), 1)


class test_seqComparer_36(unittest.TestCase):
    def runTest(self):
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            reference=refSeq,
            startAfresh=True,
            snpCeiling=1,
        )
        sc.setComparator1(sequence="TTAA")
        sc.setComparator2(sequence="--AG")
        self.assertEqual(sc.countDifferences(), 1)


class test_seqComparer_37(unittest.TestCase):
    """tests the loading of an exclusion file"""

    def runTest(self):

        # default exclusion file
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            reference=refSeq,
            startAfresh=True,
            snpCeiling=1,
            excludeFile=os.path.join("..", "reference", "TB-exclude-adaptive.txt"),
        )
        self.assertEqual(
            sc.excluded_hash(), "Excl 557291 nt [5a785c944ebb96bb936159330b57f7dd]"
        )


class test_seqComparer_38(unittest.TestCase):
    """tests the loading of an exclusion file"""

    def runTest(self):

        # no exclusion file
        refSeq = "ACTG"
        sc = seqComparer(
            NCompressionCutoff=1e8,
            maxNs=1e8,
            excludeFile=None,
            reference=refSeq,
            startAfresh=True,
            snpCeiling=1,
        )
        self.assertEqual(
            sc.excluded_hash(), "Excl 0 nt [d751713988987e9331980363e24189ce]"
        )
