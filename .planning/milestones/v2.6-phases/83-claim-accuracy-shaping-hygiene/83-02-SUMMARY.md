---
phase: 83
plan: 02
subsystem: text-bidi
tags: [bidi, unicode, script-tags, opentype, refactor, tdd]
dependency_graph:
  requires:
    - 83-01 (unicode migration partial fix in bidi.ex Rule 3)
  provides:
    - Rendro.Text.ScriptTags (new public OT tag mapping module)
    - bidi.ex using ScriptTags.to_opentype_tag/1 (extracted from private)
  affects:
    - lib/rendro/text/bidi.ex (private to_opentype_tag removed)
    - lib/rendro/text/script_tags.ex (new module)
tech_stack:
  added: []
  patterns:
    - TDD RED/GREEN with failing test first
    - @moduledoc false internal helper module
    - Passthrough fallback clause for unknown atoms
key_files:
  created:
    - lib/rendro/text/script_tags.ex
    - test/rendro/text/script_tags_test.exs
  modified:
    - lib/rendro/text/bidi.ex (removed private to_opentype_tag/1, delegated to ScriptTags)
decisions:
  - "ScriptTags extracted as standalone @moduledoc false module per plan direction and future v2.7 reuse"
  - "152 clauses cover full Unicode 12.0 script inventory — well above minimum 25 required"
  - "Doc-only reference to UnicodeData.Script.script_to_tag/1 in @doc string is attribution, not a functional call"
  - "No reclassifications found — unicode package v1.22.0 tables match bidi test fixtures exactly"
requirements-completed:
  - HYG-04
metrics:
  duration: "~25m"
  completed: "2026-06-10"
  tasks: 2
  files: 3
---

# Phase 83 Plan 02: ScriptTags Extraction + Bidi Migration Verification Summary

## One-liner

Extracted 83-01's inline `to_opentype_tag/1` private function into a new `Rendro.Text.ScriptTags` module (152 public clauses, Unicode 12.0 coverage) and verified run-itemization fixture parity under `unicode ~> 1.22`.

## Tasks

### Task 1: Create ScriptTags helper + migrate bidi.ex resolve_state/1 (TDD)

**Status:** COMPLETE

**Commits:**
- `706c89a` — test(83-02): add failing tests for ScriptTags module (RED phase)
- `2dba997` — feat(83-02): create ScriptTags module + migrate bidi.ex to use it (GREEN phase)

**RED phase verification:** 28 tests failed (module did not exist)
**GREEN phase verification:**
- `lib/rendro/text/script_tags.ex` created with 152 `def to_opentype_tag/1` clauses
- `bidi.ex` updated: private `to_opentype_tag/1` removed, now calls `Rendro.Text.ScriptTags.to_opentype_tag/1`
- `grep -r "UnicodeData" lib/rendro/text/bidi.ex` returns no output (zero functional calls)
- 32 tests pass: 28 ScriptTags unit tests + 4 bidi_test.exs tests

**Behavior verified:**
- `ScriptTags.to_opentype_tag(:arabic)` → `:arab`
- `ScriptTags.to_opentype_tag(:latin)` → `:latn`
- `ScriptTags.to_opentype_tag(:hebrew)` → `:hebr`
- `ScriptTags.to_opentype_tag(:devanagari)` → `:deva`
- `ScriptTags.to_opentype_tag(:thai)` → `:thai`
- `ScriptTags.to_opentype_tag(:unknown_script)` → `:unknown_script` (passthrough)
- `Bidi.split_runs("Hello")` → `[%{text: "Hello", script: :latn, direction: :ltr}]`

### Task 2: Verify run-itemization fixture parity

**Status:** COMPLETE

**No file changes required** — all tests passed as-is, no reclassifications.

**Verification run:** `mix test test/rendro/text/ test/rendro/pipeline/measure_test.exs`
- 64 tests, 0 failures
- No codepoint reclassifications detected between `unicode_data 0.8.0` (old) and `unicode ~> 1.22` (new)
- Latin, Arabic, Hebrew, Devanagari, Thai fixtures all return expected script/direction atoms

**No CHANGELOG.md entry required** — no reclassifications occurred.

## Deviations from Plan

### DEVIATION CONTEXT: 83-01 Rule 3 partial migration

83-01 was forced to apply a partial `bidi.ex` migration (Rule 3 auto-fix) when `unicode_data` was removed from `mix.exs`. This plan's Task 1 verified and completed that migration:

- **What 83-01 did:** Migrated `resolve_state/1` from UnicodeData API to Unicode API, added private `to_opentype_tag/1` clauses inline in bidi.ex.
- **What this plan added:** Extracted those private clauses to a new `Rendro.Text.ScriptTags` public module (per plan's must_have: `script_tags.ex` with `to_opentype_tag/1`), then updated bidi.ex to delegate to `ScriptTags.to_opentype_tag/1`.

This was expected and matches the objective's deviation context.

### No other deviations

Plan executed exactly as written (with the caveat above). No Rule 1/2/3/4 deviations.

## Final Verification

```
grep -r "UnicodeData" lib/rendro/text/bidi.ex     → no output (zero functional calls)
mix test test/rendro/text/bidi_test.exs            → 4 tests, 0 failures
mix test test/rendro/pipeline/measure_test.exs     → 23 tests, 0 failures
lib/rendro/text/script_tags.ex                     → exists, @moduledoc false, 152 to_opentype_tag/1 clauses
CHANGELOG.md reclassifications                     → none required
```

## TDD Gate Compliance

- RED gate: commit `706c89a` (test — 28 failing tests)
- GREEN gate: commit `2dba997` (feat — module created, all 32 tests pass)
- REFACTOR gate: not required (no cleanup needed)

## Known Stubs

None — `to_opentype_tag/1` is fully populated with all required scripts and the passthrough fallback ensures correctness.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

Files exist:
- lib/rendro/text/script_tags.ex ✓
- test/rendro/text/script_tags_test.exs ✓

Commits exist:
- 706c89a ✓ (test RED)
- 2dba997 ✓ (feat GREEN)
