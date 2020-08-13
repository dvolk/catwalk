# CatWalk

## Description

CatWalk is a service where you insert bacterial fasta files and then query relationships between them.

It is based on the design of findNeighbour3 by David Wyllie.

## Requirements

- nim >= 1.0.0

### Installing nim (on Linux)

The following assumes you're putting nim in the home directory, but you can put it anywhere and then edit the paths below

1. Nim requires gcc:
```
sudo apt install gcc
```

2. Download and extract nim:
```
cd
wget https://nim-lang.org/download/nim-1.2.6-linux_x64.tar.xz
tar xf nim-1.2.6-linux_x64.tar.xz
```

3. to be able to run nim from any directory, add it to the `PATH` variable (replace yourusername with your username):
```
echo 'PATH=$PATH:/home/yourusername/nim-1.2.6/bin' >> .bashrc
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
Nim Compiler Version 1.2.6 [Linux: amd64]
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

### utils/plot_array.py

A script that can take dumps from `cw_client process_times` and draw graphs like so:

![](https://gitea.mmmoxford.uk/dvolk/catwalk/raw/branch/master/doc/perf.png)

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

This creates a cluster graph for SNP distance 12

## References

https://github.com/davidhwyllie/findNeighbour

https://github.com/davidhwyllie/findNeighbour2

https://github.com/davidhwyllie/findNeighbour3