process UPDATE_SCHEMAS_FILE {
    tag "$meta.species"
    label 'process_single'
        
    input:
    tuple val(meta), path(cgmlst_schema)
    val(outdir_abs)

    output:
    tuple val(meta), path("cgmlst_schemas.csv"), emit: cgmlst_file

    when:
    task.ext.when == null || task.ext.when

    script:
    species = task.ext.species ?: "${meta.species}"

    """
    mkdir -p "${outdir_abs}/cgmlst_schemas"
    
    csv="${outdir_abs}/cgmlst_schemas/cgmlst_schemas.csv"
    cgmlst_path="${outdir_abs}/cgmlst_schemas/${species}_cgMLST"

    if [[ ! -f "\$csv" ]]; then
        echo "species,cgmlst_path" > "\$csv"
    fi

    # Remove any existing row for this species, then append the updated row
    awk -F',' -v species="${species}" 'NR == 1 || \$1 != species' "\$csv" > cgmlst_schemas.csv

    echo "${species},\$cgmlst_path" >> cgmlst_schemas.csv

    """
}
