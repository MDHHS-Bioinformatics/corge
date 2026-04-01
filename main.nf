#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MDHHS-Bioinformatics/corge
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/MDHHS-Bioinformatics/corge

----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

include { CORGEPLUS             } from './workflows/corgeplus'
include { PREPARE_CGMLST_SCHEMA } from './workflows/prepare_cgmlst_schema'
include { REGROUP               } from './workflows/regroup'
include { REMOVE_SAMPLES        } from './workflows/remove_samples'
include { TREE                  } from './workflows/tree'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE & PRINT PARAMETER SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

WorkflowMain.initialise(workflow, params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOW FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main MDHHS-Bioinformatics/corge analysis pipeline
//
workflow {
    if (params.mode == 'default') {
        CORGEPLUS()
    } else if (params.mode == 'schema') {
        PREPARE_CGMLST_SCHEMA()
    } else if (params.mode == 'regroup') {
        REGROUP()
    } else if (params.mode == 'remove') {
        REMOVE_SAMPLES()
    } else if (params.mode == 'tree') {
        TREE()
    } else {
        exit 1, "ERROR: Unknown --mode '${params.mode}'. Must be one of: 'default', 'schema', 'regroup', 'remove' or 'tree'."
    }
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
