process PARSNP {
    tag "$meta.species"
    label 'process_high'

    conda "bioconda::parsnp=2.0.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/parsnp:2.0.6--hdcf5f25_0':
        'quay.io/biocontainers/parsnp:2.0.6--hdcf5f25_0' }"

    input:

    tuple val(meta), path("assemblies/*")

    output:
    tuple val(meta), path("results/") , emit: results
    tuple val(meta), path("results/snps_alingment.fasta"), emit: snps_alingment

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
        --threads $task.cpus \
        -c \
        $args \
        --output-dir results > results/parsnp.log 2>&1

    #Convert ginger file to multi-fasta
    harvesttools -i results/parsnp.ggr -S results/snps_alingment.fasta >> results/parsnp.log 2>&1

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        parsnp: \$(parsnp -v 2>&1 | grep -Eo "v[0-9]+\.[0-9]+")
    END_VERSIONS
    """
}
