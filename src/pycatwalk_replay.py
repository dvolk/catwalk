import json
import argparse
import pycatwalk

def fasta_seq(filepath):
    with open(filepath) as f:
        return ''.join(f.read().split('\n')[1:])

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('reference_filepath')
    parser.add_argument('log_filepath')
    args = parser.parse_args()

    print(f"loading {args.log_filepath}")

    rows = list()
    with open(args.log_filepath) as f:
        lines = f.read()[1:][:-1].split("}{")
        for line in lines:
            rows.append(json.loads("{" + line + "}"))
        print(f"parsed {len(rows)} function calls")

    print("replaying")

    for row in rows:
        fun = row["function"]
        if fun == "init":
            pycatwalk.init(row["name"],
                           row["reference_name"],
                           fasta_seq(args.reference_filepath),
                           row["mask_name"],
                           row["mask_str"])
        elif fun == "add_sample":
            pycatwalk.add_sample(row["name"],
                                 row["sequence"],
                                 row["keep"])
        elif fun == "add_sample_from_refcomp":
            #print(f'{row["time"]} {fun} {row["sample_name"]}')
            pycatwalk.add_sample_from_refcomp(row["sample_name"],
                                              row["refcomp_json"],
                                              row["keep"])
        elif fun == "neighbours":
            pycatwalk.neighbours(row["sample_name"])
        elif fun == "status":
            pycatwalk.status()

    print("replay ended successfully")

    print(json.dumps(pycatwalk.status(), indent=4))

if __name__ == "__main__":
    main()
