#!/usr/bin/env python

import argparse
import pandas as pd
import sys


#format the functions to properly process data
def extract_numeric_partition(partition):
    # This assumes that the partition format is always 'single-<number>x1.0'
    return int(partition.split('-')[1].split('x')[0])
def generate_partitions(new_samples_df,filtered_df,partitions_summary_df,target_partitions):
    # Initialize results output for each sample
    results = {}
    # Loop to analyze every sample in the species dataframe
    for sample_id in new_samples_df['sample']:
        # Initialize dataframes and max length
        best_partition_df = pd.DataFrame()
        best_target_partition_df = pd.DataFrame()
        max_cluster_length = -1
        # Identify the best target partition (the one with the highest number of samples)
        for partition in target_partitions:
            partition_df = filtered_df[filtered_df['partition'] == partition].copy()
            cluster_row = partition_df[partition_df['samples'].str.contains(fr'\b{sample_id}\b', regex=True)].copy()

            if not cluster_row.empty:
                cluster_row = cluster_row.sort_values(by=['cluster_length', 'partition_numeric'], ascending=[False,True])
                current_max = cluster_row['cluster_length'].max()
                if current_max > max_cluster_length:
                    max_cluster_length = current_max
                    best_target_partition = cluster_row.loc[cluster_row['cluster_length'].idxmax(), 'partition']
                    best_target_partition_df = cluster_row[cluster_row['partition'] == best_target_partition].copy()
        # Choose the best partition depending on number of samples per cluster, with preference to target partition (ideally >= 10), or alternative partitions with max 25 samples
        if max_cluster_length >= 10:
            best_partition_df = best_target_partition_df.copy()
        elif 1 < max_cluster_length < 10:
            alternative_cluster_candidates = partitions_summary_df[partitions_summary_df['samples'].str.contains(fr"\b{sample_id}\b") & (partitions_summary_df['cluster_length'].between(10, 25))]
            if not alternative_cluster_candidates.empty:
                alternative_cluster_candidates = alternative_cluster_candidates.sort_values(by=['cluster_length', 'partition_numeric'], ascending=[True,True])
                best_partition_df = alternative_cluster_candidates.iloc[[0]].copy()  # Keep as DataFrame
            else:
                # Find the cluster with the highest length that contains the sample_id
                highest_cluster_candidate = partitions_summary_df[
                    (partitions_summary_df['samples'].str.contains(fr"\b{sample_id}\b")) &
                    (partitions_summary_df['cluster_length'] <= 10)
                ]
                if not highest_cluster_candidate.empty:
                    highest_cluster_candidate = highest_cluster_candidate.sort_values(by=['cluster_length', 'partition_numeric'], ascending=[False,True]).head(1)
                    best_partition_df = highest_cluster_candidate.copy()
                else:
                    best_partition_df = best_target_partition_df.copy()
        if not best_partition_df.empty and not best_target_partition_df.empty and best_target_partition_df['cluster_length'].max() > 1:
            # Make name for the cluster that includes HC partition
            best_partition_df.loc[:, 'partition_cluster_name'] = (best_partition_df['partition'] + '_' + best_partition_df['cluster']).str.replace('single-', 'HC', regex=True).str.replace('x1.0_cluster_', '-C', regex=True)
            best_target_partition_df.loc[:, 'partition_cluster_name'] = (best_target_partition_df['partition'] + '_' + best_target_partition_df['cluster']).str.replace('single-', 'HC', regex=True).str.replace('x1.0_cluster_', '-C', regex=True)
            results[sample_id] = {
                'best_partition_df': best_partition_df,
                'target_partition_df': best_target_partition_df
            }
    return results

def select_best_reference_per_cluster_no_previous_results(master_species_df,target_partition_df):
    #choose reference for SNIPPY based on the target partitions (in case the alternative partition introduces a biased reference)
    sample_list_best_target = [item for sublist in target_partition_df['samples'].str.split(',') for item in sublist]
    sample_best_target_df = master_species_df[master_species_df['sample'].isin(sample_list_best_target)].copy()
    #Find the row with the minimum number of scaffolds
    sample_best_target_df['scaffolds_over_500bp_count'] = pd.to_numeric(sample_best_target_df['scaffolds_over_500bp_count'],errors="coerce")
    #for simplicity use just the first assembly path from each row as the reference path to use
    assembly_path = sample_best_target_df['assembly'].iloc[0]
    #get the cluster name
    cluster_name = target_partition_df['partition_cluster_name'].values[0]
    cluster_manifest = create_cluster_manifest(sample_best_target_df,assembly_path,cluster_name)
    return cluster_manifest

def select_best_reference_per_cluster(master_species_df,target_partition_df):
    #choose reference for SNIPPY based on the target partitions (in case the alternative partition introduces a biased reference)
    sample_list_best_target = [item for sublist in target_partition_df['samples'].str.split(',') for item in sublist]
    sample_best_target_df = master_species_df[master_species_df['sample'].isin(sample_list_best_target)].copy()
    #Find the row with the minimum number of scaffolds
    sample_best_target_df['scaffolds_over_500bp_count'] = pd.to_numeric(sample_best_target_df['scaffolds_over_500bp_count'],errors="coerce")
    min_scaffold_row = sample_best_target_df.loc[sample_best_target_df['scaffolds_over_500bp_count'].idxmin()]
    #get the assembly path from the row with the minimum number of scaffolds
    assembly_path = min_scaffold_row['assembly']
    print(assembly_path)
    #get the cluster name
    cluster_name = target_partition_df['partition_cluster_name'].values[0]
    cluster_manifest = create_cluster_manifest(sample_best_target_df,assembly_path,cluster_name)
    return cluster_manifest

def create_cluster_manifest(samples_df,assembly_path, cluster_name):
    #drop the scaffolds column
    if "scaffolds_over_500bp_count" in samples_df.columns:
        samples_df.drop(columns='scaffolds_over_500bp_count', inplace=True)
    #add the reference column
    samples_df['reference'] = assembly_path
    #add the cluster id column
    samples_df['cluster_id'] = cluster_name
    #reformat the columns order
    samples_df = samples_df[["sample","fastq_1","fastq_2","gff","assembly","reference","cluster_id","species"]]

    return samples_df

def process_cluster_info(results,master_manifest_df, previous_results ='True', output_csv_path="test.csv"):
    #store all the create dfs
    cluster_manifest_list = []
    #iterate over the results
    for sample_id, partition_info in results.items():
        best_partition_df = partition_info['best_partition_df']
        target_partition_df = partition_info['target_partition_df']  # Used for SNIPPY to identify reference
        # make sure that there's actually a value in the variable
        if not target_partition_df.empty:
            if previous_results == 'False':
                current_cluster_manifest = select_best_reference_per_cluster_no_previous_results(master_manifest_df,target_partition_df)
            else:
                current_cluster_manifest = select_best_reference_per_cluster(master_manifest_df,target_partition_df)
            #save each cluster manifest to the list if it doesn't already exist
            if not any(current_cluster_manifest.equals(df) for df in cluster_manifest_list):
                cluster_manifest_list.append(current_cluster_manifest)
    # Concatenate all the cluster manifests if there are multiple, or use the single one
    if cluster_manifest_list:
        if len(cluster_manifest_list) > 1:
            final_cluster_manifest = pd.concat(cluster_manifest_list, ignore_index=True)
        else:
            final_cluster_manifest = cluster_manifest_list[0]

        # Store to a CSV file
        final_cluster_manifest.to_csv(output_csv_path, index=False)
        print(f"Cluster manifest saved to {output_csv_path}")
    else:
        print("No cluster manifests were generated.")
    return cluster_manifest_list

def main(argv=None):
    #Use sys.argv if argv is not passed
    if argv is None:
        argv = sys.argv[1:]
    parser = argparse.ArgumentParser(
        description="Get the best partition per species "
    )
    parser.add_argument(
        'reportree_partitions', type=str, help="Path to the reportree partitions summary file"
    )
    parser.add_argument(
        'master_manifest', type=str, help="Path to the master manifest"
    )
    parser.add_argument(
        'manifest_new_assemblies', type=str, help="Path to the assemblies manifest"
    )
    parser.add_argument(
        'scheme_available', type=str, help="Scheme availability for the species being analyzed (True or False)"
    )
    parser.add_argument(
        'file_output', type=str, help="File name for the partitions"
    )
    parser.add_argument(
        'previous_results', type=str, help='Are there previous results being used (Bool)'
    )
    #use the args
    args = parser.parse_args(argv)

    #read in the ReporTree partitions summary
    partitions_summary_df = pd.read_csv(args.reportree_partitions,sep='\t')
    #convert partitions to numeric
    partitions_summary_df['partition_numeric'] = partitions_summary_df['partition'].apply(extract_numeric_partition)
    #use the scheme_avaiable argument to determine the target partitions
    scheme_available = args.scheme_available
    #convert to boolean true or false
    bool_value = {'true': True, 'false': False}.get(scheme_available.lower(), None)
    #set target partitions (0-40) for cgMLST or 100 for Parsnp)
    target_partitions = [f"single-{i}x1.0" for i in range(41 if bool_value==True else 101)]
    #filter the partitions summary table based on the target partitions
    filtered_df = partitions_summary_df[partitions_summary_df['partition'].isin(target_partitions)]
    #read in manifest file for the new samples
    new_samples_df = pd.read_csv(args.manifest_new_assemblies)
    #get the best partitions
    best_partitions = generate_partitions(new_samples_df,filtered_df,partitions_summary_df,target_partitions)
    #load in the updated master manifest
    master_updated_df = pd.read_csv(args.master_manifest)
    #create the summary file
    process_cluster_info(best_partitions,master_updated_df, args.previous_results, args.file_output,)

if __name__ == "__main__":
    main()
