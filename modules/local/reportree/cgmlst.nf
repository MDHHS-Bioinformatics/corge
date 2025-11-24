process REPORTREE_CGMLST {
    tag "$meta.species"
    label 'process_medium'


    container "reportree_v2.6.0.sif"

    input:
    tuple val(meta), path(allele_table)
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
    def partitions = previous_partitions ? "--nomenclature-file ${previous_partitions}" : ""
    """
    mkdir ReporTree

    echo $species
    reportree.py \
        --output ReporTree/${species} \
        --allele-profile $allele_table \
        --method MSTreeV2 \
        --analysis HC \
        --n_proc $task.cpus \
        $partitions

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        reportree: \$(reportree.py --version 2>&1 | sed 's/.*Version: //i' | head -n1)
    END_VERSIONS
    """
}
