"""CLI tool for making multifasta singleline files from a directory of fasta files."""

import pathlib

import argh


def go(fasta_dir):
    """Main function."""
    fs = pathlib.Path(fasta_dir).glob("*")

    for i, f in enumerate(fs):
        o = open(f).readlines()
        header = ">" + f.name
        seq = "".join(x.strip() for x in o[1:])
        if i > 0 and i % 1000 == 0:
            print(f"{i} samples processed")

        with open("{fasta_dir}.fa", "a") as g:
            g.write(header + "\n")
            g.write(seq + "\n")


if __name__ == "__main__":
    argh.dispatch_command(go)
