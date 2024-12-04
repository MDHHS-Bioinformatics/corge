#!/usr/bin/env python

import argparse
import pandas as pd
import sys

def main(argv=None):
    # Use sys.argv if argv is not passed
    if argv is None:
        argv = sys.argv[1:]

    parser = argparse.ArgumentParser(
        description="Subset LIMS datasheet by a specified species"
    )
    parser.add_argument(
        'lims_data', type=str, help="Path to the LIMS datasheet"
    )
    parser.add_argument(
        'species', type=str, help="Name of species to subset the dataframe by"
    )
    args = parser.parse_args(argv)

    # Read the dataframe
    df = pd.read_csv(args.lims_data)
    # Format species column
    df['species'] = [species.replace(' ', '_') for species in df['species']]
    # Format species argument
    species = args.species.replace(' ', '_')
    # Subset the dataframe by species
    subset_df = df[df['species'] == species]
    # Save the subsetted dataframe to CSV
    subset_df.to_csv(f"{species}_lims.csv", index=False)

if __name__ == "__main__":
    main()
