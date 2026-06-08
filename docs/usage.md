# 🚀 Pipeline Usage

This guide explains how to run **CorGe+**, prepare inputs, and understand common workflows.

For full parameter details, see 👉 [`parameters.md`](parameters.md)

---

## 🧭 How CorGe+ works

CorGe+ is designed for **incremental genomic surveillance**:

1. Download or create cgMLST schemas (once per species)
2. Prepare a sample manifest
3. Run the pipeline
4. Results are added to a **growing database** (`--outdir`)
5. (Optional) regroup, generate a phylogenetic tree or remove specific samples later

**Method selection is automatic:**

* cgMLST → used when a schema is available (**preferred**)
* Parsnp → used as fallback

---

## ⚡ Quick Start

```bash
# 1. Download schemas
nextflow run MDHHS-Bioinformatics/corge \
  --mode download_schema \
  --schema_ids s20 \
  --outdir corge_results \
  -profile apptainer

# 2. Run analysis
nextflow run MDHHS-Bioinformatics/corge \
  --input manifest.csv \
  --cgmlst_schemas corge_results/cgmlst_schemas/cgmlst_schemas.csv \
  --outdir corge_results \
  -profile apptainer
```

>[!NOTE]
>This command clones (download) this repo to `~/.nextflow/assets/MDHHS-Bioinformatics/corge`. You can download the pipeline in a different location using `git clone https://github.com/MDHHS-Bioinformatics/corge.git`. To run the pipeline, specify the path to the cloned repository (e.g. `nextflow run /path/to/corge ...`).

---

## ⚠️ Important notes

* Use **unique sample names** across runs
* Do **not run multiple jobs on the same cgMLST schema** simultaneously. By default, ChewBBACA adds new alleles to a cgMLST schema while it runs. If multiple jobs use the **same schema directory**, they may interfere with each other and cause problems with how new alleles are named.
* Parsnp results may vary across runs because they depend on assembly quality and on a core genome that changes with dataset composition.
* The `--outdir` acts as a **growing database**

---

## 1️⃣ Requirements

Install:

* [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (≥ 22.10.1)
* One container runtime:
  * [`Docker`](https://docs.docker.com/engine/installation/) (recommended for local runs)
  * [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/)
  * [`Apptainer`](https://apptainer.org/docs/user/latest/) (recommended for HPC)


> [!NOTE]  
> If using **Singularity** set `NXF_SINGULARITY_CACHEDIR` (or `singularity.cacheDir`) to reuse images later. For example: 
> ```bash
> export NXF_SINGULARITY_CACHEDIR="/path/to/singularity_cache"
> ``````
>
> If using **Apptainer** set `NXF_APPTAINER_CACHEDIR` (or `apptainer.cacheDir`) to reuse images later. For example: 
> ```bash
> export NXF_APPTAINER_CACHEDIR="/path/to/apptainer_cache"
> ``````
---

## 2️⃣ Get cgMLST schemas
CorGe+ can help you either download cgMLST schemas from [`cgmlst.org`](https://cgmlst.org/) or create cgMLST schemas with [`ChewBBACA`](https://github.com/B-UMMI/chewBBACA).

### Download cgMLST schemas
Schemas are required for cgMLST analysis and only need to be downloaded once.

```bash
nextflow run MDHHS-Bioinformatics/corge \
  --mode download_schema \
  --schema_ids s1,s20 \
  --outdir corge_results \
  -profile apptainer
```

<details>
<summary><b>Click here to check cgMLST schema IDs</b></summary>

| id  | schema_name                                                     |
|-----|------------------------------------------------------------------|
| s1  | Acinetobacter_baumannii                                          |
| s2  | Bacillus_anthracis                                               |
| s3  | Bordetella_pertussis                                             |
| s4  | Brucella_melitensis                                              |
| s5  | Brucella_spp                                                     |
| s6  | Burkholderia_mallei_FLI                                          |
| s7  | Burkholderia_mallei_RKI                                          |
| s8  | Burkholderia_pseudomallei                                        |
| s9  | Campylobacter_jejuni_coli                                        |
| s10 | Citrobacter_freundii                                             |
| s11 | Citrobacter_freundii_portucalensis_braakii_europaeus             |
| s12 | Clostridioides_difficile                                         |
| s13 | Clostridium_perfringens                                          |
| s14 | Corynebacterium_diphtheriae                                      |
| s15 | Corynebacterium_pseudotuberculosis                               |
| s16 | Cronobacter_sakazakii_malonaticus                                |
| s17 | Enterobacter_hormaechei                                          |
| s18 | Enterococcus_faecalis                                            |
| s19 | Enterococcus_faecium                                             |
| s20 | Escherichia_coli                                                 |
| s21 | Francisella_tularensis                                           |
| s22 | Klebsiella_oxytoca_grimontii_michiganensis_pasteurii             |
| s23 | Klebsiella_pneumoniae_variicola_quasipneumoniae                  |
| s24 | Legionella_pneumophila                                           |
| s25 | Listeria_monocytogenes                                           |
| s26 | Morganella_morganii                                              |
| s27 | Mycobacterium_tuberculosis_bovis_africanum_canettii              |
| s28 | Mycobacteroides_abscessus                                        |
| s29 | Mycoplasma_gallisepticum                                         |
| s30 | Paenibacillus_larvae                                             |
| s31 | Proteus_mirabilis                                                |
| s32 | Providencia_stuartii                                             |
| s33 | Pseudomonas_aeruginosa                                           |
| s34 | Salmonella_enterica                                              |
| s35 | Serratia_marcescens                                              |
| s36 | Staphylococcus_argenteus                                         |
| s37 | Staphylococcus_aureus                                            |
| s38 | Staphylococcus_capitis                                           |
| s39 | Streptococcus_pyogenes                                           |
| s40 | Yersinia_enterocolitica                                          |

</details>


<details>
<summary><b>Check species supported by the cgMLST schemas</b></summary>

| species                      | schema                                                              |
|-----------------------------|---------------------------------------------------------------------|
| Acinetobacter_baumannii     | Acinetobacter_baumannii_cgMLST                                      |
| Bacillus_anthracis          | Bacillus_anthracis_cgMLST                                           |
| Bordetella_pertussis        | Bordetella_pertussis_cgMLST                                         |
| Brucella_melitensis         | Brucella_melitensis_cgMLST                                          |
| Brucella_abortus            | Brucella_spp_cgMLST                                                 |
| Brucella_canis              | Brucella_spp_cgMLST                                                 |
| Brucella_ceti               | Brucella_spp_cgMLST                                                 |
| Brucella_inopinata          | Brucella_spp_cgMLST                                                 |
| Brucella_melitensis         | Brucella_spp_cgMLST                                                 |
| Brucella_microti            | Brucella_spp_cgMLST                                                 |
| Brucella_neotomae           | Brucella_spp_cgMLST                                                 |
| Brucella_ovis               | Brucella_spp_cgMLST                                                 |
| Brucella_pinnipedialis      | Brucella_spp_cgMLST                                                 |
| Brucella_suis               | Brucella_spp_cgMLST                                                 |
| Burkholderia_mallei         | Burkholderia_mallei_FLI_cgMLST                                      |
| Burkholderia_mallei         | Burkholderia_mallei_RKI_cgMLST                                      |
| Burkholderia_pseudomallei   | Burkholderia_pseudomallei_cgMLST                                    |
| Campylobacter_coli          | Campylobacter_jejuni_coli_cgMLST                                    |
| Campylobacter_jejuni        | Campylobacter_jejuni_coli_cgMLST                                    |
| Citrobacter_freundii        | Citrobacter_freundii_cgMLST                                         |
| Citrobacter_braakii         | Citrobacter_freundii_portucalensis_braakii_europaeus_cgMLST         |
| Citrobacter_europaeus       | Citrobacter_freundii_portucalensis_braakii_europaeus_cgMLST         |
| Citrobacter_freundii        | Citrobacter_freundii_portucalensis_braakii_europaeus_cgMLST         |
| Citrobacter_portucalensis   | Citrobacter_freundii_portucalensis_braakii_europaeus_cgMLST         |
| Clostridioides_difficile    | Clostridioides_difficile_cgMLST                                     |
| Clostridium_perfringens     | Clostridium_perfringens_cgMLST                                      |
| Corynebacterium_diphtheriae | Corynebacterium_diphtheriae_cgMLST                                  |
| Corynebacterium_pseudotuberculosis | Corynebacterium_pseudotuberculosis_cgMLST                   |
| Cronobacter_malonaticus     | Cronobacter_sakazakii_malonaticus_cgMLST                            |
| Cronobacter_sakazakii       | Cronobacter_sakazakii_malonaticus_cgMLST                            |
| Enterobacter_hormaechei     | Enterobacter_hormaechei_cgMLST                                      |
| Enterococcus_faecalis       | Enterococcus_faecalis_cgMLST                                        |
| Enterococcus_faecium        | Enterococcus_faecium_cgMLST                                         |
| Escherichia_albertii        | Escherichia_coli_cgMLST                                             |
| Escherichia_coli            | Escherichia_coli_cgMLST                                             |
| Escherichia_fergusonii      | Escherichia_coli_cgMLST                                             |
| Escherichia_marmotae        | Escherichia_coli_cgMLST                                             |
| Escherichia_ruysiae         | Escherichia_coli_cgMLST                                             |
| Shigella_boydii             | Escherichia_coli_cgMLST                                             |
| Shigella_dysenteriae        | Escherichia_coli_cgMLST                                             |
| Shigella_flexneri           | Escherichia_coli_cgMLST                                             |
| Shigella_sonnei             | Escherichia_coli_cgMLST                                             |
| Francisella_tularensis      | Francisella_tularensis_cgMLST                                       |
| Klebsiella_grimontii        | Klebsiella_oxytoca_grimontii_michiganensis_pasteurii_cgMLST         |
| Klebsiella_michiganensis    | Klebsiella_oxytoca_grimontii_michiganensis_pasteurii_cgMLST         |
| Klebsiella_oxytoca          | Klebsiella_oxytoca_grimontii_michiganensis_pasteurii_cgMLST         |
| Klebsiella_pasteurii        | Klebsiella_oxytoca_grimontii_michiganensis_pasteurii_cgMLST         |
| Klebsiella_pneumoniae       | Klebsiella_pneumoniae_variicola_quasipneumoniae_cgMLST              |
| Klebsiella_quasipneumoniae  | Klebsiella_pneumoniae_variicola_quasipneumoniae_cgMLST              |
| Klebsiella_variicola        | Klebsiella_pneumoniae_variicola_quasipneumoniae_cgMLST              |
| Legionella_pneumophila      | Legionella_pneumophila_cgMLST                                       |
| Listeria_monocytogenes      | Listeria_monocytogenes_cgMLST                                       |
| Morganella_morganii         | Morganella_morganii_cgMLST                                          |
| Mycobacterium_africanum     | Mycobacterium_tuberculosis_bovis_africanum_canettii_cgMLST          |
| Mycobacterium_bovis         | Mycobacterium_tuberculosis_bovis_africanum_canettii_cgMLST          |
| Mycobacterium_canettii      | Mycobacterium_tuberculosis_bovis_africanum_canettii_cgMLST          |
| Mycobacterium_tuberculosis  | Mycobacterium_tuberculosis_bovis_africanum_canettii_cgMLST          |
| Mycobacteroides_abscessus   | Mycobacteroides_abscessus_cgMLST                                    |
| Mycoplasma_gallisepticum    | Mycoplasma_gallisepticum_cgMLST                                     |
| Paenibacillus_larvae        | Paenibacillus_larvae_cgMLST                                         |
| Proteus_mirabilis           | Proteus_mirabilis_cgMLST                                            |
| Providencia_stuartii        | Providencia_stuartii_cgMLST                                         |
| Pseudomonas_aeruginosa      | Pseudomonas_aeruginosa_cgMLST                                       |
| Salmonella_bongori          | Salmonella_enterica_cgMLST                                          |
| Salmonella_enterica         | Salmonella_enterica_cgMLST                                          |
| Serratia_marcescens         | Serratia_marcescens_cgMLST                                          |
| Staphylococcus_argenteus    | Staphylococcus_argenteus_cgMLST                                     |
| Staphylococcus_aureus       | Staphylococcus_aureus_cgMLST                                        |
| Staphylococcus_capitis      | Staphylococcus_capitis_cgMLST                                       |
| Streptococcus_pyogenes      | Streptococcus_pyogenes_cgMLST                                       |
| Yersinia_enterocolitica     | Yersinia_enterocolitica_cgMLST                                      |

</details>

* Output file:

  ```
  <outdir>/cgmlst_schemas/cgmlst_schemas.csv
  ```

> 💡 Use this file in all downstream runs.

> The `DOWNLOAD_CGMLST_SCHEMA` step may occasionally fail with `curl` error 52 (`Empty reply from server`) when downloading schemas from `cgmlst.org`. This is usually a temporary server-side issue. Resume or re-run the pipeline after a few minutes; the step typically succeeds once the server responds again.


> [!TIP]
> After the cgMLST schemas have been successfully downloaded, the `work/` folder inside the working directory can be safely deleted.


### Create cgMLST schemas

If a cgMLST schema for your species is not available in [`cgmlst.org`](https://cgmlst.org/), CorGe+ can create a new species-specific cgMLST schema using chewBBACA.

Schema creation should be run for **one species at a time**. Provide a text file with one assembly FASTA path per line using `--assembly_sheet` (no header), and specify the target species with `--species`. For example:

For best results, use a representative set of high-quality assemblies that captures the genomic diversity of the species or lineage of interest. Complete genomes from NCBI RefSeq are preferred when available because they can reduce problems caused by incomplete or fragmented genes in draft assemblies. However, complete genomes are not always error-free, and some may contain issues such as frameshifts or poor annotations, so genome quality should still be reviewed before schema creation.

There is no strict minimum number of assemblies, but a dataset with at least ~12 distinct genotypes can be a reasonable starting point. If complete RefSeq genomes do not adequately represent the diversity of the species or lineage, high-quality draft genomes may be included.

The `--reference_path` parameter specifies the path to a representative assembly used to generate the Prodigal training file for chewBBACA. This assembly should ideally be high quality, contiguous, and representative of the dataset. 

The `--cgmlst_threshold` parameter defines the proportion of assemblies in which a locus must be present to be included in the cgMLST schema (default: `0.95`).

```bash
nextflow run MDHHS-Bioinformatics/corge \
  --mode create_schema \
  --species Vibrio_cholerae \
  --assembly_sheet /path/to/assembly_paths.txt \
  --reference_path /path/to/reference.fasta \
  --cgmlst_threshold 0.95 \
  --outdir corge_results \
  -profile apptainer
```

Example `assembly_paths.txt`:

```text
/path/to/assembly_01.fasta
/path/to/assembly_02.fna
/path/to/assembly_03.fa.gz
/path/to/assembly_04.fasta.gz
```


> [!NOTE]
> - You could also download schemas from [`Chewie-NS`](https://chewie-ns.readthedocs.io/en/latest/) or prepare an external one using [ChewBBACA](https://chewbbaca.readthedocs.io/en/latest/index.html). Once your custom schema is ready, add it to the schema's file.
> - You can still use CorGe+ without a cgMLST schema.

---

## 3️⃣ Prepare the manifest

Create a CSV file describing your samples:

```csv
sample,assembly,species
ISO1,/path/iso1.fasta,Escherichia_coli
ISO2,/path/iso2.fasta,Acinetobacter_baumannii
```

### Requirements

| Column     | Description                                             |
| ---------- | ------------------------------------------------------- |
| `sample`   | Unique sample ID                                        |
| `assembly` | Path to FASTA file (`.fasta`, `.fna`, `.fa`, `fas`, `.fasta.gz`, `.fna.gz`, `.fa.gz`, `.fas.gz`) |
| `species`  | Species name (must match `species` from schema file if cgMLST is used) |


An example samplesheet is available in [`assets/samplesheet.csv`](../assets/samplesheet.csv)

---

## 🚀 Run analyses

### 🔹 Basic run

```bash
nextflow run MDHHS-Bioinformatics/corge \
  --input manifest.csv \
  --cgmlst_schemas cgmlst_schemas.csv \
  --outdir corge_results \
  -profile apptainer
```

**What this does:**

* Runs cgMLST or Parsnp automatically
* Computes distances
* Generates groups, linkages, and reports
* Updates the existing database

### ⚙️ Optional features

These options enhance analysis and reporting and can be combined.

#### 🔹 Custom hierarchical-clustering (HC) thresholds

```bash
--hc_thresholds 5,10,20,50
```

* Comma-separated (no spaces)
* Defines clustering levels

More info below [`Choosing thresholds`](#-choosing-thresholds) 

#### 🕒 **Metadata-aware reporting**

  ReporTree can link genetic clusters with epidemiological data through summary tables showing key statistics and trends. These parameters are optional but strongly recommended when generating lineage-, time-, or metadata-based reports.

  At minimum, you can provide a metadata file like this:

  ```bash
  --metadata metadata.csv
  ```

  Example:

  ```csv
  sample,st,source,location,date
  ISO1,ST2,wound,FacilityA,2026-01-03
  ISO2,ST2,urine,FacilityA,2026-02-12
  ```

  Once metadata is included, ReporTree will enrich cluster outputs with useful summaries such as:

  - number of samples per cluster
  - distribution across locations or sources
  - temporal signals (e.g. first and last detection dates, duration of circulation)

  💡 **Going further**

  You can refine and expand these reports depending on your needs.

  For example, you might want to:

  - focus only on a subset of samples (e.g. a country or time period)
  - track specific metadata fields separately (e.g. sequence type or resistance profile)
  - explore how lineages change over time

  This can be done with options like:

  Optional:

  ```bash
  --columns_summary_report lineage,country,date
  --metadata2report st
  --filter 'country == USA;date > 2024-01-01'
  --frequency_matrix lineage,iso_week
  ```
  These allow you to:

  - customize what gets summarized per cluster
  - generate dedicated reports for key variables
  - filter your dataset before analysis
  - produce matrices for downstream visualization (e.g. lineage trends over time)



  More details about these options in [`parameters.md`](parameters.md) and [`ReporTree`](https://github.com/insapathogenomics/ReporTree?tab=readme-ov-file#usage).

#### 🌳 Phylogenetic trees (ML)

```bash
--tree
```

* Builds a **maximum-likelihood tree (GTR+G4)**
* Requires ≥3 samples
* Uses cgMLST-derived alignments when available
* More computationally intensive

#### 📦 PoODLE sample sheets
> [`PoODLE`](https://github.com/MDHHS-Bioinformatics/poodle) is a Nextflow pipeline for parallel analysis of multiple bacterial species clusters, including hqSNP calling, recombination filtering, pangenome analysis, Mash, and report generation.

CorGe+ can infer read and annotation paths based on sample IDs from PHoeNIx `--phoenix_path` or Bactopia `--bactopia_path` main output directories. Alternatively, a CSV table with explicit absolute paths to reads and annotations specified with `--master_paths` can be used. 

  Example for `--master_paths master_paths.csv`

  ```csv
  sample,fastq_1,fastq_2,annotation
  ISO1,/path/ISO1_R1.trim.fq.gz,/path/ISO1_R2.trim.fq.gz,/path/ISO1.gff
  ISO2,/path/ISO2_R1.trim.fq.gz,/path/ISO2_R2.trim.fq.gz,/path/ISO2.gff
  ```

  > If none are provided, the PoODLE samplesheets will contain empty placeholders for FASTQ and annotation paths, which you must fill in manually before running PoODLE. 

> [!NOTE]
> * Avoids manual file tracking
> * Use only **one option per run**

---

### 🔹 Advanced example
Example enabling optional analyses (phylogenetic tree and use sample metadata) and adjusting resources:

```bash
nextflow run MDHHS-Bioinformatics/corge \
  -profile apptainer \
  --input manifest.csv \
  --cgmlst_schemas cgmlst_schemas.csv \
  --outdir corge_results \
  --hc_thresholds 5,10,20,30,150 \
  --tree \
  --metadata full_lims_data.csv \
  --columns_summary_report st,source,county,date,first_seq_date,last_seq_date,timespan_days \
  --metadata2report st \
  --count_matrix st,source \
  --phoenix_path /path/to/phx_output \
  --max_memory 50.GB \
  --max_cpus 16 \
  --max_time 2.h
```

---

## 🔄 Working with existing results

### 🔁 Regroup
Recompute clusters with new HC thresholds.

The `--mode regroup` allows you to generate new clustering groups using **existing database results**. New genomic context groups, PoODLE samplesheets, and Microreact outputs will be generated with the new HC thresholds (old results are overwritten).

Specify the species to regroup using `--species`. Multiple species can be provided as a comma-separated list **without spaces**. If available, include one of the following to populate the updated PoODLE samplesheets: `--phoenix_path`, `--bactopia_path`, or `--master_paths master_paths.csv`.

```bash
nextflow run MDHHS-Bioinformatics/corge \
  --mode regroup \
  --species Escherichia_coli,Acinetobacter_baumannii \
  --outdir corge_results \
  --hc_thresholds 50,100 \
  -profile apptainer
```

---

### 🌳 Build phylogenetic trees from existing data
The `--mode tree` allows you to generate a phylogenetic tree using **existing database results**. New Microreact outputs will be generated to include the new phylogenetic tree with existing MSTreeV2 and MashTree from the database (`outdir`). A maximum-likelihood phylogenetic tree (GTR+G4) will be build from a DNA multiple-sequence alignment (MSA). When a cgMLST schema is used, the MSA is derived from the cgMLST allelic profiles. ML trees need at least 3 samples.

Specify the species to analyze using `--species`. Multiple species can be provided as a comma-separated list **without spaces**. The cgMLST schemas file is required if the previous analysis used cgMLST.

```bash
nextflow run MDHHS-Bioinformatics/corge \
  --mode tree \
  --cgmlst_schemas cgmlst_schemas.csv \
  --species Escherichia_coli,Acinetobacter_baumannii \
  --outdir corge_results \
  -profile apptainer
```

---

### 🗑️ Remove samples

The `--mode remove` helps remove samples already added to the CorGe+ database (e.g., due to contamination, mislabeling, or reanalysis)

Create a CSV file listing the samples to remove, including their corresponding species:

```csv
sample,species
ISO1,Escherichia_coli
ISO4,Acinetobacter_baumannii
```

💡 Include previous options (metadata, reporting settings) to regenerate outputs consistently.

```bash
nextflow run MDHHS-Bioinformatics/corge \
  --mode remove \
  --samples_to_remove manifest_remove.csv \
  --cgmlst_schemas cgmlst_schemas.csv \
  --outdir corge_results \
  --metadata metadata.csv \
  --columns_summary_report st,specimen_source,date,first_seq_date,last_seq_date,timespan_days \
  -profile apptainer
```

## 🧪 Common workflows

* **Add new samples** → reuse same `--outdir`
* **Independent analysis** → use new `--outdir`
* **Adjust HC thresholds** → use `--mode regroup`

---

## 🧠 Interpretation guidance

### cgMLST

* Stable and reproducible
* Works with few samples (min 2 samples)
* Preferred method
* Group names remain **stable across runs**, as CorGe+ reuses previous clustering nomenclature (`partitions.csv`).


### Parsnp

* Used as fallback
* Requires more samples (≥5 recommended)
* SNP distances may be inflated → use higher HC thresholds (~150 SNPs) when evaluating potential linkages.
* SNP-based analysis may yield less reproducible results because they depend on assembly quality and on a core genome that changes with dataset composition. Therefore, historical group nomenclature is not used by default for SNP/Parsnp analyses. To force reuse of previous clustering nomenclature, use `--use_previous_partitions_for_snp`. Note that ReporTree may take **several hours** to map prior partitions onto the new analysis.
* For SNP analyses, a practical subset of HC thresholds is calculated with ReporTree to provide detailed resolution for closely related samples (0-2000 SNPs), while still including broader population-level HC thresholds (5,000 and 10,000 SNPs). This avoids generating unnecessary partitions for every SNP threshold up to very large distances (i.e. ~200k SNPs).

---

## 🔢 Choosing HC thresholds

HC thresholds define **groups for downstream analysis** like [**PoODLE**](https://github.com/MDHHS-Bioinformatics/poodle) (hqSNPs, recombination filtering, pangenome comparisons). 

These groups are **not strict “clusters”**, since they can include contextual samples to maintain lineage-level resolution.


| Threshold | Use case                         |
| --------- | -------------------------------- |
| 15–20     | Tight clusters (high-resolution) |
| 40        | General clustering               |
| 150       | Broad lineage grouping           |

Reference HC thresholds from different sources are available at [`cgmlst_thresholds_reference.md`](cgmlst_thresholds_reference.md). 

> 💡 Ideal group size: **≥4 samples**
> If your group becomes too large, **lower the threshold** to retain only the most strongly related isolates.


> [!TIP]
> Use the [**Microreact visualization**](output.md#-microreact-visualization) to explore the dataset and decide which HC thresholds best capture meaningful relationships for your species or lineage.

---

## 📂 Outputs

```
work/           # temporary files
results/        # final outputs
.nextflow.log   # execution log
```

* You can safely delete `work/` after completion

👉 See full details: [`output.md`](output.md)

---

## ⏱️ Runtime expectations

* cgMLST → fast (minutes)
* Parsnp → slower, scales with dataset size
* `--tree` → most computationally expensive

---

## 🔁 Reproducibility

For reproducible analyses, run a specific pipeline release:

```bash
nextflow run MDHHS-Bioinformatics/corge \
  -r v1.0.0 \
  -profile apptainer \
  --input samplesheet.csv \
  --outdir corge_results \
  --cgmlst_schemas cgmlst_schemas.csv

```

Using version tags ensures the same pipeline code and container versions are used.

---

## 🔄 Updating the pipeline
Nextflow caches pipeline code locally.

To update to the latest version:

```bash
nextflow pull MDHHS-Bioinformatics/corge
```

---

## 🛠 Troubleshooting

* **No clusters** → increase `--hc_thresholds`
* **Different group IDs across runs** → expected with Parsnp
* **Switching from Parsnp to cgMLST** → remove prior results for that species and re-run all samples for consistency
* **Low-quality results** → check assembly quality. The output `linkages/<Species>_potential_linkages.csv` reports the completeness quality check.
 

---

## 🧠 Best practices

* Use high-quality assemblies (≥30× coverage, low fragmentation)
* Treat CorGe+ as **screening tool**
* Confirm results with high-resolution methods like [**PoODLE**](https://github.com/MDHHS-Bioinformatics/poodle) (hqSNPs, recombination filtering, pangenome comparisons). 
