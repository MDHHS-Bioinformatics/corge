// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { BACTERIAL_LINKAGE      } from '../../modules/local/bacterial_linkage.nf'
include { UPDATE_MASTER_MANIFEST } from '../../modules/local/update_master_manifest.nf'
include { GET_BEST_PARTITION     } from '../../modules/local/get_best_partition.nf'
include { CONCAT_BEST_PARTITIONS } from '../../modules/local/concat_best_partitions.nf'

workflow LINKAGE_ANALYSIS {

    take:
    // TODO nf-core: edit input (take) channels
    ch_chewbbaca_dist_hamming  // channel: [ val(meta), [ results ] ]
    ch_parsnp_dist_hamming     // channel: [ val(meta), [ results ] ]
    ch_chewbbaca_partitions_summary  // channel: [ val(meta), [ partitions_summary ] ]
    ch_parsnp_partitions_summary     // channel: [ val(meta), [ partitions_summary ] ]

    main:

    ch_versions = Channel.empty()
    //Add a scheme avaiability boolean value based on whether a cgMLST scheme exists
    ch_chewbbaca_partitions_summary
        .map {meta, partitions_summary -> [[species:meta.species, scheme_available:true], partitions_summary]}
        .set {ch_chewbbaca}
    ch_parsnp_partitions_summary
        .map {meta, partitions_summary -> [[species:meta.species, scheme_available:false], partitions_summary]}
        .set {ch_parsnp}
    //create channel to store all reportree partitions summary results
    ch_all_partitions_summary = Channel.empty()
    ch_all_partitions_summary = ch_all_partitions_summary.mix(ch_chewbbaca)
    ch_all_partitions_summary = ch_all_partitions_summary.mix(ch_parsnp)
    ch_all_partitions_summary.view()

    //create channel to store all reportree dist_hamming results
    ch_all_dist_hamming = Channel.empty()
    ch_all_dist_hamming = ch_all_dist_hamming.mix(ch_chewbbaca_dist_hamming)
    ch_all_dist_hamming= ch_all_dist_hamming.mix(ch_parsnp_dist_hamming)
    //ch_all_dist_hamming.view()

    //
    // MODULE: Create bacterial linkage table per species
    //
    BACTERIAL_LINKAGE(
        ch_all_dist_hamming
    )

    //
    // MODULE: Update the master manifest file
    //
    UPDATE_MASTER_MANIFEST(
        file(params.input),
        file(params.reads_manifest),
        file(params.master_manifest)
    )

    //
    // MODULE: Get the best partitions per species
    //
    GET_BEST_PARTITION(
        ch_all_partitions_summary,
        UPDATE_MASTER_MANIFEST.out.updated_manifest,
        file(params.input)
    )

    //Initiailze channel to collect all partitions
    ch_all_partitions = Channel.empty()
    ch_all_partitions = ch_all_partitions.mix(GET_BEST_PARTITION.out.best_partitions.collect{it[1]}.ifEmpty([]))
    ch_all_partitions.view()

    //
    //MODULE: Combine all the partitions summary into one
    //
    CONCAT_BEST_PARTITIONS(
        ch_all_partitions
    )
    //
    // SAMTOOLS_SORT ( ch_bam )
    // ch_versions = ch_versions.mix(SAMTOOLS_SORT.out.versions.first())

    // SAMTOOLS_INDEX ( SAMTOOLS_SORT.out.bam )
    // ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions.first())

    emit:
    // TODO nf-core: edit emitted channels
    // bam      = SAMTOOLS_SORT.out.bam           // channel: [ val(meta), [ bam ] ]
    // bai      = SAMTOOLS_INDEX.out.bai          // channel: [ val(meta), [ bai ] ]
    // csi      = SAMTOOLS_INDEX.out.csi          // channel: [ val(meta), [ csi ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}

