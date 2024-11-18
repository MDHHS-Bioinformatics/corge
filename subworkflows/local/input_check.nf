//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_assembly_channel(it) }
        .set { assemblies }
    count_species(assemblies)
    .set{species_count}

    emit:
    species_count
    assemblies                                    // channel: [ val(meta), gff, assembly ]
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def create_assembly_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id         = row.sample
    meta.single_end = row.single_end ? row.single_end.toBoolean() : false
    meta.species    = row.species

    // add paths to the assemblies and gffs
    def assembly_meta = []
    if (!file(row.gff).exists() && !file(row.assembly).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> GFF or Assembly does not exist!\n${row.gff} or ${row.assembly}"
    } else {
        assembly_meta = [meta, file(row.gff), file(row.assembly)]
    }

    return assembly_meta
}

// Function to count how many samples for each species there are
def count_species(input_channel) {
    def counts = input_channel
        .map { meta, gff, assembly ->
            [meta.species, 1]  // Extract species and assign initial count of 1
        }
        .groupTuple()  // Group by species
        .map { species, counts ->
            [species, counts.size()]  // Count occurrences of each species
        }

    return counts
}
