import json
import random

import requests
import argh


def get_neighbours(sample_name, snp_distance):
    return requests.get(
        f"http://localhost:5000/neighbours/{sample_name}/{snp_distance}"
    ).json()


def get_neighbours_times():
    return requests.get("http://localhost:5000/neighbours_times").json()


def clear_neighbours_times():
    requests.post("http://localhost:5000/clear_neighbours_times")


def get_sample_list():
    return requests.get("http://localhost:5000/list_samples").json()


def load_cog_samples(cog_multifasta_file):
    return requests.post(
        "http://localhost:5000/add_samples_from_mfsl",
        json={"filepath": cog_multifasta_file},
    )


def go(cog_multifasta_file="", N=100, distances="1,10,100,1000"):
    if cog_multifasta_file:
        load_cog_samples(cog_multifasta_file)

    all_samples = get_sample_list()
    random_samples = [random.choice(all_samples) for _ in range(N)]
    distances = map(int, distances.split(","))
    distance_times = dict()

    for distance in distances:
        for random_sample in random_samples:
            get_neighbours(random_sample, distance)
        distance_times[distance] = get_neighbours_times()
        clear_neighbours_times()
    print(json.dumps(distance_times))


if __name__ == "__main__":
    argh.dispatch_command(go)
