## Context

The package has reached the point where not every helper needs to be exported. Several functions exist only to support file naming, CSV writing, QC report preparation, or internal path handling. These are useful, but they are not necessarily part of the package contract a Bioconductor reviewer or downstream R user needs.

## Goals / Non-Goals

**Goals:**

- Reduce the exported API to the functions that are genuinely useful to callers.
- Keep the existing Shiny and CLI behavior working.
- Keep the change mechanically small.

**Non-Goals:**

- Do not rename workflow entry points.
- Do not rewrite the export logic.
- Do not change file formats or output content.

## Decisions

### 1. Prefer internal helpers for plumbing

Helpers used only by the package itself should be left unexported unless there is a clear external use case.

### 2. Keep the workflow boundaries public

Functions that represent real user actions, such as running QC or complex analysis, should remain exported.

### 3. Update docs in place

If an exported function becomes internal, remove it from `NAMESPACE` and update any examples or vignettes that depended on the export to use direct package-relative or base R alternatives.

## Risks / Trade-offs

- A helper might still be convenient for advanced users -> keep it exported only if there is a clear call-site outside the package.
- Removing exports can break downstream scripts -> accept this only for plumbing helpers, not workflow entry points.

## Migration Plan

1. Identify helpers used only internally or in package docs.
2. Remove export tags and namespace entries for those helpers.
3. Replace direct vignette/test uses if needed.
4. Regenerate docs and rerun tests.
