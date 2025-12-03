
process CHEWBBACA_EXTRACTCGMLST {
    tag "$meta.species"
    label 'process_single'
    conda "bioconda::chewbbaca=3.4.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/chewbbaca:3.4.2--pyhdfd78af_0':
        'quay.io/biocontainers/chewbbaca:3.4.2--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(alleles)

    output:
    tuple val(meta), path("masked/${meta.species}_masked_results_alleles.tsv"), emit: masked_alleles
    tuple val(meta), path("masked/")                          , emit: masked_results
    path "versions.yml"                                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.species ?: "${meta.species}"

    """
    #make the masked results folder
    mkdir masked

    chewBBACA.py ExtractCgMLST \
        --input-file $alleles \
        --output-directory masked/ \
        --threshold 0

    #get the threshold 0 .tsv file and renamed for our purpose
    mv masked/cgMLST0.tsv masked/masked_results_alleles.tsv

    # Rename results
    for f in masked/*; do
        mv "\$f" "masked/${species}_\$(basename "\$f")"
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chewbbaca: \$(echo \$(chewie --version 2>&1 | sed 's/^.*chewBBACA version: //g; s/Using.*\$//' ))
    END_VERSIONS
    """
}
