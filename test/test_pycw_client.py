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
            reference_name="H37RV",
            reference_filepath="reference/TB-ref.fasta",
            mask_filepath="reference/TB-exclude-adaptive.txt",
            max_distance=20,
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
            "A": [100000, 100001, 100002],
            "G": [],
            "T": [],
            "C": [],
            "N": [20000, 20001, 20002],
        }
        payload2 = {
            "A": [100003, 100004, 100005],
            "G": [],
            "T": [],
            "C": [],
            "N": [20000, 20001, 20002],
        }

        # one is 10000 nt different
        payload3 = {
            "A": list(range(110000, 120000)),
            "G": [],
            "T": [],
            "C": [],
            "N": [20000, 20001, 20002],
        }
        res = self.cw.add_sample_from_refcomp("guid1", payload1)
        self.assertEqual(res, 201)

        res = self.cw.add_sample_from_refcomp("guid2", payload2)
        self.assertEqual(res, 201)

        res = self.cw.add_sample_from_refcomp("guid2", payload2)  # insert twice
        self.assertEqual(res, 200)

        res = self.cw.add_sample_from_refcomp("guid3", payload3)  # insert once
        self.assertEqual(res, 201)

        self.assertEqual(self.cw.neighbours("guid1"), [("guid2", 6)])
        self.assertEqual(self.cw.neighbours("guid2"), [("guid1", 6)])
        self.assertEqual(self.cw.neighbours("guid3"), [])  # should be empty

        self.assertEqual(
            self.cw.neighbours("guid1", distance=7), [("guid2", 6)]
        )  # should be guid2
        self.assertEqual(
            self.cw.neighbours("guid1", distance=6), [("guid2", 6)]
        )  # should be guid2
        self.assertEqual(self.cw.neighbours("guid1", distance=5), [])  # should be empty

        with self.assertRaises(requests.exceptions.HTTPError):
            res = self.cw.neighbours("guid4")  # should raise 404


class test_cw_3(test_cw):
    """tests list_samples"""

    def runTest(self):

        payload1 = {
            "A": [1000, 1001, 1002],
            "G": [],
            "T": [],
            "C": [],
            "N": [20000, 20001, 20002],
        }
        payload2 = {
            "A": [1003, 1004, 1005],
            "G": [],
            "T": [],
            "C": [],
            "N": [20000, 20001, 20002],
        }
        self.cw.add_sample_from_refcomp("guid1", payload1)
        self.cw.add_sample_from_refcomp("guid2", payload2)

        self.assertEqual(
            set(self.cw.sample_names()), set(["guid1", "guid2"])
        )  # order doesn't matter


class test_cw_4(test_cw):
    """tests remove_sample"""

    def runTest(self):

        payload1 = {
            "A": [1000, 1001, 1002],
            "G": [],
            "T": [],
            "C": [],
            "N": [20000, 20001, 20002],
        }
        payload2 = {
            "A": [1003, 1004, 1005],
            "G": [],
            "T": [],
            "C": [],
            "N": [20000, 20001, 20002],
        }
        self.cw.add_sample_from_refcomp("guid1", payload1)
        self.cw.add_sample_from_refcomp("guid2", payload2)

        self.assertEqual(
            set(self.cw.sample_names()), set(["guid1", "guid2"])
        )  # order doesn't matter

        self.cw.remove_sample("guid1")

        self.assertEqual(
            set(self.cw.sample_names()), set(["guid2"])
        )  # order doesn't matter

        self.cw.remove_sample("guid2")

        self.assertEqual(set(self.cw.sample_names()), set([]))  # order doesn't matter

        # add guid2 again
        self.cw.add_sample_from_refcomp("guid2", payload2)
        self.assertEqual(set(self.cw.sample_names()), set(['guid2']))  # order doesn't matter

