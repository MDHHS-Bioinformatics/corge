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
//This version only uses the latest input counts per species
//Since the master manifest is expected to have the same samples as well, we don't want to double count
workflow VERIFY_CGMLST_SCHEMES_NPR {

    take:
    // TODO nf-core: edit input (take) channels
    ch_assemblies   // channel: [ val(meta), gff, assemblies]
    ch_new_species_count
    //ch_previous_species_count

    main:
    ch_versions = Channel.empty()
    //ch_total_counts = merge_species_counts(ch_new_species_count,ch_previous_species_count)
    // First, collect ch_total_counts into a map, keys are species names, and values are the counts
    ch_total_counts_map = ch_new_species_count.toList().map { counts ->
        counts.collectEntries { it -> [(it[0]): it[1]] }
    }
    //Check whether cgMLST schemes are avaiable
    ch_assemblies_with_counts = ch_assemblies
        .combine(ch_total_counts_map)
        .map { meta, gff, assemblies, counts_map ->
            def species_count = counts_map[meta.species] ?: 0
            tuple([id: meta.id, single_end: meta.single_end, species: meta.species,species_count:species_count, schema: check_schema(meta.species)], gff, assemblies)
        }
        .branch {
            scheme_available: it[0].schema == true
            scheme_unavailable: it[0].schema == false
        }
        .set { ch_schemes_availability }

    //Check if there is more than one sample for each species for samples with no cgMLST
    ch_schemes_availability.scheme_unavailable
        .branch {
            meta, gff, assemblies ->
            skip_core_genome_analysis: meta.species_count == 1
            run_parsnp: meta.species_count > 1
        }
        .set { ch_no_schemes }

    emit:
    // TODO nf-core: edit emitted channels
    samples_to_chewbbaca                = ch_schemes_availability.scheme_available
    samples_to_parsnp                   = ch_no_schemes.run_parsnp
    samples_to_skip_analysis            = ch_no_schemes.skip_core_genome_analysis
    versions = ch_versions                     // channel: [ versions.yml ]
}

