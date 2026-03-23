process CONSTANTSITES {
    tag "${meta.species}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container 'quay.io/biocontainers/snp-sites:2.5.1--h577a1d6_7'

    input:
    tuple val(meta), path(msa)

    output:
    tuple val(meta), path("${meta.species}_constant-sites.txt"), emit: constant_sites

    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.prefix ?: "${meta.species}"
    """
    snp-sites \
        $msa \
        -C \
        $args \
        > ${species}_constant-sites.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        snpsites: \$(snp-sites -V 2>&1 | sed 's/snp-sites //')
    END_VERSIONS
    """
}