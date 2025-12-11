process CHECK_METADATA_MSA {
    tag "$meta.species"
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas%3A2.2.1' :
        'https://quay.io/repository/biocontainers/pandas/manifest/sha256:509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987' }"

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
