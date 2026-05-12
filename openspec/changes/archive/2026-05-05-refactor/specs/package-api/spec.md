## ADDED Requirements

### Requirement: Package Callable Workflows

The system SHALL expose package-level R functions that run core ComplexBrowser workflows without requiring a Shiny session.

#### Scenario: Run QC workflow without Shiny

- **GIVEN** a valid quantitative proteomics input table
- **AND** condition, replicate, grouping, q-value, log2, and design settings
- **WHEN** the caller invokes the package QC workflow
- **THEN** the system SHALL return QC statistics and a merged statistics table without reading Shiny inputs or mutating Shiny state

#### Scenario: Run complex analysis without Shiny

- **GIVEN** QC statistics from the package QC workflow
- **AND** a selected complex database, species, and threshold settings
- **WHEN** the caller invokes the package complex-analysis workflow
- **THEN** the system SHALL return filtered statistics, matched complexes, complex scores, and display-ready complex tables without requiring Shiny

### Requirement: Stable Result Objects

The system SHALL return named result objects whose fields are stable enough for Shiny, R scripts, tests, and future command-line callers.

#### Scenario: QC result object

- **WHEN** the package QC workflow succeeds
- **THEN** the returned object SHALL include prepared input data, calculated statistics, merged display table, and workflow metadata

#### Scenario: Complex result object

- **WHEN** the package complex-analysis workflow succeeds
- **THEN** the returned object SHALL include filtered statistics, filtered database rows, display table, scoring summaries, selected database, selected species, and threshold metadata

### Requirement: Refactor Result Parity

The system SHALL preserve current Shiny workflow results when Shiny is rewired to package APIs.

#### Scenario: Example QC parity

- **GIVEN** the bundled example input and fixed QC settings
- **WHEN** the pre-refactor workflow and package QC workflow are compared
- **THEN** protein identifiers, column names, row counts, and rounded display values SHALL match
- **AND** unrounded numeric values SHALL match within 0.1% relative tolerance

#### Scenario: Example complex-analysis parity

- **GIVEN** the bundled example input, fixed database selection, fixed species, and fixed thresholds
- **WHEN** the pre-refactor workflow and package complex-analysis workflow are compared
- **THEN** matched complex identifiers, display table columns, coverage values, scores, and summary outputs SHALL match within 0.1% relative tolerance for unrounded numeric values

### Requirement: Explicit Error Handling

The system SHALL report invalid package API inputs with explicit errors instead of Shiny-only validation side effects.

#### Scenario: Missing input file

- **WHEN** a package workflow is called with a missing file path
- **THEN** the system SHALL return or raise an error that identifies the missing path

#### Scenario: Invalid workflow parameters

- **WHEN** a package workflow is called with unsupported condition, replicate, database, species, threshold, or design settings
- **THEN** the system SHALL return or raise an error that identifies the invalid parameter

### Requirement: Side-Effect Boundaries

Core package computation functions SHALL be free of implicit UI, filesystem, and global-state side effects.

#### Scenario: Pure computation call

- **WHEN** a caller runs a computation function with in-memory data and parameters
- **THEN** the function SHALL return its result without writing files, updating Shiny controls, or changing global application state

#### Scenario: Explicit export call

- **WHEN** a caller invokes an export or report function with an output path
- **THEN** filesystem writes SHALL be limited to the requested output artifact and documented temporary files

### Requirement: Package Database Assets

The system SHALL provide prepared database assets from the `complexbrowser` package instead of relying on repository-root RDS paths.

#### Scenario: Load bundled CORUM database

- **WHEN** a caller requests the bundled CORUM database through the package API
- **THEN** the system SHALL load the prepared CORUM RDS asset from package-managed data paths
- **AND** the loaded database content SHALL match the pre-refactor prepared CORUM database content

#### Scenario: Load bundled EBI Complex Portal database

- **WHEN** a caller requests the bundled EBI Complex Portal database through the package API
- **THEN** the system SHALL load the prepared EBI Complex Portal RDS asset from package-managed data paths
- **AND** the loaded database content SHALL match the pre-refactor prepared EBI Complex Portal database content
