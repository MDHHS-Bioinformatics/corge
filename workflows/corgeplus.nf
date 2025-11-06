/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowCorgeplus.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

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
include { MICROREACT AS MICROREACT_CGMLST           } from '../modules/local/microreact.nf'
include { MICROREACT AS MICROREACT_SNP           } from '../modules/local/microreact.nf'

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK                 } from '../subworkflows/local/input_check'
include { INPUT_CHECK_READS           } from '../subworkflows/local/input_check_reads.nf'
include { INPUT_CHECK_MASTER_MANIFEST } from '../subworkflows/local/input_check_master_manifest.nf'
include { VERIFY_CGMLST_SCHEMES       } from '../subworkflows/local/verify_cgmlst_schemes.nf'
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
    //INPUT_CHECK.out.assemblies.view()

    //
    // SUBWORKFLOW: Read in reads samplesheet if specifeid, validate that they exist but no need to stage files
    //
    INPUT_CHECK_READS(file(params.reads_manifest))

    //
    // SUBWORKFLOW: Read in master manifest file. Validate GFFs and Assemblies. Count how many samples per species
    //
    INPUT_CHECK_MASTER_MANIFEST(file(params.master_manifest))
        //INPUT_CHECK_MASTER_MANIFEST.out.master_info.view()
        //INPUT_CHECK_MASTER_MANIFEST.out.species_count.view()

    //
    //SUBWORKFLOW: Check if cgMLST schemes exist for each species

    VERIFY_CGMLST_SCHEMES(
        INPUT_CHECK.out.prepped_assemblies,
        INPUT_CHECK.out.species_count,
        INPUT_CHECK_MASTER_MANIFEST.out.species_count
        //file(params.schema_dir)
    )

    //
    //SUBWORKFLOW: Run ChewBBACA on samples with a schema
    //
    CHEWBBACA_ANALYSIS (
        VERIFY_CGMLST_SCHEMES.out.samples_to_chewbbaca
    )

    //
    // SUBWORKFLOW: Run Parsnp on samples without a schema
    //
    PARSNP_ANALYSIS (
        VERIFY_CGMLST_SCHEMES.out.samples_to_parsnp,
        INPUT_CHECK_MASTER_MANIFEST.out.master_info
    )

    //
    // SUBWORKFLOW: Run MashTree and create microreact files
    //
    MASHTREE_CORGE(
        VERIFY_CGMLST_SCHEMES.out.samples_to_chewbbaca,
        VERIFY_CGMLST_SCHEMES.out.samples_to_parsnp,
        INPUT_CHECK_MASTER_MANIFEST.out.master_info
    )

    //
    // MICROREACT: Summary plot with distance trees and selected partitions
    //
    ch_cgmlst_microreact = CHEWBBACA_ANALYSIS.out.partitions_summary
    .join(CHEWBBACA_ANALYSIS.out.dist_tree, by:0)
    .join(MASHTREE_CORGE.out.mashtree, by:0)
    .map{meta, partitions_tsv, dist_tree, mashtree -> tuple(meta, partitions_tsv, dist_tree, mashtree)}
   
    MICROREACT_CGMLST(ch_cgmlst_microreact)

    ch_parsnp_microreact = PARSNP_ANALYSIS.out.partitions_summary
    .join(PARSNP_ANALYSIS.out.dist_tree, by:0)
    .join(MASHTREE_CORGE.out.mashtree, by:0)
    .map{meta, partitions_tsv, dist_tree, mashtree -> tuple(meta, partitions_tsv, dist_tree, mashtree)}
   
    MICROREACT_SNP(ch_parsnp_microreact)

    // CHEWBBACA_ANALYSIS.out.partitions_summary.view()
    // PARSNP_ANALYSIS.out.partitions_summary.view()
    //
    // SUBWORKFLOW: Determine if there are linkages and select clusters
    //
    LINKAGE_ANALYSIS(
        CHEWBBACA_ANALYSIS.out.dist_hamming,
        PARSNP_ANALYSIS.out.dist_hamming,
        CHEWBBACA_ANALYSIS.out.partitions_summary,
        PARSNP_ANALYSIS.out.partitions_summary
    )

    // CUSTOM_DUMPSOFTWAREVERSIONS (
    //     ch_versions.unique().collectFile(name: 'collated_versions.yml')
    // )

    // //
    // // MODULE: MultiQC
    // //
    // workflow_summary    = WorkflowCorgeplus.paramsSummaryMultiqc(workflow, summary_params)
    // ch_workflow_summary = Channel.value(workflow_summary)

    // methods_description    = WorkflowCorgeplus.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    // ch_methods_description = Channel.value(methods_description)

    // ch_multiqc_files = Channel.empty()
    // ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    // ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    // ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    // ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))

    // MULTIQC (
    //     ch_multiqc_files.collect(),
    //     ch_multiqc_config.toList(),
    //     ch_multiqc_custom_config.toList(),
    //     ch_multiqc_logo.toList()
    // )
    // multiqc_report = MULTIQC.out.report.toList()
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
