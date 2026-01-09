process CONVERT_XMFA_FASTA {
    tag "$meta.species"
    label 'process_high'

    conda "bioconda::parsnp=2.1.5"
    container "quay.io/staphb/parsnp:2.1.5"

    input:

    tuple val(meta), path(xmfa)

    output:
    tuple val(meta), path("${meta.species}_core_msa.fasta") , emit: core_aln
    path "versions.yml"                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.species ?: "${meta.species}"

    """
    #Run Parsnp
    harvesttools -x $xmfa -M ${species}_core_msa.fasta
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        parsnp: \$(parsnp -V 2>&1 | tail -n 1 | sed 's/^parsnp //')
    END_VERSIONS
    """
}
