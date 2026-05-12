# Input and Quality Control Specification

## Purpose

Define how ComplexBrowser accepts quantitative proteomics input, prepares condition/replicate data, calculates quality-control statistics, and displays QC views.
## Requirements
### Requirement: Tabular User Input

The system SHALL accept tabular proteomics data with protein identifiers in the first column and quantitative measurement columns for all selected conditions and replicates.

#### Scenario: Valid uploaded file

- GIVEN a user selects a CSV or text file
- AND the selected separator and decimal mark match the file
- AND the first column contains unique protein identifiers
- WHEN the app reads the file
- THEN the app SHALL load the data for QC processing
- AND rows with only missing measurement values SHALL be excluded

#### Scenario: Incorrect separator

- GIVEN a user selects a file whose separator does not match the selected separator control
- WHEN the app reads the file as a single column
- THEN the app SHALL display an incorrect input format error
- AND the app SHALL direct the user to check the separator

#### Scenario: Duplicate protein identifiers

- GIVEN a user selects a file whose first column contains duplicated protein identifiers
- WHEN the app reads the file
- THEN the app SHALL display an incorrect input format error
- AND QC processing SHALL NOT continue for that input

### Requirement: Condition and Replicate Layout

The system SHALL interpret measurement columns according to the selected number of conditions, number of replicates, grouping mode, log2-transform setting, and q-value setting.

#### Scenario: Expected column count

- GIVEN a loaded input table
- AND the user has selected condition and replicate counts
- WHEN the user runs QC
- THEN the table SHALL have either `C * R + 1` columns without supplied q-values
- OR `C * (R + 1)` columns with supplied q-values

#### Scenario: Missing q-value columns

- GIVEN the user indicates q-values are included
- AND the input table only contains protein identifiers and measurement columns
- WHEN the user runs QC
- THEN the app SHALL display an error that q-value columns are missing

#### Scenario: Derived q-values

- GIVEN the user indicates q-values are not included
- WHEN the user runs QC
- THEN the app SHALL calculate q-values with the selected paired or unpaired design
- AND calculated q-value columns SHALL compare conditions 2..N against condition 1

### Requirement: Example Data Loading

The system SHALL provide a built-in example data workflow that loads the bundled T-cell dataset and prepares it for QC and complex analysis.

#### Scenario: Load example

- GIVEN the user clicks "Load example"
- WHEN the bundled example data is available
- THEN the app SHALL load the example data
- AND set conditions to 4
- AND set replicates to 2
- AND calculate statistics using an unpaired design
- AND render the calculated statistics table

### Requirement: External Data Message Loading

The system SHALL accept externally posted JSON data messages that contain expression data, design metadata, and optionally statistical values.

#### Scenario: External expression matrix

- GIVEN a browser message contains expression matrix columns with equal row counts
- AND the first expression column contains unique feature names
- WHEN the app receives the message
- THEN the app SHALL prepare the matrix using the supplied condition, replicate, grouping, and pairing metadata
- AND calculate statistics for the loaded data

#### Scenario: External statistics matrix

- GIVEN a browser message indicates that statistics are supplied
- AND the statistics matrix has the same number of rows as the expression matrix
- WHEN the app receives the message
- THEN the app SHALL append those statistics before calculating derived outputs

### Requirement: Quality-Control Statistics

The system SHALL calculate and display per-protein and per-condition statistics for QC review.

#### Scenario: Successful QC calculation

- GIVEN valid input data
- WHEN the user runs QC
- THEN the app SHALL calculate absolute intensities, log2 intensities, means, standard deviations, coefficients of variation, q-values, ratios, fold changes, log2 ratios, and z-scores
- AND display the merged statistics table as "Table 1"

#### Scenario: Normalization

- GIVEN QC statistics have been calculated
- AND the user selects a normalization technique
- WHEN the user runs normalization
- THEN the app SHALL recalculate statistics using the selected normalization technique
- AND replace the displayed statistics table with the normalized results

### Requirement: Quality-Control Visualizations

The system SHALL expose visual QC summaries after statistics are available.

#### Scenario: QC plots

- GIVEN QC statistics have been calculated
- WHEN the user views the Data input and QC tab
- THEN the app SHALL provide plots for intensity distributions, missing values, coefficient of variation, significant feature counts, volcano analysis, PCA, and sample-to-sample correlation

#### Scenario: Interactive thresholds and selectors

- GIVEN a QC plot supports a threshold, condition selector, sample selector, color selector, or correlation method selector
- WHEN the user changes the control
- THEN the app SHALL update the corresponding plot using the selected value

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

