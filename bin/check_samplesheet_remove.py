#!/usr/bin/env python


"""Provide a command line tool to validate and transform tabular samplesheets."""


import argparse
import csv
import logging
import sys
from pathlib import Path

logger = logging.getLogger()

class RowChecker:
    """
    Define a service that can validate and transform each given row.

    Attributes:
        modified (list): A list of dicts, where each dict corresponds to a previously
            validated and transformed row. The order of rows is maintained.
    """

    def __init__(
        self,
        sample_col="sample",
        species_col="species",
        **kwargs,
    ):
        """
        Initialize the row checker with the expected column names.
        """
        super().__init__(**kwargs)
        self._sample_col = sample_col
        self._species_col = species_col
        self._seen = set()
        self.modified = []

    def validate_and_transform(self, row):
        """
        Perform all validations on the given row and insert the read pairing status.
        """
        self._validate_sample(row)
        self._validate_species(row)
        self._seen.add((row[self._sample_col], row[self._species_col]))
        self.modified.append(row)

    def _validate_sample(self, row):
        """Assert that the sample name exists and convert spaces to underscores."""
        if not row[self._sample_col].strip():
            raise AssertionError("Sample input is required.")
        row[self._sample_col] = row[self._sample_col].replace(" ", "_")

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
    return csv.Sniffer().sniff(peek)


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

            sample,species
            ISO1,Escherichia_coli
            ISO3,Acinetobacter baumannii

    """
    with file_in.open(newline="", encoding="utf-8-sig") as in_handle:
        reader = csv.DictReader(in_handle, dialect=sniff_format(in_handle))

        required = {"sample", "species"}
        if not required.issubset(reader.fieldnames or []):
            logger.critical(
                f"Missing required columns: {required}. Found: {reader.fieldnames}"
            )
            sys.exit(1)

        checker = RowChecker()
        for i, row in enumerate(reader):
            try:
                checker.validate_and_transform(row)
            except AssertionError as error:
                logger.critical(f"{str(error)} On line {i + 2}.")
                sys.exit(1)


        header = list(reader.fieldnames)

    with file_out.open(mode="w", newline="", encoding="utf-8") as out_handle:
        writer = csv.DictWriter(out_handle, fieldnames=header, delimiter=",")
        writer.writeheader()
        writer.writerows(checker.modified)
        
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
