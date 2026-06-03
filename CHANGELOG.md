# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-06-03

### Added

- Added synthetic SNDS data generation functionalities
  - New `synthetic_data.R` with functions to download and manage synthetic datasets
  - New `synthetic_data_avc.R` with 721 lines of AVC (stroke) case study synthetic data
- Added `extract_drug_erucdf()` function to extract drugs from `er_ucd_f` table
- Added CCAM parameter to `extract_hospital_consultations()` to filter consultations by CCAM medical procedures
- Added vignette `tutoriel_avc.Rmd` - Complete stroke study tutorial
- Added vignette `benchmark_sndstools_vs_r.Rmd` - Performance comparison between sndsTools and base R

### Changed

- Simplified and improved the "prise en main" (getting started) vignette
- Moved `connexion` parameter to last position in all functions for API consistency
- Changed constants from `constants()` function to direct variable exports

### Fixed

- Fixed `extract_drug_dispenses()` bug when no drug_filter is specified
- Fixed `extract_hospital_stays()` to allow null diagnostic filters
- Added validation to ensure `output_table_name` is in uppercase (#89)
- Corrected broken links in README (#88)
- Better parameter harmonization across extraction functions

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
