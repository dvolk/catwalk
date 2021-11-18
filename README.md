# CatWalk

## Description

CatWalk is a memory-efficient and ultra-fast web server to compute pairwise single nucleotide polymorphism (SNP) distance matrix written in Nim language.

The memory usage is 160kb per sequence for a pathogen of 4M bases, therefore computing 1M pairwise SNP distance of pathogen sequences of this kind can be achieved with a server of 16G memory. Catwalk can compare 1.2M sequences within a second using one core. It takes less than one second to get a neighborhood sequences of 20 SNPs.


## Requirements

- nim >= 1.4.0

### Installing nim (on Linux)

The following assumes you're putting nim in the home directory, but you can put it anywhere and then edit the paths below

1. Nim requires gcc:
```
sudo apt install gcc
```

2. Download and extract nim:
```
cd
wget https://nim-lang.org/download/nim-1.4.8-linux_x64.tar.xz
tar xf nim-1.4.8-linux_x64.tar.xz
```

3. to be able to run nim from any directory, add it to the `PATH` variable (replace yourusername with your username):
```
echo 'PATH=$PATH:/home/yourusername/nim-1.4.8/bin' >> .bashrc
```

4. When you run `nimble install` (the nim package manager), it puts binaries into `~/.nimble/bin`, so add that too (replace yourusername with your username):
```
echo 'PATH=$PATH:/home/yourusername/.nimble/bin' >> .bashrc
```

5. Source the bashrc file:
```
source ~/.bashrc
```
6. Confirm it's working:
```
$ nim -v
Nim Compiler Version 1.4.8 [Linux: amd64]
```

## Building

in the catwalk directory, run:

    nimble build -d:release -d:danger

This creates four binaries: `cw_server`, `cw_client`, `cw_webui`, `refcompress`

## Starting cw_server (example)

    ./cw_server --instance-name=test \
                --reference-filepath=res/references/R00000039.fa \
                --mask-filepath=res/masks/TB-exclude-adaptive.txt \
                --max_distance=20

## Unit tests

Using a python virtual environment, run tests through python client

    pipenv install
    ./run_tests.sh

## Batch adding samples

use something like `find`. e.g.:

    find path/to/your/fasta/files -type f -exec ./cw_client add_sample -f {} \;

## Starting the web UI

    ./cw_webui

Open browser at `http://localhost:5001`

## Cache

When you add samples to catwalk, a JSON string of the reference compressed sequence is saved to the `instance-name` directory. When you restart catwalk with that instance name, it will load these sequences automatically. This is much faster than re-adding them every time, and the files are smaller than the original fasta files.

We also provide the `refcompress` binary, which is a program to produce these reference compressed sequences. This enables the reference compression to be done in parallel (e.g. with GNU parallel) or integrated into pipelines.

## Utils

### utils/verify.py

Given a reference, a mask file and two samples, check the difference between
the samples in different ways.

### utils/compare_neighbours.py

Get all neighbours from different relateness services and compare them. Useful for
comparing identical datasets

### utils/clusters.py

Use networkx to create a cluster graph

#### Example: making a cluster graph png

You will need a running catwalk server and graphviz installed

Add your samples to catwalk and run:

```
python3 compare_neighbours.py cwn 12 > example.txt
python3 clusters.py example.txt 12
sfdp example.dot -Tpng -o example.png
```

This creates a cluster graph for SNP distance 12, see [an output example](https://gitea.mmmoxford.uk/dvolk/catwalk/raw/branch/master/doc/cluster-example.png).

## HTTP API

Catwalk provides the following HTTP API endpoints (examples are given with the Python Requests library):

### /info

Returns server information such which reference is used, memory used, version, etc.

    >>> requests.get("http://localhost:5000/info").json()

### /list_samples

Returns a JSON array of sample names loaded into the server.

    >>> requests.get("http://localhost:5000/list_samples").json()

### /add_sample

Add a sample to catwalk

    >>> requests.post("http://localhost:5000/add_sample", json={ "name": sample_name,
                                                                 "sequence": "ACGTACGT",
                                                                 "keep": True })

### /neighbours/<sample_name>/<distance>

Get a array of tuples [(neighbour_name, distance)] of neighbours of sample_name up to the SNP cut-off distance.

    >>> requests.get("http://localhost:5000/neighbours/sample_name/20")

### /add_samples_from_mfsl

Add samples to catwalk in the multifasta singleline format.

    >>> requests.post("http://localhost:5000/add_samples_from_mfsl", json={"filepath": "mysamples.fa"})

The filepath must be readable from the catwalk server.

This is faster than sending the sequences over HTTP with /add_sample. For maximum performance, use fast storage such as SSD drives.

### /remove_sample/<sample_name>

Remove a sample from catwalk

    >>> requests.get("http://localhost:5000/remove_sample/sample_name")

## References

Catwalk is motivated by BugMat and FindNeighbour.

Mazariegos-Canellas, O., Do, T., Peto, T. et al. BugMat and FindNeighbour: command line and server applications for investigating bacterial relatedness. BMC Bioinformatics 18, 477 (2017) [doi.org/10.1186/s12859-017-1907-2](https://doi.org/10.1186/s12859-017-1907-2)

[Repository of Bugmat and Findneighbour](https://github.com/davidhwyllie/findNeighbour)
