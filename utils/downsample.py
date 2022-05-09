""" downsamples as fasta file """
import random
from Bio import SeqIO

inputfasta = "cog_unmasked_alignment.fasta"
outputfasta = "benchmark_downsample.fasta"
proportion_to_select = 0.01

# downsample
selected = []
n_read = 0
n_selected = 0
for record in SeqIO.parse(inputfasta, "fasta"):
    n_read += 1
    if random.random() <= proportion_to_select:
        selected.append(record)
        n_selected += 1
    if n_read % 1000 == 0:
        print(n_read, n_selected)
    #if n_read > 2000:
    #    break    

SeqIO.write(selected, outputfasta, 'fasta-2line')
