""" benchmark_seqcomparer.py

Performs benchmarking of the sequence comparison engine from findneighbour2.
The engine is in the seqcomparer.py module, which is included here for comparison purposes

Usage:
python3 benchmark_seqcomparer.py reference_fasta_file test_multifasta_file

Example usage:
pipenv run python3 benchmark_seqcomparer.py test_ref.fa test_seqs.fa

Outputs test results into the directory the script is run from.

"""
import argparse
import pandas as pd
import datetime
import random
from seqcomparer import seqComparer
from Bio import SeqIO


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawTextHelpFormatter,
        description="""Runs benchmark_seqcomparer.py, which tests the performance of the seqComparer module from findneighbour2

Example usage:
==============
# show command line options
python benchmark_seqcomparer.py --help

# run benchmark with test_seqs.fa, sequences mapped to test_ref.fa.  Exclude the positions found in test_exclude.txt
pipenv run python3 benchmark_seqcomparer.py test_ref.fa test_seqs.fa test_exclude.txt 130000 12

""",
    )
    parser.add_argument(
        "ref_filename",
        type=str,
        action="store",
        nargs="?",
        help="the filename of the the reference sequence",
        default="",
    )
    parser.add_argument(
        "multifasta_filename",
        type=str,
        action="store",
        nargs="?",
        help="the multifasta file to test with",
        default="",
    )
    parser.add_argument(
        "exclude_filename",
        type=str,
        action="store",
        nargs="?",
        help="a file of zero indexed positions to exclude from distance computations",
        default="",
    )
    parser.add_argument(
        "maxNs",
        type=int,
        action="store",
        nargs="?",
        help="the maximum number of Ns in sequence to tolerate before regarding the sequence as invalid",
        default="",
    )
    parser.add_argument(
        "snpCeiling",
        type=int,
        action="store",
        nargs="?",
        help="the maximum SNV distance to report",
        default="",
    )

args = parser.parse_args()

# load reference
for record in SeqIO.parse(args.ref_filename, "fasta"):
    refseq = str(record.seq).upper()
    reflen = len(refseq)
    print("Loaded reference with {0} bases".format(reflen))

# initiate seqComparer object
sc = seqComparer(
    reference=refseq,
    NCompressionCutoff=0,
    maxNs=args.maxNs,
    startAfresh=True,
    excludeFile=args.exclude_filename,
    snpCeiling=args.snpCeiling,
)

print("Loading records")

loadlog_records = []
n_loaded = 0
for record in SeqIO.parse(args.multifasta_filename, "fasta"):

    n_loaded = n_loaded + 1
    id = record.id
    seq = str(record.seq).upper()
    seq = seq.replace("-", "N")

    rc = sc.compress(seq)
    dist2reference = (
        len(rc.get("A", []))
        + len(rc.get("C", []))
        + len(rc.get("T", []))
        + len(rc.get("G", []))
    )
    sc.persist(rc, method="localmemory", guid=id)
    loadlog_records.append(
        dict(
            timenow=datetime.datetime.now(),
            sample_id=id,
            rss_memory=sc.memoryInfo().rss,
            n_loaded=n_loaded,
            dist2reference=dist2reference,
            ns=len(rc.get("N", [])),
        )
    )

mem_profile = pd.DataFrame.from_records(loadlog_records, index="sample_id")
mem_profile_output_file = args.multifasta_filename + ".memprofile_{0}.csv".format(
    args.snpCeiling
)
mem_profile.to_csv(mem_profile_output_file)

print("Memory usage during load is in {0}".format(mem_profile_output_file))
print("top & tail:")
print(mem_profile)

# now sample up to 100 records for performance testing
all_sample_ids = list(sc.guidscachedinram())

if len(all_sample_ids) > 100:
    sample_ids = [random.choice(all_sample_ids) for _ in range(100)]
else:
    sample_ids = all_sample_ids
print("Selected {0} samples for performance testing".format(len(sample_ids)))

# performance test
perflog_records = []
for sample_id in sample_ids:
    print(sample_id)
    t0 = datetime.datetime.now()
    for cf_sample_id in all_sample_ids:
        res = sc.countDifferences_byKey(
            (sample_id, cf_sample_id), cutoff=args.snpCeiling
        )
    t1 = datetime.datetime.now()
    delta = (t1 - t0).total_seconds()
    perflog_records.append(
        dict(start_time=t0, end_time=t1, delta_seconds=delta, sample_id=sample_id)
    )

perf_profile = pd.DataFrame.from_records(perflog_records, index="sample_id")
perf_profile = perf_profile.merge(
    mem_profile[["dist2reference", "ns"]], right_index=True, left_index=True
)
perf_profile_output_file = args.multifasta_filename + ".perfprofile_{0}.csv".format(
    args.snpCeiling
)
perf_profile.to_csv(perf_profile_output_file)

print("Query performanceis in {0}".format(perf_profile_output_file))
print("top & tail:")
print(perf_profile)
