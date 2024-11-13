include { MASTER_MANIFEST_CHECK } from '../../modules/local/mastermanifestcheck.nf'

workflow INPUT_CHECK_MASTER_MANIFEST {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    MASTER_MANIFEST_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_fastq_channel(it) }
        .set { master_info }

    count_species(master_info)
    .set{species_count}

    emit:
    species_count
    master_info                                     // channel: [ val(meta), [ reads ] ]
    versions = MASTER_MANIFEST_CHECK.out.versions // channel: [ versions.yml ]
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def create_fastq_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id         = row.sample
    meta.single_end = row.single_end ? row.single_end.toBoolean() : false
    meta.species    = row.species


    // add path(s) of the fastq file(s) to the meta map
    def master_meta = []
    if (!file(row.fastq_1).exists() and !file(row.fastq_2).exists()) {
        exit 1, "ERROR: Please check master manifest -> Read 1/2 FastQ file does not exist!\n ${row.fastq_1} or ${row.fastq_2}"
    }
    else if (!file(row.gff).exists()) {
        exit 1, "ERROR: Please check master manifest -> GFF file does not exist!\n ${row.gff}"
    }
    else if (!file(row.assembly).exists()) {
        exit 1, "ERROR: Please check master manifest -> Assembly file does not exist!\n ${row.assembly}"
    }
    master_meta = [meta, [file(row.fastq_1), file(row.fastq_2)], file(row.gff), file(row.assembly)]
    return master_meta
}

// Function to count how many samples for each species there are
def count_species(input_channel) {
    def species_counting = input_channel
        .map { meta, fastqs, gff, assembly ->
            [meta.species, 1]  // Extract species and assign initial count of 1
        }
        .groupTuple()  // Group by species
        .map { species, counts ->
            [species, counts.size()]  // Count occurrences of each species
        }

    return species_counting
}
