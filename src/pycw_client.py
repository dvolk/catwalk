"""
run catwalk from python.
"""
import argparse
import threading
import subprocess
import shlex
import time
import json

import requests

def start(cw_binary_filepath, instance_name, reference_filepath, mask_filepath, max_distance):
    """
    Start the catwalk process in the background.

    This must be run before any other functions are called.
    """
    cw_binary_filepath = shlex.quote(cw_binary_filepath)
    instance_name = shlex.quote(instance_name)
    reference_filepath = shlex.quote(reference_filepath)
    mask_filepath = shlex.quote(mask_filepath)
    
    cmd = f"{cw_binary_filepath} --instance_name {instance_name} --reference_name {reference_filepath} --reference_filepath {reference_filepath} --mask_name {mask_filepath} --mask_filepath {mask_filepath} --max_distance {max_distance}"
    print(cmd)
    def run():
        subprocess.run(shlex.split(cmd))
    t = threading.Thread(target=run)
    t.start()

def info():
    """
    Get status information from catwalk
    """
    return requests.get("http://127.0.0.1:5000/info").json()

def add_sample_from_refcomp(name, refcomp_json):
    """
    Add a reference compressed (json dict with ACGTN keys and list of positions as values) sample.

    The json dict must have all keys: ACGTN, even if they're empty
    """
    requests.post("http://127.0.0.1:5000/add_sample_from_refcomp",
                  json={ "name": name,
                         "refcomp": refcomp_json,
                         "keep": True })

def neighbours(name):
    """
    """
    r = requests.get(f"http://127.0.0.1:5000/neighbours/{name}")
    j = r.json()
    return [(sample_name, int(distance_str)) for (sample_name, distance_str) in j]

def main():
    """
    You can also start it on the command-line, and then skip start()
    """
    p = argparse.ArgumentParser()
    p.add_argument("cw_binary_filepath")
    p.add_argument("instance_name")
    p.add_argument("reference_filepath")
    p.add_argument("mask_filepath")
    p.add_argument("max_distance")
    args = p.parse_args()

    start(*vars(args).values())

    time.sleep(5)
    while True:
        print(json.dumps(info(), indent=4))
        time.sleep(60)

if __name__ == "__main__":
    main()
