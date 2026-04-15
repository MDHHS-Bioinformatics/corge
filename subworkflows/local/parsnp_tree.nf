//
// Build a phylogenetic tree using prior Parsnp results
//


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { CONVERT_XMFA_FASTA                       } from '../../modules/local/parsnp/convert_xmfa_fasta.nf'
include { IQTREE as IQTREE_PARSNP                  } from '../../modules/local/tree/iqtree.nf'
include { CONSTANTSITES as CONSTANT_SITES_PARSNP   } from '../../modules/local/tree/constant_sites.nf'
include { ROOT_TREE as ROOT_TREE_PARSNP            } from '../../modules/local/tree/root_tree.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow TREE_PARSNP {

    take:
    ch_parsnp_species   // channel: [[species,count]]
    ch_parsnp_xmfa      // channel: [ val(meta), xmfa ]
    ch_parsnp_snps      // channel: [ val(meta), snp_msa ]

    main:

    ch_versions = Channel.empty()
    //
    // MODULE: Generate an ML tree based on SNPs with adjusted branch length
    //
    ch_snp_tree = Channel.empty()
    CONVERT_XMFA_FASTA(ch_parsnp_xmfa)
    ch_versions = ch_versions.mix(CONVERT_XMFA_FASTA.out.versions)
    
    CONSTANT_SITES_PARSNP(CONVERT_XMFA_FASTA.out.core_aln)
    ch_versions = ch_versions.mix(CONSTANT_SITES_PARSNP.out.versions)

    const_ch = CONSTANT_SITES_PARSNP.out.constant_sites.map { meta, p -> tuple(meta, p.text.trim())}

    iqtree_input = ch_parsnp_snps
        .join(const_ch)
        .map { meta, msa, const_sites ->
            tuple(meta, msa, const_sites)
        }
    IQTREE_PARSNP(iqtree_input)
    ch_versions = ch_versions.mix(IQTREE_PARSNP.out.versions)

    ROOT_TREE_PARSNP(IQTREE_PARSNP.out.phylogeny)
    ch_versions = ch_versions.mix(ROOT_TREE_PARSNP.out.versions)
    ch_snp_tree = ROOT_TREE_PARSNP.out.tre

    emit:
    snp_tree            = ch_snp_tree                                 //channel: [val(meta), tree]
    versions            = ch_versions                                 // channel: [ versions.yml ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
