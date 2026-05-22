#!/usr/bin/env python3
import os
import re
import sys
import pandas as pd
import numpy as np
import argparse
import logging


def bacterial_linkage_corge(species: str, data_type: str, dist_hamming: str, loci_report: str, parsnp_log: str, output: str):
    """
    Generate a summary bacterial linkage table with potential strong and intermediate linkages.
    """

    def is_parsnp_reference(x):
        x = os.path.basename(str(x).strip())
        return x.endswith(".ref") or ".ref" in x

    def clean_sample_name(x):
        x = os.path.basename(str(x).strip())

        for suffix in [
            ".fna.ref",
            ".fasta.ref",
            ".fa.ref",
            ".fna",
            ".fasta",
            ".fa"
        ]:
            if x.endswith(suffix):
                x = x[:-len(suffix)]

        return x

    def parse_parsnp_log(parsnp_log):
        """
        Parse Parsnp log and return per-sample QC metrics.

        Returns:
            sample
            analysis_length
            percentage_called
        """

        records = []
        current_seq = None
        current_sample = None
        current_length = None

        sequence_info = {}

        with open(parsnp_log, "r") as handle:
            lines = handle.readlines()

        for i, line in enumerate(lines):
            stripped = line.strip()

            seq_match = re.match(r"Sequence\s+(\d+)\s+:\s+(.+)", stripped)
            if seq_match:
                current_seq = int(seq_match.group(1))
                path = seq_match.group(2).strip()

                # Parsnp log usually has the cleaner sample name on the next line
                if i + 1 < len(lines):
                    next_line = lines[i + 1].strip()
                else:
                    next_line = ""

                # Detect random Parsnp reference before cleaning sample names
                is_reference = is_parsnp_reference(path) or is_parsnp_reference(next_line)

                if is_reference:
                    current_seq = None
                    continue

                if next_line and not next_line.startswith("Length:"):
                    current_sample = clean_sample_name(next_line)
                else:
                    current_sample = clean_sample_name(path)

                sequence_info[current_seq] = {
                    "sample": current_sample,
                    "analysis_length": None,
                    "percentage_called": None
                }

            length_match = re.match(r"Length:\s+(\d+)\s+bps", stripped)
            if length_match and current_seq is not None:
                sequence_info[current_seq]["analysis_length"] = int(length_match.group(1))

            cov_match = re.match(
                r"Cluster coverage in sequence\s+(\d+):\s+([\d.]+)%",
                stripped
            )
            if cov_match:
                seq_num = int(cov_match.group(1))
                coverage_pct = float(cov_match.group(2))
                coverage_decimal = coverage_pct / 100.0

                if seq_num in sequence_info:
                    sequence_info[seq_num]["percentage_called"] = coverage_decimal

        for seq_num, info in sequence_info.items():
            records.append({
                "sample": info["sample"],
                "analysis_length": info["analysis_length"],
                "percentage_called": info["percentage_called"]
            })

        return pd.DataFrame(records)

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
    # Load method-specific completeness metrics
    # -----------------------------

    def completeness_check_cgmlst(pct):
        if pd.isna(pct):
            return "FAIL"
        if pct >= 0.95:
            return "PASS"
        elif pct >= 0.90:
            return "WARN"
        else:
            return "FAIL"

    def completeness_check_snp(pct):
        if pd.isna(pct):
            return "FAIL"
        if pct >= 0.50:
            return "PASS"
        elif pct >= 0.40:
            return "WARN"
        else:
            return "FAIL"
        
    if data_type == "cgMLST":

        if loci_report is None or not os.path.exists(loci_report):
            logging.error(f"Error: cgMLST requires a loci report, but none was found: {loci_report}")
            sys.exit(1)

        try:
            qc_df = pd.read_csv(loci_report, sep="\t")
        except Exception as e:
            logging.error(f"Error reading loci report {loci_report}: {e}")
            sys.exit(1)

        required_cols = {"samples", "missing", "called", "pct_called"}
        missing_cols = required_cols - set(qc_df.columns)

        if missing_cols:
            logging.error(f"Loci report is missing required columns: {', '.join(sorted(missing_cols))}")
            sys.exit(1)

        qc_df = qc_df.rename(columns={
            "samples": "sample",
            "pct_called": "percentage_called"
        })

        qc_df["sample"] = qc_df["sample"].apply(clean_sample_name)
        qc_df["analysis_length"] = qc_df["missing"].astype(int) + qc_df["called"].astype(int)
        qc_df["percentage_called"] = pd.to_numeric(qc_df["percentage_called"], errors="coerce")
        qc_df["completeness_qc"] = qc_df["percentage_called"].apply(completeness_check_cgmlst)

        qc_df = qc_df[[
            "sample",
            "analysis_length",
            "percentage_called",
            "completeness_qc"
        ]]


    elif data_type == "SNP":

        if parsnp_log is None or not os.path.exists(parsnp_log):
            logging.error(f"Error: SNP analysis requires a Parsnp log, but none was found: {parsnp_log}")
            sys.exit(1)

        qc_df = parse_parsnp_log(parsnp_log)

        qc_df["sample"] = qc_df["sample"].apply(clean_sample_name)
        qc_df["analysis_length"] = pd.to_numeric(qc_df["analysis_length"], errors="coerce")
        qc_df["percentage_called"] = pd.to_numeric(qc_df["percentage_called"], errors="coerce").round(3)
        qc_df["completeness_qc"] = qc_df["percentage_called"].apply(completeness_check_snp)

        qc_df = qc_df[[
            "sample",
            "analysis_length",
            "percentage_called",
            "completeness_qc"
        ]]
        
    # -----------------------------
    # Compute linkages
    # -----------------------------
    strong_linkages = format_linkages(matrix_df, 0, 10, include_threshold=True)
    intermediate_linkages = format_linkages(matrix_df, 10, 40)
    lineage_level = format_linkages(matrix_df, 40, 150)

    # -----------------------------
    # Build results table
    # -----------------------------
    qc_index = qc_df.set_index("sample")

    result_df = pd.DataFrame({
        "sample": matrix_df.index,
        "species": species,
        "data_type": data_type,
        "analysis_length": matrix_df.index.map(qc_index["analysis_length"]),
        "percentage_called": matrix_df.index.map(qc_index["percentage_called"]),
        "completeness_qc": matrix_df.index.map(qc_index["completeness_qc"]),
        "min_dist": min_dist,
        "strong_linkages": strong_linkages,
        "intermediate_linkages": intermediate_linkages,
        "lineage_level": lineage_level
    })

    # Fill missing safely
    for col in ['strong_linkages', 'intermediate_linkages', 'lineage_level']:
        result_df[col] = result_df[col].fillna('None')

    result_df["analysis_length"] = pd.to_numeric(result_df["analysis_length"], errors="coerce").astype("Int64")
    result_df["percentage_called"] = pd.to_numeric(result_df["percentage_called"], errors="coerce")
    result_df["min_dist"] = pd.to_numeric(result_df["min_dist"], errors="coerce").astype("Int64")
    result_df = result_df.sort_values("sample").reset_index(drop=True)
    
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
    parser.add_argument("--data-type", required=True, choices=["cgMLST", "SNP"])
    parser.add_argument("--loci-report", required=False, default=None)
    parser.add_argument("--parsnp-log", required=False, default=None)
    parser.add_argument("--output", required=True)

    args = parser.parse_args()

    logging.basicConfig(
        format='[%(asctime)s] %(levelname)s: %(message)s',
        level=logging.INFO
    )

    bacterial_linkage_corge(
        args.species,
        args.data_type,
        args.dist_hamming,
        args.loci_report,
        args.parsnp_log,
        args.output
    )

if __name__ == "__main__":
    main()
