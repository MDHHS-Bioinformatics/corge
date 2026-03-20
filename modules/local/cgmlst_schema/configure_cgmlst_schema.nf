process CONFIGURE_CGMLST_SCHEMA {
    label 'process_high'

    conda "bioconda::chewbbaca=3.5.3"
    container 'quay.io/biocontainers/chewbbaca:3.5.3--pyh106432d_1'

    input:
    tuple val(name), path(alleles), path(trn)

    output:
    path("${name}_cgMLST")        , emit: schema
    val(name)                     , emit: name
    path "versions.yml"           , emit: versions
    val true , emit: done
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    chewBBACA.py PrepExternalSchema -g $alleles -o ${name}_cgMLST --ptf $trn --cpu $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chewbbaca: \$(echo \$(chewie --version 2>&1 | sed 's/^.*chewBBACA version: //g; s/Using.*\$//' ))
    END_VERSIONS
    """
}
