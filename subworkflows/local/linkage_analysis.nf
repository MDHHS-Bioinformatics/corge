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
    ch_parsnp_snp_dists               // channel: [ val(meta), [ results ] ]
    ch_chewbbaca_cluster_composition  // channel: [ val(meta), [ cluster_composition ] ]
    ch_parsnp_cluster_composition     // channel: [ val(meta), [ cluster_composition ] ]
    ch_chewbbaca_loci_report          // channel: [ val(meta), [ loci_report ] ]
    ch_parsnp_alignment_stats         // channel: [ val(meta), [ log ] ]

    main:

    ch_versions = Channel.empty()
    //
    // Create two linkage input channels
    //
    ch_chewbbaca_linkage = ch_chewbbaca_dist_hamming
        .join(ch_chewbbaca_loci_report)
        .map { meta, dist_hamming, loci_report ->
            tuple(meta + [data_type: 'cgMLST'], dist_hamming, loci_report, [])
        }

    ch_parsnp_linkage = ch_parsnp_snp_dists
        .join(ch_parsnp_alignment_stats)
        .map { meta, snp_dists, parsnp_log ->
            tuple(meta + [data_type: 'SNP'], snp_dists, [], parsnp_log)
        }

    ch_dist_loci = ch_chewbbaca_linkage.mix(ch_parsnp_linkage)

    //
    // MODULE: Create bacterial linkage table per species
    //
    BACTERIAL_LINKAGE(
        ch_dist_loci
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
