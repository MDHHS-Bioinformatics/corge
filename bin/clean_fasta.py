#!/usr/bin/env python

import os
import sys
import argparse

def clean_fasta_headers(input_path, output_path):
    """
    Cleans the headers in a FASTA file by removing everything after the first '.'
    and saves the updated sequences to a new FASTA file,
    skipping the first sequence record.
    """
    output_path = f"{output_path}_snps_alignment.fasta"

    with open(input_path, 'r') as infile, open(output_path, 'w') as outfile:
        write_record = False  # Start writing only after the first record
        for line in infile:
            if line.startswith('>'):
                if not write_record:
                    # First header encountered — skip this entire record
                    write_record = True
                    skip_record = True
                else:
                    skip_record = False
                    # Clean header and write
                    new_line = line.split('.')[0]
                    outfile.write(f"{new_line}\n")
            else:
                # Write only if we’re not skipping
                if not skip_record:
                    outfile.write(line)

def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Clean FASTA headers by removing everything after the first '.' and save to a new file, skipping the first sequence."
    )
    parser.add_argument("input_file", type=str, help="Path to the input FASTA file.")
    parser.add_argument("output_file", type=str, help="Path to save the modified FASTA file.")
    args = parser.parse_args(argv)

    clean_fasta_headers(args.input_file, args.output_file)

if __name__ == "__main__":
    sys.exit(main())
