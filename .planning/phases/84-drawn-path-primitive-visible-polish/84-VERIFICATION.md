---
phase: 84-drawn-path-primitive-visible-polish
verified: 2026-06-10T17:18:00Z
status: verified
score: 4/4 must-haves verified
overrides_applied: 0
resolution:
  - finding: "Rendro.path/2 builder crashed (KeyError) on block-level width:/height: attrs shown in its own @moduledoc example."
    resolved: 2026-06-10
    decision: "Resolved per locked decision D-12 (builder 'supports width:/height:') — not an open design choice. Split block-level attrs (x/y/width/height/keep_*/break_*) and route them to the Block wrapper, mirroring the sibling form_field/2 builder. No human decision required: D-12 already locked option (a)."
    commit: "fix(84): route block-level attrs through Rendro.path/2 builder (D-12)"
    evidence: "3 regression tests added (test/rendro/path_test.exs); documented example now returns %Block{content: %Path{}, width: 200, height: 70}; full suite 1073 tests, 0 failures."
---

# Phase 84: Drawn-Path Primitive & Visible Polish — Verification Report

**Phase Goal:** A Phoenix engineer can author deterministic vector graphics via a declarative `%Rendro.Path{}` element, tables can opt in to borders and rules, and the Certificate recipe gains a decorative border frame — so the gallery shows visually compelling output.
**Verified:** 2026-06-10T17:18:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth                                                                                       | Status     | Evidence                                                                                          |
|----|---------------------------------------------------------------------------------------------|------------|---------------------------------------------------------------------------------------------------|
| 1  | `%Rendro.Path{ops: [{:rect, x, y, w, h}], stroke: %{color: {0,0,0}, width: 1.0}}` in a document renders visible `re`/`S` PDF operators | ✓ VERIFIED | `mix run` confirmed: `re op: true`, `S op: true`, `q/Q: true`, `cm: true`; 16 path tests green   |
| 2  | `borders: :all` on a table renders visible cell rules (`re`/`S`); omitting the option is byte-identical to today's borderless rendering | ✓ VERIFIED | `mix run` confirmed: `re: true`, `S: true`, byte-identical baseline confirmed; 19 table border tests green |
| 3  | Certificate `border: true` renders a decorative frame; `border: false` (default) is byte-identical to prior output; coordinates differ A4 vs US Letter | ✓ VERIFIED | `mix run` confirmed: `re: true`, `S: true`, no-border no `re`, A4 != Letter; 35 certificate tests green |
| 4  | `priv/support_matrix.json` has terminal `path_primitive` rows; transforms, clipping, and gradients are `explicit_deferral` entries with ≥40-char evidence strings; byte-determinism golden tests pass | ✓ VERIFIED | Python inspection confirmed all three deferrals present with 136–201-char evidence; `deterministic_test.exs` 3 properties + 12 tests green |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact                                       | Expected                                         | Status      | Details                                                                   |
|------------------------------------------------|--------------------------------------------------|-------------|---------------------------------------------------------------------------|
| `lib/rendro/color.ex`                          | Internal `Rendro.Color` helper (`@moduledoc false`) | ✓ VERIFIED | Present; `rg/1`, `rg_stroke/1`, `to_pdf_components/1`, `validate/1` all implemented; `format_num/1` verbatim copy for byte-determinism |
| `lib/rendro/path.ex`                           | Public `%Rendro.Path{}` struct (`@moduledoc tags: [:stable]`) | ✓ VERIFIED | Present; `@enforce_keys [:ops]`; all 6 op types typed; stroke/fill style types defined |
| `lib/rendro/pipeline/measure.ex`               | `measure_block/3` clause for `%Rendro.Path{}`   | ✓ VERIFIED | Clause at line 141; four-case dimension resolution; `compute_ops_extent/1` fallback |
| `lib/rendro/pdf/writer.ex`                     | `render_block/5` clause for `%Rendro.Path{}` + `paint_op/2` + `rounded_rect_path/6` | ✓ VERIFIED | Clause at line 586; `q/cm/Q` balanced state; `paint_op/2` at lines 1884–1887; `rounded_rect_path/6` at line 1934; `table_decoration/3` at line 1993 |
| `lib/rendro.ex`                                | `Rendro.path/2` builder (`@spec path([term()], keyword()) :: Block.t()`) | ✓ VERIFIED (with warning) | Builder exists; works for path-level attrs (`stroke`, `fill`); see WARNING below |
| `lib/rendro/table.ex`                          | Three new fields: `borders: :none`, `border_style: nil`, `header_fill: nil` | ✓ VERIFIED | All three fields present with correct defaults |
| `lib/rendro/recipes/certificate.ex`            | `validate_border!/2`, `resolve_frame_opts/7`, `:frame` region, `:certificate_frame` section | ✓ VERIFIED | All present; closed key allowlist; color/inset validation delegated to `Rendro.Color` |
| `priv/support_matrix.json`                     | `path_primitive` section with `explicit_deferral` rows for transforms, clipping, gradients | ✓ VERIFIED | Section present; all three deferrals with `evidence_deferred` strings (201, 139, 136 chars respectively) |
| `priv/public_api.json`                         | `Rendro.Path` stable tier + `path/2` in `Rendro` module | ✓ VERIFIED | `Elixir.Rendro.Path` at line 289 with `tier: "stable"`; `path/2` in `Elixir.Rendro` functions at line 16 |
| `test/rendro/path_test.exs`                    | P01a–P01f tests all green                        | ✓ VERIFIED | 16 tests, 0 failures                                                      |
| `test/rendro/table_borders_test.exs`           | P02a–P02f + normalization tests all green        | ✓ VERIFIED | 19 tests, 0 failures                                                      |
| `test/rendro/recipes/certificate_test.exs`     | C1–C20 all green (C15–C20 new border tests)      | ✓ VERIFIED | 35 tests, 0 failures (C16 note: typing warning on pre-existing C12 test, unrelated) |
| `test/docs_contract/path_claims_test.exs`      | PATH-04 docs-contract lane (2 tests)             | ✓ VERIFIED | 2 tests, 0 failures                                                       |
| `guides/api_stability.md`                      | Three path_primitive deferral mirror entries     | ✓ VERIFIED | All three `path_primitive × transforms_cm / clipping_W / gradients` lines present |
| `scripts/verify_docs.exs`                      | Path claims lane self-registration               | ✓ VERIFIED | `{"Path claims lane", [...]}` entry at line 21                           |

### Key Link Verification

| From                      | To                                  | Via                              | Status     | Details                                                                    |
|---------------------------|-------------------------------------|----------------------------------|------------|----------------------------------------------------------------------------|
| `Rendro.path/2`           | `%Rendro.Path{}` struct             | `struct!(Rendro.Path, attrs)`    | ✓ WIRED    | Builder returns `%Block{content: %Rendro.Path{}}` |
| `measure.ex`              | `%Rendro.Path{}`                    | `measure_block/3` pattern match  | ✓ WIRED    | Clause present and dispatches correctly |
| `writer.ex` render_block  | `%Rendro.Path{}`                    | `render_block/5` pattern match   | ✓ WIRED    | Clause at line 586; emits `q/cm/Q` + ops |
| `Rendro.Color.rg/1`       | Text writer (D-03 retrofit)         | `render_text_block/8`            | ✓ WIRED    | Inline color computation replaced with `Rendro.Color.rg/1` |
| `table_decoration/3`      | `render_block/5` (table branch)     | `decoration = table_decoration(...)` + guard | ✓ WIRED | Guarded prepend: Pitfall-3 stray-newline guard confirmed |
| `Certificate.document/2`  | `%Rendro.Path{}` frame              | `sections/2` + `:certificate_frame` section + `:frame` region | ✓ WIRED | Dogfoods path primitive; `border: false` emits zero path ops |
| `path_claims_test.exs`    | `priv/support_matrix.json`          | JSON parse + key assertions      | ✓ WIRED    | Test 1 reads and asserts deferral keys |
| `viewer_evidence_claims_test.exs` | `guides/api_stability.md`   | Recursive evidence_deferred substring check | ✓ WIRED | All 3 path_primitive deferral mirrors pass the 40-char substring test |

### Data-Flow Trace (Level 4)

| Artifact            | Data Variable       | Source                               | Produces Real Data | Status     |
|---------------------|---------------------|--------------------------------------|--------------------|------------|
| `writer.ex` Path clause | `path_ops`      | `render_path_ops(path.ops, h)` → per-op dispatch | Yes — ops from `%Rendro.Path{}` struct field | ✓ FLOWING |
| `table_decoration/3` | `borders`, `header_fill` | `table.borders`, `table.header_fill` from struct | Yes — from normalized `Rendro.table/2` attrs | ✓ FLOWING |
| `certificate.ex`    | frame `%Rendro.Path{ops: [{:rect, 0, 0, rw, rh}], stroke: ...}` | `resolve_frame_opts/7` geometry derivation | Yes — `rw/rh` derived from `pw - 2*inset` / `ph - 2*inset` | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior                                              | Command                                                                          | Result                                                  | Status  |
|-------------------------------------------------------|----------------------------------------------------------------------------------|---------------------------------------------------------|---------|
| Rect path renders `re`/`S` PDF operators              | `mix run -e '...'` with `%Rendro.Path{ops: [{:rect,...}], stroke: %{color: {0,0,0}, width: 1.0}}` | `re op: true`, `S op: true`, 766 bytes                 | ✓ PASS  |
| `borders: :all` renders `re`/`S`; borderless byte-identical | `mix run -e '...'` with `Rendro.table(rows, columns: cols, borders: :all)` | `re: true`, `S: true`, `no-border == none: true`       | ✓ PASS  |
| Certificate A4 border frame ≠ Letter (geometry-derived) | `mix run -e '...'` with `page_size: :a4` vs `page_size: :us_letter`          | `A4 border != Letter border: true`                      | ✓ PASS  |
| `Rendro.path/2` with `:stroke` only                   | `mix run -e 'Rendro.path([{:rect,0,0,100,50}], stroke: {0,0,0})'`              | Returns `%Rendro.Block{}` with no error                 | ✓ PASS  |
| `Rendro.path/2` with `:width`/`:height` (documented example) | `mix run -e 'Rendro.path([{:rect,10,10,100,50}], stroke: {0,0,0}, width: 200, height: 70)'` | `KeyError: key :width not found` — CRASH               | ✗ FAIL  |

### Probe Execution

Step 7c: SKIPPED — no probe scripts declared in PLAN files or SUMMARY files; phase is a library feature addition, not a migration or CLI tooling phase. The Wave 0 validation harness (`mix test`) serves as the probe.

### Requirements Coverage

| Requirement | Source Plan | Description                                                                                     | Status           | Evidence                                                   |
|-------------|-------------|-------------------------------------------------------------------------------------------------|------------------|------------------------------------------------------------|
| PATH-01     | 84-01, 84-02 | `%Rendro.Path{}` declarative vector block element through standard pipeline                    | ✓ SATISFIED      | 16 path tests green; struct form renders correctly; pipeline dispatch in measure.ex + writer.ex |
| PATH-02     | 84-03        | Opt-in table borders/rules/header-band; default byte-identical                                 | ✓ SATISFIED      | 19 table border tests green; byte-identity confirmed by spot-check |
| PATH-03     | 84-04        | Certificate `border:` frame; geometry-derived coordinates at A4 and US Letter                  | ✓ SATISFIED      | 35 certificate tests green (C15–C20 new); A4 ≠ Letter confirmed |
| PATH-04     | 84-05        | Byte-determinism golden tests + terminal support-matrix rows; transforms/clipping/gradients deferred | ✓ SATISFIED | 3 properties + 12 deterministic tests green; all 3 deferral rows present with evidence strings ≥40 chars |

### Anti-Patterns Found

| File           | Line | Pattern                                                           | Severity      | Impact                                                                                   |
|----------------|------|-------------------------------------------------------------------|---------------|------------------------------------------------------------------------------------------|
| `lib/rendro/path.ex` | 46–48 | Module doc example `Rendro.path([{:rect,...}], stroke: ..., width: 200, height: 70)` crashes at runtime | WARNING | Callers following the documented example for the stable-tier `Rendro.path/2` builder will hit `KeyError: key :width not found`. The builder passes ALL attrs to `struct!(Rendro.Path, ...)` but `%Rendro.Path{}` only accepts `ops`, `fill`, `stroke`. Block-level dims (`width`, `height`) must either be (a) split into a Block wrapper, or (b) the doc example must show the two-step pattern. |

No `TBD`, `FIXME`, or `XXX` markers found in phase-modified files (the "placeholder" occurrences in `priv/support_matrix.json` are all pre-existing signature-widget rows, not path_primitive rows, and describe intended unsigned-placeholder behavior — not stubs).

### Human Verification Required

#### 1. Rendro.path/2 builder — width/height attrs not routed to Block

**Test:** Call `Rendro.path([{:rect, 10, 10, 100, 50}], stroke: {0, 0, 0}, width: 200, height: 70)` in an IEx session.

**Expected per module docs:** Returns a `%Rendro.Block{content: %Rendro.Path{...}, width: 200, height: 70}`.

**Actual:** `** (KeyError) key :width not found` — because `normalize_path_attrs` does not split block-level attrs before passing the full keyword list to `struct!(Rendro.Path, &1)`.

**Why human:** This is a stable-tier Tier-1 public API (`@moduledoc tags: [:stable]`; `Rendro.path/2` is in `priv/public_api.json`). The fix requires a decision: either (a) `normalize_path_attrs` splits out block-level keys and routes them to the final `struct!(Block, ...)` call (matching D-12's design intent: "supports `width:`/`height:`"), or (b) the module doc example is corrected to show the two-step pattern (`Rendro.block(Rendro.path([...], stroke: ...), width: 200, height: 70)`). Option (a) is the clearly intended design per CONTEXT.md D-12; option (b) accepts a narrower builder API. Both are valid but only a human can confirm the intent and apply the stable-tier change.

**Suggested fix (option a):**
```elixir
@block_attrs [:x, :y, :width, :height, :keep_together, :keep_with_next, :break_before, :break_after]

def path(ops, attrs \\ []) do
  {block_attrs, path_attrs} = Keyword.split(attrs, @block_attrs)
  path_attrs
  |> normalize_path_attrs()
  |> Keyword.put(:ops, ops)
  |> then(&struct!(Rendro.Path, &1))
  |> then(&struct!(Block, Keyword.put(block_attrs, :content, &1)))
end
```

### Gaps Summary

No gaps block the phase goal. All four success criteria are verifiably achieved in the codebase:

- PATH-01: `%Rendro.Path{}` renders via `re`/`S`/`f`/`B`/`n` PDF operators through the standard pipeline. 16 tests green.
- PATH-02: Table borders render correctly; borderless output is byte-identical to pre-84 baseline. 19 tests green.
- PATH-03: Certificate border frame works at A4 and US Letter with geometry-derived coordinates; `border: false` is byte-identical. 35 tests green.
- PATH-04: `priv/support_matrix.json` has terminal `path_primitive` rows with three `explicit_deferral` entries (transforms_cm, clipping_W, gradients). Byte-determinism: 3 properties + 12 tests green. Full suite: 1070 tests, 0 failures.

One WARNING issue exists and needs human decision before the phase is fully closed: the stable-tier `Rendro.path/2` builder crashes when called with block-level `width:`/`height:` attrs as its own module documentation example shows. This is a doc/API consistency gap on a Tier-1 stable surface.

---

_Verified: 2026-06-10T17:18:00Z_
_Verifier: Claude (gsd-verifier)_
