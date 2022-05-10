# How to benchmark catwalk

These scripts were used for benchmarking catwalk for the Publication.

## Obtain test dataset

Benchmarking requires a multifasta file containing genomes, and a fasta file containing the reference genome against which mapping occurred.  

To illustrate the performance of the software, we provide a 1% random downsample of the SARS-CoV-2 COG-UK sequence data set containing 22,133 sequences.  The patterns of performance observed in this small dataset are very similar to those seen in much larger bodies of data.  The test data can be extracted as follows:

``` bunzip2 --keep benchmark/benchmark_downsample.fasta.bz2 ```

In the publication, we used the following data sets:
[M. tuberculosis](https://ora.ox.ac.uk/objects/uuid:82ce6500-fa71-496a-8ba5-ba822b6cbb50).   
[SARS-CoV-2 COG-UK public unmasked fasta output](https://cog-uk.s3.climb.ac.uk/phylogenetics/latest/cog_unmasked_alignment.fasta) downloaded on 1/12/2021. This is a large file [~ 60G ] and can be obtained using wget:
```
    wget https://cog-uk.s3.climb.ac.uk/phylogenetics/latest/cog_all.fasta
```

## Convert fasta files into fasta-2line multifasta format

(not needed if your data is already in fasta-2line format, which the SARS-CoV-2 sequence data is)
```
    python3 make_mfsl.py <fasta_dir>
```

## Start catwalk if not already running
If you followed the instructions in [using Catwalk](use.md), and the server is still running, no action is needed.  Otherwise, start the server:
```
    ./cw_server --instance-name=test --reference-filepath=reference/nc_045512.fasta --mask-filepath=reference/covid-exclude.txt
```
## Load samples into catwalk

Load samples for example by using Python requests:
```python3```

Then 
```
    >>> import requests
    >>> requests.post("http://localhost:5000/add_samples_from_mfsl", json={"filepath": "benchmark/benchmark_downsample.fasta"})
```
Wait for this to finish - should take about 1-2 seconds.  Then exit python
``` quit() ```

## Start benchmark

eg.: to benchmark using 100 randomly picked samples for distances 0-50

    ``` pipenv run python3 benchmark/bench.py -N 100 -d $(seq -s ',' 0 50) > small_test.json ```

See --help for bench.py parameters

## Plot result

eg.:

    ``` pipenv run python3 benchmark/plot.py small_test.json ```

## Look at result

    small_test.json
    small_test.json-refdist.pdf
    small_test.json-times.pdf
    small_test.json-unknownpos.pdf 

## (Optional) Convert result JSON to csv

eg.:

    ``` pipenv run python3 benchmark/bench2csv.py small_test.json ```

The resulting csv are:

    small_test.json-stats.csv
    small_test.json-times.csv
