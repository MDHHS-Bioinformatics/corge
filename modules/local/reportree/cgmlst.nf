process REPORTREE_CGMLST {
    tag "$meta.species"
    label 'process_medium'


    //conda "YOUR-TOOL-HERE"
    container "reportree_local_v2.5.3.sif"

    input:
    tuple val(meta), path(allele_table) // path(allele_table)

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
    //tuple val(meta), path("ReporTree_metadata_w_partitions.tsv"), emit: metadata_w_partitions
    //tuple val(meta), path("ReporTree_partitions_summary.tsv"), emit: partitions_summary
    tuple val(meta), path("ReporTree_partitions.tsv"), emit: partitions
    tuple val(meta), path("ReporTree_single_HC.nwk"), emit: single_HC
    tuple val(meta), path("ReporTree.log"), emit: log
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.prefix ?: "${meta.species}"

    """
    #mv $allele_table results_alleles.tsv
    echo $species
    reportree.py \
        --allele-profile $allele_table \
        --loci-called 0.95 \
        --method MSTreeV2 \
        --analysis HC \
        --n_proc $task.cpus \

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        reportree: \$(reportree.py --version 2>&1 | sed 's/.*Version: //i' | head -n1)
    END_VERSIONS
    """
}
