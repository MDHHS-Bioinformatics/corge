#!/usr/bin/env python3
import os
import csv
import argparse
import pandas as pd


def remove_assembly_files(outdir, species, samples):
    """Remove assemblies: outdir/<species>/assemblies/<sample>.fna."""
    asm_dir = os.path.join(outdir, species, "assemblies")
    if not os.path.isdir(asm_dir):
        print(f"[INFO] Assemblies directory missing: {asm_dir}")
        return

    for sample in samples:
        fna_path = os.path.join(asm_dir, f"{sample}.fna")
        if os.path.exists(fna_path):
            os.remove(fna_path)
            print(f"[OK] Removed assembly: {fna_path}")
        else:
            print(f"[WARN] Assembly not found: {fna_path}")


def remove_samples_from_tsv(path, id_column, samples):
    """Remove rows where id_column matches samples."""
    if not os.path.exists(path):
        print(f"[INFO] File does not exist: {path}")
        return

    try:
        df = pd.read_csv(path, sep="\t", dtype=str)
    except Exception as e:
        print(f"[ERROR] Could not read {path}: {e}")
        return

    before = df.shape[0]
    df = df[~df[id_column].isin(samples)]
    removed = before - df.shape[0]

    df.to_csv(path, sep="\t", index=False)
    print(f"[OK] Updated {path} (removed {removed} rows)")


def process_species(outdir, species, samples):
    """Process all cleanup steps for a given species."""
    species_dir = os.path.join(outdir, species)
    if not os.path.isdir(species_dir):
        print(f"[WARN] Species directory missing: {species_dir}")
        return

    print(f"\n=== Processing species: {species} | Samples: {len(samples)} ===")

    # 1. Remove assemblies
    remove_assembly_files(outdir, species, samples)

    # 2. cgMLST
    cg_dir = os.path.join(species_dir, "cgMLST", "joined")
    if os.path.isdir(cg_dir):
        joined_file = os.path.join(cg_dir, f"{species}_joined_results_alleles.tsv")
        masked_file = os.path.join(cg_dir, f"{species}_masked_results_alleles.tsv")

        remove_samples_from_tsv(joined_file, "FILE", samples)
        remove_samples_from_tsv(masked_file, "FILE", samples)
    else:
        print(f"[INFO] No cgMLST directory for {species}")

    # 3. ReporTree
    rep_path = os.path.join(species_dir, "ReporTree", f"{species}_partitions.tsv")
    remove_samples_from_tsv(rep_path, "sequence", samples)


def main():
    parser = argparse.ArgumentParser(description="Remove samples from species directories")
    parser.add_argument("--csv", required=True, help="CSV file with columns: sample,species")
    parser.add_argument("--outdir", required=True, help="Output directory")
    args = parser.parse_args()

    # Read CSV
    species_map = {}
    with open(args.csv) as f:
        reader = csv.DictReader(f)
        for row in reader:
            sample = row["sample"]
            species = row["species"]
            species_map.setdefault(species, []).append(sample)

    # Process each species
    for species, samples in species_map.items():
        process_species(args.outdir, species, samples)


if __name__ == "__main__":
    main()
