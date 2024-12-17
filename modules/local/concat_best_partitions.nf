process CONCAT_BEST_PARTITIONS {
    //tag "$meta.id"
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas%3A2.2.1' :
        'https://quay.io/repository/biocontainers/pandas/manifest/sha256:509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987' }"

    input:
    path("partitions/*")

    output:
    path('*.csv'), emit: best_partitions
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    //tuple val(meta), path("*.bam"), emit: bam
    // TODO nf-core: List additional required output channels/values here
    //path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    //def prefix = task.ext.prefix ?: "${meta.id}"

    """

    concat_best_partitions.py partitions/

    """
}
