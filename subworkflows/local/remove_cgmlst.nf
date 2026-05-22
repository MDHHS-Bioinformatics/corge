//
// Remove samples from database and update cgMLST results and ReporTree
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { REMOVE_FROM_PARTITIONS                   } from '../../modules/local/remove_samples/remove_from_partitions.nf'
include { REMOVE_FROM_ALLELES                      } from '../../modules/local/remove_samples/remove_from_alleles.nf'
include { CHECK_METADATA                           } from '../../modules/local/reportree/check_metadata.nf'
include { REPORTREE_CGMLST                         } from '../../modules/local/reportree/reportree_cgmlst.nf'
include { CHEWBBACA_COMPUTEMSA                     } from '../../modules/local/chewbbaca/computemsa.nf'
include { IQTREE as IQTREE_CGMLST                  } from '../../modules/local/tree/iqtree.nf'
include { CONSTANTSITES as CONSTANT_SITES_CGMLST   } from '../../modules/local/tree/constant_sites.nf'
include { ROOT_TREE as ROOT_TREE_CGMLST            } from '../../modules/local/tree/root_tree.nf'

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
    // MODULE: If a phylogenetic tree is required compute MSA from cgMLST alleles and generate ML tree
    //
    ch_snp_tree = Channel.empty()
    if(params.tree) {
        ch_masked_by_species = REMOVE_FROM_ALLELES.out.masked_alleles
            .map { meta, alleles ->
                tuple([species: meta.species], alleles)
            }
       
        samples_to_remove
            .join(schemas_by_species) // [ species, ids, count, schema ]
            .map { species, ids, count, schema ->
            def meta = [species: species]
            tuple(meta, schema) }
            .set{ch_schema_by_species} 
        
        ch_alleles_schema = ch_schema_by_species
            .join(ch_masked_by_species)
            .map { meta, schema, alleles ->
                tuple(meta, schema, alleles)
            }

        CHEWBBACA_COMPUTEMSA(ch_alleles_schema)
        ch_versions = ch_versions.mix(CHEWBBACA_COMPUTEMSA.out.versions)
        
        CONSTANT_SITES_CGMLST(CHEWBBACA_COMPUTEMSA.out.dna_msa)
        ch_versions = ch_versions.mix(CONSTANT_SITES_CGMLST.out.versions)

        const_ch = CONSTANT_SITES_CGMLST.out.constant_sites
            .map { meta, p ->
                tuple([species: meta.species], p.text.trim())
            }
        iqtree_input = CHEWBBACA_COMPUTEMSA.out.dna_msa
            .join(const_ch)
            .map { meta, msa, const_sites ->
                tuple(meta, msa, const_sites)
            }

        IQTREE_CGMLST(iqtree_input)
        ch_versions = ch_versions.mix(IQTREE_CGMLST.out.versions)

        ROOT_TREE_CGMLST(IQTREE_CGMLST.out.phylogeny)
        ch_versions = ch_versions.mix(ROOT_TREE_CGMLST.out.versions)

        ch_snp_tree = ROOT_TREE_CGMLST.out.tre
    }

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
    ch_reportree_input = REMOVE_FROM_ALLELES.out.masked_alleles
        .join(ch_metadata)
        .join(REMOVE_FROM_PARTITIONS.out.partitions)
        .map { meta, masked_alleles, metadata_tsv, previous_partitions ->
            tuple(meta, masked_alleles, metadata_tsv, previous_partitions)
        }

    REPORTREE_CGMLST(
        ch_reportree_input
        )
    ch_versions = ch_versions.mix(REPORTREE_CGMLST.out.versions)
    
    emit:
    dist_hamming        = REPORTREE_CGMLST.out.dist_hamming           //channel: [val (meta), dist_hamming ]
    partitions          = REPORTREE_CGMLST.out.partitions             //channel: [val (meta), partitions_summary]
    dist_tree           = REPORTREE_CGMLST.out.single_HC              //channel: [val(meta), single_hc]
    cluster_composition = REPORTREE_CGMLST.out.cluster_composition    //channel: [val(meta), cluster_composition]
    loci_report         = REPORTREE_CGMLST.out.loci_report           //channel: [val(meta), loci_report]
    snp_tree            = ch_snp_tree                                 //channel: [val(meta), tree]
    versions            = ch_versions                                 // channel: [ versions.yml ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
