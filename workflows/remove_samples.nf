/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowCorgeplus.initialise(params, log)

def outdir_abs = file(params.outdir).toAbsolutePath()
if (params.mode == 'remove') { //following params only need to be validated for remove mode
    def checkPathParamList = [ params.samples_to_remove, params.outdir]
    for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

    if (params.samples_to_remove == null) {
        exit 1, 'Missing --samples_to_remove.  Provide a CSV file with columns: sample,species'}
}

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
include { DELETE_ASSEMBLIES                      } from '../modules/local/remove_samples/delete_assemblies.nf'
include { ROOT_TREE as ROOT_TREE_MASHTREE        } from '../modules/local/tree/root_tree.nf'
include { MICROREACT as MICROREACT_CGMLST        } from '../modules/local/microreact/microreact.nf'
include { MICROREACT as MICROREACT_SNP           } from '../modules/local/microreact/microreact.nf'
include { MICROREACT_ML as MICROREACT_ML_CGMLST  } from '../modules/local/microreact/microreact_ml.nf'
include { MICROREACT_ML as MICROREACT_ML_SNP     } from '../modules/local/microreact/microreact_ml.nf'
include { MAKE_POODLE_MANIFEST                   } from '../modules/local/post_processing/make_poodle_manifest.nf'
include { MAKE_POODLE_MANIFEST_MASTER            } from '../modules/local/post_processing/make_poodle_manifest_master.nf'
include { MASHTREE                               } from '../modules/local/mashtree/main.nf'

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK_REMOVE_SAMPLES  } from '../subworkflows/local/input_check_remove.nf'
include { INPUT_CHECK_CGMLST          } from '../subworkflows/local/input_check_cgmlst.nf'
include { VERIFY_PREVIOUS_RESULTS     } from '../subworkflows/local/verify_previous_results.nf'
include { REMOVE_CGMLST               } from '../subworkflows/local/remove_cgmlst.nf'
include { REMOVE_PARSNP               } from '../subworkflows/local/remove_parsnp.nf'
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


workflow REMOVE_SAMPLES {

    ch_versions = Channel.empty()
    //
    // MODULE: Check input and split by species
    //
    INPUT_CHECK_REMOVE_SAMPLES(
        file(params.samples_to_remove))
    ch_versions = ch_versions.mix(INPUT_CHECK_REMOVE_SAMPLES.out.versions)

    //
    // SUBWORKFLOW: Read in csv containing cgmlst paths per species and validate they exist
    //

    if (params.cgmlst_schemas) {
        INPUT_CHECK_CGMLST(
            file(params.cgmlst_schemas),
            INPUT_CHECK_REMOVE_SAMPLES.out.species_count
        )

        ch_species_counts_cgmlst = INPUT_CHECK_CGMLST.out.species_counts_cgmlst
        ch_species_count_nocgmlst = INPUT_CHECK_CGMLST.out.species_count_nocgmlst
        ch_versions              = ch_versions.mix(INPUT_CHECK_CGMLST.out.versions)

    } else {
        ch_species_counts_cgmlst = Channel.empty()

        ch_species_count_nocgmlst = INPUT_CHECK_REMOVE_SAMPLES.out.species_count
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
    // MODULE: Remove samples and generated updated cgmlst outputs, metadata and assemblies
    //
    DELETE_ASSEMBLIES(INPUT_CHECK_REMOVE_SAMPLES.out.samples_to_remove,
                        outdir_abs)

    //
    //
    // MODULE: Run MashTree without the removed samples
    ch_updated_assemblies_with_meta =
    DELETE_ASSEMBLIES.out.updated_assemblies
        .map { species, assemblies ->
            def meta = [ species: species ]
            tuple(meta, assemblies)
        }
    MASHTREE(ch_updated_assemblies_with_meta)
    ch_versions = ch_versions.mix(MASHTREE.out.versions)

    //
    // MODULE: Root the MashTree tree
    //
    ROOT_TREE_MASHTREE(
        MASHTREE.out.tree
    )
    ch_versions = ch_versions.mix(ROOT_TREE_MASHTREE.out.versions)

    //
    // SUBWORKFLOW: Remove samples from cgMLST results and re-run ReporTree
    //
    REMOVE_CGMLST(
        INPUT_CHECK_REMOVE_SAMPLES.out.samples_to_remove,
        VERIFY_PREVIOUS_RESULTS.out.species_to_chewbbaca,
        outdir_abs)
    ch_versions = ch_versions.mix(REMOVE_CGMLST.out.versions)
    
    //
    // SUBWORKFLOW: Run Parsnp without the removed samples and re-run ReporTree
    //
    REMOVE_PARSNP(
        INPUT_CHECK_REMOVE_SAMPLES.out.samples_to_remove,
        DELETE_ASSEMBLIES.out.updated_assemblies,
        VERIFY_PREVIOUS_RESULTS.out.species_to_parsnp,
        outdir_abs)
    ch_versions = ch_versions.mix(REMOVE_PARSNP.out.versions)

    //
    // MODULE: Make a Microreact file with trees and selected groups
    //
    if(!params.tree) {
        template_microreact = file(params.microreact_template)
        // Using cgMLST results
        ch_cgmlst_microreact = REMOVE_CGMLST.out.partitions
            .join(REMOVE_CGMLST.out.dist_tree)
            .map { meta, partitions_tsv, dist_tree ->
                [[species: meta.species], partitions_tsv, dist_tree]
            }
            .join(ROOT_TREE_MASHTREE.out.tre)
            .map { meta, partitions_tsv, dist_tree, mashtree_tree ->
                tuple(meta, partitions_tsv, dist_tree, mashtree_tree, template_microreact)}

        MICROREACT_CGMLST(
            ch_cgmlst_microreact
        )
        ch_versions = ch_versions.mix(MICROREACT_CGMLST.out.versions)

        // Using Parsnp results
        ch_parsnp_microreact = REMOVE_PARSNP.out.partitions.join(REMOVE_PARSNP.out.dist_tree)
            .map{meta, partitions_tsv, dist_tree -> [[species:meta.species], partitions_tsv, dist_tree]}
            .join(ROOT_TREE_MASHTREE.out.tre)         
            .map { meta, partitions_tsv, dist_tree, mashtree_tree ->
                tuple(meta, partitions_tsv, dist_tree, mashtree_tree, template_microreact)}

        MICROREACT_SNP(
            ch_parsnp_microreact
        )
        ch_versions = ch_versions.mix(MICROREACT_SNP.out.versions)
    }

    if(params.tree) {
        template_microreact_ml = file(params.microreact_template_ml)
        // Using cgMLST results
        ch_cgmlst_microreact_ml = REMOVE_CGMLST.out.partitions
            .join(REMOVE_CGMLST.out.dist_tree)
            .map { meta, partitions_tsv, dist_tree ->
                [[species: meta.species], partitions_tsv, dist_tree]}
            .join(REMOVE_CGMLST.out.snp_tree)
            .join(ROOT_TREE_MASHTREE.out.tre)
            .map { meta, partitions_tsv, dist_tree, snp_tree, mashtree_tree ->
                tuple(meta, partitions_tsv, dist_tree, snp_tree, mashtree_tree, template_microreact_ml)}

        MICROREACT_ML_CGMLST(
            ch_cgmlst_microreact_ml
        )
        ch_versions = ch_versions.mix(MICROREACT_ML_CGMLST.out.versions)

        // Using Parsnp results
        ch_parsnp_microreact_ml = REMOVE_PARSNP.out.partitions
            .join(REMOVE_PARSNP.out.dist_tree)
            .join(REMOVE_PARSNP.out.snp_tree)
            .map{meta, partitions_tsv, dist_tree, snp_tree -> 
                [[species:meta.species], partitions_tsv, dist_tree, snp_tree]}
            .join(ROOT_TREE_MASHTREE.out.tre)         
            .map { meta, partitions_tsv, dist_tree, snp_tree, mashtree_tree ->
                tuple(meta, partitions_tsv, dist_tree, snp_tree, mashtree_tree, template_microreact_ml)}

        MICROREACT_ML_SNP(
            ch_parsnp_microreact_ml
        )
        ch_versions = ch_versions.mix(MICROREACT_ML_SNP.out.versions)
    }

    //
    // SUBWORKFLOW: Determine if there are linkages and select clusters
    //
    LINKAGE_ANALYSIS(
        REMOVE_CGMLST.out.dist_hamming,
        REMOVE_PARSNP.out.snp_dists,
        REMOVE_CGMLST.out.cluster_composition,
        REMOVE_PARSNP.out.cluster_composition,
        REMOVE_CGMLST.out.loci_report,
        REMOVE_PARSNP.out.alignment_stats
    )
    ch_versions = ch_versions.mix(LINKAGE_ANALYSIS.out.versions)
    
    //
    // POODLE MANIFESTS: Generate PoODLE manifests per sample depending on the presence of master paths or not
    //
    ch_linkages = LINKAGE_ANALYSIS.out.selected_cluster
    .join(LINKAGE_ANALYSIS.out.potential_linkages)

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
