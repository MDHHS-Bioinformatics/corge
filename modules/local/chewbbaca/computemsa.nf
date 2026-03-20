
process CHEWBBACA_COMPUTEMSA {
    tag "$meta.species"
    label 'process_single'
    
    conda "bioconda::chewbbaca=3.5.3"
    container 'quay.io/biocontainers/chewbbaca:3.5.3--pyh106432d_1'

    input:
    tuple val(meta), path(schema), path(alleles)

    output:
    tuple val(meta), path("msa/${meta.species}_dna_msa.fasta")              , emit: dna_msa
    tuple val(meta), path("msa/${meta.species}_dna_msa_variable.fasta")     , emit: dna_variable_msa
    tuple val(meta), path("msa/${meta.species}_protein_msa.fasta")          , emit: protein_msa
    tuple val(meta), path("msa/${meta.species}_protein_msa_variable.fasta") , emit: protein_variable_msa
    tuple val(meta), path("msa/${meta.species}_summary_stats.tsv")          , emit: summary_stats
    path "versions.yml"                                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.species ?: "${meta.species}"

    """
    chewBBACA.py ComputeMSA \
        --input-path $alleles \
        --schema-directory $schema \
        --output-directory msa/ \
        --output-variable \
        --dna-msa \
        --cpu $task.cpus

    # Rename the prefix of the results files    
    for file in msa/*; do
        if [ -f "\$file" ]; then
            mv -n "\$file" "msa/${species}_\$(basename "\$file")" || echo "Failed to move \$file"
        fi
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chewbbaca: \$(echo \$(chewie --version 2>&1 | sed 's/^.*chewBBACA version: //g; s/Using.*\$//' ))
    END_VERSIONS
    """
}
