""" runs unittest for pycw_client

A component of the findNeighbour4 system for bacterial relatedness monitoring
Copyright (C) 2021 David Wyllie david.wyllie@phe.gov.uk
repo: https://github.com/davidhwyllie/findNeighbour4

This program is free software: you can redistribute it and/or modify
it under the terms of the MIT License as published
by the Free Software Foundation.  See <https://opensource.org/licenses/MIT>, and the LICENSE file.



"""

import unittest
import glob
import json
from pyclient.pycw_client import CatWalk

# unit tests
class test_cw(unittest.TestCase):
    """starts server, and shuts it down"""

    def setUp(self):
        """cw_binary_filepath must point to the catwalk server and mask & reference files to the relevant data files.
        Shuts down **any catwalk server** running initially.

        Note: requires CW_BINARY_FILEPATH environment variable to point to the catwalk binary.
        """
        self.cw = CatWalk(
            cw_binary_filepath=None,
            reference_name="test",
            reference_filepath="reference/TB-ref.fasta",
            mask_filepath="reference/nil.txt",
            max_n_positions=1e5,
            bind_host="localhost",
            bind_port=5999,
        )

        # stop the server if it is running
        self.cw.stop()
        self.assertEqual(len(self.cw._running_servers()), 0)
        
        self.assertFalse(self.cw.server_is_running())

        self.cw.start()
        self.assertEqual(len(self.cw._running_servers()), 1)
        self.assertTrue(self.cw.server_is_running())

    def teardown(self):
        self.cw.stop()
        self.assertEqual(len(self.cw._running_servers()), 0)
        pass


class test_cw_1(test_cw):
    """tests server startup, shutdown, info(), and the server_is_running method.
    Shuts down **any catwalk server** running initially"""

    def runTest(self):

        self.cw.start()
               
        self.assertTrue(self.cw.server_is_running())

        self.assertIsInstance(self.cw.info(), dict)

        self.cw.stop()
        self.assertFalse(self.cw.server_is_running())


class test_cw_2(test_cw):
    """tests insert"""

    def runTest(self):
        # two sequences are similar to each other
        payload1 = {
            "A": [],
            "G": [],
            "T": [0,1,2,3,4,5],
            "C": [],
            "N": [],
        }
        payload2 = {
            "A": [],
            "G": [],
            "T": [0,1,2,3,4,5],
            "C": [],
            "N": [],
        }
        res = self.cw.add_sample_from_refcomp("guid1", payload1)
        self.assertEqual(res, 201)

        res = self.cw.add_sample_from_refcomp("guid2", payload2)
        self.assertEqual(res, 201)

        self.assertEqual(self.cw.neighbours("guid1",20), [("guid2", 0)])

class test_cw_3(test_cw):
    """tests insert"""

    def runTest(self):
        # two sequences are similar to each other
        payload1 = {
            "A": [],
            "G": [],
            "T": [0,1,2,3,4,5],
            "C": [],
            "N": [],
        }
        payload2 = {
            "A": [],
            "G": [],
            "T": [0,1,2,3,4,5,6],
            "C": [],
            "N": [],
        }
        res = self.cw.add_sample_from_refcomp("guid1", payload1)
        self.assertEqual(res, 201)

        res = self.cw.add_sample_from_refcomp("guid2", payload2)
        self.assertEqual(res, 201)

        self.assertEqual(self.cw.neighbours("guid1"), [("guid2", 1)])


class test_cw_5(test_cw):
    """tests insert"""

    def runTest(self):
        # two sequences are similar to each other
        payload1 = {
            "A": [],
            "G": [],
            "T": [],
            "C": [],
            "N": list(range(1000)),
        }
      
        res = self.cw.add_sample_from_refcomp("guid1", payload1)
        self.assertEqual(res, 201)

        res = self.cw.neighbours('guid1',20)
        self.assertEqual(res, [])


class test_cw_6(test_cw):
    """tests insert and comparison with high Ns"""

    def runTest(self):
        # three sequences are similar to each other
        # one has 110,000 Ns, which is more than max_n_storage
        # one has 90,000 Ns
        # one has no Ns
        # all are 0 snp from each other
        payload1 = {
            "A": [],
            "G": [],
            "T": [],
            "C": [],
            "N": list(range(110000))
        }       # we expect this not to be analysed
      
        res = self.cw.add_sample_from_refcomp("guid1", payload1)
        self.assertEqual(res, 201)

        payload2 = {
            "A": [],
            "G": [],
            "T": [],
            "C": [],
            "N": list(range(90000))
        }
      
        res = self.cw.add_sample_from_refcomp("guid2", payload2)
        self.assertEqual(res, 201)

        payload3 = {
            "A": [],
            "G": [],
            "T": [],
            "C": [],
            "N": list(range(0))
        }
      
        res = self.cw.add_sample_from_refcomp("guid3", payload3)
        self.assertEqual(res, 201)

        res = self.cw.sample_names()
        self.assertEqual(set(res), set(['guid1','guid2','guid3']))      

        res = self.cw.neighbours('guid1', 20)
        self.assertEqual(res, [])
        res = self.cw.neighbours('guid2', 20)
        self.assertEqual(res, [('guid3',0)])
