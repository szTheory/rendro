---
phase: 94-docs-warning-hygiene
reviewed: 2026-06-13T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - mix.exs
  - lib/rendro/pdf/font.ex
  - lib/rendro/viewer_evidence/validator.ex
  - lib/mix/tasks/rendro/api.gen.ex
  - priv/public_api.json
  - guides/viewer_evidence.md
  - test/mix/tasks/ci_alias_contract_test.exs
  - test/guardrails/required_checks_contract_test.exs
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
status: issues_found
---

# Phase 94: Code Review Report

**Reviewed:** 2026-06-13
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Phase 94 resolves two ExDoc warning classes (HYG-01 prose autolinks + typespec autolinks) and makes the viewer-evidence staleness signal self-explaining (HYG-02). A post-merge integration correction promoted `Rendro.PDF.Font` from a hidden internal module to a genuine public `[:stable]`-tagged module, added it to the `api.gen` registry, and regenerated the manifest. The overall approach is sound and the manifest is internally consistent with the `@moduledoc tags: [:stable]` declaration. One warning and two info items were found.

## Warnings

### WR-01: `Rendro.PDF.Font` missing from `groups_for_modules` after promotion to public stable

**File:** `mix.exs:160-219`
**Issue:** When `Rendro.PDF.Font` was promoted to the public stable surface (post-merge correction commit `63e7cc4`), it was added to `@public_modules` in `api.gen.ex` and tagged `[:stable]` in `font.ex`, but was never added to the `groups_for_modules` list in `mix.exs docs/0`. Every other stable-tier module visible in the docs sidebar is explicitly grouped (e.g., `Rendro.Text.Shaper` and `Rendro.Text.Shaper.Simple` are both in `"Core Builder API"`). `Rendro.PDF.Font` has no group assignment and will appear in ExDoc's ungrouped "Modules" bucket — conspicuously separated from its natural peer modules.

Note: several other stable modules (`Rendro.Artifact`, `Rendro.Path`, `Rendro.FormField`, `Rendro.Link`, `Rendro.FontRegistry.EmbeddedFontFamilyError`, etc.) also lack group assignments — this is a pre-existing omission, not introduced in this phase. However, `Rendro.PDF.Font` is new to the public surface in this phase and is the one this phase owns.

**Fix:** Add `Rendro.PDF.Font` to an appropriate group in `docs/0` `groups_for_modules`. Its natural home is `"Core Builder API"` alongside `Rendro.Text.Shaper` and `Rendro.Text.Shaper.Simple`, since it is the data type passed through the shaping API:

```elixir
"Core Builder API": [
  Rendro,
  Rendro.Document,
  # ... existing entries ...
  Rendro.Text.Shaper,
  Rendro.Text.Shaper.Simple,
  Rendro.PDF.Font          # add here
],
```

---

## Info

### IN-01: Duplicate ci alias contract assertion across two test files

**File:** `test/mix/tasks/ci_alias_contract_test.exs:9-17` and `test/guardrails/required_checks_contract_test.exs:190-199`
**Issue:** Both test files contain identical `assert ci_steps == [...]` assertions for the full ci alias step list. When the alias changes (e.g., a future phase adds a step), both assertions must be updated in sync. This phase correctly updated both (the `"docs"` → `"docs --warnings-as-errors"` change is reflected in both), but the duplication is a maintenance hazard.
**Fix:** Consider extracting the expected step list into a shared module attribute or test support helper. Alternatively, leave the duplication and accept the maintenance cost — the two tests exist at different contract levels and the redundancy may be intentional for defense-in-depth.

### IN-02: Staleness warning remediation omits required positional arguments

**File:** `lib/rendro/viewer_evidence/validator.ex:105-107`
**Issue:** The augmented staleness warning instructs users to run `mix rendro.viewer_evidence record to re-record` but the actual task signature requires positional arguments: `record <surface> <viewer>`. The warning tells the user what task to run but does not tell them what arguments to supply, leaving them to discover the full syntax from `mix help rendro.viewer_evidence` or the guide.

This is a minor UX gap, not a bug — the guide pointer at the end of the message (`see guides/viewer_evidence.md`) provides the full workflow, and the plan explicitly called for "compact inline" style. It is flagged here for visibility.
**Fix:** Optionally include the surface/viewer placeholders to make the command self-contained:

```elixir
" (advisory — non-fatal unless --strict;" <>
" run mix rendro.viewer_evidence record <surface> <viewer> to re-record;" <>
" see guides/viewer_evidence.md)"
```

This brings the message closer to the guide's own example syntax without violating the inline-compact house style.

---

## Consistency Check: Font Promotion (Phase Context)

The phase context asked specifically whether `Rendro.PDF.Font`'s `@moduledoc`/tagging, the `api.gen` registry edit, and the regenerated manifest are internally consistent. They are:

- `font.ex`: `@moduledoc` string + `@moduledoc tags: [:stable]` (two-attribute pattern, consistent with `Rendro.Page`, `Rendro.Cell`, etc.)
- `api.gen.ex` `@public_modules`: `Rendro.PDF.Font` listed at line 65, under the `# Stable tier` comment block (lines 45–76), before the `# Adapter tier` comment at line 77. Placement is correct.
- `priv/public_api.json`: entry `"Elixir.Rendro.PDF.Font"` with `"tier": "stable"`, four functions (`embedded/1`, `has_glyph?/2`, `helvetica/0`, `text_width/3`), and one type (`t/0`) — matches the module source exactly.
- The `c:Rendro.Text.Shaper.shape/3` cross-reference in the `@moduledoc` string correctly uses ExDoc's callback link syntax; `shape/3` is confirmed as a `@callback` on `Rendro.Text.Shaper`.
- `mix docs --warnings-as-errors` exits 0 (verified per summary), confirming `Rendro.PDF.Font` generates no stray ExDoc warnings at its new public location.

No inconsistencies found in the promotion artifacts.

---

_Reviewed: 2026-06-13_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
