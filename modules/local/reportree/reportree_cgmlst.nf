process REPORTREE_CGMLST {
    tag "$meta.species"
    label 'process_medium'

    container "quay.io/vascok/reportree:2.6.0"

    input:
    tuple val(meta), path(allele_table)
    tuple val(meta), path(metadata)
    tuple val(meta), path(previous_partitions)

    output:
    tuple val(meta), path("ReporTree/")                                               , emit: reportree_results
    tuple val(meta), path("ReporTree/${meta.species}_clusterComposition.tsv")         , emit: cluster_composition
    tuple val(meta), path("ReporTree/${meta.species}_dist_hamming.tsv")               , emit: dist_hamming
    tuple val(meta), path("ReporTree/${meta.species}_partitions.tsv")                 , emit: partitions
    tuple val(meta), path("ReporTree/${meta.species}_single_HC.nwk")                  , emit: single_HC
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.prefix ?: "${meta.species}"
    def columns_summary_report = ''
    if (params.columns_summary_report) {columns_summary_report = "--columns_summary_report '${params.columns_summary_report}'"}
    def metadata2report = ''
    if (params.metadata2report) {metadata2report = "--metadata2report '${params.metadata2report}'"}
    def filter = ''
    if (params.filter) {filter = "--filter '${params.filter}'"}
    def frequency_matrix = ''
    if (params.frequency_matrix) {frequency_matrix = "--frequency-matrix '${params.frequency_matrix}'"}  
    def count_matrix = ''
    if (params.count_matrix) {count_matrix = "--count-matrix '${params.count_matrix}'"}  
    def metadata = metadata ? "--metadata ${metadata}" : ""
    def partitions = previous_partitions ? "--nomenclature-file ${previous_partitions}" : ""
    """
    mkdir ReporTree

    echo $species
    reportree.py \
        $metadata \
        --output ReporTree/${species} \
        --allele-profile $allele_table \
        --method MSTreeV2 \
        --analysis HC \
        --n_proc $task.cpus \
        $partitions $columns_summary_report $metadata2report $filter $frequency_matrix $count_matrix

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        reportree: \$(reportree.py --version 2>&1 | sed 's/.*Version: //i' | head -n1)
    END_VERSIONS
    """
}
