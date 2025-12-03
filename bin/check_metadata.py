#!/usr/bin/env python3
import pandas as pd
import argparse
import sys

def error(msg):
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)

def read_table(path):
    """Load TSV or CSV automatically."""
    try:
        return pd.read_csv(path, sep=None, engine="python", dtype=str)
    except Exception as e:
        error(f"Cannot read table '{path}': {e}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--metadata", required=True)
    parser.add_argument("--input", required=True)
    parser.add_argument("--species", required=True)
    args = parser.parse_args()

    # -------------------------------------------------------
    # Load metadata (TSV or CSV)
    # -------------------------------------------------------
    metadata = read_table(args.metadata)
    metadata_firstcol = metadata.columns[0]          # the species' sample ID column
    metadata_samples = (
        metadata[metadata_firstcol]
        .dropna()
        .astype(str)
        .unique()
        .tolist()
    )

    # -------------------------------------------------------
    # Load input masked alleles (already species-filtered)
    # First column is FILE
    # -------------------------------------------------------
    masked = read_table(args.input)
    if "FILE" not in masked.columns:
        error("Input file must contain a 'FILE' column.")

    masked_samples = (
        masked["FILE"]
        .dropna()
        .astype(str)
        .unique()
        .tolist()
    )

    # -------------------------------------------------------
    # Check missing samples
    # -------------------------------------------------------
    missing = sorted(set(masked_samples) - set(metadata_samples))
    if missing:
        error(f"These samples from masked alleles are missing in metadata: {missing}")

    # -------------------------------------------------------
    # Filter metadata for the valid samples
    # -------------------------------------------------------
    filtered = metadata[metadata[metadata_firstcol].isin(masked_samples)]

    # -------------------------------------------------------
    # Save output
    # -------------------------------------------------------
    outpath = f"{args.species}_metadata.tsv"
    filtered.to_csv(outpath, sep="\t", index=False)

    print(f"✔ Metadata OK. Written: {outpath}")

if __name__ == "__main__":
    main()
