## ADDED Requirements

### Requirement: R CMD Check Diagnostics

The package SHALL maintain a reproducible R package check with no
package-owned warnings or notes.

#### Scenario: Package-owned diagnostics are fixed

- **GIVEN** the package source tree
- **WHEN** `R CMD build` and `R CMD check --no-manual` run in an environment
  with required system and R dependencies available
- **THEN** the check SHALL complete without package-owned warnings or notes
- **AND** package examples, tests, and vignettes SHALL still run

#### Scenario: Environment-owned diagnostics are documented

- **GIVEN** a check diagnostic caused by network access, unavailable external
  repositories, missing system tools, or local permissions
- **WHEN** the diagnostic cannot be fixed by changing package source
- **THEN** the diagnostic SHALL be documented with its cause and reproduction
  condition
- **AND** it SHALL NOT be hidden by weakening package validation
