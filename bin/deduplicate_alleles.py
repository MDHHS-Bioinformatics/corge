#!/usr/bin/env python

import argparse
import pandas as pd
import sys

def main(argv=None):
    #Use sys.argv if argv is not passed
    if argv is None:
        argv = sys.argv[1:]
    parser = argparse.ArgumentParser(
        description="Deduplicate alleles table if a sample appears more than once"
    )
    parser.add_argument(
        'alleles_table',type=str,help= 'Path to the alleles table'
    )
    parser.add_argument(
        'species',type=str,help='Name of species'
    )
    args = parser.parse_args(argv)
    #read the dataframe
    df = pd.read_csv(args.alleles_table,sep='\t')
    # Deduplicate the DataFrame based on the 'FILE' column
    deduplicated_df = df.drop_duplicates(subset='FILE', keep='last')
    # Format species argument
    species = args.species.replace(' ', '_')
    print('made it to the end')
    deduplicated_df.to_csv(f"results_alleles.tsv",index=False,sep='\t')
if __name__ == "__main__":
    main()
