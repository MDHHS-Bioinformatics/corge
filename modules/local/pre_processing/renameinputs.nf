process RENAME_INPUTS {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("${meta.id}.fna"), emit: renamed_files

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    species = task.ext.species ?: "${meta.species}"

    """
    if [[ "${assembly}" == *.gz ]]; then
        gzip -cd "${assembly}" > "${prefix}.fna"
    else
        if [[ "\$(realpath "${assembly}")" != "\$(realpath "${prefix}.fna")" ]]; then
            cp "${assembly}" "${prefix}.fna"
        fi
    fi
    """
}
