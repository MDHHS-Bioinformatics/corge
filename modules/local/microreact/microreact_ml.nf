
process MICROREACT_ML {
    tag "$meta.species"
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container 'quay.io/biocontainers/pandas:2.2.1'

    input:
    tuple val(meta), path(partitions), path(single_HC), path(snp_tree), path(mashtree), path(template_microreact)

    output:
    path '*.microreact'       , emit: microreact
    path "versions.yml"       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def thresholds = params.thresholds ?: ''
    species = task.ext.prefix ?: "${meta.species}"

    """
    make_microreact_ml.py --species $species --partitions ${thresholds} \
        --partitions-tsv $partitions \
        --reportree-tree $single_HC \
        --snp-tree $snp_tree \
        --mash-tree $mashtree \
        --template $template_microreact \
        --output ${species}_ml_corge.microreact

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
