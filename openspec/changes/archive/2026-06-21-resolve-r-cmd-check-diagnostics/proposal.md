## Why

The package refactor should finish with a reproducible R package check that has
no package-owned warnings or notes. A reported check run still has 4 warnings
and 2 notes that need to be identified, classified, and removed where they are
caused by the package.

## What Changes

- Capture the exact check log that reports the 4 warnings and 2 notes.
- Classify each diagnostic as package-owned or environment-owned.
- Fix package-owned diagnostics with the smallest possible changes.
- Document any environment-owned diagnostics and the command/environment needed
  to reproduce a clean package check.

## Compatibility

- Public R APIs, CLI arguments, Shiny behavior, bundled examples, and database
  contents should not change unless a diagnostic proves they are invalid.

## Non-Goals

- Do not rewrite package structure or scientific calculations.
- Do not hide real package problems with broad ignore rules.
- Do not treat sandbox network warnings as package failures.
