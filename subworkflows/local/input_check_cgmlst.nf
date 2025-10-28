

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
    //.map{species, count, cgmlst -> [cgmlst[0],cgMLST[1] count]}

    //Now branch based on if a cgmlst is used or not
    joined_species_count
    .branch {
        parsnp: it[2] == null
        chewbbaca: it[2] != null
    }
    .set{cgmlst_species_counts}

    emit:
    species_counts_chewbbaca = cgmlst_species_counts.chewbbaca                  // channel: [ species, counts, [ meta, cgmlst_path ] ]
    species_counts_parsnp   = cgmlst_species_counts.parsnp                      // channel: [species, counts, null]
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
