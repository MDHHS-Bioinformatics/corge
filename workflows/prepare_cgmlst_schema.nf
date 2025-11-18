/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowCorgeplus.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check schema path parameters to see if they exist
def checkPathParamList = [ params.schema_info, params.trn_files,  params.species_schemas]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

if (params.schema_ids == null) {
     exit 1, 'Missing --schema_ids.  Give e.g. "s12" or "s12,s24,s36".'}

def raw = params.schema_ids?.toString() ?: ''
def schemaList = raw.split(/,\s*/).collect { it.trim() }.unique()

// Define allowed schema pattern: s1 to s40
def validRe = ~/^s([1-9]|[1-3]\d|40)$/
def invalid = schemaList.findAll { !(it ==~ validRe) }

// Perform validation
if( !schemaList || invalid ) {
    exit 1, "Invalid --schema_ids value(s): ${ invalid.join(', ') }  " +
            "Allowed range is s1–s40, comma‑separated."
}

println "Schemas requested: ${schemaList.join(', ')}"   // => s24,s25

// Check mandatory parameters
if (params.outdir) { ch_db = file("${params.outdir}/cgmlst_schemas") } else { exit 1, 'CorGe outdir not specified!' }

// Create db path if it does not exist
ch_db.exists() ?: ch_db.mkdirs()


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
include { FETCH_CGMLST_SCHEMAS } from '../modules/local/fetch_cgmlst_schemas'
include { DOWNLOAD_CGMLST_SCHEMA } from '../modules/local/download_cgmlst_schema'
include { UNZIP_CGMLST_SCHEMA } from '../modules/local/unzip_cgmlst_schema'
include { CONFIGURE_CGMLST_SCHEMA } from '../modules/local/configure_cgmlst_schema'
include { UPDATE_CGMLST_FILE } from '../modules/local/update_cgmlst_file'

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


workflow PREPARE_CGMLST_SCHEMA {

    ch_versions = Channel.empty()

    FETCH_CGMLST_SCHEMAS(params.schema_info)

    // Broadcast the list to use in filtering
    Channel
        .from(schemaList.toSet())
        .set { schema_filter_set }
    // schema_filter_set.view()
    
    FETCH_CGMLST_SCHEMAS.out.schemas_info_updated
        .splitCsv(header: true, sep: ',')
        .map { row -> tuple(row.id, row) }
        .join(schema_filter_set)
        .set { selected_schema_data }

    selected_schema_data
        .map { id, row -> 
            tuple(id, row.schema_name, row.url_alleles, "${params.trn_files}/${row.trn}")
        }
        .set { schema_channel }


    // MODULE: Download the cgMLST schemas
    DOWNLOAD_CGMLST_SCHEMA(
        schema_channel
    )
    
    UNZIP_CGMLST_SCHEMA(
        DOWNLOAD_CGMLST_SCHEMA.out.alleles_zip
    )

    // MODULE: Configure the cgMLST schemas in chewbbaca format
    CONFIGURE_CGMLST_SCHEMA(
        UNZIP_CGMLST_SCHEMA.out.alleles
    )
    
    // Wait for all schema dirs to finish
    CONFIGURE_CGMLST_SCHEMA.out.schema
        .collect()
        .map { dirs -> true }  // just a signal
        .set { ready_ch }

    // Combine static path and species file with completion signal
    Channel
        .of(tuple(file(params.outdir), file(params.species_schemas)))
        .combine(ready_ch)
        .set { update_ch }

    // Update cgMLST info file once all schemas were downloaded and configured as ChewBBACA format
    UPDATE_CGMLST_FILE(
        update_ch
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