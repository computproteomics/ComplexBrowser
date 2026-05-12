# ComplexBrowser

ComplexBrowser is an R/Shiny application and R package for supervised
proteomics analysis focused on protein complexes.

The original application is described in the manuscript:
<https://doi.org/10.1074/mcp.TIR119.001434>

The current development version keeps the Shiny app, but also exposes reusable R
functions and a small command-line interface for non-interactive workflows.

## Current Entry Points

- Shiny app: `inst/shiny/ui.R`, `inst/shiny/server.R`, and `inst/shiny/Global.R`
- R package APIs: `R/`
- Shiny-only plotting helpers: `inst/shiny/R/`
- Shiny app assets, report template, and bundled example input: `inst/shiny/`
- Bundled prepared databases: `inst/extdata/`
- Reusable example input files for R/CLI workflows: `inst/extdata/examples/`
- Historical source data and old database snapshots: `data-raw/legacy/`
- Package workflow vignettes: `vignettes/`
- Command-line wrapper script: `exec/complexbrowser`
- OpenSpec behavior documents: `openspec/specs/`

## Installation

From the repository root:

```r
install.packages(".", repos = NULL, type = "source")
```

For development without installation:

```r
pkgload::load_all(".")
```

The package name is lower-case:

```r
library(complexbrowser)
```

## Running the Shiny App

From the repository checkout:

```r
shiny::runApp("inst/shiny")
```

After installing the package:

```r
complexbrowser::complexbrowser_run_app()
```

Equivalent explicit form:

```r
shiny::runApp(system.file("shiny", package = "complexbrowser"))
```

## Docker

The Docker image installs the package, then serves the packaged Shiny app from
`system.file("shiny", package = "complexbrowser")` through Shiny Server.

```bash
docker build -t complexbrowser .
docker run --rm -p 3838:3838 complexbrowser
```

The deployed app may also be available at:
<http://computproteomics.bmb.sdu.dk/Apps/ComplexBrowser>

The historical tutorial is available here:
<https://bitbucket.org/michalakw/complexbrowser/raw/dcaef828f7f0f9501c4f041391471b94acf00be1/Manual.pdf>

## R Usage

### QC/statistics

```r
library(complexbrowser)

input <- read.csv("input.csv", check.names = FALSE)

qc <- complexbrowser_run_qc(
  data = input,
  no_cond = 2,
  no_rep = 4,
  grouped = TRUE,
  log2 = FALSE,
  q_values = FALSE,
  design = "unpaired"
)

head(qc$merged_table)
```

### Complex Analysis

```r
complex <- complexbrowser_run_complex_analysis(
  stats = qc$stats,
  database = "CORUM",
  organism = "Mus musculus",
  no_cond = 2,
  no_rep = 4,
  database_name = "CORUM"
)

head(complex$display_table)
```

Bundled databases can also be loaded explicitly:

```r
corum <- complexbrowser_load_corum()
ebi <- complexbrowser_load_complex_portal()
```

Example files bundled with the installed package can be located with:

```r
system.file("extdata", "examples", "myo.csv", package = "complexbrowser")
system.file("shiny", "data", "UserDB_EXAMPLE.csv", package = "complexbrowser")
```

## Command-Line Usage

The CLI is intentionally thin: it parses arguments, reads input, calls the same
package APIs used above, and writes CSV/RDS outputs. It does not launch Shiny and
does not render plots or reports.

R packages do not normally install executables directly onto your shell `PATH`.
The most portable way to run the CLI is through `Rscript`:

```bash
Rscript -e 'status <- complexbrowser::complexbrowser_cli(commandArgs(TRUE)); quit(save="no", status=as.integer(status), runLast=FALSE)' --args qc \
  --input input.csv \
  --outdir results \
  --conditions 2 \
  --replicates 4 \
  --grouped true \
  --log2 false \
  --q-values false
```

Complex analysis from the shell:

```bash
Rscript -e 'status <- complexbrowser::complexbrowser_cli(commandArgs(TRUE)); quit(save="no", status=as.integer(status), runLast=FALSE)' --args complex \
  --input input.csv \
  --outdir results \
  --conditions 2 \
  --replicates 4 \
  --grouped true \
  --log2 false \
  --q-values false \
  --database CORUM \
  --organism "Mus musculus"
```

The package also installs the helper script under its package directory. You can
call it directly after installing the package:

```bash
"$(Rscript -e 'cat(system.file("exec", "complexbrowser", package="complexbrowser"))')" qc \
  --input input.csv \
  --outdir results \
  --conditions 2 \
  --replicates 4
```

For frequent use, create a local wrapper such as `~/bin/complexbrowser`:

```sh
#!/usr/bin/env sh
exec Rscript -e 'status <- complexbrowser::complexbrowser_cli(commandArgs(TRUE)); quit(save="no", status=as.integer(status), runLast=FALSE)' --args "$@"
```

Then make it executable:

```bash
chmod +x ~/bin/complexbrowser
```

After that, assuming `~/bin` is on your `PATH`:

```bash
complexbrowser qc --input input.csv --outdir results --conditions 2 --replicates 4
```

### CLI Outputs

`qc` writes:

- `input_statistics.csv`
- `qc_result.rds`

`complex` writes:

- `input_statistics.csv`
- `qc_result.rds`
- `complex_result.rds`
- `complex_table.csv` when matching complexes are found

No matching complexes is treated as a successful analysis result. In that case
`complex_result.rds` is written and `complex_table.csv` is omitted.

## Input Notes

- The first input column must contain protein identifiers.
- Measurement columns must match the `--conditions`, `--replicates`, and
  `--grouped` settings.
- q-value columns may be supplied, or q-values can be calculated with LIMMA.
- Complex analysis supports CORUM, EBI Complex Portal, or a user-defined
  database CSV with the expected complex columns.

## Validation

The current package has test coverage for:

- QC fixture parity
- complex-analysis fixture parity
- bundled database accessors
- CSV/RDS exports
- CLI QC and complex-analysis smoke tests
- Shiny smoke tests for core workflows

Typical local checks:

```bash
Rscript -e 'pkgload::load_all(".", quiet=TRUE); testthat::test_dir("tests/testthat", reporter="summary")'
R CMD build --no-build-vignettes .
R CMD check --no-manual --no-build-vignettes complexbrowser_*.tar.gz
openspec validate --specs --strict --no-interactive
```

## Current Limitations

- The CLI covers tabular QC and complex-analysis outputs, not Shiny-only
  interactive plots.
- The QC PDF report remains part of the Shiny workflow.
- The shell convenience command requires either the installed package script path
  or a user-created wrapper.

## Legacy Links

Historical released versions:
<https://bitbucket.org/michalakw/complexbrowser/downloads/?tab=tags>

Historical source downloads:
<https://bitbucket.org/michalakw/complexbrowser/downloads/?tab=downloads>
