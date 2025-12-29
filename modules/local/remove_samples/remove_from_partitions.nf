process REMOVE_FROM_PARTITIONS {

    tag "${meta.species}"
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:2.2.1' :
        'quay.io/biocontainers/pandas:2.2.1' }"

    input:
    tuple val(meta), val(ids)
    path outdir

    output:
    tuple val(meta), path("${meta.species}_partitions.tsv"), emit: partitions
    path "versions.yml", emit: versions

    script:
    """
    SRC="${outdir}/${meta.species}/ReporTree/${meta.species}_partitions.tsv"
    OUT="${meta.species}_partitions.tsv"

    if [[ ! -f "\$SRC" ]]; then
        echo "WARNING: partitions file not found: \$SRC" >&2
        # satisfy Nextflow output contract
        touch "\$OUT"
    else
        cp "\$SRC" "\$OUT"

        remove_from_partitions.py \
            --input "\$OUT" \
            --ids "${ids.join(',')}"
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
