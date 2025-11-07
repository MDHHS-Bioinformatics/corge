process CHEWBBACA_ALLELECALL {
    tag "$meta.species"
    label 'process_high'
    conda "bioconda::chewbbaca=3.3.10"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/chewbbaca:3.3.10--pyhdfd78af_0':
        'quay.io/biocontainers/chewbbaca:3.3.10--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(schema), path(assemblies)

    output:
    tuple val(meta), path("new/*") , emit: results
    tuple val(meta), path("new/new_results_alleles.tsv"), emit: results_alleles
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.species ?: "${meta.species}"
    //def schema_path = file(file(params.schema_dir).resolve(species))

    """
    #first move all the new assmples to a directory
    mkdir new_assemblies/
    mv *.fna new_assemblies/

    chewBBACA.py AlleleCall \
        --input-files new_assemblies \
        --schema-directory $schema \
        --output-directory new/ \
        --cpu $task.cpus

    # Rename the prefix of the results files
    for file in new/*; do
        if [ -f "\$file" ]; then
            mv -n "\$file" "new/new_\$(basename "\$file")" || echo "Failed to move \$file"
        fi
    done
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chewbbaca: \$(echo \$(chewie --version 2>&1 | sed 's/^.*chewBBACA version: //g; s/Using.*\$//' ))
    END_VERSIONS
    """
}
