//
// Check input samplesheet and get species count and sample assemblies channels
//

/*
=============================================================================================================================
    SUBWORKFLOW FUNCTIONS
=============================================================================================================================
*/
// Function to get list of [ meta, assembly ]
def create_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id         = row.sample
    meta.species    = row.species
    return meta
}

// Function to count how many samples for each species there are
def count_species(input_channel) {
    input_channel
        .map { meta -> tuple(meta.species, 1) } // Extract species and assign initial count of 1
        .groupTuple() // Group by species
        .map { species, counts -> tuple(species, counts.size()) } // Count occurrences of each species
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMPLESHEET_CHECK_RM } from '../../modules/local/pre_processing/samplesheet_check_rm.nf'
include { RENAME_INPUTS        } from '../../modules/local/pre_processing/renameinputs.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow INPUT_CHECK_REMOVE_SAMPLES {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    ch_versions = Channel.empty()
    SAMPLESHEET_CHECK_RM ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_channel(it) }
        .set { samples_rm }
    
    count_species(samples_rm)
    .set{species_count}

    ch_versions = ch_versions.mix(SAMPLESHEET_CHECK_RM.out.versions)
    
    //Group all the samples by species
    samples_rm
    .map { meta ->
        tuple(meta.species, meta.id)
    }
    .groupTuple()
    .set { samples_to_remove }

    emit:
    species_count             // channel: [ val(species), val(count) ]
    samples_to_remove         // channel: [ val(species), val(ids) ]
    versions          = SAMPLESHEET_CHECK_RM.out.versions // channel: [ versions.yml ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
