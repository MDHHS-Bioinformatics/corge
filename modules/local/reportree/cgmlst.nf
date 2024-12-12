
process REPORTREE_CGMLST {
    tag "$meta.species"
    label 'process_medium'


    //conda "YOUR-TOOL-HERE"
    container "reportree_local_v2.5.3.sif"

    input:
    tuple val(meta), path(allele_table), path(lims_manifest) // path(master_manifest)

    output:
    //tuple val(meta), path("ReporTree*"), emit: results
    //tuple val(meta), path("ReporTree_align_profile.fasta"), emit: profile_fasta
    //tuple val(meta), path("ReporTree_align_profile.tsv"), emit: profile_tsv
    tuple val(meta), path("ReporTree_clean_missing_matrix.tsv"), emit: clean_missing_matrix
    tuple val(meta), path("ReporTree_clusterComposition.tsv"), emit: cluster_composition
    tuple val(meta), path("ReporTree_dist_hamming.tsv"), emit: dist_hamming
    tuple val(meta), path("ReporTree_flt_samples_matrix.tsv"), emit: flt_samples_matrix
    tuple val(meta), path("ReporTree_loci_report.tsv"), emit: loci_report
    tuple val(meta), path("ReporTree_loci_used.txt"), emit: loci_used
    tuple val(meta), path("ReporTree_metadata_w_partitions.tsv"), emit: metadata_w_partitions
    tuple val(meta), path("ReporTree_partitions_summary.tsv"), emit: partitions_summary
    tuple val(meta), path("ReporTree_partitions.tsv"), emit: partitions
    tuple val(meta), path("ReporTree_single_HC.nwk"), emit: single_HC
    tuple val(meta), path("ReporTree.log"), emit: log

    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    // tuple val(meta), path("*.bam"), emit: bam
    // TODO nf-core: List additional required output channels/values here
    //path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.prefix ?: "${meta.species}"

    """
    #mv $allele_table results_alleles.tsv
    echo $species
    reportree.py \
        --metadata $lims_manifest \
        --allele-profile $allele_table \
        --loci-called 0.95 \
        --method MSTreeV2 \
        --columns_summary_report st,specimen_source,patient_county,submitter_name,date,first_seq_date,last_seq_date,timespan_days,patient_age,patient_sex,patient_race \
        --metadata2report st \
        --analysis HC \
        --n_proc $task.cpus \

    """
}
