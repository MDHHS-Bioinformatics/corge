//
// Check input samplesheet and get species count and sample assemblies channels
//

/*
=============================================================================================================================
    SUBWORKFLOW FUNCTIONS
=============================================================================================================================
*/
// Function to get list of [ meta, assembly ]
def create_assembly_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id         = row.sample
    meta.species    = row.species

    // add paths to the assemblies
    def assembly_meta = []
    if (!file(row.assembly).exists()){
        exit 1, "ERROR: Please check input samplesheet -> Assembly file does not exist! \n${row.assembly}"
    } else {
        assembly_meta = [meta,file(row.assembly)]
    }

    return assembly_meta
}

// Function to count how many samples for each species there are
def count_species(input_channel) {
    def counts = input_channel
        .map { meta, assembly ->
            [meta.species, 1]  // Extract species and assign initial count of 1
        }
        .groupTuple()  // Group by species
        .map { species, counts ->
            [species, counts.size()]  // Count occurrences of each species
        }

    return counts
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMPLESHEET_CHECK } from '../../modules/local/pre_processing/samplesheet_check.nf'
include { RENAME_INPUTS     } from '../../modules/local/pre_processing/renameinputs.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    ch_versions = Channel.empty()
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_assembly_channel(it) }
        .set { assemblies }
    count_species(assemblies)
    .set{species_count}
    ch_versions = ch_versions.mix(SAMPLESHEET_CHECK.out.versions)
    //
    // Rename the input files if desired
    //
    prepped_assemblies = Channel.empty()
    if (params.rename_files) {
        // Rename the files
        RENAME_INPUTS(assemblies)
        prepped_assemblies = prepped_assemblies.mix(RENAME_INPUTS.out.renamed_files)
    }
    else {
        prepped_assemblies = prepped_assemblies.mix(assemblies)
    }

    emit:
    species_count                             // channel: [ val(species), val(count) ]
    ch_sample_assemblies = prepped_assemblies // channel: [ val(meta), assembly ]
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
