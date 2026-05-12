## ADDED Requirements

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
