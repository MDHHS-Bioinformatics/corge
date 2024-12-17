#!/usr/bin/env python

import pandas as pd
import os
import sys
import argparse


def main(argv=None):
    #Use sys.argv if argv is not passed
    if argv is None:
        argv = sys.argv[1:]
    parser = argparse.ArgumentParser(
        description="Get the best partition per species "
    )
    parser.add_argument(
        'new_assemblies', type=str, help="Path to the new assemblies file"
    )
    parser.add_argument(
        'new_reads', type=str, help="Path to the new reads file"
    )
    parser.add_argument(
        'master_manifest', type=str, help="Path to the master manifest"
    )
    #use the args
    args = parser.parse_args(argv)
    #load the assemblies
    df_assemblies = pd.read_csv(args.new_assemblies)
    #load in the reads manifest
    df_reads = pd.read_csv(args.new_reads)
    #join the reads and assemblies dataframes
    df_new_samples = pd.merge(df_reads, df_assemblies, on='sample')
    #read in the master manifest
    df_master_manifest = pd.read_csv(args.master_manifest)
    #now join the dataframes to add the new samples
    df_updated = pd.concat([df_master_manifest,df_new_samples],ignore_index=True)
    #save the combined csv
    df_updated.to_csv('updated_manifest.csv',index=False)
if __name__ == "__main__":
    main()
