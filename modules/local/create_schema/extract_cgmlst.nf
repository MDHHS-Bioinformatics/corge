process CHEWBBACA_EXTRACT_CGMLST {
    tag "$meta.species"
    label 'process_single'
   
    conda "bioconda::chewbbaca=3.5.4"
    container 'quay.io/biocontainers/chewbbaca@sha256:39cde3bf7cfa90f5f936998f56c15a2452004e438611002d4a269d9d2812e573'
    //'quay.io/biocontainers/chewbbaca:3.5.4--pyh106432d_0'
        
    input:
    tuple val(meta), path(results_alleles)

    output:
    tuple val(meta), path("cgmlst/cgMLSTschema*.txt")  , emit: cgmlst_txt
    path "versions.yml"                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.species ?: "${meta.species}"

    """
    chewBBACA.py ExtractCgMLST  \
        --input-file ${results_alleles} \
        --output-directory cgmlst \
        --threshold $params.cgmlst_threshold
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chewbbaca: \$(echo \$(chewie --version 2>&1 | tail -n 1 | sed 's/^.*chewBBACA version: //g; s/Using.*\$//' ))
    END_VERSIONS
    """
}
