# CatWalk

## Description

CatWalk is a service where you insert bacterial fasta files and then query relationships between them.

It is based on the design of findNeighbour3 by David Wyllie.

## Requirements

- nim >= 1.0.0

### Installing nim

The following assumes you're putting nim in the home directory, but you can put it anywhere and then edit the paths below

1. Nim requires gcc:
```
sudo apt install gcc
```

2. Download and extract nim:
```
cd
wget https://nim-lang.org/download/nim-1.0.2-linux_x64.tar.xz
tar xf nim-1.0.2-linux_x64.tar.xz
```

3. to be able to run nim from any directory, add it to the `PATH` variable (replace yourusername with your username):
```
echo 'PATH=$PATH:/home/yourusername/nim-1.0.2/bin' >> .bashrc
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
Nim Compiler Version 1.0.2 [Linux: amd64]
```

## Building

in the catwalk directory, run:

    nimble build -d:release -d:danger 

This creates three binaries: `cw_server`, `cw_client` and `cw_webui`

## Starting cw_server (example)

    ./cw_server --instance-name=test \
                --reference-name=test \
                --reference-filepath=res/references/R00000039.fa \
                --mask-name=TB-exclude-adaptive.txt \
                --mask-filepath=res/masks/TB-exclude-adaptive.txt \
                --max_distance=20

## Batch adding samples

use something like `find`. e.g.:

    find path/to/your/fasta/files -type f -exec ./cw_client add_sample -f {} \;

## Starting the web UI

    ./cw_webui

Open browser at `http://localhost:5001`

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