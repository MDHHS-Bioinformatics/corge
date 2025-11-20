process CONFIGURE_CGMLST_SCHEMA {
    label 'process_high'
    conda "bioconda::chewbbaca=3.4.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/chewbbaca:3.4.2--pyhdfd78af_0':
        'quay.io/biocontainers/chewbbaca:3.4.2--pyhdfd78af_0' }"

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
    //def schema_path = file(file(params.schema_dir).resolve(species))

    """
    chewBBACA.py PrepExternalSchema -g $alleles -o ${name}_cgMLST --ptf $trn --cpu $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chewbbaca: \$(echo \$(chewie --version 2>&1 | sed 's/^.*chewBBACA version: //g; s/Using.*\$//' ))
    END_VERSIONS
    """
}
