#!/usr/bin/env python

import os
import sys
import argparse

def clean_fasta_headers(input_path, output_path):
    """
    Cleans the headers in a FASTA file by removing everything after the first '.'
    and saves the updated sequences to a new FASTA file.

    :param input_path: Path to the input FASTA file.
    :param output_path: Path to save the modified FASTA file.
    """
    output_path = f"{output_path}_snps_alignment.fasta"
    with open(input_path, 'r') as infile, open(output_path, 'w') as outfile:
        for line in infile:
            if line.startswith('>'):
                # Remove file extensions from headers
                new_line = line.split('.')[0]
                outfile.write(f"{new_line}\n")
            else:
                # Write the sequence lines as-is
                outfile.write(line)

def main(argv=None):
    """Coordinate argument parsing and program execution."""
    parser = argparse.ArgumentParser(
        description="Clean FASTA headers by removing everything after the first '.' and save to a new file."
    )
    parser.add_argument(
        "input_file", type=str, help="Path to the input FASTA file."
    )
    parser.add_argument(
        "output_file", type=str, help="Path to save the modified FASTA file."
    )
    args = parser.parse_args(argv)

    # Call the function with provided arguments
    clean_fasta_headers(args.input_file, args.output_file)

if __name__ == "__main__":
    sys.exit(main())
