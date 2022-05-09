"""CLI tool for making multifasta files from a
 directory of fasta files or multifasta files.
 
 These files are characterised by having no line endings in the sequence
 and can be read very fast by Catwalk.
 
 Example:  The script will convert files of this type
 >seq1
 ACTGA
 AAAAG
 >seq2
 ACTGA
 AAAAT

 Into
>seq1
ACTGAAAAG
>seq2
ACTGAAAAT

"""

import pathlib
import os
import argh
from Bio import SeqIO

def convert_fasta_files(fasta_dir):
    """ Converts fasta denoted by a .fasta ending present in fasta_dir 
        into a single reformatted fasta file
        called 'mfsl.fa' in the same directory.
        
        This format is referred to as 'fasta-2line' by Biopython
        https://biopython.org/wiki/SeqIO 
    """
    
    # list any files found
    fs = pathlib.Path(fasta_dir).glob("*.fasta")

    records = list()

    # for each input file
    for i, input_filename in enumerate(fs):
        print("Converting {0}".format(input_filename))
        with open(input_filename, 'rt') as ifh:
            for record in SeqIO.parse(ifh, 'fasta'):
                records.append(record)

    SeqIO.write(records, os.path.join(fasta_dir, 'mfsl.fa'), 'fasta-2line')

    print("Exported {0} records to {1}".format(len(records), 'mfsl.fa'))

if __name__ == "__main__":
    argh.dispatch_command(convert_fasta_files)
