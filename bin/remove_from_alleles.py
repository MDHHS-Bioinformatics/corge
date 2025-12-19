#!/usr/bin/env python

import argparse
import sys
from pathlib import Path

def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True, help="Local alleles TSV to edit")
    p.add_argument("--ids", required=True, help="Comma-separated list of sample IDs")
    return p.parse_args()

def main():
    args = parse_args()
    ids_to_remove = set(args.ids.split(","))

    alleles = Path(args.input)

    if not alleles.exists():
        sys.stderr.write(f"ERROR: input file not found: {alleles}\n")
        sys.exit(1)

    with alleles.open() as fh:
        header = fh.readline().rstrip("\n").split("\t")

        if "FILE" not in header:
            sys.stderr.write("ERROR: 'FILE' column not found\n")
            sys.exit(1)

        file_idx = header.index("FILE")

        kept = ["\t".join(header)]
        removed = 0

        for line in fh:
            fields = line.rstrip("\n").split("\t")
            if fields[file_idx] not in ids_to_remove:
                kept.append("\t".join(fields))
            else:
                removed += 1

    alleles.write_text("\n".join(kept) + "\n")

    sys.stderr.write(f"Removed {removed} rows from {alleles.name}\n")

if __name__ == "__main__":
    main()
