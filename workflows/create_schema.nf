/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowCorgeplus.initialise(params, log)

if (params.mode == 'create_schema') {

    if (!params.assembly_sheet) {
        exit 1, "Input assemblies not specified! (--assembly_sheet is required for mode: ${params.mode})"
    }

    file(params.assembly_sheet, checkIfExists: true)

    if (!params.reference_path) {
        exit 1, "Reference genome not specified! (--reference_path is required for mode: ${params.mode})"
    }

    file(params.reference_path, checkIfExists: true)

    if (!params.species) {
        exit 1, "Species not specified! (--species is required for mode: ${params.mode})"
    }

    if (params.cgmlst_threshold == null) {
        exit 1, "cgMLST threshold not specified! (--cgmlst_threshold is required for mode: ${params.mode})"
    }

    def threshold = params.cgmlst_threshold.toString().trim()

    if (!threshold) {
        exit 1, "--cgmlst_threshold must be a single numeric value > 0 and <= 1"
    }

    if (threshold.contains(',')) {
        exit 1, "--cgmlst_threshold accepts only one value, but got: '${params.cgmlst_threshold}'"
    }

    if (!(threshold ==~ /^(0(\.\d+)?|1(\.0+)?)$/)) {
        exit 1, "Invalid --cgmlst_threshold value: '${threshold}'. Must be numeric > 0 and <= 1."
    }

    def threshold_value = threshold as BigDecimal

    if (threshold_value <= 0 || threshold_value > 1) {
        exit 1, "Invalid --cgmlst_threshold value: '${threshold}'. Must be > 0 and <= 1."
    }
}

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

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { PRODIGAL_CREATE_TRN         } from '../modules/local/create_schema/create_trn'
include { CHEWBBACA_CREATE_SCHEMA     } from '../modules/local/create_schema/create_schema'
include { CHEWBBACA_ALLELECALL        } from '../modules/local/chewbbaca/allelecall'
include { CHEWBBACA_EXTRACT_CGMLST    } from '../modules/local/create_schema/extract_cgmlst'
include { CHEWBBACA_PREPARE_CGMLST    } from '../modules/local/create_schema/prepare_cgmlst'
include { UPDATE_SCHEMAS_FILE         } from '../modules/local/create_schema/update_schemas_file'

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


workflow CREATE_SCHEMA {

    ch_versions = Channel.empty()
    //
    // MODULE: Generate a training file from reference genome
    //
    ch_reference = Channel.of(
        tuple(
            [ species: params.species ],
            file(params.reference_path)
        )
    )
    PRODIGAL_CREATE_TRN(ch_reference)
    ch_versions = ch_versions.mix(PRODIGAL_CREATE_TRN.out.versions)
    //
    // MODULE: Create wgMLST schema
    //
    ch_assemblies = Channel
        .fromPath(params.assembly_sheet)
        .splitText()
        .map { line -> line.trim() }
        .filter { line -> line && !line.startsWith('#') }
        .map { assembly_path -> file(assembly_path) }
        .collect()
        .map { assemblies -> [ assemblies: assemblies ] }
        
    ch_create = PRODIGAL_CREATE_TRN.out.trn
        .combine(ch_assemblies)
        .map { meta, trn, assembly_box ->
            tuple(meta, assembly_box.assemblies, trn)
        }

    CHEWBBACA_CREATE_SCHEMA(ch_create)
    ch_versions = ch_versions.mix(CHEWBBACA_CREATE_SCHEMA.out.versions)
    //
    // MODULE: Allele call
    //
    CHEWBBACA_ALLELECALL(CHEWBBACA_CREATE_SCHEMA.out.wgmlst)
    ch_versions = ch_versions.mix(CHEWBBACA_ALLELECALL.out.versions)
    //
    // MODULE: Extract cgMLST loci list
    //
    CHEWBBACA_EXTRACT_CGMLST(
        CHEWBBACA_ALLELECALL.out.results_alleles
    )
    ch_versions = ch_versions.mix(CHEWBBACA_EXTRACT_CGMLST.out.versions)
    //
    // MODULE: Prepare cgMLST
    //
    ch_cgmlst = CHEWBBACA_ALLELECALL.out.results_alleles
        .join(CHEWBBACA_EXTRACT_CGMLST.out.cgmlst_txt)
        .map { meta, results_alleles, schema, cgmlst_txt ->
            tuple(meta, cgmlst_txt, schema)
        }

    CHEWBBACA_PREPARE_CGMLST(
        ch_cgmlst
    )
    ch_versions = ch_versions.mix(CHEWBBACA_PREPARE_CGMLST.out.versions)
    //
    // MODULE: Update cgMLST schemas file
    //
    UPDATE_SCHEMAS_FILE(
        CHEWBBACA_PREPARE_CGMLST.out.cgmlst_schema,
        outdir_abs
    )   

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
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log)
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
