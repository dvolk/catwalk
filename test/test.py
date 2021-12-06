"""Tests some catwalk features.

NB this assumes there's no catwalk running on the system. It will
kill all cw_server processes at the end
"""

import os
import time
import requests
import argh


def start_test_catwalk():
    os.system("echo -n '>test\nACGTACGT' > test.ref")
    os.system("touch test.mask")
    os.system(
        "../cw_server --instance_name=test --reference_filepath=test.ref --mask-filepath=test.mask &"
    )
    time.sleep(1)


def stop_test_catwalk():
    os.system("pkill cw_server")


def add_sample_to_catwalk(sample_name, sample_sequence):
    return requests.post(
        "http://localhost:5000/add_sample",
        json={"name": sample_name, "sequence": sample_sequence, "keep": True},
    )


def remove_sample_from_catwalk(sample_name):
    return requests.get(f"http://localhost:5000/remove_sample/{sample_name}")


def get_neighbours(sample_name, snp_distance):
    return requests.get(
        f"http://localhost:5000/neighbours/{sample_name}/{snp_distance}"
    ).json()


def get_debug():
    return requests.get("http://localhost:5000/debug").json()


def get_sample_list():
    return requests.get("http://localhost:5000/list_samples").json()


def go():
    start_test_catwalk()
    r = add_sample_to_catwalk("test1", "ACGTACGT")
    assert r.status_code == 201
    r = add_sample_to_catwalk("test2", "ACGTACGG")
    assert r.status_code == 201
    r = add_sample_to_catwalk("test3", "ACGTACGC")
    assert r.status_code == 201
    r = add_sample_to_catwalk("test3", "ACGTACGC")
    assert r.status_code == 200

    print(get_debug())
    print(get_sample_list())

    n1 = get_neighbours("test1", 50)
    assert n1 == [["test3", "1"], ["test2", "1"]]
    n2 = get_neighbours("test2", 50)
    assert n2 == [["test3", "1"], ["test1", "1"]]
    n3 = get_neighbours("test3", 50)
    assert n3 == [["test1", "1"], ["test2", "1"]]

    r = remove_sample_from_catwalk("test3")
    assert r.status_code == 200

    print(get_debug())
    print(get_sample_list())

    n1 = get_neighbours("test1", 50)
    assert n1 == [["test2", "1"]]

    r = add_sample_to_catwalk("test3", "ACGTACGC")
    assert r.status_code == 201

    n1 = get_neighbours("test1", 50)
    assert n1 == [["test3", "1"], ["test2", "1"]]

    # lowercase test
    r = add_sample_to_catwalk("test2l", "aCgTAcGg")
    assert r.status_code == 201
    n2l = get_neighbours("test2l", 50)
    assert n2l == [["test1", "1"], ["test2", "0"]]

    print(get_debug())
    print(get_sample_list())


if __name__ == "__main__":
    try:
        go()
        print("*** all ok")
    finally:
        os.system("pkill cw_server")
        os.system("rm -rf test")
