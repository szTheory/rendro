# Phase 117: Edge-case stress matrix - Context

**Gathered:** 2026-07-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove the whole recipe surface (all six families: Invoice, Statement, Receipt, Certificate, Payslip, Ticket) is robust and deterministic under a **family × stress-dimension grid** — a curated matrix of SHA-256 hash-checked PDF-byte goldens + a small set of pdfium raster refs + typed-error assertions — and record the fixtures' exemption from the reader-quality "beauty" rubric (they prove robustness, not aesthetics).

This is a **TEST/INFRA phase**. Empirically verified during discussion: **no `lib/` product change is required** (the milestone's only irreversible act was the Phase-115 `Format` promotion). Allowed edits are confined to `test/`, `test/support/`, and non-`lib/` `priv/` (goldens, rubric manifest/schema). Any decision that would force a `lib/` change is called out as a risk below and is out of scope unless a real product-defect is discovered.

**Requirements:** EDGE-01 (deterministic goldens + raster refs + tarball exclusion), EDGE-02 (typed errors for overflow/tall-row/RTL), EDGE-03 (rubric beauty-gate exemption, explicit).

**Key de-risking finding:** all three EDGE-02 inputs already surface instructive **public** `%Rendro.Error{}` values (verified by live render probes) — so EDGE-02 is satisfiable by pure assertions, and the phase stays posture-clean.

</domain>

<decisions>
## Implementation Decisions

All decisions below are **locked** from a 4-agent parallel research fan-out (matrix/golden storage, errors-as-product, byte-vs-raster split, rubric exemption), each grounded in reading the actual source and existing infra, and mutually coherent: one data-driven matrix feeds golden cells, error cells, and raster cells; one bless idiom family; one exemption-by-construction rule.

### Matrix shape & golden storage (EDGE-01)
- **D-01 — Curated data-driven matrix, not a blind cross-product.** Express the grid as a single `@matrix` map keyed `{family, dimension} => :applies | "<N/A reason string>"` in `test/rendro/edge_matrix_test.exs` (`async: true` — render is pure). Every one of the ~120 `{family × dimension}` pairs MUST have an entry; N/A cells carry a short human reason (e.g. `{:certificate, :tax_vat} => "certificates carry no money"`, `{:ticket, :pagination_boundary} => "single-page family"`). A `for {{f,d}, :applies} <- @matrix` comprehension generates only the real golden cases.
- **D-02 — Coverage-honesty ratchet.** A meta-test asserts every `{family, dimension}` pair from the full `@families × @dimensions` lists is present in `@matrix` (`:applies` or an N/A reason) — so a gap can never masquerade as coverage. This encodes Rendro's "honesty / no overclaim" DNA as a machine-checked guard.
- **D-03 — Per-case golden files, hash-only, at `priv/goldens/<family>/<dimension>.sha256`.** One lowercase-hex line + `\n`, mirroring the existing `priv/raster_refs/` convention. Chosen over inline `@sha256` constants (they don't scale to ~40-60 cells: one bloated module, giant multi-hash diffs) and over a single JSON manifest (whole-file churn, skim-and-LGTM risk). Per-case files give: the path *names the case*, a golden change is a **one-line diff in exactly the named file**, and per-case `git blame`. **Never commit the PDF bytes** — a `MIX_GOLDEN_DUMP=<dir>` escape hatch writes the artifact to a gitignored scratch dir for eyeballing only.
- **D-04 — Explicit human bless gesture, assert-by-default, un-gated.** A `test/support/golden.ex` helper `assert_or_bless({family, dim}, pdf)` mirrors the raster `assert_or_bless` but is **not** CI-container-gated (PDF-byte hashes are cross-platform stable: embedded fonts + fixed epoch `D:20000101000000Z` + sorted dict keys). Default `mix test` is assert-only; a **missing** ref hard-**flunks** (no silent auto-create — the deliberate inverse of Jest's `-u` auto-bless footgun). Refresh = `MIX_GOLDEN_BLESS=true mix test <file>`, which rewrites only the changed one-line files. The failure message states "a hash change is a DEFECT, not a refresh, unless a human re-authorizes it." Before any hash is taken, assert two `deterministic: true` renders are byte-identical (reusing `deterministic_test.exs` discipline) so a non-determinism leak can never be blessed into a ref.

### Errors-as-product — EDGE-02 (NO lib change; verified by live probes)
- **D-05 — Overflow & tall-row → assert `%Rendro.Error{stage: :paginate, reason: :content_overflow}`.** Both funnel through the same `check_overflow!/4` path in `lib/rendro/pipeline/paginate.ex` (block/row taller than body → `throw {:error, :content_overflow, details}` → `Error.from_stage/3`). Assert struct match + `stage` + `reason` + `next =~ "does not auto-fit"` (verified message at `error.ex:273`). Use a **distinct** tall-row fixture (an atomic table row exceeding body height) from generic overflow so both entry points are exercised, and assert `is_map(e.details.block)` — that map identifying the offending block is the "never silent truncation" evidence.
- **D-06 — RTL → assert `%Rendro.Error{stage: :measure, ...}`.** Two honest public refusal modes, both verified via live probes: **(a)** default font → glyph resolution fails first → `reason: {:unsupported_glyph, char}`, `next =~ "fallback font"`; **(b)** a font that *has* RTL glyphs → `Shaper.Simple` gates `:hebr`/`:arab` (`simple.ex:56-57`) → `{:shaping_required, script, hint}` (engine has no UAX #9 reordering). Assert on `stage: :measure` + a **match** on either reason shape (`match?({:unsupported_glyph, _}, e.reason)`), never on message prose. Add a `refute` that `render/2` ever returns `{:ok, _}` for RTL under the default shaper — locking the honesty guarantee (Hebrew/Arabic rendered LTR = silently-wrong = the worst outcome for an auditable-docs library) against regression.
- **D-07 — Assertion idiom: match the typed struct + `stage`/`reason` + `next` substring — not prose.** `stage`/`reason`/`next` are the Stable contract; the message string is not. Never assert that a raw internal tuple (`{:error, {:shaping_required, ...}}`) reaches the caller — the whole point is that `render/2` returns a wrapped `%Rendro.Error{}`.
- **D-08 — Engine-level granularity, one representative per input — NOT per-family.** Overflow, tall-row, and RTL are pipeline (paginate/measure) concerns identical across all six recipes; six copies add zero coverage. One representative document each. (Per-family `validate_data!` `ArgumentError` coverage is a different concern already living in the recipe tests.) Error cells produce **no PDF golden and no raster ref** (there is no artifact) — they live in a sibling `@error_matrix`/`assert_raise`-style module, reusing the same fixture builder + exhaustiveness discipline.

### Byte-golden vs pdfium-raster split — "where applicable" (EDGE-01)
- **D-09 — Split rule: every cell gets a byte golden; a raster ref is added iff the correctness claim is placement geometry.** Byte SHA-256 is the portable backbone (runs in default `mix test`, everywhere) and is a *complete* constraint on the output for content substitutions. A raster ref earns its keep **only** where the claim is "where content lands relative to page edges/margins, where page breaks fall, and where running headers/footers sit under odd/even parity" — properties a human cannot verify from a content-stream diff — plus a "does it actually rasterize" render guard. Byte-hash-only dimensions: currency/VAT-vs-sales-tax labels, numeric edges ($0.00/negatives-as-parens/$1M+/cents-rounding/zero-qty), missing optional fields, small line counts (0/1/few). Raster dimensions: pagination boundaries, page-boundary/60+ line counts, A4-vs-Letter geometry, odd/even running content, extreme text wrap.
- **D-10 — Curated raster set with a hard ceiling (~6 fixtures / ~12 page refs; ceiling ≤ 8 / ≤ 16).** Do NOT raster the full applicable sub-grid. Ship: (a) one multi-page (≥2pp) paginating fixture per paginating family — Invoice, Statement, Payslip = 3 — each simultaneously covering pagination + 60+ + odd/even; (b) one A4 + one US Letter pair on a single representative family = 2 (page-size machinery is shared engine code); (c) one extreme-wrap fixture = 1. Receipt/Certificate/Ticket are structurally single-page → no pagination raster. What is intentionally NOT raster-checked is logged (coverage honesty), and Rendro claims byte-determinism everywhere, NOT pixel-perfect everywhere.
- **D-11 — Reuse the existing raster lane + tags verbatim.** Byte goldens: untagged, `async: true`, run in the default `test` job on every platform. Raster: `@tag raster_snapshot: true`, `async: false`, committed to `priv/raster_refs/<fixture>/page_N.sha256`, rendered via `Pdfium.render(pdf, dpi: 150, ...)`, already excluded from default `mix test` (`test_helper.exs:10`), blessed only when `MIX_RASTER_BLESS=true && GITHUB_ACTIONS=true` (pinned container — raster hashes are NOT portable). Keep the existing bless-guard test (raises outside `GITHUB_ACTIONS`) in the default run. Raster stays an **advisory** lane (not a required check) so a pdfium pin bump can't red-wall the required `test` job; byte goldens are the gating signal. Clone `pdfium_raster_snapshot_test.exs` for mechanics.
- **D-12 — Tarball-exclusion guard test (EDGE-01 tail).** `priv/goldens` and `priv/raster_refs` are excluded from the Hex tarball **by construction** (the `mix.exs:114-128` `files:` allowlist admits only `priv/branded` + `priv/examples` under `priv/`), but EDGE-01 wants an explicit tripwire. Clone the tarball-exclusion test in `test/docs_contract/branding_claims_test.exs` (~lines 57-72; untars the built `contents.tar.gz` via `Rendro.Test.HexBuildCache`) and add `refute contents =~ "priv/goldens/"` and `refute contents =~ "priv/raster_refs/"`, plus a positive companion asserting `lib`/`priv/branded` still ship (so an over-aggressive exclusion also fails loudly).

### Rubric beauty-gate exemption — EDGE-03
- **D-13 — Exemption by construction + one explicit manifest-level block; zero per-fixture entries.** Stress fixtures never receive a `score_entry` in `priv/quality/rubric_scores.json` (they live in test-land). Add ONE top-level `stress_exemption` object `{ "exempt": true, "reason": "...", "fixture_source": "test/rendro/edge_matrix_test.exs", "gate_scope": "scores" }` so the exemption is a single reviewer-visible, reasoned statement — not 40-60 near-identical noise rows polluting the array Phase 118 appends real demo scores into. Chosen over per-fixture `stress_exempt: true` entries (schema requires `dimension_scores`, forcing contradictory dummy scores; high noise) and over silent exclude-by-construction (exemption would be implicit — violates "explicit in the manifest/tests").
- **D-14 — Minimal schema delta.** In `priv/schemas/rubric_scores.schema.json`: add top-level `stress_exemption` (object; `required: ["exempt","reason"]`; `exempt = {const: true}`; `reason` non-empty string) AND add `"stress_exemption"` to the root `required` array so the manifest **cannot validate** if the block is ever deleted (hard anti-silent-loss). No `if/then` conditional and no change making `dimension_scores` optional (unnecessary — no exempt entry ever lives in `scores`). Leave the existing anticipatory per-entry `stress_exempt` field (schema line 126) in place, now repurposed as a loophole tripwire (D-15).
- **D-15 — Contract-test guards, fail loud in BOTH directions** (extend `test/docs_contract/rubric_manifest_contract_test.exs`): (i) assert `stress_exemption.exempt == true` + non-empty `reason` (anti-silent-loss, paired with schema-required); (ii) assert **every** `scores` entry has `stress_exempt` absent/false (a real demo can never use the flag to dodge the beauty gate); (iii) assert **disjointness** — the stress-matrix fixture id set (imported from the `@matrix` enumeration, one source of truth) ∩ `scores` `demo_id`s = ∅ (a robustness fixture can never be wrongly beauty-gated); (iv) a "teeth guard" asserting the imported stress-fixture set is non-empty (so disjointness can't pass vacuously).

### Claude's Discretion
- Exact dimension list granularity and fixture-builder shape (`Rendro.Test.EdgeFixtures.build/2`), the precise N/A reason strings, and which single family is the A4/Letter + extreme-wrap representative — planner/executor may refine within the locked structure (D-01/D-02 ratchet, D-03 path convention, D-10 ceiling).
- Whether the two-run determinism pre-check (D-04) is inline per case or a shared helper.
- Exact `stress_exemption.reason` wording and whether `fixture_source` points at the matrix module or a shared enumeration constant.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements & roadmap
- `.planning/ROADMAP.md` §"Phase 117: Edge-case stress matrix" — goal, 3 success criteria, rubric beauty-gate exemption.
- `.planning/REQUIREMENTS.md` — EDGE-01 (goldens + raster + tarball guard), EDGE-02 (typed errors), EDGE-03 (rubric exemption).

### Milestone-A research (DNA, pillars, prior-art footguns)
- `.planning/research/milestone-a/SUMMARY.md` — milestone guardrails; pitfalls P1–P7.
- `.planning/research/milestone-a/R4-PRIOR-ART-PITFALLS.md` — float money, jurisdiction-in-layout, PII footguns; catalog-vs-stress raster scoping.
- `.planning/research/milestone-a/R5-COHERENCE-PILLARS.md` — P2 honesty / no overclaim (the source of the coverage-honesty ratchet D-02 and the "byte-determinism not pixel-perfect" framing).
- `prompts/rendro-oss-dna.md`, `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — Rendro design DNA/values (errors-as-product, determinism, honesty). (Brand book: prefer `brand/README.md` over the older superseded `prompts/Rendro Brand Book.txt` — but this phase is largely non-visual.)

### Existing test infra to clone / extend (the phase's structural analogs)
- `test/rendro/table_byte_identity_test.exs` — inline byte-golden precedent + the "a hash change is a defect, not a refresh" doctrine (D-04's failure-message tone).
- `test/rendro/deterministic_test.exs` — `deterministic: true` byte-identity property + fixed-epoch/sorted-key assertions (two-run pre-check in D-04).
- `test/rendro/adapters/pdfium_raster_snapshot_test.exs` — the `assert_or_bless` / `MIX_RASTER_BLESS` / `GITHUB_ACTIONS` container-guard mechanics to clone for D-11; ref storage `priv/raster_refs/<fixture>/page_N.sha256`.
- `test/support/pdfium_cli.ex`, `priv/pdfium_pin.json` — pdfium CLI helper + version pin (raster determinism).
- `test/test_helper.exs:10` — the `exclude: [... raster_snapshot: true]` default-exclude (already in place).
- `test/docs_contract/branding_claims_test.exs` (~57-72) — tarball-exclusion guard to clone for D-12; `test/support/hex_build_cache.ex` (`Rendro.Test.HexBuildCache.get_build_output/0`).
- `test/docs_contract/rubric_manifest_contract_test.exs` — the rubric docs-contract test to extend for D-15.

### Product code the assertions target (READ, do NOT edit — EDGE-02 is test-only)
- `lib/rendro/pipeline/paginate.ex` (~359-360, 715, 811-824, 863-877, 1189-1190, 1303) — `:content_overflow` throw + `check_overflow!/4` (overflow + tall-row, D-05).
- `lib/rendro/error.ex` (~116-122, 257-267, 273) — `Error.from_stage/3`, `next_step(:paginate, :content_overflow)` = "…does not auto-fit…", measure-stage next steps.
- `lib/rendro/pipeline/measure.ex` (~648, 873) — glyph-resolution failure → `{:unsupported_glyph, char}` (RTL default-font path, D-06).
- `lib/rendro/text/shaper/simple.ex` (13-39 `@requires_shaping`; 56-57 gate) + `lib/rendro/text/shaper.ex` + `lib/rendro/text/bidi.ex` (64-70 script derivation) — RTL refusal / `{:shaping_required, script, hint}` (D-06). **NOTE:** `lib/rendro/i18n/analyzer.ex` `analyze/1` is unwired **dead code** (no pipeline callers) — do NOT wire it in; flag for a future cleanup phase.

### Rubric manifest & schema (non-`lib/` edits allowed — EDGE-03)
- `priv/quality/rubric_scores.json` — append the `stress_exemption` block (D-13); `scores` array stays free of stress noise.
- `priv/schemas/rubric_scores.schema.json` — add `stress_exemption` def + root-`required` entry (D-14); existing per-entry `stress_exempt` field at line 126.

### Packaging
- `mix.exs` (~110-130 `defp package` `files:` allowlist) — the allowlist that excludes `priv/goldens`/`priv/raster_refs`/`test/` by construction (D-12).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Rendro.render(doc, deterministic: true)`** — already byte-stable (fixed epoch, sorted dict keys); the golden + two-run determinism backbone. No new determinism work needed.
- **Raster `assert_or_bless` + `MIX_RASTER_BLESS` + `GITHUB_ACTIONS` guard** (`pdfium_raster_snapshot_test.exs`) — clone directly; the byte-golden `assert_or_bless` (D-04) is the un-gated sibling of this.
- **`Rendro.Test.HexBuildCache.get_build_output/0`** + the branding-claims tarball untar test — the tarball-exclusion guard template (D-12).
- **`%Rendro.Error{}` + `Error.from_stage/3` + `next_step/2`** — all three EDGE-02 inputs already produce instructive public typed errors; assertions only (D-05/D-06).

### Established Patterns
- **Data-driven test generation** (`for`-comprehension over a module-attribute table generating tests, `async: true`) — the idiomatic Elixir large-suite pattern the `@matrix` (D-01) uses.
- **`priv/<kind>/<fixture>/….sha256` ref-file convention** — one mental model shared by `raster_refs` and the new `goldens`; the one deliberate divergence is bless-gating (raster CI-container-gated, byte un-gated) because raster hashes aren't portable.
- **Exemption-by-construction + explicit marker + fail-loud contract test** — the rubric governance pattern (D-13/D-15), mirroring xfail-registry discipline.

### Integration Points
- New `test/rendro/edge_matrix_test.exs` (goldens), a sibling error-assertion module (EDGE-02), `test/support/golden.ex` + `Rendro.Test.EdgeFixtures`, new `priv/goldens/**`, extended `priv/raster_refs/**`, extended `rubric_manifest_contract_test.exs`, and one added tarball-guard assertion — all test/support/priv, zero `lib/`.

</code_context>

<specifics>
## Specific Ideas

- The money-edge golden cells render `Rendro.Format` output; `Format` is adapter-tier (Phase 115), so a future authorized `Format` string change will (correctly) flap those goldens — the intended ratchet. Document this in the bless message so a maintainer distinguishes "authorized `Format` evolution" from "determinism regression."
- Recommended contingency (cheap, ~10 min): a throwaway probe confirming the three EDGE-02 inputs' current error types before locking test-only — already done during discussion (live probes confirmed all three), so no `lib/` change is scheduled.

</specifics>

<deferred>
## Deferred Ideas

- **Wire or delete `Rendro.I18n.Analyzer.analyze/1`** — currently unwired dead code (only its own test calls it). Not needed for EDGE-02 (measure already fails honestly on RTL). A future cleanup/tech-debt phase, not this one.
- **HarfBuzz adapter for real RTL/complex-script shaping** — the `{:shaping_required, ...}` error names it as the resolution path; actually supporting RTL layout is a large, separate capability (explicitly out of milestone scope), not a stress-matrix concern.
- **Retrofit opts-shape/`validate_data!` typed-error coverage to Invoice/Statement** — D-19 from Phase 116 scoped errors-as-product opts validation to Payslip/Ticket; a broader retrofit is a future additive phase.

</deferred>
