# ![Corge](docs/images/corge_workflow.png)



[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)



## Introduction

<!-- TODO nf-core: Write a 1-2 sentence summary of what data the pipeline is for and what it does -->

**Corgeplus** is a bioinformatics best-practice analysis pipeline for Core genome clustering using a core genome MLST.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. Where possible, these processes have been submitted to and installed from [nf-core/modules](https://github.com/nf-core/modules) in order to make them available to all nf-core pipelines, and to everyone within the Nextflow community!

<!-- TODO nf-core: Add full-sized test dataset and amend the paragraph below if applicable -->

On release, automated continuous integration tests run the pipeline on a full-sized dataset on the AWS cloud infrastructure. This ensures that the pipeline runs on AWS, has sensible resource allocation defaults set to run on real-world datasets, and permits the persistent storage of results to benchmark between pipeline releases and other analysis sources.The results obtained from the full-sized test can be viewed on the [nf-core website](https://nf-co.re/corgeplus/results).

## Pipeline summary

<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->

1. Verification of CGMLST scheme avaiability for each sample
2. Perform core genome analysis with either cgMLST scheme (['chewBBACA'](https://chewbbaca.readthedocs.io/en/latest/index.html)) or core genome alignment if there is no scheme avaiable (['Parsnp'](https://github.com/marbl/parsnp))
3. Hierarchical clustering (['ReporTree'](https://github.com/insapathogenomics/ReporTree))
4. Create linkage table
5. Cluster selection
6. Generate Microract file to visalize results (tbd)

## Quick Start

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=22.10.1`)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) (you can follow [this tutorial](https://singularity-tutorial.github.io/01-installation/)), [`Podman`](https://podman.io/), [`Shifter`](https://nersc.gitlab.io/development/shifter/how-to-use/) or [`Charliecloud`](https://hpc.github.io/charliecloud/) for full pipeline reproducibility _(you can use [`Conda`](https://conda.io/miniconda.html) both to install Nextflow itself and also to manage software within pipelines. Please only use it within pipelines as a last resort; see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))_.

3. Download the pipeline and test it on a minimal dataset with a single command:

   ```bash
   nextflow run nf-core/corgeplus -profile test,YOURPROFILE --outdir <OUTDIR>
   ```

   Note that some form of configuration will be needed so that Nextflow knows how to fetch the required software. This is usually done in the form of a config profile (`YOURPROFILE` in the example command above). You can chain multiple config profiles in a comma-separated string.

   > - The pipeline comes with config profiles called `docker`, `singularity`, `podman`, `shifter`, `charliecloud` and `conda` which instruct the pipeline to use the named tool for software management. For example, `-profile test,docker`.
   > - Please check [nf-core/configs](https://github.com/nf-core/configs#documentation) to see if a custom config file to run nf-core pipelines already exists for your Institute. If so, you can simply use `-profile <institute>` in your command. This will enable either `docker` or `singularity` and set the appropriate execution settings for your local compute environment.
   > - If you are using `singularity`, please use the [`nf-core download`](https://nf-co.re/tools/#downloading-pipelines-for-offline-use) command to download images first, before running the pipeline. Setting the [`NXF_SINGULARITY_CACHEDIR` or `singularity.cacheDir`](https://www.nextflow.io/docs/latest/singularity.html?#singularity-docker-hub) Nextflow options enables you to store and re-use the images from a central location for future pipeline runs.
   > - If you are using `conda`, it is highly recommended to use the [`NXF_CONDA_CACHEDIR` or `conda.cacheDir`](https://www.nextflow.io/docs/latest/conda.html) settings to store the environments in a central location for future pipeline runs.

4. Prepare manifest files
Currently, the pipeline requires three different input csv files. The assemblies manifest, the reads manifest, and the master manifest.

### Assemblies manifest
Create a csv file containing paths to the GFFs, assemblies, and species

The following columns are **mandatory**:
- `sample`
- `gff`
- `assembly`
- `species`

### Reads manifest
Create a csv file containing paths to the reads used to generate the assemblies in the assemblies manifest. Should have the same samples as the assemblies manifest.
The following columns are **mandatory**:
- `sample`
- `fastq_1`
- `fastq_2`

### Master manifest
Create a csv file containing any legacy samples that have been previously analyzed. The following columns are **mandatory**:
- `sample`
- `fastq_1`
- `fastq_2`
- `gff`
- `assembly`
- `species`
- `scaffolds_over_500bp_count`

   <!-- TODO nf-core: Update the example "typical command" below used to run the pipeline -->

5. Start running your own analysis
   ```bash
   nextflow run main.nf --input manifest_assemblies.csv --outdir <OUTDIR> \
   --schema_dir <PATH_TO_SCHEMAS> --previous_results <BASE_PATH_TO_PREVIOUS_RESULTS> \
   --previous_results_inner_dir <PATH_TO_PREVIOUS_RESULTS> --master_manifest master_manifest.csv \
   --lims lims_data.csv --reads_manifest manifest_reads.csv \
   -profile <docker/singularity/podman/shifter/charliecloud/conda/institute>

   ```

## Inpuut/Output Options
- `--input` [string] Path to a csv file containing information about the samples, specifically the gff, assembly, and species (mandatory).
- `--outdir`  [string] The output directory where the results will be saved. You must use absolute paths for storage on Cloud infrastructure (mandatory).
- `--schema_dir` [string] Path to where your schemas are located. This directory should contain a directory named after each species you hope to use a schema for cgMLST. If no schema is avaiable for a given species, analysis will default to using Parsnp instead of chewBBACA. (optional)
- `--previous_results` [string] Path to where previous results are located. Directories located in this path should have the same species names as the species names in your samplesheet if you plan to use these previous results. Used when seeking to use chewBBACA (optional)
- `--previous_results_inner_dir` [string] Used in conjunction with --previous_results. Uses the base path of --previous_results and the current sample species, to form the complete path to the previous 'results_alleles.tsv' (mandatory if --previous_results used)
- `--master_manifest` [string] Path to a csv file containing information about previous samples (mandatory).
- `--reads_manifest` [string] Path to a csv file containing read information for the newest samples being analyzed (mandatory).
- `--lims` [string] Path to a lims csv file (mandatory)

## Credits

Corge was originally written by MDHHS Genomics Analysis Unit with Karla Vasco and Douglas Maldonado-Torres as main mainteiners.





## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use  nf-core/corgeplus for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
