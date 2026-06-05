process PREPARE_CGMLST {
    tag "$meta.species"
    label 'process_medium'
   
    conda "bioconda::chewbbaca=3.5.4"
    container 'quay.io/biocontainers/chewbbaca@sha256:39cde3bf7cfa90f5f936998f56c15a2452004e438611002d4a269d9d2812e573'
    //'quay.io/biocontainers/chewbbaca:3.5.4--pyh106432d_0'
        
    input:
    tuple val(meta), path(cgmlst_txt), path(schema)

    output:
    tuple val(meta), path("${species}_cgMLST")   , emit: cgmlst_schema
    path "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.species ?: "${meta.species}"

    """
    mkdir -p ${species}_loci_cgMLST
    
    # Copy the core gene fasta files
    while read -r gene; do
        cp "${schema}/\${gene}.fasta" "${species}_loci_cgMLST"
    done < "$cgmlst_txt" &&

    trn="${schema}/${species}.trn"

    chewBBACA.py PrepExternalSchema \\
        -g ${species}_loci_cgMLST \\
        -o ${species}_cgMLST \\
        --ptf \$trn \\
        --cpu $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chewbbaca: \$(echo \$(chewie --version 2>&1 | tail -n 1 | sed 's/^.*chewBBACA version: //g; s/Using.*\$//' ))
    END_VERSIONS
    """
}
