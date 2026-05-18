process CHECK_METADATA {
    tag "$meta.species"
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container 'quay.io/biocontainers/pandas@sha256:509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987'
    //'quay.io/biocontainers/pandas:2.2.1'
    
    input:
    tuple val(meta), path(masked_alleles)
    path metadata

    output:
    tuple val(meta), path("${meta.species}_metadata.tsv") , emit: metadata
    path "versions.yml", emit: versions

    script:
    species = meta.species

    """
    check_metadata.py \
        --metadata ${metadata} \
        --input ${masked_alleles} \
        --species ${species} 
            
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
