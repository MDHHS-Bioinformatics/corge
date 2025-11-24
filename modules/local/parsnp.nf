process PARSNP {
    tag "$meta.species"
    label 'process_high'

    conda "bioconda::parsnp=2.1.5"
    container "quay.io/staphb/parsnp:2.1.5"

    input:

    tuple val(meta), path("assemblies/*")

    output:
    tuple val(meta), path("results/") , emit: results
    tuple val(meta), path("results/parsnp.snps.mblocks"), emit: snps_alignment
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.species ?: "${meta.species}"

    """
    #Create results directory to store outputs
    mkdir results

    #Run Parsnp
    parsnp \
        --reference ! \
        --sequences assemblies/ \
        --skip-phylogeny \
        --alignment-program mafft \
        --curated \
        --recomb-filter \
        --force-overwrite \
        --threads $task.cpus \
        $args \
        --output-dir results > parsnp.log 2>&1

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        parsnp: \$(parsnp -V 2>&1 | tail -n 1)
    END_VERSIONS
    """
}
