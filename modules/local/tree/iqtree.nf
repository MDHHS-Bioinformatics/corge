process IQTREE {
    tag "${meta.species}"
    label 'process_high'

    container 'quay.io/biocontainers/iqtree@sha256:604552032e25a7a8d30c8d2f6cbc72b576f2f8159b4d5a0bc17c28dfd9e55511'
    // 'quay.io/biocontainers/iqtree:2.4.0--h503566f_0'

    input:
    tuple val(meta), path(alignment), val(constant_sites)

    output:
    tuple val(meta), path("*.nwk")      , emit: phylogeny     , optional: true
    tuple val(meta), path("*.iqtree")   , emit: report        , optional: true
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args                     = task.ext.args           ?: ''
    def alignment_arg            = alignment               ? "-s $alignment": ''
    def args_extension           = task.ext.args_extension ?: ''
    species                      = task.ext.prefix ?: "${meta.species}"
    def memory                   = task.memory.toString().replaceAll(' ', '')
    """
    # Count number of samples (FASTA format)
    count=\$(grep -c "^>" "$alignment")

    # Branch support strategy:
    # <=4 samples: no support
    # 5-499 samples: ultrafast bootstrap
    # >=500 samples: SH-aLRT, faster and more practical for large trees
    if [[ \$count -ge 500 ]]; then
        support="--alrt 1000"
        treefile="${species}${args_extension}.treefile"
    elif [[ \$count -gt 100 ]]; then
        support="-B 1000 --fast"
        treefile="${species}${args_extension}.contree"
    elif [[ \$count -gt 4 ]]; then
        support="-B 1000"
        treefile="${species}${args_extension}.contree"
    else
        support=""
        treefile="${species}${args_extension}.treefile"
    fi

    iqtree \\
        $args \\
        $alignment_arg \\
        -fconst $constant_sites \\
        --prefix ${species}${args_extension} \\
        --seed 12345 \\
        --safe \\
        -T AUTO \\
        --threads-max $task.cpus \\
        -m GTR+G4 \\
        -mem $memory \\
        --cptime 300 \\
        \$support

    # Rename file for consistency
    mv "\$treefile" ${species}${args_extension}.nwk

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iqtree: \$(echo \$(iqtree -version 2>&1) | sed 's/^IQ-TREE multicore version //;s/ .*//')
    END_VERSIONS
    """

}
