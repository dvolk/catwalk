import argh

def load_fasta(filepath):
    return ''.join([x.strip() for x in open(filepath).readlines()][1:])

def load_mask(filepath):
    return set([int(x.strip()) for x in open(filepath).readlines()])

def main(ref_filepath, mask_filepath, sample1_filepath, sample2_filepath):
    ref = load_fasta(ref_filepath)
    sam1 = load_fasta(sample1_filepath)
    sam2 = load_fasta(sample2_filepath)
    mask = load_mask(mask_filepath)

    assert(len(ref) == len(sam1))
    assert(len(ref) == len(sam2))

    changes_raw = 0
    changes_after_ref_ns = 0
    changes_after_ref_mask = 0
    changes_after_pair_ns = 0

    for i, _ in enumerate(ref):
        if sam1[i] != sam2[i]:
            changes_raw = changes_raw + 1

            if ref[i] in 'ACGT':
                changes_after_ref_ns = changes_after_ref_ns + 1

                if i not in mask:
                    changes_after_ref_mask = changes_after_ref_mask + 1

                    if sam1[i] in 'ACGT' and sam2[i] in 'ACGT':
                        changes_after_pair_ns = changes_after_pair_ns + 1

    print(f"changes raw: {changes_raw}")
    print(f"changes after ref ns: {changes_after_ref_ns}")
    print(f"changes after ref mask: {changes_after_ref_mask}")
    print(f"changes after pair ns: {changes_after_pair_ns}")
    
    
if __name__ == "__main__":
    argh.dispatch_command(main)
