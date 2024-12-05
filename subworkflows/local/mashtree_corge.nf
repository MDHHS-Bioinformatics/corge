// include { SAMTOOLS_SORT      } from '../../../modules/nf-core/samtools/sort/main'
// include { SAMTOOLS_INDEX     } from '../../../modules/nf-core/samtools/index/main'
include { MASHTREE              } from '../../modules/nf-core/mashtree/main'

workflow MASHTREE_CORGE {

    take:
    // TODO nf-core: edit input (take) channels
    //ch_bam // channel: [ val(meta), [ bam ] ]
    samples_to_chewbbaca
    samples_to_parsnp
    master_info

    main:

    ch_versions = Channel.empty()
    //Create empty channel for all the samples
    ch_all_samples = Channel.empty()
    //Add all the samples to a channel
    ch_all_samples = ch_all_samples.mix(samples_to_parsnp)
    ch_all_samples = ch_all_samples.mix(samples_to_chewbbaca)
    //Branch the channel by only species that have more than one samples
    ch_all_samples
        .map{
            meta, gff, assemblies ->
            [[species:meta.species, species_count:meta.species_count], gff, assemblies]
        }
        .branch{
            meta, gff, assemblies ->
            to_mash: meta.species_count > 1
            no_mash: meta.species_count == 1
        }
        .set{ch_prepped_samples}
    //Remap the samples to only include the species value
    ch_prepped_samples.to_mash
        .map{
            meta, gff, assemblies ->
            [[species:meta.species], assemblies]
        }
        .groupTuple()
        .set{ch_samples_to_mash}
    //Remap the master samples to only have the assemblies
    master_info
        .map{
            meta, fastqs, gff, assemblies ->
            [[species:meta.species], assemblies]
        }
        .groupTuple()
        .set{master_assemblies}
    //Join the new samples and the historic samples
    ch_new_and_historic_assemblies = ch_samples_to_mash.join(master_assemblies)
        .map{meta, new_assemblies, old_assemblies -> [meta, new_assemblies+old_assemblies]}

    //
    //MODULE: Run Mashtree on all the assemblies for each species, both new and historic
    //
    MASHTREE(
        ch_new_and_historic_assemblies
    )
    emit:
    // TODO nf-core: edit emitted channels
    // bam      = SAMTOOLS_SORT.out.bam           // channel: [ val(meta), [ bam ] ]
    // bai      = SAMTOOLS_INDEX.out.bai          // channel: [ val(meta), [ bai ] ]
    // csi      = SAMTOOLS_INDEX.out.csi          // channel: [ val(meta), [ csi ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}

