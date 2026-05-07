---
phase: 29
plan: 03
type: execute
wave: 2
depends_on: [01, 02]
files_modified:
  - lib/rendro/recipes/branded_invoice.ex
  - lib/rendro/recipes.ex
autonomous: true
requirements: [LAY-13]
requirements_addressed: [LAY-13]

must_haves:
  truths:
    - "Rendro.Recipes.BrandedInvoice is a NEW sibling module at lib/rendro/recipes/branded_invoice.ex; lib/rendro/recipes/invoice.ex is NOT modified (D-01, D-06)"
    - "BrandedInvoice exposes Tiered Composition trio: document/2, page_template/1, sections/2 — exact arity and @spec mirror of Rendro.Recipes.Invoice (D-02)"
    - "page_template/1 returns a %Rendro.PageTemplate{name: :branded_invoice} with FOUR named regions: :logo, :header, :body, :footer (D-02)"
    - "sections/2 returns a list of %Rendro.Section{} mapped to the four regions; first call inside is validate_data!/1 (D-02, D-04)"
    - "document/2 calls validate_data!/1 first, then composes Rendro.Document.new |> register_embedded_font(brand.font_name, {:path, Rendro.Branded.font_path()}) |> register_image(brand.logo_name, {:path, Rendro.Branded.logo_path()}) |> add_template |> set_template |> reduce add_section (D-02, D-05, D-10, D-31)"
    - "validate_data!/1 raises ArgumentError when data.brand is missing or :font_name/:logo_name aren't atoms — hard fail, NO silent unbranded fallback (D-04, METHODOLOGY 'Boundary Validation First')"
    - "register_embedded_font/3 and register_image/3 are called with {:path, _} tuples — NOT pre-read binaries; the registries normalize internally (D-05)"
    - "Three module doctests on BrandedInvoice mirroring Invoice doctest style: page_template/1 (struct shape), sections/2 (list shape), document/2 (returns %Rendro.Document{page_template: :branded_invoice} given minimal data) (D-23)"
    - "Rendro.Recipes.branded_invoice/1 delegate added in lib/rendro/recipes.ex right below the existing invoice/1 delegate, with parallel @doc + @spec, calling Rendro.Recipes.BrandedInvoice.document/1 (D-03)"
    - "No system-font discovery, no remote asset fetching, no ambient OS state in any recipe path (D-31 carried forward)"
    - "Rendro.Recipes.Invoice public contract is FROZEN — no edits to its file, doctests, or shipped behavior (D-06)"
  artifacts:
    - path: "lib/rendro/recipes/branded_invoice.ex"
      provides: "Rendro.Recipes.BrandedInvoice with document/2, page_template/1, sections/2 + private builders + validate_data!/1"
      exports: ["document/1", "document/2", "page_template/0", "page_template/1", "sections/1", "sections/2"]
      contains: ["defmodule Rendro.Recipes.BrandedInvoice", "register_embedded_font", "register_image", "Rendro.Branded.font_path", "Rendro.Branded.logo_path", "validate_data!", ":branded_invoice", ":logo", "iex>"]
    - path: "lib/rendro/recipes.ex"
      provides: "Public top-level Rendro.Recipes.branded_invoice/1 delegate"
      exports: ["branded_invoice/1", "invoice/1"]
      contains: ["def branded_invoice(data)", "Rendro.Recipes.BrandedInvoice.document(data)"]
  key_links:
    - from: "lib/rendro/recipes/branded_invoice.ex"
      to: "lib/rendro/branded.ex (Plan 02)"
      via: "Rendro.Branded.font_path/0 and Rendro.Branded.logo_path/0 calls inside document/2"
      pattern: "Rendro\\.Branded\\.(font|logo)_path"
    - from: "lib/rendro/recipes/branded_invoice.ex"
      to: "lib/rendro/document.ex"
      via: "Rendro.Document.register_embedded_font/3 + register_image/3 with {:path, _}"
      pattern: "Rendro\\.Document\\.register_(embedded_font|image)"
    - from: "lib/rendro/recipes.ex"
      to: "lib/rendro/recipes/branded_invoice.ex"
      via: "Rendro.Recipes.branded_invoice/1 calls Rendro.Recipes.BrandedInvoice.document/1"
      pattern: "Rendro\\.Recipes\\.BrandedInvoice\\.document"
---

<objective>
Ship `Rendro.Recipes.BrandedInvoice` — the canonical branded recipe — as a NEW sibling module to `Rendro.Recipes.Invoice` (D-01), mirroring the locked Tiered Composition surface verbatim (D-02). Differences from the unbranded recipe live entirely inside:
- `page_template/1`: adds a `:logo` region (regions become `:logo`, `:header`, `:body`, `:footer`).
- `sections/2`: prepends `validate_data!/1` and adds `logo_section/1`; `header_section/1` authors text with the brand font.
- `document/2`: registers brand font + logo on the document via `Rendro.Document.register_embedded_font/3` and `Rendro.Document.register_image/3` BEFORE template/section composition (D-05, D-10).

Also adds the `Rendro.Recipes.branded_invoice/1` shortcut delegate alongside the existing `invoice/1` (D-03), keeping discovery symmetrical.

This plan implements D-01, D-02, D-03, D-04, D-05, D-06, D-23 and re-affirms D-31 for the recipe path.

Purpose: Provide the complete authoring API the Phoenix example (Plan 07), regression tests (Plan 04), guide fences (Plan 05), and docs-contract tests (Plan 06) all depend on. Without this module, none of the downstream verification surfaces have a target.

Output: One new ~150-line `lib/` module with three doctests + a tiny edit (~12 lines) to `lib/rendro/recipes.ex`.
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
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-01-PLAN.md
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-02-PLAN.md

# Mirror target (D-02, D-06: frozen — DO NOT modify):
@lib/rendro/recipes/invoice.ex

# Where the new delegate lands:
@lib/rendro/recipes.ex

# Resolver consumed by document/2 (Plan 02 output):
@lib/rendro/branded.ex

# Document builder API used by document/2:
@lib/rendro/document.ex

# Authoring helpers used by sections:
@lib/rendro.ex
@lib/rendro/component.ex

<interfaces>
<!-- Public API contracts the recipe consumes — extracted so the executor needs zero codebase exploration. -->

From lib/rendro/document.ex (verified at lines 156-200):
```elixir
@spec register_embedded_font(t(), atom(), {:path, Path.t()} | {:binary, binary()}) :: t()
def register_embedded_font(%__MODULE__{} = doc, logical_name, source)

@spec register_image(t(), atom(), {:path, Path.t()} | {:binary, binary()}) :: t()
def register_image(%__MODULE__{} = doc, logical_name, source)

@spec add_template(t(), Rendro.PageTemplate.t()) :: t()
@spec set_template(t(), atom()) :: t()
@spec add_section(t(), Rendro.Section.t()) :: t()
@spec new() :: t()
```

From lib/rendro/branded.ex (Plan 02 output):
```elixir
@spec font_path() :: Path.t()    # → priv/branded/fonts/B612-Regular.ttf
@spec logo_path() :: Path.t()    # → priv/branded/images/rendro-logo.png
```

From lib/rendro.ex (authoring helpers):
```elixir
def page_template(opts)        # Rendro.page_template(name: :branded_invoice, regions: [...])
def section(opts)              # Rendro.section(name: ..., region: ..., content: [...])
def block(content_or_struct)   # wraps content in a %Rendro.Block{}
def text(content, opts)        # text node — opts include :size, :font (logical name atom)
def table(rows, opts)          # tabular content
def image(logical_name, opts)  # %Rendro.Image{logical_name: ..., width: ..., height: ...} (Phase 28)
```

From lib/rendro/error.ex (used in doctest if needed):
```elixir
%Rendro.Error{stage, reason, details, what, where, why, next, render_id}
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Author lib/rendro/recipes/branded_invoice.ex with three doctests</name>
  <read_first>
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-CONTEXT.md (D-01..D-06, D-10, D-23, D-31; "Claude's discretion" item — exact field names inside data.brand)
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-RESEARCH.md ("Pattern 1: Tiered Composition Mirror" lines 261-353; "Anti-Patterns to Avoid" lines 386-394; Pitfall 3 lines 444-455 — doctest mechanics; Pitfall 6 lines 503-512 — registry assertion shape)
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-PATTERNS.md (`lib/rendro/recipes/branded_invoice.ex` analog section, lines 33-188; "Tiered Composition surface" shared pattern, lines 980-984)
    - lib/rendro/recipes/invoice.ex (mirror target — read entire file; D-06 says it is FROZEN)
    - lib/rendro/document.ex (verify register_embedded_font/3 + register_image/3 + add_template/2 + set_template/2 + add_section/2 signatures)
    - lib/rendro/branded.ex (just authored in Plan 02 — confirms font_path/0 + logo_path/0 are available)
    - lib/rendro.ex (verify page_template/1, section/1, block/1, text/2, table/2, image/2 signatures)
  </read_first>
  <behavior>
    - Public surface: `document/2`, `page_template/1`, `sections/2` with @spec exactly mirroring `Rendro.Recipes.Invoice` arities (`document/2`, `page_template/1`, `sections/2`); each also takes `data` only (delegate-friendly arity for `Rendro.Recipes.branded_invoice/1`).
    - `page_template(opts \\ [])` returns `%Rendro.PageTemplate{name: :branded_invoice}` with FOUR named regions `:logo`, `:header`, `:body`, `:footer` (D-02).
    - `sections(data, opts \\ [])` calls `validate_data!(data)` first; returns `[logo_section(data), header_section(data), body_section(data), footer_section(data)]`.
    - `document(data, opts \\ [])` calls `validate_data!(data)` first, then composes:
      ```
      Rendro.Document.new()
      |> Rendro.Document.register_embedded_font(data.brand.font_name, {:path, Rendro.Branded.font_path()})
      |> Rendro.Document.register_image(data.brand.logo_name, {:path, Rendro.Branded.logo_path()})
      |> Rendro.Document.add_template(template)
      |> Rendro.Document.set_template(template.name)
      |> reduce add_section/2 over sections
      ```
    - `validate_data!(%{brand: %{font_name: f, logo_name: l}})` when `is_atom(f) and is_atom(l)` → `:ok`; otherwise raises `ArgumentError` with concrete message.
    - Doctest 1 (`page_template/1`): asserts return matches `%Rendro.PageTemplate{name: :branded_invoice}`.
    - Doctest 2 (`sections/2`): given a minimal data map (with `brand:` populated), asserts the returned list has length 4 and includes a section with `region: :logo`.
    - Doctest 3 (`document/2`): given a minimal data map, asserts return matches `%Rendro.Document{page_template: :branded_invoice}` AND `Map.has_key?(doc.font_registry.fonts, :brand_heading)` AND `Map.has_key?(doc.asset_registry.assets, :company_logo)`.
  </behavior>
  <files>
    - lib/rendro/recipes/branded_invoice.ex (NEW)
  </files>
  <action>
    Author `lib/rendro/recipes/branded_invoice.ex` mirroring `lib/rendro/recipes/invoice.ex` line-by-line, with the differences below. Per D-02 the public surface is verbatim — only private builder bodies and the `:logo` region are different.

    Field-name choice (Claude's discretion per CONTEXT.md): use `:font_name` and `:logo_name` inside `data.brand`. Rationale — these are the most read-natural in doctests ("font_name: :brand_heading, logo_name: :company_logo") and match the RESEARCH.md skeleton verbatim. Document the choice in the @moduledoc.

    Skeleton (per RESEARCH.md "Pattern 1" lines 261-353 + PATTERNS.md analog lines 33-188):

    ```elixir
    defmodule Rendro.Recipes.BrandedInvoice do
      @moduledoc """
      Branded canonical invoice recipe using the Tiered Composition pattern.

      Differs from `Rendro.Recipes.Invoice` only in:

        * `page_template/1` adds a `:logo` region beside `:header`.
        * `sections/2` includes the brand logo via `Rendro.image/2` and authors
          header text using a brand-named logical font.
        * `document/2` registers the brand font and logo on the returned document
          before assembling templates and sections.

      ## Data shape

      The recipe drives branding through `data.brand`:

          data = %{
            id: "INV-001",
            date: ~D[2026-01-15],
            items: [...],
            brand: %{font_name: :brand_heading, logo_name: :company_logo}
          }

      `data.brand.font_name` and `data.brand.logo_name` MUST be atoms; missing or
      non-atom values raise `ArgumentError` (per the "Boundary Validation First"
      methodology — no silent unbranded fallback).

      The actual brand font and logo bytes are resolved through `Rendro.Branded`,
      which ships demo assets (B612 Regular SIL OFL 1.1 + a 64×64 PNG mark) under
      `priv/branded/`. Adopters who copy this recipe to author their own brand
      should swap the `Rendro.Branded` calls for their own asset bytes.

      ## Usage

      ### Zero-to-one

          data = %{
            id: "INV-001", date: ~D[2026-01-15], items: [...],
            brand: %{font_name: :brand_heading, logo_name: :company_logo}
          }
          doc  = Rendro.Recipes.BrandedInvoice.document(data)
          {:ok, pdf} = Rendro.render(doc)

      ### Layout-only

          template = Rendro.Recipes.BrandedInvoice.page_template()

      ### Content-only

          sections = Rendro.Recipes.BrandedInvoice.sections(data)
      """

      @doc """
      Returns a `%Rendro.PageTemplate{}` with four named regions:
      `:logo`, `:header`, `:body`, `:footer`.

      ## Examples

          iex> template = Rendro.Recipes.BrandedInvoice.page_template()
          iex> template.name
          :branded_invoice
          iex> Enum.map(template.regions, & &1.name) |> Enum.sort()
          [:body, :footer, :header, :logo]
      """
      @spec page_template(keyword()) :: Rendro.PageTemplate.t()
      def page_template(opts \\ []) do
        defaults = [
          name: :branded_invoice,
          regions: [
            Rendro.region(name: :logo),
            Rendro.region(name: :header),
            Rendro.region(name: :body),
            Rendro.region(name: :footer)
          ]
        ]

        Rendro.page_template(Keyword.merge(defaults, opts))
      end

      @doc """
      Returns a list of `%Rendro.Section{}` structs covering all four regions.

      ## Examples

          iex> data = %{
          ...>   id: "INV-001", date: ~D[2026-01-15],
          ...>   items: [%{name: "Widget", qty: 1, price: 100}],
          ...>   brand: %{font_name: :brand_heading, logo_name: :company_logo}
          ...> }
          iex> sections = Rendro.Recipes.BrandedInvoice.sections(data)
          iex> length(sections)
          4
          iex> Enum.map(sections, & &1.region) |> Enum.sort()
          [:body, :footer, :header, :logo]
      """
      @spec sections(map(), keyword()) :: [Rendro.Section.t()]
      def sections(data, _opts \\ []) do
        validate_data!(data)

        [
          logo_section(data),
          header_section(data),
          body_section(data),
          footer_section(data)
        ]
      end

      @doc """
      Assembles a complete `%Rendro.Document{}` ready for `Rendro.render/1`.

      Registers the brand font and logo on the document via the public
      `Rendro.Document.register_embedded_font/3` and `Rendro.Document.register_image/3`
      APIs, then assembles the page template and sections.

      ## Examples

          iex> data = %{
          ...>   id: "INV-001", date: ~D[2026-01-15],
          ...>   items: [%{name: "Widget", qty: 1, price: 100}],
          ...>   brand: %{font_name: :brand_heading, logo_name: :company_logo}
          ...> }
          iex> doc = Rendro.Recipes.BrandedInvoice.document(data)
          iex> doc.page_template
          :branded_invoice
          iex> Map.has_key?(doc.font_registry.fonts, :brand_heading)
          true
          iex> Map.has_key?(doc.asset_registry.assets, :company_logo)
          true
      """
      @spec document(map(), keyword()) :: Rendro.Document.t()
      def document(data, opts \\ []) do
        validate_data!(data)

        template = page_template(opts)
        secs = sections(data, opts)

        base_doc =
          Rendro.Document.new()
          |> Rendro.Document.register_embedded_font(
               data.brand.font_name,
               {:path, Rendro.Branded.font_path()})
          |> Rendro.Document.register_image(
               data.brand.logo_name,
               {:path, Rendro.Branded.logo_path()})
          |> Rendro.Document.add_template(template)
          |> Rendro.Document.set_template(template.name)

        Enum.reduce(secs, base_doc, fn section, doc ->
          Rendro.Document.add_section(doc, section)
        end)
      end

      # ---- private builders ----

      defp logo_section(%{brand: %{logo_name: logo}} = _data) do
        Rendro.section(
          name: :branded_invoice_logo,
          region: :logo,
          content: [Rendro.block(Rendro.image(logo, width: 64, height: 64))]
        )
      end

      defp header_section(%{id: id, date: date, brand: %{font_name: brand_font}} = _data) do
        Rendro.section(
          name: :branded_invoice_header,
          region: :header,
          content: [
            Rendro.block(Rendro.text("INVOICE ##{id}", size: 18, font: brand_font)),
            Rendro.block(Rendro.text("Date: #{date}", size: 10))
          ]
        )
      end

      defp body_section(%{items: items} = _data) do
        rows =
          Enum.map(items, fn item ->
            [item.name, Integer.to_string(item.qty), "$#{item.price}"]
          end)

        table =
          Rendro.table(rows,
            header: ["Item", "Qty", "Price"],
            columns: [{:share, 1}, {:fixed, 50}, {:fixed, 80}]
          )

        Rendro.section(
          name: :branded_invoice_body,
          region: :body,
          content: [Rendro.block(table)]
        )
      end

      defp footer_section(%{id: id} = _data) do
        Rendro.section(
          name: :branded_invoice_footer,
          region: :footer,
          content: [Rendro.block(Rendro.text("Thank you — ##{id}", size: 9))]
        )
      end

      # ---- boundary validator (D-04, METHODOLOGY "Boundary Validation First") ----

      defp validate_data!(%{brand: %{font_name: f, logo_name: l}} = _data)
           when is_atom(f) and is_atom(l),
           do: :ok

      defp validate_data!(other) do
        raise ArgumentError,
              "Rendro.Recipes.BrandedInvoice requires data.brand.font_name and " <>
                "data.brand.logo_name as atoms; got: #{inspect(other)}"
      end
    end
    ```

    Concrete requirements (executor MUST satisfy each — these become acceptance grep gates):
    - File path EXACTLY `lib/rendro/recipes/branded_invoice.ex` (mirrors `lib/rendro/recipes/invoice.ex` location).
    - Module name `Rendro.Recipes.BrandedInvoice` (no other namespace).
    - Three public defs: `page_template/1`, `sections/2`, `document/2` (each with default keyword args giving arity-0 / arity-1 too — match Invoice's signature shape).
    - First call inside `sections/2` AND `document/2` is `validate_data!(data)`.
    - `document/2` body contains BOTH `register_embedded_font` AND `register_image` calls with `{:path, Rendro.Branded.font_path()}` and `{:path, Rendro.Branded.logo_path()}` respectively.
    - `validate_data!/1` clause-1 pattern-matches `%{brand: %{font_name: f, logo_name: l}} when is_atom(f) and is_atom(l)`.
    - `validate_data!/1` clause-2 raises `ArgumentError` with `inspect(other)` interpolation.
    - Three doctests (`iex>` blocks): in `page_template/1`, `sections/2`, `document/2` @doc.
    - The `document/2` doctest asserts `doc.page_template == :branded_invoice` AND `Map.has_key?(doc.font_registry.fonts, :brand_heading)` AND `Map.has_key?(doc.asset_registry.assets, :company_logo)` (Pitfall 6 mitigation — non-vacuous registry checks).
    - DO NOT touch `lib/rendro/recipes/invoice.ex` (D-06 frozen).
    - DO NOT add a fourth public function or change arities.
    - DO NOT silently fall back to unbranded rendering when `brand` is missing (D-04).
    - DO NOT pre-read font/logo bytes via `File.read!/1`; pass `{:path, _}` (D-05 — registries normalize).
    - DO NOT use `Path.expand(__DIR__)` or `File.cwd!` anywhere — go through `Rendro.Branded` (D-31).

    Verify:
    ```bash
    mix compile --warnings-as-errors
    mix test --include doctest test/rendro/recipes/branded_invoice_test.exs 2>/dev/null || true   # may not exist yet (Plan 04)
    mix test lib/rendro/recipes/branded_invoice.ex   # runs doctests in the file directly
    ```

    The doctests in this file MUST pass on `mix test` — that's the unit gate for Task 1. The non-doctest regression test file is created in Plan 04.

    If a doctest fails because of a mismatch in struct field shapes (e.g., `Rendro.region/1` returns a different field layout than expected), the executor should READ `lib/rendro.ex` and `lib/rendro/region.ex` (or wherever the region struct is defined) to confirm the actual signature, then adjust the doctest assertions — the @spec contract on `page_template/1` returning `Rendro.PageTemplate.t()` is fixed; the assertion shape may need a small adjustment.
  </action>
  <acceptance_criteria>
    - `test -f lib/rendro/recipes/branded_invoice.ex` exits 0
    - `grep -Eq '^defmodule Rendro\.Recipes\.BrandedInvoice do$' lib/rendro/recipes/branded_invoice.ex` exits 0
    - `grep -cE '^\s*def (page_template|sections|document)\(' lib/rendro/recipes/branded_invoice.ex` outputs `3`
    - `grep -cE '@spec (page_template|sections|document)\(' lib/rendro/recipes/branded_invoice.ex` outputs `3`
    - `grep -cE '^\s*defp validate_data!' lib/rendro/recipes/branded_invoice.ex` outputs at least `2`  (two clauses)
    - `grep -Fq 'validate_data!(data)' lib/rendro/recipes/branded_invoice.ex` exits 0
    - `grep -Fq 'register_embedded_font' lib/rendro/recipes/branded_invoice.ex` exits 0
    - `grep -Fq 'register_image' lib/rendro/recipes/branded_invoice.ex` exits 0
    - `grep -Fq 'Rendro.Branded.font_path' lib/rendro/recipes/branded_invoice.ex` exits 0
    - `grep -Fq 'Rendro.Branded.logo_path' lib/rendro/recipes/branded_invoice.ex` exits 0
    - `grep -Fq '{:path, Rendro.Branded.font_path()}' lib/rendro/recipes/branded_invoice.ex` exits 0
    - `grep -Fq '{:path, Rendro.Branded.logo_path()}' lib/rendro/recipes/branded_invoice.ex` exits 0
    - `grep -Fq ':branded_invoice' lib/rendro/recipes/branded_invoice.ex` exits 0
    - `grep -Fq ':logo' lib/rendro/recipes/branded_invoice.ex` exits 0
    - `grep -Fq 'raise ArgumentError' lib/rendro/recipes/branded_invoice.ex` exits 0
    - `grep -Fq 'inspect(other)' lib/rendro/recipes/branded_invoice.ex` exits 0
    - `grep -cE '^\s+iex>' lib/rendro/recipes/branded_invoice.ex` outputs at least `9`  (3 doctests × ~3 iex lines each)
    - `grep -Fq 'data.brand.font_name' lib/rendro/recipes/branded_invoice.ex` exits 0
    - `grep -Fq 'data.brand.logo_name' lib/rendro/recipes/branded_invoice.ex` exits 0
    - Anti-pattern absence: `! grep -Fq 'Path.expand(__DIR__)' lib/rendro/recipes/branded_invoice.ex` (D-31)
    - Anti-pattern absence: `! grep -Fq 'File.cwd' lib/rendro/recipes/branded_invoice.ex` (D-31)
    - Anti-pattern absence: `! grep -Fq 'File.read!' lib/rendro/recipes/branded_invoice.ex` (D-05 — pass {:path,_} not pre-read bytes)
    - Frozen-file invariant: `git diff --quiet HEAD lib/rendro/recipes/invoice.ex` exits 0 (D-06)
    - `mix compile --warnings-as-errors` exits 0
    - `mix test lib/rendro/recipes/branded_invoice.ex` runs and passes (3 doctests, all green)
  </acceptance_criteria>
  <verify>
    <automated>mix compile --warnings-as-errors && grep -Eq '^defmodule Rendro\.Recipes\.BrandedInvoice do$' lib/rendro/recipes/branded_invoice.ex && [ "$(grep -cE '^\s*def (page_template|sections|document)\(' lib/rendro/recipes/branded_invoice.ex)" = "3" ] && grep -Fq 'register_embedded_font' lib/rendro/recipes/branded_invoice.ex && grep -Fq 'register_image' lib/rendro/recipes/branded_invoice.ex && grep -Fq 'Rendro.Branded.font_path' lib/rendro/recipes/branded_invoice.ex && grep -Fq 'raise ArgumentError' lib/rendro/recipes/branded_invoice.ex && [ "$(grep -cE '^\s+iex>' lib/rendro/recipes/branded_invoice.ex)" -ge 9 ] && ! grep -Fq 'Path.expand(__DIR__)' lib/rendro/recipes/branded_invoice.ex && git diff --quiet HEAD lib/rendro/recipes/invoice.ex && mix test lib/rendro/recipes/branded_invoice.ex</automated>
  </verify>
  <done>
    `Rendro.Recipes.BrandedInvoice` exists at the canonical path, mirrors the Tiered Composition trio of `Rendro.Recipes.Invoice` (verbatim shape, four-region template), validates `data.brand` at the boundary with `ArgumentError`, registers brand font and logo via the public `Rendro.Document.register_embedded_font/3` and `register_image/3` APIs using `{:path, _}` tuples wrapping `Rendro.Branded.font_path/0`/`logo_path/0`, ships three module doctests that pass under `mix test`, contains no host-discovery anti-patterns, and `lib/rendro/recipes/invoice.ex` is byte-unchanged (D-06).
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Add Rendro.Recipes.branded_invoice/1 delegate to lib/rendro/recipes.ex</name>
  <read_first>
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-CONTEXT.md (D-03)
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-PATTERNS.md (`lib/rendro/recipes.ex` analog section, lines 225-256)
    - lib/rendro/recipes.ex (existing — read entire file; the new delegate slots immediately below the existing `invoice/1`)
    - lib/rendro/recipes/branded_invoice.ex (just authored in Task 1)
  </read_first>
  <behavior>
    - `Rendro.Recipes.branded_invoice/1` is a new top-level public function at `lib/rendro/recipes.ex`.
    - It accepts `data :: map()` and returns `Rendro.Document.t()`.
    - Body is exactly `Rendro.Recipes.BrandedInvoice.document(data)` (no extra logic, no opts forwarding).
    - It carries a parallel @doc + @spec mirroring the existing `invoice/1` delegate.
    - The existing `invoice/1` delegate is NOT modified (D-06 frozen contract on Invoice).
  </behavior>
  <files>
    - lib/rendro/recipes.ex (MODIFIED — append delegate; ~12 net new lines)
  </files>
  <action>
    Read the existing `lib/rendro/recipes.ex` to confirm the surrounding shape. The existing `invoice/1` delegate has the structure (per PATTERNS.md analog lines 227-240):

    ```elixir
    @doc """
    Builds a standard invoice document using the canonical Tiered Composition recipe.

    Delegates to `Rendro.Recipes.Invoice.document/1` ...
    """
    @spec invoice(map()) :: Rendro.Document.t()
    def invoice(data) do
      Rendro.Recipes.Invoice.document(data)
    end
    ```

    Append a sibling `branded_invoice/1` immediately below `invoice/1`. Suggested phrasing (per PATTERNS.md analog lines 244-255):

    ```elixir
    @doc """
    Builds a branded invoice document with a custom font and logo.

    Delegates to `Rendro.Recipes.BrandedInvoice.document/1`. Requires `data.brand`
    with `:font_name` and `:logo_name` atoms; see `Rendro.Recipes.BrandedInvoice`
    for the full data shape.
    """
    @spec branded_invoice(map()) :: Rendro.Document.t()
    def branded_invoice(data) do
      Rendro.Recipes.BrandedInvoice.document(data)
    end
    ```

    Concrete requirements:
    - The new function is added INSIDE the existing `defmodule Rendro.Recipes do ... end` block (no new module).
    - The new function appears AFTER the existing `invoice/1` definition (immediate sibling — convention for Elixir module organization).
    - DO NOT alter `Rendro.Recipes.invoice/1` (D-06).
    - DO NOT add an `opts` parameter (mirror `invoice/1` arity-1 exactly per D-03).
    - DO NOT call anything other than `Rendro.Recipes.BrandedInvoice.document(data)`.
    - The delegate's @doc points readers at `Rendro.Recipes.BrandedInvoice` for the data-shape contract.

    Verify:
    ```bash
    mix compile --warnings-as-errors
    mix run -e 'IO.inspect(function_exported?(Rendro.Recipes, :branded_invoice, 1))' | grep -q true
    ```
  </action>
  <acceptance_criteria>
    - `grep -Eq '^\s*def branded_invoice\(data\) do$' lib/rendro/recipes.ex` exits 0
    - `grep -Fq 'Rendro.Recipes.BrandedInvoice.document(data)' lib/rendro/recipes.ex` exits 0
    - `grep -Eq '^\s*@spec branded_invoice\(map\(\)\) :: Rendro\.Document\.t\(\)$' lib/rendro/recipes.ex` exits 0
    - The existing `invoice/1` delegate is preserved: `grep -Fq 'Rendro.Recipes.Invoice.document(data)' lib/rendro/recipes.ex` exits 0
    - Existing `invoice/1` def signature unchanged: `grep -Eq '^\s*def invoice\(data\) do$' lib/rendro/recipes.ex` exits 0
    - Frozen-file invariant on Invoice: `git diff --quiet HEAD lib/rendro/recipes/invoice.ex` exits 0 (D-06)
    - `mix compile --warnings-as-errors` exits 0
    - `mix run -e 'IO.puts(function_exported?(Rendro.Recipes, :branded_invoice, 1))' | grep -Fq 'true'` exits 0
    - `mix run -e 'IO.puts(function_exported?(Rendro.Recipes, :invoice, 1))' | grep -Fq 'true'` exits 0  (existing delegate still present)
  </acceptance_criteria>
  <verify>
    <automated>mix compile --warnings-as-errors && grep -Eq '^\s*def branded_invoice\(data\) do$' lib/rendro/recipes.ex && grep -Fq 'Rendro.Recipes.BrandedInvoice.document(data)' lib/rendro/recipes.ex && grep -Fq 'Rendro.Recipes.Invoice.document(data)' lib/rendro/recipes.ex && git diff --quiet HEAD lib/rendro/recipes/invoice.ex && mix run -e 'IO.puts(function_exported?(Rendro.Recipes, :branded_invoice, 1))' | grep -Fq 'true'</automated>
  </verify>
  <done>
    `Rendro.Recipes.branded_invoice/1` is exported, delegates to `Rendro.Recipes.BrandedInvoice.document/1`, mirrors the existing `invoice/1` delegate's @doc + @spec shape, preserves the existing `invoice/1` definition, and `lib/rendro/recipes/invoice.ex` is byte-unchanged.
  </done>
</task>

</tasks>

<verification>
- `mix compile --warnings-as-errors` exits 0
- `mix test lib/rendro/recipes/branded_invoice.ex` exits 0 with 3 doctests passing
- `mix run -e 'IO.puts(function_exported?(Rendro.Recipes, :branded_invoice, 1))'` outputs `true`
- `mix run -e 'IO.puts(function_exported?(Rendro.Recipes.BrandedInvoice, :document, 1))'` outputs `true`
- `mix run -e 'IO.puts(function_exported?(Rendro.Recipes.BrandedInvoice, :page_template, 0))'` outputs `true`
- `mix run -e 'IO.puts(function_exported?(Rendro.Recipes.BrandedInvoice, :sections, 1))'` outputs `true`
- `git diff --quiet HEAD lib/rendro/recipes/invoice.ex` exits 0 (Invoice frozen per D-06)
- The recipe file uses `{:path, _}` source tuples — no `File.read!` calls present.
- `validate_data!/1` is invoked at the entry of both `sections/2` and `document/2`.
- Three doctest blocks (`iex>` lines) appear in `lib/rendro/recipes/branded_invoice.ex`, one per public function.
</verification>

<success_criteria>
- `Rendro.Recipes.BrandedInvoice` ships with the canonical Tiered Composition surface (`document/2`, `page_template/1`, `sections/2`) verbatim mirroring `Rendro.Recipes.Invoice` (D-02).
- `:branded_invoice` is the page-template name; the four regions are `:logo`, `:header`, `:body`, `:footer` (D-02).
- `validate_data!/1` raises `ArgumentError` on missing or non-atom `data.brand` — no silent fallback (D-04).
- `document/2` registers the brand font and logo via the public document API using `{:path, _}` tuples sourced from `Rendro.Branded` (D-05, D-10).
- Three doctests pass; `document/2`'s doctest asserts non-vacuous registry presence (`Map.has_key?` + atom logical names — Pitfall 6 mitigation).
- `Rendro.Recipes.branded_invoice/1` delegate exists alongside the existing `invoice/1` (D-03).
- `Rendro.Recipes.Invoice` and its delegate are byte-unchanged (D-06).
- No `Path.expand(__DIR__)`, `File.cwd!`, `File.read!` direct-byte-reading, or system-font discovery anywhere on the recipe path (D-31 carried forward).
</success_criteria>

<output>
After completion, create `.planning/phases/29-branded-recipes-docs-and-proof-closure/29-03-SUMMARY.md` documenting:
- Final LOC of `lib/rendro/recipes/branded_invoice.ex` and net diff size of `lib/rendro/recipes.ex`.
- Confirmation that 3 doctests pass under `mix test lib/rendro/recipes/branded_invoice.ex`.
- The exact `data.brand` field-name choice made (`:font_name` + `:logo_name`) for downstream consistency.
- Confirmation that `lib/rendro/recipes/invoice.ex` is unchanged (`git diff --quiet`).
- The exact public API exported (`document/2`, `page_template/1`, `sections/2`, plus the top-level `Rendro.Recipes.branded_invoice/1` delegate).
</output>
</content>
</invoke>