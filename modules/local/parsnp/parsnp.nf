process PARSNP {
    tag "$meta.species"
    label 'process_high'

    conda "bioconda::parsnp=2.1.5"
    container 'quay.io/staphb/parsnp@sha256:bb0246aa25118199b721caaba538fad7ee7f64d7e8683faf324dbf37baab0792' 
    // 'quay.io/staphb/parsnp:2.1.5'

    input:

    tuple val(meta), path("assemblies/*")

    output:
    tuple val(meta), path("${meta.species}_parsnp*")            , emit: results
    tuple val(meta), path("${meta.species}_parsnp.snps.mblocks"), emit: snps_alignment
    tuple val(meta), path("${meta.species}_parsnp.xmfa")        , emit: xmfa
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.species ?: "${meta.species}"

    """
    #Create results directory to store outputs
    mkdir results

    #Run Parsnp
    parsnp \
        --reference ! \
        --sequences assemblies/ \
        --skip-phylogeny \
        --alignment-program mafft \
        --curated \
        --recomb-filter \
        --force-overwrite \
        --threads $task.cpus \
        $args \
        --output-dir results
    
    # Moving relevant log to results
    mv results/log/parsnpAligner.log results/

    # Move and rename with species prefix
    for f in results/*; do
        base=\$(basename "\$f")
        mv "\$f" "${species}_\${base}"
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        parsnp: \$(parsnp -V 2>&1 | tail -n 1 | sed 's/^parsnp //')
    END_VERSIONS
    """
}
