## Design

Use the current package check as the gate:

```bash
R CMD build .
R CMD check --no-manual /tmp/complexbrowser_*.tar.gz
```

The captured 4-warning/2-note log came from checking the repository directory
directly instead of a source archive. That check included local/project files
such as `.Rhistory`, `.Rproj.user`, `.git`, `.github`, `.vscode`, `..Rcheck`,
`Dockerfile~`, OpenSpec internals, and unbuilt vignette sources. The supported
package validation path is build first, then check the tarball.

Expected diagnostic buckets:

- Build metadata: RDS serialization version, stale build artifacts, generated
  vignette files.
- Package metadata: missing dependencies, top-level files, hidden files,
  executable permissions.
- Documentation: Rd usage/example mismatches, missing aliases, vignette
  dependency declarations.
- Test/runtime: warnings emitted by examples, tests, or vignettes.
- Environment: unavailable CRAN index, missing system tools, local-only
  permissions.

## Code Structure

Prefer metadata fixes over code changes. If code changes are needed, keep them
at the smallest caller boundary that emits the diagnostic. Do not add helper
layers only for check cleanup.

## Validation

- Full `R CMD build`.
- Full `R CMD check --no-manual`.
- `openspec validate --specs --strict --no-interactive`.
