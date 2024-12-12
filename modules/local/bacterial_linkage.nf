

process BACTERIAL_LINKAGE {
    tag '$meta.species'
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas%3A2.2.1' :
        'https://quay.io/repository/biocontainers/pandas/manifest/sha256:509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987' }"


    input:
    tuple val(meta), path(dist_hamming)

    output:
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    // path "*.bam", emit: bam
    // TODO nf-core: List additional required output channels/values here
    tuple val(meta), path("*_linkages_table.csv"), emit: linkage_table
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.species ?: "${meta.species}"

    // TODO nf-core: Where possible, a command MUST be provided to obtain the version number of the software e.g. 1.10
    //               If the software is unable to output a version number on the command-line then it can be manually specified
    //               e.g. https://github.com/nf-core/modules/blob/master/modules/nf-core/homer/annotatepeaks/main.nf
    //               Each software used MUST provide the software name and version number in the YAML version file (versions.yml)
    // TODO nf-core: It MUST be possible to pass additional parameters to the tool as a command-line string via the "task.ext.args" directive
    // TODO nf-core: If the tool supports multi-threading then you MUST provide the appropriate parameter
    //               using the Nextflow "task" variable e.g. "--threads $task.cpus"
    // TODO nf-core: Please replace the example samtools command below with your module's command
    // TODO nf-core: Please indent the command appropriately (4 spaces!!) to help with readability ;)
    """
    echo $species
    bacterial_linkage.py $dist_hamming $species

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bacteriallinkage: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
