

process BACTERIAL_LINKAGE {
    tag  "$meta.species"
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:2.2.1' :
        'quay.io/biocontainers/pandas:2.2.1' }"

    input:
    tuple val(meta), path(dist_hamming), path(loci_report)

    output:
    tuple val(meta), path("*_potential_linkages.csv"), emit: potential_linkages
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.species ?: "${meta.species}"

    """
    echo $species
    bacterial_linkage_corge.py \
        --species $species \
        --dist-hamming $dist_hamming \
        --loci-report $loci_report \
        --output ${species}_potential_linkages.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
