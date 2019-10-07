import unittest

from catwalk import *

class TestSample(unittest.TestCase):
    def test_from_fasta(self):
        contents = ">header\nACGT\nTGAC\nAT\n"
        expected_header = "header"
        expected_sequence = "ACGTTGACAT"
        s = Sample()
        s.from_fasta(contents)
        self.assertEqual(s.name, expected_header)
        self.assertEqual(s.sequence, expected_sequence)

    def test_reference_compress(self):
        reference = Sample()
        reference.from_fasta(">seqb\nACGT")
        s1 = Sample()
        s1.from_fasta(">seqb\nATGT")
        expected_diff_sets = { '-': set(), 'A': set(), 'C': set(), 'G': set(), 'T': { 1 }, 'N': set() }
        s1.reference_compress(reference)
        self.assertEqual(s1.diff_sets, expected_diff_sets)

class TestCatWalk(unittest.TestCase):
    def test_add_sample(self):
        reference_sample = Sample().from_fasta(">seqb\nACGT")
        c = CatWalk("test", reference_sample)
        s = Sample().from_fasta(">seqc\nATGT")
        c.add_sample(s)
        expected_diff_sets = { '-': set(), 'A': set(), 'C': set(), 'G': set(), 'T': { 1 }, 'N': set() }
        self.assertEqual(c.samples["seqc"].diff_sets, expected_diff_sets)

    def test_diff_samples(self):
        reference_sample = Sample().from_fasta(">seqb\nACGT")
        c = CatWalk("test", reference_sample)

        c.add_samples([Sample().from_fasta(">seq1\nATGT"),
                       Sample().from_fasta(">seq2\nACGT"),
                       Sample().from_fasta(">seq3\nATGT"),
                       Sample().from_fasta(">seq4\nCGTA"),
        ])

        expected = set()
        actual = c.diff_samples('seq1', 'seq3')
        self.assertEqual(expected, actual)
        expected = { 1 }
        actual = c.diff_samples('seq1', 'seq2')
        self.assertEqual(expected, actual)
        expected = { 0, 1, 2, 3 }
        actual = c.diff_samples('seq2', 'seq4')
        self.assertEqual(expected, actual)

if __name__ == "__main__":
    unittest.main()
