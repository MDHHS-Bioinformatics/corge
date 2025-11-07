#!/usr/bin/env python3
import os
import sys
import pandas as pd
import logging
import datetime
import argparse
from pathlib import Path


# -----------------------------
# Helper: build species index
# -----------------------------
def build_species_index(ps: pd.DataFrame) -> pd.DataFrame:
    """
    Expand partition summary into long-form index.
    Input columns: ['partition','cluster','cluster_length','samples']
    """
    idx = ps[['partition','cluster','cluster_length','samples']].copy()

    # Extract numeric values
    idx['partition_numeric'] = (
        idx['partition']
        .str.split('-', expand=True)[1]
        .str.split('x', expand=True)[0]
        .astype(int)
    )
    idx['cluster_numeric'] = (
        idx['cluster']
        .str.split('_', expand=True)[1]
        .astype(int)
    )

    # Build combined names
    idx['partition_cluster_name'] = (
        idx['partition'] + '_' + idx['cluster']
    ).str.replace('single-', 'HC', regex=True).str.replace('x1.0_cluster_', '-C', regex=True)

    # Expand samples into rows
    idx['sample_token'] = idx['samples'].fillna('').astype(str).str.split(',')
    idx = idx.explode('sample_token', ignore_index=True)
    idx['sample_token'] = idx['sample_token'].str.strip()
    idx = idx[idx['sample_token'] != '']

    return idx[
        ['sample_token','partition','partition_numeric','cluster','cluster_numeric',
         'partition_cluster_name','cluster_length']
    ]


# -----------------------------
# Helper: select clusters for species
# -----------------------------
def select_clusters_for_species(
    samples_df: pd.DataFrame,
    species: str,
    ps_index: pd.DataFrame,
    max_range: int
) -> pd.DataFrame:
    """
    Selects best clusters for a species given a partition range.
    """
    if samples_df.empty or ps_index.empty:
        return pd.DataFrame(columns=['sample_id','partition_cluster_name','cluster_length','cluster_samples'])

    # Full cluster membership
    full_members = (
        ps_index
        .groupby('partition_cluster_name', as_index=False)['sample_token']
        .agg(lambda s: ','.join(sorted(set(t for t in s.astype(str) if t and t.strip()))))
        .rename(columns={'sample_token': 'cluster_samples'})
    )

    # Clusters containing given samples
    base = ps_index[ps_index['sample_token'].isin(set(samples_df['sample_id']))].copy()
    if base.empty:
        return pd.DataFrame(columns=['sample_id','partition_cluster_name','cluster_length','cluster_samples'])

    # Apply range filter
    base['cluster_length'] = pd.to_numeric(base['cluster_length'], errors='coerce').fillna(0)
    cand = base[base['partition_numeric'] <= max_range].copy()
    if cand.empty:
        return pd.DataFrame(columns=['sample_id','partition_cluster_name','cluster_length','cluster_samples'])

    # Choose best cluster per sample
    cand = cand.sort_values(
        by=['sample_token','cluster_length','partition_numeric','cluster_numeric'],
        ascending=[True, False, True, True]
    )
    chosen = cand.drop_duplicates('sample_token', keep='first').copy()

    # Attach membership
    chosen = chosen.merge(full_members, on='partition_cluster_name', how='left')
    chosen.rename(columns={'sample_token': 'sample_id'}, inplace=True)

    return chosen[['sample_id','partition_cluster_name','cluster_length','cluster_samples']]


# -----------------------------
# Core: run corge cluster selection
# -----------------------------
def run_corge_cluster_selection(
    species: str,
    cluster_composition: str,
    thresholds: str,
    outdir: str,
    include_date: bool = False
) -> None:
    """
    Run cluster selection for a given species using cluster composition TSV and thresholds.
    """
    if not os.path.exists(cluster_composition):
        logging.error(f"❌ Cluster composition file not found: {cluster_composition}")
        sys.exit(1)

    # Load composition file safely
    try:
        ps = pd.read_csv(cluster_composition, sep='\t')

        # Clean up header: remove leading '#' if present
        ps.columns = ps.columns.str.lstrip('#')

        # Select only the expected columns
        expected_cols = ['partition', 'cluster', 'cluster_length', 'samples']
        missing = [c for c in expected_cols if c not in ps.columns]
        if missing:
            logging.error(f"Missing expected columns in cluster composition file: {missing}")
            sys.exit(1)

        ps = ps[expected_cols]

    except Exception as e:
        logging.error(f"❌ Failed to read cluster composition file: {e}")
        sys.exit(1)

    # Build index
    ps_index = build_species_index(ps)
    if ps_index.empty:
        logging.warning(f"No valid partition entries found for species={species}")
        return

    # Extract samples
    all_samples = ps_index['sample_token'].dropna().unique().tolist()
    if not all_samples:
        logging.warning(f"No samples found in cluster composition for {species}")
        return

    samples_df = pd.DataFrame({'sample_id': all_samples})
    os.makedirs(outdir, exist_ok=True)

    # Process thresholds
    for th_str in thresholds.split(','):
        try:
            th = int(th_str.strip())
        except ValueError:
            logging.warning(f"Skipping invalid threshold value: {th_str}")
            continue

        chosen = select_clusters_for_species(samples_df, species, ps_index, max_range=th)
        if chosen.empty:
            logging.warning(f"No clusters selected for {species} (threshold={th})")
            continue

        if include_date:
            chosen['report_date'] = datetime.datetime.now().strftime('%Y-%m-%d')

        out_path = os.path.join(outdir, f'{species}-groups_HC{th}.csv')
        chosen.to_csv(out_path, index=False)
        logging.info(f"✅ Cluster info saved for {species} threshold={th}: {out_path}")


# -----------------------------
# Command-line interface
# -----------------------------
def main():
    parser = argparse.ArgumentParser(
        description="Run CoRGE cluster selection for bacterial species."
    )
    parser.add_argument("--species", required=True, help="Species name (e.g., Klebsiella_pneumoniae).")
    parser.add_argument(
        "--cluster-composition",
        required=True,
        help="Path to cluster composition TSV file (columns: partition, cluster, cluster_length, samples)."
    )
    parser.add_argument("--thresholds", required=True, help="Comma-separated thresholds (e.g. '15,20,40,150').")
    parser.add_argument("--outdir", required=True, help="Output directory for generated cluster CSV files.")
    parser.add_argument("--include-date", action="store_true", help="Include report_date column in outputs.")

    args = parser.parse_args()

    logging.basicConfig(
        format='[%(asctime)s] %(levelname)s: %(message)s',
        level=logging.INFO
    )

    run_corge_cluster_selection(
        species=args.species,
        cluster_composition=args.cluster_composition,
        thresholds=args.thresholds,
        outdir=args.outdir,
        include_date=args.include_date
    )


if __name__ == "__main__":
    main()
