# MDHHS-Bioinformatics/corge: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.1 - [11/10/2026]
### Fixed

- **IQ-TREE branch support calculation:** Updated the branch support method based on the number of samples to improve compatibility and performance:
  - **4–500 samples:** Uses ultrafast bootstrap approximation (`-B 1000`).
  - **More than 500 samples:** Uses SH-aLRT branch support (`--alrt 1000`).
  - **Fewer than 4 samples:** Branch support calculations are disabled.

  This change applies only when running phylogenetic inference using `--mode tree` or the `--tree` option.

- **Parsnp partitioning and QC compatibility:** Added the `--no-partition` flag to disable automatic partitioning in Parsnp, ensuring the generation of a single `parsnpAligner.log` file required for downstream alignment coverage and quality control (QC) checks. Previously, Parsnp could partition analyses involving more than 50 samples, generating multiple log files and causing downstream QC steps to fail. This fix affects Parsnp analyses involving more than 50 samples.

## v1.0.0 - [06/25/2026]

### Added
- Initial release of CorGe+.
- Core workflow implemented.
- Documentation for usage, workflow, parameters, and outputs.
- Containerized execution using Docker/Apptainer/Singularity.
- Example samplesheet provided in `assets/`.

### Notes
- First stable release of the pipeline.
