#!/usr/bin/env python3
import os
import sys
import pandas as pd
import numpy as np
import argparse
import logging


def bacterial_linkage_corge(species: str, dist_hamming: str, output: str):
    """
    Generate a summary bacterial linkage table with potential strong and intermediate linkages.

    Parameters
    ----------
    species : str
        Species name
    dist_hamming : str
        Path to distance matrix TSV file from ReporTree
    output : str
        Output file path for linkage report
    """

    # -----------------------------
    # Helper: format linkages
    # -----------------------------
    def format_linkages(df, threshold, max_distance, include_threshold=False):
        def linkages(distances):
            linked_samples = [
                f"{sample} ({distances[sample]})"
                for sample in distances.index
                if (
                    ((distances[sample] > threshold) if not include_threshold else (distances[sample] >= threshold))
                    and distances[sample] <= max_distance
                    and sample != distances.name
                )
            ]
            return ', '.join(linked_samples) if linked_samples else 'no linkages'

        return df.apply(linkages, axis=1)

    # -----------------------------
    # Load distance matrix
    # -----------------------------
    if not os.path.exists(dist_hamming):
        logging.error(f"Error: Distance file not found - {dist_hamming}")
        sys.exit(1)

    try:
        matrix_df = pd.read_csv(dist_hamming, sep='\t', index_col=0)
        matrix_df = matrix_df.astype(float)
    except Exception as e:
        logging.error(f"Error reading distance file {dist_hamming}: {e}")
        sys.exit(1)

    # Replace diagonal with inf (self-comparisons)
    np.fill_diagonal(matrix_df.values, float('inf'))

    # -----------------------------
    # Compute linkages
    # -----------------------------
    strong_linkages = format_linkages(matrix_df, 0, 10, include_threshold=True)
    intermediate_linkages = format_linkages(matrix_df, 10, 40)

    # -----------------------------
    # Build results table
    # -----------------------------
    result_df = pd.DataFrame({
        'sample_id': matrix_df.index,
        'species': species,
        'strong_linkages': strong_linkages,
        'intermediate_linkages': intermediate_linkages
    })

    # Fill missing safely
    result_df['strong_linkages'] = result_df['strong_linkages'].fillna('no linkages')
    result_df['intermediate_linkages'] = result_df['intermediate_linkages'].fillna('no linkages')

    # -----------------------------
    # Save to CSV
    # -----------------------------
    try:
        result_df.to_csv(output, index=False)
        logging.info(f"✅ Potential linkage table saved: {output}")
    except Exception as e:
        logging.error(f"❌ Failed to write output file {output}: {e}")
        sys.exit(1)


# -----------------------------
# Command-line interface
# -----------------------------
def main():
    parser = argparse.ArgumentParser(
        description="Generate linkage tables based on core genome distances."
    )
    parser.add_argument("--species", required=True, help="Species name for the linkage report.")
    parser.add_argument("--dist-hamming", required=True, help="Path to distance matrix TSV from ReporTree.")
    parser.add_argument("--output", required=True, help="Output CSV file path.")

    args = parser.parse_args()

    logging.basicConfig(
        format='[%(asctime)s] %(levelname)s: %(message)s',
        level=logging.INFO
    )

    bacterial_linkage_corge(args.species, args.dist_hamming, args.output)


if __name__ == "__main__":
    main()

