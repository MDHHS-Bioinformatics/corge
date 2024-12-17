
process UPDATE_MASTER_MANIFEST {
    //tag "$meta.id"
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas%3A2.2.1' :
        'https://quay.io/repository/biocontainers/pandas/manifest/sha256:509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987' }"

    input:
    //tuple val(meta), path(bam)
    path(new_assemblies)
    path(new_reads)
    path(master_manifest)

    output:
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    path("*.csv"), emit: updated_manifest
    // TODO nf-core: List additional required output channels/values here
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    //def prefix = task.ext.prefix ?: "${meta.id}"

    """
    update_master_manifest.py $new_assemblies $new_reads $master_manifest

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        updatemastermanifest: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
