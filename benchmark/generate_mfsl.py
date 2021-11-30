"""Generate random sequences for benchmarking.

This script generates a multifasta file potentially useful for benchmarking catwalk. It
generates a reference genome and mutates the reference and future samples to generate
more samples. 10% of samples are saved for future mutation.

Parameters (and defaults):

- number_of_samples=10

How many samples to create

- reference_length=10

How many bases the reference (and samples) should have.

- max_percent_of_ns=0.0

How many Ns the samples should have. This will be [0, max_percent_of_ns] percent

- mutate_elems_count_max=3

How many bases to change for every new sample. This will be [0, mutate_elems_count_max]

- seed=0

Random seed to use. For repeatable sample generation.
"""

import logging
import os
import random

import argh

logging.basicConfig(level=logging.WARNING)


def mask(seq, max_percent_of_ns):
    """Mask up to max_percent_of_ns of the sequence."""
    seqlen = len(seq)
    seq = seq[:]
    if max_percent_of_ns > 0:
        mask_elems_count = int(len(seq) * (random.uniform(0, max_percent_of_ns) / 100))
        mask_elems = list()
        for _ in range(mask_elems_count):
            mask_elems.append(random.randint(0, seqlen - 1))
        for mask_elem in mask_elems:
            seq[mask_elem] = "N"
    return seq


def mutate_v2(seq, mutate_elems_count_max):
    """Mutate up to mutate_elems_count_max bases in the sequence."""
    seqlen = len(seq)
    seq = seq[:]
    mutate_elems_count = random.randint(0, mutate_elems_count_max)
    for _ in range(mutate_elems_count):
        i = random.randint(0, seqlen - 1)
        seq[i] = random.choice("ACGT")
    return seq


def go(
        number_of_samples=10,
        reference_length=10,
        max_percent_of_ns=0.0,
        mutate_elems_count_max=3,
        seed=0,
):
    """Main function."""

    file_prefix = f"syn-{number_of_samples}_{reference_length}_{max_percent_of_ns}_{mutate_elems_count_max}"

    logging.info(f"number_of_samples={number_of_samples}, reference_length={reference_length}, max_percent_of_ns={max_percent_of_ns}, mutate_elems_count_max={mutate_elems_count_max}")
    # initialize rng so we always get the same seqs with the same seed
    random.seed(seed)

    # create the reference sequence
    reference_elems = "ACGT"
    reference = random.choices(reference_elems, k=reference_length)

    # write the reference to ref.fa
    with open(f"{file_prefix}-ref.fa", "w") as f:
        reference_name = (
            f">synthetic-reference_{reference_length}_{max_percent_of_ns}" + "\n"
        )

        reference_str = "".join(reference)
        f.write(reference_name + "\n")
        f.write(reference_str + "\n")

    # create samples and write to mfsl.fa
    # since we're appending, first delete it
    os.system(f"rm {file_prefix}-mfsl.fa")
    sample = None
    samples = [reference]
    for i in range(number_of_samples):
        with open(f"{file_prefix}-mfsl.fa", "a") as f:
            sample_name = f">syn-{i}"
            to_mutate_idx = random.randint(0, len(samples)-1)
            logging.info(f"mutating sample id {to_mutate_idx}")
            sample = mutate_v2(
                # pick a random sample to mutate
                samples[to_mutate_idx],
                mutate_elems_count_max
            )
            # save 10% of samples for later mutation
            if random.random() > 0.9:
                logging.info(f"saving sample {i}")
                samples.append(sample)
            sample_str = "".join(mask(sample, max_percent_of_ns))
            logging.debug(sample_str)
            f.write(sample_name + "\n")
            f.write(sample_str + "\n")
        if i > 0 and i % 1000 == 0:
            logging.warning(f"{i} / {number_of_samples}")

    logging.info("reference saved to {file_prefix}-ref.fa")
    logging.info("samples saved to {file_prefix}-mfsl.fa")


if __name__ == "__main__":
    argh.dispatch_command(go)
