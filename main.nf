#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MDHHS-Bioinformatics/corge
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/MDHHS-Bioinformatics/corge

----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

include { CORGEPLUS              } from './workflows/corgeplus'
include { DOWNLOAD_SCHEMA        } from './workflows/download_schema'
include { CREATE_SCHEMA          } from './workflows/create_schema'
include { REGROUP                } from './workflows/regroup'
include { REMOVE_SAMPLES         } from './workflows/remove_samples'
include { TREE                   } from './workflows/tree'

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
    } else if (params.mode == 'download_schema') {
        DOWNLOAD_SCHEMA()
    } else if (params.mode == 'create_schema') {
        CREATE_SCHEMA()
    } else if (params.mode == 'regroup') {
        REGROUP()
    } else if (params.mode == 'remove') {
        REMOVE_SAMPLES()
    } else if (params.mode == 'tree') {
        TREE()
    } else {
        exit 1, "ERROR: Unknown --mode '${params.mode}'. Must be one of: 'default', 'download_schema', 'create_schema', 'regroup', 'remove' or 'tree'."
    }
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
