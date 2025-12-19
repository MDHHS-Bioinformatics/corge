#!/usr/bin/env python

import argparse
import sys
from pathlib import Path

def parse_args():
    p = argparse.ArgumentParser(
        description="Remove rows from ReporTree partitions.tsv based on sample IDs"
    )
    p.add_argument("--input", required=True, help="Local partitions TSV to edit")
    p.add_argument("--ids", required=True, help="Comma-separated list of sample IDs")
    return p.parse_args()

def main():
    args = parse_args()
    ids_to_remove = set(args.ids.split(","))

    partitions = Path(args.input)

    if not partitions.exists():
        sys.stderr.write(f"ERROR: input file not found: {partitions}\n")
        sys.exit(1)

    with partitions.open() as fh:
        header = fh.readline().rstrip("\n").split("\t")

        if "sequence" not in header:
            sys.stderr.write("ERROR: 'sequence' column not found\n")
            sys.exit(1)

        seq_idx = header.index("sequence")

        kept = ["\t".join(header)]
        removed = 0

        for line in fh:
            fields = line.rstrip("\n").split("\t")
            if fields[seq_idx] not in ids_to_remove:
                kept.append("\t".join(fields))
            else:
                removed += 1

    partitions.write_text("\n".join(kept) + "\n")

    sys.stderr.write(f"Removed {removed} rows from {partitions.name}\n")

if __name__ == "__main__":
    main()
