import json
import glob
import argparse
import pycatwalk

def fasta_seq(filepath):
    with open(filepath) as f:
        return ''.join(f.read().split('\n')[1:])

def ref_compress(refseq, mask, sampleseq, max_n_positions):
    ret = dict()
    ret['N'] = list()
    ret['A'] = list()
    ret['C'] = list()
    ret['G'] = list()
    ret['T'] = list()

    if len(refseq) != len(sampleseq):
        print("following sample length does not match reference length")
        return None

    for i, _ in enumerate(refseq):
        if sampleseq[i] != refseq[i] and not i in mask:
            if sampleseq[i] not in ["A", "C", "G", "T"]:
                ret["N"].append(i)
            else:
                ret[sampleseq[i]].append(i)

    if len(ret["N"]) > max_n_positions:
        print(f"following sample has {len(ret['N'])} n positions, which is too many")
        return None

    return ret

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('reference_filepath')
    parser.add_argument('mask_filepath')
    parser.add_argument('fasta_dir')
    args = parser.parse_args()

    refseq = fasta_seq(args.reference_filepath)

    with open(args.mask_filepath) as mask:
        mask_str = mask.read()

    mask = set([int(x) for x in mask_str.split('\n') if x])

    pycatwalk.init(name="test instance",
                   reference_name="test reference",
                   reference_sequence=refseq,
                   mask_name="test mask",
                   mask_str=mask_str)

    glob_dir = args.fasta_dir + "/*"
    for i, f in enumerate(glob.glob(glob_dir)):
        refcomp = ref_compress(refseq, mask, fasta_seq(f), 130000)
        if refcomp is not None:
            pycatwalk.add_sample_from_refcomp(name=f, refcomp_json=json.dumps(refcomp))
            print(f"{i}. {f} neighbours: {len(pycatwalk.neighbours(f))}")
        else:
            print(f"skipped {f}")

    print(json.dumps(pycatwalk.status(), indent=4))

if __name__ == "__main__":
    main()
