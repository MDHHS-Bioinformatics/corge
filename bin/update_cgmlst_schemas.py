#!/usr/bin/env python

import os
import argparse
import pandas as pd

def update_cgmlst_schemas(db_path: str, species_schemas_csv: str, output_csv: str = "cgmlst_schemas_list.csv"):
    """
    Generate or update a CSV mapping species to their cgMLST schema directory path.
    If the output CSV already exists, merge new data with existing entries.

    Parameters:
        db_path (str): Path to the base directory containing cgMLST schema directories.
        species_schemas_csv (str): Path to CSV file mapping species to schema.
        output_csv (str): Path to save the output CSV. Defaults to 'cgmlst_schemas_list.csv'.
    """
    # Load species-schemas CSV
    df = pd.read_csv(species_schemas_csv) 

    # Get the schema names from subdirectories in db_path
    available_schemas = {
        name for name in os.listdir(db_path)
        if os.path.isdir(os.path.join(db_path, name))
    }
    
    # Filter rows where schema is a subdirectory of db_path
    filtered_df = df[df['schema'].isin(available_schemas)].copy()
    filtered_df['cgmlst_dir'] = filtered_df['schema'].apply(lambda s: os.path.join(db_path, s))
    new_df = filtered_df[['species', 'cgmlst_dir']]

    if os.path.exists(output_csv):
        # Load existing file and merge
        existing_df = pd.read_csv(output_csv)
        combined_df = pd.concat([existing_df, new_df], ignore_index=True)
        combined_df.drop_duplicates(subset=['species', 'cgmlst_dir'], inplace=True)
    else:
        combined_df = new_df
    print(combined_df)
    # Save the merged or new file
    combined_df.to_csv(output_csv, index=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Update cgMLST schema list for species.")
    parser.add_argument("db_path", help="Directory containing cgMLST schemas")
    parser.add_argument("species_schemas_csv", help="CSV mapping species to schema")
    parser.add_argument("output_csv", nargs='?', default="cgmlst_schemas_list.csv", help="Output CSV file (optional)")

    args = parser.parse_args()
    update_cgmlst_schemas(args.db_path, args.species_schemas_csv, args.output_csv)
    