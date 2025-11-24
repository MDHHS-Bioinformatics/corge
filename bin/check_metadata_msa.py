#!/usr/bin/env python3
import pandas as pd
import argparse
import sys
import re

def error(msg):
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)

def read_table(path):
    """Load TSV or CSV automatically."""
    try:
        return pd.read_csv(path, sep=None, engine="python", dtype=str)
    except Exception as e:
        error(f"Cannot read table '{path}': {e}")

def read_fasta_headers(path):
    """Extract headers (sample IDs) from FASTA/MSA file."""
    headers = []
    try:
        with open(path) as f:
            for line in f:
                if line.startswith(">"):
                    h = line[1:].strip()
                    headers.append(h)
    except Exception as e:
        error(f"Cannot read FASTA file '{path}': {e}")

    if not headers:
        error(f"No FASTA headers found in '{path}'.")

    return headers

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--metadata", required=True)
    parser.add_argument("--msa", required=True)
    parser.add_argument("--species", required=True)
    args = parser.parse_args()

    # -------------------------------------------------------
    # Load metadata (TSV or CSV)
    # -------------------------------------------------------
    metadata = read_table(args.metadata)
    metadata_firstcol = metadata.columns[0]  # sample ID column
    metadata_samples = (
        metadata[metadata_firstcol]
        .dropna()
        .astype(str)
        .unique()
        .tolist()
    )

    # -------------------------------------------------------
    # Read FASTA headers as sample IDs
    # -------------------------------------------------------
    msa_samples = read_fasta_headers(args.msa)

    # -------------------------------------------------------
    # Check missing samples
    # -------------------------------------------------------
    missing = sorted(set(msa_samples) - set(metadata_samples))
    if missing:
        error(f"The following MSA sample IDs are missing in metadata: {missing}")

    # -------------------------------------------------------
    # Filter metadata for only those samples in the MSA
    # -------------------------------------------------------
    filtered = metadata[metadata[metadata_firstcol].isin(msa_samples)]

    # -------------------------------------------------------
    # Save output
    # -------------------------------------------------------
    outpath = f"{args.species}_metadata.tsv"
    filtered.to_csv(outpath, sep="\t", index=False)

    print(f"✔ Metadata validated against FASTA/MSA. Written: {outpath}")

if __name__ == "__main__":
    main()
