process REPORTREE_PARSNP {
    tag "$meta.species"
    label 'process_high'

    container "reportree_local_v2.5.3.sif"

    input:
    tuple val(meta), path(snps_alignment_fasta)

    output:
    tuple val(meta), path("ReporTree_align_profile.fasta"), emit: profile_fasta
    tuple val(meta), path("ReporTree_align_profile.tsv"), emit: profile_tsv
    tuple val(meta), path("ReporTree_clean_missing_matrix.tsv"), emit: clean_missing_matrix
    tuple val(meta), path("ReporTree_clusterComposition.tsv"), emit: cluster_composition
    tuple val(meta), path("ReporTree_dist_hamming.tsv"), emit: dist_hamming
    //tuple val(meta), path("ReporTree_flt_samples_matrix.tsv"), emit: flt_samples_matrix
    //tuple val(meta), path("ReporTree_loci_report.tsv"), emit: loci_report
    tuple val(meta), path("ReporTree_loci_used.txt"), emit: loci_used
    // tuple val(meta), path("ReporTree_metadata_w_partitions.tsv"), emit: metadata_w_partitions
    // tuple val(meta), path("ReporTree_partitions_summary.tsv"), emit: partitions_summary
    tuple val(meta), path("ReporTree_partitions.tsv"), emit: partitions
    tuple val(meta), path("ReporTree_single_HC.nwk"), emit: single_HC
    tuple val(meta), path("ReporTree.log"), emit: log

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.prefix ?: "${meta.species}"

    """
    reportree.py \
        --alignment $snps_alignment_fasta \
        --sample-ATCG-content 0.95 \
        --method MSTreeV2 \
        --analysis HC \
        --n_proc $task.cpus \

    """
}
