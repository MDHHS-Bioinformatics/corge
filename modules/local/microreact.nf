
process MICROREACT {
    tag "$meta.species"
    label 'process_single'

    conda "conda-forge::python=3.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(meta), path(partitions), path(single_HC), path(mashtree)
    output:
    path '*.microreact'       , emit: microreact
    path "versions.yml"       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def thresholds = params.thresholds ?: ''
    species = task.ext.prefix ?: "${meta.species}"


    """
    make_microreact.py --species $species --partitions ${thresholds} \
        --partitions-tsv $partitions \
        --reportree-tree $single_HC \
        --mash-tree $mashtree \
        --template $params.microreact_template \
        --output ${species}_corge.microreact

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
