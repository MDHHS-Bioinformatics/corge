
process REPORTREE_CGMLST {
    tag "$meta.species"
    label 'process_medium'


    //conda "YOUR-TOOL-HERE"
    container "reportree_local_v2.5.3.sif"

    input:
    tuple val(meta), path(allele_table), path(lims_manifest) // path(master_manifest)

    output:
    tuple val(meta), path("ReporTree*"), emit: results
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    // tuple val(meta), path("*.bam"), emit: bam
    // TODO nf-core: List additional required output channels/values here
    //path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    species = task.ext.prefix ?: "${meta.species}"

    """
    #mv $allele_table results_alleles.tsv
    echo $species
    reportree.py \
        --metadata $lims_manifest \
        --allele-profile $allele_table \
        --loci-called 0.95 \
        --method MSTreeV2 \
        --columns_summary_report st,specimen_source,patient_county,submitter_name,date,first_seq_date,last_seq_date,timespan_days,patient_age,patient_sex,patient_race \
        --metadata2report st \
        --analysis HC \
        --n_proc $task.cpus \

    """
}
