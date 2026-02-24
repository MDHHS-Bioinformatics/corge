# MDHHS-Bioinformatics/corge: Output

## Introduction

This document describes the output produced by the pipeline. 

The directories listed in [`corge_outputs.md`](../docs/corge_outputs.md) will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [cgMLST](#cgmlst) - ChewBBACA results for species with cgMLST schema
- [Parsnp](#parsnp) - Parsnp results for species without cgMLST schema
- [ReporTree](#reporTree) - ReporTree results with clustering and metadata information
- [MashTree](#mashTree) - MashTree results
- [Metadata](#metadata) - Metadata information for the species
- [Microreact](#microreact) - Microreact file
- [Genomic context groups](#genomic-context-groups) - Genomic context groups selected at the given thresholds
- [Linkages](#linkage-analysis) - File with per-sample information about strong, intermediate and lineage level thresholds
- [PoODLE samplesheets](#poodle-samplesheets) - PoODLE manifests for downstream analysis
- [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution
- [Tree](#tree) - Phylogenetic tree information

### cgMLST
Detailed output information for each sudirectory are shown below:
- `new/`: Only cgMLST results for the last batch. More details: [AlleleCall](https://chewbbaca.readthedocs.io/en/latest/user/modules/AlleleCall.html)
- `joined/`: Joined results from new and previous results. More details: [JoinProfile](https://chewbbaca.readthedocs.io/en/latest/user/modules/JoinProfiles.html)
- `masked/`: Masked invalid and inferred loci alleles, used as input for ReporTree. More details: [ExtractCgMLST](https://chewbbaca.readthedocs.io/en/latest/user/modules/ExtractCgMLST.html)
- `msa/`: computed multiple-sequence alignment generated when the `--tree` option is used. More details: [ComputeMSA](https://chewbbaca.readthedocs.io/en/latest/user/modules/ComputeMSA.html#outputs)

### Parsnp
For species **without** a cgMLST schema, CorGe+ uses **Parsnp** to generate core-genome alignments and SNP-based comparisons.

| File | Description |
|------|-------------|
| `<Species>_core_msa.fasta` | **Multiple-sequence alignment** — alignment of core-genome regions in FASTA format (only when `--tree` is used) |
| `<Species>_parsnp.ggr` | **Genome Graph Representation** — a binary file used internally by Parsnp to represent the alignment graph. |
| `<Species>_parsnp.maf` | **Multiple Alignment Format (MAF)** — contains the core-genome alignment across all input genomes. |
| `<Species>_parsnp.rec` | **Recombination Regions** — lists regions identified as recombinant and excluded from SNP analysis (if `--recomb-filter` is used). |
| `<Species>_parsnp.snps.mblocks` | **SNP Blocks** — lists SNPs grouped into blocks, useful for downstream phylogenetic analysis. |
| `<Species>_parsnp.xmfa` | **Extended Multi-FASTA Alignment (XMFA)** — alignment of core-genome regions in XMFA format, compatible with tools like Mauve. |
| `<Species>_parsnpAligner.ini` | **Configuration File** — records the parameters and settings used during the Parsnp run. |
| `<Species>_parsnpAligner.log` | **Log File** — detailed log of the Parsnp execution, including progress and any warnings or errors. |
| `<Species>_snps_alignment.fasta` | **SNP Alignment** — FASTA file containing the core-genome SNP alignment with reference and assembly extensions removed, used for ReporTree. |

### ReporTree
Details at [ReporTree-Main-Outputs](https://github.com/insapathogenomics/ReporTree/wiki/2.-Input-Output#main-output-files)

### MashTree
MashTree generates:

- A Newick tree (.dnd)
- A distance matrix
- A midpoint-rooted tree used in the Microreact export

### Metadata
A filtered .tsv file is produced per species if the `--metadata` file is provided.

### Microreact
CorGe+ generates a `.microreact` file that brings together **complementary genetic perspectives**:

* **Mashtree** — produces a k-mer–based distance tree that reflects overall genome composition, including accessory genes.
* **Core-genome distance tree** — prepared by ReporTree with the MSTreeV2 method, it's useful for visualizing genetic relatedness among isolates.
* **Maximum-Likelihood tree** — phylogenetic tree based on DNA sequence alignment, included when `--tree` is used.

Microreact provides an intuitive way to explore how samples group at the thresholds defined with `--thresholds`, and helps you decide which group threshold to use in downstream high-resolution analyses.

To aid interpretation, Microreact also displays **heatmaps per threshold**, using the ReporTree **partition nomenclature**.
Each partition corresponds to a hierarchical clustering level and includes the method, numeric threshold, and distance unit. For example, threshold **15** corresponds to the partition `single-15x1.0`.

To visualize, upload the `.microreact` file to [`Microreact/upload`](https://microreact.org/upload)

_Microreact example using default settings_
### ![Microreact example](images/corge_microreact_example.png)

_Microreact example using the `--tree` option_
### ![Microreact example](images/corge_microreact_example_ml.png)

### Tree
This subdirectory contains files related to phylogenetic tree inference when `--tree` is used:

- **Constant sites**: Proportion of A, G, T, and C sites observed in the alignment, used by IQ-TREE to adjust branch lengths.
- **Rooted tree**: A midpoint-rooted maximum-likelihood (ML) tree used for Microreact export.
- **IQ-TREE file**: Summary file containing log output and model information from IQ-TREE.
- **NWK**: Newick-formatted tree generated by IQ-TREE. When more than four samples are included, ultrafast bootstrap support values are reported.

### PoODLE samplesheets

[**PoODLE**](https://github.com/MDHHS-Bioinformatics/poodle) is a Nextflow pipeline for high-resolution analysis of bacterial groups, combining hqSNP calling ([`Snippy`](https://github.com/tseemann/snippy)), recombination filtering ([`Gubbins`](https://github.com/nickjcroucher/gubbins)), phylogenetics ([`IQ-TREE`](https://iqtree.github.io/)), pangenome analysis ([`Panaroo`](https://github.com/gtonkinhill/panaroo)), and Mash distance estimation ([`MashTree`](https://github.com/lskatz/mashtree)). It produces an interactive HTML report for each cluster with trees, pangenome profile, and distance matrices.

CorGe+ automatically generates a PoODLE-compatible manifest for every selected threshold if genomic context groups were identified. The required columns are:

```
sample,fastq_1,fastq_2,gff,assembly,cluster_id,species,reference
```

The FASTQ and GFF fields are left empty by default, but CorGe+ can fill them automatically if you provide a **PHoeNIx** directory (`--phoenix_path`), a **Bactopia** results directory (`--bactopia_path`), or a CSV with paths via `--master_paths`.

For each cluster, CorGe+ selects a reference genome based on the "best" assembly quality (fewest contigs, longest length, and alphabetical tie-break).

### Genomic context groups

Files: `<Species>-groups_HC<threshold>.csv`
One file is produced for **each threshold** selected with `--thresholds`.

These tables define groups of samples for downstream analysis, using the standardized `HC<partition>-C<id>` nomenclature. Example: `HC20-C25`
  * **Partition** corresponds to the *lowest distance at which two clusters merge* under single-linkage at the chosen threshold.
  * **Cluster IDs** (`C1`, `C2`, …) are unique within each partition.
  * Group names remain **stable across batches** because CorGe+ reuses `partitions.csv` from previous runs.

  **Columns:**

  * `sample`
  * `species`
  * `group_name` — stable cluster label in the form `HC<partition>-C<id>`
  * `group_length` — number of samples in the group
  * `group_samples` — comma-separated list of all samples in the group
  * `report_date` — timestamp of the analysis

### Linkage analysis

File: `<Species>_potential_linkages.csv`

This table summarizes genome completeness and identifies **strong**, **intermediate**, or **lineage-level** linkages between samples based on **cgMLST allelic distances** or **SNP distances** (Parsnp), depending on the analysis performed.

### Columns

* `sample` — sample identifier

* `species` — species assignment used for cgMLST or SNP-based analysis

* `percentage_called` — proportion of the cgMLST schema (or aligned genome length) successfully called for the sample (range 0–1; e.g. `0.95` = 95%)

* `completeness_qc` — genome completeness quality flag derived from `percentage_called`:

  * **PASS**: ≥ 95%
  * **WARN**: 90–94.9%
  * **FAIL**: < 90%

  Samples flagged as **WARN** or **FAIL** may yield unreliable distance estimates due to incomplete assemblies, misassemblies, contamination, or incorrect species assignment. Linkages involving these samples should be interpreted with caution. We recommend confirming relatedness using **read-based analyses** with samples at the **lineage level** to avoid missing potential links.

* `min_dist` — minimum genetic distance to any other sample:

  * **allelic distance (AD)** when cgMLST is used
  * **SNP distance** when Parsnp is used

* `strong_linkages` — highly similar isolates (distance 0–10).

* `intermediate_linkages` — moderately similar isolates (distance 11–40).

* `lineage_level` — related isolates (distance 41–150).

### Pipeline information

### 
<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
