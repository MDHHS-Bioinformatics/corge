#!/usr/bin/env python


"""Provide a command line tool to validate and transform tabular samplesheets."""


import argparse
import csv
import logging
import sys
from collections import Counter
from pathlib import Path

logger = logging.getLogger()


from pathlib import Path
from collections import Counter

class RowChecker:
    """
    Define a service that can validate and transform each given row.

    Attributes:
        modified (list): A list of dicts, where each dict corresponds to a previously
            validated and transformed row. The order of rows is maintained.
    """

    VALID_ASSEMBLY_FORMATS = (
        ".fasta", 
        ".fna", 
        ".fa",
        ".fas"
    )

    def __init__(
        self,
        sample_col="sample",
        assembly_col="assembly",
        species_col="species",
        **kwargs,
    ):
        """
        Initialize the row checker with the expected column names.
        """
        super().__init__(**kwargs)
        self._sample_col = sample_col
        self._assembly_col = assembly_col
        self._species_col = species_col
        self._seen = set()
        self.modified = []

    def validate_and_transform(self, row):
        """
        Perform all validations on the given row and insert the read pairing status.
        """
        self._validate_sample(row)
        self._validate_assembly(row)
        self._validate_species(row)
        self._seen.add((row[self._sample_col], row[self._assembly_col]))
        self.modified.append(row)

    def _validate_sample(self, row):
        """Assert that the sample name exists and convert spaces to underscores."""
        if not row[self._sample_col].strip():
            raise AssertionError("Sample input is required.")
        row[self._sample_col] = row[self._sample_col].replace(" ", "_")

    def _validate_assembly(self, row):
        """Assert that the assembly entry is non-empty and has the right format."""
        assembly = row.get(self._assembly_col, "")
        if assembly and not any(assembly.endswith(ext) for ext in self.VALID_ASSEMBLY_FORMATS):
            raise AssertionError(
                f"The Assembly file has an unrecognized extension: {assembly}\n"
                f"It should be one of: {', '.join(self.VALID_ASSEMBLY_FORMATS)}"
            )

    def _validate_species(self, row):
        """Assert that the inputted species name is formatted correctly."""
        species = row.get(self._species_col, "")
        row[self._species_col] = species.replace(' ', '_')


def read_head(handle, num_lines=10):
    """Read the specified number of lines from the current position in the file."""
    lines = []
    for idx, line in enumerate(handle):
        if idx == num_lines:
            break
        lines.append(line)
    return "".join(lines)


def sniff_format(handle):
    """
    Detect the tabular format.

    Args:
        handle (text file): A handle to a `text file`_ object. The read position is
        expected to be at the beginning (index 0).

    Returns:
        csv.Dialect: The detected tabular format.

    .. _text file:
        https://docs.python.org/3/glossary.html#term-text-file

    """
    peek = read_head(handle)
    handle.seek(0)
    sniffer = csv.Sniffer()
    if not sniffer.has_header(peek):
        logger.critical("The given sample sheet does not appear to contain a header.")
        sys.exit(1)
    dialect = sniffer.sniff(peek)
    return dialect


def check_samplesheet(file_in, file_out):
    """
    Validate the general shape of the table, expected columns, and each row. 

    Args:
        file_in (pathlib.Path): The given tabular samplesheet. The format can be either
            CSV, TSV, or any other format automatically recognized by ``csv.Sniffer``.
        file_out (pathlib.Path): Where the validated and transformed samplesheet should
            be created; always in CSV format.

    Example:
        This function checks that the samplesheet follows the following structure:

            sample,assembly,species
            ISO1,/path/iso1.fasta,Escherichia_coli
            ISO2,/path/iso2.fasta,Escherichia coli
            ISO3/path/iso3.fasta,Acinetobacter baumannii
            ISO4,/path/iso4.fasta,Acinetobacter baumannii

    """

    with file_in.open(newline="") as in_handle:
        reader = csv.DictReader(in_handle, dialect=sniff_format(in_handle))
        checker = RowChecker()
        for i, row in enumerate(reader):
            try:
                checker.validate_and_transform(row)
            except AssertionError as error:
                logger.critical(f"{str(error)} On line {i + 2}.")
                sys.exit(1)
    header = list(reader.fieldnames)
    with file_out.open(mode="w", newline="") as out_handle:
        writer = csv.DictWriter(out_handle, header, delimiter=",")
        writer.writeheader()
        for row in checker.modified:
            writer.writerow(row)


def parse_args(argv=None):
    """Define and immediately parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Validate and transform a tabular samplesheet.",
        epilog="Example: python check_samplesheet.py samplesheet.csv samplesheet.valid.csv",
    )
    parser.add_argument(
        "file_in",
        metavar="FILE_IN",
        type=Path,
        help="Tabular input samplesheet in CSV or TSV format.",
    )
    parser.add_argument(
        "file_out",
        metavar="FILE_OUT",
        type=Path,
        help="Transformed output samplesheet in CSV format.",
    )
    parser.add_argument(
        "-l",
        "--log-level",
        help="The desired log level (default WARNING).",
        choices=("CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"),
        default="WARNING",
    )
    return parser.parse_args(argv)


def main(argv=None):
    """Coordinate argument parsing and program execution."""
    args = parse_args(argv)
    logging.basicConfig(level=args.log_level, format="[%(levelname)s] %(message)s")
    if not args.file_in.is_file():
        logger.error(f"The given input file {args.file_in} was not found!")
        sys.exit(2)
    args.file_out.parent.mkdir(parents=True, exist_ok=True)
    check_samplesheet(args.file_in, args.file_out)


if __name__ == "__main__":
    sys.exit(main())
