# cgMLST schema provided
     📁 corge
      └── 📁 <Species>
            ├── 📁 assemblies
            │    └── 📄 <sample>.fasta (one Fasta per sample)
            ├── 📁 cgMLST
            │   ├── 📁 joined
            │   │   └── 📄 joined_results_alleles.tsv
            │   ├── 📁 masked
            │   │    ├── 📄 Presence_Abscence.tsv
            │   |    ├── 📄 cgMLST0.tsv
            │   |    ├── 📄 cgMLSTschema0.txt
            │   |    ├── 📄 masked_results_alleles.tsv
            │   |    └── 📄 cgMLST.html
            │   └── 📁 new
            │       ├── 📄 cds_coordinates.tsv
            │       ├── 📄 invalid_cds.txt
            │       ├── 📄 loci_summary_stats.tsv
            │       ├── 📄 logging_info.txt
            │       ├── 📄 paralogous_loci.tsv
            │       ├── 📄 results_alleles.tsv
            │       ├── 📄 results_contigsInfo.tsv
            │       └── 📄 results_statistics.tsv
            ├── 📁 linkage_analysis
            │   └── 📄 <Species>_potential_linkages.csv
            ├── 📁 genomic_context_groups
            │   └── 📄 <Species>-groups_HC<threshold>.csv (one per threshold)
            ├── 📁 mash
            │   ├── 📄 <Species>_mash.dist
            │   ├── 📄 <Species>_mash.dnd
            │   └── 📄 <Species>_mash_rooted.tre
            ├── 📁 microreact
            │   └── 📄 <Species>_corge.microreact
            └── 📁 ReporTree
                 ├── 📄 <Species>_clusterComposition.tsv
                 ├── 📄 <Species>_dist_hamming.tsv
                 ├── 📄 <Species>_flt_samples_matrix.tsv
                 ├── 📄 <Species>_loci_report.tsv
                 ├── 📄 <Species>_nomenclature_changes.tsv
                 ├── 📄 <Species>_partitions.tsv
                 ├── 📄 <Species>_single_HC.nwk
                 └── 📄 <Species>.log

# No cgMLST schema provided (Parsnp)
     📁 corge
      └── 📁 <Species>
            ├── 📁 assemblies
            │    └── 📄 <sample>.fasta (one Fasta per sample)
            ├── 📁 parsnp
            │   ├── 📁 config
            │   ├── 📁 log
            │   ├── 📄 <sample>.fasta.ref
            │   ├── 📄 parsnp.ggr
            │   ├── 📄 parsnp.snps.mblocks
            │   ├── 📄 parsnp.xmfa
            │   ├── 📄 parsnpAligner.ini
            │   ├── 📄 paralogous_loci.tsv
            │   ├── 📄 snps_alignment_no_ref.fasta
            │   └── 📄 snps_alignment.fasta
            ├── 📁 linkage_analysis
            │   └── 📄 <Species>_potential_linkages.csv
            ├── 📁 genomic_context_groups
            │   └── 📄 <Species>-groups_HC<threshold>.csv (one per threshold)
            ├── 📁 mash
            │   ├── 📄 <Species>_mash.dist
            │   ├── 📄 <Species>_mash.dnd
            │   └── 📄 <Species>_mash_rooted.tre
            ├── 📁 microreact
            │   └── 📄 <Species>_corge.microreact
            └── 📁 ReporTree
                 ├── 📄 <Species>_clusterComposition.tsv
                 ├── 📄 <Species>_dist_hamming.tsv
                 ├── 📄 <Species>_flt_samples_matrix.tsv
                 ├── 📄 <Species>_loci_report.tsv
                 ├── 📄 <Species>_nomenclature_changes.tsv
                 ├── 📄 <Species>_partitions.tsv
                 ├── 📄 <Species>_single_HC.nwk
                 └── 📄 <Species>.log