process CHECK_METADATA_MSA {
    tag "$meta.species"
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:2.2.1' :
        'quay.io/biocontainers/pandas:2.2.1' }"

    input:
    tuple val(meta), path(msa)
    path metadata

    output:
    tuple val(meta), path("${meta.species}_metadata.tsv") , emit: metadata
    path "versions.yml", emit: versions

    script:
    species = meta.species

    """
    check_metadata_msa.py \
        --metadata ${metadata} \
        --msa ${msa} \
        --species ${species} 
            
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
