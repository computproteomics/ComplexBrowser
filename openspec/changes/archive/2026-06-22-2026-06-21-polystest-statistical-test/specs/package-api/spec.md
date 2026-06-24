## MODIFIED Requirements

### Requirement: Stable Result Objects

The system SHALL return named result objects whose fields are stable enough for Shiny, R scripts, tests, and future command-line callers.

#### Scenario: QC result object

- **WHEN** the package QC workflow succeeds
- **THEN** the returned object SHALL include prepared input data, calculated statistics, merged display table, and workflow metadata
- **AND** the QC statistics SHALL reflect the current `PolySTest`-based implementation

### Requirement: Refactor Result Parity

The system SHALL preserve current Shiny workflow results when Shiny is rewired to package APIs, except where a later scientific-method change explicitly updates the statistical baseline.

#### Scenario: Example QC parity

- **GIVEN** the bundled example input and fixed QC settings
- **WHEN** the pre-refactor workflow and package QC workflow are compared
- **THEN** protein identifiers, column names, row counts, and rounded display values SHALL match
- **AND** unrounded numeric values SHALL match within 0.1% relative tolerance
- **EXCEPT WHEN** the statistical baseline has been intentionally changed by a later OpenSpec change

## ADDED Requirements

### Requirement: PolySTest Workflow Controls

The package SHALL expose only workflow-level QC controls for the `PolySTest`-based implementation.

#### Scenario: Public QC controls remain workflow-level

- **GIVEN** an R user, Shiny user, or CLI caller running QC
- **WHEN** the caller configures the workflow
- **THEN** the available controls SHALL remain normalization, paired versus unpaired design, and the significance threshold used by the workflow
- **AND** lower-level `PolySTest` tuning parameters SHALL remain internal defaults unless a later OpenSpec change adds a concrete user-facing need
