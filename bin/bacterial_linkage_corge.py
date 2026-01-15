#!/usr/bin/env python3
import os
import sys
import pandas as pd
import numpy as np
import argparse
import logging


def bacterial_linkage_corge(species: str, dist_hamming: str, loci_report: str, output: str):
    """
    Generate a summary bacterial linkage table with potential strong and intermediate linkages.
    """

    # -----------------------------
    # Helper: format linkages
    # -----------------------------
    def format_linkages(df, threshold, max_distance, include_threshold=False):
        def linkages(distances):
            linked = [
                (sample, distances[sample])
                for sample in distances.index
                if (
                    ((distances[sample] > threshold) if not include_threshold else (distances[sample] >= threshold))
                    and distances[sample] <= max_distance
                    and sample != distances.name
                )
            ]

            if not linked:
                return 'None'

            linked_sorted = sorted(linked, key=lambda x: x[1])
            return ', '.join(f"{s} ({int(d)})" for s, d in linked_sorted)

        return df.apply(linkages, axis=1)

    # -----------------------------
    # Load distance matrix
    # -----------------------------
    if not os.path.exists(dist_hamming):
        logging.error(f"Error: Distance file not found - {dist_hamming}")
        sys.exit(1)

    try:
        matrix_df = pd.read_csv(dist_hamming, sep='\t', index_col=0).astype(float)
    except Exception as e:
        logging.error(f"Error reading distance file {dist_hamming}: {e}")
        sys.exit(1)

    # Replace diagonal with inf
    np.fill_diagonal(matrix_df.values, float('inf'))

    # Minimum distance per sample
    min_dist = matrix_df.min(axis=1)

    # -----------------------------
    # Load loci report
    # -----------------------------
    if not os.path.exists(loci_report):
        logging.error(f"Error: Loci report not found - {loci_report}")
        sys.exit(1)

    try:
        loci_df = pd.read_csv(loci_report, sep='\t')
    except Exception as e:
        logging.error(f"Error reading loci report {loci_report}: {e}")
        sys.exit(1)

    if 'samples' not in loci_df.columns or 'pct_called' not in loci_df.columns:
        logging.error("Loci report must contain columns: 'samples' and 'pct_called'")
        sys.exit(1)

    loci_df = loci_df.rename(columns={'samples': 'sample'})
    loci_df = loci_df[['sample', 'pct_called']]

    # -----------------------------
    # Completeness logic
    # -----------------------------
    def completeness_check(pct):
        if pd.isna(pct):
            return 'FAIL'
        if pct >= 0.95:
            return 'PASS'
        elif pct >= 0.90:
            return 'WARN'
        else:
            return 'FAIL'

    loci_df['completeness_check'] = loci_df['pct_called'].apply(completeness_check)

    # -----------------------------
    # Compute linkages
    # -----------------------------
    strong_linkages = format_linkages(matrix_df, 0, 10, include_threshold=True)
    intermediate_linkages = format_linkages(matrix_df, 10, 40)
    lineage_level = format_linkages(matrix_df, 40, 150)

    # -----------------------------
    # Build results table
    # -----------------------------
    result_df = pd.DataFrame({
        'sample': matrix_df.index,
        'species': species,
        'percentage_called': matrix_df.index.map(loci_df.set_index('sample')['pct_called']),
        'completeness_check': matrix_df.index.map(loci_df.set_index('sample')['completeness_check']),
        'min_dist': min_dist,
        'strong_linkages': strong_linkages,
        'intermediate_linkages': intermediate_linkages,
        'lineage_level': lineage_level
    })

    # Fill missing safely
    for col in ['strong_linkages', 'intermediate_linkages', 'lineage_level']:
        result_df[col] = result_df[col].fillna('None')

    result_df['percentage_called'] = result_df['percentage_called'].astype(float)
    result_df['min_dist'] = result_df['min_dist'].astype(int)

    # -----------------------------
    # Save to CSV
    # -----------------------------
    try:
        result_df.to_csv(output, index=False)
        logging.info(f"✅ Potential linkage table saved: {output}")
    except Exception as e:
        logging.error(f"❌ Failed to write output file {output}: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Generate linkage tables based on core genome distances."
    )
    parser.add_argument("--species", required=True)
    parser.add_argument("--dist-hamming", required=True)
    parser.add_argument("--loci-report", required=True)
    parser.add_argument("--output", required=True)

    args = parser.parse_args()

    logging.basicConfig(
        format='[%(asctime)s] %(levelname)s: %(message)s',
        level=logging.INFO
    )

    bacterial_linkage_corge(
        args.species,
        args.dist_hamming,
        args.loci_report,
        args.output
    )


if __name__ == "__main__":
    main()
