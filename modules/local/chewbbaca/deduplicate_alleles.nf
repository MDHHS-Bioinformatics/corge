process DEDUPLICATE_ALLELES {
    tag "${meta.species}"
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container 'quay.io/biocontainers/pandas:2.2.1'

    input:
     tuple val(meta), path(alleles_table)

    output:
    tuple val(meta), path("*.tsv"), emit: deduplicated_alleles_table
    path "versions.yml", emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.species ?: "${meta.species}"


    """
    deduplicate_alleles.py $alleles_table $species


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS

    """
}
