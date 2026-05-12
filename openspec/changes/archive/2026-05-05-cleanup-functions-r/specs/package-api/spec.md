## MODIFIED Requirements

### Requirement: Side-Effect Boundaries

Core package computation functions SHALL be free of implicit UI, filesystem, and global-state side effects, and legacy app helper files SHALL NOT be required for package API execution.

#### Scenario: Package workflows without legacy Functions file

- **WHEN** package QC, complex-analysis, export, or CLI workflows run
- **THEN** they SHALL execute without sourcing `Functions.R`
- **AND** they SHALL NOT depend on Shiny plotting helper definitions
