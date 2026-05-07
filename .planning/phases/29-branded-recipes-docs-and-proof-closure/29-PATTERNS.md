# Phase 29: Branded Recipes, Docs, and Proof Closure - Pattern Map

**Mapped:** 2026-05-01
**Files analyzed:** 16 (8 new code/doc/asset files, 1 optional script, 7 modified files)
**Analogs found:** 14 / 16 (binary assets `B612-Regular.ttf` and `rendro-logo.png` have no in-tree analog by design — they ARE the analogs for future branded assets)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/recipes/branded_invoice.ex` | recipe | data → builder → registry → document | `lib/rendro/recipes/invoice.ex` | exact (mirror per D-02) |
| `lib/rendro/branded.ex` | public-helper (path resolver) | `Application.app_dir/2` → absolute path | `lib/rendro/component.ex` (small public helper module) | role-match |
| `priv/branded/fonts/B612-Regular.ttf` | asset (binary, font) | committed bytes → `File.read!/1` at registry time | none in-tree (first shipped library binary) | no analog |
| `priv/branded/images/rendro-logo.png` | asset (binary, image) | committed bytes → `File.read!/1` at registry time | none in-tree (first shipped library binary) | no analog |
| `NOTICE` | docs (third-party attribution) | static plain-text shipped in tarball | `README.md` (top-level plain doc) | partial (top-level shipped doc) |
| `guides/branding.md` | guide (verified ExDoc extra) | narrative + four `# docs-contract:` fences evaluated by harness | `guides/integrations.md` | exact (cardinality + structure mirror per D-21) |
| `test/docs_contract/branding_contract_test.exs` | test (docs-contract fence-evaluation lane) | guide path → `verified_fences/1` → `evaluate!/2` | `test/docs_contract/integrations_contract_test.exs` | exact (line-for-line mirror) |
| `test/docs_contract/branding_claims_test.exs` | test (docs-contract claims lane) | filesystem assertions + structural `%Rendro.Error{}` shape | `test/docs_contract/integrations_claims_test.exs` | exact |
| `test/rendro/recipes/branded_invoice_test.exs` | test (recipe regression) | data → recipe → document/render → structural assertions | `test/rendro/recipes/invoice_test.exs` | exact (describe-block layout mirrors) |
| `test/rendro/branded_test.exs` | test (path-resolver unit) | `Branded.font_path/0` → `File.exists?/1` + byte-size assertion | `test/rendro/asset_registry_test.exs` (small public-API unit test) | partial (smallest analog) |
| `examples/phoenix_example/.../page_controller.ex` | phoenix-controller (HTML chooser) | `conn` → `send_resp/3` with hardcoded HTML | `examples/phoenix_example/.../pdf_controller.ex` (controller pattern) + RESEARCH.md skeleton (D-16) | role-match (no Phoenix HTML controller exists yet) |
| `scripts/render_logo.exs` (OPTIONAL) | script (provenance — pre-renders committed PNG bytes) | erlang `:zlib` → PNG bytes → `File.write!/1` | `scripts/release_preflight_proof.exs` (top-level Mix script convention) | partial (script harness only; no PNG-emit precedent) |
| `lib/rendro/recipes.ex` (MODIFIED) | recipe-delegate | shortcut `branded_invoice/1` calling `BrandedInvoice.document/1` | existing `invoice/1` delegate at lines 16–19 of same file | exact (in-place sibling) |
| `mix.exs` (MODIFIED) | config (Hex package metadata) | `:files` whitelist + `:extras` + `:licenses` audit | existing `package/0` and `docs/0` at lines 68–84 | exact (in-place edit) |
| `README.md` (MODIFIED) | docs (orientation surface) | ≤2-sentence "Branded Documents" pointer subsection | existing "Tiered Composition" / "Phoenix Integration" subsections (lines 58, 263) | exact (precedent boundary) |
| `examples/phoenix_example/.../pdf_controller.ex` (MODIFIED) | phoenix-controller (PDF endpoints) | `conn` → recipe → `RendroPhoenix.render_pdf/3` or `preview_pdf/2` | existing `download/2` and `preview/2` actions in same file (lines 15–25) | exact (sibling actions) |
| `examples/phoenix_example/.../router.ex` (MODIFIED) | phoenix-router | scope → pipeline → routes | existing `:api` scope at lines 4–13 of same file | exact (in-place edit; add `:browser` pipeline + new routes) |
| `examples/phoenix_example/.../pdf_controller_test.exs` (MODIFIED) | test (phoenix integration) | `conn` test → 200 + `%PDF-` magic bytes + structural `%Document{}` checks | existing `describe "GET /download"` + `describe "Invoice recipe structural assertions"` blocks (lines 18–65) | exact (sibling describe blocks) |
| `.planning/ROADMAP.md` (MODIFIED) | planning-artifact | append v1.3-readiness blockers subsection | existing `Phase 999.1: First Hex Release Readiness (BACKLOG)` entry at lines 97–104 | exact (in-place append) |

## Pattern Assignments

### `lib/rendro/recipes/branded_invoice.ex` (recipe, data → builder → registry → document)

**Analog:** `lib/rendro/recipes/invoice.ex` (mirror verbatim per D-02; differences live entirely inside `page_template/1` and `sections/2`).

**Imports / module shape pattern** (`lib/rendro/recipes/invoice.ex:1-32`):

```elixir
defmodule Rendro.Recipes.Invoice do
  @moduledoc """
  Canonical invoice recipe using the Tiered Composition pattern.

  Exposes three levels of composability:

    - `document/2`      — Batteries-included; returns a fully assembled
                          `%Rendro.Document{}` ready for `Rendro.render/1`.
    - `page_template/1` — Layout only; returns the `%Rendro.PageTemplate{}`.
    - `sections/2`      — Content only; returns a list of `%Rendro.Section{}`
                          structs mapped to named regions.

  ## Usage

  ### Zero-to-one (just works)

      data = %{id: "INV-001", date: ~D[2026-01-15], items: [...]}
      doc  = Rendro.Recipes.Invoice.document(data)
      {:ok, pdf} = Rendro.render(doc)
  """
```

`BrandedInvoice` reuses this `@moduledoc` shape and adds a "Differs from `Rendro.Recipes.Invoice` only in: …" paragraph plus a `data.brand` example.

**Tiered Composition surface pattern — `page_template/1`** (`lib/rendro/recipes/invoice.ex:33-54`):

```elixir
@doc """
Returns a `%Rendro.PageTemplate{}` with three named regions: `:header`, `:body`, `:footer`.

## Examples

    iex> Rendro.Recipes.Invoice.page_template()
    %Rendro.PageTemplate{name: :invoice, ...}
"""
@spec page_template(keyword()) :: Rendro.PageTemplate.t()
def page_template(opts \\ []) do
  defaults = [name: :invoice]
  Rendro.page_template(Keyword.merge(defaults, opts))
end
```

`BrandedInvoice.page_template/1` keeps the `@spec`, `@doc`, `defaults |> Keyword.merge` shape verbatim; defaults use `name: :branded_invoice`; the regions list adds a fourth `:logo` region (D-02). Doctest mirrors line-for-line.

**Tiered Composition surface pattern — `sections/2`** (`lib/rendro/recipes/invoice.ex:56-75`):

```elixir
@spec sections(map(), keyword()) :: [Rendro.Section.t()]
def sections(data, _opts \\ []) do
  [
    header_section(data),
    body_section(data),
    footer_section(data)
  ]
end
```

`BrandedInvoice.sections/2` adds `validate_data!(data)` as the first call (per D-04 boundary validation) and prepends `logo_section(data)` to the returned list.

**Tiered Composition surface pattern — `document/2`** (`lib/rendro/recipes/invoice.ex:77-105`):

```elixir
@spec document(map(), keyword()) :: Rendro.Document.t()
def document(data, opts \\ []) do
  template = page_template(opts)
  secs = sections(data, opts)

  base_doc =
    Rendro.Document.new()
    |> Rendro.Document.add_template(template)
    |> Rendro.Document.set_template(template.name)

  Enum.reduce(secs, base_doc, fn section, doc ->
    Rendro.Document.add_section(doc, section)
  end)
end
```

`BrandedInvoice.document/2` inserts two registration steps between `Rendro.Document.new/0` and `add_template/2`:

```elixir
Rendro.Document.new()
|> Rendro.Document.register_embedded_font(
     data.brand.font_name,
     {:path, Rendro.Branded.font_path()})
|> Rendro.Document.register_image(
     data.brand.logo_name,
     {:path, Rendro.Branded.logo_path()})
|> Rendro.Document.add_template(template)
|> Rendro.Document.set_template(template.name)
```

The `register_embedded_font/3` and `register_image/3` accept `{:path, Path.t()}` — verified at `lib/rendro/document.ex:156-200`.

**Private builder pattern** (`lib/rendro/recipes/invoice.ex:107-149`):

```elixir
defp header_section(%{id: id, date: date} = _data) do
  Rendro.section(
    name: :invoice_header,
    region: :header,
    content: [
      Rendro.block(Rendro.text("INVOICE ##{id}", size: 18)),
      Rendro.block(Rendro.text("Date: #{date}", size: 10))
    ]
  )
end

defp body_section(%{items: items} = _data) do
  table_rows =
    Enum.map(items, fn item ->
      [item.name, Integer.to_string(item.qty), "$#{item.price}"]
    end)

  table =
    Rendro.table(table_rows,
      header: ["Item", "Qty", "Price"],
      columns: [{:share, 1}, {:fixed, 50}, {:fixed, 80}]
    )

  Rendro.section(
    name: :invoice_body,
    region: :body,
    content: [Rendro.block(table)]
  )
end
```

`BrandedInvoice` adds `defp logo_section(data)` using `Rendro.Component.image(data.brand.logo_name, width: 64, height: 64)` (image AST helper at `lib/rendro/component.ex:17-34`) wrapped in `Rendro.section/1`. `header_section/1` is overridden to author header text with `font: data.brand.font_name`. `body_section/1` and `footer_section/1` mirror `Invoice` byte-for-byte modulo private-name prefix.

**Boundary validation pattern** (new, derived from `Rendro.table/2` at `lib/rendro.ex:158-167`):

```elixir
# Pattern from lib/rendro.ex:160 — raise ArgumentError with concrete inspect()
if Keyword.has_key?(attrs, :width) or Keyword.has_key?(attrs, :border) do
  raise ArgumentError, "Rendro.table/2 no longer supports :width or :border. Use ..."
end
```

`BrandedInvoice.validate_data!/1` follows the same `raise ArgumentError, "…; got: #{inspect(other)}"` shape per RESEARCH.md skeleton:

```elixir
defp validate_data!(%{brand: %{font_name: f, logo_name: l}} = _data)
     when is_atom(f) and is_atom(l), do: :ok
defp validate_data!(other),
  do: raise ArgumentError,
        "BrandedInvoice requires data.brand.font_name and data.brand.logo_name as atoms; got: #{inspect(other)}"
```

---

### `lib/rendro/branded.ex` (public-helper, `Application.app_dir/2`)

**Analog:** `lib/rendro/component.ex` (small public helper module — defines `image/2` and `render_component/2`).

**Module shape pattern** (`lib/rendro/component.ex:1-11`):

```elixir
defmodule Rendro.Component do
  @moduledoc """
  Component-based layout pattern for reusable PDF UI parts.
  """

  @doc """
  Renders a component by calling its `render/1` function.
  """
  def render_component(module, assigns \\ []) do
    module.render(assigns)
  end
```

`Rendro.Branded` mirrors this shape: short `@moduledoc`, two `@doc` + `@spec` + one-line function bodies. Per D-11 the `@moduledoc` must explicitly state "demo assets … NOT a built-in font or default logo." Per D-10 the bodies are pure `Application.app_dir(:rendro, "priv/branded/...")` calls (no `File.exists?/1`, no fallback, no caching).

```elixir
@doc "Absolute path to the demo brand font (B612 Regular, SIL OFL 1.1)."
@spec font_path() :: Path.t()
def font_path, do: Application.app_dir(:rendro, "priv/branded/fonts/B612-Regular.ttf")

@doc "Absolute path to the demo brand logo (64×64 RGBA PNG)."
@spec logo_path() :: Path.t()
def logo_path, do: Application.app_dir(:rendro, "priv/branded/images/rendro-logo.png")
```

---

### `lib/rendro/recipes.ex` (MODIFIED — add `branded_invoice/1` delegate)

**Analog:** existing `invoice/1` delegate in same file at `lib/rendro/recipes.ex:10-19`:

```elixir
@doc """
Builds a standard invoice document using the canonical Tiered Composition recipe.

Delegates to `Rendro.Recipes.Invoice.document/1` which uses explicit page template
regions and sections instead of legacy `header:` / `footer:` kwargs.
"""
@spec invoice(map()) :: Rendro.Document.t()
def invoice(data) do
  Rendro.Recipes.Invoice.document(data)
end
```

Add `branded_invoice/1` immediately below, mirroring the doc-comment phrasing and `@spec` exactly:

```elixir
@doc """
Builds a branded invoice document with a custom font and logo.

Delegates to `Rendro.Recipes.BrandedInvoice.document/1`. Requires `data.brand`
with `:font_name` and `:logo_name` atoms; see `Rendro.Recipes.BrandedInvoice`.
"""
@spec branded_invoice(map()) :: Rendro.Document.t()
def branded_invoice(data) do
  Rendro.Recipes.BrandedInvoice.document(data)
end
```

---

### `guides/branding.md` (guide, verified ExDoc extra)

**Analog:** `guides/integrations.md` — exact structural mirror (header → Overview → per-topic subsections → Verification fences → Failure diagnostics tables) with cardinality of FOUR verified `elixir` fences (D-21).

**Verified-fence ID format pattern** (`guides/integrations.md:142-150`):

````markdown
```elixir
# docs-contract: integrations-threadline-happy-path
Rendro.Adapters.Threadline.attach()

{:ok, _pdf} = Rendro.render(
  Rendro.flow([Rendro.block(Rendro.text("Test invoice", size: 12))])
)

Rendro.Adapters.Threadline.detach()
```
````

`guides/branding.md` ships exactly four such fences with IDs (per D-21): `branding-register-assets`, `branding-tiered-document`, `branding-tiered-template`, `branding-missing-asset-diagnostic`. Each opens with `# docs-contract: <id>`. The matcher at `test/support/docs_contract.ex:5` is `~r/^\s*#\s*docs-contract:\s*(?<id>[[:alnum:]_-]+)\s*$/m` — every fence MUST carry one and only one such line.

**Schematic-fence (compile-only, NOT evaluated) pattern** (`guides/integrations.md:97-105`):

````markdown
```elixir-schematic
defp deps do
  [
    {:rendro, "~> 0.1"},
    {:threadline, "~> 0.2"},
    # ...
  ]
end
```
````

Per D-22, `guides/branding.md` MAY include up to one `elixir-schematic` fence showing where to drop a `MyApp.Branding` setup module. The harness at `test/support/docs_contract.ex:11` filters to `lang == "elixir"` only — schematic fences are skipped.

**Failure-diagnostics table pattern** (`guides/integrations.md:286-294`):

```markdown
| Error tuple | When it occurs | What to check |
|---|---|---|
| `{:error, %Rendro.Error{reason: {:invalid_email_target, value}}}` | … | … |
| `{:error, {:unrecognized_message_shape, struct_module}}` | … | … |
```

`guides/branding.md` reuses this three-column "Error tuple / When / What to check" Markdown table for the Failure-diagnostics subsection.

**Fence 4 (missing-asset diagnostic) pattern** (per RESEARCH.md Pitfall 4 + D-26 structural-only assertion):

````markdown
```elixir
# docs-contract: branding-missing-asset-diagnostic
doc = Rendro.Document.new()
      |> Rendro.Document.add_template(Rendro.Recipes.BrandedInvoice.page_template())
      |> Rendro.Document.set_template(:branded_invoice)
      |> Rendro.Document.add_section(Rendro.section(name: :logo, region: :logo, content: [
           Rendro.block(%Rendro.Image{logical_name: :unregistered_logo})
         ]))

assert {:error, %Rendro.Error{stage: stage, reason: reason}} = Rendro.render(doc)
assert stage in [:build, :compose, :measure, :render]
assert reason != nil
# Structural-only — do NOT assert on .what / .why / .next message strings.
```
````

The `%Rendro.Error{}` struct shape is verified at `lib/rendro/error.ex:9-21` — fields are `:what`, `:where`, `:why`, `:next`, `:stage`, `:reason`, `:render_id`, `:details`. The fence asserts ONLY on `:stage` (set membership) and non-nil `:reason`, never on the human-readable `:what`/`:why`/`:next` strings.

---

### `test/docs_contract/branding_contract_test.exs` (test, docs-contract fence-evaluation lane)

**Analog:** `test/docs_contract/integrations_contract_test.exs` — the entire file is ~32 lines and mirrors verbatim.

**Full pattern** (`test/docs_contract/integrations_contract_test.exs:1-32`):

```elixir
defmodule Rendro.DocsContract.IntegrationsContractTest do
  use ExUnit.Case, async: false

  alias Rendro.Test.DocsContract
  alias Rendro.Test.Mocks

  setup do
    Mocks.reset_threadline()
    :ok
  end

  test "curated integration guide fences stay executable" do
    fences = DocsContract.verified_fences("guides/integrations.md")

    assert Enum.map(fences, & &1.id) == [
             "integrations-threadline-happy-path",
             "integrations-mailglass-swoosh",
             "integrations-mailglass-message",
             "integrations-accrue-verification"
           ]

    Enum.each(fences, fn %{id: id, code: code} ->
      refute String.contains?(code, "...")
      refute String.contains?(code, "%{...}")

      case id do
        _ ->
          DocsContract.evaluate!(code, "guides/integrations.md")
      end
    end)
  end
end
```

`branding_contract_test.exs` mirrors:
- `defmodule Rendro.DocsContract.BrandingContractTest do`
- `use ExUnit.Case, async: false`
- `alias Rendro.Test.DocsContract` (omit `Mocks` alias and the threadline `setup` — branded fences don't need adapter mocks)
- Asserts `Enum.map(fences, & &1.id)` is exactly the four IDs from D-21
- `Enum.each` evaluates each via `DocsContract.evaluate!/2`
- Same `refute String.contains?(code, "...")` guard

---

### `test/docs_contract/branding_claims_test.exs` (test, docs-contract claims lane)

**Analog:** `test/docs_contract/integrations_claims_test.exs` — claims tests assert on filesystem, README content, mix.exs config, and structural error shapes.

**Filesystem-claim assertion pattern** (`test/docs_contract/integrations_claims_test.exs:27-37`):

```elixir
test "optional adapters stay behind compile-time guards" do
  for {path, dependency} <- [
        {"lib/rendro/adapters/threadline.ex", "Threadline"},
        ...
      ] do
    source = File.read!(path)
    assert source =~ "if Code.ensure_loaded?(#{dependency}) do"
  end
end
```

`branding_claims_test.exs` reuses this `File.read!/1 + assert =~` pattern for:
- `assert File.exists?("NOTICE")` and `File.read!("NOTICE") =~ "SIL OPEN FONT LICENSE Version 1.1"` (D-13)
- `File.read!("README.md") =~ "Branded Documents"` (D-24)
- `File.read!("mix.exs") =~ "guides/branding.md"` (D-20)
- `byte_size(File.read!("priv/branded/fonts/B612-Regular.ttf")) == 153_192` (RESEARCH.md Pitfall 5; CONTEXT D-08 corrected)
- `byte_size(File.read!("priv/branded/images/rendro-logo.png")) < 2_000` (D-09)

**Structural-error-claim pattern** (`test/docs_contract/integrations_claims_test.exs:51-61`):

```elixir
test "threadline timeout closure stays truthful" do
  content = for i <- 1..200, do: Rendro.block(Rendro.text("timeout me #{i}", size: 12))
  doc = Rendro.flow(content)
  doc = put_in(doc.options[:policies], timeout: 0)

  assert {:error, %Rendro.Error{reason: :timeout}} = Rendro.render(doc)

  assert [{:render_failed, metadata}] = Mocks.threadline_calls()
  assert metadata.status == :error
  assert %{kind: :timeout, stage: :render} = metadata.error
end
```

`branding_claims_test.exs` mirrors the `assert {:error, %Rendro.Error{stage: ..., reason: ...}}` pattern for an unregistered-asset render — structural fields only, no message strings (D-26).

**Byte-identical regression pattern** (`test/rendro/deterministic_test.exs:13-19`):

```elixir
property "two deterministic renders of the same document produce identical binaries" do
  check all(doc <- renderable_document_gen(), max_runs: 100) do
    {:ok, pdf1} = Rendro.render(doc, deterministic: true)
    {:ok, pdf2} = Rendro.render(doc, deterministic: true)
    assert pdf1 == pdf2
  end
end
```

`branding_claims_test.exs` adopts the simpler unit form (non-property) per D-25:

```elixir
test "two consecutive BrandedInvoice renders produce byte-identical PDFs" do
  doc = Rendro.Recipes.BrandedInvoice.document(sample_data())
  {:ok, pdf1} = Rendro.render(doc, deterministic: true)
  {:ok, pdf2} = Rendro.render(doc, deterministic: true)
  assert pdf1 == pdf2
end
```

---

### `test/rendro/recipes/branded_invoice_test.exs` (test, recipe regression)

**Analog:** `test/rendro/recipes/invoice_test.exs` — three describe blocks (`page_template/1`, `sections/2`, `document/2`) mirroring the three public functions.

**Sample-data fixture pattern** (`test/rendro/recipes/invoice_test.exs:6-15`):

```elixir
defp sample_data do
  %{
    id: "INV-042",
    date: ~D[2026-04-30],
    items: [
      %{name: "Widget A", qty: 3, price: 200},
      %{name: "Widget B", qty: 1, price: 500}
    ]
  }
end
```

`branded_invoice_test.exs` reuses identical shape and adds `brand: %{font_name: :brand_heading, logo_name: :company_logo}` per D-04.

**`describe "page_template/1"` pattern** (`test/rendro/recipes/invoice_test.exs:17-37`):

```elixir
describe "page_template/1" do
  test "returns a %Rendro.PageTemplate{} with name :invoice" do
    template = Invoice.page_template()
    assert %Rendro.PageTemplate{} = template
    assert template.name == :invoice
  end

  test "template has named regions :header, :body, :footer" do
    template = Invoice.page_template()
    region_names = Enum.map(template.regions, & &1.name)
    assert :header in region_names
    assert :body in region_names
    assert :footer in region_names
  end
end
```

`BrandedInvoice` mirror asserts `template.name == :branded_invoice` and the FOUR regions `:logo`, `:header`, `:body`, `:footer` (D-23).

**`describe "document/2"` pattern** (`test/rendro/recipes/invoice_test.exs:79-116`):

```elixir
describe "document/2" do
  test "returns a %Rendro.Document{} struct" do
    doc = Invoice.document(sample_data())
    assert %Rendro.Document{} = doc
  end

  test "document has page_template set to :invoice" do
    doc = Invoice.document(sample_data())
    assert doc.page_template == :invoice
  end

  test "document has sections covering all three regions" do
    doc = Invoice.document(sample_data())
    region_targets = Enum.map(doc.sections, & &1.region)
    assert :header in region_targets
    ...
  end
end
```

`BrandedInvoice` mirror adds (per RESEARCH.md Pitfall 6):

```elixir
test "document has the brand font registered as :embedded" do
  doc = BrandedInvoice.document(sample_data())
  assert Map.has_key?(doc.font_registry.fonts, sample_data().brand.font_name)
  assert match?(%{source: :embedded}, doc.font_registry.fonts[sample_data().brand.font_name])
end

test "document has the brand logo registered" do
  doc = BrandedInvoice.document(sample_data())
  assert map_size(doc.asset_registry.assets) >= 1
  assert Map.has_key?(doc.asset_registry.assets, sample_data().brand.logo_name)
end
```

**PDF-substring regression pattern** (`test/rendro/pdf/writer_test.exs:236-294`):

```elixir
assert pdf =~ "/F_BRAND"
assert pdf =~ "/Subtype /TrueType"
assert pdf =~ "/FontDescriptor"
assert pdf =~ "/FontFile2"
assert pdf =~ "/Encoding /WinAnsiEncoding"
assert pdf =~ "(Brand heading) Tj"
...
assert pdf =~ "/Type /XObject"
assert pdf =~ "/Subtype /Image"
assert pdf =~ "/IM_LOGO_PNG"
assert pdf =~ "/Filter /FlateDecode"
assert pdf =~ "/Width 100"
assert pdf =~ "/Height 50"
```

`branded_invoice_test.exs` regression block (per D-27) renders `BrandedInvoice.document(sample_data())` and asserts:
- `binary_part(pdf, 0, 5) == "%PDF-"` (magic bytes)
- `pdf =~ "/F_BRAND_HEADING"` (font dict for the brand logical name)
- `pdf =~ "/FontFile2"` (embedded font stream)
- `pdf =~ "/Type /XObject"` and `pdf =~ "/Subtype /Image"` (logo XObject)
- `pdf =~ "/IM_COMPANY_LOGO"` (image dictionary entry; uppercase atom-derived ID)

**Boundary-validation-failure pattern** (new, per D-04):

```elixir
test "raises ArgumentError when data.brand is missing" do
  assert_raise ArgumentError, ~r/data\.brand/, fn ->
    BrandedInvoice.document(%{id: "INV-042", date: ~D[2026-04-30], items: []})
  end
end
```

(Pattern: `assert_raise` with regex matcher — established Elixir convention; no in-tree analog needed.)

---

### `test/rendro/branded_test.exs` (test, path-resolver unit)

**Analog:** `test/rendro/asset_registry_test.exs` (small public-API unit test). The test is minimal — three assertions tied to D-10/D-11.

```elixir
defmodule Rendro.BrandedTest do
  use ExUnit.Case, async: true

  test "font_path/0 resolves to an existing file" do
    path = Rendro.Branded.font_path()
    assert is_binary(path)
    assert File.exists?(path)
  end

  test "logo_path/0 resolves to an existing file" do
    path = Rendro.Branded.logo_path()
    assert is_binary(path)
    assert File.exists?(path)
  end
end
```

(Note: file-byte-size assertions belong in `branding_claims_test.exs`, not here — this file is the unit boundary for the resolver module only.)

---

### `examples/phoenix_example/.../page_controller.ex` (phoenix-controller, HTML chooser)

**Analog:** Existing `pdf_controller.ex` (controller convention) + RESEARCH.md skeleton at lines 539–566. No in-tree HTML controller exists.

**Controller-module pattern** (`examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex:1-3`):

```elixir
defmodule PhoenixExampleWeb.PDFController do
  use PhoenixExampleWeb, :controller
  alias Rendro.Adapters.Phoenix, as: RendroPhoenix
```

`PageController` mirrors:

```elixir
defmodule PhoenixExampleWeb.PageController do
  use PhoenixExampleWeb, :controller
```

**Module-attribute-as-fixture pattern** (`pdf_controller.ex:5-13`):

```elixir
@demo_invoice %{
  id: "INV-2026-001",
  date: ~D[2026-04-30],
  items: [
    %{name: "Consulting Services", qty: 10, price: 2_500},
    %{name: "Support Plan", qty: 1, price: 500}
  ]
}
```

`PageController` uses `@chooser_html ~S"""…"""` heredoc per RESEARCH.md skeleton (D-16) — hardcoded HTML, no template engine, no `priv/static`.

**Action-body pattern** (`pdf_controller.ex:15-19`):

```elixir
def download(conn, _params) do
  doc = Rendro.Recipes.Invoice.document(@demo_invoice)

  RendroPhoenix.render_pdf(conn, doc, "example.pdf")
end
```

`index/2` body uses `Plug.Conn` directly:

```elixir
def index(conn, _params) do
  conn
  |> Plug.Conn.put_resp_content_type("text/html")
  |> Plug.Conn.send_resp(200, @chooser_html)
end
```

(Note: `use PhoenixExampleWeb, :controller` already imports `Plug.Conn`; `Plug.Conn.` prefix can be elided. The skeleton uses the explicit prefix for readability — either is methodology-compliant.)

---

### `examples/phoenix_example/.../pdf_controller.ex` (MODIFIED — add `branded_download/2`, `branded_preview/2`)

**Analog:** existing `download/2` and `preview/2` actions in same file (`pdf_controller.ex:15-25`):

```elixir
def download(conn, _params) do
  doc = Rendro.Recipes.Invoice.document(@demo_invoice)

  RendroPhoenix.render_pdf(conn, doc, "example.pdf")
end

def preview(conn, _params) do
  doc = Rendro.Recipes.Invoice.document(@demo_invoice)

  RendroPhoenix.preview_pdf(conn, doc)
end
```

Add two sibling actions (per D-17) reusing the SAME `@demo_invoice` plus the `:brand` field; per D-18 the example app does NOT vendor or copy font/logo bytes. Pattern:

```elixir
@demo_branded_invoice Map.put(@demo_invoice, :brand, %{
  font_name: :brand_heading,
  logo_name: :company_logo
})

def branded_download(conn, _params) do
  doc = Rendro.Recipes.BrandedInvoice.document(@demo_branded_invoice)

  RendroPhoenix.render_pdf(conn, doc, "branded_example.pdf")
end

def branded_preview(conn, _params) do
  doc = Rendro.Recipes.BrandedInvoice.document(@demo_branded_invoice)

  RendroPhoenix.preview_pdf(conn, doc)
end
```

---

### `examples/phoenix_example/.../router.ex` (MODIFIED — add `:browser` pipeline + new routes)

**Analog:** existing `:api` pipeline + `scope "/", PhoenixExampleWeb` block (`router.ex:1-14`):

```elixir
defmodule PhoenixExampleWeb.Router do
  use PhoenixExampleWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixExampleWeb do
    pipe_through :api

    get "/download", PDFController, :download
    get "/preview", PDFController, :preview
  end
end
```

Per D-15 + D-16 + RESEARCH.md A4: add a `:browser` pipeline accepting `["html"]` for the index route, and add the two `/branded/*` routes alongside existing PDF routes:

```elixir
pipeline :browser do
  plug :accepts, ["html"]
end

scope "/", PhoenixExampleWeb do
  pipe_through :browser

  get "/", PageController, :index
end

scope "/", PhoenixExampleWeb do
  pipe_through :api

  get "/download", PDFController, :download
  get "/preview", PDFController, :preview
  get "/branded/download", PDFController, :branded_download
  get "/branded/preview", PDFController, :branded_preview
end
```

---

### `examples/phoenix_example/.../pdf_controller_test.exs` (MODIFIED — add two describe blocks)

**Analog:** existing `describe "GET /download"` (`pdf_controller_test.exs:18-34`) and `describe "Invoice recipe structural assertions"` (`pdf_controller_test.exs:36-65`).

**HTTP-status + magic-bytes pattern** (`pdf_controller_test.exs:18-34`):

```elixir
describe "GET /download" do
  test "returns 200 with application/pdf content-type", %{conn: conn} do
    conn = get(conn, "/download")
    assert conn.status == 200
    assert get_resp_header(conn, "content-type") |> hd() =~ "application/pdf"
  end

  test "response body begins with PDF magic bytes", %{conn: conn} do
    conn = get(conn, "/download")
    body = conn.resp_body
    assert is_binary(body)
    assert byte_size(body) > 0
    assert binary_part(body, 0, 5) == "%PDF-"
  end
end
```

`describe "GET /branded/download"` mirrors this exactly with route swapped.

**Structural-document-assertion pattern** (`pdf_controller_test.exs:36-65`):

```elixir
describe "Invoice recipe structural assertions" do
  test "document has named page_template regions and non-empty sections" do
    doc = Rendro.Recipes.Invoice.document(@invoice_data)

    assert %Rendro.Document{} = doc
    assert doc.page_template == :invoice

    assert [template] = doc.page_templates
    assert template.name == :invoice
    assert length(template.regions) >= 3

    region_names = Enum.map(template.regions, & &1.name)
    assert :header in region_names
    assert :body in region_names
    assert :footer in region_names

    assert doc.sections != []
    assert length(doc.sections) == 3
  end
end
```

`describe "BrandedInvoice recipe structural assertions"` mirrors this and adds (per D-19 + RESEARCH.md Pitfall 6):

```elixir
assert doc.page_template == :branded_invoice
assert length(template.regions) >= 4         # adds :logo
assert :logo in region_names
# Brand registrations (NOT vacuous count check — Pitfall 6)
assert Map.has_key?(doc.font_registry.fonts, @branded_data.brand.font_name)
assert match?(%{source: :embedded},
              doc.font_registry.fonts[@branded_data.brand.font_name])
assert Map.has_key?(doc.asset_registry.assets, @branded_data.brand.logo_name)
```

The existing `describe "Source-level check: controller uses canonical recipe"` block (lines 67–107) stays UNCHANGED per D-19.

---

### `mix.exs` (MODIFIED — `:files`, `:extras`, `:licenses` audit)

**Analog:** existing `package/0` and `docs/0` in same file (`mix.exs:68-84`):

```elixir
defp package do
  [
    licenses: ["UNLICENSED"],
    links: %{"GitHub" => @source_url}
  ]
end

defp docs do
  [
    main: "Rendro",
    source_url: @source_url,
    extras: [
      "README.md",
      "guides/integrations.md"
    ]
  ]
end
```

Per D-12: extend `package/0` with explicit `:files` whitelist (per RESEARCH.md "mix.exs `:files` enumeration" code skeleton, lines 572–589). Per D-20: append `"guides/branding.md"` to `:extras`. Per RESEARCH.md A1 + Pitfall 2: leave `licenses: ["UNLICENSED"]` for now and capture SPDX-license decision in v1.3 readiness blockers (D-28). The license audit decision is the only `:licenses` change; the actual swap to `Apache-2.0`/`MIT` is a v1.3 task, not a Phase 29 task.

```elixir
defp package do
  [
    licenses: ["UNLICENSED"],   # v1.3 release-readiness blocker — see ROADMAP.md
    links: %{"GitHub" => @source_url},
    files: ~w(
      lib
      priv/branded
      .formatter.exs
      mix.exs
      README.md
      LICENSE
      NOTICE
      CHANGELOG.md
    )
  ]
end

defp docs do
  [
    main: "Rendro",
    source_url: @source_url,
    extras: [
      "README.md",
      "guides/integrations.md",
      "guides/branding.md"
    ]
  ]
end
```

---

### `README.md` (MODIFIED — ≤2-sentence "Branded Documents" pointer subsection)

**Analog:** existing `## Tiered Composition: Canonical Recipes` and `## Phoenix Integration` subsection seam at `README.md:58-99` and `README.md:263`.

Per D-24: insert a single ≤2-sentence subsection between Tiered Composition (ends at line 99) and Phoenix Integration (starts at line 263). NO new verified fences (D-24 explicit). Pattern (orientation-grade, narrative redirected to the guide):

```markdown
### Branded Documents

For documents that combine the canonical recipe with a registered brand font and
logo asset, see `Rendro.Recipes.BrandedInvoice` and the
[Branding guide](guides/branding.md).
```

---

### `NOTICE` (top-level plain-text attribution)

**Analog:** none in tree — first NOTICE file. Closest top-level shipped doc is `README.md`.

**Content pattern** (per D-13 + RESEARCH.md "NOTICE file" section, lines 622–646):

The file MUST contain the verbatim 93-line OFL.txt as shipped in `polarsys/b612/OFL.txt` (and identically mirrored at `google/fonts/ofl/b612/OFL.txt`), 4,470 bytes. First seven lines:

```
Copyright 2012 The B612 Project Authors (https://github.com/polarsys/b612)

This Font Software is licensed under the SIL Open Font License, Version 1.1.
This license is copied below, and is also available with a FAQ at:
http://scripts.sil.org/OFL


-----------------------------------------------------------
SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
-----------------------------------------------------------
```

The file is plain text, no extension, top-level (sibling of `README.md`, `mix.exs`). The `branding_claims_test.exs` asserts presence + "SIL OPEN FONT LICENSE Version 1.1" + "Copyright 2012 The B612 Project Authors" + "http://scripts.sil.org/OFL" substrings.

---

### `priv/branded/fonts/B612-Regular.ttf` and `priv/branded/images/rendro-logo.png` (asset, binary)

**Analog:** none in-tree (no `priv/` subtree currently exists; verified by `ls /Users/jon/projects/rendro/priv` returning empty).

**Sourcing pattern** (per D-08 + RESEARCH.md Pitfall 5):

- `B612-Regular.ttf` — download from `https://github.com/polarsys/b612/raw/master/fonts/ttf/B612-Regular.ttf` (or identical mirror `https://github.com/google/fonts/raw/main/ofl/b612/B612-Regular.ttf`); committed bytes are exactly 153,192 bytes (NOT the ~52 KB CONTEXT D-08 estimate; correction surfaced by RESEARCH.md).
- `rendro-logo.png` — hand-authored 64×64 RGBA PNG, < 2,000 bytes compressed; bytes committed once (D-09); optional `scripts/render_logo.exs` ships for regeneration provenance only.

Resolution at runtime is via `Rendro.Branded.font_path/0` and `.logo_path/0` (which use `Application.app_dir(:rendro, "priv/...")`) — never raw `File.read!/1` against a relative path (RESEARCH.md "Anti-Patterns to Avoid").

---

### `scripts/render_logo.exs` (OPTIONAL, per D-09)

**Analog:** `scripts/release_preflight_proof.exs:1-3`:

```elixir
defmodule Rendro.ReleasePreflightProof do
  @moduledoc false
```

The `defmodule … do … end` + `@moduledoc false` pattern is the existing `scripts/` convention. Phase 29's optional script follows the RESEARCH.md skeleton (lines 651–676): pure Erlang `:zlib` PNG encoder, no external deps. The script's runtime contract is "regenerate the committed `rendro-logo.png` for audit" — NOT "load at app start" or "test setup."

```elixir
# scripts/render_logo.exs (OPTIONAL)
# Run with: mix run scripts/render_logo.exs

png_signature = <<137, 80, 78, 71, 13, 10, 26, 10>>
ihdr = chunk("IHDR", <<64::32, 64::32, 8, 6, 0, 0, 0>>)
raw = build_pixels(64, 64)
idat = chunk("IDAT", :zlib.compress(raw))
iend = chunk("IEND", <<>>)
File.write!("priv/branded/images/rendro-logo.png",
  png_signature <> ihdr <> idat <> iend)
```

---

### `.planning/ROADMAP.md` (MODIFIED — append v1.3-readiness blockers)

**Analog:** existing `Phase 999.1: First Hex Release Readiness (BACKLOG)` entry at `.planning/ROADMAP.md:97-104`:

```markdown
### Phase 999.1: First Hex Release Readiness (BACKLOG)
**Goal**: Decide whether Rendro is ready for a truthful first public Hex.pm release and close the remaining packaging, proof, and support-boundary work required to publish.
**Source**: `SEED-001`
**Deferred at**: 2026-04-30 during `v1.1` milestone-close preflight
**Notes**:
- Existing release preflight coverage already exercises `mix hex.build --unpack` and `mix hex.publish --dry-run --yes`.
- This is now the intended `v1.3` milestone theme if `v1.2` closes truthfully.
```

Per D-28: append a `**v1.3 readiness blockers**:` subsection listing concrete items (RESEARCH.md Pitfall 2 + the `:licenses` audit decision deferred from `mix.exs`):

```markdown
**v1.3 readiness blockers** (captured during Phase 29 closure):
- `mix.exs` `:licenses` is `["UNLICENSED"]`; pick SPDX-valid value (Apache-2.0 vs MIT decision) and ship matching top-level `LICENSE` file.
- Hex package metadata audit: `:description`, `:source_url`, `:links`, `:maintainers`.
- README badge state (build, hex.pm version, hexdocs).
- ExDoc `:groups_for_extras` decision once guide count exceeds three.
- `usage_rules.md` artifact decision (deferred from Phase 29).
- Public-API stability scan and deprecation policy doc.
- NOTICE file shipping verified (closed by Phase 29 D-13).
- `mix hex.publish --dry-run` preflight already covered by `scripts/release_preflight_proof.exs`.
```

---

## Shared Patterns

### Tiered Composition surface (locked since Phase 22)
**Source:** `lib/rendro/recipes/invoice.ex:33-105`
**Apply to:** `lib/rendro/recipes/branded_invoice.ex`

The three-function trio `page_template/1`, `sections/2`, `document/2` with identical `@spec` shapes and identical doctest mechanics. NEVER add a fourth public function or change the arities; D-02 mandates verbatim mirror.

### Application.app_dir/2 path resolution
**Source:** `lib/rendro/document.ex:156-167` (`register_embedded_font/3` accepts `{:path, _}`)
**Apply to:** `lib/rendro/branded.ex` (resolver) and `lib/rendro/recipes/branded_invoice.ex` (consumer)

Always resolve shipped library binaries via `Application.app_dir(:rendro, "priv/...")` — never raw `Path.expand(__DIR__)` chains. Works identically in `mix test`, `iex -S mix`, doctests, and Hex consumer apps. Same convention as `tzdata`, `gettext`, `cldr_*`.

### Boundary validation with `raise ArgumentError`
**Source:** `lib/rendro.ex:158-163` (`Rendro.table/2` rejects forbidden opts)
**Apply to:** `lib/rendro/recipes/branded_invoice.ex` `validate_data!/1`

```elixir
raise ArgumentError, "<concrete message>; got: #{inspect(other)}"
```

Never silently fall back; never return `{:error, _}` from the recipe surface for input-shape errors. Hard fail at the boundary (METHODOLOGY "Boundary Validation First").

### `{:path, _} | {:binary, _}` source tuple
**Source:** `lib/rendro/document.ex:159, 175, 192`
**Apply to:** `lib/rendro/recipes/branded_invoice.ex` (`register_embedded_font/3` and `register_image/3` calls)

Both registries accept `{:path, Path.t()}` directly — no need to pre-read bytes via `File.read!/1`. The recipe passes `{:path, Rendro.Branded.font_path()}` and lets the registry normalize internally.

### Verified-fence ID format
**Source:** `test/support/docs_contract.ex:5` (regex) + `guides/integrations.md` (4 instances)
**Apply to:** `guides/branding.md` (4 fences)

Each `elixir` fence MUST carry one `# docs-contract: <id>` line. Regex matcher: `~r/^\s*#\s*docs-contract:\s*(?<id>[[:alnum:]_-]+)\s*$/m`. Missing ID raises during fence discovery.

### Fence evaluation (caller-process, ExUnit assertions auto-imported)
**Source:** `test/support/docs_contract.ex:20-22`
**Apply to:** `test/docs_contract/branding_contract_test.exs`

```elixir
def evaluate!(code, file) do
  Code.eval_string("import ExUnit.Assertions\n#{code}", [], file: file)
end
```

`assert` works inside fences without explicit import. `elixir-schematic` fences are skipped (filter at `docs_contract.ex:11`).

### Structural `%Rendro.Error{}` assertion (D-26)
**Source:** `test/docs_contract/integrations_claims_test.exs:51-61` and `lib/rendro/error.ex:9-21`
**Apply to:** `guides/branding.md` fence 4 + `test/docs_contract/branding_claims_test.exs`

```elixir
assert {:error, %Rendro.Error{stage: stage, reason: reason}} = Rendro.render(doc)
assert stage in [:build, :compose, :measure, :render]
assert reason != nil
```

Assert structurally on `:stage` (set membership) and `:reason` (non-nil). NEVER assert on `:what`/`:why`/`:next` message strings — those drift as ASSET-03/FONT-04 wording evolves.

### PDF-substring assertion (D-27)
**Source:** `test/rendro/pdf/writer_test.exs:236-294`
**Apply to:** `test/rendro/recipes/branded_invoice_test.exs` regression block

```elixir
assert binary_part(pdf, 0, 5) == "%PDF-"
assert pdf =~ "/F_BRAND_HEADING"
assert pdf =~ "/FontFile2"
assert pdf =~ "/Type /XObject"
assert pdf =~ "/Subtype /Image"
assert pdf =~ "/IM_COMPANY_LOGO"
```

Substring assertions on the rendered binary, not whole-file byte identity (D-30 caps byte-identity to a narrow internal regression).

### Module-attribute as test fixture
**Source:** `examples/phoenix_example/.../pdf_controller.ex:6-13` and `pdf_controller_test.exs:9-16`
**Apply to:** new `@demo_branded_invoice` in controller, new `@branded_data` in test

Per D-17, the SAME `@demo_invoice` plus `:brand` field feeds both branded actions. Mirrored as test fixture in `pdf_controller_test.exs`.

### `%PDF-` magic-bytes assertion
**Source:** `examples/phoenix_example/.../pdf_controller_test.exs:27-33`
**Apply to:** new `describe "GET /branded/download"` block

```elixir
body = conn.resp_body
assert is_binary(body)
assert byte_size(body) > 0
assert binary_part(body, 0, 5) == "%PDF-"
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `priv/branded/fonts/B612-Regular.ttf` | asset (binary, font) | committed bytes | First library-shipped font; this file IS the analog for any future shipped font. Sourcing from `polarsys/b612` master branch (RESEARCH.md verified 153,192 bytes). |
| `priv/branded/images/rendro-logo.png` | asset (binary, image) | committed bytes | First library-shipped image; this file IS the analog for any future shipped image. Hand-authored bytes (RESEARCH.md skeleton, `:zlib`-encoded). |

(`NOTICE`, `lib/rendro/branded.ex`, `examples/.../page_controller.ex`, and `scripts/render_logo.exs` have partial/role-match analogs documented above — they are not in this "no analog" table.)

## Metadata

**Analog search scope:**
- `lib/rendro/recipes/` (recipe analogs)
- `lib/rendro/` top-level (public-helper analogs)
- `guides/` (verified ExDoc extra precedent)
- `test/docs_contract/` (docs-contract harness lanes)
- `test/rendro/recipes/` (recipe regression tests)
- `test/rendro/pdf/` (PDF substring assertion patterns)
- `test/rendro/` top-level (asset/font registry tests, deterministic tests)
- `test/support/` (DocsContract harness helpers)
- `examples/phoenix_example/lib/phoenix_example_web/controllers/` (Phoenix controller convention)
- `examples/phoenix_example/lib/phoenix_example_web/router.ex` (router convention)
- `examples/phoenix_example/test/phoenix_example_web/controllers/` (Phoenix conn-case test convention)
- `mix.exs`, `README.md`, `.planning/ROADMAP.md` (config + docs surfaces)
- `scripts/` (Mix-script convention)

**Files scanned:** 18

**Pattern extraction date:** 2026-05-01

---

## PATTERN MAPPING COMPLETE

**Phase:** 29 - Branded Recipes, Docs, and Proof Closure
**Files classified:** 19 (12 new files including the optional script + 7 modified files)
**Analogs found:** 17 / 19 (the two binary-asset files have no in-tree analog by design — they are themselves the first-of-kind shipped library binaries)

### Coverage
- Files with exact analog: 13 (`branded_invoice.ex`, both docs-contract test files, `branded_invoice_test.exs`, `guides/branding.md`, `recipes.ex` delegate edit, `mix.exs` edit, `README.md` edit, both `pdf_controller.ex` actions, both `pdf_controller_test.exs` describe blocks, `router.ex` edit, `ROADMAP.md` append)
- Files with role-match analog: 4 (`lib/rendro/branded.ex` mirrors `lib/rendro/component.ex` shape; `examples/.../page_controller.ex` mirrors `pdf_controller.ex` controller convention; `test/rendro/branded_test.exs` mirrors small public-API test conventions; `scripts/render_logo.exs` mirrors `scripts/release_preflight_proof.exs` script convention)
- Files with no analog: 2 (`B612-Regular.ttf`, `rendro-logo.png` — first-of-kind shipped binaries; `NOTICE` has partial precedent in top-level `README.md` location only)

### Key Patterns Identified
- **Tiered Composition surface is locked** — `BrandedInvoice` mirrors `Invoice`'s `document/2` + `page_template/1` + `sections/2` shape verbatim; differences live entirely in private builders and the `:logo` region.
- **`Application.app_dir(:rendro, "priv/...")` is the canonical asset-resolution pattern** — same convention as tzdata/gettext/cldr; works in mix test, iex, doctests, and Hex consumers.
- **Docs-contract harness is single-source** — `verified_fences/1` discovers via `# docs-contract: <id>` comment line; `evaluate!/2` runs in caller process with `import ExUnit.Assertions` prepended; `elixir-schematic` fences skip evaluation.
- **`%Rendro.Error{}` structural assertions only** (D-26) — `:stage` set membership + non-nil `:reason`; never message-string `=~` checks.
- **Boundary validation hard-fails at recipe surface** — `raise ArgumentError, "...; got: #{inspect(other)}"` per METHODOLOGY "Boundary Validation First".
- **Phoenix example mirrors itself** — `branded_download/2` and `branded_preview/2` are sibling actions to existing `download/2` and `preview/2` reusing the same `@demo_invoice` (per D-17), keeping the diff minimal.
- **Two material context corrections surfaced by RESEARCH.md** — (1) B612-Regular.ttf is 153,192 bytes (not ~52 KB per D-08); regression assertion must match actual size. (2) `licenses: ["UNLICENSED"]` blocks `mix hex.publish` and is captured as a v1.3 readiness blocker (D-28), NOT a Phase 29 fix.

### File Created
`/Users/jon/projects/rendro/.planning/phases/29-branded-recipes-docs-and-proof-closure/29-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can now reference analog patterns in PLAN.md files via the `file_path:line_number` citations above.
