process REMOVE_FROM_PARTITIONS {
    tag "$meta.species"
    label 'process_single'

    conda "conda-forge::python=3.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(meta), val(ids)
    path outdir

    output:
    tuple val(meta), path("${meta.species}_partitions.tsv"), emit: partitions
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    species = task.ext.species ?: "${meta.species}"
    samples = task.ext.ids ?: ${ids.join(',')}

    """
    remove_from_partitions.py -outdir $outdir --species $species --ids $samples

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
