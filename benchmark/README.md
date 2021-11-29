# How to benchmark catwalk

## Find some fasta files and the corresponding gnome reference fasta file

for example:

    wget https://cog-uk.s3.climb.ac.uk/phylogenetics/latest/cog_all.fasta

## Convert fasta files into singleline multifasta format

(not needed if it's already in this format like cog_all.fasta above)

    python3 make_mfsl.py <fasta_dir>

## Start catwalk

eg.:

    ./cw_server --instance-name=test --reference-filepath=reference/nc_045512.fasta --mask-filepath=reference/covid-exclude.txt

## Load samples into catwalk

Load samples for example by using Python requests:

    >>> import requests
    >>> requests.post("http://localhost:5000/add_samples_from_mfsl", json={"filepath": "/path/to/your/cog_all.fasta"})

Wait for this to finish

## Start benchmark

eg.: to benchmark using 100 randomly picked samples for distances 0-50

    python3 bench.py -N 100 -d $(seq -s ',' 0 50) > cog_test.json

See --help for bench.py parameters

## Plot result

eg.:

    python3 plot.py cog_test.json

## Look at result

eg.:

    cog_test.json-acgt_corr.png
    cog_test.json-refdist2525.png
    cog_test.json-unknownpos2525.png

## (Optional) Convert result JSON to csv

eg.:

    python3 bench2csv.py cog_test.json
