process CONFIGURE_CGMLST_SCHEMA {
    label 'process_high'

    conda "bioconda::chewbbaca=3.5.4"
    container 'quay.io/biocontainers/chewbbaca@sha256:39cde3bf7cfa90f5f936998f56c15a2452004e438611002d4a269d9d2812e573'
    //'quay.io/biocontainers/chewbbaca:3.5.4--pyh106432d_0'

    input:
    tuple val(name), path(alleles), path(trn)

    output:
    path("${name}_cgMLST")        , emit: schema
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    chewBBACA.py PrepExternalSchema -g $alleles -o ${name}_cgMLST --ptf $trn --cpu $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chewbbaca: \$(echo \$(chewie --version 2>&1 | tail -n 1 | sed 's/^.*chewBBACA version: //g; s/Using.*\$//' ))
    END_VERSIONS
    """
}
