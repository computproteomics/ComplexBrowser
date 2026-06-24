## 1. Package Metadata

- [ ] 1.1 Update package versioning and Bioconductor-facing metadata.
- [ ] 1.2 Verify `DESCRIPTION`, `NAMESPACE`, and package fields are consistent with installed-package use.
- [ ] 1.3 Confirm package load/install still works after metadata changes.

## 2. Documentation

- [ ] 2.1 Complete help text for all exported functions.
- [ ] 2.2 Add short runnable examples to every exported help page.
- [ ] 2.3 Expand parameter documentation for QC, complex analysis, database selection, exports, and CLI helpers.

## 3. Vignettes

- [ ] 3.1 Keep one QC vignette and one complex-analysis vignette focused on the installed package.
- [ ] 3.2 Add `SessionInfo()` to the end of each vignette.
- [ ] 3.3 Verify both vignettes build and run from package data without root-path assumptions.

## 4. Shiny Packaging

- [ ] 4.1 Keep the app under `inst/shiny/` and verify package-relative path lookup.
- [ ] 4.2 Make the package helper launch the installed app cleanly.
- [ ] 4.3 Verify app startup, example loading, QC rendering, and complex-analysis rendering still work.

## 5. Check Hygiene

- [ ] 5.1 Remove or ignore generated artifacts, backup files, and local check directories.
- [ ] 5.2 Run `R CMD build` and `R CMD check --no-manual` on the built tarball.
- [ ] 5.3 Run `BiocCheck` and record any remaining package-owned issues.

## 6. Regression Protection

- [ ] 6.1 Keep the current QC and complex-analysis regression fixtures.
- [ ] 6.2 Verify fixed bundled examples still produce the same outputs.
- [ ] 6.3 Keep export filenames and table shapes stable.
