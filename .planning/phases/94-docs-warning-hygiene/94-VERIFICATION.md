---
phase: 94-docs-warning-hygiene
verified: 2026-06-13T00:00:00Z
status: passed
score: 7/7 must-haves verified
overrides_applied: 1
overrides:
  - must_have: "priv/public_api.json is unchanged (Rendro.PDF.Font not added)"
    reason: "User-approved deviation (2026-06-13): Font.t() is already in the public Rendro.Text.Shaper.shape/3 contract; keeping Font @moduledoc false was impossible because the full-surface public_api_test forbids visible-untagged modules and skip_code_autolink_to cannot suppress typespec warnings. Font was promoted to [:stable] and added to priv/public_api.json. Documented in ROADMAP.md SC-1 and 94-01-SUMMARY post-merge correction."
    accepted_by: "user (project owner)"
    accepted_at: "2026-06-13"
---

# Phase 94: Docs & Warning Hygiene Verification Report

**Phase Goal:** A maintainer building the docs sees a clean, deliberate warning posture — `mix docs` emits zero unexplained ExDoc warnings, and the latent viewer-evidence staleness signal is self-explaining rather than mysterious.
**Verified:** 2026-06-13
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `mix docs` emits zero ExDoc warnings | VERIFIED | `mix docs 2>&1 \| grep -c "^    warning:"` → `0`; `mix docs --warnings-as-errors` → exit 0 |
| 2 | `mix docs --warnings-as-errors` exits 0 | VERIFIED | Executed live; output: "Generating docs... View html docs at doc/index.html"; EXIT_CODE: 0 |
| 3 | `mix.exs` `docs/0` contains `skip_code_autolink_to:` with all three module name strings | VERIFIED | Lines 116-119: `skip_code_autolink_to: ["Rendro.PDF.CidFont", "Rendro.PDF.FontSubsetter", "Rendro.Format"]` |
| 4 | `ci:` alias contains `"docs --warnings-as-errors"` | VERIFIED | Line 70: `"docs --warnings-as-errors",` confirmed in `aliases/0` |
| 5 | `Rendro.PDF.Font` has a real `@moduledoc` (not `@moduledoc false`) — Font promoted to `[:stable]` (user-approved deviation) | VERIFIED (override) | Lines 2-15: full `@moduledoc """..."""` with `@moduledoc tags: [:stable]`; Font in `priv/public_api.json` line 276; no `@moduledoc false` in font.ex |
| 6 | `staleness_warnings/1` message is self-explaining: contains advisory note, remediation command, and guide pointer | VERIFIED | Lines 105-108 of validator.ex: `"(advisory — non-fatal unless --strict; run mix rendro.viewer_evidence record #{cell.surface} #{cell.viewer} to re-record; see guides/viewer_evidence.md)"` |
| 7 | `guides/viewer_evidence.md` documents the staleness lifecycle | VERIFIED | Lines 196-223: "Staleness Lifecycle" section with designed-cadence explanation, late-November-2026 first-fire date, re-record instructions, advisory vs. --strict severity, and do-not-suppress guidance |

**Score:** 7/7 truths verified (1 via user-approved override)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `mix.exs` | `skip_code_autolink_to:` list + `--warnings-as-errors` in `ci:` alias | VERIFIED | Line 116: `skip_code_autolink_to:`; lines 117-119: three module strings; line 70: `"docs --warnings-as-errors"` |
| `lib/rendro/pdf/font.ex` | Real `@moduledoc` (not `@moduledoc false`) | VERIFIED | Lines 2-15: public `@moduledoc"""..."""` with `@moduledoc tags: [:stable]`; `@moduledoc false` absent |
| `lib/rendro/viewer_evidence/validator.ex` | Augmented `staleness_warnings/1` message with remediation, advisory note, guide pointer | VERIFIED | Lines 105-108: full augmented string; `@staleness_days 180` at line 11 (3 occurrences total: 1 definition + 2 usage sites) |
| `guides/viewer_evidence.md` | New staleness lifecycle section | VERIFIED | Lines 196-223 contain "Staleness Lifecycle" section covering all required content |
| `priv/public_api.json` | Regenerated to include `Rendro.PDF.Font` (user-approved deviation) | VERIFIED | Line 276: `"Elixir.Rendro.PDF.Font":` confirmed present |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `mix.exs docs/0 skip_code_autolink_to:` | ExDoc warning suppression | list of 3 module name strings | VERIFIED | `grep skip_code_autolink_to mix.exs` → line 116; `mix docs` emits 0 warnings |
| `mix.exs aliases/0 ci:` | ExDoc `--warnings-as-errors` gate | string `"docs --warnings-as-errors"` | VERIFIED | `grep '"docs --warnings-as-errors"' mix.exs` → line 70 |
| `staleness_warnings/1` message | Self-explanation for maintainer | inline advisory + remediation + guide pointer concatenated | VERIFIED | Lines 106-108 produce single runtime string with all three augmentations |
| `guides/viewer_evidence.md` lifecycle section | Maintainer reading guide after first warning fires | "Staleness Lifecycle" section heading and content | VERIFIED | Section present at lines 196-223; includes all D-07 required content |

### Data-Flow Trace (Level 4)

Not applicable — this phase modifies documentation configuration (ExDoc options in mix.exs, a warning message string, and a markdown guide). No dynamic data rendering paths introduced.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `mix docs --warnings-as-errors` exits 0 | `mix docs --warnings-as-errors; echo "EXIT_CODE: $?"` | EXIT_CODE: 0; docs generated cleanly | PASS |
| ExDoc warning count is zero | `mix docs 2>&1 \| grep -c "^    warning:"` | `0` | PASS |
| Target test suite passes (74 tests) | `mix test test/rendro/public_api_test.exs test/docs_contract/public_api_contract_test.exs test/mix/tasks/ci_alias_contract_test.exs test/guardrails/required_checks_contract_test.exs test/rendro/viewer_evidence/validator_test.exs` | 74 tests, 0 failures, EXIT_CODE: 0 | PASS |
| `@staleness_days 180` preserved | `grep "@staleness_days 180" validator.ex` | line 11 matched | PASS |
| Remediation command in validator message | `grep "mix rendro.viewer_evidence record" validator.ex` | line 107 matched | PASS |
| Guide pointer in validator message | `grep "viewer_evidence.md" validator.ex` | line 108 matched | PASS |
| Staleness lifecycle section in guide | `grep -i "cadence\|designed\|lifecycle\|intentional" guides/viewer_evidence.md` | lines 198, 202, 223 matched | PASS |
| 180-day threshold mentioned in guide | `grep "180" guides/viewer_evidence.md` | lines 198, 202, 223, 345, 346 matched | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| HYG-01 | 94-01-PLAN.md | Known hidden-internal ExDoc warnings eliminated, zero-warning policy mechanically enforced in CI | SATISFIED | `mix docs` → 0 warnings; `mix docs --warnings-as-errors` → exit 0; `ci:` alias contains `"docs --warnings-as-errors"`; `skip_code_autolink_to:` list present; Font `@moduledoc false` replaced |
| HYG-02 | 94-02-PLAN.md | Stale viewer-evidence warning noise resolved/documented — staleness signal self-explaining, 180-day threshold preserved | SATISFIED | `staleness_warnings/1` augmented with advisory note, remediation command, guide pointer; `@staleness_days 180` unchanged; guide lifecycle section added |

**Note on pre-existing failure:** `Rendro.RecipesFacadeDriftTest` ("Rendro.Recipes.invoice/1 not exported") fails in the full suite. This is phase-93 debt, confirmed pre-existing: `git diff --name-only 6f422e5..HEAD` shows no recipes-facade files touched by phase 94. It does not affect phase 94's scope or status.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `guides/viewer_evidence.md` | 137, 249, 258, 297 | `placeholder`, `TBD` | Info | Occurrences are within guide prose describing the `explicit_deferral` scheme and user-facing vocabulary rules for that scheme — not code stubs or unresolved debt markers. No blocker. |

No `TBD`, `FIXME`, or `XXX` debt markers in code files modified by this phase.

### Human Verification Required

None. All must-haves are mechanically verifiable and were verified by running the specified commands against the live codebase.

### Gaps Summary

No gaps. All phase-94 success criteria are met:

- `mix docs --warnings-as-errors` exits 0 (zero ExDoc warnings, enforcement gate active).
- `docs --warnings-as-errors` is in the `ci:` alias at line 70 of `mix.exs`.
- `skip_code_autolink_to: ["Rendro.PDF.CidFont", "Rendro.PDF.FontSubsetter", "Rendro.Format"]` is in `docs/0`.
- `Rendro.PDF.Font` carries a public `[:stable]` `@moduledoc` and is in `priv/public_api.json` (user-approved deviation from the original plan; wording superseded per ROADMAP SC-1).
- `staleness_warnings/1` message in `validator.ex` is self-explaining: advisory note + `run mix rendro.viewer_evidence record <surface> <viewer>` + `see guides/viewer_evidence.md`.
- `@staleness_days 180` is unchanged (line 11, 3 occurrences only: 1 definition + 2 usage sites).
- `guides/viewer_evidence.md` has a "Staleness Lifecycle" section explaining designed cadence, ~late November 2026 first-fire date, re-recording response, advisory vs. `--strict` severity, and do-not-suppress guidance.
- 74 tests in the target suite: 0 failures.

---

_Verified: 2026-06-13_
_Verifier: Claude (gsd-verifier)_
