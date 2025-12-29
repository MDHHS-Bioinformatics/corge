process CLUSTER_SELECTION {
    tag "$meta.species"
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:2.2.1' :
        'quay.io/biocontainers/pandas:2.2.1' }"


    input:
    tuple val(meta), path(cluster_composition)

    output:

    tuple val(meta), path("genomic_context_groups/"), emit: genomic_context_groups
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def thresholds = params.thresholds ?: ''
    species = task.ext.species ?: "${meta.species}"

    """
    cluster_selection.py \
        --species  ${species} \
        --cluster-composition $cluster_composition \
        --thresholds ${thresholds} \
        --outdir genomic_context_groups \
        --include-date

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
