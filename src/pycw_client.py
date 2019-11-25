"""
run catwalk from python.
"""
import argparse
import threading
import subprocess
import shlex
import time
import json
import sys

import requests

def start(cw_binary_filepath, instance_name, reference_filepath, mask_filepath, max_distance, bind_host="localhost", bind_port=5000):
    """
    Start the catwalk process in the background.

    This must be run before any other functions are called.
    """
    cw_binary_filepath = shlex.quote(cw_binary_filepath)
    instance_name = shlex.quote(instance_name)
    reference_filepath = shlex.quote(reference_filepath)
    mask_filepath = shlex.quote(mask_filepath)

    cmd = f"{cw_binary_filepath} --instance_name {instance_name}  --bind_host {bind_host} --bind_port {bind_port} --reference_name {reference_filepath} --reference_filepath {reference_filepath} --mask_name {mask_filepath} --mask_filepath {mask_filepath} --max_distance {max_distance}"
    print(cmd)
    def run():
        subprocess.run(shlex.split(cmd))
    t = threading.Thread(target=run)
    t.start()

    i = 0
    max_i = 100
    delay = 0.1
    while True:
        if i >= max_i:
            print(f"Failed to contact cw_server after {i * delay}s")
            return None
        time.sleep(delay)
        try:
            info(bind_host, bind_port)
            break
        except:
            pass
        i = i + 1
    print("cw_server started")
    return bind_host, bind_port

def info(host="localhost", port=5000):
    """
    Get status information from catwalk
    """
    return requests.get(f"http://{host}:{port}/info").json()

def add_sample_from_refcomp(name, refcomp_json, host="localhost", port=5000):
    """
    Add a reference compressed (json dict with ACGTN keys and list of positions as values) sample.

    The json dict must have all keys: ACGTN, even if they're empty
    """
    requests.post(f"http://{host}:{port}/add_sample_from_refcomp",
                  json={ "name": name,
                         "refcomp": refcomp_json,
                         "keep": True })

def neighbours(name, host="localhost", port=5000):
    """
    """
    r = requests.get(f"http://{host}:{port}/neighbours/{name}")
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

    r = start(*vars(args).values())
    if r:
        host, port = r
    else:
        print("Error: Couldn't start catwalk")
        return

    while True:
        print(json.dumps(info(host, port), indent=4))
        time.sleep(60)

if __name__ == "__main__":
    main()
