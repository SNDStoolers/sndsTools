# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added death extraction functions (#112):
  - `extract_idt_from_death_causes()` - extracts, for each death within a date
    range, the ICD-10 codes associated with the death (one row per code) from the
    medical cause-of-death tables `KI_CCI_R` (initial cause) and `KI_ECD_R` (other
    causes). A `STATUS` column distinguishes the initial cause from the other
    codes. Optional filtering by ICD-10 codes (prefix match).
  - `extract_death_causes_from_idt()` - from a list of patient identifiers,
    returns their cause-of-death codes and flags the patients still alive.
- Added notebook `notebooks/demo_death.R` - self-contained demo of the death
  extraction functions (in-memory DuckDB + fictitious data).

### Changed

- Death extractions are built lazily (`dbplyr`) and materialised only at the
  output boundary: when `output_table_name` is supplied the result is written
  directly in Oracle (`CREATE TABLE ... AS SELECT`) without being collected into
  R memory.
- Declared `stringr` in `Imports`.
- Documentation generated with roxygen2 8.0.0; removed `quarto` from
  `VignetteBuilder` (unblocks `make check` and `make site`).

### Fixed

- `extract_stays_mcob()`: write the temporary patient-ids table with
  `overwrite = TRUE` and remove it at the end of the function, avoiding
  collisions and leftover temporary tables on repeated calls.

## [0.2.2] - 2026-06-03

### Added

- Added synthetic SNDS data generation functionalities
  - New `synthetic_data.R` with functions to download and manage synthetic datasets
  - New `synthetic_data_avc.R` with 721 lines of AVC (stroke) case study synthetic data
- Added `extract_drugs_erucdf()` function to extract drugs from `er_ucd_f` table
- Added CCAM parameter to `extract_consultations_mcofcstc()` to filter consultations by CCAM medical procedures
- Added vignette `tutoriel_avc.Rmd` - Complete stroke study tutorial
- Added vignette `benchmark_sndstools_vs_r.Rmd` - Performance comparison between sndsTools and base R
- Added to vignette `contribuer.Rmd` API conventions

### Changed

- Simplified and improved the "prise en main" (getting started) vignette
- Moved `connexion` parameter to last position in all functions for API consistency
- Changed constants from `constants()` function to direct variable exports
- Renamed all extraction functions to be consistent with the API naming convention

### Fixed

- Fixed `extract_drugs_erphaf()` bug when no drug_filter is specified
- Fixed `extract_stays_mcob()` to allow null diagnostic filters
- Added validation to ensure `output_table_name` is in uppercase (#89)
- Corrected broken links in README (#88)
- Better parameter harmonization across extraction functions
- Fixed get_kwikly_format broken by removed reference on documentation snds website

### Removed
- Removed unused R man files from git tracking (now auto-generated)
- Excluded synthetic data from codecov coverage reports

## [0.1.2] - 2026-02-10

### Added
- Documentation: added new instructions to get back the sndsTools.R file

## [0.1.0] - 2026-02-10

### Added
- Initial release of SndsTools
- Core extraction functions for SNDS data
- Basic documentation and vignettes
