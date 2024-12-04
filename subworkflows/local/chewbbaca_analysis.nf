
include { CHEWBBACA_ALLELECALL      } from '../../modules/local/chewbbaca/allelecall.nf'
include { CHEWBBACA_JOINPROFILES    } from '../../modules/local/chewbbaca/joinprofiles.nf'
include { SUBSET_LIMS               } from '../../modules/local/subset_lims.nf'
include { DEDUPLICATE_ALLELES       } from '../../modules/local/deduplicate_alleles.nf'
include { REPORTREE_CGMLST          } from '../../modules/local/reportree/cgmlst.nf'

//Function for creating the path to the schema for a species
def include_schema(species) {
    //create the path to what should be the schema for the species
    species_schema_path = file(file(params.schema_dir).resolve(species))
    return species_schema_path
}
//Function to check if the previous allele table exists
def check_previous_alleles_tsv(species) {
    // Create the path to where the previous alleles tsv are stored
    def previous_alleles_path = file("${params.previous_results}/${species}/${params.previous_results_extra}/results_alleles.tsv", checkIfExists: false)
    return previous_alleles_path.exists()
}
//Function to return the previous allele table (assuming it exists)
def get_previous_alleles_tsv(species ) {
    // Create the path to where the previous alleles tsv are stored
    def previous_alleles_path = file("${params.previous_results}/${species}/${params.previous_results_extra}/results_alleles.tsv", checkIfExists: false)
    return previous_alleles_path
}
workflow CHEWBBACA_ANALYSIS {

    take:
    // TODO nf-core: edit input (take) channels
    ch_samples // channel: [ val(meta), gff, assemblies ]

    main:
    ch_versions = Channel.empty()

    //Join all samples by species
    ch_samples
        .map { meta, gff, assemblies ->
            [ [species:meta.species, species_count:meta.species_count], gff, assemblies ]
        }
        .groupTuple()
        .map {
            meta, gff, assemblies ->
            [meta, gff, assemblies, include_schema(meta.species)]
        }
        .set { samples_per_species }

    //
    //MODULE: Determine the allelic profiles of a set of genomes
    //
    CHEWBBACA_ALLELECALL (
        samples_per_species
    )

    //Check if a previous alleles tsv file exists
    CHEWBBACA_ALLELECALL.out.results_alleles
        .map {
            meta, new_alleles ->
            [[species:meta.species, species_count: meta.species_count, previous_alleles: check_previous_alleles_tsv(meta.species)], new_alleles]
        }
        .branch {
            yes : it[0].previous_alleles == true
            no: it[0].previous_alleles == false
        }
        .set{ch_previous_alleles}
    //For species that preivously had an alleles tsv file, add it to the channel
    ch_previous_alleles.yes
        .map {
            meta, new_alleles ->
            [meta, new_alleles, get_previous_alleles_tsv(meta.species) ]
        }
        .set{ch_allele_tables}

    //
    //MODULE: Join new and previous allele table
    //
    CHEWBBACA_JOINPROFILES(
        ch_allele_tables
    )
    //Create channel of all the allele tables, regardless of if JOIN PROFILES was run
    ch_all_allele_results = Channel.empty()
    ch_all_allele_results = ch_all_allele_results.mix(CHEWBBACA_JOINPROFILES.out.final_alleles)
    ch_all_allele_results = ch_all_allele_results.mix(ch_previous_alleles.no)
    // Check how many counts there are per species, greater than one means we run reportree
    ch_all_allele_results
        .branch { meta, allele_table ->
            yes: meta.species_count > 1
            no: meta.species_count == 1
        }
        .set{ch_run_reportree}

    //
    ///MODULE: Run subsetting for the lims datasheet by each species
    //
    SUBSET_LIMS(
        ch_run_reportree.yes,
        file(params.lims)
    )


    //
    //MODULE: Deduplicate any samples from the alleles table
    //
    DEDUPLICATE_ALLELES(
        SUBSET_LIMS.out.subset_species_lims
    )

    //
    //MODULE: Run reportree on multiple samples for a species with a cgMLST
    //
    REPORTREE_CGMLST (
        DEDUPLICATE_ALLELES.out.data_for_reportree //ch_run_reportree.yes,
        //file(params.lims)//file(params.master_manifest)
    )

    REPORTREE_CGMLST.out.results.view()

    emit:
    // TODO nf-core: edit emitted channels
    // bam      = SAMTOOLS_SORT.out.bam           // channel: [ val(meta), [ bam ] ]
    // bai      = SAMTOOLS_INDEX.out.bai          // channel: [ val(meta), [ bai ] ]
    // csi      = SAMTOOLS_INDEX.out.csi          // channel: [ val(meta), [ csi ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}

