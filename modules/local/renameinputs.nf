process RENAME_INPUTS {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta),path(gff), path(reference)

    output:
    tuple val(meta), path("renamed_files/*.gff"), path("renamed_files/*.fna"), emit:renamed_files
    //path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p renamed_files

    #rename the gff file
    newname="renamed_files/${prefix}.gff"
    mv *.gff "\$newname"

    #rename the fna file
    newname="renamed_files/${prefix}.fna"
    mv *.fna "\$newname"



    """
}
