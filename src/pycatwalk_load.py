import json
import glob
import argparse
import pycatwalk

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('reference_filepath')
    parser.add_argument('mask_filepath')
    parser.add_argument('fasta_dir')
    args = parser.parse_args()

    def fasta_seq(filepath):
        with open(filepath) as f:
            return ''.join(f.read().split('\n')[1:])

    with open(args.mask_filepath) as mask:
        pycatwalk.init(name="test instance",
                       reference_name="test reference",
                       reference_sequence=fasta_seq(args.reference_filepath),
                       mask_name="test mask",
                       mask_str = mask.read())

    glob_dir = args.fasta_dir + "/*"
    for i, f in enumerate(glob.glob(glob_dir)):
        pycatwalk.add_sample(name=f, sequence=fasta_seq(f))
        print(f"{i}. {f} neighbours: {len(pycatwalk.neighbours(f))}")

    print(json.dumps(pycatwalk.status(), indent=4))

if __name__ == "__main__":
    main()
