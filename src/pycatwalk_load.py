import json
import glob
import argh
import pycatwalk

def main(reference_filepath, mask_filepath, fasta_dir):
    def fasta_seq(filepath):
        with open(filepath) as f:
            return ''.join(f.read().split('\n')[1:])
    
    with open(mask_filepath) as mask:
        pycatwalk.init(name="test instance",
                       reference_name="test reference",
                       reference_sequence=fasta_seq(reference_filepath),
                       mask_name="test mask",
                       mask_str = mask.read())
    
    for i, f in enumerate(glob.glob(fasta_dir)):
        pycatwalk.add_sample(name=f, sequence=fasta_seq(f))
        print(f"{i}. {f} neighbours: {len(pycatwalk.neighbours(f))}")

    print(json.dumps(pycatwalk.status(), indent=4))

if __name__ == "__main__":
    argh.dispatch_command(main)
