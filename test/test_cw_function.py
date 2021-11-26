""" runs unittest for pycw_client

A component of the findNeighbour4 system for bacterial relatedness monitoring
Copyright (C) 2021 David Wyllie david.wyllie@phe.gov.uk
repo: https://github.com/davidhwyllie/findNeighbour4

This program is free software: you can redistribute it and/or modify
it under the terms of the MIT License as published
by the Free Software Foundation.  See <https://opensource.org/licenses/MIT>, and the LICENSE file.



"""

import unittest
import requests
from client.pycw_client import CatWalk

# unit tests
class test_cw(unittest.TestCase):
    """starts server, and shuts it down"""

    def setUp(self):
        """cw_binary_filepath must point to the catwalk server and mask & reference files to the relevant data files.
        Shuts down **any catwalk server** running initially.

        Note: requires CW_BINARY_FILEPATH environment variable to point to the catwalk binary."""
        self.cw = CatWalk(
            cw_binary_filepath=None,
            reference_name="test",
            reference_filepath="reference/testref.fasta",
            mask_filepath="reference/nil.txt",
            max_n_positions=130000,
            bind_host="localhost",
            bind_port=5999,
        )

        # stop the server if it is running
        self.cw.stop()
        self.assertFalse(self.cw.server_is_running())

        self.cw.start()
        self.assertTrue(self.cw.server_is_running())

    def teardown(self):
        self.cw.stop()
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

        self.assertEqual(self.cw.neighbours("guid1"), [("guid2", 0)])

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
