# Pitfalls Research — v2.4 Batteries-Included Workflow & Adoption Closure

**Domain:** Adding page-numbering/running-region primitives, business-document recipes, and a CI-run reference app to a deterministic, honesty-first PDF engine (Rendro v2.4)
**Researched:** 2026-05-29
**Confidence:** HIGH (based on direct codebase inspection + domain knowledge of deterministic layout engines)

## Scope of This Document

These pitfalls are specific to **adding page-numbering/running-header-footer primitives, three production recipes (Statement, Receipt/Report, Certificate), and a CI-exercised reference Phoenix app to a pure-Elixir deterministic PDF library that already ships a proof-backed trust stack and an explicit honesty culture.**

They are not generic PDF pitfalls. Each is grounded in what was found in the actual codebase:

- `{{page_number}}` is already substituted in `Pipeline.Paginate.replace_page_numbers/2` during `apply_page_template`, but there is **no `{{total_pages}}` equivalent** — the total is not yet known at substitution time during the single forward pass.
- Header/footer regions exist (`Rendro.Region` with `anchor: :top | :bottom`, `PageTemplate` with zero-height header/footer regions by default), but their height contributes to body capacity only if explicitly set — a zero-height header does not change `body_capacity`.
- The pipeline is a strict single linear pass: `build → compose → measure → paginate → render → validate`. `total_pages` requires knowing the pagination result before running it — a structural second-pass or fixpoint problem.
- Carried-forward running totals (statement balance-forward, subtotal-per-page) are a data-assembly concern, not an engine concern — but the boundary is subtle.
- The three-rung escape-hatch recipe pattern (`document/2` / `page_template/1` / `sections/2`) exists and works in `Rendro.Recipes.Invoice`. The same pattern must be followed exactly for new recipes.
- The Phoenix example compiles and CI verifies compile only (`mix compile`). It does not run `mix test` and has no docs-contract coverage.

Five non-negotiable guardrails from the project carry forward into every v2.4 pitfall:

1. Pure-Elixir core — no Phoenix, Oban, browser runtime, Python, or external binary hard dependencies in core or in recipe modules.
2. One pipeline: `build → compose → measure → paginate → render → validate`. No alternate rendering paths.
3. Determinism for unsigned render output — any new feature that introduces non-determinism must be explicitly labeled and separated.
4. Public claims must stay narrower than blanket support; new surfaces inherit the v2.3 viewer-evidence discipline.
5. The existing required CI lanes (`test`, `signing-live-proof`, `long-lived-live-proof`, `viewer-evidence-live-proof`, `release-proof`) must stay green and unaffected.

---

## Critical Pitfalls

### Pitfall 1: Total-Page-Count Resolution Breaking Determinism or Causing Infinite Layout Loops

**What goes wrong:**

"Page X of Y" requires the total page count `Y` at substitution time. The current pipeline resolves page numbers in `apply_page_template` during `paginate_flow`, which runs during the single `:paginate` stage — before the total count is known. A naive approach does one of two things, both wrong:

- **Pre-emptive lie:** Injects a placeholder for `{{total_pages}}` that mirrors `{{page_number}}` but resolves to the *current estimate* rather than the true final count. If body content causes a split near a page boundary, the estimate is wrong and "Page 3 of 4" appears on what is actually page 3 of 5.

- **Iterative convergence loop:** Run paginate, get total, substitute total, run paginate again to account for any layout change introduced by the substitution (e.g., "Page 10 of 100" is wider than "Page 1 of 9" and may cause line wrapping), repeat until stable. This loop has no guaranteed convergence. A pathological document where substituting total-page-count text causes the page count to increase (longer footer wraps, body capacity shrinks, one more page is added, "of 11" is wider than "of 10", repeat) can cycle indefinitely. Even when it does converge, it is multiple pipeline runs per render, which makes the "deterministic" guarantee harder to reason about and substantially more expensive.

- **Silent off-by-one:** Apply `length(pages)` after `Enum.reverse(pages)` but before `apply_page_template`, use that count as `total_pages`. Works for most documents. Fails when the final `apply_page_template` step causes a region overflow error that is handled by adding a continuation page — now the pre-computed total is wrong by one.

The actual failure mode adopters will experience: PDFs that say "Page 3 of 4" when there are 5 pages, or a render that hangs under production load when a subtly pathological document triggers the convergence loop.

**Why it happens:**

The pipeline is designed for a single forward pass. `total_pages` is a backward-looking aggregate. Developers reach for the most obvious extension of `replace_page_numbers` (add another `String.replace`) without realizing the total is not available at that call site. The existing `{{page_number}}` substitution works because page number is a forward-incrementing value known at substitution time; total pages is not.

**How to avoid:**

Use a **two-phase substitution strategy with a fixed geometry constraint**:

Phase 1 (pre-paginate): Measure the total-pages placeholder with the *widest possible rendered value* (the maximum digit count you will ever need, e.g. "999" or "9999" depending on document budget). Use this reserved-width placeholder throughout layout so that substituting the real total can never increase text width and therefore can never change page count.

Phase 2 (post-paginate, pre-render): After `paginate` completes and `length(pages)` is stable, do a final pass through all rendered page blocks to replace the reserved-width placeholder with the actual total. Since the placeholder was reserved at maximum width and the actual value is the same or narrower (it is always `<= total`), no layout change can occur. This substitution is safe to do as a post-paginate text-rewrite pass because it cannot trigger re-pagination.

This is the approach used by ReportLab (two-pass, reserved-width) and fpdf2 (`alias_nb_pages` reserve). It is the only approach that preserves single-pass semantics while allowing accurate total-count display.

Constraints to enforce at design time:
- The reserved-width placeholder must be measured and used in body capacity calculations exactly like any other text of that width. Do not let the placeholder participate in layout at zero width.
- The reserved width must be explicitly documented as a user-facing constraint: "total page count display reserves width for up to N digits; documents exceeding N pages will overflow the reserved region." This is an honesty constraint — do not silently truncate.
- The post-paginate substitution pass must be deterministic: same input document always produces the same substitution result.

**Warning signs:**

- Any code path that calls `Enum.count(pages)` or `length(pages)` and then injects that value into block text *before* `Enum.reverse(pages) |> Enum.with_index(1)` has completed (the current paginate call is still on the stack).
- A loop structure around `paginate_flow` that re-runs on "changed" count — convergence loops are a smell.
- `{{total_pages}}` implemented identically to `{{page_number}}` (just another `String.replace` in `replace_page_numbers`) without a reserved-width design.
- Tests only covering single-page or fixed-page-count documents — the error only manifests at boundary page counts.

**Phase to address:**
The page-numbering/running-header-footer primitive phase (the dedicated foundational phase before recipes). This must be fully resolved, tested across multi-page documents with varying digit-count totals, and documented before any recipe phase begins.

---

### Pitfall 2: Footer Height Changing Body Capacity After Pagination (Layout Invalidation)

**What goes wrong:**

The current `PageTemplate` ships with a zero-height header region and a zero-height footer region by default. When an adopter adds a running footer with real height (e.g., 36pt for "Page X of Y" text), that height must be subtracted from `body_capacity` *before* pagination runs. The trap: if the footer height is specified in the same data structure as the footer content, and both are processed together, it is possible to calculate `body_capacity` using the old (zero) footer height and then render a footer of actual height — meaning the footer silently overlaps the last N lines of body content on every page.

The paginator already computes `body_capacity = body_region.height` from `layout.body_region` (see `paginate_flow`). If `body_region.height` is not reduced to account for the running footer's height before body content is paginated, the body overflows into footer space.

Variant: a dynamically sized footer (one whose content height is data-dependent, e.g., a multi-line legal notice of variable length) will cause `body_capacity` to be different for different document instances, which is fine as long as the capacity is measured before pagination. The trap is a footer whose height is determined at measure time but applied to body capacity after pagination.

**Why it happens:**

The `PageTemplate.regions` struct is a static list. Footer height is `0` by default and may be overridden. But nothing in the current pipeline enforces that if you set `footer.height = 36`, `body_region.height` must be reduced by 36. The `flow_layout/1` helper constructs `body_region` from `template.height - margin_top - margin_bottom` but does not account for the actual footer/header region heights defined in the template's region list. This works today because default header and footer have zero height. A running footer with real height exposes the gap.

**How to avoid:**

When introducing the running-region primitive, enforce a **body-capacity derivation that accounts for all non-body region heights**. Specifically, `body_capacity` must equal:

```
template.height
  - template.margin_top
  - template.margin_bottom
  - sum(height of header regions)
  - sum(height of footer regions)
```

This derivation must run during `normalize_flow_layout` (in `Compose`) or at the start of `paginate_flow`, so the corrected capacity is used throughout pagination. A validation step should assert that `body_capacity > 0` and emit a meaningful error if header + footer heights consume the full page height.

Additionally, the `body_region.y` origin must account for header height, not just `margin_top`. A footer with height 36 placed at `anchor: :bottom` must have its `y` coordinate computed as `template.height - margin_bottom - footer_height`, not left at the default static value.

**Warning signs:**

- Header and footer blocks visually overlap the bottom lines of body text when a non-zero footer height is used.
- Tests pass on documents with zero-height headers/footers but fail when a 36pt footer is added.
- `body_capacity` is computed once in `flow_layout` and never updated when template regions declare non-zero header/footer heights.
- The region `height: 0` default in `PageTemplate` is left intact but a running-footer API silently creates a region with `height: N` without updating `body_capacity`.

**Phase to address:**
Page-numbering/running-header-footer primitive phase. Must be verified with explicit tests: body content with a 36pt footer must not overlap footer; a footer taller than the page body must produce a meaningful error, not a silent overlap.

---

### Pitfall 3: Carried-Forward Running Totals Implemented in the Engine Rather Than Data Assembly

**What goes wrong:**

Statement recipes require per-page "balance carried forward" and "opening balance" displays. Receipt/report recipes may require per-page subtotals. The wrong approach is to implement this as engine logic: let the engine track a running total across page breaks and inject it into page blocks. This is wrong for two reasons:

1. **It breaks the single-pass pipeline model.** Carried totals require knowing where page breaks fall, which requires pagination, which requires knowing content heights, which requires the content to be fixed. If the engine injects carried-total values, it must either (a) run a pre-paginate pass to guess page breaks (expensive and potentially wrong), or (b) run a post-paginate pass that modifies already-paginated pages (mutates the output of a completed pipeline stage, violating stage immutability).

2. **It leaks domain logic into the engine.** "Balance carried forward" is business logic. Whether a statement uses a FIFO balance, a running net, or a subtotal-per-section depends on the domain model. An engine that understands "balance carried forward" must be updated every time a user's domain model differs. This is scope creep into WYSIWYG/config-soup territory — exactly what the PROJECT.md out-of-scope list prohibits.

**Why it happens:**

ReportLab provides `onPage` hooks for running totals. fpdf2 provides header/footer override methods. The idiomatic analog in Rendro would be "give the engine a callback it calls at each page break." This feels clean but it makes the engine stateful and breaks determinism: two renders of the same document data must produce identical bytes, but a callback-driven running total can behave differently if the callback has side effects or depends on external state.

**How to avoid:**

Carried-forward totals are a **data-assembly problem, not an engine problem**. The Statement recipe's `sections/2` function receives the full dataset and can compute all per-page totals *before* calling the engine, because the recipe controls page grouping by construction:

- Group line items into page-sized batches at data assembly time (before `document/2` is called).
- Each batch is assembled as a section with the computed opening balance and closing balance included as explicit content blocks.
- The engine paginates these pre-assembled sections without needing to know what "balance" means.

The recipe's job is to split data into page-sized sections with pre-computed totals; the engine's job is to lay out those sections. The three-rung escape-hatch pattern supports this: adopters who need different batching logic can call `sections/2` with pre-split data or override it entirely using the `page_template/1` escape hatch.

Document clearly that "the recipe pre-computes carried totals; the engine does not track running state across page breaks." This prevents adopters from expecting engine-level running-total support and then being surprised.

**Warning signs:**

- A recipe function parameter includes `on_page_break:` or `on_carry_forward:` callback options.
- `Pipeline.Paginate` gains a `running_state` accumulator that mutates as blocks are placed.
- A recipe takes raw unsorted line items and internally decides page breaks based on item counts — this is data batching and belongs in the recipe, but if it also modifies block content based on accumulated values, it has leaked domain logic.
- Tests for the Statement recipe use items whose totals are not pre-computed but instead "emerge" from the render.

**Phase to address:**
Statement recipe phase. The data-assembly contract must be explicit in the recipe's `@moduledoc`: "carried-forward totals are pre-computed by the caller; this recipe lays out pre-computed sections."

---

### Pitfall 4: Certificate Fixed-Coordinate Brittleness Breaking Across Page Sizes

**What goes wrong:**

Certificate documents use decorative layouts — centered seals, bordered frames, positioned text blocks, specific x/y coordinates for signatories. The trap is hardcoding these coordinates for A4 paper (595.28 × 841.89 pt) inside the recipe, then having the coordinates silently overflow or misalign when an adopter uses US Letter (612 × 792 pt) or a custom page size.

This fails silently: no overflow error, no diagnostic — the block fits within the page bounds at A4 dimensions, but looks visually wrong at Letter dimensions because the "centered" coordinate is hardcoded at `x: 297.64` instead of computed as `(page_width - element_width) / 2`.

The deeper issue: a certificate recipe that looks beautiful at one page size is useless at another page size. Adopters in North America use Letter; adopters in Europe use A4. A recipe that silently misaligns at Letter without error is a trust violation — it produces visually broken output that a non-expert adopter may not catch.

**Why it happens:**

It is much easier to design a certificate layout at fixed coordinates than to derive layout from page geometry. The invoice recipe also uses an A4 default — but invoice content is flow-based (a table that reflows), so it is not fragile. Certificate content is typically fixed-position (a border at the page edges, a seal at the center), so it requires coordinate derivation from template geometry.

**How to avoid:**

All certificate layout coordinates must be derived from template geometry, not hardcoded:

- "Center" = `template.width / 2`
- "Page bottom with margin" = `template.height - template.margin_bottom`
- "Bordered frame" = computed from `margin_left`, `margin_right`, `margin_top`, `margin_bottom`

The `page_template/1` function for the certificate recipe must accept `width:` and `height:` overrides. The `sections/2` function must accept the template (or page dimensions) so it can derive coordinates.

Add a docs-contract test that verifies the certificate recipe renders without overflow at both A4 and US Letter dimensions.

**Warning signs:**

- `page_template/1` returns a `%PageTemplate{}` with hardcoded `x:` coordinates in its regions that are multiples of 595.28 or 841.89.
- `sections/2` constructs blocks with `x:` or `y:` values computed as literal numbers rather than expressions referencing template dimensions.
- The recipe's only test uses the default A4 dimensions.
- The recipe's `@moduledoc` does not state which page sizes are supported and tested.

**Phase to address:**
Certificate recipe phase. Coordinate derivation from template must be enforced in the recipe implementation and verified by a multi-page-size test.

---

### Pitfall 5: Determinism Regression from Non-Deterministic Identifiers in Running Regions

**What goes wrong:**

Running header/footer blocks are constructed in `apply_page_template` during pagination. A determinism regression occurs when any value injected into those blocks is not a pure function of (document data + page index + total pages). The most common accidental non-determinism sources:

- **Timestamps in headers:** A recipe that injects `DateTime.utc_now()` or `NaiveDateTime.local_now()` into a "printed at" header line produces different bytes on every render. This breaks the existing determinism contract.
- **Unique IDs from `:crypto.strong_rand_bytes` or `System.unique_integer`:** A recipe that generates a per-page nonce or trace ID in the header is non-deterministic.
- **Process-dictionary or ETS-backed counters:** Any global mutable state read during `apply_page_template` can produce different values across renders of the same document.
- **Locale-dependent formatting:** `Calendar.strftime` with a locale that may differ between processes (or between CI and production) produces different bytes for the same date value.

The existing pipeline already has a `deterministic: true` render option. The new running-region primitive must respect that flag: if `deterministic: true`, every block injected into running regions must be deterministic. If a recipe injects a "printed at" timestamp and `deterministic: true` is set, the pipeline should either (a) omit the timestamp or (b) use the document metadata's `created_at` rather than wall time.

**Why it happens:**

Running headers/footers often display contextual information: "Confidential — printed 2026-05-29", "Generated by Rendro vX.Y.Z". These look innocuous. But each one breaks the `deterministic: true` contract because the value changes on every render. An adopter who relies on deterministic output for audit trails (e.g., comparing two renders to detect tampering) is silently broken.

**How to avoid:**

- The running-region primitive documentation must explicitly state which substitution variables are deterministic (page number, total pages, document title from metadata, document date from metadata) and which are not (wall time, random values).
- If a recipe includes time-sensitive fields, it must receive them as explicit data parameters, not compute them internally via `DateTime.utc_now()`.
- The pipeline's `deterministic: true` flag should, when set, fail fast on any running-region block that contains `{{now}}` or similar wall-time substitutions unless the caller has explicitly provided a pinned timestamp via document metadata.
- The docs-contract test suite should include a test that renders the same document twice with `deterministic: true` and asserts binary equality of the output.

**Warning signs:**

- A recipe or running-region example in docs calls `DateTime.utc_now()` directly in a block builder function.
- Two renders of the same document under `deterministic: true` produce different byte counts.
- `apply_page_template` or any block-injection function calls `:rand`, `:crypto`, `System.unique_integer`, or any I/O function.
- A "printed at" timestamp in the footer is hardcoded in the recipe rather than injected as a parameter.

**Phase to address:**
Page-numbering/running-header-footer primitive phase. Determinism constraints for running-region values must be documented and tested in the primitive phase before recipes use the primitive.

---

### Pitfall 6: Recipe API Widening Into Config-Soup or WYSIWYG Territory

**What goes wrong:**

Each recipe ships three runnable functions: `document/2`, `page_template/1`, `sections/2`. The escape-hatch pattern is intentionally layered so that adopters who need customization override at the appropriate rung. The pitfall is widening each recipe's own API to absorb customization that belongs at the escape-hatch level:

- Adding a growing `opts` parameter to `document/2` that accepts `color:`, `logo_url:`, `border_style:`, `font_size:`, `column_count:`, `show_running_total:`, etc. Each individually reasonable option collectively becomes a WYSIWYG config API baked into core.
- Conditional logic inside `sections/2` based on opts flags: `if opts[:show_subtotal], do: ...` — this moves layout logic into opts rather than into the caller's override.
- A recipe that imports or optionally uses Phoenix-specific modules (LiveView helpers, Gettext, Phoenix.HTML) to produce localized content — this introduces a Phoenix hard dependency into a recipe that lives in core.

The existing `BrandedInvoice` recipe shows the correct pattern: it is a separate module that calls `Invoice.page_template/1` and overrides specific regions. The v2.4 recipes must follow the same pattern of composition, not opts accumulation.

**Why it happens:**

Real users send feature requests ("can the statement recipe support X currency format?", "can the certificate recipe show a border or not?"). The path of least resistance is `opts[:show_border]`. Each opt seems reasonable in isolation but collectively they make the recipe an undocumented, untested configuration surface with combinatorial complexity.

**How to avoid:**

- The `opts` accepted by `document/2` and `page_template/1` must be limited to **structural layout overrides** (`:name`, `:width`, `:height`, margin overrides) that map directly to `%PageTemplate{}` fields — not content or styling decisions.
- Content customization must flow through the three-rung escape hatch: call `sections/2` and override the section you want to change. Document this pattern prominently.
- No recipe module may `require` or `import` Phoenix, Oban, Gettext, or any non-core dependency. If a recipe needs localized currency formatting, it accepts a pre-formatted string — formatting belongs to the caller.
- The docs-contract test must verify that each recipe module's `deps` footprint is pure core (`Rendro.*` only). A test that compiles each recipe module in isolation without Phoenix available must pass.

**Warning signs:**

- A recipe's `@spec document(map(), keyword()) :: Rendro.Document.t()` opts type grows beyond five keys across three PRs.
- A recipe calls `Phoenix.HTML.raw/1`, `Gettext.gettext/2`, or any module outside `Rendro.*` or Elixir stdlib.
- A recipe `opts` key controls a boolean that changes which content blocks are included (not which dimensions are used).
- An adopter thread asks "how do I change the statement recipe's currency format?" and the answer is a new `currency_formatter:` opt rather than "override `sections/2` and format before calling it."

**Phase to address:**
Each recipe phase. The recipe's `@moduledoc` must state the allowed opts and explain the escape-hatch pattern for everything else. The docs-contract test suite must lint opts usage.

---

### Pitfall 7: Reference App Leaking Phoenix or Oban Into Core Rendro

**What goes wrong:**

The Phoenix example (`examples/phoenix_example`) is an application that depends on Rendro via `path: "../.."`. When upgrading it to be a CI-run reference app, the boundary must be preserved: Phoenix-specific behavior lives in the example, not in `lib/rendro/`. The trap is subtle:

- A helper module added to `lib/rendro/adapters/phoenix.ex` gains a new function that accepts a `Phoenix.LiveView.Socket` or `Plug.Conn` — this hardcodes the Phoenix dependency in core even though it is in the adapters namespace.
- The CI job that verifies the example starts with `cd examples/phoenix_example && mix compile` but is upgraded to `mix test` — the example's tests import or mock Phoenix internals, and a breakage in the Phoenix version used by the example propagates as a flaky required check on the main Rendro test job.
- A recipe module begins `use Phoenix.Component` or `import Phoenix.HTML` because a developer tested it in the Phoenix context first.

**Why it happens:**

When iterating on a recipe inside a Phoenix app, it is tempting to use Phoenix helpers. The `examples/phoenix_example` context makes Phoenix available, so `use Phoenix.Component` compiles without error. The dev imports the module into `lib/rendro/recipes/` without noticing the dependency has leaked.

**How to avoid:**

- The CI job for the example must run in a **separate job** from the main `mix ci` job, not as a step in the same job. A separate job with its own `mix deps.get` and `mix compile` (or `mix test`) means a Phoenix version incompatibility in the example cannot block the core library merge gate.
- The main `mix ci` / `mix test` job must **never** have Phoenix, Bandit, or Oban in its `mix.exs` deps. A docs-contract test can assert that `mix.exs` deps do not include any Phoenix-family package.
- Every new function added to `lib/rendro/adapters/phoenix.ex` must be reviewed against the type signatures to verify no Phoenix struct types appear in the core `Rendro.*` type signatures (they should appear only in the adapter module's own typespecs or in the `examples/` tree).
- The Phoenix example's `mix.exs` must use `{:rendro, path: "../.."}` (not a hex version) to ensure it always tracks the working tree.

**Warning signs:**

- `grep -r "Phoenix\|Plug\.Conn\|LiveView" lib/rendro/recipes/ lib/rendro/pipeline/` returns hits.
- A CI job failure in `examples/phoenix_example` blocks a merge that only changed `lib/rendro/pipeline/paginate.ex`.
- A recipe module's `mix compile --warnings-as-errors` produces an "undefined module" error when Phoenix is not in the BEAM path.

**Phase to address:**
Reference app CI phase. The CI job isolation pattern must be documented and the core dependency lint test must be added before the example is wired into required checks.

---

### Pitfall 8: Reference App Drifting From the Real API and Overclaiming

**What goes wrong:**

A reference app that is not continuously tested against the actual library API drifts. The `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` currently calls `Rendro.Recipes.Invoice.document/1` — if `Invoice.document/1` gains a required parameter or has its signature changed in a v2.4 phase, the example breaks at compile time and CI catches it. But subtler drift is not caught by compile:

- The example's README says "run `mix phx.server` to see Rendro in action" but the server starts on port 4000 and the CI verification job only runs `mix compile`, not `mix test` or a smoke-test HTTP request. An adopter clones the repo, follows the README, and hits a 500 error because the new recipe requires data the example does not provide.
- The example exercises only `Invoice` and `BrandedInvoice` after v2.4 ships `Statement`, `ReceiptReport`, and `Certificate`. A new adopter looking at the example for adoption patterns cannot see the new recipes in action.
- The example's README makes claims ("Rendro generates production-grade PDFs with full viewer support") that go beyond what `priv/support_matrix.json` records. This is an honesty violation — examples are public claims.

**Why it happens:**

Example code is written once, checked in, and then treated as inert. No one owns it between milestones. API changes happen without a "does the example still work end-to-end" check.

**How to avoid:**

- Upgrade the CI job from `mix compile` to `mix test` (or at minimum, a smoke test that calls the PDF render pipeline and asserts the returned binary is non-empty). An HTTP smoke test is not required — a `mix run` script that calls each recipe and asserts `{:ok, _pdf_binary} = Rendro.render(doc)` is sufficient.
- After adding the three new recipes, the example must exercise all five recipes (Invoice, BrandedInvoice, Statement, ReceiptReport, Certificate) either in the controller or in a dedicated test file.
- The example README must have an explicit **"What this demonstrates"** section that lists only the features demonstrated — never a blanket "Rendro supports X" claim. Any capability claim in the README must be traceable to a row in `priv/support_matrix.json`.
- The example README must state the Elixir and OTP version it was tested against, and the CI job must pin those versions.
- The milestone-audit phase must verify that the example compiles and its test/smoke suite passes against the v2.4 codebase before the milestone closes.

**Warning signs:**

- The CI job for the example runs `mix compile` only — no test or smoke invocation.
- The example controller or README references a recipe name that does not yet exist in `lib/rendro/recipes/`.
- The example README contains language like "works in all major PDF viewers" or "production-ready for all document types."
- The example has not been updated to use the new v2.4 APIs after the recipe phases ship.

**Phase to address:**
Reference app CI phase. Smoke-test coverage and README honesty review are exit criteria for this phase. The milestone-audit phase verifies all five recipes are exercised.

---

### Pitfall 9: Viewer-Evidence and Support-Matrix Gaps for New Surfaces

**What goes wrong:**

v2.3 closed all 26 existing (surface × viewer) cells to terminal state. v2.4 adds new surfaces: running headers/footers and the three recipe types. If these new surfaces ship without any (surface × viewer) cells in `priv/support_matrix.json`, the v2.3 discipline is implicitly rolled back — there are surfaces in the public API with no recorded viewer posture. If they are added as silent `unverified` without the v2.3 evidence discipline, that is a regression.

This does not mean every new surface needs full Acrobat × Preview × PDFium × PDF.js recording before v2.4 ships. Running headers/footers are rendered as standard text and image content — they have no viewer-specific behavior beyond what existing text and image surfaces already record. But the support matrix still needs to acknowledge the surface exists and state the viewer posture explicitly.

**Why it happens:**

New surfaces added during an "adoption" milestone feel like ergonomic improvements, not trust-sensitive additions. The developer adds the running-footer feature, it renders correctly in their local viewer, and there is no obvious prompt to update the support matrix.

**How to avoid:**

- Any new public API surface must add an `explicit_deferral` row (with a named reason) or a `supported` row (with recorded evidence) to `priv/support_matrix.json` before shipping. No new surface ships as a silent gap.
- For running headers/footers: these are standard rendered text/image content. The appropriate posture is an `explicit_deferral` row noting "viewer behavior inherits from existing text/image surfaces; no additional per-viewer recording is required for this primitive." This is an honest, named position, not a silent unverified.
- For the three recipes: recipes do not introduce new PDF features — they compose existing primitives. The support matrix row for a recipe surface is "recipe output inherits the support posture of the primitives it composes; see text, table, image, and running-region rows." This is a named explicit position.
- The JSON schema validator (added in v2.3) must be run on any changes to `priv/support_matrix.json` during v2.4 development. The docs-contract test must pass before merge.

**Warning signs:**

- v2.4 ships page-numbering and three recipes without any change to `priv/support_matrix.json`.
- A new row is added to `priv/support_matrix.json` with `status: unverified` and no `explicit_deferral_reason`.
- The JSON schema validator is not run as part of the v2.4 phase transition checks.

**Phase to address:**
Each phase that introduces a new public API surface must include a support-matrix update as an exit criterion. The milestone-audit phase verifies no new surfaces are silent gaps.

---

### Pitfall 10: CI Job Coupling Making the Example a Required Gate on Core Tests

**What goes wrong:**

The current CI workflow (`ci.yml`) has a "Verify Phoenix Example" step inside the same `test` job as `mix ci`. If the Phoenix example fails to compile (e.g., because the Phoenix version in `examples/phoenix_example/mix.exs` is pinned to `1.7` but a transient dep resolution issue occurs), it blocks the entire `test` job — including `mix ci` for the core library. This means a Phoenix upstream change can block core Rendro merges.

Upgrading the example to `mix test` rather than `mix compile` worsens this: Phoenix test infrastructure (Ecto sandbox, endpoint config) can be flaky in CI environments in ways that the deterministic Rendro core tests are not. A flaky Phoenix test becomes a required gate on every Rendro merge.

**Why it happens:**

"Verify Phoenix Example" was added as a step rather than a separate job — the simplest thing. For `mix compile` only, this was low risk. Once upgraded to `mix test`, the same coupling is now dangerous.

**How to avoid:**

- Move the Phoenix example verification to a **separate CI job** (`example-phoenix` or similar) that is declared `needs: test` but is **not** added to the branch protection required checks. The example must be green to merge, but its failure should be a clear "example problem" signal, not a "core test failure" signal.
- Alternatively, add the example job to required checks but keep it strictly limited to `mix compile` (verifying API compatibility) and a `mix run` smoke script that does not start the Phoenix server (no HTTP infrastructure required, no flaky endpoint).
- Use `continue-on-error: false` so the example job failure is visible, but scope the job's failure blast radius to the example alone, not to the signing-live-proof or long-lived-live-proof required checks.

**Warning signs:**

- "Verify Phoenix Example" remains a step in the same job as `mix ci` after the upgrade.
- A transient `mix deps.get` failure in `examples/phoenix_example` causes the core `test` job to be marked as failed.
- The `signing-live-proof` or `long-lived-live-proof` jobs declare `needs: test` and therefore never run when the Phoenix example step fails early.

**Phase to address:**
Reference app CI phase. The job isolation must be implemented before the example is upgraded to `mix test` or a smoke script.

---

## Technical Debt Patterns

Shortcuts that look reasonable now but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|---|---|---|---|
| Implement `{{total_pages}}` as a second `String.replace` in `replace_page_numbers` using `length(pages)` at that call site | Ships in one line | Wrong count when page breaks occur after `apply_page_template`; no reserved-width; iterative loop temptation | Never — reserved-width two-phase approach is required |
| Hardcode A4 coordinates in the Certificate recipe | Faster to write | Silently broken at US Letter; no test will catch it until an adopter files a bug | Never — derive from template geometry |
| Wire `mix phx.server` smoke test into required branch protection | Strong "it works" signal | Flaky HTTP infrastructure blocks core merges | Never as required gate — `mix run` smoke script only |
| Add `carried_total:` as an engine-level option to `paginate_flow` | Appealing for statement use case | Engine accrues domain logic; breaks single-pass model; non-deterministic under concurrent renders | Never — carried totals belong in data assembly |
| Accept `currency_formatter:` as a recipe opt | Easy per-caller customization | Opts accumulate into WYSIWYG config; opts are not tested combinatorially | Only if the formatter is a pure function with a defined type, and only if the recipe module doc explicitly lists it as a stable opt |
| Skip support-matrix update for "it's just a recipe" surfaces | Less overhead | Implicit regression of v2.3 discipline; silent gaps re-emerge | Never — named explicit_deferral is the minimum |
| Leave "Verify Phoenix Example" as a step in the `test` job | Simpler CI config | Any Phoenix dep issue blocks core tests and required proof lanes downstream | Never after upgrading beyond `mix compile` |
| Bump `recorded_at` on existing viewer evidence rows without re-verifying, to acknowledge new surfaces | Clears staleness warnings | Dishonest recording — bumping date without re-check is an active lie | Never |

## Integration Gotchas

Common mistakes when wiring v2.4 features into the existing engine and CI.

| Integration | Common Mistake | Correct Approach |
|---|---|---|
| `body_capacity` in `paginate_flow` | Leaves `body_region.height` unchanged when a non-zero running footer is configured | Re-derive `body_capacity` subtracting all non-body region heights after template is resolved |
| `apply_page_template` / `replace_page_numbers` | Adds `{{total_pages}}` substitution at the same call site as `{{page_number}}` using current page list length | Two-phase approach: reserve width during layout, substitute actual total in a post-paginate pass |
| `priv/support_matrix.json` | New surfaces ship without any matrix row | Every new public surface needs either `supported` (with evidence) or `explicit_deferral` (with named reason) before v2.4 closes |
| Phoenix example CI job | "Verify Phoenix Example" stays as a step in the required `test` job | Separate job, declared `needs: test`, not itself a required branch protection check, or narrowly scoped to `mix compile` + `mix run` smoke |
| Recipe modules in `lib/rendro/recipes/` | `use Phoenix.Component` or `import Gettext` inside a recipe | Core recipes must import only `Rendro.*` and Elixir stdlib; Phoenix-specific concerns belong in `lib/rendro/adapters/phoenix.ex` or the example |
| Carried totals in Statement recipe | Pass `on_carry_forward: fn balance -> ... end` callback option to recipe | Pre-compute all per-page totals in the caller before calling `sections/2`; document this contract in the recipe's `@moduledoc` |
| `guides/api_stability.md` | Updating prose to imply running-footer or recipe viewer support beyond what matrix records | Prose must mirror matrix; new surfaces are acknowledged as "inherits from existing primitives" or deferred explicitly |
| Existing signing/long-lived CI lanes | Adding the example CI job as a new `needs:` dependency of `signing-live-proof` | The signing lanes depend only on `test`; the example job is parallel, not in the signing lane dependency chain |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **`{{total_pages}}` substitution:** Verify the reserved-width placeholder is measured at maximum digit count and the actual substitution happens post-paginate, not during `replace_page_numbers`.
- [ ] **Footer height in body capacity:** Verify a 36pt footer causes `body_capacity` to decrease by 36pt and does not overlap body content on the last line of any page.
- [ ] **Statement carried totals:** Verify that opening and closing balance values in the recipe output are pre-computed inputs, not engine-computed outputs. The recipe has no accumulator.
- [ ] **Certificate multi-page-size:** Verify the certificate recipe renders without overflow on both A4 (595.28 × 841.89) and US Letter (612 × 792) dimensions.
- [ ] **Recipe pure-core deps:** Verify each new recipe module compiles cleanly in an Elixir environment where Phoenix and Oban are not available on the BEAM path.
- [ ] **Determinism regression:** Verify two sequential renders of each new recipe with `deterministic: true` produce byte-identical output. No wall-time, no random values, no `System.unique_integer` in any block builder.
- [ ] **Support-matrix coverage:** Verify `priv/support_matrix.json` has an entry (either `supported` with evidence or `explicit_deferral` with a named reason) for every new public surface: running-header, running-footer, statement recipe output, receipt-report recipe output, certificate recipe output.
- [ ] **Schema validator passes:** Verify `mix test` (docs-contract lane) passes after any `priv/support_matrix.json` change introduced in v2.4.
- [ ] **Phoenix example exercises all five recipes:** Verify the example controller or test calls Invoice, BrandedInvoice, Statement, ReceiptReport, and Certificate after all recipe phases ship.
- [ ] **CI job isolation:** Verify the Phoenix example verification job is separate from the core `test` job and that a Phoenix example failure does not prevent `signing-live-proof` or `long-lived-live-proof` from running.
- [ ] **Example README honesty:** Verify no claim in the example README implies viewer support or compliance coverage beyond what `priv/support_matrix.json` records.
- [ ] **Recipe escape-hatch documented:** Verify each new recipe's `@moduledoc` explicitly documents the three-rung pattern and states what `opts` are structural-only vs. what requires override via `sections/2`.
- [ ] **Existing required CI lanes unchanged:** Verify `test`, `signing-live-proof`, `long-lived-live-proof`, `viewer-evidence-live-proof`, and `release-proof` all remain required on `main` after v2.4 CI changes.

## Recovery Strategies

When pitfalls occur despite prevention.

| Pitfall | Recovery Cost | Recovery Steps |
|---|---|---|
| `{{total_pages}}` ships with wrong count | HIGH | Requires a two-pass re-implementation; cannot be patched without API/behavior change; revert and implement reserved-width approach; bump patch version with note |
| Footer-height overlap discovered in production | MEDIUM | Hotfix: derive `body_capacity` correctly; existing documents may need re-render; release patch and document in CHANGELOG |
| Statement recipe computes carried totals in engine | MEDIUM | Extract to data-assembly layer; engine API stays stable; recipe API changes minimally; CHANGELOG notes the correction |
| Certificate hardcoded coordinates misalign at Letter | LOW-MEDIUM | Fix coordinate derivation to use template geometry; add multi-size test; patch release |
| Determinism regression discovered post-release | MEDIUM | Identify the non-deterministic value; make it a required parameter with a data-flow fix; patch release; add determinism regression test |
| Phoenix core dependency leaked into `lib/rendro/recipes/` | MEDIUM | Move to `lib/rendro/adapters/phoenix.ex` or to the example; no adopter API breakage if caught before 1.0; harder after SemVer commitment |
| Example README overclaim discovered | LOW | Update README to match matrix; no code change; CHANGELOG note; no version bump required unless the overclaim is in a docstring |
| CI job coupling blocks core merges | LOW-MEDIUM | Move example step to its own job; re-wire `needs:` dependencies; no code change to the library |
| Support-matrix gap discovered at milestone audit | LOW | Add `explicit_deferral` row with named reason; run schema validator; merge; no functional change |

## Pitfall-to-Phase Mapping

How v2.4 phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---|---|---|
| 1: `{{total_pages}}` layout-convergence | Page-numbering/running-region primitive phase | Test: multi-page document with varying digit-count totals; two-phase substitution produces correct count; no convergence loop |
| 2: Footer height invalidates body capacity | Page-numbering/running-region primitive phase | Test: 36pt footer reduces body capacity by 36pt; body and footer do not overlap |
| 3: Carried totals in engine | Statement recipe phase | Review: recipe has no accumulator; `@moduledoc` states pre-computation contract; no `on_carry_forward:` option |
| 4: Certificate fixed coordinates | Certificate recipe phase | Test: recipe renders without overflow at A4 and US Letter; all coordinates derived from template geometry |
| 5: Determinism regression | Page-numbering primitive phase + each recipe phase | Test: deterministic? render twice, assert binary equality; no wall-time/random calls in block builders |
| 6: Recipe API config-soup | Each recipe phase (Statement, ReceiptReport, Certificate) | Review: `opts` list in `@spec`; no Phoenix/Oban imports; escape-hatch documented; docs-contract test lints opts count |
| 7: Phoenix leaking into core | Reference app CI phase | Test: compile each recipe module without Phoenix on path; grep `lib/rendro/recipes/` for Phoenix references |
| 8: Reference app drift and overclaim | Reference app CI phase + milestone-audit phase | CI: smoke test exercises all five recipes; README reviewed for honesty; milestone-audit: example passes on final v2.4 codebase |
| 9: Viewer-evidence gaps for new surfaces | Each phase that ships a new surface | Support matrix has row (supported or explicit_deferral) before phase closes; schema validator passes |
| 10: CI job coupling | Reference app CI phase | CI config reviewed: example in separate job; `signing-live-proof` and `long-lived-live-proof` unaffected by example failures |

## Sources

- `/Users/jon/projects/rendro/lib/rendro/pipeline/paginate.ex` — direct inspection of `replace_page_numbers/2`, `apply_page_template/3`, `paginate_flow/1`, and `body_capacity` derivation (HIGH confidence — primary source)
- `/Users/jon/projects/rendro/lib/rendro/page_template.ex` — default region heights (header: 0, footer: 0) and their structural implications (HIGH confidence — primary source)
- `/Users/jon/projects/rendro/lib/rendro/pipeline.ex` — single-pass pipeline structure: build → compose → measure → paginate → render → validate (HIGH confidence — primary source)
- `/Users/jon/projects/rendro/lib/rendro/recipes/invoice.ex` — three-rung escape-hatch pattern, correct `opts` discipline, what belongs in recipe vs. engine (HIGH confidence — primary source)
- `/Users/jon/projects/rendro/lib/rendro/document.ex` — `header: []`, `footer: []` as document-level fields alongside `body_capacity` implications (HIGH confidence — primary source)
- `/Users/jon/projects/rendro/.github/workflows/ci.yml` — current "Verify Phoenix Example" as a step in the `test` job, not a separate job; compile-only, no smoke test (HIGH confidence — primary source)
- `/Users/jon/projects/rendro/examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` — exercises only Invoice and BrandedInvoice; no Statement, Receipt, Certificate (HIGH confidence — primary source)
- `.planning/PROJECT.md` — non-negotiable constraints (pure-Elixir core, single pipeline, determinism, honesty-first public claims, proof-backed support matrix) (HIGH confidence — primary)
- `.planning/STATE.md` — diminishing-returns guidance on proof axis; adoption ergonomics as the leverage axis; multi-signature/HSM/text-shaping must not leak in (HIGH confidence — primary)
- `.planning/threads/v24-adoption-scoping.md` — explicit anti-scope warnings: "resist adjacent scope (multi-signature, HSM, global text shaping)"; "must stay deterministic + tested"; "evidence-discipline-is-inheritable" graduation candidate (HIGH confidence — primary)
- `.planning/research/PITFALLS.md` (v2.3) — predecessor document establishing the overclaim, scope-creep, and CI-dilution pitfall patterns carried forward (HIGH confidence — primary)
- ReportLab two-pass `total_pages` pattern (`setPageSize` / `onPage` hook with deferred canvas write) — MEDIUM confidence (training knowledge, consistent with approach used in the codebase's existing single-pass design)
- fpdf2 `alias_nb_pages` reserved-width approach — MEDIUM confidence (training knowledge; same reserved-width principle applies directly to this engine)

---
*Pitfalls research for: v2.4 Batteries-Included Workflow & Adoption Closure — page-numbering/running-region primitive, Statement/ReceiptReport/Certificate recipes, CI-run reference Phoenix app*
*Researched: 2026-05-29*
