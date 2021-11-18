# How to benchmark catwalk

## Find some fasta files and the corresponding gnome reference fasta file

## Convert fasta files into singleline multifasta format

    python3 make_mfsl.py <fasta_dir>

## Start catwalk

## Load samples into catwalk

For example by using Python requests:

>>> import requests
>>> requests.post("http://localhost:5000/add_samples_from_mfsl", json={"filepath": "your_mfsl_file.fa"})

Wait for this to finish

## Start benchmark

eg.:

    python3 bench.py -N 100 -d $(seq -s ',' 0 50) > a.fa-TB37k.json

See --help for bench.py parameters

## Plot result

eg.:

    python3 plot.py a.fa-TB37k.json

## Look at result

eg.: a.fa-TB37k.json-acgt_corr.png
