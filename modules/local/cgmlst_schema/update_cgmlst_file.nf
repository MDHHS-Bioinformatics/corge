process UPDATE_CGMLST_FILE {
    label 'process_medium'

    conda "conda-forge::pandas=2.2.3"
    container 'quay.io/biocontainers/pandas@sha256:509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987'
    //'quay.io/biocontainers/pandas:2.2.1'

    input:
    tuple val(outdir), path(species_schemas), val(ready)
    
    output:
    path("cgmlst_schemas.csv"), emit: cgmlst_list
    path "versions.yml"       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """    
    update_cgmlst_schemas.py \
        $outdir \
        $species_schemas \
        'cgmlst_schemas.csv'
        cat <<-END_VERSIONS > versions.yml

    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}