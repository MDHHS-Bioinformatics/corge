#!/usr/bin/env python

import argparse
import sys
from pathlib import Path

def parse_args():
    p = argparse.ArgumentParser(
        description="Remove samples from chewBBACA masked alleles table"
    )
    p.add_argument("--outdir", required=True, help="Pipeline output directory")
    p.add_argument("--species", required=True, help="Species name")
    p.add_argument("--ids", required=True, help="Comma-separated list of sample IDs")
    return p.parse_args()

def main():
    args = parse_args()

    ids_to_remove = set(args.ids.split(","))

    alleles = (
        Path(args.outdir)
        / args.species
        / "cgMLST"
        / "masked"
        / f"{args.species}_masked_results_alleles.tsv"
    )

    if not alleles.exists():
        sys.stderr.write(f"WARNING: alleles file not found: {alleles}\n")
        return 0

    with alleles.open() as fh:
        header = fh.readline().rstrip("\n").split("\t")

        if "FILE" not in header:
            sys.stderr.write("ERROR: 'FILE' column not found in alleles table\n")
            sys.exit(1)

        file_idx = header.index("FILE")

        kept_lines = ["\t".join(header)]
        removed = 0

        for line in fh:
            fields = line.rstrip("\n").split("\t")
            if fields[file_idx] not in ids_to_remove:
                kept_lines.append("\t".join(fields))
            else:
                removed += 1

    alleles.write_text("\n".join(kept_lines) + "\n")

    sys.stderr.write(
        f"Removed {removed} rows from {alleles.name} for species {args.species}\n"
    )

if __name__ == "__main__":
    main()
