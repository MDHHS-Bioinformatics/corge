//
// Remove samples from database and update cgMLST results and ReporTree
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { REMOVE_FROM_PARTITIONS    } from '../../modules/local/remove_samples/remove_from_partitions.nf'
include { REMOVE_FROM_ALLELES       } from '../../modules/local/remove_samples/remove_from_alleles.nf'
include { CHECK_METADATA            } from '../../modules/local/reportree/check_metadata.nf'
include { REPORTREE_CGMLST          } from '../../modules/local/reportree/reportree_cgmlst.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow REMOVE_CGMLST {

    take:
    samples_to_remove      // channel: [ val(species), val(ids) ]
    species_to_chewbbaca   // channel: [[species, count], path_to_cgmlst_schema]
    outdir                 // file(params.outdir)
  
    main:

    ch_versions = Channel.empty()

    // Join samples to remove and schemas
    species_to_chewbbaca
        .map { info, schema ->
            tuple(info.species, info.count, schema)
        }
        .set { schemas_by_species }

    samples_to_remove
    .join(schemas_by_species) // [ species, ids, count, schema ]
    .map { species, ids, count, schema ->
    def meta = [species: species]
    tuple(meta, ids) }
    .set{ch_samples_rm_cgmlst} 

    //
    // MODULE: Remove selected samples from masked alleles
    //
    REMOVE_FROM_ALLELES(ch_samples_rm_cgmlst, 
                        outdir)
    ch_versions = ch_versions.mix(REMOVE_FROM_ALLELES.out.versions)

    //
    // MODULE: Remove selected samples from partitions
    //
    REMOVE_FROM_PARTITIONS(ch_samples_rm_cgmlst,
                            outdir)
    ch_versions = ch_versions.mix(REMOVE_FROM_PARTITIONS.out.versions)

    //
    // MODULE: Check that metadata has info for all the samples in the final masked_alleles results
    //
    if(params.metadata) {
        CHECK_METADATA(REMOVE_FROM_ALLELES.out.masked_alleles, file(params.metadata))
        ch_metadata = CHECK_METADATA.out.metadata
        ch_versions = ch_versions.mix(CHECK_METADATA.out.versions)}
    else {
        REMOVE_FROM_ALLELES.out.masked_alleles
        .map { meta, _ -> 
            def metadata = []
            tuple( meta, metadata)
        }
        .set { ch_metadata }
         }
         
    //
    // MODULE: Run ReporTree for hierarchical clustering and analysis
    //
    REPORTREE_CGMLST(
        REMOVE_FROM_ALLELES.out.masked_alleles,
        ch_metadata,
        REMOVE_FROM_PARTITIONS.out.partitions)
    ch_versions = ch_versions.mix(REPORTREE_CGMLST.out.versions)
    
    emit:
    dist_hamming        = REPORTREE_CGMLST.out.dist_hamming           //channel: [val (meta), dist_hamming ]
    partitions          = REPORTREE_CGMLST.out.partitions             //channel: [val (meta), partitions_summary]
    dist_tree           = REPORTREE_CGMLST.out.single_HC              //channel: [val(meta), single_hc]
    cluster_composition = REPORTREE_CGMLST.out.cluster_composition    //channel: [val(meta), cluster_composition]
    versions            = ch_versions                                 // channel: [ versions.yml ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
