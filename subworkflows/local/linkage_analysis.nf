// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

// include { SAMTOOLS_SORT      } from '../../../modules/nf-core/samtools/sort/main'
// include { SAMTOOLS_INDEX     } from '../../../modules/nf-core/samtools/index/main'
include { BACTERIAL_LINKAGE     } from '../../modules/local/bacterial_linkage.nf'

workflow LINKAGE_ANALYSIS {

    take:
    // TODO nf-core: edit input (take) channels
    ch_chewbbaca_dist_hamming  // channel: [ val(meta), [ results ] ]
    ch_parsnp_dist_hamming     // channel: [ val(meta), [ results ] ]

    main:

    ch_versions = Channel.empty()

    //create channel to store all reportree results
    ch_all_dist_hamming = Channel.empty()
    ch_all_dist_hamming = ch_all_dist_hamming.mix(ch_chewbbaca_dist_hamming)
    ch_all_dist_hamming= ch_all_dist_hamming.mix(ch_parsnp_dist_hamming)
    ch_all_dist_hamming.view()

    //
    // MODULE: Create bacterial linkage table per species
    //
    BACTERIAL_LINKAGE(
        ch_all_dist_hamming
    )
    // TODO nf-core: substitute modules here for the modules of your subworkflow

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

