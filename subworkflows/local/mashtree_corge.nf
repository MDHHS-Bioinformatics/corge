//
// Run MashTree using all assemblies in database
//
/*
=============================================================================================================================
    SUBWORKFLOW FUNCTIONS
=============================================================================================================================
*/

//Function to get all assembly files for each species
def get_all_assemblies(species) {
    // Create the path to get all fasta files
    def all_assemblies = file("${params.outdir}/${species}/assemblies/*.{fasta,fa,fas,fna}")
    return all_assemblies
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL AND NF-COR MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { MASHTREE              } from '../../modules/nf-core/mashtree/main.nf'
include { ROOT_TREE             } from '../../modules/local/post_processing/root_tree.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow MASHTREE_CORGE {

    take:
    ch_samples           // channel: [ val(meta), assembly ]
    ch_chewbbaca_species // channel: [[species, count], cgmlst] //counts included the latest assemblies
    ch_parsnp_species    // channel: [[species,count]] //counts included the latest assemblies

    main:

    ch_versions = Channel.empty()
    //
    // Get unique species of samples in the batch
    //
    ch_species = ch_samples
    .map{ meta, assembly -> meta.species }
    .distinct()
    //
    // For each species get the all fasta files
    //
    ch_all_assemblies = Channel.empty()

    ch_all_assemblies = ch_all_assemblies
    .mix(
        ch_chewbbaca_species.map { meta, cgmlst -> 
            def sp = meta.species
            tuple(sp, get_all_assemblies(sp))
        } 
    )
    
    ch_all_assemblies = ch_all_assemblies
    .mix(
        ch_parsnp_species.map { meta -> 
            def sp = meta[0].species
            tuple(sp, get_all_assemblies(sp))
        }
    )
    //
    //
    // Filter assemblies only for species in the batch
    ch_sp_assemblies = ch_species
    .join(ch_all_assemblies)
    .map { species, assemblies -> tuple([species: species], assemblies) }
    //
    //
    // MODULE: Run Mashtree on all the assemblies for each species, both new and historic
    //
    MASHTREE(
       ch_sp_assemblies
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
    mashtree_tree       = ROOT_TREE.out.tre    //channel: [val(meta), tree]
    mashtree_matrix     = MASHTREE.out.matrix  //channel: [val(meta), matrix]
    versions            = ch_versions         // channel: [ versions.yml ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
