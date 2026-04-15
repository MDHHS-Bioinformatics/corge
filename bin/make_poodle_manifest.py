#!/usr/bin/env python3
import argparse
import os
import sys
import json
import pandas as pd


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate poodle manifests per threshold from genomic context groups."
    )
    parser.add_argument(
        "--species",
        required=True,
        help="Species name used in group filenames (e.g. Acinetobacter_baumannii).",
    )
    parser.add_argument(
        "--thresholds",
        required=True,
        help="Comma-separated thresholds (e.g. '15,20,40,150').",
    )
    parser.add_argument(
        "--groups",
        required=True,
        help="Directory containing group CSVs named '{species}-groups_HC<threshold>.csv'.",
    )
    parser.add_argument(
        "--outdir",
        required=True,
        help="Output directory for poodle_manifest_HC<threshold>.csv, "
             "and base for default assembly paths: outdir/species/assemblies/<sample>.fna",
    )
    parser.add_argument(
        "--master_paths",
        help=(
            "Optional master paths file (JSON or CSV). "
            "JSON: {\"sample\": {\"fastq_1\":..., \"fastq_2\":..., \"annotation\":..., \"assembly\":...}, ...} "
            "CSV: columns sample,fastq_1,fastq_2,annotation,assembly"
        ),
    )
    parser.add_argument(
        "--phoenix_path",
        help="Optional phoenix base path. Uses phoenix_path/<sample>/fastp_trimd and /annotation for fastqs and annotation.",
    )
    parser.add_argument(
        "--bactopia_path",
        help="Optional bactopia base path. Uses bactopia_path/<sample>/quality-control and /annotation.",
    )
    parser.add_argument(
        "--linkages",
        help=(
            "Optional linkage CSV with columns including: "
            "sample,species,percentage_called,completeness_qc,min_dist,"
            "strong_linkages,intermediate_linkages,lineage_level"
        ),
    )
    return parser.parse_args()

def load_linkages(path):
    """
    Load linkage CSV into a mapping:
      sample -> {
          "species": ...,
          "percentage_called": float or None,
          ...
      }

    Expected columns include at least:
      sample, percentage_called
    """
    if path is None:
        return {}

    try:
        df = pd.read_csv(path)

        required = {"sample", "percentage_called"}
        missing = required - set(df.columns)
        if missing:
            print(
                f"[WARN] Linkage file {path} is missing required columns: {sorted(missing)}",
                file=sys.stderr,
            )
            return {}

        linkages = {}
        for _, row in df.iterrows():
            sample = str(row["sample"]).strip()
            if not sample:
                continue

            percentage_called = row.get("percentage_called", None)
            if pd.isna(percentage_called):
                percentage_called = None
            else:
                try:
                    percentage_called = float(percentage_called)
                except (TypeError, ValueError):
                    percentage_called = None

            linkages[sample] = {
                "species": row.get("species", ""),
                "percentage_called": percentage_called,
                "completeness_qc": row.get("completeness_qc", ""),
                "min_dist": row.get("min_dist", ""),
                "strong_linkages": row.get("strong_linkages", ""),
                "intermediate_linkages": row.get("intermediate_linkages", ""),
                "lineage_level": row.get("lineage_level", ""),
            }

        return linkages

    except Exception as e:
        print(f"[WARN] Failed to load linkages from {path}: {e}", file=sys.stderr)
        return {}
    

def load_master_paths(path):
    """
    Load master paths mapping sample -> dict(fastq_1, fastq_2, annotation, assembly).

    Supports:
      - JSON: {sample: {fastq_1, fastq_2, annotation, assembly}}
      - CSV:  columns: sample,fastq_1,fastq_2,annotation,assembly
    """
    if path is None:
        return {}

    ext = os.path.splitext(path)[1].lower()
    mp = {}

    try:
        if ext == ".json":
            with open(path) as f:
                data = json.load(f)
            # Normalize keys to expected names
            for sample, vals in data.items():
                mp[sample] = {
                    "fastq_1": vals.get("fastq_1") or vals.get("fastq1", ""),
                    "fastq_2": vals.get("fastq_2") or vals.get("fastq2", ""),
                    "annotation": vals.get("annotation", ""),
                    "assembly": vals.get("assembly", ""),
                }
        else:
            df = pd.read_csv(path)
            for _, row in df.iterrows():
                sample = str(row["sample"])
                mp[sample] = {
                    "fastq_1": row.get("fastq_1", "") or row.get("fastq1", ""),
                    "fastq_2": row.get("fastq_2", "") or row.get("fastq2", ""),
                    "annotation": row.get("annotation", ""),
                    "assembly": row.get("assembly", ""),
                }
    except Exception as e:
        print(f"[WARN] Failed to load master_paths from {path}: {e}", file=sys.stderr)

    return mp


def build_paths_from_phoenix(sample, phoenix_path):
    base = os.path.join(phoenix_path, sample)
    fastq_1 = os.path.join(base, "fastp_trimd", f"{sample}_1.trim.fastq.gz")
    fastq_2 = os.path.join(base, "fastp_trimd", f"{sample}_2.trim.fastq.gz")
    annotation = os.path.join(base, "annotation", f"{sample}.gff")
    return fastq_1, fastq_2, annotation


def build_paths_from_bactopia(sample, bactopia_path):
    base = os.path.join(bactopia_path, sample)
    fastq_1 = os.path.join(base, "quality-control", f"{sample}_R1.fastq.gz")
    fastq_2 = os.path.join(base, "quality-control", f"{sample}_R2.fastq.gz")
    annotation = os.path.join(base, "annotation", f"{sample}.gff")
    return fastq_1, fastq_2, annotation


def get_default_assembly_path(outdir, species, sample):
    # From original spec: $outdir/$species/assemblies/<sample>.fna
    return os.path.join(outdir, species, "assemblies", f"{sample}.fna")


def get_assembly_metrics(assembly_path, cache):
    """
    Return (num_contigs, total_length) for given assembly FASTA.
    If the file can't be read, return (inf, 0) so it's never chosen
    over assemblies with valid metrics.
    """
    if assembly_path in cache:
        return cache[assembly_path]

    num_contigs = 0
    total_length = 0

    try:
        with open(assembly_path) as fh:
            seq_len = 0
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                if line.startswith(">"):
                    if seq_len > 0:
                        num_contigs += 1
                        total_length += seq_len
                        seq_len = 0
                else:
                    seq_len += len(line)
            if seq_len > 0:
                num_contigs += 1
                total_length += seq_len
    except OSError as e:
        print(f"[WARN] Cannot read assembly '{assembly_path}': {e}", file=sys.stderr)
        num_contigs = float("inf")
        total_length = 0

    cache[assembly_path] = (num_contigs, total_length)
    return num_contigs, total_length


def choose_reference_sample(samples_info, metrics_cache, linkages_by_sample=None):
    """
    samples_info: list of dicts with keys:
      - sample
      - assembly

    Reference selection priority:
      1) highest percentage_called (from --linkages)
      2) fewest contigs
      3) largest total assembly length
      4) alphabetical sample name

    If a sample is absent from the linkage file or percentage_called is missing,
    it is treated as worse than any sample with a valid percentage_called.
    """
    linkages_by_sample = linkages_by_sample or {}

    def sort_key(info):
        sample = info["sample"]
        assembly = info["assembly"]
        num_contigs, total_len = get_assembly_metrics(assembly, metrics_cache)

        linkage_info = linkages_by_sample.get(sample, {})
        percentage_called = linkage_info.get("percentage_called", None)

        # Higher percentage_called should win, so negate it for min()
        # Missing values sort after valid values
        missing_pct = percentage_called is None
        pct_key = 0 if percentage_called is None else -percentage_called

        return (
            missing_pct,     # False (has value) sorts before True (missing)
            pct_key,         # larger percentage_called first
            num_contigs,     # fewer contigs first
            -total_len,      # longer assembly first
            sample,          # alphabetical
        )

    if not samples_info:
        return None

    best = min(samples_info, key=sort_key)
    return best



def resolve_sample_paths(sample, species_value, outdir, master_paths, phoenix_path, bactopia_path):
    """
    Build paths for a sample:
      - start with defaults (empty fastqs/annotation, default assembly path)
      - fill phoenix or bactopia if provided
      - override with master_paths if present for the sample
    """
    # Default assembly path
    assembly = get_default_assembly_path(outdir, species_value, sample)

    # Default fastq/annotation: empty
    fastq_1 = ""
    fastq_2 = ""
    annotation = ""

    # Phoenix / Bactopia (only one should be used, as Nextflow chooses)
    if phoenix_path:
        fastq_1, fastq_2, annotation = build_paths_from_phoenix(sample, phoenix_path)
    elif bactopia_path:
        fastq_1, fastq_2, annotation = build_paths_from_bactopia(sample, bactopia_path)

    # master_paths overrides everything per sample
    if sample in master_paths:
        mp = master_paths[sample]
        if mp.get("fastq_1"):
            fastq_1 = mp["fastq_1"]
        if mp.get("fastq_2"):
            fastq_2 = mp["fastq_2"]
        if mp.get("annotation"):
            annotation = mp["annotation"]
        if mp.get("assembly"):
            assembly = mp["assembly"]

    return {
        "sample": sample,
        "fastq_1": fastq_1,
        "fastq_2": fastq_2,
        "annotation": annotation,
        "assembly": assembly,
        "species": species_value,
    }


def process_threshold(
    species,
    threshold,
    groups_dir,
    outdir,
    master_paths,
    phoenix_path,
    bactopia_path,
    metrics_cache,
    linkages_by_sample,
):
    """
    For a single threshold:
      - Read {species}-groups_HC<threshold>.csv
      - For each unique group_name:
          - expand group_samples into rows
          - compute per-sample paths
          - choose reference sample by contigs/length/name
          - write poodle_manifest_HC<threshold>.csv in outdir
    """
    group_filename = f"{species}-groups_HC{threshold}.csv"
    group_path = os.path.join(groups_dir, group_filename)

    if not os.path.exists(group_path):
        print(f"[WARN] Group file not found for threshold {threshold}: {group_path}", file=sys.stderr)
        return

    df = pd.read_csv(group_path)

    # Filter: keep only groups with length > 1
    if "group_length" in df.columns:
        df = df[df["group_length"] > 1]

    # Map group_name -> (species_name, list of sample_ids)
    groups = {}
    for _, row in df.iterrows():
        group_name = str(row["group_name"])
        species_value = str(row["species"]) if "species" in row and not pd.isna(row["species"]) else species
        samples_str = str(row["group_samples"])
        sample_ids = [s.strip() for s in samples_str.split(",") if s.strip()]
        # If group_name appears multiple times, we just overwrite; content should be identical
        groups[group_name] = (species_value, sample_ids)

    manifest_rows = []

    for group_name, (species_value, sample_ids) in groups.items():
        # Collect info for reference selection
        samples_info = []
        resolved_samples = []

        for sample in sample_ids:
            info = resolve_sample_paths(
                sample=sample,
                species_value=species_value,
                outdir=outdir,
                master_paths=master_paths,
                phoenix_path=phoenix_path,
                bactopia_path=bactopia_path,
            )
            resolved_samples.append(info)
            samples_info.append({"sample": info["sample"], "assembly": info["assembly"]})

        ref_sample_info = choose_reference_sample(
            samples_info,
            metrics_cache,
            linkages_by_sample=linkages_by_sample,
        )
        reference_path = ref_sample_info["assembly"] if ref_sample_info else ""

        for info in resolved_samples:
            manifest_rows.append(
                {
                    "sample": info["sample"],
                    "fastq_1": info["fastq_1"],
                    "fastq_2": info["fastq_2"],
                    "annotation": info["annotation"],
                    "assembly": info["assembly"],
                    "cluster_id": group_name,
                    "species": info["species"],
                    "reference": reference_path,
                }
            )

    if not manifest_rows:
        print(f"[WARN] No rows produced for threshold {threshold}", file=sys.stderr)
        return

    os.makedirs('poodle_samplesheets', exist_ok=True)
    manifest_path = os.path.join('poodle_samplesheets', f"{species}_poodle_manifest_HC{threshold}.csv")
    out_df = pd.DataFrame(manifest_rows)
    out_df.to_csv(manifest_path, index=False)
    print(f"[INFO] Wrote manifest for threshold {threshold}: {manifest_path}", file=sys.stderr)


def main():
    args = parse_args()

    thresholds = [t.strip() for t in args.thresholds.split(",") if t.strip()]
    if not thresholds:
        print("[ERROR] No valid thresholds provided in --thresholds.", file=sys.stderr)
        sys.exit(1)

    master_paths = load_master_paths(args.master_paths)
    metrics_cache = {}
    linkages_by_sample = load_linkages(args.linkages)

    for thr in thresholds:
        process_threshold(
            species=args.species,
            threshold=thr,
            groups_dir=args.groups,
            outdir=args.outdir,
            master_paths=master_paths,
            phoenix_path=args.phoenix_path,
            bactopia_path=args.bactopia_path,
            metrics_cache=metrics_cache,
            linkages_by_sample=linkages_by_sample,
        )


if __name__ == "__main__":
    main()
