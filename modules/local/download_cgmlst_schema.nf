process DOWNLOAD_CGMLST_SCHEMA {
    label 'process_high'
    
    input:
    tuple val(id), val(name), val(url), val(trn)

    output:
    tuple val(name), path("${name}_alleles"), val(trn)
    
    when:
    task.ext.when == null || task.ext.when

    script:
    """
    curl -s ${url} -o ${name}_alleles.zip
    unzip -o -q ${name}_alleles.zip -d ${name}_alleles
    """
}
