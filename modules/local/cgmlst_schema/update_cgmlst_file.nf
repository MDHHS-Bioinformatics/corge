process UPDATE_CGMLST_FILE {
    label 'process_medium'

    conda "conda-forge::pandas=2.2.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:2.2.1' :
        'quay.io/biocontainers/pandas:2.2.1' }"

    input:
    tuple val(outdir), path(species_schemas), val(ready)
    
    output:
    path("cgmlst_schemas.csv"), emit: cgmls_list

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """    
    update_cgmlst_schemas.py \
        $outdir \
        $species_schemas \
        'cgmlst_schemas.csv'
    
    """
}