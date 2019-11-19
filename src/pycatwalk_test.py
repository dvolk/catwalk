import unittest

import pycatwalk

class test_pycatwalk(unittest.TestCase):
    def test1(self):
        pycatwalk.init(name="test instance",
                       reference_name="test reference",
                       reference_sequence="ACGTACGT",
                       mask_name="test mask",
                       mask_str = "0")

        pycatwalk.add_sample(name="test sample 1", sequence="ACGTACGT")
        pycatwalk.add_sample(name="test sample 2", sequence="ACGTACGC")
        pycatwalk.add_sample(name="test sample 3", sequence="ACGTACGN")
        pycatwalk.add_sample_from_refcomp("test sample 4", """{"A": [], "C": [], "G": [], "T": [], "N": []}""")
        pycatwalk.add_sample_from_refcomp("test sample 5", """{"A": [1], "C": [2], "G": [], "T": [], "N": [3]}""")

        sample1_neighbours = pycatwalk.neighbours("test sample 1")
        expected_sample1_neighbours = [("test sample 2", 1),
                                       ("test sample 3", 0),
                                       ("test sample 4", 0),
                                       ("test sample 5", 2)
                                       ]

        self.assertEqual(sample1_neighbours,
                         expected_sample1_neighbours,
                         "Neighbours for sample1 do not match")


        status = pycatwalk.status()

        cw_n_samples = int(status['n_samples'])
        expected_cw_n_samples = 5

        self.assertEqual(cw_n_samples, expected_cw_n_samples)
