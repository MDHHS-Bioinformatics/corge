process PRODIGAL_CREATE_TRN {
    tag "$meta.species"
    label 'process_single'
   
    conda "bioconda::prodigal=2.6.3"
    container 'quay.io/biocontainers/prodigal@sha256:894e9100527f5c01c2f2c662723dacfe03d7d86f1e5cc5064d00b12e8494a6b1'
    //'quay.io/biocontainers/prodigal:2.6.3--h577a1d6_11'
        
    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("*.trn")          , emit: trn
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.species ?: "${meta.species}"

    """
    prodigal \\
        -i "${assembly}" \\
        -p single \\
        -t "${species}.trn"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        prodigal: \$(echo \$(prodigal --version 2>&1 | sed 's/^.*Prodigal V\\([^: ]*\\).*/\\1/p' ))
    END_VERSIONS
    """
}
