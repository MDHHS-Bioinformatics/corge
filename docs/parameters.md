# ⚙️ Pipeline Parameters

This page documents all parameters available for **CorGe+**.

Pipeline parameters use **double hyphens (`--`)**, while Nextflow runtime options use **single hyphens (`-`)**.

Example:

```bash
nextflow run MDHHS-Bioinformatics/corge \
  -profile apptainer \
  --input manifest.csv \
  --cgmlst_schemas cgmlst_schemas.csv \
  --outdir corge_results
```

---

## 📥 Core Pipeline Parameters

These parameters are required for most pipeline runs.

| Parameter          | Type   | Required | Default           | Description                                                 |
| ------------------ | ------ | -------- | ----------------- | ----------------------------------------------------------- |
| `--input`          | string | ✓        | –                 | Manifest CSV (`sample,assembly,species`).                   |
| `--outdir`         | string | ✓        | `./corge_results` | Output directory (acts as a growing database across runs).  |
| `--cgmlst_schemas` | string | –        | –                 | CSV mapping species to cgMLST schemas (`species,cgmlst_path`). |
| `--thresholds`     | string | ✓        | `15,20,40,150`    | Distance thresholds for grouping samples. Comma-separated (no spaces). |
| `--mode`           | string | ✓        | `default`         | Pipeline mode: `default`, `schema`, `regroup`, `remove` or `tree`. |
| `--tree`           | boolean| –        |`false`            | Build a maximum-likelihood phylogenetic tree (GTR+G4) from a DNA multiple-sequence alignment (MSA). By default, the pipeline outputs only distance-based trees (MashTree and MSTreeV2 from allele or SNP distances). Enabling this option requires substantially more computational time and resources. When a cgMLST schema is used, the MSA is derived from the cgMLST allelic profiles. Only when using modes `default` or `remove` |
| `--email`          | string | –        | –                 | Email address to receive pipeline completion notifications.  |

---

## 🧬 Analysis Options

These parameters control analysis behavior.

| Parameter              | Type    | Default | Description                                                        |
| ---------------------- | ------- | ------- | ------------------------------------------------------------------ |
| `--schema_ids`         | string  | –       | cgMLST schema IDs (required for `--mode schema`). Comma-separated (no spaces)                  |
| `--samples_to_remove`  | string  | –       | CSV of samples to remove (required for `--mode remove`, columns: `sample,species`).           |
| `--species`            | string  | –       | Species to reanalyze using prior results from `outdir` (required for `--mode regroup` or `--mode tree`).          |

---

## 📦 Read and annotation file source options (PoODLE)

Optional parameters to populate PoODLE manifests automatically.

| Parameter         | Type   | Default | Description                                       |
| ----------------- | ------ | ------- | ------------------------------------------------- |
| `--master_paths`  | string | –       | CSV with explicit absolute paths to reads and annotations (`sample,fastq_1,fastq_2,gff`). Use this when you already have all paths from the database organized in a single file. |
| `--phoenix_path`  | string | –       | Path to PHoeNIx results directory.                |
| `--bactopia_path` | string | –       | Path to Bactopia results directory.               |

> ⚠ Only one of these options should be used per run. If your data was priorly processed with [PHoeNIx](https://github.com/CDCgov/phoenix) or [Bactopia](https://bactopia.github.io/latest/), CorGe+ will infer read and annotation paths based on sample IDs. 

---

## 🌳 ReporTree Metadata Options
ReporTree can link genetic clusters with epidemiological data through summary tables showing key statistics and trends. These parameters are optional but strongly recommended when generating lineage-, time-, or metadata-based reports.


| Parameter                  | Type   | Default        | Description                                               |
| -------------------------- | ------ | -------------- | --------------------------------------------------------- |
| `--metadata`               | string | –              | Metadata table (CSV/TSV) used for reporting. Must include **all samples** (new + previous) for the species. Sample IDs in the first column must match CorGe+ names. Recommended to include a `date` column (YYYY-MM-DD) for temporal summaries.                 |
| `--columns_summary_report` | string | predefined set | Metadata columns to summarize per cluster. Supports counts (`n_country`), distributions (`country`), and-if a `date` column exists-temporal measures (first/last sample date and time span). Useful for generating cluster-level epidemiological summaries. (default: `n_sequence,lineage,n_country,country,n_region,first_seq_date,last_seq_date,timespan_days`)                |
| `--metadata2report`        | string | –              | Additional metadata columns for which **separate** summary reports should be created. Useful when tracking specific fields (e.g.,`st,source,serotype,AMR_profile`). |
| `--filter`                 | string | –              | Filter samples before analysis using expressions such as `'country == USA'` or `'country == USA;date > 2024-01-01'`. Supports multiple conditions and multiple columns. |
| `--frequency_matrix`       | string | –              | Generate frequency matrices showing the proportion of samples for variable combinations (e.g., `'lineage,iso_week'` → lineage distribution over time). Supports multiple matrices.               |
| `--count_matrix`           | string | –              | Same as `--frequency_matrix` but outputs raw counts instead of percentages. Useful for plotting absolute numbers across time or categories.                     |

More details about these options in [`ReporTree`](https://github.com/insapathogenomics/ReporTree?tab=readme-ov-file#usage).

---

## ⚙️ Execution Configuration

These parameters control compute resource limits.

| Parameter      | Type    | Default  | Description                                      |
| -------------- | ------- | -------- | ------------------------------------------------ |
| `--max_cpus`   | integer | `16`     | Maximum CPUs that can be requested by any job.   |
| `--max_memory` | string  | `128.GB` | Maximum memory that can be requested by any job. |
| `--max_time`   | string  | `24.h`   | Maximum execution time for any job.              |

---

## 🔧 Generic Pipeline Options

These parameters control pipeline behavior.

| Parameter              | Type    | Default | Description                              |
| ---------------------- | ------- | ------- | ---------------------------------------- |
| `--help`               | boolean | –       | Display help message and exit.           |
| `--version`            | boolean | –       | Print pipeline version and exit.         |
| `--validate_params`    | boolean | `true`  | Validate parameters against schema.      |
| `--show_hidden_params` | boolean | `false` | Show advanced parameters in help output. |
| `--monochrome_logs`    | boolean | `false` | Disable colored logging output.          |

---

## 🧠 Core Nextflow Arguments

These options are part of **Nextflow itself** and use a **single hyphen (`-`)**.

---

## `-profile`

Select the execution configuration profile.

Example:

```bash
-profile singularity
```

Available profiles:

| Profile       | Description                         |
| ------------- | ----------------------------------- |
| `docker`      | Run using Docker containers         |
| `apptainer`   | Run using Apptainer containers      |
| `singularity` | Run using Singularity containers    |
| `test`        | Run pipeline with bundled test data |
| `test_full`   | Run pipeline with bundled full test data |

Multiple profiles can be combined:

```bash
-profile test,singularity
```

---

## `-r` (Pipeline Release Version)

Specify the **pipeline version or Git revision** to run.

Example:

```bash
nextflow run MDHHS-Bioinformatics/corge -r v1.0.0
```

This ensures that the **exact same pipeline version** is used for analysis.

You can also run:

| Example       | Description                        |
| ------------- | ---------------------------------- |
| `-r v1.0.0`   | Run a tagged release               |
| `-r main`     | Run the latest development version |
| `-r <commit>` | Run a specific Git commit          |

⚠️ For **reproducible analyses**, it is strongly recommended to run a **tagged release**.

---

## `-resume`

Resume a previously failed or interrupted pipeline run.

```bash
-resume
```

Nextflow will reuse cached results when possible.

---

## `-c`

Provide a custom Nextflow configuration file.

```bash
-c custom.config
```

---

## 🏛 Institutional Configuration Options

These parameters are used when loading configurations from [`nf-core/configs`](https://nf-co.re/configs/).

| Parameter                      | Description                                         |
| ------------------------------ | --------------------------------------------------- |
| `--custom_config_version`      | Git commit ID for institutional configs             |
| `--custom_config_base`         | Base URL for institutional configuration repository |
| `--config_profile_name`        | Name of institutional profile                       |
| `--config_profile_description` | Description of institutional profile                |
| `--config_profile_contact`     | Contact information                                 |
| `--config_profile_url`         | Documentation URL                                   |

---

## ⚡ Custom Configuration (Advanced)

Users can override pipeline resource requirements using custom configuration files.

Example:

```nextflow
process {
    withName: ALIGNMENT {
        memory = 100.GB
        cpus = 8
    }
}
```

Run with:

```bash
nextflow run corge -c custom.config
```

---

## 🧰 Troubleshooting Resource Issues

If a job fails due to insufficient memory or CPUs, you can increase global resource limits:

```bash
--max_memory 200.GB \
--max_cpus 32 \
-resume
```
