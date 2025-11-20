#!/usr/bin/env python3

import re
import csv
import sys
from html.parser import HTMLParser
from urllib.request import urlopen

INDEX_URL = "https://www.cgmlst.org/ncs"


def normalize_for_match(s: str) -> str:
    """
    Make a species name comparable between CSV and HTML.
    Examples:
      'Bacillus anthracis cgMLST' -> 'bacillus_anthracis'
      'Bacillus_anthracis'        -> 'bacillus_anthracis'
    """
    s = s.strip().lower()
    s = s.replace("cgmlst", "")      # remove the suffix
    s = s.replace("spp.", "spp")     # normalize 'spp.' -> 'spp'
    # Turn any non-alphanumeric run into a single underscore
    s = re.sub(r"[^a-z0-9]+", "_", s)
    s = re.sub(r"_+", "_", s)
    return s.strip("_")


class SchemaLinkParser(HTMLParser):
    """
    HTML parser that extracts (href, text) pairs for links whose href
    contains '/ncs/schema/'.
    """

    def __init__(self):
        super().__init__()
        self.in_schema_link = False
        self.current_href = None
        self.current_text_chunks = []
        self.links = []  # list of (href, text)

    def handle_starttag(self, tag, attrs):
        if tag != "a":
            return
        attrs_dict = dict(attrs)
        href = attrs_dict.get("href", "")
        if "/ncs/schema/" in href:
            self.in_schema_link = True
            self.current_href = href
            self.current_text_chunks = []

    def handle_data(self, data):
        if self.in_schema_link:
            self.current_text_chunks.append(data)

    def handle_endtag(self, tag):
        if tag == "a" and self.in_schema_link:
            text = "".join(self.current_text_chunks).strip()
            self.links.append((self.current_href, text))
            # reset state
            self.in_schema_link = False
            self.current_href = None
            self.current_text_chunks = []


def scrape_schema_urls():
    """
    Scrape cgmlst.org/ncs and return:
      { normalized_name: allele_url }
    using only standard library.
    """
    with urlopen(INDEX_URL) as resp:
        html = resp.read().decode("utf-8", errors="replace")

    parser = SchemaLinkParser()
    parser.feed(html)

    mapping = {}
    for href, text in parser.links:
        # text is e.g. "Bacillus anthracis cgMLST"
        key = normalize_for_match(text)

        if href.startswith("http"):
            base = href.rstrip("/")
        else:
            base = "https://www.cgmlst.org" + href.rstrip("/")

        allele_url = base + "/alleles/"
        mapping[key] = allele_url

    print(f"Found {len(mapping)} schemas on cgMLST")
    print("First few keys:", list(mapping.keys())[:10])

    return mapping


def update_csv(input_csv, output_csv):
    # Read CSV into list-of-dicts
    with open(input_csv, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))

    if not rows:
        print("Input CSV is empty; nothing to do.")
        return

    schema_map = scrape_schema_urls()

    # Decide which column to use for matching
    header = rows[0].keys()
    if "schema_name_website" in header:
        match_col = "schema_name_website"
    elif "schema_name" in header:
        match_col = "schema_name"
    else:
        raise RuntimeError(
            "Could not find 'schema_name_website' or 'schema_name' column "
            f"in {input_csv}"
        )

    new_rows = []
    for row in rows:
        name_raw = row.get(match_col, "")
        key = normalize_for_match(str(name_raw))

        if key in schema_map:
            row["url_alleles"] = schema_map[key]
        else:
            print(
                f"WARNING: No schema found for: {name_raw} "
                f"(normalized: {key})"
            )
            # keep old URL if present
            # (if column missing, this just leaves it absent)
        new_rows.append(row)

    # Write updated CSV
    with open(output_csv, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=new_rows[0].keys())
        writer.writeheader()
        writer.writerows(new_rows)

    print(f"Updated CSV saved to {output_csv}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} INPUT_CSV OUTPUT_CSV")
        sys.exit(1)

    update_csv(sys.argv[1], sys.argv[2])
