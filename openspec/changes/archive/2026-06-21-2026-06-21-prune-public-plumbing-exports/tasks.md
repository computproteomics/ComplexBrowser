## 1. API Review

- [ ] 1.1 Identify helpers that are only internal plumbing.
- [ ] 1.2 Confirm workflow entry points remain exported.

## 2. Export Pruning

- [ ] 2.1 Remove export tags from internal-only helpers.
- [ ] 2.2 Update `NAMESPACE` and generated help pages.
- [ ] 2.3 Replace any vignette or test call sites that relied on removed exports.

## 3. Validation

- [ ] 3.1 Regenerate documentation.
- [ ] 3.2 Run package tests and check that Shiny and CLI still work.
