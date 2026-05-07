# Plan: Phase 29 Gap Closure — Header-Wrap Fix (Plan 29-08)

## Mode

`gap_closure` (executed by `/gsd-execute-phase 29 --gaps-only`)

## Output Path

```
.planning/phases/29-branded-recipes-docs-and-proof-closure/29-08-header-wrap-gap-fix-PLAN.md
```

## In Scope (and only this)

UAT Gap 2 — header wrap defect:

> "Branded invoice header text fits the header region without breaking the
> invoice id mid-token."

The header text `"Rendro, Inc.\nInvoice #INV-2026-001"` rendered at size 18 in
B612 Regular wraps inside a `width: 260` block (`branded_invoice.ex:123`).
Because `"Invoice #INV-2026-001"` measured at size 18 in B612 exceeds 260pt,
`split_chunk` falls through to `split_graphemes` and the invoice id breaks at
a character boundary (`#INV-2026-0` / `01`), per UAT root cause analysis.

## Explicitly Out of Scope (deferred to Phase 30)

- Logo not rendering (UAT Gap 1, `status: deferred`).
- All `lib/rendro/pdf/writer.ex` PNG/`build_image_objects` changes.
- Adding `break_inside_word: false` to `Rendro.Text` (UAT explicitly rejects
  this scope for the gap fix).
- ~~Splitting title and id into two stacked `Rendro.block` fragments~~
  **LIFTED in Plan v2** — see "Plan Amendment v2" below. Stacked-block
  composition is the recommended fix.
- Any rasterize-and-decode regression class. That belongs to Phase 30.

The plan must contain a `## Out of Scope` section that mirrors the bullets
above so the gap executor cannot drift into Phase 30 territory.

---

## Plan Amendment v2 (after Task 1 contingency triggered)

### Why amended

Task 1 probe measured `"Invoice #INV-2026-001"` at **423.0pt** in B612 Regular @ size 18 — far above the plan author's predicted 290–330pt range and above the
geometric ceiling (371.28pt at `x: 152` on A4). The recipe-only width fix is
mathematically impossible at size 18.

Three parallel research streams converged on a single answer:

1. **Empirical (Rendro pipeline)** — stacked blocks with no width raise
   `Rendro.Error{stage: :paginate, reason: :content_overflow}` (truthful-fit
   catches it). Stacked blocks with `width: 371.28` wrap cleanly — id stays
   intact, no grapheme split.
2. **In-codebase pattern** — the unbranded `Rendro.Recipes.Invoice` sibling
   recipe (`lib/rendro/recipes/invoice.ex:111-119`) already uses two stacked
   blocks with no width and differentiated sizes. The branded variant was
   the outlier with its `\n`-jammed single block.
3. **Industry survey** — every popular PDF library (Prawn, ReportLab, PDFKit,
   react-pdf, jsPDF, LaTeX scrlttr2) and every production SaaS template
   (FreshBooks, Wave, QuickBooks, HubSpot 28-sample roundup) stacks brand
   and invoice id with id at 10–14pt — strictly smaller than brand. Uniform
   18pt brand+id is the one shape no production template ships.

### What changes (v2)

- **Out of Scope** — strike the "stacked blocks" bullet (see strikethrough
  above). Side-by-side (brand-left / id-right) header layouts remain out of
  scope; the canonical recipe ships the stacked variant only.
- **`must_haves.truths`** — replace size-18 truth on the id with:
  - "Branded invoice header renders 'Invoice #INV-{id}' on a single line for
    the canonical sample id; brand renders at size 18 and id renders at
    size ≤ 14 in B612 Regular per industry-standard invoice typography
    (id strictly smaller than brand)."
  - "Each header block sizes to its natural text width and is independently
    fit-validated against the `:header` region by `Rendro.Pipeline.Paginate`."
- **Implementation** — Task 2 now stacks the header into THREE blocks
  (brand, id, date) at sizes (18, 12, 10) with no explicit `width:` — each
  block sizes to natural text width and is paginate-fit-validated.
- Region geometry (`:header` x:152, width:371.28) is unchanged. No Phase 30
  logo collision.

---

## Wave Structure (single plan, three sequential tasks)

```
Wave 1: 29-08 (Task 1: Probe → Task 2: Fix → Task 3: Verify)
```

`autonomous: true` (no checkpoints — `mix rendro.visual_uat` is gated on
`ANTHROPIC_API_KEY` and `pdftoppm` and is run opportunistically, not as a
blocking step).

---

## Frontmatter to Write

```yaml
---
phase: 29-branded-recipes-docs-and-proof-closure
plan: 8
type: execute
wave: 1
depends_on: [29-07]
gap_closure: true
files_modified:
  - lib/rendro/recipes/branded_invoice.ex
  - test/rendro/recipes/branded_invoice_test.exs
autonomous: true
requirements: [LAY-13]
must_haves:
  truths:
    - "Branded invoice header renders 'Invoice #INV-{id}' on a single line for the canonical sample id at size 18 in B612 Regular."
    - "Header block width in lib/rendro/recipes/branded_invoice.ex is wide enough to fit 'Invoice #INV-2026-001' at size 18 with measured B612 metrics, with the chosen value documented in the source via comment."
    - "branded_invoice_test.exs no longer asserts the broken three-line wrap (length(tl(lines)) > 1) and instead asserts the id stays intact."
    - "All previously passing branded_invoice tests continue to pass; deterministic two-render parity is preserved."
  artifacts:
    - path: "lib/rendro/recipes/branded_invoice.ex"
      provides: "header_section/1 with widened block width and explanatory comment"
      contains: "Rendro.block("
    - path: "test/rendro/recipes/branded_invoice_test.exs"
      provides: "Updated regression assertion that the invoice id stays on one line"
      contains: "Invoice #INV-2026-042"
  key_links:
    - from: "lib/rendro/recipes/branded_invoice.ex header_section/1"
      to: "Rendro.Pipeline.Measure.wrap_text/4"
      via: "block.width passed to measure_block which feeds wrap_text"
      pattern: "Rendro\\.block\\(.*width: [0-9]+"
---
```

Note `requirements: [LAY-13]` — the gap is a defect against the LAY-13
"branded canonical recipe" requirement that Phase 29 already claimed; the gap
closure restores that claim. We do NOT add a new requirement ID.

---

## Tasks

### Task 1 — Probe B612 metrics and choose a defensible width

**type:** `auto`
**files:** none (read-only probe via `mix run` script in `/tmp`)

**action:**

1. The UAT recommends widening to ~340pt but explicitly says: "Verify the
   recommended numeric width by computing the actual rendered width." Do that
   measurement. Do NOT copy 340 blindly.
2. From within the project root, run a one-shot probe to print the measured
   width of the worst-case header strings using the *actual* font/metrics
   path the recipe uses. Use `mix run -e` so `Rendro` and the embedded font
   asset path resolve normally:

   Drive the probe through a real recipe document so
   `Rendro.Pipeline.Build.run/1` accepts it — an empty
   `Rendro.Document.new()` would be rejected with `{:error, :no_pages}`
   per `lib/rendro/pipeline/build.ex:49`:

   ```sh
   mix run -e '
   alias Rendro.PDF.Font
   alias Rendro.FontRegistry

   data = %{
     id: "INV-2026-001",
     date: ~D[2026-04-30],
     items: [],
     brand: %{font_name: :brand_heading, logo_name: :company_logo}
   }

   {:ok, built} =
     data
     |> Rendro.Recipes.BrandedInvoice.document()
     |> Rendro.Pipeline.Build.run()

   {:ok, [font | _]} =
     FontRegistry.resolve_pdf_font_chain(built.font_registry, :brand_heading, built.default_font)

   strings = [
     "Rendro, Inc.",
     "Invoice #INV-2026-001",
     "Invoice #INV-2026-042",
     "Invoice #INV-9999-9999"
   ]

   for s <- strings do
     IO.puts("#{Float.round(Font.text_width(font, s, 18), 2)}\t#{s}")
   end
   '
   ```

   The recipe document carries a page template, sections, and the
   registered embedded font, so `Build.run/1`'s preflight (`pages != [] or
   content != [] or sections != []`) passes and `font_registry` arrives
   populated with a parsed `%Rendro.PDF.Font{}` entry — which is what
   `Font.text_width/3` needs.

3. Record the printed width of `"Invoice #INV-2026-001"` (the canonical UAT
   string from `29-branded-preview.png`) and `"Invoice #INV-2026-042"` (the
   sample-data string used by the test). Pick a single block width that:
   - Fits BOTH strings + at least 4pt safety margin (covers minor metric
     drift between B612 builds and the line-break decision boundary).
   - Stays inside the header region's geometry: header region is
     `x: 152, width: 371.28` (`branded_invoice.ex:53`), so the block width
     MUST be `<= 371.28`. **Hard ceiling: 371.**
   - Is rounded to a whole pt for readability.

4. Document the chosen width in the source as a code comment immediately
   above the `width:` argument, e.g.:

   ```elixir
   # B612 Regular @ size 18: "Invoice #INV-2026-XXX" measures ~{N}pt;
   # widened from 260 to {chosen} to keep the id on a single line.
   # Header region is 371.28pt wide (see page_template/1), which is the
   # hard upper bound for this block.
   width: {chosen}
   ```

5. If the measured width of either string is `> 371` (the region ceiling):
   STOP and surface this as a gap-closure escalation in the executor
   summary. The recipe-only fix is no longer sufficient; widening the
   region is now in scope and Task 2 must also patch the `:header` region
   `width:` in `page_template/1`. (Treat this as a contingency, not an
   expected outcome — B612 Regular at size 18 should land in the
   ~290–330pt range for this string, well under 371.)

**verify:**

```xml
<verify>
  <automated>
    # Re-run the probe and assert that at least one numeric width printed
    # so the executor cannot silently skip the measurement step.
    mix run -e '
    data = %{id: "INV-2026-001", date: ~D[2026-04-30], items: [], brand: %{font_name: :brand_heading, logo_name: :company_logo}}
    {:ok, built} = data |> Rendro.Recipes.BrandedInvoice.document() |> Rendro.Pipeline.Build.run()
    {:ok, [font | _]} = Rendro.FontRegistry.resolve_pdf_font_chain(built.font_registry, :brand_heading, built.default_font)
    w = Rendro.PDF.Font.text_width(font, "Invoice #INV-2026-001", 18)
    IO.puts("PROBE_WIDTH=#{Float.round(w, 2)}")
    ' | grep -E "^PROBE_WIDTH=[0-9]+\.[0-9]+$"
  </automated>
</verify>
```

**done:**

- A measured width for `"Invoice #INV-2026-001"` and `"Invoice #INV-2026-042"`
  at size 18 in B612 Regular is printed in the run log.
- A specific integer pt value for the new block width is chosen and recorded
  in the task summary, with arithmetic shown (`measured_max + safety = N`).
- Chosen value `<= 371`. If not, escalate before proceeding.

---

### Task 2 — Apply the fix to recipe and test

**type:** `auto`
**files:**

- `lib/rendro/recipes/branded_invoice.ex`
- `test/rendro/recipes/branded_invoice_test.exs`

**action:**

#### 2a. `lib/rendro/recipes/branded_invoice.ex`

Edit `header_section/1` (lines 116–128). Replace the `Rendro.block(...)` call
with the widened block + explanatory comment.

**Before (lines 121–124):**

```elixir
        Rendro.block(
          Rendro.text("Rendro, Inc.\nInvoice ##{id}", font: font_name, size: 18),
          width: 260
        ),
```

**After (use the value chosen in Task 1; the example below assumes 340 — replace with the Task 1 result):**

```elixir
        # B612 Regular @ size 18: "Invoice #INV-2026-XXX" measures ~{measured}pt
        # at the rendered runs path. Widened from 260 to {chosen} so the
        # invoice id renders on a single line. Header region width is 371.28pt
        # (see page_template/1) — that is the hard upper bound for this block.
        Rendro.block(
          Rendro.text("Rendro, Inc.\nInvoice ##{id}", font: font_name, size: 18),
          width: {chosen}
        ),
```

Do NOT touch any other line of this file. Do NOT change `header_section/1`'s
function signature, the date sub-block, the `:header` region in
`page_template/1` (unless Task 1 contingency triggered), or the docstring
examples.

#### 2b. `test/rendro/recipes/branded_invoice_test.exs`

Edit the `regression: full-pipeline render` test (lines 115–149). The current
assertions on lines 144–148 lock in the broken wrap.

**Before (lines 144–148):**

```elixir
      lines = Enum.map(header_block.content.lines, fn line -> Enum.map_join(line, "", & &1.text) end)

      assert hd(lines) == "Rendro, Inc."
      assert Enum.join(tl(lines), "") == "Invoice #INV-2026-042"
      assert length(tl(lines)) > 1
```

**After:**

```elixir
      lines = Enum.map(header_block.content.lines, fn line -> Enum.map_join(line, "", & &1.text) end)

      # The header block is wide enough to render the invoice id on a single
      # line. Two lines total: title, then the full id intact. This pins the
      # fix for UAT Gap 2 (29-HUMAN-UAT.md).
      assert lines == ["Rendro, Inc.", "Invoice #INV-2026-042"]
```

Rationale for the exact assertion shape:

- `assert lines == ["Rendro, Inc.", "Invoice #INV-2026-042"]` is strictly
  stronger than `assert "Invoice #INV-2026-042" in lines` (UAT alternative).
  It pins both line count and content, preventing a future regression that
  splits onto three lines for any other reason (e.g. an unrelated line-height
  bug) from passing this test.
- Replacing `length(tl(lines)) > 1` (which REQUIRED the broken wrap) with the
  exact equality check directly inverts the previously-locked-in defect.

Do NOT touch any other test in the file. Doctests, validation tests, and the
byte-identical two-render test must remain unchanged.

**verify:**

```xml
<verify>
  <automated>mix test test/rendro/recipes/branded_invoice_test.exs</automated>
</verify>
```

**done:**

- `lib/rendro/recipes/branded_invoice.ex` line 123 (and surrounding context)
  now uses the Task 1–chosen width with the documented comment.
- `test/rendro/recipes/branded_invoice_test.exs` line 148 no longer asserts
  `length(tl(lines)) > 1`.
- `mix test test/rendro/recipes/branded_invoice_test.exs` passes — including
  the doctests, validation tests, and byte-identical two-render test (no
  collateral damage).

---

### Task 3 — Verify the fix end-to-end

**type:** `auto`
**files:** none (verification only)

**action:**

Run the broader regression suites that touch this recipe to confirm no
collateral damage. Then opportunistically run the visual UAT pipeline to
re-grade Gap 2.

1. Targeted suite — must pass:
   ```sh
   mix test test/rendro/recipes/branded_invoice_test.exs \
            test/rendro/branded_test.exs \
            test/docs_contract/branding_contract_test.exs \
            test/docs_contract/branding_claims_test.exs
   ```

2. Full suite — must pass with the same pass count as Phase 29 verification
   (411 tests, 0 failures, per `29-VERIFICATION.md`):
   ```sh
   mix test
   ```

3. Phoenix example suite — must continue to pass (downstream consumer of the
   recipe):
   ```sh
   cd examples/phoenix_example && mix compile --warnings-as-errors && mix test
   ```

4. Visual UAT (opportunistic — only if `pdftoppm` and `ANTHROPIC_API_KEY`
   are available; otherwise note "skipped: env"):
   ```sh
   mix rendro.visual_uat 29
   ```

   This will overwrite `29-branded-preview.png` and write a fresh verdict
   into `29-HUMAN-UAT.md`. Expected outcome on the header criterion only:
   `layout_intentional: true` and the `layout_notes` no longer mention an
   id mid-token break.

   The logo criterion (`logo_present: false`) is EXPECTED to remain failing
   — that gap is deferred to Phase 30 and is NOT part of this plan's
   acceptance criteria. The executor must not edit `29-HUMAN-UAT.md` to
   suppress or rewrite the logo gap; the visual UAT task itself is the
   only writer of that file.

**verify:**

```xml
<verify>
  <automated>
    mix test test/rendro/recipes/branded_invoice_test.exs test/rendro/branded_test.exs test/docs_contract/branding_contract_test.exs test/docs_contract/branding_claims_test.exs && mix test
  </automated>
</verify>
```

**done:**

- All four targeted suites pass.
- `mix test` reports `411 tests, 0 failures` (or whatever count current
  `main` reports for unaffected baseline; deviation from 411 must be
  explained as new tests added by other branches, not failures).
- Phoenix example suite passes with `--warnings-as-errors`.
- If visual UAT was runnable: `29-HUMAN-UAT.md`'s most recent verdict shows
  the header gap as resolved (`layout_intentional: true` AND `layout_notes`
  describes the id staying intact). If not runnable, the executor records
  "visual UAT skipped: missing env (pdftoppm or ANTHROPIC_API_KEY)" in the
  plan summary and the targeted/full mix test runs are sufficient acceptance.

---

## Acceptance Criteria (whole plan)

1. `lib/rendro/recipes/branded_invoice.ex` line ~123 has `width: {chosen}`
   where `{chosen}` is justified by measured B612 metrics and documented in
   a code comment.
2. `test/rendro/recipes/branded_invoice_test.exs` no longer contains
   `length(tl(lines)) > 1`.
3. `mix test` passes at the same pass count as the existing Phase 29
   baseline.
4. The header rendering produces exactly two lines: `"Rendro, Inc."` and
   `"Invoice #INV-2026-{id}"` for the test's sample id.
5. No edits made to `lib/rendro/pdf/writer.ex`, the `:header` region (unless
   Task 1 contingency triggered), or any file outside the two listed in
   `files_modified`.
6. Phase 30's logo gap is left untouched; `29-HUMAN-UAT.md` Gap 1 entry
   remains `status: deferred`.

---

## Verification Commands (summary block in PLAN.md)

```sh
# Targeted regression suite
mix test test/rendro/recipes/branded_invoice_test.exs \
         test/rendro/branded_test.exs \
         test/docs_contract/branding_contract_test.exs \
         test/docs_contract/branding_claims_test.exs

# Full suite (must remain at 0 failures)
mix test

# Phoenix example proof
cd examples/phoenix_example && mix compile --warnings-as-errors && mix test

# Optional: re-grade visual UAT (requires pdftoppm + ANTHROPIC_API_KEY)
mix rendro.visual_uat 29
```

---

## Threat Model

`security_enforcement` is not asserted in `.planning/STATE.md` for this
project, but for completeness:

| Boundary | Description |
|----------|-------------|
| User-supplied invoice id | Crosses into `header_section/1` via `data.id` and is interpolated into the header text. |

| Threat ID | Category | Component | Disposition | Mitigation |
|-----------|----------|-----------|-------------|------------|
| T-29-08-01 | T (Tampering) | header_section/1 width | accept | Width is a static integer literal in the recipe; no user input flows into it. Out of scope: ids longer than `INV-9999-9999` would still grapheme-split, but that is governed by the existing `split_graphemes` fallback and is not a regression introduced by this plan. |
| T-29-08-02 | I (Information disclosure) | header_section/1 text interpolation | accept | `data.id` is already trusted (validated upstream by recipe consumers) and is not rendered to a security boundary; PDFs do not execute embedded text. |

No new trust boundaries introduced; no new external dependencies.

---

## Source Audit

| Source | Item | Plan Coverage |
|--------|------|---------------|
| GOAL (ROADMAP) | "branded canonical recipe ... truthfully documented" | Restored via fix to `branded_invoice.ex` so the rendered output matches the documented intent. |
| REQ | LAY-13 (branded recipe) | Task 2a edits the recipe; Task 3 verifies via test suite. |
| UAT Gap 2 | Header wrap defect, `status: failed` | Closed by the entire plan. |
| UAT Gap 1 | Logo defect, `status: deferred` | Explicitly out of scope; deferred to Phase 30 (already on roadmap). |
| RESEARCH | n/a (no new research artifact for this gap closure) | — |
| CONTEXT | n/a (no D-XX decisions for this gap closure) | — |

No unplanned items. No phase split needed.

---

## Files Touched

- `lib/rendro/recipes/branded_invoice.ex` (1 small edit, ~5 lines incl. comment)
- `test/rendro/recipes/branded_invoice_test.exs` (1 small edit, ~3 lines)

Total context cost estimate: ~15% (tiny diff, two files, one regression suite,
one full suite). Well within budget.

---

## ROADMAP Update

After the plan is written and committed, append the new plan entry to the
Phase 29 plan list in `.planning/ROADMAP.md`:

```
- [ ] 29-08-header-wrap-gap-fix-PLAN.md — Close UAT Gap 2 by widening the branded invoice header block so the invoice id stays on a single line.
```

Update the `Plans:` count from `7` to `8`.

Do NOT alter the Phase 29 Goal text, Phase 30 entry, or any other phase.

---

## Summary of Decisions Embedded in This Plan

1. **One plan, three tasks.** Probe → Fix → Verify. Probe is mandatory because
   the user explicitly required the chosen width to be backed by measured
   font metrics, not the UAT's suggested 340.
2. **Hard ceiling at 371pt.** The header region is 371.28pt wide; the block
   cannot exceed that without overflowing the region. If the probe shows
   the string measures `> 371pt`, the recipe-only fix is insufficient and
   Task 1 escalates instead of silently widening the region.
3. **Stronger test assertion than UAT alternatives.** Use exact equality
   `lines == ["Rendro, Inc.", "Invoice #INV-2026-042"]` rather than
   `assert "Invoice #INV-2026-042" in lines` — pins line count and content
   to prevent future regressions.
4. **Logo gap stays deferred.** The plan explicitly forbids editing
   `lib/rendro/pdf/writer.ex` or the deferred UAT entry. Phase 30 owns it.
5. **Visual UAT is opportunistic, not blocking.** It depends on
   `pdftoppm` + `ANTHROPIC_API_KEY` env, which the executor may not have.
   Mix test suites are the authoritative acceptance gate.
