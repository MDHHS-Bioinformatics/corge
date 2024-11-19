
include { CHEWBBACA_ALLELECALL      } from '../../modules/local/chewbbaca/allelecall.nf'
include { CHEWBBACA_JOINPROFILES    } from '../../modules/local/chewbbaca/joinprofiles.nf'

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
    emit:
    // TODO nf-core: edit emitted channels
    // bam      = SAMTOOLS_SORT.out.bam           // channel: [ val(meta), [ bam ] ]
    // bai      = SAMTOOLS_INDEX.out.bai          // channel: [ val(meta), [ bai ] ]
    // csi      = SAMTOOLS_INDEX.out.csi          // channel: [ val(meta), [ csi ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}

