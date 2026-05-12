## ADDED Requirements

### Requirement: Shiny QC Uses Package API

The Shiny QC workflow SHALL use the extracted package QC functions while preserving current user-visible behavior.

#### Scenario: Uploaded file QC after extraction

- **GIVEN** a valid uploaded CSV or text file
- **AND** the user selects the same QC settings as before extraction
- **WHEN** the user runs QC in Shiny
- **THEN** the rendered statistics table SHALL contain the same rows, columns, identifiers, and display values as the pre-refactor Shiny workflow

#### Scenario: Invalid uploaded file after extraction

- **GIVEN** an uploaded file with an incorrect separator or duplicated protein identifiers
- **WHEN** the user runs the same Shiny input workflow after extraction
- **THEN** the app SHALL display the same error category as the pre-refactor workflow
- **AND** QC processing SHALL NOT continue for that input

### Requirement: QC Fixture Coverage

The system SHALL include regression fixtures for representative QC outputs before QC logic is moved out of Shiny-facing files.

#### Scenario: Fixture comparison

- **GIVEN** the bundled example data and fixed QC settings
- **WHEN** tests run after a QC extraction step
- **THEN** fixture comparisons SHALL verify merged statistics, q-values, fold changes, ratios, and condition-level statistics

### Requirement: Normalization Compatibility

Extracted QC functions SHALL preserve existing normalization behavior.

#### Scenario: Normalized statistics after extraction

- **GIVEN** QC data loaded with the same normalization method as before extraction
- **WHEN** normalized statistics are recalculated through the package API
- **THEN** the normalized merged statistics table SHALL match the pre-refactor normalized table within 0.1% relative tolerance for unrounded numeric values
