<img src="docs/images/corge_logo.png" alt="CorGe Logo" width="100" align="right"/>

# 🧬 CorGe+ — Core Genome plus **grouping** of bacteria

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)


CorGe+ is a **Nextflow** pipeline designed for **bacterial genomic surveillance and linkage investigation**. It performs **core genome MLST (cgMLST)** or **core genome alignment** and then identifies potential linkages between samples and clusters isolates into **genomic context groups**.

It’s portable, reproducible, and simple — whether you’re tracking an outbreak or monitoring genomic trends over time. More details [below](#-designed-for-bacterial-surveillance)

# Table of Contents
- [Pipeline summary](#-pipeline-summary)
- [Quick Start](#-quick-start)
- [Parameters](#parameters)
- [Designed for bacterial surveillance](#-designed-for-bacterial-surveillance)
- [When to use what](#-when-to-use-what)
- [Key files: Linkages & context groups](#-key-files-linkages--context-groups)
- [Best practices & caveats](#-best-practices--caveats)
- [Troubleshooting](#-troubleshooting)
- [Output overview](#-output-overview)
- [Citations](#-citations)
- [Credits & Community](#credits--community)
- [License](#-license)

---

## 🧩 Pipeline summary

1. Verify cgMLST schema availability for each species.
2. Perform core genome analysis using [`ChewBBACA`](https://github.com/B-UMMI/chewBBACA) (cgMLST) or [`Parsnp`](https://github.com/marbl/parsnp) (core alignment if schema unavailable).
3. Hierarchical clustering with [`ReporTree`](https://github.com/insapathogenomics/ReporTree) (method = `single`).
4. Create potential linkage tables per species.
5. Select groups per sample using user-defined thresholds.
6. Generate [`PoODLE`](https://github.com/MI-Bioinformatics/poodle) manifests.
7. Run [`MashTree`](https://github.com/lskatz/mashtree).
8. Generate [`Microreact`](https://microreact.org/) files for visual exploration of genomic groups in trees based on core genome and Mash distances.

### ![CorGe workflow](docs/images/corge_workflow.png)

---

## ⚡ Quick Start

### 1. Install prerequisites

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=22.10.1`)
2. Install [`Docker`](https://docs.docker.com/engine/installation/) or [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) for full pipeline reproducibility.

> [!NOTE]  
> If using **Singularity** set `NXF_SINGULARITY_CACHEDIR` (or `singularity.cacheDir`) to reuse images later.

---

### 2. Download cgMLST schemas

You only need to download each species’ cgMLST schema **once**. CorGe+ can automatically fetch and prepare schemas from [`cgmlst.org`](https://cgmlst.org/).

- **Step 1. Download the schemas**: Find the schema ID in [`cgMLST schema IDs`](https://github.com/MI-Bioinformatics/CorGe/blob/feature/prepcgmlst/assets/cgmlst_schemas_id.csv) (e.g., *A. baumannii* = `s1`, *E. coli* = `s20`). Multiple IDs can be listed as: `--schema_ids s1,s20`.

```bash
nextflow run MI-Bioinformatics/CorGe \
  --mode schema \
  --schema_ids s1,s20 \
  --outdir corge \
  -profile singularity
```

- **Step 2. Check the generated schema file**: CorGe+ writes a summary to: `<outdir>/cgmlst_schemas/cgmlst_schemas.csv`. Some schemas can be used for multiple species and this file will automatically reflect those mappings (e.g. _E. coli_ cgMLST schema can be used for _Escherichia_ and _Shigella_ spp.). You can browse the full list of supported species here [`cgMLST species`](https://github.com/MI-Bioinformatics/CorGe/blob/feature/prepcgmlst/assets/species_schemas.csv). Use `<outdir>/cgmlst_schemas/cgmlst_schemas.csv` for downstream runs. Example cgMLST schema file:

```
species,cgmlst_path
Acinetobacter_baumannii,/path/to/Acinetobacter_baumannii_cgMLST
Escherichia_albertii,/path/to/Escherichia_coli_cgMLST
Escherichia_coli,/path/to/Escherichia_coli_cgMLST
Escherichia_fergusonii,/path/to/Escherichia_coli_cgMLST
Escherichia_marmotae,/path/to/Escherichia_coli_cgMLST
Escherichia_ruysiae,/path/to/Escherichia_coli_cgMLST
Shigella_boydii,/path/to/Escherichia_coli_cgMLST
Shigella_dysenteriae,/path/to/Escherichia_coli_cgMLST
Shigella_flexneri,/path/to/Escherichia_coli_cgMLST
Shigella_sonnei,/path/to/Escherichia_coli_cgMLST
```

> [!NOTE]
> If a species schema is not available on [`cgmlst.org`](https://cgmlst.org/), you can still use CorGe+ without a schema.
> You could also download schemas from [`Chewie-NS`](https://chewie-ns.readthedocs.io/en/latest/), create your own schema, or prepare an external one using [ChewBBACA](https://chewbbaca.readthedocs.io/en/latest/index.html). Once your custom schema is ready, add it to the schema's file.

### 3. Prepare your manifest file
Include:
* `sample`: unique ID (no spaces recommended)
* `assembly`: absolute path to FASTA assembly for the sample (uncompressed FASTA only; .gz or .zip not supported)
* `species`: Species name used for taxonomic grouping. It must match the species name used in the cgMLST schema file. Any spaces in the name will be automatically replaced with underscores.
```
sample,assembly,species
ISO1,/path/iso1.fasta,Escherichia_coli
ISO2,/path/iso2.fasta,Escherichia coli
ISO3/path/iso3.fasta,Acinetobacter baumannii
ISO4,/path/iso4.fasta,Acinetobacter baumannii
```

### 4. Run your analyses

### Basic run

```bash
nextflow run MI-Bioinformatics/CorGe \
  --input manifest.csv \
  --cgmlst_schemas cgmlst_schemas.csv \
  --outdir corge \
  -profile singularity
```

Default clustering thresholds: `15,20,40,150` (alleles for cgMLST or SNPs for Parsnp) — customizable via `--thresholds 1,10,100,1000`.

### With custom thresholds

```bash
nextflow run MI-Bioinformatics/CorGe \
  --input manifest.csv \
  --cgmlst_schemas cgmlst_schemas.csv \
  --outdir results \
  --thresholds 1,10,100,1000 \
  -profile singularity
```

### Expert level

```bash
nextflow run MI-Bioinformatics/CorGe \
  --input manifest.csv \
  --cgmlst_schemas cgmlst_schemas.csv \
  --outdir /path/to/corge \
  --thresholds 5,10,20,30,150 \
  --metadata full_lims_data.csv \
  --columns_summary_report st,specimen_source,specimen_type,patient_county,submitter_name,date,first_seq_date,last_seq_date,timespan_days \
  --metadata2report st \
  --count_matrix st,specimen_source \
  --phoenix_path /path/to/phx_output \
  --max_memory 160.GB \
  --max_cpus 24 \
  --max_time 8.h \
  -profile singularity

```

>[!Note]
>This command clones (downloads) the repo to ~/.nextflow/assets/MI-Bioinformatics/CorGe. You can download the pipeline in a different location using `git clone https://github.com/MI-Bioinformatics/CorGe`. To run the pipeline, specify the path to the cloned repository (e.g. `nextflow run /path/to/CorGe ...`) 

---

## Parameters

### **📥 Input & Core Parameters**

| Parameter          | Required | Default        | Description                                                                                                |
| ------------------ | :------: | -------------- | ---------------------------------------------------------------------------------------------------------- |
| `--input`          |     ✓    | –              | Manifest CSV (`sample,assembly,species`).                                                                  |
| `--outdir`         |     ✓    | `$PWD/corge`   | Output directory root.                                                                                     |
| `--cgmlst_schemas` |     ✓    | –              | CSV mapping species to cgMLST schemas (`species,cgmlst_path`). Parsnp is used for species with no schema. |
| `--thresholds`     |     ✓    | `15,20,40,150` | Allelic/SNP distance thresholds for grouping samples. Comma-separated integers.                                                 |
| `--mode`           |     ✓    | `default`      | `default` or `schema` for **schema-download workflow**.                                                          |
| `--schema_ids`     |     –    | –              | Comma-separated schema IDs (no spaces), required when `--mode schema` is used (e.g., s1,s20).                                                    |


### ⚙️ **Execution Configuration**

| Parameter      | Required | Default  | Description                                                                                                                      |
| -------------- | :------: | -------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `-profile`     |     ✓    | –        | Execution profile (`docker` or `singularity`).                                                             |
| `--max_memory` |     ✓    | `128.GB` | Maximum memory allocation.                                                                                                       |
| `--max_cpus`   |     ✓    | `16`     | Maximum CPUs allowed.                                                                                                            |
| `--max_time`   |     ✓    | `24.h`   | Maximum execution time.                                                                                                          |
| `-resume`      |     –    | –        | Reuse cached results from previous runs when inputs and code haven't changed. Ideal for interrupted runs. |

More NextFlow configuration options [`here`](https://www.nextflow.io/docs/latest/reference/config.html).


### **📦 Data Source Options (for PoODLE Manifests)**
[`PoODLE`](https://github.com/MI-Bioinformatics/poodle) is a Nextflow pipeline for parallel analysis of multiple bacterial species clusters, including hqSNP calling, recombination filtering, pangenome analysis, Mash, and report generation.
These options allow CorGe+ to automatically fill PoODLE manifests with read and annotation paths. They are optional, but only **one** may be used per run. If none are provided, the [`PoODLE samplesheets`](#-poodle-samplesheets) will contain empty placeholders for FASTQ and GFF paths, which you must fill in manually before running PoODLE.

| Parameter         | Required | Default | Description                                                                                       |
| ----------------- | :------: | ------- | ------------------------------------------------------------------------------------------------- |
| `--master_paths`  |     –    | –       | CSV with explicit absolute paths to reads and annotations (`sample,fastq_1,fastq_2,gff`). Use this when you already have all paths from the database organized in a single file.  |
| `--phoenix_path`  |     –    | –       | Absolute path to a PHoeNIx results directory. CorGe+ will infer read and annotation paths based on sample IDs. Use if your data was processed with PHoeNIx.                                         |
| `--bactopia_path` |     –    | –       | Absolute path to a Bactopia results directory. CorGe+ will infer read and annotation paths based on sample IDs. Use if your data was processed with Bactopia.                                        |


### 🌳 **ReporTree Options**
ReporTree can link genetic clusters with epidemiological data through summary tables showing key statistics and trends. These parameters are optional but strongly recommended when generating lineage-, time-, or metadata-based reports.

| Parameter                  | Required | Default        | Description                                                                                                                                                                                                                                               |
| -------------------------- | :------: | -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--metadata`               |     –    | –              | Metadata table (CSV/TSV) used for reporting. Must include **all samples** (new + previous) for the species. Sample IDs in the first column must match CorGe+ names. Recommended to include a `date` column (YYYY-MM-DD) for temporal summaries.                        |
| `--columns_summary_report` |     –    | Predefined set | Metadata columns to summarize per cluster. Supports counts (`n_country`), distributions (`country`), and—if a `date` column exists—temporal measures (first/last sample date and time span). Useful for generating cluster-level epidemiological summaries. (default: `n_sequence,lineage,n_country,country,n_region,first_seq_date,last_seq_date,timespan_days`)|
| `--metadata2report`        |     –    | –              | Additional metadata columns for which **separate** summary reports should be created. Useful when tracking specific fields (e.g.,`st,source,serotype,AMR_profile`).                                                                                   |
| `--filter`                 |     –    | –              | Filter samples before analysis using expressions such as `'country == USA'` or `'country == USA;date > 2024-01-01'`. Supports multiple conditions and multiple columns.                                                                                   |
| `--frequency_matrix`       |     –    | –              | Generate frequency matrices showing the proportion of samples for variable combinations (e.g., `'lineage,iso_week'` → lineage distribution over time). Supports multiple matrices.                                                                        |
| `--count_matrix`           |     –    | –              | Same as `--frequency_matrix` but outputs raw counts instead of percentages. Useful for plotting absolute numbers across time or categories.                                                                                                               |

More details about these options in [`ReporTree`](https://github.com/insapathogenomics/ReporTree?tab=readme-ov-file#usage).

---

## 🔍 Designed for bacterial surveillance

CorGe+ was created to make **genomic epidemiology, routine surveillance, and outbreak screening both fast and accessible**. It helps you:

* 🕒 **Track related isolates over time** and monitor emerging patterns.
* 🧬 **Group genomes by allelic or SNP distance** using cgMLST or core-genome alignment.
* 🔗 **Identify potential linkages** based on allelic distances (cgMLST) or SNP distances (Parsnp).
* 📤 **Export clean, shareable outputs** (CSV tables + Microreact visualizations).
* 🧩 **Feed selected genomic context groups** into the downstream pipeline [`PoODLE`](#-poodle-samplesheets) for high-quality SNP and pangenome analyses.

When the first question is *“Are these isolates related?”*, CorGe+ gives you a fast answer.

### Multi-species and incremental analysis

CorGe+ can analyze **multiple species in a single run**.
The output directory acts as a **growing surveillance database** — new samples are automatically compared with previous ones, and group nomenclature remains stable across batches.

If you need to **analyze a batch independently** (e.g., without comparing to historical data), simply specify a **new `--outdir`** and include only the samples you want to compare in the manifest.

---

>[!NOTE]
>**Disclaimer**: This pipeline is only for investigation and epidemiology use. *The data presented in this pipeline has not been validated or subjected to CLIA standards for diagnosing and treating disease. Relatedness by WGS should not replace epidemiological investigations for determining linkage.*

## 🧭 When to use what

### **🔹 cgMLST (ChewBBACA)** — *preferred method*

Used automatically when a cgMLST schema is available for the species.

* Works with as few as **2 samples**.
* Provides **stable, reference-free** allele calling (40–80% of the genome).

---

### **🔹 Parsnp fallback** — *used when no cgMLST schema exists*

Parsnp is triggered when a species lacks a schema.

* Recommended: **≥5 samples** for meaningful alignments.
* Minimum: **2 samples**, but expect longer runtimes and reduced SNP accuracy.
* Assembly-based SNPs are often **inflated**, so treat Parsnp results as **screening** only. Apply **higher SNP thresholds** (e.g., ~150 SNPs) when evaluating potential linkages.
* For downstream confirmation, use an hqSNP workflow (e.g., [`Snippy`](https://github.com/tseemann/snippy) and [`Gubbins`](https://github.com/nickjcroucher/gubbins)).

---

### **🔹 Group thresholds (allelic or SNP distance cutoffs)**

Thresholds determine **which samples are grouped together** for downstream high-resolution analysis like [**PoODLE**](https://github.com/MI-Bioinformatics/poodle) (hqSNPs, recombination filtering, pangenome comparisons).
These groups are **not strict “clusters”**, since they can include contextual samples to maintain lineage-level resolution.

**Practical guidance from surveillance experience:**

* **15–20 alleles**

  * Useful for species or STs that are *highly prevalent* and genetically tight
    (e.g., *Acinetobacter baumannii* ST2, *Klebsiella pneumoniae* ST219).
  * Helps separate closely related sub-lineages.

* **40 alleles**

  * Good general-purpose threshold to keep **linked + contextual** samples together
    within the same broader lineage.

* **150 alleles**

  * Useful when a cluster has **too few samples** and you want to include more that are
    still related at a lineage level but not necessarily linked.

A meaningful group for downstream SNP-based analysis ideally contains **>4 samples**.
If your group becomes too large, **lower the threshold** to retain only the most strongly related isolates.

---

> [!TIP]
> Use the [**Microreact visualization**](https://github.com/MI-Bioinformatics/CorGe/tree/development#-microreact-export) to explore the dataset and decide which thresholds best capture meaningful relationships for your species or lineage.

---

## 🔑 Key files: Linkages & context groups

CorGe+ generates two main tables to support surveillance, cluster interpretation, and downstream hqSNP-based analysis.

### **📘 Potential linkages**

File: `<Species>_potential_linkages.csv`
Identifies **strong** or **intermediate** linkages between samples based on **allelic distances** (cgMLST) or **SNP distances** (Parsnp).

**Columns:**

* `sample`
* `strong_linkages` — highly similar isolates (0-10)
* `intermediate_linkage` — moderately similar isolates (11-40)
* `lineage_level` — less similar isolates (41-150)

---

### **📗 Genomic context groups**

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

---

### 📝 **PoODLE samplesheets**
<img src="docs/images/corge_poodle.png" alt="CorGe PoODLE" width="200" align="right"/>

[**PoODLE**](https://github.com/MI-Bioinformatics/poodle) is a Nextflow pipeline for high-resolution analysis of bacterial groups, combining hqSNP calling ([`Snippy`](https://github.com/tseemann/snippy)), recombination filtering ([`Gubbins`](https://github.com/nickjcroucher/gubbins)), phylogenetics ([`IQ-TREE`](https://iqtree.github.io/)), pangenome analysis ([`Panaroo`](https://github.com/gtonkinhill/panaroo)), and Mash distance estimation ([`MashTree`](https://github.com/lskatz/mashtree)). It produces an interactive HTML report for each cluster with trees, pangenome profile, and distance matrices.

CorGe+ automatically generates a PoODLE-compatible manifest for every selected threshold. The required columns are:

```
sample,fastq_1,fastq_2,gff,assembly,cluster_id,species,reference
```

The FASTQ and GFF fields are left empty by default, but CorGe+ can fill them automatically if you provide a **PHoeNIx** directory (`--phoenix_path`), a **Bactopia** results directory (`--bactopia_path`), or a CSV with paths via `--master_paths`.

For each cluster, CorGe+ selects a reference genome based on the "best" assembly quality (fewest contigs, longest length, and alphabetical tie-break).


---

### 🧬 Microreact export

CorGe+ generates a `.microreact` file that brings together **two complementary genetic perspectives**:

* **Mashtree** — produces a k-mer–based distance tree that reflects overall genome composition, including accessory genes.
* **Core-genome distance tree** — prepared by ReporTree with the MSTreeV2 method, it's useful for visualizing genetic relatedness among isolates.

By integrating both views, Microreact provides an intuitive way to explore how samples group at the thresholds defined with `--thresholds`, and helps you decide which group threshold to use in downstream high-resolution analyses.

To aid interpretation, Microreact also displays **heatmaps per threshold**, using the ReporTree **partition nomenclature**.
Each partition corresponds to a hierarchical clustering level and includes the method, numeric threshold, and distance unit. For example, threshold **15** corresponds to the partition `single-15x1.0`.

To visualize, upload the `.microreact` file to [`Microreact/upload`](https://microreact.org/upload)

### ![Microreact example](docs/images/corge_microreact_example.png)

> [!TIP]  
> You can also explore groups interactively by uploading the ReporTree files `.nwk` and `metadata_w_partitions.tsv` or `partitions.tsv` to [`GrapeTree`](https://github.com/achtman-lab/GrapeTree), [`SPREAD`](https://github.com/genpat-it/spread) or [`Auspice`](https://auspice.us/). These tools run entirely in your browser for quick and private visualization.

---

## 🧭 Best practices & caveats

* **Use high-quality assemblies:** Ideally, assemblies should have **<500 contigs ≥500 bp**, **≥30× Illumina coverage**, and **no contamination**.

* **Interpret CorGe+ results as *screening*:** Use the output to identify candidate related isolates, but confirm relatedness with more granular analysis within an identified genomic context group (e.g., Snippy, Panaroo, Gubbins, Mashtree).

* **Parsnp-specific guidance:**
  * Prefer **≥5 samples** to obtain meaningful alignments.
  * Treat SNP distances as inflated; use **higher SNP thresholds** (~150 SNPs) when evaluating potential linkages.

* **Disk cleanup:** After the pipeline completes, you may safely remove the Nextflow `work/` directory to reclaim space.

* **Sample names:** Use unique sample names across all runs (both historical and new). If a sample name is reused, CorGe+ will overwrite the previous results for that sample with the most recent analysis.

---

## 🛠 Troubleshooting

* **No clusters at a threshold**: Increase the value in `--thresholds`.

* **Different group IDs across runs**: Expected when using **Parsnp**, because reference choice and sample composition affect cluster boundaries. For **stable and reproducible** group IDs, prefer cgMLST.

* **Using a cgMLST schema for a species after using Parsnp**
  If samples were previously analyzed with Parsnp and you later obtain a cgMLST schema, **re-run all samples using cgMLST** for consistency.
  Rename or remove the old species subdirectory that was analyzed with Parsnp in your `outdir` to prevent conflicts when the pipeline checks for prior results.

---

## 📊 Output overview

Results are structured by **species** inside `<outdir>/<Species>/`.
Each folder includes:

* **cgMLST** or **Parsnp** results
* **Linkage analysis** CSVs
* **Genomic context group** tables per threshold
* **MashTree** files
* **Microreact** project file (`*.microreact`)
* **ReporTree** distance and cluster files
* **PoODLE** manifests


Detailed outputs can be found in the [`corge_outputs.md`](docs/corge_outputs.md) file.

---

## 💬 Citations

If you use CorGe+, please cite:

* ChewBBACA — cgMLST calling
* ReporTree — hierarchical clustering
* Mashtree — composition-based tree
* Parsnp — core alignment
* Microreact — visualization platform
* cgmlst.org —  cgMLST server
* nf-core — bioinformatics pipeline framework
* NextFlow — computational workflow
* Software packaging/containerization tools

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

---

## Credits & Community

CorGe+ was built and is maintained by the Genomics Analysis Unit at the Michigan Department of Health & Human Services (MDHHS). This pipeline was developed by [Karla Vasco](https://github.com/vascokarla) and [Douglas Maldonado-Torres](https://github.com/MTDouglas).

📢 Contributions, issues, and pull requests are welcome — help make bacterial surveillance reproducible and accessible for everyone!

---

## 📜 License

This project is released under the **MIT License**.









