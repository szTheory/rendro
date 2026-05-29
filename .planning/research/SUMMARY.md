# Project Research Summary

**Project:** Rendro v2.4 — Batteries-Included Workflow & Adoption Closure
**Domain:** Pure-Elixir deterministic PDF generation library — page-numbering primitive, production recipes (Statement, Receipt/Report, Certificate), CI-exercised reference Phoenix app
**Researched:** 2026-05-29
**Confidence:** HIGH

---

## Resolved Disagreements

Two genuine disagreements surfaced across the four research files. Both required reading the actual code in `lib/rendro/pipeline/paginate.ex` to adjudicate. The resolved truths are stated here so the roadmapper can treat them as settled constraints, not open questions.

### Disagreement 1: Total-Page-Count Seam

**STACK.md and ARCHITECTURE.md claimed:** `{{total_pages}}` is trivially available single-pass at the `apply_page_template/replace_page_numbers` call site because it runs after `Enum.reverse()` on the fully-collected page list — making `{{total_pages}}` a localized additive change with no special treatment needed.

**PITFALLS.md and FEATURES.md warned:** Substituting a shorter string for a longer placeholder (e.g. "of 9" for "of 10") changes text width in already-measured lines — risking layout convergence or infinite loops. Also warned of a `body_capacity` / footer-height gap where running footer height is not subtracted from the body region.

**Resolved truth from the code:**

**Part A — Is total_pages genuinely available single-pass?** Yes. Looking at `paginate_flow/1` (lines 22–48 of `paginate.ex`): `paginate_blocks` returns a `{pages, diagnostics}` accumulator. The subsequent pipeline is:

```elixir
pages
|> Enum.reverse()
|> Enum.with_index(1)
|> Enum.map(fn {page, idx} -> ... apply_page_template(idx, layout) end)
```

`total_pages = length(pages)` can be bound immediately after `Enum.reverse()` and before the `Enum.map` runs. There is no second pagination stage, no new page added after this point — `apply_page_template` only anchors region blocks onto existing pages. STACK/ARCHITECTURE are correct: a single-pass approach works here.

**Part B — Is the placeholder-width concern real?** No, not in Rendro's layout model. `replace_page_numbers` (and the future `replace_running_tokens`) runs post-measurement, post-pagination, inside the final `Enum.map`. Block heights are frozen. Substituting a narrower string into a `MeasuredText` line does not re-trigger layout; it only causes a visual width mismatch in the rendered run. The convergence/infinite-loop risk that PITFALLS describes — where a longer substituted string causes a new page, which increases total, which causes a longer string, repeat — does not exist in this pipeline because layout is already frozen when substitution happens. **A reserved-width placeholder is NOT required for correctness in Rendro's model.** It is cosmetically desirable (ensures the rendered glyph string fits its pre-measured run width), but it cannot cause pagination instability.

**Part C — Is the body_capacity/footer-height gap a real prerequisite bug?** Yes, this is real. Looking at `flow_layout/1` (lines 477–501 of `paginate.ex`): `body_region.height = template.height - template.margin_top - template.margin_bottom`. Header and footer region heights declared in the template are not subtracted. Default `%PageTemplate{}` has zero-height header and footer, so this has never manifested. But any recipe that authors a running footer with real height (e.g. a 36pt "Page X of Y" line) will have a `body_capacity` that does not account for that footer — the last N lines of body content will visually overlap the footer. This must be fixed in the foundational primitive phase before any recipe uses a running footer. The fix is to derive `body_capacity` by also subtracting all non-body region heights declared in the template.

**Roadmapper directive:** Use single-pass `length(pages)` approach — no reserved-width placeholder required for correctness. Fix `body_capacity` derivation in Phase 73 (primitive phase) as a required exit criterion before any recipe phase ships a running footer. A cosmetic digit reserve is a nice-to-have, noted as an open question below.

---

### Disagreement 2: Reference-App CI Isolation

**STACK.md and ARCHITECTURE.md claimed:** Extend the existing "Verify Phoenix Example" step inside the required `test` job from `mix compile` to `mix test`. No new required status check needed.

**PITFALLS.md warned:** Keeping the example as a step in the `test` job couples Phoenix-dependency failures to the engine-critical required lanes. A transient Phoenix dep failure or flaky Phoenix test infrastructure would block `mix ci` and, because `signing-live-proof` and `long-lived-live-proof` declare `needs: test`, could prevent the entire proof chain from running.

**Resolved truth:** PITFALLS is correct. The risk is structural: a `mix test` step that uses Phoenix test infrastructure (even without Ecto, endpoint startup is more fragile than deterministic Elixir unit tests) is categorically more likely to flake in CI than the Rendro core tests. Keeping it as a step in the `test` job means any Phoenix flakiness causes the core `test` job to fail, which blocks downstream signing proof lanes. The current `mix compile` step has low failure probability. Upgrading to `mix test` while keeping it as a step in `test` creates an unacceptable blast radius.

**Roadmapper directive:** In the reference-app phase (Phase 77), move the example verification to a **separate `example-phoenix` CI job** that declares `needs: [test]` but is NOT itself a required branch-protection check. Then upgrade to `mix test`. This isolates Phoenix flakiness so it never blocks core proof lanes. A Phoenix example failure becomes a visible "adoption signal failed" status rather than a "core tests failed" status.

---

## Executive Summary

Rendro v2.4 is a pure-Elixir PDF generation library milestone with three parallel workstreams: a page-numbering/running-region engine primitive, three new production document recipes (Statement, Receipt/Report, Certificate), and a CI-exercised reference Phoenix application. All three workstreams share a foundational constraint: zero new runtime Hex dependencies at the core library level. Every feature is implementable using existing pipeline infrastructure, existing structs, and existing recipe patterns. The milestone is adoption ergonomics, not a trust-axis extension — the v2.3 viewer-evidence and support-matrix discipline is inherited (named explicit_deferral or recorded proof), not deepened.

The key architectural finding is that `{{total_pages}}` token substitution is genuinely available in a single pipeline pass. After `paginate_blocks` collects all pages and `Enum.reverse()` produces the final ordered list, `total_pages = length(pages)` can be bound before the existing `Enum.map` runs `apply_page_template`. No second render pass is needed; no reserved-width placeholder is required for pagination correctness. There is, however, a real prerequisite bug: `flow_layout/1` computes `body_capacity` without subtracting header and footer region heights. Recipes authoring a running footer with real height will have the footer overlap the last body lines unless this derivation is fixed in Phase 73. This fix is a hard prerequisite for any recipe that uses a running footer.

Carried-forward running totals (balance C/F and B/F for Statement) are emphatically a data-assembly concern, not an engine concern. The recipe's `sections/2` function receives the full dataset and must pre-compute all per-page totals before constructing blocks. The pipeline does not accumulate running state across page breaks. Certificate is fully independent of the page-numbering primitive — it uses `Rendro.fixed/2` and existing asset registration, and must derive all layout coordinates from template dimensions (no hardcoded A4 values). For CI, the Phoenix example verification must be moved to an isolated job before it is upgraded from `mix compile` to `mix test`, preventing Phoenix flakiness from coupling to the engine's required proof lanes.

---

## Key Findings

### Recommended Stack

No new runtime Hex dependencies at the core library level. The entire v2.4 scope is implementable with existing pipeline infrastructure. The only stack changes are scoped to `examples/phoenix_example/mix.exs` (Phoenix constraint update from `~> 1.7` to `~> 1.8`, Jason from `~> 1.2` to `~> 1.4`, Elixir minimum from `~> 1.15` to `~> 1.19`) and a cosmetic ExDoc lock bump. Elixir stays at 1.19.5 (1.20 is still RC); OTP stays at 28; all CI runner pins unchanged.

**Core technologies (no change):**
- Elixir `~> 1.19` (locked 1.19.5) — core language; 1.20.0-rc.6 not yet stable, stay on 1.19.5 for v2.4
- OTP 28 CI pin — resolves to 28.5.0.1; no reason to move to OTP 29 in v2.4
- `telemetry ~> 1.4` — existing pipeline hooks cover new recipe and primitive telemetry
- `harfbuzz_ex ~> 1.2` — text measurement in recipes uses existing shaper unchanged
- All dev/test deps unchanged (`stream_data`, `credo`, `dialyxir`, `jsv`, `yaml_elixir`, `req`)

**Reference app scoped additions (phoenix_example only):**
- Phoenix: update constraint to `~> 1.8` (latest stable 1.8.7 as of 2026-05-06)
- Jason: update constraint to `~> 1.4` (latest 1.4.5 as of 2026-05-05)
- Elixir minimum: align to `~> 1.19` to match core

See `.planning/research/STACK.md` for full version compatibility table.

### Expected Features

**Must have (table stakes for v2.4 milestone):**
- `{{page_number}}` and `{{total_pages}}` token substitution in header/footer regions (single-pass deferred injection, post-measurement, post-pagination)
- `body_capacity` correctly derived by subtracting all non-body region heights
- Statement recipe: transaction line table with running balance, "Page X of Y" footer, balance carried forward/brought forward at page breaks (pre-computed in `sections/2`, not in engine)
- Receipt/Report recipe: itemized lines + payment block (single-page receipt), repeating column headers + "Page X of Y" (multi-page report variant)
- Certificate recipe: fixed-layout single page using `Rendro.fixed/2`, all coordinates derived from template geometry (no hardcoded A4 numerics), recipient name as hero element, issuer identity, signature line
- Phoenix reference app exercising all five recipes with `mix test` smoke suite in isolated CI job
- All new public surfaces covered in `priv/support_matrix.json` (either `supported` with evidence or `explicit_deferral` with named reason)

**Should have (add during v2.4 if schedule allows):**
- "Continued" marker on table splits (low effort, recipe-level decoration)
- Aging summary panel (current/30/60/90 day buckets) on Statement final page
- QR code image placement on Certificate (caller-generated, recipe positions it)
- Statement zero-balance guard in `document/2`
- Report group subtotals with pre-grouped data shape

**Defer (post-v2.4):**
- Even/odd header content variants (book-style duplex)
- Section-local page number restart
- Decorative border frame on Certificate (depends on drawn-path primitive)
- Chart/graph rendering in Report body (major new rendering surface)
- Table of contents with page numbers (forward-reference, multi-pass concern)
- Certificate "theme gallery" or style picker (WYSIWYG territory)
- Multi-signature / HSM / global text shaping — explicitly out of scope per STATE.md

See `.planning/research/FEATURES.md` for full prioritization matrix and anti-feature rationale.

### Architecture Approach

The single seam for all v2.4 work is `Rendro.Pipeline.Paginate` plus the recipe layer. No new pipeline stages. No second render path. No new public struct fields on `%Rendro.Document{}`. The `replace_page_numbers/2` private function is renamed to `replace_running_tokens/3` with a new `total_pages` parameter added to `apply_page_template/4`. The callsite in `paginate_flow/1` binds `total_pages = length(pages)` after `Enum.reverse()` and passes it through. Everything else is additive new files.

**Major components and their responsibilities:**

1. `Rendro.Pipeline.Paginate` (modified) — rename `replace_page_numbers/2` to `replace_running_tokens/3`; add `total_pages` parameter; fix `body_capacity` derivation to subtract non-body region heights; backward-compatible (`{{page_number}}` behavior unchanged)
2. `Rendro.Recipes.Base` (new, `@moduledoc false`) — shared `assemble_document/3` helper extracted from Invoice/BrandedInvoice duplication; not public API
3. `Rendro.Recipes.Statement` / `Receipt` / `Certificate` (new) — three-rung pattern (`document/2` / `page_template/1` / `sections/2`); `sections/2` pre-computes carried totals from data before building blocks; Certificate derives all coordinates from template geometry
4. `examples/phoenix_example` (modified) — new controllers for three recipes; new `test/` directory with render smoke tests; README; CI upgraded to `mix test` inside isolated `example-phoenix` job

**Key pattern: carried-forward totals are data assembly, not engine state.** The Statement recipe's `sections/2` groups line items, computes opening and closing balances per page group, and passes pre-computed strings into content blocks. The engine sees only blocks with resolved strings — it never accumulates numeric running state across page breaks. This boundary must be documented in each recipe's `@moduledoc`.

See `.planning/research/ARCHITECTURE.md` for full system diagram and component classification table.

### Critical Pitfalls

1. **`body_capacity` not subtracting footer/header region heights** — `flow_layout/1` in `paginate.ex` derives `body_capacity` from `template.height - margin_top - margin_bottom` only. Default regions have zero height so this has been invisible. Any recipe with a real-height running footer will silently overlap the last body lines. Fix in Phase 73 as a required exit criterion. Test with explicit 36pt footer on a multi-page document.

2. **Running totals implemented in engine rather than data assembly** — Adding `running_state` accumulator to the paginator or `on_carry_forward:` callbacks to recipes leaks domain logic into the engine, breaks stage immutability, and widens `%Rendro.Document{}`. Pre-compute all per-page totals in `sections/2` before constructing blocks. Document this contract in each recipe's `@moduledoc`.

3. **Certificate coordinates hardcoded for A4** — Fixed-layout coordinates that are literal numbers (multiples of 595.28 or 841.89) break silently at US Letter and custom page sizes. All certificate coordinates must be derived from `template.width`, `template.height`, and margin fields. Add a multi-page-size test (A4 + US Letter) as an exit criterion for Phase 76.

4. **Phoenix example blocking core proof lanes** — Keeping "Verify Phoenix Example" as a step in the `test` job after upgrading to `mix test` means Phoenix flakiness can block `signing-live-proof` and `long-lived-live-proof`. Move to an isolated `example-phoenix` job (not a required branch-protection check) before upgrading scope.

5. **Recipe API widening into config-soup** — `opts` to `document/2` must be limited to structural layout overrides that map to `%PageTemplate{}` fields. Content or styling decisions belong in the three-rung escape hatch (`sections/2` override), not in `opts`. No recipe module may import Phoenix, Oban, or Gettext. Document the escape-hatch pattern prominently.

6. **Support-matrix gaps for new surfaces** — Every new public surface (running-header, running-footer, Statement, Receipt/Report, Certificate) needs an entry in `priv/support_matrix.json` before the phase closes — either `supported` with recorded evidence or `explicit_deferral` with a named reason. No new surface ships as a silent gap.

See `.planning/research/PITFALLS.md` for the full ten-pitfall list, recovery strategies, and "looks done but isn't" checklist.

---

## Implications for Roadmap

Based on combined research, the phase structure is firm because of hard dependency constraints: recipes use `{{total_pages}}`; the Paginate modification must be proven before any multi-page recipe can use it. Certificate is independent but benefits from the `Rendro.Recipes.Base` extraction. The reference app cannot demonstrate recipes that do not yet exist.

### Phase 73: Page-Numbering / Running-Region Primitive

**Rationale:** Foundation all multi-page recipes depend on. Must be green and fully tested before recipe work begins. The `body_capacity` prerequisite bug must be fixed here.

**Delivers:** `{{page_number}}` and `{{total_pages}}` token substitution via single-pass injection; corrected `body_capacity` derivation subtracting non-body region heights; `replace_running_tokens/3` replacing `replace_page_numbers/2`; unit tests across 1-page, multi-page, varying digit-count total scenarios; determinism regression test (render twice with `deterministic: true`, assert binary equality); support-matrix rows for running-header and running-footer surfaces; guide entry.

**Addresses:** Page X of Y (table stakes), repeated static header region, footer/header suppress option

**Avoids:** Pitfall 1 (convergence/wrong count — resolved as non-issue via single-pass confirmation), Pitfall 2 (body_capacity/footer-height gap — fixed here), Pitfall 5 (determinism regression), Pitfall 9 (support-matrix gap)

**Research flag:** Standard. All patterns confirmed from direct `paginate.ex` inspection.

---

### Phase 74: Recipe Base Extraction (Refactor)

**Rationale:** Pure refactor with no behavior change. Extract the shared `assemble_document/3` loop from Invoice and BrandedInvoice before three new consumers are built. De-risks extraction with only two existing consumers and all existing docs-contract tests as the safety net.

**Delivers:** `lib/rendro/recipes/base.ex` (`@moduledoc false`); Invoice and BrandedInvoice refactored to use it; all existing docs-contract tests pass unchanged.

**Avoids:** Recipe duplication that becomes maintenance burden under three new consumers

**Research flag:** Standard. Pure refactor.

---

### Phase 75: Statement Recipe

**Rationale:** Highest-value multi-page recipe; first exercise of `{{total_pages}}` in a full recipe; most complex recipe due to carried-forward totals discipline.

**Delivers:** `Rendro.Recipes.Statement` with three-rung pattern; `{{page_number}}/{{total_pages}}` in footer; running balance column pre-computed from data in `sections/2`; balance carried forward/brought forward as explicit content blocks at page-group boundaries (not engine-computed); docs-contract test; zero-balance guard; support-matrix row; guide entry.

**Addresses:** Statement transaction table, running balance, "Page X of Y" footer, balance C/F and B/F

**Avoids:** Pitfall 3 (carried totals in engine — no accumulator in recipe; `@moduledoc` must state pre-computation contract), Pitfall 6 (recipe API widening)

**Research flag:** Standard. Three-rung pattern and data-assembly carried-totals contract are well-understood.

---

### Phase 76: Receipt/Report and Certificate Recipes

**Rationale:** Lower complexity; Certificate is fully independent of Phase 73 but benefits from Phase 74; batched together to reduce ceremony overhead.

**Delivers:** `Rendro.Recipes.Receipt` (single-page receipt + multi-page report variant with repeating headers); `Rendro.Recipes.Certificate` (fixed-layout, all coordinates derived from template geometry, tested at A4 and US Letter); docs-contract tests for both; support-matrix rows; guide entries.

**Addresses:** Receipt fields (IRS-aligned), Report column headers + grand total, Certificate fixed layout, recipient name hero element, issuer identity, signature line, no page-number footer

**Avoids:** Pitfall 4 (Certificate fixed-coordinate brittleness — multi-size test is a required exit criterion), Pitfall 6 (recipe API widening)

**Research flag:** Standard for both. Certificate coordinate derivation pattern is well-understood.

---

### Phase 77: Reference Phoenix App and CI Upgrade

**Rationale:** Depends on all five recipes existing. Isolated entirely to `examples/phoenix_example/`. No core changes. CI isolation must happen before upgrading from `mix compile` to `mix test`.

**Delivers:** New controllers for Statement, Receipt/Report, Certificate; `examples/phoenix_example/test/` with render smoke tests for all five recipes; `examples/phoenix_example/README.md` with `mix deps.get && mix phx.server` instructions; `mix.exs` constraint updates (Phoenix `~> 1.8`, Jason `~> 1.4`, Elixir `~> 1.19`); `example-phoenix` isolated CI job (separate from `test` job, not a required branch-protection check); ExDoc extras wiring for three new recipe guides.

**Addresses:** All five recipes exercised in CI, adoption reference app for new users, README honesty review

**Avoids:** Pitfall 7 (Phoenix leaking into core), Pitfall 8 (reference app drift and overclaim — README must mirror support matrix), Pitfall 10 (CI job coupling — isolated job before `mix test` upgrade)

**Research flag:** Standard. CI YAML job isolation is a well-documented GitHub Actions pattern.

---

### Phase Ordering Rationale

- Phase 73 must precede Phases 75 and 76 multi-page variants because they depend on `{{total_pages}}` and the corrected `body_capacity` derivation.
- Phase 74 must precede Phases 75 and 76 because new recipes are the first consumers of `Rendro.Recipes.Base`; extracting after three new consumers exist is harder.
- Phase 76 (Certificate) is independent of Phase 73 but benefits from Phase 74; batched with Receipt for efficiency.
- Phase 77 must follow all recipe phases; it cannot demonstrate recipes that do not yet exist.
- The existing required CI lanes (`test`, `signing-live-proof`, `long-lived-live-proof`, `viewer-evidence-live-proof`, `release-proof`) must remain green and unaffected throughout all phases.

### Research Flags

All phases in this milestone have standard, well-documented patterns. No phase requires a `/gsd-plan-phase --research-phase` invocation. All key technical questions were resolved during this research round via direct codebase inspection.

---

## Open Questions for Requirements/Roadmap Decisions

These are not blockers but benefit from explicit resolution before implementation begins:

1. **Scope of `carried_forward.<key>` tokens.** STACK.md proposes a `{{carried_forward.<key>}}` interpolation token backed by a caller-supplied map. This widens the token namespace. Decision needed: implement generic `carried_forward` tokens in the engine, or keep carried totals entirely in recipe data assembly with no engine-level token? The data-assembly approach (ARCHITECTURE/PITFALLS consensus) is safer and sufficient for all three recipes.

2. **Max total-page-count digit reserve.** Even though a reserved-width placeholder is not required for pagination correctness, it is cosmetically desirable (ensures the rendered glyph string fits its pre-measured run width). Decision needed: should the authoring API accept a `max_pages:` hint that pads `{{total_pages}}` output to a fixed width? What is the appropriate default digit reserve?

3. **Certificate page size as required parameter vs. default.** The `page_template/1` function must accept `width:` and `height:` overrides. Decision needed: require explicit page size (no default) to force intent, or default to A4 with an override option? Defaulting to A4 is acceptable as long as all coordinates are geometry-derived, not hardcoded A4 numerics.

4. **Page-number authoring API shape.** Should the API expose a named helper (`Rendro.page_number(format: "Page ~p of ~t")`), a raw anonymous function receiving `{page, total}`, or both? A named helper is more discoverable for recipe authors. Both can coexist: the helper returns a function the region-content mechanism accepts. This decision affects what is a stable public API surface for v2.4 and must be resolved before Phase 73 API surface is finalized.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All version pins verified against Hex.pm and GitHub releases as of 2026-05-29. Pure-core determination derives from direct paginate.ex inspection. |
| Features | HIGH | Page-numbering mechanics verified across ReportLab, fpdf2, Prawn, wkhtmltopdf. Document field structures verified against industry templates and accounting standards. |
| Architecture | HIGH | All findings based on direct source inspection of live codebase. Single-pass total_pages availability confirmed by reading paginate_flow/1 line by line. |
| Pitfalls | HIGH | Grounded in direct codebase inspection. body_capacity gap confirmed from flow_layout/1 derivation. CI coupling risk confirmed from ci.yml structure. |

**Overall confidence:** HIGH

### Gaps to Address

- **Page-number authoring API shape:** The `Rendro.page_number/1` named helper vs. raw function vs. both question should be resolved in Phase 73 requirements before implementation starts. This affects what counts as a stable public API surface for v2.4.
- **`body_capacity` fix location:** The fix is straightforward but should be confirmed during Phase 73 planning — the derivation in `flow_layout/1` is in `paginate.ex`, but the compose stage builds `layout.body_region`. Confirm the correct fix location (paginate vs. compose) before implementation.
- **`maybe_validate_region_fit` interaction with footer blocks:** After `apply_page_template` anchors footer blocks, `maybe_validate_region_fit` is called. Confirm during Phase 73 that this validation path is exercised in tests with a non-zero footer height to catch any remaining overlap edge cases.

---

## Sources

### Primary (HIGH confidence — direct codebase inspection)

- `lib/rendro/pipeline/paginate.ex` — `paginate_flow/1`, `replace_page_numbers/2`, `apply_page_template/3`, `flow_layout/1`, `body_capacity` derivation
- `lib/rendro/pipeline/pipeline.ex` — stage sequencing
- `lib/rendro/pipeline/compose.ex` — `region_blocks` assembly
- `lib/rendro/pipeline/measure.ex` — token strings survive measurement
- `lib/rendro/recipes/invoice.ex` — three-rung pattern canonical implementation
- `lib/rendro/recipes/branded_invoice.ex` — three-rung pattern with extra_setup
- `lib/rendro/recipes.ex` — delegate facade
- `lib/rendro/document.ex` — `%Document{}` struct fields
- `lib/rendro/adapters/phoenix.ex` — `Code.ensure_loaded?` guard pattern
- `examples/phoenix_example/mix.exs` — path dep, isolation boundary
- `.github/workflows/ci.yml` — existing `test` job structure, "Verify Phoenix Example" step
- `.planning/PROJECT.md` — non-negotiable constraints
- `.planning/STATE.md` — diminishing-returns guidance and adoption ergonomics framing

### Primary (HIGH confidence — official sources, verified 2026-05-29)

- hex.pm/packages/phoenix/versions — Phoenix 1.8.7 as of 2026-05-06
- hex.pm/packages/bandit — Bandit 1.11.1 as of 2026-05-13
- hex.pm/packages/jason — Jason 1.4.5 as of 2026-05-05
- hex.pm/packages/ex_doc — ExDoc 0.40.3 as of 2026-05-21
- hex.pm/packages/oban — Oban 2.23.0 as of 2026-05-27
- github.com/elixir-lang/elixir/releases — Elixir 1.19.5 stable, 1.20.0-rc.6 pre-release
- erlang.org — OTP 28.5.0.1 as of 2026-05-27

### Secondary (MEDIUM confidence — domain knowledge, consistent with codebase design)

- fpdf2 `alias_nb_pages` reserved-width approach — consistent with single-pass post-pagination substitution
- ReportLab deferred canvas two-pass pattern — confirms total count available before first byte written
- Prawn `number_pages` post-render stamp — structural comparison
- Statement of account structure: zoho.com/books/academy, accountingcapital.com (balance C/F and B/F convention)
- Payment receipt required fields: stripe.com/resources/more/receipt-template
- Completion certificate structure: sertifier.com

---

*Research completed: 2026-05-29*
*Ready for roadmap: yes*
