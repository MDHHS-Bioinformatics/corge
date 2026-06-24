/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowCorgeplus.initialise(params, log)

// Check schema path parameters to see if they exist
// Define speciesList/outdir_abs at script level (before the if block)
def speciesList = []
if (params.mode == 'tree') { //following params only need to be validated for tree mode
    def checkPathParamList = [params.outdir]
    for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

    if (params.species == null) {
        exit 1, 'Missing --species.  Provide a species or list of species separated by commas, no spaces allowed'}
    
    def raw = params.species?.toString() ?: ''
    speciesList = raw.split(/,/).collect { it.trim() }.unique()

    println "Species requested to build a ML tree: ${speciesList.join(', ')}" 
}

def master_paths = params.master_paths ? file(params.master_paths) : null

// Define paths from outdir as channels
def outdir_abs = file(params.outdir).toAbsolutePath()

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// MODULES
include { MICROREACT_ML as MICROREACT_ML_CGMLST  } from '../modules/local/microreact/microreact_ml.nf'
include { MICROREACT_ML as MICROREACT_ML_SNP     } from '../modules/local/microreact/microreact_ml.nf'

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK_CGMLST          } from '../subworkflows/local/input_check_cgmlst.nf'
include { VERIFY_PREVIOUS_RESULTS     } from '../subworkflows/local/verify_previous_results.nf'
include { TREE_CGMLST                 } from '../subworkflows/local/chewbbaca_tree.nf'
include { TREE_PARSNP                 } from '../subworkflows/local/parsnp_tree.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow TREE {

    ch_versions = Channel.empty()
    
    ch_species_count_input = Channel
        .fromList(speciesList)
        .map { sp -> tuple(sp.trim(), 1) }

    if (params.cgmlst_schemas) {
        INPUT_CHECK_CGMLST(
            file(params.cgmlst_schemas),
            ch_species_count_input
        )

        ch_species_counts_cgmlst  = INPUT_CHECK_CGMLST.out.species_counts_cgmlst
        ch_species_count_nocgmlst = INPUT_CHECK_CGMLST.out.species_count_nocgmlst
        ch_versions               = ch_versions.mix(INPUT_CHECK_CGMLST.out.versions)

    } else {
        ch_species_counts_cgmlst = Channel.empty()

        ch_species_count_nocgmlst = ch_species_count_input
            .map { species, count ->
                tuple([species: species, count: count ?: 0])
            }
    }
    //
    // SUBWORKFLOW: Check the previous results if provided and determine what analysis will be performed for each species
    //
    VERIFY_PREVIOUS_RESULTS(
        ch_species_counts_cgmlst,
        ch_species_count_nocgmlst
    )

    // helper closure to build an existing-file channel given a template
    def existingFileChannelCg = { ch_meta, String template ->
        ch_meta.map { metaIn, path_to_cgmlst ->
            def species = metaIn.species
            def count   = metaIn.count

            def meta = [species: species, count: count]
            def f = outdir_abs.resolve(template.replace('<species>', species))
            tuple(meta, file(f, checkIfExists: true))
        }
    }

    def existingFileChannelPn = { ch_meta, String template ->
        ch_meta.map { metaList ->
            def metaIn = metaList[0]
            def species = metaIn.species

            def meta = [species: species]
            def f = outdir_abs.resolve(template.replace('<species>', species))
            tuple(meta, file(f, checkIfExists: true))
        }
    }

    def existingFileChannel = { ch_meta, String template ->
        ch_meta.map { species, count ->
            def meta = [species: species]

            def f = outdir_abs.resolve(
                template.replace('<species>', meta.species)
            )

            tuple(meta, file(f, checkIfExists: true))
        }
    }

    // cgMLST-only
    ch_cgmlst_profile = existingFileChannelCg(
        VERIFY_PREVIOUS_RESULTS.out.species_to_chewbbaca,
        "<species>/cgMLST/masked/<species>_masked_results_alleles.tsv"
    )

    // Parsnp-only
    ch_parsnp_xmfa = existingFileChannelPn(
        VERIFY_PREVIOUS_RESULTS.out.species_to_parsnp,
        "<species>/parsnp/<species>_parsnp.xmfa"
    )

    ch_parsnp_snps = existingFileChannelPn(
        VERIFY_PREVIOUS_RESULTS.out.species_to_parsnp,
        "<species>/parsnp/<species>_snps_alignment.fasta"
    )

    // present for all species
    ch_dist_tree = existingFileChannel(
        ch_species_count_input,
        "<species>/ReporTree/<species>_single_HC.nwk"
    )

    ch_partitions_tsv = existingFileChannel(
        ch_species_count_input,
        "<species>/ReporTree/<species>_partitions.tsv"
    )

    ch_mashtree_tree = existingFileChannel(
        ch_species_count_input,
        "<species>/mashtree/<species>_rooted_mash.tre"
    )
    //
    // SUBWORKFLOW: Make phylogenetic trees
    //
    TREE_CGMLST(ch_species_counts_cgmlst, ch_cgmlst_profile)
    ch_versions = ch_versions.mix(TREE_CGMLST.out.versions)

    TREE_PARSNP(ch_species_count_nocgmlst, ch_parsnp_xmfa, ch_parsnp_snps)
    ch_versions = ch_versions.mix(TREE_PARSNP.out.versions)

    //
    // MODULE: Make a Microreact file with trees and selected groups
    //
    template_microreact_ml = file(params.microreact_template_ml)

    // Using cgMLST results
    ch_cgmlst_microreact_ml = ch_partitions_tsv
        .join(ch_dist_tree)
        .map { meta, partitions_tsv, dist_tree ->
            [[species: meta.species], partitions_tsv, dist_tree]}
        .join(TREE_CGMLST.out.snp_tree)
        .join(ch_mashtree_tree)
        .map { meta, partitions_tsv, dist_tree, snp_tree, mashtree_tree ->
            tuple(meta, partitions_tsv, dist_tree, snp_tree, mashtree_tree, template_microreact_ml)}

    MICROREACT_ML_CGMLST(
        ch_cgmlst_microreact_ml
    )
    ch_versions = ch_versions.mix(MICROREACT_ML_CGMLST.out.versions)

    // Using Parsnp results
    ch_parsnp_microreact_ml = ch_partitions_tsv
        .join(ch_dist_tree)
        .join(TREE_PARSNP.out.snp_tree)
        .map{meta, partitions_tsv, dist_tree, snp_tree -> 
            [[species:meta.species], partitions_tsv, dist_tree, snp_tree]}
        .join(ch_mashtree_tree)         
        .map { meta, partitions_tsv, dist_tree, snp_tree, mashtree_tree ->
            tuple(meta, partitions_tsv, dist_tree, snp_tree, mashtree_tree, template_microreact_ml)}

    MICROREACT_ML_SNP(
        ch_parsnp_microreact_ml
    )
    ch_versions = ch_versions.mix(MICROREACT_ML_SNP.out.versions)

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
