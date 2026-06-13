# Phase 92: Docs, Claims, Release Hygiene - Context

**Gathered:** 2026-06-13
**Status:** Ready for research
**Source:** Phase 92 roadmap scope, completed Phase 89-91 artifacts, and current docs/release scan

<domain>

## Phase Boundary

Phase 92 closes v2.7 by making public documentation, support claims, HexDocs/package behavior, and release workflow posture match the features that actually shipped in Phases 89-91.

This is not a new engine feature phase. It should explain and mechanically guard:

- `page_numbering: [restart: true]`
- `{{section_page_number}}` / `{{section_total_pages}}`
- `only_on: :odd | :even` for physical-page duplex running content
- pinned PDF.js advisory observations without GUI-viewer support promotion
- global text shaping remaining demand-gated, not silently renamed as v2.7 scope

</domain>

<decisions>

## Implementation Decisions

### Documentation Surface

- Prefer targeted updates to existing public docs over adding many new guides.
- `guides/page_primitive.md` is the right home for page context, section-local numbering, duplex running content, and explicit TOC/outline/anchor/chart boundaries.
- `guides/recipes.md` may reference these primitives only where they improve report/statement ergonomics; avoid duplicating the full primitive guide.
- `guides/api_stability.md` remains the canonical support-boundary guide for support matrix and viewer claims.
- `README.md` should stay concise and point to guides rather than becoming a reference manual.

### Support Matrix And Claims

- Add or update support matrix rows only for feature claims that are public and backed by tests.
- Do not add a PDF.js support row or promote any existing `pdfjs` viewer deferral row.
- If a top-level PDF.js advisory section is added, it must avoid support vocabulary and stay distinct from viewer support rows; otherwise keep Phase 91 observations outside the support matrix and rely on docs-contract tests.
- Named deferrals must include TOC/outlines/anchors/cross-references, charts, global text shaping, PDF.js GUI support, and full release automation.

### Release / HexDocs Hygiene

- Current scan found `ADOPTION.md` linked from README and scripts, but `mix.exs` package files do not include `ADOPTION.md`; `mix ci` emits ExDoc warnings for missing `ADOPTION.md`. Phase 92 should fix this if feasible.
- `hexdocs.yml` already sets `permissions: contents: read` and SHA-pins checkout/setup-beam. `ci.yml` and `release.yml` currently do not set top-level permissions; harden to least-privilege if compatible.
- Avoid introducing release-please or full release automation; the milestone explicitly defers it.
- Existing exact-tag release preflight and required-check guardrails should stay intact.

### Changelog / Public Versioning

- If Phase 92 changes public docs/support matrix/release workflow posture, add a concise `[Unreleased]` changelog entry.
- Do not imply these v2.7 docs are already available in the current Hex release until package/docs evidence proves they are included.

</decisions>

<canonical_refs>

## Canonical References

Downstream agents MUST read these before planning or implementing.

### Phase Scope

- `.planning/ROADMAP.md` - Phase 92 deliverables and exit criteria.
- `.planning/REQUIREMENTS.md` - DOC-01, DOC-02, DOC-03.
- `.planning/PROJECT.md` - v2.7 decisions and demand-gated shaping posture.
- `.planning/phases/89-page-context-primitive/89-01-SUMMARY.md`
- `.planning/phases/90-duplex-running-content/90-01-SUMMARY.md`
- `.planning/phases/91-pdf-js-advisory-proof-lane/91-01-SUMMARY.md`
- `.planning/phases/91-pdf-js-advisory-proof-lane/91-VERIFICATION.md`

### Public Docs And Claims

- `README.md`
- `guides/page_primitive.md`
- `guides/recipes.md`
- `guides/api_stability.md`
- `guides/comparison.md`
- `guides/viewer_evidence.md`
- `ADOPTION.md`
- `CHANGELOG.md`
- `priv/support_matrix.json`
- `test/docs_contract/`
- `scripts/verify_docs.exs`

### Release / Workflow Guardrails

- `mix.exs`
- `.github/workflows/ci.yml`
- `.github/workflows/hexdocs.yml`
- `.github/workflows/release.yml`
- `priv/guardrails/required_status_checks.json`
- `test/guardrails/required_checks_contract_test.exs`
- `scripts/release_preflight_proof.exs`
- `test/scripts/release_preflight_proof_test.exs`
- `scripts/verify_public_launch_urls.sh`

</canonical_refs>

<specifics>

## Specific Ideas

- Extend `guides/page_primitive.md` with:
  - section-local numbering example using `Rendro.section(page_numbering: [restart: true])`
  - section tokens `{{section_page_number}}` / `{{section_total_pages}}`
  - duplex example using footer sections with `only_on: :odd` and `only_on: :even`
  - clear unsupported boundaries for TOC/outlines/anchors/cross-references, charts, and global text shaping
- Add support matrix rows/fields for `section_page_numbering` and `duplex_running_content` only if the schema permits non-viewer top-level support rows and docs-contract tests can bind them to existing tests.
- Add docs-contract checks for page-context and duplex public copy.
- Add docs-contract checks that PDF.js advisory wording remains narrow and linked to `priv/pdfjs_observations/` rather than support promotion.
- Include `ADOPTION.md` in Hex package files and optionally ExDoc extras if that resolves public link warnings without over-expanding docs.
- Add top-level `permissions: contents: read` to `.github/workflows/ci.yml` and `.github/workflows/release.yml` if GitHub Actions semantics allow all current jobs to keep working.

</specifics>

<deferred>

## Deferred Ideas

- Public `Rendro.PageContext` struct or callback API.
- Full visual TOC, PDF outlines, anchors, and cross-references.
- Charts / `%Rendro.Chart{}`.
- Global text shaping and broad script support.
- PDF.js GUI support, browser rendering backend, or support-matrix promotion.
- release-please / full release automation.

</deferred>

---

*Phase: 92-docs-claims-release-hygiene*
*Context gathered: 2026-06-13 after Phase 91 closeout*

