process UNZIP_CGMLST_SCHEMA {
    label 'process_high'
    
    input:
    tuple val(id), path(alleles_zip), val(trn)

    output:
    tuple val(id), path("${id}_alleles"), val(trn),  emit: alleles

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    unzip -o -q $alleles_zip -d ${id}_alleles
    """
}
