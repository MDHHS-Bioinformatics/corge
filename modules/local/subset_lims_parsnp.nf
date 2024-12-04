process SUBSET_LIMS_PARSNP {
    tag '$meta.species'
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas%3A2.2.1' :
        'https://quay.io/repository/biocontainers/pandas/manifest/sha256:509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987' }"

    input:
    tuple val(meta), path(fasta)
    path(lims_manifest)

    output:
    tuple val(meta), path(fasta), path("*.csv"), emit: subset_species_lims


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.species ?: "${meta.species}"

    """
    subset_lims.py $lims_manifest $species

    """
}
