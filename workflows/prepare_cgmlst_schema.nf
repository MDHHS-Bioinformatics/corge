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


// Define allowed schema pattern: s1 to s36
def validSchemaPattern = ~/^s([1-9]|[1-2][0-9]|3[0-6])$/

// Perform validation
if (params.schema_ids == null || !(params.schema_ids ==~ validSchemaPattern)) {
    exit 1, 'Invalid value for --schema_ids: '${params.schema_ids}'. Must be a string between s1 and s36.'}

// Split comma-separated input
def schemaList = params.schema_ids.tokenize(',')

// Validate each schema entry
def invalidSchemas = schemaList.findAll { !(it ==~ validSchemaPattern) }

if (!invalidSchemas.isEmpty()) {exit 1, 'Invalid schema values: '${invalidSchemas.join(', ')}'. Must be strings between s1 and s36.'}

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
include { DOWNLOAD_CGMLST_SCHEMA } from '../modules/local/download_cgmlst_schema'
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

    // Load and parse the CSV as a list of maps
    Channel
        .fromPath(params.schema_info)
        .splitCsv(header: true, sep: '\t') // or sep: ',' if CSV is comma-separated
        .map { row -> 
            // Create a tuple: (id, row_map)
            tuple(row.id, row)
        }
        .set { schema_data_channel }

    // Broadcast the list to use in filtering
    Channel
        .from(schemaList.toSet())
        .set { schema_filter_set }

    Channel
        .fromPath(params.schema_info)
        .splitCsv(header: true, sep: ',')
        .map { row -> tuple(row.id, row) }
        .combine(schema_filter_set)
        .filter { id, row, id_set -> id_set.contains(id) }
        .map { id, row, id_set -> tuple(id, row) }  // Remove id_set for downstream
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
    
    // MODULE: Configure the cgMLST schemas in chewbbaca format
    CONFIGURE_CGMLST_SCHEMA(
        DOWNLOAD_CGMLST_SCHEMA.out
    )
    
    Channel
        .of(tuple( file("$params.outdir/cgmlst_schemas"), file(params.species_schemas) ) )
        .set { cgmlst_sp_ch }

    CONFIGURE_CGMLST_SCHEMA.out.done
        | collect
        | map { _ -> true}
        | set {ready_ch}

    cgmlst_sp_ch
        .combine(ready_ch)
        //.view()
        .set { update_ch }

    // Update cgMLST info file once all schemas were downloaded and configured as ChewBBACA format
    UPDATE_CGMLST_FILE(
        update_ch
    )
        //.map{paths, ready -> tuple([[outdir, species_schemas], gff])}

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