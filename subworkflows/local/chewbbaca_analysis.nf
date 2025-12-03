//
// Perform cgMLST allele calling, joining with prior results, masking missing and inferred alleles and running ReporTree analysis by species
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CHEWBBACA_ALLELECALL      } from '../../modules/local/chewbbaca/allelecall.nf'
include { CHEWBBACA_JOINPROFILES    } from '../../modules/local/chewbbaca/joinprofiles.nf'
include { CHEWBBACA_EXTRACTCGMLST   } from '../../modules/local/chewbbaca/extractcgmlst.nf'
include { DEDUPLICATE_ALLELES       } from '../../modules/local/chewbbaca/deduplicate_alleles.nf'
include { CHECK_METADATA            } from '../../modules/local/reportree/check_metadata.nf'
include { REPORTREE_CGMLST          } from '../../modules/local/reportree/reportree_cgmlst.nf'

/*
=============================================================================================================================
    SUBWORKFLOW FUNCTIONS
=============================================================================================================================
*/
//Function for creating the path to the schema for a species
def include_schema(species) {
    //create the path to what should be the schema for the species
    species_schema_path = file(file(params.schema_dir).resolve(species))
    return species_schema_path
}
//Function to check if the previous allele table exists
def check_previous_alleles_tsv(species) {
    // Create the path to where the previous alleles tsv are stored
    def previous_alleles_path = file("${params.outdir}/${species}/cgMLST/masked/${species}_masked_results_alleles.tsv", checkIfExists: false)
    return previous_alleles_path.exists()
}
//Function to return the previous allele table (assuming it exists)
def get_previous_alleles_tsv(species ) {
    // Create the path to where the previous alleles tsv are stored
    def previous_alleles_path = file("${params.outdir}/${species}/cgMLST/masked/${species}_masked_results_alleles.tsv", checkIfExists: false)
    return previous_alleles_path
}
//Function to return the previous HC partitions table or empty list
def get_previous_partitions_tsv(species) {
    def p = "${params.outdir}/${species}/ReporTree/${species}_partitions.tsv"
    return new File(p).exists() ? file(p) : []
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow CHEWBBACA_ANALYSIS {

    take:
    ch_samples         // channel: [ val(meta), assemblies ]
    ch_cgmlst_schema  // [[species, count], path_to_cgmlst_scheme]

    main:
    ch_versions = Channel.empty()
    //
    // Join all samples by species
    //
    ch_samples
        .map{meta, assembly ->
            [[species:meta.species],assembly]
        }
        .groupTuple(by: 0)
        .set{ch_samples_grouped}
    //
    // Now joing species with the appropriate schema
    //
    ch_samples_and_schema = ch_cgmlst_schema.map{
        meta, schema_path -> [[species:meta.species],schema_path]
    }.join(ch_samples_grouped)
    //
    // MODULE: Determine the allelic profiles of a set of genomes
    //
    CHEWBBACA_ALLELECALL (
        ch_samples_and_schema
    )
    ch_versions = ch_versions.mix(CHEWBBACA_ALLELECALL.out.versions)
    //
    // Check if a previous alleles tsv file exists
    //
    CHEWBBACA_ALLELECALL.out.results_alleles
        .map{
            meta, new_alleles ->
            [[species:meta.species,previous_alleles: check_previous_alleles_tsv(meta.species)],new_alleles]
        }
        .branch{
            previous_alleles : it[0].previous_alleles == true
            no_previous_alleles : it[0].previous_alleles == false
        }
        .set{ch_verify_previous_alleles} //[[species, previous_alleles], path_to_new_alleles.tsv]
    //
    // For species that previously had an alleles tsv file, add it to the channel
    //
    ch_verify_previous_alleles.previous_alleles
        .map{
            meta, new_alleles ->
            [meta, new_alleles, get_previous_alleles_tsv(meta.species)]
        }
        .set{ch_alleles_tables} // [[species,previous_alleles], new_alleles, previous_alleles]
    //
    // MODULE: Join new and previous allele tables
    //
    CHEWBBACA_JOINPROFILES(
        ch_alleles_tables
    )
    ch_versions = ch_versions.mix(CHEWBBACA_JOINPROFILES.out.versions)
    //
    //Create channel of all the allele tables, regardless of if JOIN PROFILES was run
    //
    ch_all_allele_results = Channel.empty()
    ch_all_allele_results = ch_all_allele_results.mix(CHEWBBACA_JOINPROFILES.out.joined_alleles)
    ch_all_allele_results = ch_all_allele_results.mix(ch_verify_previous_alleles.no_previous_alleles)
    //
    // MODULE: Deduplicate any samples from the alleles table
    //
    DEDUPLICATE_ALLELES(
        ch_all_allele_results
    )
    ch_versions = ch_versions.mix(DEDUPLICATE_ALLELES.out.versions)
    //
    // MODULE: Properly format the alleles matrix for possible new allels
    //
    CHEWBBACA_EXTRACTCGMLST(
        DEDUPLICATE_ALLELES.out.deduplicated_alleles_table
    )
    //
    // MODULE: Check that metadata has info for all the samples in the final masked_alleles results
    //
    if(params.metadata) {
        CHECK_METADATA(CHEWBBACA_EXTRACTCGMLST.out.masked_alleles, file(params.metadata))
        ch_metadata = CHECK_METADATA.out.metadata
        ch_versions = ch_versions.mix(CHECK_METADATA.out.versions)}
    else {
        CHEWBBACA_EXTRACTCGMLST.out.masked_alleles
        .map { meta, _ -> 
            def metadata = []
            tuple( meta, metadata)
        }
        .set { ch_metadata }
    }
    //
    //
    // Check if there are previous partitions to keep consistent nomenclature
    // 
    CHEWBBACA_EXTRACTCGMLST.out.masked_alleles
        .map { meta, _ -> 
            def prev = get_previous_partitions_tsv(meta.species)
            [ meta, prev ]
        }
        .set { ch_previous_partitions }
    //
    // MODULE: Run ReporTree for hierarchical clustering and analysis
    //
    REPORTREE_CGMLST(
            CHEWBBACA_EXTRACTCGMLST.out.masked_alleles,
            ch_metadata,
            ch_previous_partitions
        )
    ch_versions = ch_versions.mix(REPORTREE_CGMLST.out.versions)

    emit:
    dist_hamming        = REPORTREE_CGMLST.out.dist_hamming          //channel: [val (meta), dist_hamming ]
    partitions          = REPORTREE_CGMLST.out.partitions            //channel" [val (meta), partitions_summary]
    dist_tree           = REPORTREE_CGMLST.out.single_HC             //channel: [val(meta), single_hc]
    cluster_composition = REPORTREE_CGMLST.out.cluster_composition   //channel: [val(meta), cluster_composition]
    versions            = ch_versions                                //channel: [ versions.yml ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/