#!/usr/bin/env python

import argparse
from pathlib import Path
import pandas as pd


def update_cgmlst_schemas(
    db_path: str,
    species_schemas_csv: str,
    output_csv: str,
    prior_file: str | None = None,
):
    """
    Generate or update a CSV mapping species to cgMLST schema directory paths.

    The species_schemas_csv input should contain:

        species,schema

    where schema is the directory name inside:

        <db_path>/cgmlst_schemas/

    If prior_file is provided, it is appended and duplicates are removed.
    """

    db_path = Path(db_path)
    cgmlst_dir = db_path / "cgmlst_schemas"

    if not cgmlst_dir.exists():
        raise FileNotFoundError(f"cgMLST schema directory does not exist: {cgmlst_dir}")

    species_df = pd.read_csv(species_schemas_csv)

    required_cols = {"species", "schema"}
    missing_cols = required_cols - set(species_df.columns)
    if missing_cols:
        raise ValueError(
            f"Input CSV is missing required column(s): {', '.join(sorted(missing_cols))}"
        )

    available_schemas = {
        p.name
        for p in cgmlst_dir.iterdir()
        if p.is_dir()
    }

    new_df = species_df[species_df["schema"].isin(available_schemas)].copy()

    new_df["cgmlst_path"] = new_df["schema"].apply(
        lambda schema: str(cgmlst_dir / schema)
    )

    new_df = new_df[["species", "cgmlst_path"]]

    if prior_file:
        prior_path = Path(prior_file)

        if prior_path.exists() and prior_path.stat().st_size > 0:
            prior_df = pd.read_csv(prior_path)

            required_prior_cols = {"species", "cgmlst_path"}
            missing_prior_cols = required_prior_cols - set(prior_df.columns)
            if missing_prior_cols:
                raise ValueError(
                    f"Prior CSV is missing required column(s): "
                    f"{', '.join(sorted(missing_prior_cols))}"
                )

            prior_df = prior_df[["species", "cgmlst_path"]]
            combined_df = pd.concat([prior_df, new_df], ignore_index=True)
        else:
            combined_df = new_df
    else:
        combined_df = new_df

    combined_df = combined_df.dropna(subset=["species", "cgmlst_path"])

    combined_df = combined_df.drop_duplicates(
        subset=["species", "cgmlst_path"],
        keep="last",
    )

    combined_df = combined_df.sort_values(["species", "cgmlst_path"])

    output_path = Path(output_csv)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    combined_df.to_csv(output_path, index=False)

    print(combined_df)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Update cgMLST schema list for species."
    )

    parser.add_argument(
        "--db-path",
        required=True,
        help="Base database/output directory containing cgmlst_schemas/.",
    )

    parser.add_argument(
        "--species-schemas-csv",
        required=True,
        help="CSV mapping species to cgMLST schema directory names.",
    )

    parser.add_argument(
        "--prior-file",
        default=None,
        help="Optional previous cgMLST schemas CSV to append before removing duplicates.",
    )

    parser.add_argument(
        "--output-csv",
        default="updated/cgmlst_schemas.csv",
        help="Output CSV file.",
    )

    args = parser.parse_args()

    update_cgmlst_schemas(
        db_path=args.db_path,
        species_schemas_csv=args.species_schemas_csv,
        prior_file=args.prior_file,
        output_csv=args.output_csv,
    )
