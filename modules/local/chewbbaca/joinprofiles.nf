
process CHEWBBACA_JOINPROFILES {
    tag "$meta.species"
    label 'process_single'
    
    conda "bioconda::chewbbaca=3.5.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/chewbbaca:3.5.3--pyh106432d_1':
        'quay.io/biocontainers/chewbbaca:3.5.3--pyh106432d_1' }"

    input:
    tuple val(meta), path(new_alleles), path(old_alleles)

    output:
    tuple val(meta), path("${meta.species}_joined_results_alleles.tsv"), emit: joined_alleles
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.species ?: "${meta.species}"

    """
    #crete previous directory to disambiguate files
    mkdir previous
    mv $old_alleles previous/


    chewBBACA.py JoinProfiles \
        --profiles $new_alleles previous/$old_alleles \
        --output-file ${species}_joined_results_alleles.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chewbbaca: \$(echo \$(chewie --version 2>&1 | sed 's/^.*chewBBACA version: //g; s/Using.*\$//' ))
    END_VERSIONS
    """
}
