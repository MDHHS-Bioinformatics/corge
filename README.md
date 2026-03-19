<p align="center">
<img src="docs/images/corge_logo.png" width="250">
</p>

# 🧬 CorGe+: Core Genome plus

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![run with apptainer](https://img.shields.io/badge/run%20with-apptainer-1d355c.svg?labelColor=000000)](https://apptainer.org/docs/user/latest/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/MDHHS-Bioinformatics/mdhhs_repo_template)](https://github.com/MDHHS-Bioinformatics/mdhhs_repo_template/releases)
![Last Commit](https://img.shields.io/github/last-commit/MDHHS-Bioinformatics/mdhhs_repo_template)

[![DOI](https://zenodo.org/badge/DOI/XXXX.svg)](https://zenodo.org/badge/latestdoi/XXXXXX)


**CorGe+** is a bioinformatics pipeline for analyzing bacterial DNA sequencing data. It takes a sample sheet with FASTA files and optionally sample metadata as input, performs either core genome MLST (cgMLST) or core genome alignment and produces linkage tables, Microreact visualizations, metadata summaries, and sample groupings based on allelic or SNP distances for downstream analysis.

## 🌟 Highlights

- 🧬 **Fast and scalable**: Designed for high-throughput screening and large datasets.
- 🔗 **Detects potential linkages**: Identifies related samples using allelic distances (cgMLST) or SNP distances (Parsnp).
- 🧩 **Flexible grouping**: Groups genomes at user-defined thresholds and generates sample sheets for downstream analysis with [PoODLE](https://github.com/MDHHS-Bioinformatics/poodle).
- 📤 **Clear, shareable outputs**: Exports results as CSV tables and Microreact visualizations.
- 🕒 **Tracks trends over time**: Helps monitor related isolates and detect emerging patterns.
- 🧪 **Multi-species support**: Can analyze multiple species in a single run.
- 🗂️ **Built-in surveillance database**: The output directory grows over time:
  * New samples are automatically compared to previous ones
  * Group names remain consistent across batches



## 📊 Workflow Overview

### ![CorGe flow](docs/images/corge_flow.png)

High-level steps:

1. Run [`MashTree`](https://github.com/lskatz/mashtree).
2. Verify cgMLST schema availability for each species.
3. Perform core genome analysis using [`ChewBBACA`](https://github.com/B-UMMI/chewBBACA) (cgMLST) or [`Parsnp`](https://github.com/marbl/parsnp) (core alignment if schema unavailable).
4. Hierarchical clustering with [`ReporTree`](https://github.com/insapathogenomics/ReporTree).
5. Create potential linkage tables per species.
6. Select groups per sample using user-defined thresholds.
7. Generate [`PoODLE`](https://github.com/MDHHS-Bioinformatics/poodle) manifests.
8. Generate [`Microreact`](https://microreact.org/) files for visual exploration of genomic groups in trees.

Full workflow details: [`Worflow documentation`](docs/workflow.md)

## 🚀 Usage

### 1️⃣ Requirements

* [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=22.10.1`)
* [`Docker`](https://docs.docker.com/engine/installation/) (recommended for local runs) or [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/)/[`Apptainer`](https://apptainer.org/docs/user/latest/) (recommended for HPC clusters) for full pipeline reproducibility

> [!NOTE]  
> If using **Singularity/Apptainer** set `NXF_SINGULARITY_CACHEDIR` (or `singularity.cacheDir`) to reuse images later. For example: 
> ```bash
> export NXF_SINGULARITY_CACHEDIR="/path/to/singularity_cache"
> ``````

### 2️⃣ Download cgMLST schemas

Download cgMLST schemas once per species. CorGe+ can fetch them automatically from [cgmlst.org](https://cgmlst.org/).

```bash
nextflow run MDHHS-Bioinformatics/corge \
  -profile singularity \
  --mode schema \
  --schema_ids s1,s20 \
  --outdir corge
```

> [!TIP]
> Find schema IDs in [`cgMLST schema IDs`](assets/cgmlst_schemas_id.csv)

> [!NOTE]
> - The generated schema file (`cgmlst_schemas.csv`) will be used in the next step.
> - Parsnp is triggered when a species lacks a cgMLST schema. 
---

### 3️⃣ Prepare manifest file

Prepare a CSV file describing your input assemblies:

```csv
sample,assembly,species
ISO1,/path/iso1.fasta,Escherichia_coli
ISO2,/path/iso2.fasta,Acinetobacter_baumannii
```

**Input format description**

| Column   | Description                           |
| -------- | ------------------------------------- |
| sample   | Unique sample ID                      |
| assembly | Path to FASTA assembly                |
| species  | Species name (must match schema file) |

---

### 4️⃣ Run

Run the pipeline using:

```bash
nextflow run MDHHS-Bioinformatics/corge \
  -profile singularity \
  --input manifest.csv \
  --cgmlst_schemas cgmlst_schemas.csv \
  --outdir results
```

> [!TIP]
> Default clustering thresholds: `15,20,40,150`
> You can customize them with `--thresholds`


### 🔧 Optional: Custom thresholds

```bash
nextflow run MDHHS-Bioinformatics/corge \
  -profile singularity \
  --input manifest.csv \
  --cgmlst_schemas cgmlst_schemas.csv \
  --outdir results \
  --thresholds 1,10,100,1000
```


For more details and advanced usage, see the
[`Usage documentation`](docs/usage.md) and [`Parameter documentation`](docs/parameters.md)

---

## 📂 Outputs

Results are structured by **species**:

```text
   📁 <outdir>/
    └── 📁 <Species>/
        ├── 📁 assemblies/
        ├── 📁 cgMLST/ or 📁 parsnp/
        ├── 📁 genomic_context_groups/
        ├── 📁 linkages/
        ├── 📁 mashtree/
        ├── 📁 metadata/ (when `--metadata` is used)
        ├── 📁 microreact/
        ├── 📁 tree/ (when `--tree` is used)
        ├── 📁 poodle_samplesheets/
        └── 📁 ReporTree/
```
For more details about the output files and reports, please refer to the [`Output documentation`](docs/output.md)

Key outputs:
* Linkages tables
* Genomic context group tables
* PoODLE samplesheets
* Microreact visualizations


## 👥 Credits

CorGe+ was built and is maintained by the Genomics Analysis Unit at the Michigan Department of Health & Human Services (MDHHS) Bureau of Laboratories. This pipeline was developed by [Douglas Maldonado-Torres](https://github.com/MTDouglas) and [Karla Vasco](https://github.com/vascokarla) using the nf-core template.

## 🤝 Contributions
Contributions, issues, and pull requests are welcome! If you would like to contribute to this pipeline, please see the [`Contribution guidelines`](CONTRIBUTING.md). 

## 📚 Citations

If you use CorGe+ for your analysis, please cite the following doi:

Maldonado-Torres D & Vasco K (2026). 
MDHHS-Bioinformatics/CorGe+: v1.0.0 (v1.0.0). 
Zenodo. https://doi.org/XX.XXX/zenodo.XXXX

An extensive list of references for the tools used by the pipeline can be found in [`CITATIONS.md`](CITATIONS.md).


## ⚠️ Disclaimer
This repository is not a source of government records but is intended to increase collaboration and collaborative potential on public health related projects. Materials and information in this repository are intended to share information and collaboratively develop analysis workflows. 

The workflows and pipelines reflect the current understanding of the software and biological questions being answered and may be updated as needed and pursuant to further analysis and review. No warranty, expressed or implied, is made by MDHHS Bureau of Laboratories as to the functionality of the software and related material nor shall the fact of release constitute any such warranty. Furthermore, the software is released on condition that the MDHHS Bureau of Laboratories shall not be held liable for any damages resulting from its authorized or unauthorized use. 

## 🔒 Privacy Notice
Use of this service is limited only to non-sensitive and publicly available data. Users must not use, share, or store any kind of sensitive data like health status, provision or payment of healthcare, Personally Identifiable Information (PII) and/or Protected Health Information (PHI), etc. under any circumstance.

## 📜 License
This project is released under the [**MIT License**](LICENSE).
