---
phase: 80-stability-contract-migration-docs
reviewed: 2026-05-30T00:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - guides/api_stability.md
  - guides/upgrading_to_1.0.md
  - guides/viewer_evidence.md
  - mix.exs
  - scripts/verify_docs.exs
  - test/docs_contract/api_stability_claims_test.exs
  - test/docs_contract/embedded_artifact_claims_test.exs
  - test/docs_contract/protection_claims_test.exs
  - test/docs_contract/signing_claims_test.exs
  - test/docs_contract/viewer_evidence_claims_test.exs
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 80: Code Review Report

**Reviewed:** 2026-05-30
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Phase 80 adds `guides/api_stability.md` (rewritten), `guides/upgrading_to_1.0.md` (new), `test/docs_contract/api_stability_claims_test.exs` (new), and lockstep edits to the sibling claims tests plus `mix.exs` ExDoc wiring and `scripts/verify_docs.exs` lane registration.

The new claims test is structurally sound: false-pass guards via `Code.ensure_loaded?` and `function_exported?` are correctly applied, `struct(Rendro.Artifact)` is safe at runtime (the `@enforce_keys` check is compile-time only), `Rendro.Inspector` is correctly absent from all Tier-1 assertions, and the lane self-registration string matches the actual entry in `verify_docs.exs` exactly. The `mix.exs` ExDoc wiring is consistent — all three new `Policies` extras are present in both `extras:` and `groups_for_extras:` with no orphan entries.

Four issues require attention before shipping, none blocking CI today but two of them will confuse adopters or cause broken links on HexDocs.

---

## Warnings

### WR-01: Internal plan/decision labels survive in public guide `viewer_evidence.md`

**File:** `guides/viewer_evidence.md:167`, `guides/viewer_evidence.md:273`, `guides/viewer_evidence.md:315`

**Issue:** Three internal references remain in the public guide that ships in the Hex package (`guides/` is declared in `package/files`):

- Line 167: `(see plan 69-03)` — internal phase plan reference.
- Line 273: `(D-15)` — internal decision label in the SURFACE_EQUIVALENCE template prose.
- Line 315: `(D-09/D-10)` — internal decision labels in the `validate --strict` table row.

`guides/upgrading_to_1.0.md` (line 33) states "Internal milestone labels are scrubbed from public guides." That claim is now contradicted by these three surviving references in the same public guides bundle. Adopters reading the recorded evidence recipe will encounter opaque internal labels with no resolution path.

**Fix:** Remove the parenthetical references or replace them with self-contained prose. Examples:

- Line 167: remove `(see plan 69-03)` — the surrounding sentence is self-explanatory without it.
- Line 273: change `(D-15)` to a brief inline note, e.g., "— this is the standard signing-preparation inheritance pattern".
- Line 315: change `(D-09/D-10)` to a brief note, e.g., "— advisory only; staleness gate is intentionally non-blocking".

---

### WR-02: `guides/upgrading_to_1.0.md` contains a broken CHANGELOG link

**File:** `guides/upgrading_to_1.0.md:43`

**Issue:** The guide ends with:

```
For full change history, see [CHANGELOG.md](../CHANGELOG.md).
```

`CHANGELOG.md` is not present in `mix.exs`'s `extras:` list, so ExDoc never renders it as a navigable page. The `../CHANGELOG.md` relative path resolves to nothing on HexDocs — it produces a dead link for every adopter who clicks it. `guides/upgrading_to_1.0.md` is also absent from `skip_undefined_reference_warnings_on`, so ExDoc ~0.40 will emit a reference warning during `mix docs` (which runs as part of `mix ci`).

**Fix:** Either add `CHANGELOG.md` to the `extras:` list in `mix.exs` (and optionally to a group), or replace the link with plain prose:

Option A — add to extras (preferred):
```elixir
extras: [
  "README.md",
  "CHANGELOG.md",          # add here
  "guides/integrations.md",
  ...
]
```

Option B — remove the link and substitute plain text:
```markdown
For full change history, see `CHANGELOG.md` in the repository root.
```

---

### WR-03: `mix.exs` version is `0.3.1` but public guides claim `as of 1.0.0`; no CHANGELOG entry for Phase 80

**File:** `mix.exs:4`, `guides/api_stability.md:57`, `guides/upgrading_to_1.0.md:1`

**Issue:** `mix.exs` declares `@version "0.3.1"` and `CHANGELOG.md` shows `[0.3.1] - Unreleased`. Both public guides reference 1.0.0 as the current/target release (`_None as of 1.0.0_` in the Deprecations table; "Upgrading to 1.0" as the guide title; multiple "1.0.0 release" references in the What's New section). When `0.3.1` is published to Hex, adopters will see "Upgrading to 1.0" documentation on a `0.3.1` package — a confusing mismatch.

Separately, `CHANGELOG.md` has no entry for Phase 80's changes: the rewritten `guides/api_stability.md`, new `guides/upgrading_to_1.0.md`, new `test/docs_contract/api_stability_claims_test.exs`, and ExDoc wiring. The Viewer Evidence and CHANGELOG Discipline section of `guides/api_stability.md` (lines 59–63) states that public-contract changes require CHANGELOG entries. A full rewrite of the stability guide and a new upgrade guide are public-contract changes under that policy.

**Fix:** Either:
- Bump `mix.exs` `@version` to `"1.0.0"` and add a `## [1.0.0]` CHANGELOG section describing Phase 80 additions before publishing; or
- If 1.0.0 is intentionally deferred, update the Deprecations table sentinel row to `_None as of 0.3.1_` (and the test assertion on line 21 of `api_stability_claims_test.exs`), and add a CHANGELOG entry under `[0.3.1]` describing the stability-contract documentation additions.

---

### WR-04: `viewer_evidence_claims_test.exs` test name "prior seven" is stale after Phase 80 adds an eighth post-viewer-evidence lane

**File:** `test/docs_contract/viewer_evidence_claims_test.exs:285`

**Issue:** The test is named `"verify_docs.exs retains the prior seven docs-contract lanes"`. When this test was written, the viewer evidence lane was lane #8 and there were exactly seven prior lanes. After Phase 80 adds the `"API stability claims lane"` as lane #12, there are now eleven lanes before the script ends — the description `"prior seven"` is factually wrong and will mislead future maintainers. The assertions themselves are still correct (they check by substring, not count), but the test name creates a false audit trail about the guarded count.

**Fix:** Rename the test to reflect the actual assertion intent:

```elixir
test "verify_docs.exs retains the original seven core docs-contract lanes" do
```

or more durably:

```elixir
test "verify_docs.exs retains the seven lanes registered before the viewer evidence lane" do
```

---

## Info

### IN-01: `## Per-Surface Support Boundaries` is an empty section with no body content

**File:** `guides/api_stability.md:65–66`

**Issue:** Lines 65–66 contain only:

```markdown
## Per-Surface Support Boundaries

## Interactive Forms Support Boundary
```

The section has no introductory text. All sub-surface sections (`Interactive Forms`, `Signing Preparation`, etc.) are `##` siblings, not `###` children, so ExDoc renders them as flat peers with no parent paragraph. The `guides/upgrading_to_1.0.md` cross-reference (line 37) points readers to this section, but clicking the ToC entry shows only the bare heading before the next section appears. This is functional but unhelpful as an adoption anchor.

**Fix:** Add a one- or two-sentence introduction between the two headers, e.g.:

```markdown
## Per-Surface Support Boundaries

Each surface below documents its supported authoring API, proof lane, and viewer posture.
Structural proof (pdfinfo/Poppler) is never sufficient for viewer promotion — recorded
evidence is required.

## Interactive Forms Support Boundary
```

---

### IN-02: `upgrading_to_1.0.md` cross-references a section header using backtick code syntax instead of a navigable link

**File:** `guides/upgrading_to_1.0.md:37`

**Issue:**

```markdown
see the `## Per-Surface Support Boundaries` section of `guides/api_stability.md`.
```

The backtick syntax renders as inline code (`## Per-Surface Support Boundaries`) rather than as a hyperlink to the section. Adopters cannot click through; they must find the section manually. ExDoc supports cross-guide section links.

**Fix:** Use an ExDoc guide cross-reference:

```markdown
see the [Per-Surface Support Boundaries](api_stability.html#per-surface-support-boundaries) section of the API Stability guide.
```

---

### IN-03: `api_stability_claims_test.exs` has no refute guard preventing future promotion of `Rendro.Inspector` to Tier-1 in the guide

**File:** `test/docs_contract/api_stability_claims_test.exs` (Category 1 test)

**Issue:** `guides/api_stability.md` correctly states `Rendro.Inspector` is "adapter-tier and not part of the Tier-1 contract." The test checks that the Tier-1 section header exists and that specific modules are loaded, but there is no `refute guide =~` guard preventing someone from accidentally promoting Inspector to the Tier-1 prose in a future edit. The category 2 test has no `Code.ensure_loaded?(Rendro.Inspector)` assertion (correctly), but the category 1 test has no negative guard either.

**Fix:** Add a targeted refute in the category 1 test to pin the adapter-tier status of Inspector:

```elixir
# Rendro.Inspector is explicitly adapter-tier — must not appear in the Tier-1 stable list
refute guide =~ "`Rendro.Inspector` is Tier-1",
       "Rendro.Inspector was promoted to Tier-1 — revert to adapter-tier classification"
```

Or more broadly, assert the guide retains its explicit exclusion sentence:

```elixir
assert guide =~
         "The implementation module (`Rendro.Inspector`) is adapter-tier and not part of the Tier-1 contract."
```

---

_Reviewed: 2026-05-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
