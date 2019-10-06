import sys
import glob
import argh
import profile

def make_acgtn_set():
    return { 'A': set(), 'C': set(), 'G': set(), 'T': set(), '-': set(), 'N': set() }

class Sample:
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
        self.diff_sets = make_acgtn_set()
        for i, (sample_base, reference_base) in enumerate(zip(self.sequence, reference_sample.sequence)):
            if sample_base != reference_base and sample_base not in ['N', '-'] and reference_base not in ['N','-']:
                self.diff_sets[sample_base].add(i)
        self.sequence = None

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

    def diff_samples(self, sample1_name, sample2_name):
        sample1 = self.samples[sample1_name]
        sample2 = self.samples[sample2_name]
        diff = set()
        for k in list(sample1.diff_sets.keys()):
            diff = diff.union(sample1.diff_sets[k].symmetric_difference(sample2.diff_sets[k]))
        return diff

    def snp_distance(self, sample1_name, sample2_name):
        return len(self.diff_samples(sample1_name, sample2_name))

def print_matrix(reference_fasta, fastas):
    with open(reference_fasta) as f:
        reference = Sample().from_fasta(f.read())

    c = CatWalk('test', reference)

    for file in glob.glob(fastas):
        with open(file) as f:
            sample = Sample().from_fasta(f.read())
        c.add_sample(sample)
        print(f"loaded {sample.name}")

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
