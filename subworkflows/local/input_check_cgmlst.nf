
//
// Check the cgMLST schemas provided
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMPLESHEET_CHECK_CGMLST } from '../../modules/local/pre_processing/samplesheet_check_cgmlst.nf'

/*
=============================================================================================================================
    SUBWORKFLOW FUNCTIONS
=============================================================================================================================
*/
// Function to set up cgMLST channel properly
def create_cgmlst_channel(LinkedHashMap row) {
    def meta = [species: row.species]
    if (!file(row.cgmlst_path).exists()) {
        exit 1, "ERROR: Please check input cgmlST directory -> cgmlST directory does not exist!\n${row.cgmlst_path}"
    }
    return tuple(meta, file(row.cgmlst_path))
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow INPUT_CHECK_CGMLST {

    take:
    cgmlst_schemas  // csv file containg species and path species schemas
    species_count   // channel: [species, counts] from input manifest
    
    main:
    ch_versions = Channel.empty()
    //
    // MODULE: Check cgmlst_schemas file to make sure everything looks good
    //
    SAMPLESHEET_CHECK_CGMLST (cgmlst_schemas)
        .csv
        .splitCsv (header:true, sep:',')
        .map{ create_cgmlst_channel(it)}
        .set{cgmlst_paths}
    ch_versions = ch_versions.mix(SAMPLESHEET_CHECK_CGMLST.out.versions)
    //
    // Join the cgmlst paths with the species_count channel
    //
    cgmlst_paths_keyed = cgmlst_paths
        .map { meta, path ->
            tuple(meta.species, path)
        }

    joined_species_count = species_count
        .join(cgmlst_paths_keyed, remainder: true)
        .filter { species, count, path_to_cgmlst ->
            count != null
        }
    //
    // Now branch based on if a cgmlst is a available or not
    joined_species_count
        .branch {
            schema_unavailable: it[2] == null
            chewbbaca: it[2] != null
        }
        .set { cgmlst_species_counts }
    //
    // Reformat channel for species with cgmlst
    //
    cgmlst_species_counts.chewbbaca
        .map { species, count, path_to_cgmlst ->
            tuple([species: species, count: count], path_to_cgmlst)
        }
        .set { cgmlst_species }
    //
    // Reformat channel for species with no cgmlst
    //
    cgmlst_species_counts.schema_unavailable
        .map { species, count, path_to_cgmlst ->
            tuple([species: species, count: count])
        }
        .set { no_cgmlst_species }

    emit:
    species_counts_cgmlst  = cgmlst_species     // channel: [[species, count], path_to_cgmlst]
    species_count_nocgmlst = no_cgmlst_species  // channel: [[species, count]]
    versions = ch_versions                     // channel: [ versions.yml ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/