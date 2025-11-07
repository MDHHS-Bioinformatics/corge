

include { SAMPLESHEET_CHECK_CGMLST } from '../../modules/local/samplesheet_check_cgmlst.nf'

workflow INPUT_CHECK_CGMLST {

    take:
    // TODO nf-core: edit input (take) channels
    cgmlst_schemas  // csv file containg species and path species schemas
    species_count   //channel: [species, counts]
    main:
    ch_versions = Channel.empty()

    //Check to make sure everything in the cgmlst file looks good
    SAMPLESHEET_CHECK_CGMLST ( cgmlst_schemas)
        .csv
        .splitCsv (header:true, sep:',')
        .map{ create_cgmlst_channel(it)}
        .set{cgmlst_paths}
    //join the cgmlst paths with the species_count channel
    joined_species_count = species_count
    .join(cgmlst_paths.map{ meta, path -> [meta.species, [meta, path]]}, remainder:true)

    //Now branch based on if a cgmlst is a avaiable or not
    joined_species_count
    .branch {
        schema_unavaiable: it[2] == null
        chewbbaca: it[2] != null
    }
    .set{cgmlst_species_counts}

    //Reformat channel for species witha  cgmlst
    cgmlst_species_counts.chewbbaca.map{
        species, count, inner_tuple -> [[species:species, count:count], inner_tuple[1]]
    }
    .set{cgmlst_species}
    //Reformat channel for species with no cgmlst
    cgmlst_species_counts.schema_unavaiable.map{
        species, count, no_path -> [[species:species, count:count]]
    }
    .set{no_cgmlst_species}

    emit:
    species_counts_cgmlst  = cgmlst_species     // channel: [[species, count,], path_to_cgmlst]
    species_count_nocgmlst = no_cgmlst_species  // channel: [[species, count]]
    versions = ch_versions                     // channel: [ versions.yml ]
}

//Function to get set up our channel properly
def create_cgmlst_channel(LinkedHashMap row) {
    //create meta map
    def meta = [:]
    meta.species = row.species
    //add cgmlst paths
    def cgmlst_channel = []
    if (!file(row.cgmlst_path).exists()) {
        exit 1, "ERROR: Please check input cgmlst directory -> cgmlst directory does not exist!\n${row.cgmlst_path}"
    } else {
        cgmlst_channel = [meta, file(row.cgmlst_path)]
    }
    return cgmlst_channel
}
