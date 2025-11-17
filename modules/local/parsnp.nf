process PARSNP {
    tag "$meta.species"
    label 'process_high'

    conda "bioconda::parsnp=2.0.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/parsnp%3A2.1.5--h077b44d_0':
        'quay.io/biocontainers/parsnp:2.1.5--h077b44d_0' }"

    input:

    tuple val(meta), path("assemblies/*")

    output:
    tuple val(meta), path("results/") , emit: results
    tuple val(meta), path("results/parsnp.snps.mblocks"), emit: snps_alingment
    tuple val(meta), path('parsnp.log'), emit: parsnp_log
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
        --threads $task.cpus \
        --force-overwrite \
        $args \
        --output-dir results > parsnp.log 2>&1

    #Convert ginger file to multi-fasta
    harvesttools -i results/parsnp.ggr -S results/snps_alingment.fasta >> parsnp.log 2>&1

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        parsnp: \$(parsnp -V 2>&1 | tail -n 1)
    END_VERSIONS
    """
}
