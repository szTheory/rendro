# Phase 122 — Deferred Items

Out-of-scope discoveries logged during execution (not fixed — not caused by this phase's changes).

| Category | Item | Detail | Discovered During |
|----------|------|--------|-------------------|
| Pre-existing test failure | `Rendro.DocsContract.DxLocalReproducibilityClaimsTest` (2 tests) | Both read `.planning/phases/113-dx-local-reproducibility-validation/113-UAT.md` and `.../reports`, planning files ABSENT from this working tree (untracked/missing — see repo git status). Unrelated to typography; fails on a clean tree independent of 122-02. | 122-02 phase-gate `mix test` |
