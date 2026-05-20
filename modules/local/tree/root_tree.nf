process ROOT_TREE {
    tag "${meta.species}"
    label 'process_single'

    conda "conda-forge::r-phytools=0.7_47"
    container 'quay.io/biocontainers/r-phytools@sha256:5672e6d56f36bdace102047e4d3aa5f143accd09b5f211eb3503e4da5d411934'
    // 'quay.io/biocontainers/r-phytools:0.6_44--r3.4.1_0'

    input:
    tuple val(meta), path(tree)

    output:
    tuple val(meta), path('*.tre')       , emit: tre
    path "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args_extension = task.ext.args_extension ?: ''
    species = task.ext.prefix ?: "${meta.species}"

    """
    root_tree.R '${tree}' '${species}_rooted_${args_extension}.tre' 50

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(R --version | sed -n 's/^R version \\([0-9.]*\\).*/\\1/p')
    END_VERSIONS
    """
}
