# CatWalk

## Description

CatWalk is a service where you insert bacterial fasta files and then query relationships between them.

It is based on the design of findNeighbour3 by David Wyllie.

## Requirements

- nim >= 1.0.0

## Building

    nimble build

This creates three binaries: `cw_server`, `cw_client` and `cw_webui`

## Starting cw_server (example)

    ./cw_server --instance-name=test \
                --reference-name=test \
                --reference-filepath=res/references/R00000039.fa \
                --mask-name=TB-exclude-adaptive.txt \
                --mask-filepath=res/masks/TB-exclude-adaptive.txt

## Adding samples

    ./cw_client add_samples_from_dir -s path/to/directory/of/fastas

## Starting the web UI

    ./cw_webui

Open browser at `http://localhost:5001`

## Utils

### utils/compile.bash

Compile catwalk binaries with more aggressive optimization options.

### utils/verify.py

Given a reference, a mask file and two samples, check the difference between
the samples in different ways.

### utils/plot_array.py

A script that can take dumps from `cw_client process_times` and draw graphs like so:

![](https://gitea.mmmoxford.uk/dvolk/catwalk/raw/branch/master/doc/perf.png)

## TODO

- persistence with database
- more tests

## References

https://github.com/davidhwyllie/findNeighbour

https://github.com/davidhwyllie/findNeighbour2

https://github.com/davidhwyllie/findNeighbour3