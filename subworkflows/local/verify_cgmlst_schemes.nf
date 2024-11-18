//
// Perform Snippy analysis by species per clsuter
//

//Modules

/*
=============================================================================================================================
    SUBWORKFLOW FUNCTIONS
=============================================================================================================================
*/

//Function for determinnning if a prior schema exists for the species being analyzed
def check_schema(species) {
    //create the path to what should be the schema for the species
    species_schema_path = file(file(params.schema_dir).resolve(species))
    //check if this species schema_path exists
    species_schema_exists = species_schema_path.exists() ? true : false
    return species_schema_exists
}
//Function to sum the new species counts and the previous species counts from our master file
def merge_species_counts(new_counts,old_counts) {
    return new_counts
        .mix(old_counts)
        .groupTuple()
        .map{ species, counts ->
        [species, counts.sum()]}
}
//Function to find how many samples there are per species
// def add_species_counts(count_channel, species_name) {
//     ch_species = Channel.of(species_name)
//     ch_species
//         .mix(count_channel)
//         .groupTuple()
//         .map { species, counts -> counts}
//     return ch_species
// }
def add_species_counts(count_channel, species_name) {
    return count_channel
        .filter { it[0] == species_name }
        .map { it[1] }
        .first()
        .val
}
def remmap_counts(ch_counts) {
    ch_counts
        .collectEntries { species, count -> [(species) : count]}
    return ch_counts
}
workflow VERIFY_CGMLST_SCHEMES {

    take:
    // TODO nf-core: edit input (take) channels
    ch_assemblies   // channel: [ val(meta), gff, assemblies]
    ch_new_species_count
    ch_previous_species_count

    main:
    ch_versions = Channel.empty()
    //ch_previous_species_count.view()
    ch_total_counts = merge_species_counts(ch_new_species_count,ch_previous_species_count)
    //ch_total_counts.view()
    ch_assemblies.view()
    // First, collect ch_total_counts into a map, keys are species names, and values are the counts
    ch_total_counts_map = ch_total_counts.toList().map { counts ->
        counts.collectEntries { it -> [(it[0]): it[1]] }
    }
    //ch_total_counts_map.view()
    // Now combine ch_assemblies with the map of total counts
    ch_assemblies_with_counts = ch_assemblies
        .combine(ch_total_counts_map)
        .map { meta, gff, assemblies, counts_map ->
            def species_count = counts_map[meta.species] ?: 0
            tuple([id: meta.id, single_end: meta.single_end, species: meta.species,species_count:species_count], gff, assemblies, check_schema(meta.species))
        }
        .branch {
            scheme_available: it[3] == true
            scheme_unavailable: it[3] == false
        }
        .set { ch_schemes_availability }
    //Check whether cgMLST schemes are avaiable
    // ch_assemblies
    //     .map{meta, gff, assemblies ->
    //         tuple(meta, gff, assemblies, check_schema(meta.species),add_species_counts(ch_total_counts,meta.species) )
    //         }
    //     .branch{
    //         scheme_available : it[3] == true
    //         scheme_unavailable : it[3] == false
    //     }
    //     .set{ch_schemes_availability}
    //Check if there is more than one sample for each species for samples with no cgMLST
    // ch_schemes_availability.scheme_unavailable
    //     .map { meta, gff, assemblies, status -> tuple(meta.species, meta, gff, assemblies) }
    //     .groupTuple(by:[0])
    //     .map { species, meta, gff, assemblies -> tuple(meta, gff, assemblies)}
    //     .branch{
    //         skip_core_genome_analysis : it[2].size() ==1 //skipping core genome analysis if species only has one sample
    //         run_parsnp : true //if more than 1 sample per species, run parsnp
    //     }
    // .set { ch_no_schemes }
    //ch_assemblies.scheme_available.view()
    ch_schemes_availability.scheme_unavailable.view()
    //Format channel for samples/species that do have a cgMLST
    //ch
    emit:
    // TODO nf-core: edit emitted channels
    versions = ch_versions                     // channel: [ versions.yml ]
}

