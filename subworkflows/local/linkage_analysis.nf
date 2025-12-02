//
// Generate linkage table and genomic context group tables
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { BACTERIAL_LINKAGE      } from '../../modules/local/post_processing/bacterial_linkage.nf'
include { CLUSTER_SELECTION      } from '../../modules/local/post_processing/cluster_selection.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow LINKAGE_ANALYSIS {

    take:
    ch_chewbbaca_dist_hamming         // channel: [ val(meta), [ results ] ]
    ch_parsnp_dist_hamming            // channel: [ val(meta), [ results ] ]
    ch_chewbbaca_cluster_composition  // channel: [ val(meta), [ cluster_composition ] ]
    ch_parsnp_cluster_composition     // channel: [ val(meta), [ cluster_composition ] ]

    main:

    ch_versions = Channel.empty()
    //
    // Combine all the distance matrix
    //
    ch_all_dist_hamming = Channel.empty()
    ch_all_dist_hamming = ch_all_dist_hamming.mix(ch_chewbbaca_dist_hamming)
    ch_all_dist_hamming = ch_all_dist_hamming.mix(ch_parsnp_dist_hamming)
    //ch_all_dist_hamming.view()

    //
    // MODULE: Create bacterial linkage table per species
    //
    BACTERIAL_LINKAGE(
        ch_all_dist_hamming
    )
    ch_versions = ch_versions.mix(BACTERIAL_LINKAGE.out.versions)
    //
    // Combine all the cluster composition files
    //
    ch_all_cluster_composition = Channel.empty()
    ch_all_cluster_composition = ch_all_cluster_composition.mix(ch_chewbbaca_cluster_composition)
    ch_all_cluster_composition = ch_all_cluster_composition.mix(ch_parsnp_cluster_composition)
    //
    // MODULE: Get partions for each species
    //
    CLUSTER_SELECTION(
        ch_all_cluster_composition
    )
    ch_versions = ch_versions.mix(CLUSTER_SELECTION.out.versions)

    emit:
    potential_linkages  = BACTERIAL_LINKAGE.out.potential_linkages     //channel: [ val(meta), potential_linkages]
    selected_cluster    = CLUSTER_SELECTION.out.genomic_context_groups //channel: [ val(meta), cluster_selection]
    versions            = ch_versions                                  // channel: [ versions.yml ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
