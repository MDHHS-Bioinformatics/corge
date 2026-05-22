/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowCorgeplus.initialise(params, log)

// Check regroup path parameters to see if they exist
// Define speciesList/outdir_abs at script level (before the if block)
def speciesList = []
if (params.mode == 'regroup') { //following params only need to be validated for regroup mode
    def checkPathParamList = [params.outdir]
    for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

    if (params.species == null) {
        exit 1, 'Missing --species .  Provide a species or list of species separated by commas, no spaces allowed'}
    
    def raw = params.species?.toString() ?: ''
    speciesList = raw.split(/,/).collect { it.trim() }.unique()

    println "Species requested to regroup: ${speciesList.join(', ')}" 
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
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// MODULES
include { MICROREACT                     } from '../modules/local/microreact/microreact.nf'
include { MICROREACT_ML                  } from '../modules/local/microreact/microreact_ml.nf'
include { MAKE_POODLE_MANIFEST           } from '../modules/local/post_processing/make_poodle_manifest.nf'
include { MAKE_POODLE_MANIFEST_MASTER    } from '../modules/local/post_processing/make_poodle_manifest_master.nf'
include { CLUSTER_SELECTION              } from '../modules/local/post_processing/cluster_selection.nf'

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

workflow REGROUP {

    ch_versions = Channel.empty()

    ch_species_meta = Channel
        .fromList(speciesList)
        .map { sp -> [ species: sp ] }

    // helper closure to build an existing-file channel given a template
    def existingFileChannel = { String template ->
    ch_species_meta.map { meta ->
        def sp = meta.species
        def f  = outdir_abs.resolve( template.replace('<species>', sp) )
        tuple(meta, file(f, checkIfExists: true))
    }
    }

    // ReporTree
    ch_cluster_composition  = existingFileChannel("<species>/ReporTree/<species>_clusterComposition.tsv")
    ch_partitions_tsv       = existingFileChannel("<species>/ReporTree/<species>_partitions.tsv")
    ch_dist_tree            = existingFileChannel("<species>/ReporTree/<species>_single_HC.nwk")

    // Linkages
    ch_potential_linkages    = existingFileChannel("<species>/linkages/<species>_potential_linkages.csv")

    // mashtree
    ch_mashtree_tree        = existingFileChannel("<species>/mashtree/<species>_rooted_mash.tre")

    // tree
    ch_tree_status = ch_species_meta.map { meta ->
    def sp   = meta.species
    def p    = outdir_abs.resolve("${sp}/tree/${sp}.nwk")
    def tree = file(p)
    tuple(meta, tree.exists(), tree)
    }

    ch_tree_status
    .branch { meta, exists, tree ->
        has_tree: exists
        no_tree : !exists
    }
    .set { branched }

    ch_has_tree = branched.has_tree.map { meta, exists, tree -> tuple(meta, tree) }
    ch_no_tree  = branched.no_tree .map { meta, exists, tree -> meta }

    ch_empty = ch_species_meta.map { meta -> tuple(meta, []) }

    //
    // MODULE: Make a Microreact file with trees and selected groups
    //
    template_microreact = file(params.microreact_template)
    ch_microreact = ch_no_tree
        .join(ch_partitions_tsv)
        .join(ch_dist_tree)
        .join(ch_mashtree_tree)
        .map { meta, partitions_tsv, dist_tree, mashtree_tree ->
            tuple(meta, partitions_tsv, dist_tree, mashtree_tree, template_microreact)}

    MICROREACT(
        ch_microreact
    )
    ch_versions = ch_versions.mix(MICROREACT.out.versions)

    ch_microreact_ml = ch_partitions_tsv
        .join(ch_dist_tree)
        .join(ch_has_tree)
        .join(ch_mashtree_tree)
        .map { meta, partitions_tsv, dist_tree, snp_tree, mashtree_tree ->
            tuple(meta, partitions_tsv, dist_tree, snp_tree, mashtree_tree, template_microreact)}

    MICROREACT_ML(
        ch_microreact_ml
    )
    ch_versions = ch_versions.mix(MICROREACT_ML.out.versions)

    //
    // MODULE: Get genomic context groups for each species
    //
    CLUSTER_SELECTION(
        ch_cluster_composition
    )
    ch_versions = ch_versions.mix(CLUSTER_SELECTION.out.versions)

    //
    // POODLE MANIFESTS: Generate PoODLE manifests per sample depending on the presence of master paths or not
    //
    ch_linkages = CLUSTER_SELECTION.out.genomic_context_groups
    .join(ch_potential_linkages)

    if (!params.master_paths){
        MAKE_POODLE_MANIFEST(ch_linkages, outdir_abs)
        ch_versions = ch_versions.mix(MAKE_POODLE_MANIFEST.out.versions)
    } else {
        MAKE_POODLE_MANIFEST_MASTER(ch_linkages, outdir_abs, master_paths)
        ch_versions = ch_versions.mix(MAKE_POODLE_MANIFEST_MASTER.out.versions)
    }

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
