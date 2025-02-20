process GET_BEST_PARTITION {
    tag "$meta.species"
    label 'process_medium'

    conda "conda-forge::pandas=2.2.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas%3A2.2.1' :
        'https://quay.io/repository/biocontainers/pandas/manifest/sha256:509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987' }"

    input:
    tuple val(meta), path(reportree_partitions)
    path(master_manifest)
    path(manifest_new_assemblies)

    output:
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    tuple val(meta), path("*.csv"), optional: true, emit: best_partitions
    // TODO nf-core: List additional required output channels/values here
    //path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def scheme_available = task.ext.scheme_available ?: "${meta.scheme_available}"
    def file_output = task.ext.file_output ?: "${meta.species}_partitions.csv"
    species = task.ext.species ?: "${meta.species}"


    """
    echo $species
    echo $scheme_available

    get_best_partition.py \
        $reportree_partitions \
        $master_manifest \
        $manifest_new_assemblies \
        $scheme_available \
        $file_output \

    """
}
