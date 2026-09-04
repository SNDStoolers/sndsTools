# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a
Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## \[0.3.1\] - 2026-09-04

Contributors : Matthieu Doutreligne

- More efficient version of
  [`extract_drugs_erphaf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drugs_erphaf.md)
  exploiting the index on `PHA_CIP_C13` to accelerate the filtering of
  the drugs by CIP code. (#128)

## \[0.3.0\] - 2026-09-02

Contributors : Léa Aguilhon, Léopold Maurice, Marc Dibbling, Louisicm,
Ben Fournier, Victor Bret, Matthieu Doutreligne

### Added

- Added
  [`extract_deaths()`](https://sndstoolers.github.io/sndsTools/reference/extract_deaths.md)
  (#112) - extracts, for each death within a date range, the ICD-10
  codes associated with the death (one row per code) from the medical
  cause-of-death tables `KI_CCI_R` (initial cause) and `KI_ECD_R` (other
  causes); a `STATUS` column distinguishes the initial cause
  (`"Initial cause"`) from the other codes (`"Other"`).
- Added notebook `notebooks/demo_death.R` - self-contained demo of
  [`extract_deaths()`](https://sndstoolers.github.io/sndsTools/reference/extract_deaths.md)
  (in-memory DuckDB + fictitious data).
- Added
  [`extract_stays_ssr()`](https://sndstoolers.github.io/sndsTools/reference/extract_stays_ssr.md) -
  extracts SSR (soins de réadaptation) stays diagnostics.
- Added `extract_ij_erprfs()` - extracts daily indemnity (Indemnité
  Journalières) data from the `er_prfs` table. Built as an indicator
  (`extract_indicateurs`) function on top of
  `extract_consultations_erprsf`.

### Changed

- **MAJOR** Every extract function now returns either a lazy table or
  save it to oracle table, depending on output_table_name parameter. If
  output_table_name is NULL, the function returns a lazy table,
  otherwise it saves the result to oracle table and returns NULL. (#124)
- Declared `tibble` in `Suggests` (used by the
  [`extract_deaths()`](https://sndstoolers.github.io/sndsTools/reference/extract_deaths.md)
  tests via
  [`tibble::tribble()`](https://tibble.tidyverse.org/reference/tribble.html)).
- Documentation generated with roxygen2 8.0.0; removed `quarto` from
  `VignetteBuilder` (unblocks `make check` and `make site`).

### Fixed

- [`extract_stays_mcob()`](https://sndstoolers.github.io/sndsTools/reference/extract_stays_mcob.md):
  write the temporary patient-ids table with `overwrite = TRUE` and
  remove it at the end of the function, avoiding collisions and leftover
  temporary tables on repeated calls.
- The oracle SNDS tables are read with
  [`tbl_oracle()`](https://sndstoolers.github.io/sndsTools/reference/tbl_oracle.md)
  (#126), which add to the table names the user profile (`PROFIL_XXX`),
  guessed from its Oracle ID. The table connexion (after 2025) without
  the schema declaration ware broken due to an update on the servers
  (“modifications ADGP”).

## \[0.2.2\] - 2026-06-03

### Added

- Added synthetic SNDS data generation functionalities
  - New `synthetic_data.R` with functions to download and manage
    synthetic datasets
  - New `synthetic_data_avc.R` with 721 lines of AVC (stroke) case study
    synthetic data
- Added
  [`extract_drugs_erucdf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drugs_erucdf.md)
  function to extract drugs from `er_ucd_f` table
- Added CCAM parameter to
  [`extract_consultations_mcofcstc()`](https://sndstoolers.github.io/sndsTools/reference/extract_consultations_mcofcstc.md)
  to filter consultations by CCAM medical procedures
- Added vignette `tutoriel_avc.Rmd` - Complete stroke study tutorial
- Added vignette `benchmark_sndstools_vs_r.Rmd` - Performance comparison
  between sndsTools and base R
- Added to vignette `contribuer.Rmd` API conventions

### Changed

- Simplified and improved the “prise en main” (getting started) vignette
- Moved `connexion` parameter to last position in all functions for API
  consistency
- Changed constants from `constants()` function to direct variable
  exports
- Renamed all extraction functions to be consistent with the API naming
  convention

### Fixed

- Fixed
  [`extract_drugs_erphaf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drugs_erphaf.md)
  bug when no drug_filter is specified
- Fixed
  [`extract_stays_mcob()`](https://sndstoolers.github.io/sndsTools/reference/extract_stays_mcob.md)
  to allow null diagnostic filters
- Added validation to ensure `output_table_name` is in uppercase (#89)
- Corrected broken links in README (#88)
- Better parameter harmonization across extraction functions
- Fixed get_kwikly_format broken by removed reference on documentation
  snds website

### Removed

- Removed unused R man files from git tracking (now auto-generated)
- Excluded synthetic data from codecov coverage reports

## \[0.1.2\] - 2026-02-10

### Added

- Documentation: added new instructions to get back the sndsTools.R file

## \[0.1.0\] - 2026-02-10

### Added

- Initial release of SndsTools
- Core extraction functions for SNDS data
- Basic documentation and vignettes
