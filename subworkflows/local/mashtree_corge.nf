include { MASHTREE              } from '../../modules/nf-core/mashtree/main'
include { ROOT_TREE             } from '../../modules/local/root_tree.nf'

//Function to get all the previous assembly files for each species
def get_previous_assemblies(species ) {
    // Create the path to get the previous fasta files
    def previous_assemblies = file("${params.outdir}/${species}/assemblies/*.{fasta,fa,fas,fna}")
    return previous_assemblies
}

workflow MASHTREE_CORGE {

    take:
    ch_samples            //
    ch_chewbbaca_species // [[speices, count], cgmlst] //counts included the latest assemblies
    ch_parsnp_species    // [[species,count]] //counts included the latest assemblies

    main:

    ch_versions = Channel.empty()

    //For eaach species get the previous fasta files
    ch_previous_assemblies = Channel.empty()

    //Get the previous assemblies for chewbacca samples
    ch_previous_assemblies = ch_previous_assemblies.mix(
        ch_chewbbaca_species.map{
        meta, cgmlst -> [[species:meta.species], get_previous_assemblies(meta.species)]}
    )

    //Get the previous assemblies for parsnp samples
    ch_previous_assemblies = ch_previous_assemblies.mix(
        ch_parsnp_species.map{
                meta -> [[species:meta[0].species], get_previous_assemblies(meta[0].species)]
        }
    )
    //Join all the samples by species
    ch_samples.map{
        meta, assembly -> [[species:meta.species],assembly]
    }
    .groupTuple()
    .set{ch_samples_grouped_species}

    //Combine the new assemblies and the old assemblies
    ch_all_assemblies = ch_samples_grouped_species.join(ch_previous_assemblies)
        .map{meta,new_assemblies, old_assemblies -> [meta,new_assemblies+old_assemblies]}

    //If samples are reran, may cause occasional duplicates from inputs and old_assemblies
    //Deduplicate possible assemblies
    ch_deduplicated_assemblies = ch_all_assemblies
        .map{
            meta, files ->
            //Convert to File objects in case they're strings
            def file_objects = files.collect{
                it instanceof String ? file(it) : it
            }
            //Deduplicate by basename - keep first occurence of each basename
            def unique_files_map = [:]
            file_objects.each { file ->
                def basename = file.name
                if (!unique_files_map.containsKey(basename)){
                    unique_files_map[basename] = file
                }
            }
            return [meta, unique_files_map.values()]
        }
    //
    //MODULE: Run Mashtree on all the assemblies for each species, both new and historic
    //
    MASHTREE(
       ch_deduplicated_assemblies //ch_all_assemblies
    )
    ch_versions = ch_versions.mix(MASHTREE.out.versions)

    //
    // MODULE: Root the MashTree tree
    //
    ROOT_TREE(
        MASHTREE.out.tree
    )
    ch_versions = ch_versions.mix(ROOT_TREE.out.versions)

    emit:
    mashtree_tree       = ROOT_TREE.out.tre
    mashtree_matrix     = MASHTREE.out.matrix

    versions = ch_versions                     // channel: [ versions.yml ]
}

