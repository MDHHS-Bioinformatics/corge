process CHEWBBACA_CREATESCHEMA {
    tag "$meta.species"
    label 'process_high'
   
    conda "bioconda::chewbbaca=3.5.4"
    container 'quay.io/biocontainers/chewbbaca@sha256:39cde3bf7cfa90f5f936998f56c15a2452004e438611002d4a269d9d2812e573'
    //'quay.io/biocontainers/chewbbaca:3.5.4--pyh106432d_0'
        
    input:
    tuple val(meta), path(assemblies), path(trn)

    output:
    tuple val(meta), path("${species}_wgmlst"), path("references/*") , emit: wgmlst
    path "versions.yml"                                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.species ?: "${meta.species}"

    """
    # Move all the reference assemblies to a directory

    mkdir references/

    for asm in ${assemblies}; do
        base=\$(basename "\$asm")

        case "\$base" in
            *.fna.gz|*.fa.gz|*.fas.gz|*.fasta.gz)
                out="\${base%.gz}"
                gunzip -c "\$asm" > "references/\$out"
                ;;
            *.fna|*.fa|*.fas|*.fasta)
                ln -s "\$PWD/\$asm" "references/\$base"
                ;;
            *)
                echo "ERROR: Unsupported assembly extension: \$base" >&2
                echo "Accepted extensions: .fa, .fas, .fasta, .fna and .gz versions" >&2
                exit 1
                ;;
        esac
    done

    # Create wgMLST schema
    chewBBACA.py CreateSchema  \
        --input-files references \
        --output-directory . \
        --schema-name ${species}_wgmlst \
        --training-file ${trn} \
        --cpu $task.cpus
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chewbbaca: \$(echo \$(chewie --version 2>&1 | tail -n 1 | sed 's/^.*chewBBACA version: //g; s/Using.*\$//' ))
    END_VERSIONS
    """
}
