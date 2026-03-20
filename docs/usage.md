# 🚀 Pipeline Usage

This guide explains how to run **CorGe+**, prepare inputs, and understand common workflows.

For full parameter details, see 👉 [`parameters.md`](parameters.md)

---

## 🧭 How CorGe+ works

CorGe+ is designed for **incremental genomic surveillance**:

1. Download cgMLST schemas (once per species)
2. Prepare a sample manifest
3. Run the pipeline
4. Results are added to a **growing database** (`--outdir`)
5. (Optional) regroup or refine analyses later

**Method selection is automatic:**

* cgMLST → used when a schema is available (**preferred**)
* Parsnp → used as fallback

---

## ⚡ Quick Start

```bash
# 1. Download schemas
nextflow run MDHHS-Bioinformatics/corge \
  --mode schema \
  --schema_ids s20 \
  --outdir corge_results \
  -profile apptainer

# 2. Run analysis
nextflow run MDHHS-Bioinformatics/corge \
  --input manifest.csv \
  --cgmlst_schemas corge/cgmlst_schemas/cgmlst_schemas.csv \
  --outdir corge_results \
  -profile apptainer
```

>[!NOTE]
>This command clones (download) this repo to ~/.nextflow/assets/MDHHS-Bioinformatics/corge. You can download the pipeline in a different location using `git clone https://github.com/MDHHS-Bioinformatics/corge.git`. To run the pipeline, specify the path to the cloned repository (e.g. `nextflow run /path/to/CorGe ...`).

---

## ⚠️ Important notes (read before running)

* Use **unique sample names** across runs
* Do **not run multiple jobs on the same cgMLST schema** simultaneously
* Parsnp results may vary across runs (less reproducible than cgMLST)
* The `--outdir` acts as a **persistent database**

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
> export NXF_APPTAINER_CACHEDIR="/path/to/singularity_cache"
> ``````
---

## 2️⃣ Download cgMLST schemas

Schemas are required for cgMLST analysis and only need to be downloaded once.

```bash
nextflow run MDHHS-Bioinformatics/corge \
  --mode schema \
  --schema_ids s1,s20 \
  --outdir corge_results \
  -profile apptainer
```
<details>
<summary><b>Click here to check schema IDs</b></summary>

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


* Output file:

  ```
  <outdir>/cgmlst_schemas/cgmlst_schemas.csv
  ```

> 💡 Use this file in all downstream runs.

> [!TIP]
> After the cgMLST schemas have been successfully downloaded, the `work/` folder inside the working directory can be safely deleted.


> [!NOTE]
> If a species schema is not available on [`cgmlst.org`](https://cgmlst.org/), you can still use CorGe+ without a schema.
> You could also download schemas from [`Chewie-NS`](https://chewie-ns.readthedocs.io/en/latest/), create your own schema, or prepare an external one using [ChewBBACA](https://chewbbaca.readthedocs.io/en/latest/index.html). Once your custom schema is ready, add it to the schema's file.

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
| `assembly` | Path to FASTA file (uncompressed)                       |
| `species`  | Species name (must match schema file if cgMLST is used) |

---

## ▶ Run analyses

### 🔹 Run with new samples

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

---

### 🔹 Custom thresholds

```bash
--thresholds 5,10,20,50
```

* Comma-separated (no spaces)
* Defines clustering levels

More info below [`Choosing thresholds`](#-choosing-thresholds) 

---

### 🔹 Advanced run
Example enabling optional analyses (phylogenetic tree and use sample metadata) and adjusting resources:

```bash
nextflow run MDHHS-Bioinformatics/corge \
  -profile apptainer \
  --input manifest.csv \
  --cgmlst_schemas cgmlst_schemas.csv \
  --outdir corge_results \
  --thresholds 5,10,20,30,150 \
  --tree \
  --metadata full_lims_data.csv \
  --columns_summary_report st,specimen_source,specimen_type,patient_county,submitter_name,date,first_seq_date,last_seq_date,timespan_days \
  --metadata2report st \
  --count_matrix st,specimen_source \
  --phoenix_path /path/to/phx_output \
  --max_memory 50.GB \
  --max_cpus 16 \
  --max_time 2.h
```

---

## 🧪 Common workflows

### Add new samples to an existing database

* Use the **same `--outdir`**
* Provide only new samples

---

### Analyze samples independently

* Use a **new `--outdir`**

---

### Change clustering thresholds
If you want to generate new clustering groups using **existing database results**, you can run the pipeline in `--mode regroup`. This reuses previously generated outputs and applies new distance thresholds. New genomic context groups, PoODLE samplesheets, and Microreact outputs will be generated with the new thresholds.

Specify the species to regroup using `--species_to_regroup`. The names must **exactly match** those used in the original run. Multiple species can be provided as a comma-separated list **without spaces**.

```bash
nextflow run MDHHS-Bioinformatics/corge \
  --mode regroup \
  --species_to_regroup Escherichia_Escherichia_coli,Acinetobacter_baumanniicoli \
  --outdir corge_results \
  --thresholds 50,100 \
  -profile apptainer
```

---

### Remove samples from database

If a sample has already been added to a CorGe+ database and needs to be removed (for example, due to contamination, mislabeling, or reanalysis), you can use the dedicated **`remove` mode**. _Recommended when cgMLST was used, if Parsnp was used it may affect cluster nomenclature_.

Create a CSV file listing the samples to remove, including their corresponding species:

```csv
sample,species
ISO1,Escherichia_coli
ISO4,Acinetobacter_baumannii
```

For consistency, include all the options priorly used, such as `--metadata`, `--columns_summary_report`, `--phoenix_path`, etc:

```bash
nextflow run MDHHS-Bioinformatics/corge \
  --mode remove \
  --samples_to_remove manifest_remove.csv \
  --cgmlst_schemas cgmlst_schemas.csv \
  --outdir corge \
  --metadata metadata.csv \
  --columns_summary_report st,specimen_source,date,first_seq_date,last_seq_date,timespan_days \
  -profile apptainer
```

---

## 🧭 Which method is used?

| Scenario                | Method               |
| ----------------------- | -------------------- |
| cgMLST schema available | cgMLST (recommended) |
| No schema available     | Parsnp               |

---

## 🧠 Interpretation guidance

### cgMLST

* Stable and reproducible
* Works with few samples (min 2 samples)
* Preferred method

### Parsnp

* Used as fallback
* Requires more samples (≥5 recommended)
* SNP distances may be inflated → use higher thresholds (~150 SNPs) when evaluating potential linkages.

---

## 🔢 Choosing thresholds

Thresholds define **groups for downstream analysis** like [**PoODLE**](https://github.com/MDHHS-Bioinformatics/poodle) (hqSNPs, recombination filtering, pangenome comparisons). 

These groups are **not strict “clusters”**, since they can include contextual samples to maintain lineage-level resolution.


| Threshold | Use case                         |
| --------- | -------------------------------- |
| 15–20     | Tight clusters (high-resolution) |
| 40        | General clustering               |
| 150       | Broad lineage grouping           |

Reference thresholds from different sources are available at [`cgmlst_thresholds_reference.md`](cgmlst_thresholds_reference.md). 

> 💡 Ideal group size: **≥4 samples**
> If your group becomes too large, **lower the threshold** to retain only the most strongly related isolates.


> [!TIP]
> Use the [**Microreact visualization**](#-microreact-export) to explore the dataset and decide which thresholds best capture meaningful relationships for your species or lineage.

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

* **No clusters** → increase `--thresholds`
* **Different group IDs across runs** → expected with Parsnp
* **Switching to cgMLST** → remove prior results for that species and re-run all samples for consistency
* **Low-quality results** → check assembly quality. The output `linkages/<Species>_potential_linkages.csv` reports the completeness quality check.
 

---

## 🧠 Best practices

* Use high-quality assemblies (≥30× coverage, low fragmentation)
* Treat CorGe+ as **screening tool**
* Confirm results with high-resolution methods like [**PoODLE**](https://github.com/MDHHS-Bioinformatics/poodle) (hqSNPs, recombination filtering, pangenome comparisons). 
