# Phase 38: Advanced Layout Verification & Recipe Updates - Research

**Researched:** 2024-05-24
**Domain:** Advanced Layout, Pagination, Text Shaping (i18n), Verification
**Confidence:** HIGH

## Summary

This phase verifies the integration of table fragmentation (Phase 37) and text shaping (Phase 35/S02) using the canonical `Invoice` recipe. The primary goal is to prove that Rendro can perfectly paginate a multi-page table containing Arabic text while maintaining deterministic, verifiable PDF output.

The research indicates that we do not necessarily need to change the internal logic of `Rendro.Recipes.Invoice` unless we want to formally add a `customer` field. Since the `items` payload naturally translates into a `Rendro.table`, injecting Arabic text into the `items` list and providing enough rows (>50) will inherently trigger both complex text shaping and multi-page fragmentation. The verification will rely on Rendro's `deterministic: true` rendering mode, identical to the strategy used in `test/rendro/deterministic_test.exs`. Docs-contract tests will be satisfied by adding a new compilation fence in `README.md`.

**Primary recommendation:** Update the tests to invoke the existing `Invoice` recipe with a heavily populated `items` list containing Arabic strings. Add a deterministic verification test in `invoice_test.exs` and a new docs-contract fence in `README.md`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Integration Target:** `Rendro.Recipes.Invoice` (or a similar canonical recipe) must be updated to demonstrate the new capabilities.
- **Features to Demonstrate:** Multi-page table pagination (from Phase 37). Arabic text shaping and fallbacks (from Phase 35/S02).
- **Verification:** Visual/Flow regressions will assert exact byte-for-byte or stable structural output. Must include docs-contract tests demonstrating behavior.

### the agent's Discretion
None explicitly stated in `38-CONTEXT.md`.

### Deferred Ideas (OUT OF SCOPE)
None explicitly stated in `38-CONTEXT.md`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REQ-01 | Modify `Invoice` recipe for Arabic/multi-page | Inject 50+ Arabic-named items into the `items` list or add a `customer` struct to trigger multi-page tables and i18n shaping. |
| REQ-02 | Assert byte-for-byte or stable structural output | Add a deterministic test asserting `pdf1 == pdf2` for a large, complex payload. |
| REQ-03 | Implement docs-contract test | Add an `elixir` code block to `README.md` with a custom compile fence (e.g., `readme-invoice-i18n-compile`) and assert it in `readme_doctest_test.exs`. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Arabic Text Shaping | API / Backend (`harfbuzz_ex`) | `Rendro.Text.Shaper` | Text shaping is performed server-side by HarfBuzz during the Measure pipeline stage to generate exact glyph bounding boxes. |
| Table Pagination | API / Backend | `Rendro.Pipeline.Paginate` | Pagination relies on measured block heights and breaks table rows across pages during the Paginate stage. |
| Deterministic Output | API / Backend | `Rendro.PDF.Writer` | PDF generation must strip variable timestamps and sort dictionary keys to ensure byte-for-byte identity. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `harfbuzz_ex` | (Existing) | Complex text shaping | Pre-existing project dependency for handling Arabic fallbacks and glyph extraction. |

## Architecture Patterns

### Recommended Implementation Strategy

1. **How exactly to modify the `Invoice` recipe:**
   - **Data Injection:** The `Rendro.Recipes.Invoice.body_section/1` maps the `items` payload directly into a `Rendro.table`. By supplying 50+ items where `item.name` contains Arabic text (e.g., `"استشارات (Consulting)"`), we natively trigger both the HarfBuzz text shaping fallback (Phase 35) and the table fragmentation engine (Phase 37).
   - **Alternative API Update:** If "Arabic customer details" implies a dedicated customer section, update `header_section/1` in `lib/rendro/recipes/invoice.ex` to conditionally pattern match on `data.customer_name` and render a secondary table.

2. **Specific test files for exact byte-for-byte output:**
   - Modify `test/rendro/recipes/invoice_test.exs` (or create `test/rendro/recipes/invoice_advanced_layout_test.exs`).
   - Create a test block using `deterministic: true` to generate a PDF, and run it sequentially 5-10 times asserting `pdf == reference_pdf`. This mirrors the strategy in `test/rendro/deterministic_test.exs`.
   - Also assert structural validity (e.g., `String.contains?(pdf, "/Type /Page")` appears more than once, confirming multi-page pagination).

3. **Docs-contract test implementation:**
   - Add a new section to `README.md` under "Canonical Invoice Recipe" or "Advanced Layout" demonstrating Arabic text and multi-page support.
   - Tag the block with `<!-- fences: readme-invoice-i18n-compile -->`.
   - Update `test/docs_contract/readme_doctest_test.exs` to expect `"readme-invoice-i18n-compile"` in its list of verified fences.
   - The test runner will parse the fence, verify there are no skeleton placeholders (`...`), and execute `Code.compile_string/2` to guarantee API correctness.

4. **Edge cases and pitfalls:**
   - **Missing Font Registration:** HarfBuzz shaping requires the Arabic fallback font to be registered. If the font is missing, `Rendro.Text.Shaper` will fallback to dummy boxes (or emit a missing glyph telemetry event). The test *must* register an embedded Arabic font (e.g., NotoSansArabic) into the `Rendro.Document` before rendering.
   - **Widow/Orphan Truncation:** Table rows containing complex shaped text might split inappropriately if table cell fragmentation doesn't respect line heights for complex scripts.
   - **Deterministic Timestamps:** The `deterministic: true` flag must be explicitly passed to `Rendro.render(doc, deterministic: true)`, otherwise epoch timestamps will cause byte-for-byte comparisons to fail.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Byte-for-byte comparison | Approval/snapshot files | `deterministic: true` sequential renders | Rendro's deterministic mode eliminates variable dictionary keys and timestamps natively, preventing noisy snapshot diffs in git. |
| Complex Text Shaping | Custom width calculation | `Rendro.Text.Shaper` (HarfBuzz) | Arabic text has contextual forms and ligatures; simple character width arithmetic will fail. |

## Common Pitfalls

### Pitfall 1: Failing Docs-Contract Tests via Elixir Aliases
**What goes wrong:** The docs-contract compiler fails because a recipe alias (e.g., `Invoice`) isn't available in the README snippet.
**Why it happens:** `Code.compile_string/2` evaluates in a clean context.
**How to avoid:** Always use fully qualified module names like `Rendro.Recipes.Invoice.document/1` in the `README.md` fences.

### Pitfall 2: Shaping Fails Silently (Dummy Boxes)
**What goes wrong:** The output PDF contains `[]` or dummy boxes instead of Arabic characters, but the test passes the byte-for-byte check.
**Why it happens:** The test passed deterministic rendering but failed to register the Arabic fallback font.
**How to avoid:** Explicitly assert the presence of the embedded Arabic font dictionary in the output PDF binary (e.g., `assert pdf =~ "NotoSansArabic"` or similar font descriptor).

## Code Examples

### Deterministic Byte-for-Byte Regression Test Pattern
```elixir
test "multi-page invoice with Arabic item names produces stable deterministic output" do
  # Register the Arabic font in the test setup
  %{bytes: arabic_font_bytes} = FontFixture.arabic_font()

  items = Enum.map(1..60, fn i ->
    %{name: "تفاصيل العميل #{i} (Consulting)", qty: 1, price: 100}
  end)
  
  data = %{id: "INV-AR-001", date: ~D[2026-05-01], items: items}
  
  doc = 
    Rendro.Recipes.Invoice.document(data)
    |> Rendro.register_embedded_font(:arabic_fallback, {:binary, arabic_font_bytes})

  {:ok, ref_pdf} = Rendro.render(doc, deterministic: true)

  for _ <- 1..5 do
    {:ok, pdf} = Rendro.render(doc, deterministic: true)
    assert pdf == ref_pdf
  end
  
  # Structural assert for multi-page
  assert length(Regex.scan(~r/\/Type\s*\/Page\b/, ref_pdf)) > 1
end
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Quick run command | `mix test test/rendro/recipes/invoice_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-01 | Invoice generation with Arabic multi-page table | unit | `mix test test/rendro/recipes/invoice_test.exs` | ✅ Wave 0 |
| REQ-02 | Byte-for-byte exact rendering | unit | `mix test test/rendro/recipes/invoice_test.exs` | ✅ Wave 0 |
| REQ-03 | Docs-contract compilation success | unit | `mix test test/docs_contract/readme_doctest_test.exs` | ✅ Wave 0 |

### Wave 0 Gaps
- [ ] Add `arabic_font` to `Rendro.TestSupport.FontFixture` (if not already present from Phase 35).
- [ ] Update `README.md` with the new snippet and `readme-invoice-i18n-compile` fence.

## Sources

### Primary (HIGH confidence)
- Codebase context `test/rendro/deterministic_test.exs` - verified deterministic test structure.
- Codebase context `lib/rendro/recipes/invoice.ex` - verified recipe mapping of `items` to `Rendro.table`.
- Codebase context `test/docs_contract/readme_doctest_test.exs` - verified docs-contract testing mechanism.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir architecture already implemented.
- Architecture: HIGH - Deterministic checks already modeled in other tests.
- Pitfalls: HIGH - Common issues with `Code.compile_string` and missing fonts are known limitations.

**Research date:** 2024-05-24
**Valid until:** End of Project
