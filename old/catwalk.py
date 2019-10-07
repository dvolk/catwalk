import sys
import glob
import argh
import profile
from BitVector import BitVector
from intset import IntSet

def make_acgtn_set_bv(l):
    return { 'A': BitVector(size=l),
             'C': BitVector(size=l),
             'G': BitVector(size=l),
             'T': BitVector(size=l),
             'N': BitVector(size=l),
             '-': BitVector(size=l),
    }

def make_acgtn_set(l):
    return { 'A': set(),
             'C': set(),
             'G': set(),
             'T': set(),
             'N': set(),
             '-': set(),
    }

class BVSample:
    def __init__(self):
        self.name = None
        self.sequence = None
        self.diff_sets = None
        self.sequence_len = None

    def from_fasta(self, contents):
        xs = [x.strip() for x in contents.split('\n')]
        self.name = xs[0][1:]
        self.sequence = ''.join(xs[1:])
        return self

    def reference_compress(self, reference_sample):
        self.diff_sets = make_acgtn_set_bv(len(reference_sample.sequence))
        for i, (sample_base, reference_base) in enumerate(zip(self.sequence, reference_sample.sequence)):
            #if sample_base != reference_base and sample_base not in ['N', '-'] and reference_base not in ['N','-']:
            self.diff_sets[sample_base][i] = 1
        self.sequence_len = len(self.sequence)
        self.sequence = None

    def diff_sample(self, sample2):
        diff = BitVector(size = self.sequence_len)
        for k in self.diff_sets.keys():
            diff = diff | (self.diff_sets[k] ^ sample2.diff_sets[k])
        return diff

class FNSample:
    def __init__(self):
        self.name = None
        self.sequence = None
        self.diff_sets = None

    def from_fasta(self, contents):
        xs = [x.strip() for x in contents.split('\n')]
        self.name = xs[0][1:]
        self.sequence = ''.join(xs[1:])
        return self

    def reference_compress(self, reference_sample):
        self.diff_sets = make_acgtn_set(len(reference_sample.sequence))
        for i, (sample_base, reference_base) in enumerate(zip(self.sequence, reference_sample.sequence)):
            if sample_base != reference_base and sample_base not in ['N', '-'] and reference_base not in ['N','-']:
                self.diff_sets[sample_base].add(i)
        self.sequence = None

    def diff_sample(self, sample2):
        diff = IntS
        for k in list(self.diff_sets.keys()):
            diff = diff | (self.diff_sets[k] ^ sample2.diff_sets[k])
        return diff

class CatWalk:
    def __init__(self, instance_name, instance_reference):
        self.instance_name = instance_name
        self.instance_reference = instance_reference
        self.samples = dict() # dict of Samples

    def add_sample(self, sample):
        if not sample.diff_sets:
            sample.reference_compress(self.instance_reference)
        self.samples[sample.name] = sample

    def add_samples(self, samples):
        for sample in samples:
            self.add_sample(sample)

    def diff_sample(self, sample1_name, sample2_name):
        sample1 = self.samples[sample1_name]
        sample2 = self.samples[sample2_name]
        return sample1.diff_sample(sample2)

    def snp_distance(self, sample1_name, sample2_name):
        return len(self.diff_sample(sample1_name, sample2_name))

def print_matrix(reference_fasta, fastas):
    with open(reference_fasta) as f:
        reference = IntSetSample().from_fasta(f.read())

    c = CatWalk('test', reference)

    for file in glob.glob(fastas)[:10]:
        with open(file) as f:
            sample = IntSetSample().from_fasta(f.read())
        c.add_sample(sample)
        print(f"...")

    matrix = list()
    for kA in c.samples:
        row = list()
        for kB in c.samples:
            sys.stdout.write(str(c.snp_distance(kA, kB)) + '\t')
        matrix.append(row)
        print('\n')

if __name__ == "__main__":
    #profile.run('print_matrix("references/NC_000962.3.fasta", "fastas/*")')
    argh.dispatch_command(print_matrix)
