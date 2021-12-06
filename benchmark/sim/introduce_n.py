""" introduce unknown positions (Ns) into synthetic fasta files, for the purpose of benchmarking """

from Bio import SeqIO
import random
import numpy as np

print("Generating simulated sequences")
with open('mutated_sequences.fa', 'wt') as fo:
    with open("sim0.fasta") as f:
        for i, record in enumerate(SeqIO.parse(f, 'fasta')):
            if i % 100 == 0:
                print(i)

            for unknown_pc in [0, 5, 10, 20]:
                seq = np.array(list(record.seq.upper()))
                seqlen = len(record.seq)
                n_to_mutate = int(( unknown_pc * seqlen )/100)
                sites_to_mutate = random.sample(list(range(seqlen)), n_to_mutate)
                new_seq = seq.copy()
                new_seq[sites_to_mutate] = 'N'
                defline = ">{0}-{1}\n".format(record.id, unknown_pc)
                new_seq = "".join(new_seq)
                fo.write(defline)
                fo.write("{0}\n".format(new_seq))

print("Output is in mutated_sequences.fa") 

