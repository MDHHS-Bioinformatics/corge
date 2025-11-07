// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { BACTERIAL_LINKAGE      } from '../../modules/local/bacterial_linkage.nf'
include { UPDATE_MASTER_MANIFEST } from '../../modules/local/update_master_manifest.nf'
include { GET_BEST_PARTITION     } from '../../modules/local/get_best_partition.nf'
include { CLUSTER_SELECTION      } from '../../modules/local/cluster_selection.nf'
include { CONCAT_BEST_PARTITIONS } from '../../modules/local/concat_best_partitions.nf'

workflow LINKAGE_ANALYSIS {

    take:
    // TODO nf-core: edit input (take) channels
    ch_chewbbaca_dist_hamming         // channel: [ val(meta), [ results ] ]
    ch_parsnp_dist_hamming            // channel: [ val(meta), [ results ] ]
    ch_chewbbaca_cluster_composition  // channel: [ val(meta), [ cluster_composition ] ]
    ch_parsnp_cluster_composition     // channel: [ val(meta), [ cluster_composition ] ]

    main:

    ch_versions = Channel.empty()

    //Combine all the distance matrix
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

    //Combine all the cluster composition files
    ch_all_cluster_composition = Channel.empty()
    ch_all_cluster_composition = ch_all_cluster_composition.mix(ch_chewbbaca_cluster_composition)
    ch_all_cluster_composition = ch_all_cluster_composition.mix(ch_parsnp_cluster_composition)

    //
    // MODULE: Get the partions for each species
    //
    CLUSTER_SELECTION(
        ch_all_cluster_composition
    )

    emit:
    potential_linkages  = BACTERIAL_LINKAGE.out.potential_linkages     //channel: [ val(meta), potential_linkages]
    selected_cluster    = CLUSTER_SELECTION.out.genomic_context_groups //channel: [ val(meta), cluster_selection]

    versions = ch_versions                     // channel: [ versions.yml ]
}

