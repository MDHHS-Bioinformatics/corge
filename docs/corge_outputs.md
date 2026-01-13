# cgMLST schema provided
     📁 corge
      ├── 📁 pipeline_info
      │    ├── 📄 execution_report_<date-hour>.html (one per batch)
      │    ├── 📄 execution_timeline_<date-hour>.html (one per batch)
      │    ├── 📄 execution_trace_<date-hour>.txt (one per batch)
      │    ├── 📄 software_versions.yml
      │    └── 📄 samplesheet.valid.csv
      └── 📁 <Species>
            ├── 📁 assemblies
            │    └── 📄 <sample>.fasta (one Fasta per sample)
            ├── 📁 cgMLST
            │   ├── 📁 joined
            │   │   └── 📄 <Species>_joined_results_alleles.tsv
            │   ├── 📁 masked
            │   │    ├── 📄 <Species>_Presence_Abscence.tsv
            │   |    ├── 📄 <Species>_masked_results_alleles.tsv
            │   |    ├── 📄 <Species>_cgMLSTschema0.txt
            │   |    └── 📄 <Species>_cgMLST.html
            │   ├── 📁 msa (only if --tree is used)
            │   │    ├── 📄 <Species>_dna_msa_variable.fasta
            │   |    ├── 📄 <Species>_dna_msa.fasta
            │   |    ├── 📄 <Species>_protein_msa_variable.fasta
            │   |    ├── 📄 <Species>_protein_msa.fasta
            │   |    └── 📄 <Species>_protein_summary_stats.tsv
            │   └── 📁 new
            │       ├── 📄 <Species>_new_cds_coordinates.tsv
            │       ├── 📄 <Species>_new_invalid_cds.txt
            │       ├── 📄 <Species>_new_loci_summary_stats.tsv
            │       ├── 📄 <Species>_new_logging_info.txt
            │       ├── 📄 <Species>_new_paralogous_loci.tsv
            │       ├── 📄 <Species>_new_results_alleles.tsv
            │       ├── 📄 <Species>_new_results_contigsInfo.tsv
            │       └── 📄 <Species>_new_results_statistics.tsv
            ├── 📁 linkage_analysis
            │   └── 📄 <Species>_potential_linkages.csv
            ├── 📁 genomic_context_groups
            │   └── 📄 <Species>-groups_HC<threshold>.csv (one per threshold)
            ├── 📁 mash
            │   ├── 📄 <Species>_mash.dist
            │   ├── 📄 <Species>_mash.dnd
            │   └── 📄 <Species>_mash_rooted.tre
            ├── 📁 metadata
            │   └── 📄 <Species>_metadata.tsv (curated metadata if provided)
            ├── 📁 microreact
            │   └── 📄 <Species>_corge.microreact
            ├── 📁 poodle_samplesheets
            │   └── 📄 <Species>_poodle_manifest_HC<threshold>.csv (one per threshold)
            ├── 📁 ReporTree
            │    ├── 📄 <Species>_clusterComposition.tsv
            │    ├── 📄 <Species>_dist_hamming.tsv
            │    ├── 📄 <Species>_flt_samples_matrix.tsv
            │    ├── 📄 <Species>_loci_report.tsv
            │    ├── 📄 <Species>_nomenclature_changes.tsv
            │    ├── 📄 <Species>_partitions.tsv
            │    ├── 📄 <Species>_single_HC.nwk
            │    └── 📄 <Species>.log
            └── 📁 tree (only if --tree is used)
                ├── 📄 <Species>_constant-sites.txt
                ├── 📄 <Species>_rooted_cgmlst_snp.tree
                ├── 📄 <Species>.iqtree
                └── 📄 <Species>.nwk

# No cgMLST schema provided (Parsnp)
     📁 corge
      ├── 📁 pipeline_info
      │    ├── 📄 execution_report_<date-hour>.html (one per batch)
      │    ├── 📄 execution_timeline_<date-hour>.html (one per batch)
      │    ├── 📄 execution_trace_<date-hour>.txt (one per batch)
      │    ├── 📄 software_versions.yml
      │    └── 📄 samplesheet.valid.csv
      └── 📁 <Species>
            ├── 📁 assemblies
            │    └── 📄 <sample>.fasta (one Fasta per sample)
            ├── 📁 parsnp
            │   ├── 📄 <Species>_core_msa.fasta (only if --tree is used)
            │   ├── 📄 <Species>_parsnp.ggr
            │   ├── 📄 <Species>_parsnp.maf
            │   ├── 📄 <Species>_parsnp.rec
            │   ├── 📄 <Species>_parsnp.snps.mblocks
            │   ├── 📄 <Species>_parsnp.xmfa
            │   ├── 📄 <Species>_parsnpAligner.ini
            │   ├── 📄 <Species>_parsnpAligner.log
            │   └── 📄 <Species>_snps_alignment.fasta
            ├── 📁 linkage_analysis
            │   └── 📄 <Species>_potential_linkages.csv
            ├── 📁 genomic_context_groups
            │   └── 📄 <Species>-groups_HC<threshold>.csv (one per threshold)
            ├── 📁 metadata
            │   └── 📄 <Species>_metadata.tsv (curated metadata if provided)
            ├── 📁 mash
            │   ├── 📄 <Species>_mash.dist
            │   ├── 📄 <Species>_mash.dnd
            │   └── 📄 <Species>_mash_rooted.tre
            ├── 📁 microreact
            │   └── 📄 <Species>_corge.microreact
            ├── 📁 poodle_samplesheets
            │   └── 📄 <Species>_poodle_manifest_HC<threshold>.csv (one per threshold)
            ├── 📁 ReporTree
            │    ├── 📄 <Species>_clusterComposition.tsv
            │    ├── 📄 <Species>_dist_hamming.tsv
            │    ├── 📄 <Species>_flt_samples_matrix.tsv
            │    ├── 📄 <Species>_loci_report.tsv
            │    ├── 📄 <Species>_nomenclature_changes.tsv
            │    ├── 📄 <Species>_partitions.tsv
            │    ├── 📄 <Species>_single_HC.nwk
            │    └── 📄 <Species>.log
            └── 📁 tree (only if --tree is used)
                ├── 📄 <Species>_constant-sites.txt
                ├── 📄 <Species>_rooted_parsnp.tree
                ├── 📄 <Species>.iqtree
                └── 📄 <Species>.nwk