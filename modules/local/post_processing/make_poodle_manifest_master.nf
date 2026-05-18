process MAKE_POODLE_MANIFEST_MASTER {
    tag "$meta.species"
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container 'quay.io/biocontainers/pandas@sha256:509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987'
    //'quay.io/biocontainers/pandas:2.2.1'
    
    input:
    tuple val(meta), path(genomic_context_groups), path(potential_linkages)
    val(outdir_abs)
    path(master_paths)

    output:

    tuple val(meta), path("poodle_samplesheets/"),  optional: true, emit: poodle_samplesheets
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def thresholds = params.thresholds ?: ''
    species = task.ext.species ?: "${meta.species}"
    // Determine which input to use: prioritize master_paths, fallback to phoenix or bactopia paths, or nothing
    def sample_paths = ''
    if (master_paths) {
        sample_paths = "--master_paths '${master_paths}'"
    }
    else if (params.phoenix_path) {
        sample_paths = "--phoenix_path '${params.phoenix_path}'"
    }
    else if (params.bactopia_path) {
        sample_paths = "--bactopia_path '${params.bactopia_path}'"
    }

    """
    make_poodle_manifest.py \
        --species $species \
        --outdir ${outdir_abs} \
        --thresholds ${thresholds} \
        --groups ${genomic_context_groups} \
        --linkages ${potential_linkages} \
        ${sample_paths}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
