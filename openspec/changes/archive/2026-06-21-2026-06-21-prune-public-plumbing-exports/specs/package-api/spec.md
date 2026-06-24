## ADDED Requirements

### Requirement: Internal Plumbing Helpers

The system SHALL keep file-naming, file-writing, and QC report-preparation helpers unexported when those helpers are only needed by package internals, Shiny wiring, CLI wiring, tests, or vignettes.

#### Scenario: Package internals keep working

- **GIVEN** unexported plumbing helpers
- **WHEN** Shiny, CLI, tests, or vignettes call the package workflow entry points
- **THEN** the workflows SHALL still complete successfully
