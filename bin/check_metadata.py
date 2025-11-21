#!/usr/bin/env python3
import pandas as pd
import argparse
import os
import sys

def error(msg):
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--metadata", required=True)
    parser.add_argument("--input", required=True)
    parser.add_argument("--species", required=True)
    parser.add_argument("--partitions", required=True)
    args = parser.parse_args()

    # -------------------------------------------------------
    # Load and normalize metadata
    # -------------------------------------------------------
    meta = pd.read_csv(args.metadata, sep="\t", dtype=str)
    meta.columns = [c.replace(" ", "_") for c in meta.columns]

    first_col = meta.columns[0]

    # -------------------------------------------------------
    # Read input samples and filter by species
    # -------------------------------------------------------
    inp = pd.read_csv(args.input, sep=None, engine="python", dtype=str)

    required_cols = {"sample", "species"}
    missing = required_cols - set(inp.columns)
    if missing:
        error(f"Input file is missing required columns: {missing}")

    # Restrict to new samples of this species
    species_samples = inp[inp["species"] == args.species]
    new_samples = species_samples["sample"].dropna().unique().tolist()

    if not new_samples:
        print(f"WARNING: No new samples found for species '{args.species}'.")

    # -------------------------------------------------------
    # Check new samples exist in metadata
    # -------------------------------------------------------
    meta_samples = meta[first_col].dropna().unique().tolist()
    missing_new = sorted(set(new_samples) - set(meta_samples))
    if missing_new:
        error(f"The following NEW samples are missing in metadata: {missing_new}")

    # -------------------------------------------------------
    # Read OLD samples if partitions file exists
    # -------------------------------------------------------
    old_samples = []
    if os.path.exists(args.partitions):
        part = pd.read_csv(args.partitions, sep="\t", dtype=str)
        if "sequence" not in part.columns:
            error(f"Partitions file must have 'sequence' column.")
        old_samples = part["sequence"].dropna().unique().tolist()

        missing_old = sorted(set(old_samples) - set(meta_samples))
        if missing_old:
            error(f"The following OLD samples are missing in metadata: {missing_old}")

    # -------------------------------------------------------
    # Filter metadata for new + old samples
    # -------------------------------------------------------
    keep = sorted(set(new_samples) | set(old_samples))

    filtered = meta[meta[first_col].isin(keep)]

    # Sanity check
    if filtered[first_col].duplicated().any():
        error("Duplicate sample IDs detected after filtering.")

    # -------------------------------------------------------
    # Output
    # -------------------------------------------------------
    outpath = f"{args.species}_metadata.tsv"
    filtered.to_csv(outpath, sep="\t", index=False)
    print(f"✔ Written: {outpath}")

if __name__ == "__main__":
    main()
