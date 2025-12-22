process DELETE_ASSEMBLIES {

    tag "${species}"

    input:
    tuple val(species), val(ids)
    path outdir

    output:
    tuple val(species), path("assemblies/*"), emit: updated_assemblies

    script:
    """
    # Resolve real path of outdir (not the staged symlink)
    REAL_OUTDIR=\$(readlink -f "${outdir}")
    ASSEMBLY_DIR="\${REAL_OUTDIR}/${species}/assemblies"

    if [[ ! -d "\$ASSEMBLY_DIR" ]]; then
        echo "WARNING: Assembly directory not found: \$ASSEMBLY_DIR" >&2
        mkdir -p assemblies
        exit 0
    fi

    mkdir -p assemblies

    # Write IDs to a lookup file
    printf "%s\n" ${ids.join(' ')} > ids.txt

    shopt -s nullglob
    for f in "\$ASSEMBLY_DIR"/*; do
        base=\$(basename "\$f")
        base="\${base%%.*}"   # strip extension

        if grep -qx "\$base" ids.txt; then
            echo "Removing assembly: \$f"
            rm -f "\$f"
        else
            # Symlink using REAL filesystem path
            ln -s "\$f" assemblies/
        fi
    done
    """
}
