---
phase: 29
plan: 04
type: execute
wave: 2
depends_on: [03]
files_modified:
  - test/rendro/recipes/branded_invoice_test.exs
autonomous: true
requirements: [LAY-13, QUAL-07]
requirements_addressed: [LAY-13, QUAL-07]

must_haves:
  truths:
    - "test/rendro/recipes/branded_invoice_test.exs exists and mirrors test/rendro/recipes/invoice_test.exs structure: three describe blocks for page_template/1, sections/2, document/2 (D-23 supported by tests)"
    - "page_template/1 describe asserts %Rendro.PageTemplate{name: :branded_invoice} and four regions :logo, :header, :body, :footer (D-02)"
    - "sections/2 describe asserts list of 4 sections covering all four regions (D-02)"
    - "document/2 describe asserts %Rendro.Document{page_template: :branded_invoice}; brand font is registered with source: :embedded under data.brand.font_name (Pitfall 6 mitigation — non-vacuous)"
    - "document/2 describe asserts brand logo is registered under data.brand.logo_name in asset_registry (Pitfall 6 mitigation)"
    - "Boundary-validation describe block asserts ArgumentError raised when data.brand is missing or has non-atom font_name/logo_name (D-04)"
    - "Regression describe block runs Rendro.Recipes.BrandedInvoice.document(sample_data) through Rendro.render/1 and asserts: %PDF- magic bytes, /F_BRAND_HEADING font dict entry, /FontFile2 embedded font stream, /Type /XObject + /Subtype /Image image XObject, /IM_COMPANY_LOGO image dictionary entry, expected page count, header line breaks (D-27)"
    - "Byte-identical regression: TWO consecutive renders of BrandedInvoice.document(sample_data) with deterministic: true produce identical binaries (D-25 narrow internal regression, NOT a public byte-stability promise per D-30)"
    - "Rendro.Recipes.branded_invoice/1 delegate test: returned %Rendro.Document{} matches BrandedInvoice.document/1 output (D-03 delegate parity)"
    - "Determinism contract is preserved per D-30: structural assertions on font dictionary entries and image XObject presence are the public proof; whole-file byte identity stays a narrow internal regression tool only"
  artifacts:
    - path: "test/rendro/recipes/branded_invoice_test.exs"
      provides: "Regression coverage for BrandedInvoice public surface + boundary validation + full-pipeline render assertions + byte-identical 2-render"
      contains: ["defmodule Rendro.Recipes.BrandedInvoiceTest", "describe \"page_template/1\"", "describe \"sections/2\"", "describe \"document/2\"", "describe \"validate_data!\"", "describe \"regression: full-pipeline render\"", "describe \"regression: byte-identical two-render\"", "describe \"Rendro.Recipes.branded_invoice/1 delegate\""]
  key_links:
    - from: "test/rendro/recipes/branded_invoice_test.exs"
      to: "lib/rendro/recipes/branded_invoice.ex (Plan 03)"
      via: "Rendro.Recipes.BrandedInvoice.{page_template, sections, document}/1 calls"
      pattern: "Rendro\\.Recipes\\.BrandedInvoice\\."
    - from: "test/rendro/recipes/branded_invoice_test.exs"
      to: "Rendro.render/1"
      via: "{:ok, pdf} = Rendro.render(doc) — full pipeline regression"
      pattern: "Rendro\\.render"
    - from: "test/rendro/recipes/branded_invoice_test.exs"
      to: "lib/rendro/recipes.ex (Plan 03 delegate)"
      via: "Rendro.Recipes.branded_invoice/1 delegate-parity test"
      pattern: "Rendro\\.Recipes\\.branded_invoice"
---

<objective>
Ship `test/rendro/recipes/branded_invoice_test.exs` — the regression coverage that backs LAY-13 (recipe shape) AND QUAL-07 (committed regression tests for branded layout parity, plus an internal byte-identical 2-render check).

The test file mirrors `test/rendro/recipes/invoice_test.exs` structurally (same `describe` block layout — page_template/1 / sections/2 / document/2) and adds three Phase-29-specific blocks:
1. **Boundary-validation block** — `assert_raise ArgumentError` for missing/malformed `data.brand` (D-04).
2. **Full-pipeline render regression block** — runs `Rendro.render(BrandedInvoice.document(sample_data))` and asserts on PDF magic bytes, font dictionary, font-file stream, image XObject, image-dictionary entry, page count, and header line breaks (D-27).
3. **Byte-identical 2-render regression block** — two consecutive renders with `deterministic: true` produce identical binaries (D-25 — narrow internal regression, NOT a public byte-stability promise per D-30).
4. **Delegate-parity block** — `Rendro.Recipes.branded_invoice(sample_data)` returns the same `%Rendro.Document{}` shape as `BrandedInvoice.document(sample_data)` (D-03 delegate sanity check).

This plan implements D-04 (boundary tests), D-25 (byte-identical regression), D-27 (deterministic regression coverage), and ALSO directly references D-30 (determinism contract preserved — structural-only public proof) and D-31 (no system-font discovery — verified absent in source by Plan 03 task gates and re-asserted here).

Purpose: Without this test file, LAY-13 has no regression backstop and QUAL-07's "committed regression tests" arm is empty. This is the single largest test file in Phase 29 and the primary execution-time gate for the recipe.

Output: One new test file (~180-220 LOC), 7 describe blocks, ~18-22 distinct test cases.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/METHODOLOGY.md
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-CONTEXT.md
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-RESEARCH.md
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-PATTERNS.md
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-VALIDATION.md
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-03-PLAN.md

# Mirror analog (verbatim describe layout):
@test/rendro/recipes/invoice_test.exs

# Module under test (Plan 03 output):
@lib/rendro/recipes/branded_invoice.ex
@lib/rendro/recipes.ex

# PDF substring assertion precedent (D-27):
@test/rendro/pdf/writer_test.exs

# Byte-identical regression precedent (D-25):
@test/rendro/deterministic_test.exs

<interfaces>
<!-- Modules and helpers consumed by this test. -->

From lib/rendro/recipes/branded_invoice.ex (Plan 03):
```elixir
@spec page_template(keyword()) :: Rendro.PageTemplate.t()
@spec sections(map(), keyword()) :: [Rendro.Section.t()]
@spec document(map(), keyword()) :: Rendro.Document.t()
# validate_data! is private but is exercised through document/1 + sections/1 entry
```

From lib/rendro/recipes.ex (Plan 03):
```elixir
@spec branded_invoice(map()) :: Rendro.Document.t()
def branded_invoice(data), do: Rendro.Recipes.BrandedInvoice.document(data)
```

From lib/rendro.ex (top-level pipeline entry):
```elixir
@spec render(Rendro.Document.t(), keyword()) :: {:ok, binary()} | {:error, Rendro.Error.t()}
def render(doc, opts \\ [])
# opts include :deterministic (boolean) per Phase 26 D-15
```

From lib/rendro/document.ex:
```elixir
%Rendro.Document{
  page_template: atom(),    # set by set_template/2
  page_templates: [...],    # added by add_template/2
  sections: [...],          # added by add_section/2
  font_registry: %Rendro.FontRegistry{fonts: %{atom() => map_with_source_field}},
  asset_registry: %Rendro.AssetRegistry{assets: %{atom() => ...}}
}
```

PDF substring patterns (per RESEARCH.md "Don't Hand-Roll" + PATTERNS.md PDF assertion section):
```
"%PDF-"               # magic bytes (first 5 bytes)
"/F_BRAND_HEADING"    # font dict entry — uppercase atom-derived ID
"/FontFile2"          # embedded TrueType font stream
"/Type /XObject"      # image XObject marker
"/Subtype /Image"     # image XObject subtype
"/IM_COMPANY_LOGO"    # image dictionary entry — uppercase atom-derived ID
"/Filter /FlateDecode"  # PNG IDAT compression — Phase 28
"/Width 64"           # logo intrinsic width
"/Height 64"          # logo intrinsic height
"/Count "             # /Pages /Count for page count assertion
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Author test/rendro/recipes/branded_invoice_test.exs structural + boundary describe blocks</name>
  <read_first>
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-CONTEXT.md (D-02, D-04, D-23)
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-PATTERNS.md (`test/rendro/recipes/branded_invoice_test.exs` analog section, lines 449-566)
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-RESEARCH.md (Pitfall 6 lines 503-512 — non-vacuous registry assertion)
    - test/rendro/recipes/invoice_test.exs (mirror target — read entire file for describe-block layout, sample_data shape, helper functions)
    - lib/rendro/recipes/branded_invoice.ex (module under test — Plan 03 output)
    - lib/rendro/recipes.ex (delegate-parity test target)
  </read_first>
  <behavior>
    - Module name: `Rendro.Recipes.BrandedInvoiceTest`.
    - `use ExUnit.Case, async: true` (pure read-only assertions on returned structs; no shared registry state).
    - `defp sample_data/0` returns a deterministic data map containing `id`, `date`, `items`, AND `brand: %{font_name: :brand_heading, logo_name: :company_logo}`. Use literals only — no `Date.utc_today()`, no `:rand`.
    - Describe block 1: `page_template/1` — 3 tests asserting struct return, `:branded_invoice` name, and four region names.
    - Describe block 2: `sections/2` — 3 tests asserting list-of-4-sections, region coverage, and section names.
    - Describe block 3: `document/2` — 4 tests asserting struct return, `page_template == :branded_invoice`, brand font registered with `source: :embedded` under `:brand_heading`, brand logo registered under `:company_logo`.
    - Describe block 4: `validate_data!` (exercised through document/1 boundary) — 3 tests asserting `assert_raise ArgumentError` for: missing `:brand` key, `:brand` with non-atom `:font_name`, `:brand` with non-atom `:logo_name`.
    - Describe block 5: `Rendro.Recipes.branded_invoice/1 delegate` — 1 test asserting delegate returns same shape as `BrandedInvoice.document/1`.
    - Each test ≤ 10 LOC; the file in this task targets ~120 LOC. Regression and byte-identical blocks come in Task 2.
  </behavior>
  <files>
    - test/rendro/recipes/branded_invoice_test.exs (NEW — partial: structural + boundary + delegate blocks)
  </files>
  <action>
    Author `test/rendro/recipes/branded_invoice_test.exs` with the structural describe blocks below. The full-pipeline render regression and byte-identical 2-render blocks are added in Task 2 (same file).

    ```elixir
    defmodule Rendro.Recipes.BrandedInvoiceTest do
      use ExUnit.Case, async: true

      alias Rendro.Recipes.BrandedInvoice

      defp sample_data do
        %{
          id: "INV-2026-042",
          date: ~D[2026-04-30],
          items: [
            %{name: "Widget A", qty: 3, price: 200},
            %{name: "Widget B", qty: 1, price: 500}
          ],
          brand: %{font_name: :brand_heading, logo_name: :company_logo}
        }
      end

      describe "page_template/1" do
        test "returns a %Rendro.PageTemplate{} struct" do
          assert %Rendro.PageTemplate{} = BrandedInvoice.page_template()
        end

        test "template.name == :branded_invoice" do
          template = BrandedInvoice.page_template()
          assert template.name == :branded_invoice
        end

        test "template has all four named regions :logo, :header, :body, :footer" do
          template = BrandedInvoice.page_template()
          region_names = Enum.map(template.regions, & &1.name)
          assert :logo in region_names
          assert :header in region_names
          assert :body in region_names
          assert :footer in region_names
          assert length(region_names) >= 4
        end
      end

      describe "sections/2" do
        test "returns four %Rendro.Section{} structs" do
          sections = BrandedInvoice.sections(sample_data())
          assert length(sections) == 4
          assert Enum.all?(sections, &match?(%Rendro.Section{}, &1))
        end

        test "sections cover regions :logo, :header, :body, :footer" do
          sections = BrandedInvoice.sections(sample_data())
          region_targets = Enum.map(sections, & &1.region) |> Enum.sort()
          assert region_targets == [:body, :footer, :header, :logo]
        end

        test "section names are namespaced under :branded_invoice_*" do
          sections = BrandedInvoice.sections(sample_data())
          names = Enum.map(sections, & &1.name)
          assert Enum.any?(names, &(to_string(&1) =~ "branded_invoice"))
        end
      end

      describe "document/2" do
        test "returns a %Rendro.Document{} struct" do
          assert %Rendro.Document{} = BrandedInvoice.document(sample_data())
        end

        test "document.page_template == :branded_invoice" do
          doc = BrandedInvoice.document(sample_data())
          assert doc.page_template == :branded_invoice
        end

        test "brand font is registered with source: :embedded under data.brand.font_name (non-vacuous, Pitfall 6)" do
          data = sample_data()
          doc = BrandedInvoice.document(data)
          assert Map.has_key?(doc.font_registry.fonts, data.brand.font_name)
          assert match?(%{source: :embedded}, doc.font_registry.fonts[data.brand.font_name])
        end

        test "brand logo is registered under data.brand.logo_name in asset_registry" do
          data = sample_data()
          doc = BrandedInvoice.document(data)
          assert Map.has_key?(doc.asset_registry.assets, data.brand.logo_name)
        end
      end

      describe "validate_data! (boundary validation D-04)" do
        test "raises ArgumentError when data.brand is missing" do
          assert_raise ArgumentError, ~r/data\.brand/, fn ->
            BrandedInvoice.document(%{
              id: "INV-001", date: ~D[2026-01-15], items: []
            })
          end
        end

        test "raises ArgumentError when data.brand.font_name is not an atom" do
          assert_raise ArgumentError, ~r/data\.brand/, fn ->
            BrandedInvoice.document(%{
              id: "INV-001", date: ~D[2026-01-15], items: [],
              brand: %{font_name: "brand_heading", logo_name: :company_logo}
            })
          end
        end

        test "raises ArgumentError when data.brand.logo_name is not an atom" do
          assert_raise ArgumentError, ~r/data\.brand/, fn ->
            BrandedInvoice.document(%{
              id: "INV-001", date: ~D[2026-01-15], items: [],
              brand: %{font_name: :brand_heading, logo_name: "company_logo"}
            })
          end
        end

        test "sections/2 also enforces validation (boundary at both entry points)" do
          assert_raise ArgumentError, ~r/data\.brand/, fn ->
            BrandedInvoice.sections(%{id: "X", date: ~D[2026-01-15], items: []})
          end
        end
      end

      describe "Rendro.Recipes.branded_invoice/1 delegate (D-03)" do
        test "returns the same %Rendro.Document{} shape as BrandedInvoice.document/1" do
          data = sample_data()
          via_delegate = Rendro.Recipes.branded_invoice(data)
          via_module = BrandedInvoice.document(data)

          # Compare structural fields that should be deterministically equal:
          assert via_delegate.page_template == via_module.page_template
          assert Map.keys(via_delegate.font_registry.fonts) ==
                   Map.keys(via_module.font_registry.fonts)
          assert Map.keys(via_delegate.asset_registry.assets) ==
                   Map.keys(via_module.asset_registry.assets)
          assert length(via_delegate.sections) == length(via_module.sections)
        end
      end
    end
    ```

    Concrete requirements:
    - File path EXACTLY `test/rendro/recipes/branded_invoice_test.exs`.
    - `use ExUnit.Case, async: true`.
    - The 5 describe blocks above MUST be present; Task 2 adds 2 more (regression + byte-identical).
    - Sample data is a private function returning a literal map — no env vars, no time-based fields, no `:rand`.
    - The `:brand_heading` and `:company_logo` atoms are the canonical logical names used throughout Phase 29; using anything else here causes drift across plans.
    - Pitfall 6 mitigation: NEVER assert `map_size(doc.font_registry.fonts) >= 1` — that's vacuously true (default Helvetica seed); always assert with `Map.has_key?/2` on the brand atom AND match `%{source: :embedded}`.
    - DO NOT call `mix.exs` / `File.read!` directly here; the registry round-trip is via `BrandedInvoice.document/1`.
    - DO NOT add render/regression assertions here; those go in Task 2.

    Verify:
    ```bash
    mix test test/rendro/recipes/branded_invoice_test.exs
    ```

    All ~14 tests in the 5 describe blocks MUST pass.
  </action>
  <acceptance_criteria>
    - `test -f test/rendro/recipes/branded_invoice_test.exs` exits 0
    - `grep -Eq '^defmodule Rendro\.Recipes\.BrandedInvoiceTest do$' test/rendro/recipes/branded_invoice_test.exs` exits 0
    - `grep -Fq 'use ExUnit.Case, async: true' test/rendro/recipes/branded_invoice_test.exs` exits 0
    - `grep -cE 'describe "(page_template/1|sections/2|document/2|validate_data!|Rendro\.Recipes\.branded_invoice)' test/rendro/recipes/branded_invoice_test.exs` outputs at least `5`
    - `grep -Fq 'sample_data' test/rendro/recipes/branded_invoice_test.exs` exits 0
    - `grep -Fq ':brand_heading' test/rendro/recipes/branded_invoice_test.exs` exits 0
    - `grep -Fq ':company_logo' test/rendro/recipes/branded_invoice_test.exs` exits 0
    - `grep -Fq 'Map.has_key?(doc.font_registry.fonts' test/rendro/recipes/branded_invoice_test.exs` exits 0  (Pitfall 6 — non-vacuous)
    - `grep -Fq 'source: :embedded' test/rendro/recipes/branded_invoice_test.exs` exits 0  (Pitfall 6)
    - `grep -cE 'assert_raise ArgumentError' test/rendro/recipes/branded_invoice_test.exs` outputs at least `4`
    - Anti-pattern absence: `! grep -Fq 'map_size(doc.font_registry.fonts) >= 1' test/rendro/recipes/branded_invoice_test.exs`  (Pitfall 6 — explicitly forbidden vacuous form)
    - `mix test test/rendro/recipes/branded_invoice_test.exs` exits 0 (all describe blocks pass)
  </acceptance_criteria>
  <verify>
    <automated>mix test test/rendro/recipes/branded_invoice_test.exs && grep -Eq '^defmodule Rendro\.Recipes\.BrandedInvoiceTest do$' test/rendro/recipes/branded_invoice_test.exs && [ "$(grep -cE 'describe "(page_template/1|sections/2|document/2|validate_data!|Rendro\.Recipes\.branded_invoice)' test/rendro/recipes/branded_invoice_test.exs)" -ge 5 ] && grep -Fq 'source: :embedded' test/rendro/recipes/branded_invoice_test.exs && [ "$(grep -cE 'assert_raise ArgumentError' test/rendro/recipes/branded_invoice_test.exs)" -ge 4 ] && ! grep -Fq 'map_size(doc.font_registry.fonts) >= 1' test/rendro/recipes/branded_invoice_test.exs</automated>
  </verify>
  <done>
    test/rendro/recipes/branded_invoice_test.exs exists with 5 describe blocks (`page_template/1`, `sections/2`, `document/2`, `validate_data!`, `Rendro.Recipes.branded_invoice/1 delegate`) totaling ~14 tests. Tests pass under `mix test`. Brand-font registry assertion uses `Map.has_key?/2` + `source: :embedded` (Pitfall 6 — non-vacuous). Boundary-validation asserts `ArgumentError` on three malformation cases plus an entry-via-`sections/2` case.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Append full-pipeline render regression + byte-identical 2-render describe blocks</name>
  <read_first>
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-CONTEXT.md (D-25, D-27, D-30)
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-PATTERNS.md ("PDF-substring regression pattern" lines 531-554; "Byte-identical regression pattern" lines 424-444; "Shared Patterns: PDF-substring assertion" lines 1038-1051)
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-RESEARCH.md ("Don't Hand-Roll" PDF substring row line 408; "Determinism & verification posture" D-30 line 62-65)
    - test/rendro/pdf/writer_test.exs (PDF substring assertion patterns: /F_BRAND, /Subtype /TrueType, /FontDescriptor, /FontFile2, /Type /XObject, /Subtype /Image, /Width N, /Height N, /IM_LOGO_PNG)
    - test/rendro/deterministic_test.exs (byte-identical 2-render pattern at lines 13-19)
    - lib/rendro/recipes/branded_invoice.ex (module under test)
    - lib/rendro.ex (Rendro.render/2 signature; deterministic: true opt)
  </read_first>
  <behavior>
    - Append 2 new describe blocks to `test/rendro/recipes/branded_invoice_test.exs` (existing file from Task 1).
    - Describe block 6: `regression: full-pipeline render` — runs `BrandedInvoice.document(sample_data) |> Rendro.render()` and asserts on:
      - `binary_part(pdf, 0, 5) == "%PDF-"` (magic bytes)
      - `pdf =~ "/F_BRAND_HEADING"` (font dict for brand logical name; convention: uppercase atom-derived ID)
      - `pdf =~ "/Subtype /TrueType"` (font subtype)
      - `pdf =~ "/FontFile2"` (embedded TrueType binary stream)
      - `pdf =~ "/Type /XObject"` AND `pdf =~ "/Subtype /Image"` (logo XObject)
      - `pdf =~ "/IM_COMPANY_LOGO"` (image dictionary entry)
      - `pdf =~ "/Width 64"` AND `pdf =~ "/Height 64"` (intrinsic logo dimensions from Plan 01 PNG)
      - `pdf =~ "/Count "` (Pages catalog has a Count entry — page count proxy; structural)
      - `is_binary(pdf)` AND `byte_size(pdf) > 1000` (sanity floor — a real branded invoice PDF will easily exceed 1 KB).
    - Describe block 7: `regression: byte-identical two-render (D-25 internal-only, NOT public per D-30)` — calls `Rendro.render(doc, deterministic: true)` twice and asserts `pdf1 == pdf2`. Single test. The describe block's @doc/leading comment MUST cite D-30 explicitly: this is a NARROW INTERNAL REGRESSION, NOT a public byte-stability promise.
    - Tests use the same `sample_data/0` defined in Task 1 (do NOT redefine).
    - Atom name conventions per Phase 26 D-13/Phase 28: brand font logical name `:brand_heading` becomes uppercase `F_BRAND_HEADING` font dict key; brand logo logical name `:company_logo` becomes `IM_COMPANY_LOGO` image dict key. If executor finds the writer encodes these differently, READ `lib/rendro/pdf/writer.ex` (or the relevant writer) to confirm the actual rule and update only the substring; the structural shape (entry exists for the brand atom) is the contract.
  </behavior>
  <files>
    - test/rendro/recipes/branded_invoice_test.exs (MODIFIED — append 2 new describe blocks)
  </files>
  <action>
    Append the following describe blocks to the file authored in Task 1, INSIDE the existing module body, AFTER the existing 5 describe blocks and BEFORE the closing `end` of `defmodule Rendro.Recipes.BrandedInvoiceTest do`:

    ```elixir
      describe "regression: full-pipeline render (D-27)" do
        @tag :regression
        test "renders a complete PDF with brand font dict, font stream, and logo XObject" do
          doc = BrandedInvoice.document(sample_data())
          assert {:ok, pdf} = Rendro.render(doc)

          # Magic bytes
          assert is_binary(pdf)
          assert binary_part(pdf, 0, 5) == "%PDF-"

          # Sanity floor: a real branded invoice PDF will easily exceed 1 KB.
          assert byte_size(pdf) > 1_000

          # Font dictionary structural assertions (Phase 26 D-13/D-14):
          # logical atom :brand_heading becomes the uppercase token F_BRAND_HEADING
          # in PDF resource references. The structural contract is "entry exists
          # for the brand atom"; the exact uppercase rule is owned by the writer.
          assert pdf =~ "/F_BRAND_HEADING"
          assert pdf =~ "/Subtype /TrueType"
          assert pdf =~ "/FontDescriptor"
          assert pdf =~ "/FontFile2"

          # Image XObject structural assertions (Phase 28):
          assert pdf =~ "/Type /XObject"
          assert pdf =~ "/Subtype /Image"
          assert pdf =~ "/IM_COMPANY_LOGO"
          assert pdf =~ "/Width 64"
          assert pdf =~ "/Height 64"

          # Page catalog has a /Count entry (page count is bounded by content).
          assert pdf =~ "/Count "
        end

        test "header section authors text using the brand-named logical font" do
          doc = BrandedInvoice.document(sample_data())
          # Header section must reference the brand font in its content tree.
          [_logo, header | _] = doc.sections
          rendered = inspect(header.content, limit: :infinity, structs: false)
          assert rendered =~ ":brand_heading"
        end
      end

      describe "regression: byte-identical two-render (D-25 internal-only; D-30 — NOT a public byte-stability contract)" do
        # Per CONTEXT.md D-30 + Phase 26 D-15/D-16: whole-file PDF byte identity is
        # explicitly NOT a public guarantee. This single test exists ONLY as a
        # narrow internal regression to detect accidental nondeterminism in the
        # branded recipe path. If this test fails, the fix is to find the source
        # of nondeterminism in the recipe (NOT to relax the test).
        @tag :regression
        test "two consecutive deterministic renders of BrandedInvoice produce identical binaries" do
          doc = BrandedInvoice.document(sample_data())
          assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
          assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
          assert pdf1 == pdf2
        end
      end
    ```

    Concrete requirements:
    - Append (do not overwrite) — the existing 5 describe blocks from Task 1 stay.
    - The byte-identical describe block's leading comment MUST literally cite "D-30" (this is the audit signal that the test author understood the determinism contract).
    - `Rendro.render/1` is called WITHOUT `deterministic: true` in the structural-substring regression block (substring assertions don't need determinism; the bytes only need to contain those tokens). The byte-identical block uses `deterministic: true`.
    - The `header section` test asserts the brand atom appears somewhere in the header section's content tree — exact assertion shape may need adjustment if `Rendro.text/2`'s `:font` opt is stored differently (executor reads `lib/rendro/text.ex` or wherever the text struct lives to confirm).
    - Both new describe blocks tagged with `@tag :regression` so the test suite can opt-in/opt-out via `mix test --exclude regression` if needed (defensive against slow tests; doesn't hide them — `mix test` with no flags runs them by default).
    - DO NOT assert whole-PDF byte identity against a checked-in fixture file (that would be a public contract per D-30).
    - DO NOT loosen the byte-identical assertion to "approximately equal" or "same length" — equality is the contract.
    - DO NOT redefine `sample_data/0` — it lives in Task 1's part of the file.

    Verify:
    ```bash
    mix test test/rendro/recipes/branded_invoice_test.exs
    ```

    All ~17-18 tests across 7 describe blocks MUST pass.

    If `Rendro.render/2` fails at any pipeline stage in the regression test (e.g., :measure, :paginate, :render returning `{:error, ...}`), that's a real bug — DO NOT skip the test or wrap in `try`. The recipe and the assets in Plans 01-03 must compose into a renderable document; failure here is a Phase 29 implementation bug to fix at the source.

    The exact uppercase atom-derived font/image ID convention should be confirmed once via `iex` probe at execution time:
    ```bash
    mix run -e '
      doc = Rendro.Recipes.BrandedInvoice.document(%{
        id: "X", date: ~D[2026-01-15], items: [],
        brand: %{font_name: :brand_heading, logo_name: :company_logo}
      })
      {:ok, pdf} = Rendro.render(doc)
      pdf
      |> :binary.matches(["/F_BRAND_HEADING", "/IM_COMPANY_LOGO"])
      |> IO.inspect(label: "matches")
    '
    ```

    If the matches list is non-empty, the assertions stand. If empty, the executor must inspect the actual PDF byte layout (`mix run -e '... IO.puts(pdf)'` or write to a tmpfile and grep) to find the actual encoding and update the substring tokens — the structural contract ("brand-name appears in font dict / image dict") is what matters; the exact prefix is owned by the writer.
  </action>
  <acceptance_criteria>
    - `grep -cE 'describe "regression: ' test/rendro/recipes/branded_invoice_test.exs` outputs `2`
    - `grep -Fq '"%PDF-"' test/rendro/recipes/branded_invoice_test.exs` exits 0
    - `grep -Fq '/F_BRAND_HEADING' test/rendro/recipes/branded_invoice_test.exs` exits 0
    - `grep -Fq '/FontFile2' test/rendro/recipes/branded_invoice_test.exs` exits 0
    - `grep -Fq '/Type /XObject' test/rendro/recipes/branded_invoice_test.exs` exits 0
    - `grep -Fq '/Subtype /Image' test/rendro/recipes/branded_invoice_test.exs` exits 0
    - `grep -Fq '/IM_COMPANY_LOGO' test/rendro/recipes/branded_invoice_test.exs` exits 0
    - `grep -Fq '/Width 64' test/rendro/recipes/branded_invoice_test.exs` exits 0
    - `grep -Fq '/Height 64' test/rendro/recipes/branded_invoice_test.exs` exits 0
    - `grep -Fq 'deterministic: true' test/rendro/recipes/branded_invoice_test.exs` exits 0
    - `grep -Fq 'pdf1 == pdf2' test/rendro/recipes/branded_invoice_test.exs` exits 0
    - `grep -Fq 'D-30' test/rendro/recipes/branded_invoice_test.exs` exits 0  (audit signal that author understood the contract)
    - `grep -cE '@tag :regression' test/rendro/recipes/branded_invoice_test.exs` outputs at least `2`
    - `mix test test/rendro/recipes/branded_invoice_test.exs` exits 0 (all describe blocks pass, both regression and byte-identical)
    - All 5 describe blocks from Task 1 still present: `grep -cE 'describe "(page_template/1|sections/2|document/2|validate_data!|Rendro\.Recipes\.branded_invoice)' test/rendro/recipes/branded_invoice_test.exs` outputs at least `5`
  </acceptance_criteria>
  <verify>
    <automated>mix test test/rendro/recipes/branded_invoice_test.exs && [ "$(grep -cE 'describe "regression: ' test/rendro/recipes/branded_invoice_test.exs)" = "2" ] && grep -Fq '/F_BRAND_HEADING' test/rendro/recipes/branded_invoice_test.exs && grep -Fq '/FontFile2' test/rendro/recipes/branded_invoice_test.exs && grep -Fq '/IM_COMPANY_LOGO' test/rendro/recipes/branded_invoice_test.exs && grep -Fq 'deterministic: true' test/rendro/recipes/branded_invoice_test.exs && grep -Fq 'pdf1 == pdf2' test/rendro/recipes/branded_invoice_test.exs && grep -Fq 'D-30' test/rendro/recipes/branded_invoice_test.exs</automated>
  </verify>
  <done>
    Two new describe blocks appended to test/rendro/recipes/branded_invoice_test.exs covering: (1) full-pipeline render regression with structural assertions on PDF magic bytes, brand font dict (`/F_BRAND_HEADING`), embedded font stream (`/FontFile2`), logo XObject (`/Type /XObject`, `/Subtype /Image`, `/IM_COMPANY_LOGO`, `/Width 64`, `/Height 64`), page count entry; (2) two-render byte-identical assertion under `deterministic: true` with explicit D-30 callout that this is internal-only. All 7 describe blocks pass under `mix test`.
  </done>
</task>

</tasks>

<verification>
- `mix test test/rendro/recipes/branded_invoice_test.exs` exits 0 with all describe blocks passing
- `mix test test/rendro/recipes/branded_invoice_test.exs --exclude regression` runs structural+boundary tests only (sanity check that tags work)
- File contains exactly 7 describe blocks: `page_template/1`, `sections/2`, `document/2`, `validate_data!`, `Rendro.Recipes.branded_invoice/1 delegate`, `regression: full-pipeline render`, `regression: byte-identical two-render`
- File length: ~180-220 LOC (range — adjust as needed for clarity)
- `git diff --quiet HEAD lib/rendro/recipes/invoice.ex` exits 0 (D-06 — frozen Invoice never touched by this plan)
- All Pitfall 6 mitigations applied (no vacuous `map_size >= 1` patterns)
- D-30 explicit citation present in byte-identical describe block
</verification>

<success_criteria>
- `Rendro.Recipes.BrandedInvoice` recipe shape is regression-locked at every public function (D-02, D-23 backed by tests).
- `validate_data!/1` boundary is asserted with `assert_raise ArgumentError` on three malformation modes plus an entry-via-`sections/2` case (D-04).
- Full-pipeline render regression covers PDF magic bytes, font dictionary entry, embedded font stream, image XObject dictionary, intrinsic logo dimensions, and page count entry (D-27 — satisfies QUAL-07's "committed regression tests" arm without elevating whole-PDF byte identity to public contract).
- Byte-identical 2-render regression locks deterministic-mode determinism for the branded path (D-25), with explicit D-30 callout that this is internal-only.
- `Rendro.Recipes.branded_invoice/1` delegate parity is regression-tested (D-03).
- No vacuous registry assertions (Pitfall 6 mitigation enforced via grep gates).
- Test file is self-contained — uses `sample_data/0` literal and consumes only public APIs from Plans 02 and 03.
</success_criteria>

<output>
After completion, create `.planning/phases/29-branded-recipes-docs-and-proof-closure/29-04-SUMMARY.md` documenting:
- Final test count (target: ~17-18 tests across 7 describe blocks)
- `mix test test/rendro/recipes/branded_invoice_test.exs` pass/fail count
- Confirmation that the byte-identical 2-render passes (deterministic mode is honored end-to-end for the branded path)
- The exact PDF substring tokens that matched (`/F_BRAND_HEADING`, `/IM_COMPANY_LOGO`, etc.) — confirming the writer's atom-uppercase convention
- If any substring needed adjustment from the plan's defaults (e.g., the writer uses a different prefix), document the actual token observed and why the structural contract still holds.
- Confirmation that no Pitfall 6 vacuous patterns exist (`! grep -Fq 'map_size(doc.font_registry.fonts) >= 1'` passes)
</output>
</content>
</invoke>