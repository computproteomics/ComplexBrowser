## ADDED Requirements

### Requirement: Shiny Complex Analysis Uses Package API

The Shiny complex-analysis workflow SHALL use extracted package functions while preserving current user-visible complex-analysis behavior.

#### Scenario: Complex table after extraction

- **GIVEN** QC statistics are available
- **AND** the user selects the same database, species, q-value threshold, fold-change threshold, and noise threshold as before extraction
- **WHEN** the user runs complex analysis in Shiny
- **THEN** the rendered complex table SHALL contain the same complex identifiers, complex names, quantified subunit counts, coverage values, and score columns as the pre-refactor Shiny workflow

#### Scenario: No-match behavior after extraction

- **GIVEN** QC statistics are available
- **AND** the selected database and species contain no complexes with quantified subunits
- **WHEN** the user runs complex analysis in Shiny
- **THEN** the app SHALL display the same no-complexes-found warning behavior as the pre-refactor Shiny workflow

### Requirement: Complex Analysis Fixture Coverage

The system SHALL include regression fixtures for representative complex-analysis outputs before complex-analysis logic is moved out of Shiny-facing files.

#### Scenario: Complex fixture comparison

- **GIVEN** fixed example data, database selection, species, and thresholds
- **WHEN** tests run after a complex-analysis extraction step
- **THEN** fixture comparisons SHALL verify matched complex rows, coverage values, complex scores, summary outputs, and top up/down table content

### Requirement: Packaged Database Loading Compatibility

The Shiny complex-analysis workflow SHALL load bundled prepared databases through package database accessors after the RDS files move to `inst/extdata`.

#### Scenario: CORUM database after asset move

- **GIVEN** the prepared CORUM RDS file has moved to package-managed data paths
- **WHEN** the Shiny app offers CORUM species and runs CORUM complex analysis
- **THEN** species choices and complex-analysis results SHALL match the pre-refactor root-file behavior

#### Scenario: EBI Complex Portal database after asset move

- **GIVEN** the prepared EBI Complex Portal RDS file has moved to package-managed data paths
- **WHEN** the Shiny app offers EBI Complex Portal species and runs EBI Complex Portal complex analysis
- **THEN** species choices and complex-analysis results SHALL match the pre-refactor root-file behavior

### Requirement: Human CoExpresso Availability Compatibility

Extracted complex-analysis functions SHALL preserve the Shiny rules for enabling CoExpresso submission.

#### Scenario: Human species after extraction

- **GIVEN** the selected species is Human or Homo sapiens
- **WHEN** complex analysis results are available after extraction
- **THEN** the Shiny app SHALL enable CoExpresso submission controls

#### Scenario: Non-human species after extraction

- **GIVEN** the selected species is not Human or Homo sapiens
- **WHEN** complex analysis results are available after extraction
- **THEN** the Shiny app SHALL disable CoExpresso submission controls
