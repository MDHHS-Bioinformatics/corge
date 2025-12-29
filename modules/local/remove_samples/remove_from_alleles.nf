process REMOVE_FROM_ALLELES {
    tag "$meta.species"
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:2.2.1' :
        'quay.io/biocontainers/pandas:2.2.1' }"

    input:
    tuple val(meta), val(ids)
    path outdir

    output:
    tuple val(meta), path("${meta.species}_masked_results_alleles.tsv"), emit: masked_alleles
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    species = task.ext.species ?: "${meta.species}"

    """

    SRC="${outdir}/${meta.species}/cgMLST/masked/${meta.species}_masked_results_alleles.tsv"
    OUT="${meta.species}_masked_results_alleles.tsv"

    if [[ ! -f "\$SRC" ]]; then
        echo "WARNING: alleles file not found: \$SRC" >&2
    else
        cp "\$SRC" "\$OUT"

        remove_from_alleles.py \
            --input "\$OUT" \
            --ids "${ids.join(',')}"
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
