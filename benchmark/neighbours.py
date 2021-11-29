"""Describe the number of neighbours for a random set of samples at a given distance."""

import random
import collections

import argh
import requests
import scipy.stats
import plotille


def get_neighbours(sample_name, snp_distance):
    """Get neighbours from running catwalk server."""
    return requests.get(
        f"http://localhost:5000/neighbours/{sample_name}/{snp_distance}"
    ).json()


def get_neighbours_times():
    """Get neighbourhood analysis times from running catwalk server."""
    return requests.get("http://localhost:5000/neighbours_times").json()


def get_sample_list():
    """Get a list of all samples from running catwalk server."""
    return requests.get("http://localhost:5000/list_samples").json()


def sorted_counter(xs):
    return sorted(collections.Counter(xs).items(), key=lambda x: x[0])


def go(N=100, distance=20):
    """Main function."""
    all_samples = get_sample_list()
    random_samples = [random.choice(all_samples) for _ in range(N)]
    neighbours_count = list()
    for sample_name in random_samples:
        neighbours_count.append(len(get_neighbours(sample_name, distance)))
    print(scipy.stats.describe(neighbours_count))
    print(plotille.hist(neighbours_count, 10, 40))
    print(sorted_counter(neighbours_count))


if __name__ == "__main__":
    argh.dispatch_command(go)
