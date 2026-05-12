# Complex Analysis Specification

## Purpose

Define how ComplexBrowser matches quantified proteins to protein complex databases and presents complex-level analysis.
## Requirements
### Requirement: Database Selection

The system SHALL analyze protein complexes using CORUM, EBI Complex Portal, or a user-defined complex database.

#### Scenario: CORUM database

- GIVEN the user selects CORUM
- WHEN the analysis controls render
- THEN the app SHALL offer species choices from the prepared CORUM database

#### Scenario: EBI Complex Portal database

- GIVEN the user selects EBI Complex Portal
- WHEN the analysis controls render
- THEN the app SHALL offer species choices from the prepared EBI Complex Portal database

#### Scenario: User-defined database

- GIVEN the user selects User defined database
- WHEN the analysis controls render
- THEN the app SHALL request a user database file
- AND the database SHALL contain complex identifiers, complex names, organism labels, semicolon-separated subunits, GO terms, and comments

### Requirement: Complex Matching

The system SHALL match input protein identifiers against the selected database subunits for the selected species.

#### Scenario: Matching complexes found

- GIVEN QC statistics are available
- AND the selected database contains complexes with at least one quantified subunit
- WHEN the user runs analysis
- THEN the app SHALL display a complex table
- AND include the number of quantified subunits and coverage for each displayed complex

#### Scenario: No matching complexes

- GIVEN QC statistics are available
- AND the selected database contains no complexes with quantified subunits for the selected species
- WHEN the user runs analysis
- THEN the app SHALL display a warning table indicating that no complexes were found

### Requirement: Complex-Level Thresholds

The system SHALL apply user-selected fold-change, q-value, and noise thresholds to complex visualizations and summaries.

#### Scenario: Statistical threshold enabled

- GIVEN the statistical threshold control is enabled
- WHEN the user runs analysis or views complex plots
- THEN the selected q-value threshold SHALL be used to classify significant regulation

#### Scenario: Statistical threshold disabled

- GIVEN the statistical threshold control is disabled
- WHEN the user runs analysis or views complex plots
- THEN q-values SHALL NOT restrict significance for visualization

### Requirement: Complex Visualizations

The system SHALL provide interactive complex-level visualizations for a selected complex when enough quantified subunits are available.

#### Scenario: Complex graph

- GIVEN a complex table row is selected
- AND statistics are available for the selected complex
- WHEN the complex graph renders
- THEN the app SHALL display an interactive force-network graph for the selected condition

#### Scenario: Subunit expression profiles

- GIVEN a selected complex has more than one quantified subunit
- WHEN the subunit expression profile renders
- THEN the app SHALL display a line plot using either log2 intensity or z-score scale

#### Scenario: Protein expression barplot

- GIVEN the user clicks a quantified protein in the complex graph
- WHEN the protein expression panel renders
- THEN the app SHALL display a protein expression barplot
- AND show fold-change and q-value tables for that protein

#### Scenario: Co-expression plot

- GIVEN a selected complex has more than two quantified subunits
- WHEN the user selects two conditions for co-expression analysis
- THEN the app SHALL display a complex correlation plot for those conditions

#### Scenario: Heatmaps

- GIVEN a selected complex has at least two quantified subunits
- WHEN heatmap controls are selected
- THEN the app SHALL display a protein expression heatmap and a protein correlation heatmap
- AND use the selected distance, linkage, and correlation controls where applicable

### Requirement: Complex Summaries

The system SHALL summarize regulated complexes using selected fold-change and noise thresholds.

#### Scenario: Summary barplot

- GIVEN complex-level FARMS-derived summaries are available
- WHEN the Summary tab renders
- THEN the app SHALL display a barplot of regulated complexes using the selected thresholds

#### Scenario: Top changing complexes

- GIVEN complex-level summaries are available
- WHEN the user selects a summary condition
- THEN the app SHALL display a top up/down table and textual summary for that condition

### Requirement: External CoExpresso Submission

The system SHALL allow CoExpresso submission only for human complex analyses.

#### Scenario: Human species selected

- GIVEN the selected species is Human or Homo sapiens
- WHEN complex analysis results are available
- THEN CoExpresso submission controls SHALL be enabled

#### Scenario: Non-human species selected

- GIVEN the selected species is not Human or Homo sapiens
- WHEN complex analysis results are available
- THEN CoExpresso submission controls SHALL be disabled

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

