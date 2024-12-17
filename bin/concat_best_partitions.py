#!/usr/bin/env python

import argparse
import pandas as pd
import sys
import os


#create function to read patirions
def read_partions(path):
    df = pd.read_csv(path)
    return df

def main(argv=None):
    #Use sys.argv if argv is not passed
    if argv is None:
        argv = sys.argv[1:]
    parser = argparse.ArgumentParser(
        description="Concatenate all the partions in a director"
    )
    parser.add_argument(
        'partitions_dir',type=str,help= 'Path to a directory with partitions'
    )
    # parser.add_argument(
    #     'species',type=str,help='Name of species'
    # )
    args = parser.parse_args(argv)
    #create a list to store all the
    dfs_list = []
    #iterate over all the files in the directory
    for file in os.listdir(args.partitions_dir):
        #create path
        file_path = os.path.join(args.partitions_dir,file)
        #read in the dataframes
        df = read_partions(file_path)
        #add it to the list
        dfs_list.append(df)
    #check if there is more than one df
    if len(dfs_list) >1 :
        df_merged = pd.concat(dfs_list)
        df_merged.to_csv('newest_partitions.csv',index=False)
    elif len(dfs_list) == 1:
        df.to_csv('newest_partitions.csv',index=False)
    else:
        print("No new partitions were created")

    #deduplicated_df.to_csv(f"{species}_results_alleles.tsv",index=False,sep='\t')
if __name__ == "__main__":
    main()
