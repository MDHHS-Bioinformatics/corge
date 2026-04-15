//
// Compute MSA based on cgMLST allele calls and build an ML tree
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CHEWBBACA_COMPUTEMSA                     } from '../../modules/local/chewbbaca/computemsa.nf'
include { IQTREE as IQTREE_CGMLST                  } from '../../modules/local/tree/iqtree.nf'
include { CONSTANTSITES as CONSTANT_SITES_CGMLST   } from '../../modules/local/tree/constant_sites.nf'
include { ROOT_TREE as ROOT_TREE_CGMLST            } from '../../modules/local/tree/root_tree.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow TREE_CGMLST {

    take:
    ch_cgmlst_schema    // [[species, count], path_to_cgmlst_scheme]
    ch_cgmlst_profile   // 
    
    main:
    ch_versions = Channel.empty()

    //
    // MODULE: If a phylogenetic tree is required compute MSA from cgMLST alleles and generate ML tree
    //
    ch_snp_tree = Channel.empty()
    ch_masked_by_species = ch_cgmlst_profile
        .map { meta, alleles ->
            tuple([species: meta.species], alleles)
        }
    ch_schema_by_species = ch_cgmlst_schema
        .map { meta, schema ->
            tuple([species: meta.species], schema)
        }
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

    emit:
    snp_tree            = ch_snp_tree  //channel: [val(meta), tree]
    versions            = ch_versions  //channel: [ versions.yml ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
