/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowCorgeplus.initialise(params, log)

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.mode == 'default') {
    if (params.input) {
        ch_input = file(params.input)
    } else {
        exit 1, 'Input samplesheet not specified! (--input is required for mode: ' + params.mode + ')'
    }
}
def outdir_abs = file(params.outdir).toAbsolutePath().toString()
def master_paths = params.master_paths ? file(params.master_paths) : null

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
include { MICROREACT as MICROREACT_CGMLST        } from '../modules/local/microreact/microreact.nf'
include { MICROREACT as MICROREACT_SNP           } from '../modules/local/microreact/microreact.nf'
include { MICROREACT_ML as MICROREACT_ML_CGMLST  } from '../modules/local/microreact/microreact_ml.nf'
include { MICROREACT_ML as MICROREACT_ML_SNP     } from '../modules/local/microreact/microreact_ml.nf'
include { MAKE_POODLE_MANIFEST                   } from '../modules/local/post_processing/make_poodle_manifest.nf'
include { MAKE_POODLE_MANIFEST_MASTER            } from '../modules/local/post_processing/make_poodle_manifest_master.nf'

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK                 } from '../subworkflows/local/input_check'
include { INPUT_CHECK_CGMLST          } from '../subworkflows/local/input_check_cgmlst.nf'
include { VERIFY_PREVIOUS_RESULTS     } from '../subworkflows/local/verify_previous_results.nf'
include { MASHTREE_CORGE              } from '../subworkflows/local/mashtree_corge.nf'
include { CHEWBBACA_ANALYSIS          } from '../subworkflows/local/chewbbaca_analysis.nf'
include { PARSNP_ANALYSIS             } from '../subworkflows/local/parsnp_analysis.nf'
include { LINKAGE_ANALYSIS            } from '../subworkflows/local/linkage_analysis.nf'

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

workflow CORGEPLUS {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //
    // SUBWORKFLOW: Read in csv containing cgmlst paths per species and validate they exist
    //

    if (params.cgmlst_schemas) {
        INPUT_CHECK_CGMLST(
            file(params.cgmlst_schemas),
            INPUT_CHECK.out.species_count
        )

        ch_species_counts_cgmlst = INPUT_CHECK_CGMLST.out.species_counts_cgmlst
        ch_species_count_nocgmlst = INPUT_CHECK_CGMLST.out.species_count_nocgmlst
        ch_versions              = ch_versions.mix(INPUT_CHECK_CGMLST.out.versions)

    } else {
        ch_species_counts_cgmlst = Channel.empty()

        ch_species_count_nocgmlst = INPUT_CHECK.out.species_count
            .map { species, count ->
                [[species: species, count: count ?: 0]]
            }
    }

    //
    // SUBWORKFLOW: Check the previous results if provided and determine what analysis will be performed for each species
    //
    VERIFY_PREVIOUS_RESULTS(
        ch_species_counts_cgmlst,
        ch_species_count_nocgmlst
    )

    //
    // SUBWORKFLOW: Run ChewBBACA on samples with a schema
    //
    CHEWBBACA_ANALYSIS (
        INPUT_CHECK.out.ch_sample_assemblies,
        VERIFY_PREVIOUS_RESULTS.out.species_to_chewbbaca
    )
    ch_versions = ch_versions.mix(CHEWBBACA_ANALYSIS.out.versions)

    //
    // SUBWORKFLOW: Run Parsnp on samples without a schema
    //
    PARSNP_ANALYSIS (
        INPUT_CHECK.out.ch_sample_assemblies,
        VERIFY_PREVIOUS_RESULTS.out.species_to_parsnp
    )
    ch_versions = ch_versions.mix(PARSNP_ANALYSIS.out.versions)

    //
    // SUBWORKFLOW: Run MashTree and create microreact files
    //
    MASHTREE_CORGE(
        INPUT_CHECK.out.ch_sample_assemblies,
        VERIFY_PREVIOUS_RESULTS.out.species_to_chewbbaca,
        VERIFY_PREVIOUS_RESULTS.out.species_to_parsnp
    )
    ch_versions = ch_versions.mix(MASHTREE_CORGE.out.versions)

    //
    // MODULE: Make a Microreact file with trees and selected groups
    //
    if(!params.tree) {
        template_microreact = file(params.microreact_template)
        // Using cgMLST results
        ch_cgmlst_microreact = CHEWBBACA_ANALYSIS.out.partitions
            .join(CHEWBBACA_ANALYSIS.out.dist_tree)
            .map { meta, partitions_tsv, dist_tree ->
                [[species: meta.species], partitions_tsv, dist_tree]
            }
            .join(MASHTREE_CORGE.out.mashtree_tree)
            .map { meta, partitions_tsv, dist_tree, mashtree_tree ->
                tuple(meta, partitions_tsv, dist_tree, mashtree_tree, template_microreact)}

        MICROREACT_CGMLST(
            ch_cgmlst_microreact
        )
        ch_versions = ch_versions.mix(MICROREACT_CGMLST.out.versions)

        // Using Parsnp results
        ch_parsnp_microreact = PARSNP_ANALYSIS.out.partitions.join(PARSNP_ANALYSIS.out.dist_tree)
            .map{meta, partitions_tsv, dist_tree -> [[species:meta.species], partitions_tsv, dist_tree]}
            .join(MASHTREE_CORGE.out.mashtree_tree)         
            .map { meta, partitions_tsv, dist_tree, mashtree_tree ->
                tuple(meta, partitions_tsv, dist_tree, mashtree_tree, template_microreact)}

        MICROREACT_SNP(
            ch_parsnp_microreact
        )
        ch_versions = ch_versions.mix(MICROREACT_SNP.out.versions)
    }

    if(params.tree) {
        template_microreact = file(params.microreact_template_ml)
        // Using cgMLST results
        ch_cgmlst_microreact_ml = CHEWBBACA_ANALYSIS.out.partitions
            .join(CHEWBBACA_ANALYSIS.out.dist_tree)
            .map { meta, partitions_tsv, dist_tree ->
                [[species: meta.species], partitions_tsv, dist_tree]}
            .join(CHEWBBACA_ANALYSIS.out.snp_tree)
            .join(MASHTREE_CORGE.out.mashtree_tree)
            .map { meta, partitions_tsv, dist_tree, snp_tree, mashtree_tree ->
                tuple(meta, partitions_tsv, dist_tree, snp_tree, mashtree_tree, template_microreact)}

        MICROREACT_ML_CGMLST(
            ch_cgmlst_microreact_ml
        )
        ch_versions = ch_versions.mix(MICROREACT_ML_CGMLST.out.versions)

        // Using Parsnp results
        ch_parsnp_microreact_ml = PARSNP_ANALYSIS.out.partitions
            .join(PARSNP_ANALYSIS.out.dist_tree)
            .join(PARSNP_ANALYSIS.out.snp_tree)
            .map{meta, partitions_tsv, dist_tree, snp_tree -> 
                [[species:meta.species], partitions_tsv, dist_tree, snp_tree]}
            .join(MASHTREE_CORGE.out.mashtree_tree)         
            .map { meta, partitions_tsv, dist_tree, snp_tree, mashtree_tree ->
                tuple(meta, partitions_tsv, dist_tree, snp_tree, mashtree_tree, template_microreact)}

        MICROREACT_ML_SNP(
            ch_parsnp_microreact_ml
        )
        ch_versions = ch_versions.mix(MICROREACT_ML_SNP.out.versions)
    }

    //
    // SUBWORKFLOW: Determine if there are linkages and select clusters
    //
    LINKAGE_ANALYSIS(
        CHEWBBACA_ANALYSIS.out.dist_hamming,
        PARSNP_ANALYSIS.out.dist_hamming,
        CHEWBBACA_ANALYSIS.out.cluster_composition,
        PARSNP_ANALYSIS.out.cluster_composition,
        CHEWBBACA_ANALYSIS.out.loci_report,
        PARSNP_ANALYSIS.out.loci_report
    )
    ch_versions = ch_versions.mix(LINKAGE_ANALYSIS.out.versions)
    //
    // POODLE MANIFESTS: Generate PoODLE manifests per sample depending on the presence of master paths or not
    //
    if (!params.master_paths){MAKE_POODLE_MANIFEST(LINKAGE_ANALYSIS.out.selected_cluster, outdir_abs)
        ch_versions = ch_versions.mix(MAKE_POODLE_MANIFEST.out.versions)}

    if (params.master_paths){MAKE_POODLE_MANIFEST_MASTER(LINKAGE_ANALYSIS.out.selected_cluster, outdir_abs, master_paths)
    ch_versions = ch_versions.mix(MAKE_POODLE_MANIFEST_MASTER.out.versions)}

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
