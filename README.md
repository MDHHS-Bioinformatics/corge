<img src="docs/images/corge_logo.png" alt="CorGe Logo" width="100" align="right"/>

# CorGe+: Core Genome plus grouping of bacteria

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![run with apptainer](https://img.shields.io/badge/run%20with-apptainer-1d355c.svg?labelColor=000000)](https://apptainer.org/docs/user/latest/)


CorGe+ is a Nextflow pipeline designed for **bacterial genomic surveillance and linkage investigation**. It performs core genome MLST (cgMLST) or core genome alignment and then identifies potential linkages between samples and clusters isolates into genomic context groups.

When the first question is *“Are these isolates related?”*, CorGe+ gives you a fast answer.

## 🔍 Designed for bacterial surveillance

CorGe+ was created to make genomic epidemiology, routine surveillance, and outbreak screening both fast and accessible. It helps you:

* 🧬 Group genomes by allelic or SNP distance using cgMLST or core-genome alignment.
* 🔗 Identify potential linkages based on allelic distances (cgMLST) or SNP distances (Parsnp).
* 📤 Export clean, shareable outputs (CSV tables + Microreact visualizations).
* 🧩 Feed selected genomic context groups into the downstream pipeline [`PoODLE`](https://github.com/MDHHS-Bioinformatics/poodle) for high-quality SNP and pangenome analyses.
* 🕒 Track related isolates over time and monitor emerging patterns.

### Multi-species and incremental analysis

CorGe+ can analyze **multiple species in a single run**.
The output directory acts as a **growing surveillance database** where new samples are automatically compared with previous ones, and group nomenclature remains stable across batches.

If you need to analyze a batch independently (e.g., without comparing to historical data), simply specify a new `--outdir` and include only the samples you want to compare in the manifest.


### ![CorGe flow](docs/images/corge_flow.png)

## Documentation for CorGe+ can be found in the [`Wiki`](wiki.md) page.


---

## Citations

If you use CorGe+, please cite:

* [`ChewBBACA`](https://github.com/B-UMMI/chewBBACA) - cgMLST calling
* [`ReporTree`](https://github.com/insapathogenomics/ReporTree) - hierarchical clustering
* [`MashTree`](https://github.com/lskatz/mashtree) - composition-based tree
* [`Parsnp`](https://github.com/marbl/parsnp) - core alignment
* [`Microreact`](https://microreact.org/) - visualization platform
* [`cgmlst.org`](https://cgmlst.org/ncs) -  cgMLST server
* [`IQ-TREE`](https://www.iqtree.org/) -  phylogeny (when `--tree` is used)
* [`snp-sites`](https://sanger-pathogens.github.io/snp-sites/) - constant sites calculation (when `--tree` is used)
* [`nf-core`](https://nf-co.re/) - bioinformatics pipeline framework
* [`NextFlow`](https://www.nextflow.io/docs/latest/index.html) - computational workflow
* Software packaging/containerization tools

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.


## Disclaimer
This repository is not a source of government records but is intended to increase collaboration and collaborative potential on public health related projects. Materials and information in this repository are intended to share information and collaboratively develop analysis workflows. 

The workflows and pipelines reflect the current understanding of the software and biological questions being answered and may be updated as needed and pursuant to further analysis and review. No warranty, expressed or implied, is made by Michigan Department of Health & Human Services (MDHHS) Bureau of Laboratories as to the functionality of the software and related material nor shall the fact of release constitute any such warranty. Furthermore, the software is released on condition that the MDHHS Bureau of Laboratories shall not be held liable for any damages resulting from its authorized or unauthorized use. 


## Privacy Notice
Use of this service is limited only to non-sensitive and publicly available data. Users must not use, share, or store any kind of sensitive data like health status, provision or payment of healthcare, Personally Identifiable Information (PII) and/or Protected Health Information (PHI), etc. under any circumstance.



## Credits

CorGe+ was built and is maintained by the Genomics Analysis Unit at the MDHHS. This pipeline was developed by [Karla Vasco](https://github.com/vascokarla) and [Douglas Maldonado-Torres](https://github.com/MTDouglas).
Contributions, issues, and pull requests are welcome!


## 📜 License

This project is released under the [**MIT License**](LICENSE).
