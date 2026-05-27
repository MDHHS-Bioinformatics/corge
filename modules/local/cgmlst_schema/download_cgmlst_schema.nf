process DOWNLOAD_CGMLST_SCHEMA {
    label 'process_high'
    
    input:
    tuple val(id), val(name), val(url), val(trn)

    output:
    tuple val(name), path("${name}_alleles.zip"), val(trn), emit: alleles_zip
    
    when:
    task.ext.when == null || task.ext.when

    script:
    """
    curl -L --retry 5 --retry-delay 10 --retry-all-errors -o "${name}_alleles.zip" "${url}"
    """
}
