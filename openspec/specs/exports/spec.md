# Exports and Reports Specification

## Purpose

Define user-visible table, figure, and report export behavior for ComplexBrowser.
## Requirements
### Requirement: Statistics Table Export

The system SHALL provide a CSV export for calculated input statistics after QC processing succeeds.

#### Scenario: Download calculated statistics

- GIVEN QC statistics have been calculated
- WHEN the user downloads the input statistics table
- THEN the app SHALL return a CSV file containing the merged calculated statistics
- AND the filename SHALL identify the export as `MSComplexR_Input_WithStats`

### Requirement: Complex Table Export

The system SHALL provide a CSV export for complex analysis results after matching complexes are available.

#### Scenario: Download complex table

- GIVEN complex analysis has produced a display table
- WHEN the user downloads the complex table
- THEN the app SHALL return a CSV file containing the displayed complex analysis results
- AND the filename SHALL identify the export as `ProteinComplexesTable`

### Requirement: Quality-Control Report Export

The system SHALL provide a downloadable quality-control report after statistics are available.

#### Scenario: Download QC report

- GIVEN QC statistics have been calculated
- WHEN the user downloads the QC report
- THEN the app SHALL render `QCreport.rmd` with the current QC data
- AND return the rendered report as the download artifact

### Requirement: Figure Export Controls

The system SHALL provide figure-specific PDF downloads for rendered QC and complex-analysis plots.

#### Scenario: Download plot with dimensions

- GIVEN a plot has rendered
- AND the plot download UI includes width and height controls
- WHEN the user downloads the plot
- THEN the app SHALL render the current interactive plot to a PDF using the selected dimensions
- AND reset the width and height controls to their defaults after download

#### Scenario: Download complex graph

- GIVEN the complex graph has rendered
- WHEN the user downloads the complex graph
- THEN the app SHALL render the graph to a PDF download

### Requirement: Export Availability

The system SHALL only show export controls when the corresponding data or plot is available.

#### Scenario: Data-dependent download

- GIVEN the app has not yet calculated or rendered the data required for an export
- WHEN the page renders
- THEN the corresponding download control SHALL remain unavailable

#### Scenario: Rendered plot download

- GIVEN a plot has rendered successfully
- WHEN the plot-specific download UI renders
- THEN the corresponding download control SHALL be available

### Requirement: Export Content Compatibility

Existing Shiny downloads SHALL preserve their filenames, formats, and data content when exports are routed through package result objects.

#### Scenario: Statistics table export after extraction

- **GIVEN** QC statistics have been calculated after package extraction
- **WHEN** the user downloads the input statistics table
- **THEN** the CSV filename prefix, columns, row order, and cell values SHALL match the pre-refactor Shiny export

#### Scenario: Complex table export after extraction

- **GIVEN** complex analysis results are available after package extraction
- **WHEN** the user downloads the complex table
- **THEN** the CSV filename prefix, columns, row order, and cell values SHALL match the pre-refactor Shiny export

### Requirement: Report Data Compatibility

The QC report SHALL continue to render from the same QC data content after QC extraction.

#### Scenario: QC report after extraction

- **GIVEN** QC statistics have been calculated after package extraction
- **WHEN** the user downloads the QC report
- **THEN** the report input data SHALL match the pre-refactor report input data
- **AND** the report render SHALL complete successfully

### Requirement: Figure Download Availability Compatibility

Figure download controls SHALL remain available under the same Shiny workflow states after extraction.

#### Scenario: Plot download control after extraction

- **GIVEN** a QC or complex-analysis plot has rendered after extraction
- **WHEN** the page renders the plot-specific download UI
- **THEN** the corresponding download control SHALL be available under the same conditions as before extraction

