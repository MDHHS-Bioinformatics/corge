process BACTERIAL_LINKAGE {
    tag  "$meta.species"
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container 'quay.io/biocontainers/pandas@sha256:509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987'
    //'quay.io/biocontainers/pandas:2.2.1'
    
    input:
    tuple val(meta), path(dist_hamming), path(loci_report), path(parsnp_log)

    output:
    tuple val(meta), path("*_potential_linkages.csv"), emit: potential_linkages
    path "versions.yml"                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.species ?: "${meta.species}"
    def data_type = meta.data_type ?: 'unknown'
    def loci_arg = loci_report ? "--loci-report $loci_report" : ""
    def parsnp_arg = parsnp_log ? "--parsnp-log $parsnp_log" : ""

    """
    bacterial_linkage_corge.py \
        --species $species \
        --data-type $data_type \
        --dist-hamming $dist_hamming \
        $loci_arg \
        $parsnp_arg \
        --output ${species}_potential_linkages.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
