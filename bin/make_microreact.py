#!/usr/bin/env python3
import os
import sys
import json
import base64
import argparse
from datetime import datetime


# -----------------------------
# Helper: encode file to base64
# -----------------------------
def encode_file(file_path):
    try:
        with open(file_path, "rb") as file:
            return base64.b64encode(file.read()).decode('utf-8')
    except FileNotFoundError:
        print(f"Error: File not found - {file_path}")
        sys.exit(1)


# -----------------------------
# Core: create .microreact file
# -----------------------------
def create_microreact_file(species, partition_string, partitions_tsv, reportree_tree, mash_tree, microreact_template, output_file):
    # Convert relative paths to absolute paths
    microreact_template = os.path.abspath(microreact_template)
    partitions_tsv = os.path.abspath(partitions_tsv)
    reportree_tree = os.path.abspath(reportree_tree)
    mash_tree = os.path.abspath(mash_tree)
    output_file = os.path.abspath(output_file)

    # Load template JSON
    try:
        with open(microreact_template, 'r') as f:
            microreact_data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Template file not found - {microreact_template}")
        sys.exit(1)
    except json.JSONDecodeError:
        print("Error: Failed to decode JSON from the template file.")
        sys.exit(1)

    # Encode new CSV and tree files into Base64
    partitions_tsv_blob = encode_file(partitions_tsv)
    reportree_tree_blob = encode_file(reportree_tree)
    mash_tree_blob = encode_file(mash_tree)

    # Get file sizes
    partitions_tsv_size = os.path.getsize(partitions_tsv)
    report_tree_size = os.path.getsize(reportree_tree)
    mash_tree_size = os.path.getsize(mash_tree)

    # Split and clean the string of numbers
    partitions = [num.strip() for num in partition_string.split(',') if num.strip()]

    # Build the formatted field names
    field_names = [f"single-{num}x1.0" for num in partitions]

    # Create the columns list
    columns = [{"field": "sequence", "fixed": False}]
    columns.extend({"field": f, "fixed": False} for f in field_names)

    # Update JSON with file data
    microreact_data['files']['ozx7'] = {
        "blob": f"data:text/csv;base64,{partitions_tsv_blob}",
        "format": "text/csv",
        "id": "ozx7",
        "name": os.path.basename(partitions_tsv),
        "size": partitions_tsv_size,
        "type": "data"
    }

    microreact_data['files']['lwvj'] = {
        "blob": f"data:application/octet-stream;base64,{reportree_tree_blob}",
        "format": "text/x-nh",
        "id": "lwvj",
        "name": os.path.basename(reportree_tree),
        "size": report_tree_size,
        "type": "tree"
    }

    microreact_data['files']['07gg'] = {
        "blob": f"data:application/octet-stream;base64,{mash_tree_blob}",
        "format": "text/x-nh",
        "id": "07gg",
        "name": os.path.basename(mash_tree),
        "size": mash_tree_size,
        "type": "tree"
    }

    # Update metadata table
    microreact_data['tables']['table-1'] = {
        "displayMode": "cosy",
        "hideUnselected": False,
        "title": "HC-partitions",
        "paneId": "table-1",
        "columns": columns,
        "file": "ozx7"
    }

    # Update trees with partition-based blocks
    microreact_data.setdefault('trees', {})
    for tree_key in ["tree-1", "tree-2"]:
        microreact_data['trees'].setdefault(tree_key, {})
        microreact_data['trees'][tree_key]['blocks'] = field_names

    # Update meta info
    current_date = datetime.now().strftime("%Y-%m-%d")
    current_timestamp = datetime.now().isoformat()
    old_meta = microreact_data.get('meta', {})

    microreact_data['meta'] = {
        "name": f"{species}_{current_date}",
        "image": old_meta.get("image", ""),
        "timestamp": current_timestamp,
        "description": "MashTree, core genome distance tree and cluster partitions"
    }

    # Save output file
    try:
        with open(output_file, 'w') as f:
            json.dump(microreact_data, f, indent=2)
        print(f"✅ New .microreact file created and saved as: {output_file}", flush=True)
    except Exception as e:
        print(f"❌ Error: Failed to save the output file - {output_file}. Error: {e}")


# -----------------------------
# Command-line interface
# -----------------------------
def main():
    parser = argparse.ArgumentParser(
        description="Generate a Microreact JSON file with partitions and tree data."
    )
    parser.add_argument("--species", required=True, help="Species name (used in output metadata)")
    parser.add_argument("--partitions", required=True, help="Comma-separated partition values (e.g. '10,15,20,40')")
    parser.add_argument("--partitions-tsv", required=True, help="Path to the partitions TSV file")
    parser.add_argument("--reportree-tree", required=True, help="Path to the ReporTree Newick tree file")
    parser.add_argument("--mash-tree", required=True, help="Path to the Mash tree file")
    parser.add_argument("--template", required=True, help="Path to the Microreact JSON template")
    parser.add_argument("--output", required=True, help="Output file path (.microreact)")

    args = parser.parse_args()

    create_microreact_file(
        species=args.species,
        partition_string=args.partitions,
        partitions_tsv=args.partitions_tsv,
        reportree_tree=args.reportree_tree,
        mash_tree=args.mash_tree,
        microreact_template=args.template,
        output_file=args.output
    )


if __name__ == "__main__":
    main()
