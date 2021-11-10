import random
import os
import logging

import argh


logging.basicConfig(level=logging.WARNING)


def mutate_v1(seq, max_percent_of_ns, percent_mutation, seed):
    for i, _ in enumerate(seq):
        if random.uniform(0, 101) < percent_mutation:
            seq[i] = random.choice("ACGT")
        if random.uniform(0, 101) < random.uniform(0, max_percent_of_ns):
            seq[i] = "N"
    return seq


def mask(seq, max_percent_of_ns):
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
    logging.info(f"number_of_samples={number_of_samples}, reference_length={reference_length}, max_percent_of_ns={max_percent_of_ns}, mutate_elems_count_max={mutate_elems_count_max}")
    # initialize rng so we always get the same seqs with the same seed
    random.seed(seed)

    # create the reference sequence
    reference_elems = "ACGT"
    reference = random.choices(reference_elems, k=reference_length)

    # write the reference to ref.fa
    with open("ref.fa", "w") as f:
        reference_name = (
            f">synthetic-reference_{reference_length}_{max_percent_of_ns}" + "\n"
        )

        reference_str = "".join(reference)
        f.write(reference_name + "\n")
        f.write(reference_str + "\n")

    # create samples and write to mfsl.fa
    # since we're appending, first delete it
    os.system("rm mfsl.fa")
    sample = None
    samples = [reference]
    for i in range(number_of_samples):
        with open("mfsl.fa", "a") as f:
            sample_name = f">syn-{i}"
            to_mutate_idx = random.randint(0, len(samples)-1)
            logging.info(f"mutating sample id {to_mutate_idx}")
            sample = mutate_v2(
                # pick a random sample to mutate
                samples[to_mutate_idx],
                mutate_elems_count_max
            )
            if random.random() > 0.9:
                logging.info(f"saving sample {i}")
                samples.append(sample)
            sample_str = "".join(mask(sample, max_percent_of_ns))
            logging.debug(sample_str)
            f.write(sample_name + "\n")
            f.write(sample_str + "\n")
        if i > 0 and i % 1000 == 0:
            logging.warning(f"{i} / {number_of_samples}")

    logging.info("reference saved to ref.fa")
    logging.info("samples saved to mfsl.fa")


if __name__ == "__main__":
    argh.dispatch_command(go)
