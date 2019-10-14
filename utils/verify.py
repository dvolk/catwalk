import unittest
import argh

def load_fasta(fasta_filecontent):
    seq = ""
    header = None
    lines = fasta_filecontent.splitlines()
    for i, line in enumerate(lines):
        if i == 0:
            header = line
        else:
            seq = seq + line
    return seq

def load_mask(mask_filecontent):
    lines = mask_filecontent.splitlines()
    mask = set()
    for line in lines:
        try:
            mask.add(int(line))
        except ValueError:
            print(f"couldn't convert '{line}' to int")
    return mask

def compare(ref, mask, sam1, sam2):
    changes_raw = 0
    changes_after_ref_ns = 0
    changes_after_ref_mask = 0
    changes_after_pair_ns = 0

    for i, _ in enumerate(ref):
        if sam1[i] != sam2[i]:
            changes_raw = changes_raw + 1

            if ref[i] in 'ACGT':
                changes_after_ref_ns = changes_after_ref_ns + 1

                if i not in mask:
                    changes_after_ref_mask = changes_after_ref_mask + 1

                    if sam1[i] in 'ACGT' and sam2[i] in 'ACGT':
                        changes_after_pair_ns = changes_after_pair_ns + 1

    return changes_raw, changes_after_ref_ns, changes_after_ref_mask, changes_after_pair_ns

def main(ref_filepath, mask_filepath, sample1_filepath, sample2_filepath):
    ref = load_fasta(open(ref_filepath).read())
    sam1 = load_fasta(open(sample1_filepath).read())
    sam2 = load_fasta(open(sample2_filepath).read())
    mask = load_mask(open(mask_filepath).read())

    assert(len(ref) == len(sam1))
    assert(len(ref) == len(sam2))

    changes_raw, changes_after_ref_ns, changes_after_ref_mask, changes_after_pair_ns = compare(ref, mask, sam1, sam2)

    print(f"changes raw: {changes_raw}")
    print(f"changes after ref ns: {changes_after_ref_ns}")
    print(f"changes after ref mask: {changes_after_ref_mask}")
    print(f"changes after pair ns: {changes_after_pair_ns}")


if __name__ == "__main__":
    argh.dispatch_command(main)


class TestVerify(unittest.TestCase):
    def test_load_fasta(self):
        fasta = ">header\nACGT\nTGCA"
        expected = "ACGTTGCA"
        actual = load_fasta(fasta)
        self.assertEqual(actual, expected)

    def test_load_mask(self):
        mask = "\n123\n234\n345\n"
        expected = {123, 234, 345}
        actual = load_mask(mask)
        self.assertEqual(actual, expected)

    def test_compare1(self):
        mask = [0]
        ref  = "ACGTTGCA"
        sam1 = "ACGTCGCA"
        sam2 = "CCGTTGCA"
        c1, c2, c3, c4 = compare(ref, mask, sam1, sam2)
        self.assertEqual(c1, 2)
        self.assertEqual(c2, 2)
        self.assertEqual(c3, 1)
        self.assertEqual(c4, 1)

    def test_compare2(self):
        mask = [0]
        ref  = "ACGTTGCA"
        sam1 = "ACGTCGCA"
        sam2 = "NCGTNGCA"
        c1, c2, c3, c4 = compare(ref, mask, sam1, sam2)
        self.assertEqual(c1, 2)
        self.assertEqual(c2, 2)
        self.assertEqual(c3, 1)
        self.assertEqual(c4, 0)

    def test_compare3(self):
        mask = [0]
        ref =  "ACGTTGCA"
        sam1 = "NCGTCGCA"
        sam2 = "NCGTNGCA"
        c1, c2, c3, c4 = compare(ref, mask, sam1, sam2)
        self.assertEqual(c1, 1)
        self.assertEqual(c2, 1)
        self.assertEqual(c3, 1)
        self.assertEqual(c4, 0)
