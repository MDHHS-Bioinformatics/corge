workflow VERIFY_PREVIOUS_RESULTS {
    take:
    //previous_results       // path to previous results
    species_counts_cgmlst    // channel: [[species], count, path_to_cgmlst]
    species_counts_nocgmlst  // channel: [[species], count]

    main:
    total_counts_cgmlst = Channel.empty()
    total_counts_nocgmlst = Channel.empty()

    //Check the previous results
    if (params.previous_results){
        //count the number of fasta files for species with a cgmlst
        count_fasta_files_cgmlst(species_counts_cgmlst)
        .set{previous_cgmlst_counts}
        total_counts_cgmlst = total_counts_cgmlst.mix(previous_cgmlst_counts)

        //count the number of fasta files for species without a cgmlst
        count_fasta_files_nocgmlst(species_counts_nocgmlst)
        .set{previous_nocgmlst_counts}
        total_counts_nocgmlst = total_counts_nocgmlst.mix(previous_nocgmlst_counts)
    } else {
        total_counts_cgmlst = total_counts_cgmlst.mix(species_counts_cgmlst)
        total_counts_nocgmlst = total_counts_nocgmlst.mix(species_counts_nocgmlst)
    }

    //now determine if we will run parsnp or skip the the core genome analysis for samples without a cgmlst
    total_counts_nocgmlst
        .branch{
            meta ->
            skip_core_genome_analysis: meta[0].count == 1
            run_parsnp: meta[0].count > 1
        }
    .set{ch_no_schemas}

    emit:
    species_to_chewbbaca        = total_counts_cgmlst       // [[species, count], path_to_cgmlst_scheme]
    species_to_parsnp           = ch_no_schemas.run_parsnp  // [[species,count]]
    species_to_skip_analysis    = ch_no_schemas.skip_core_genome_analysis // [[species,count]]
}

def count_fasta_files_cgmlst(input_channel) {
    return input_channel.map { meta, path_to_cgmlst ->
        def species = meta.species
        def input_count = meta.count
        def fasta_files = file("${params.previous_results}/${species}/assemblies/*.{fasta,fa,fas}")
        def count = fasta_files.size()  // Simply get the size - will be 0 if no files found

        return [[species:species, count:count + input_count], path_to_cgmlst]
    }
}
def count_fasta_files_nocgmlst(input_channel) {
    return input_channel.map { meta ->
        def actualMeta = meta[0]  // Get the first (and only) element of the list
        def species = actualMeta.species
        def input_count = actualMeta.count
        def fasta_files = file("${params.previous_results}/${species}/assemblies/*.{fasta,fa,fas}")
        def count = fasta_files.size()

        return [[species:species, count:count + input_count]]
    }
}
