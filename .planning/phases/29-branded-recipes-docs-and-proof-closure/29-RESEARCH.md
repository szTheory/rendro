# Phase 29: Branded Recipes, Docs, and Proof Closure - Research

**Researched:** 2026-05-01
**Domain:** Elixir Hex library packaging, font/asset shipping, ExDoc verified guides, Phoenix demo wiring, branded canonical recipe authoring
**Confidence:** HIGH (almost everything is grounded in checked-in code, the live B612 source repo, and existing harness precedents). One material correction to a CONTEXT.md decision is flagged below.

## Summary

CONTEXT.md locks 31 decisions covering recipe shape, asset sourcing, Phoenix demo, docs-contract surface, v1.3 capture, and determinism posture. The job here is not to re-derive those locks but to fill in the technical "how" the planner needs to translate them into tasks. Most answers come from checked-in code: `Rendro.Recipes.Invoice` is the structural template for `BrandedInvoice`, `Rendro.AssetRegistry` already accepts `{:path, _}` and resolves via `File.read!/1`, `Rendro.FontRegistry.register_embedded/3` accepts both `{:path, _}` and `{:binary, _}`, the docs-contract harness uses an `# docs-contract: <id>` line plus `Code.eval_string/3` (not isolated processes), and the `mix.exs` `:files` whitelist already overrides the default — once locked, `priv/branded/**` MUST be enumerated explicitly.

**One material correction to surface:** D-08 estimates B612-Regular.ttf at ~52 KB; the canonical file at `polarsys/b612` (and the Google Fonts mirror at `google/fonts/ofl/b612/B612-Regular.ttf`) is **153,192 bytes (~150 KB)**. D-14's package-delta arithmetic is therefore wrong by ~100 KB; the real delta is ~+159 KB, not ~+55 KB. This is still well under the 8 MB Hex tarball limit and well under tzdata's ~1 MB precedent, so the locked decision to ship the font remains defensible — but the planner MUST update the size sanity-check assertion to match reality (153,192 bytes ± a small tolerance, NOT "<60 KB"). [VERIFIED: HTTP HEAD + GitHub API content-listing on `google/fonts` repo].

**Primary recommendation:** Plan the phase as ten coarse-grained workstreams: (1) commit assets + NOTICE + license metadata, (2) ship `Rendro.Branded` resolver, (3) ship `BrandedInvoice` recipe with doctests + delegate, (4) regression test file, (5) `guides/branding.md` with four verified fences + one schematic fence, (6) two docs-contract test files, (7) Phoenix example controllers + routes + tests, (8) README pointer + `mix.exs` `:extras` + `:files` audit, (9) ROADMAP Phase 999.1 v1.3-readiness subsection, (10) verification artifact wiring. Each workstream is two tasks at most.

## User Constraints (from CONTEXT.md)

### Locked Decisions

**Branded recipe shape**
- **D-01:** New sibling module `Rendro.Recipes.BrandedInvoice` at `lib/rendro/recipes/branded_invoice.ex`. Do NOT extend `Rendro.Recipes.Invoice`.
- **D-02:** Mirror Tiered Composition verbatim: `BrandedInvoice.document/2`, `BrandedInvoice.page_template/1`, `BrandedInvoice.sections/2`. Differences live entirely inside `page_template/1` (adds a `:logo` region) and `sections/2` (uses `Rendro.image/2` for the logo and authored brand font in the header).
- **D-03:** Add delegating shortcut `Rendro.Recipes.branded_invoice/1` calling `BrandedInvoice.document/1`.
- **D-04:** Drive branding inputs through `data` argument — e.g., `%{brand: %{font_name: :brand_heading, logo_name: :company_logo}, ...}`. Validate at recipe boundary with typed errors. The recipe MUST NOT silently render an unbranded fallback when `brand` is missing or malformed; that is a hard validation failure.
- **D-05:** Reuse `Rendro.AssetRegistry` and `Rendro.FontRegistry` directly. Do NOT invent a parallel "brand config" struct.
- **D-06:** `Rendro.Recipes.Invoice` is frozen for Phase 29 — no edits to its public contract, doctests, or shipped behavior.

**Branded asset sourcing**
- **D-07:** Commit small open-licensed font + tiny logo PNG into `priv/branded/`. No host-path discovery, no inline base64 fixtures, no test-time generation.
- **D-08:** Font: B612 Regular (SIL OFL 1.1), single weight only. Path: `priv/branded/fonts/B612-Regular.ttf`. Bold OUT OF SCOPE.
- **D-09:** Logo: 64×64 RGBA PNG, hand-authored geometric mark, < 2 KB compressed. Path: `priv/branded/images/rendro-logo.png`. Optional `scripts/render_logo.exs` for regeneration provenance.
- **D-10:** Expose committed paths through `Rendro.Branded.font_path/0` and `Rendro.Branded.logo_path/0` resolving via `Application.app_dir(:rendro, "priv/...")`.
- **D-11:** Document `Rendro.Branded` as "demo assets for the branded recipe and getting-started examples — NOT a built-in font or default logo." The font is NOT auto-registered.
- **D-12:** Update `mix.exs` `package: [files: [...]]` to enumerate shipped paths INCLUDING `priv/branded/**` and a new top-level `NOTICE` file. Once `:files` is set, Hex no longer auto-includes `priv/`.
- **D-13:** Add top-level `NOTICE` file with verbatim B612 SIL OFL 1.1 attribution. Reference NOTICE from the README's third-party-licenses section. Assert NOTICE presence and OFL header substring in a docs-contract claims test.
- **D-14:** Estimated package delta: ~+55 KB. **CORRECTION (this research):** real delta ~+159 KB. Still well under the 8 MB Hex limit.

**Phoenix example demonstration**
- **D-15:** Add NEW endpoints at `GET /branded/download` and `GET /branded/preview` alongside existing `GET /download` and `GET /preview`. Existing endpoints stay unchanged.
- **D-16:** Add new `PageController` with `index/2` action mapped to `GET /`. Renders hardcoded HTML chooser. No `priv/static`, no LiveView, no template directory.
- **D-17:** Add `branded_download/2` and `branded_preview/2` actions on existing `PDFController`. Each calls `Rendro.Recipes.BrandedInvoice.document(@demo_invoice)` then reuses `RendroPhoenix.render_pdf/3` and `preview_pdf/2`. Same `@demo_invoice` feeds both recipes.
- **D-18:** Example app does NOT vendor or copy font/logo bytes. `BrandedInvoice.document/2` resolves library `priv/branded/` via `Application.app_dir(:rendro, ...)` internally.
- **D-19:** Extend `pdf_controller_test.exs` with two new `describe` blocks mirroring existing structure: `GET /branded/download` returns `%PDF-` magic bytes; structural assertion that `BrandedInvoice.document/1` registered at least one font and one image on the returned `%Document{}`. Keep the source-level legacy-`Rendro.flow` check unchanged.

**Docs-contract & verification surface**
- **D-20:** Create new ExDoc extra `guides/branding.md`. Mirror `guides/integrations.md` structure: Overview, Registering brand fonts, Registering logo assets, BrandedInvoice tiered composition, Failure diagnostics. Add to `mix.exs` `extras:`.
- **D-21:** `guides/branding.md` ships exactly FOUR verified `elixir` fences:
  - `branding-register-assets`
  - `branding-tiered-document`
  - `branding-tiered-template`
  - `branding-missing-asset-diagnostic`
- **D-22:** Up to one `elixir-schematic` (compile-only, not evaluated) fence for app-scaffolding pattern.
- **D-23:** Three module doctests on `BrandedInvoice` mirroring `Rendro.Recipes.Invoice` style: `page_template/1`, `sections/2`, `document/2` (given minimal data + a registered font + registered image).
- **D-24:** README change BOUNDED to ≤2-sentence pointer subsection ("Branded Documents") between "Tiered Composition" and Phoenix integration. NO new verified fences in README.
- **D-25:** Two new test files: `test/docs_contract/branding_contract_test.exs` and `test/docs_contract/branding_claims_test.exs`. Plus byte-identical regression for two consecutive renders (narrow internal regression, NOT public byte-stability promise).
- **D-26:** Match `integrations_claims_test.exs` precedent: assert structurally on `%Rendro.Error{reason: ...}` (or registry-specific exception) field shape rather than message strings.
- **D-27:** Deterministic regression for branded layout parity: page count, line breaks for header text, image XObject inclusion, font dictionary structure. Satisfies QUAL-07's "committed regression tests" arm without elevating whole-PDF byte identity to a public contract.

**v1.3 release-blocker capture**
- **D-28:** Capture in TWO places: (1) append "v1.3 readiness blockers" subsection to `Phase 999.1` in ROADMAP.md; (2) mirror as "Pending v1.3 work" section in eventual `29-VERIFICATION.md`.
- **D-29:** Do NOT create separate top-level `RELEASE-CHECKLIST.md` or new docs artifact.

**Determinism & verification posture**
- **D-30:** Determinism contract identical to Phase 26 D-13/D-14/D-15: measurement/pagination/writer consume the same resolved font descriptor; structural assertions on font dict + image XObject are public proof; whole-file byte identity stays narrow internal regression tool only.
- **D-31:** No system-font discovery, no remote asset fetching, no ambient OS state — re-asserted for the branded path.

### Claude's Discretion

- Internal module split between `Rendro.Branded` (path resolver) and any private branded-recipe helpers.
- Exact field names inside `data.brand` map (`:font_name` vs `:brand_font` vs `:font`).
- Exact bytes of the hand-authored 64×64 PNG logo.
- Whether `scripts/render_logo.exs` ships or is omitted.
- Internal organization of `guides/branding.md` subsections beyond the five named.
- Whether the chooser index page embeds a one-line "what is Rendro" header.
- Telemetry/diagnostic field naming consistent with existing surfaces.

### Deferred Ideas (OUT OF SCOPE)

- A second branded canonical recipe for a different doc type (Statement, Certificate, Report) — v1.3+.
- Bold or italic variants of the brand font.
- Auto-registering a default brand font/logo on `Rendro.Document.new/0` — explicitly rejected (D-11).
- Generation pipeline for the demo logo PNG at runtime/test-setup — rejected (D-09).
- Validator-backed PDF/A or signature claims around branded artifacts — v1.5+.
- Whole-file byte-identity public guarantee for branded PDFs — explicitly NOT a public contract (D-30).
- ExDoc auto-extras index — handled by ExDoc's existing `extras:` mechanism.
- Live LiveView playground for the Phoenix demo.
- A hex `usage_rules.md` artifact — captured as v1.3 release-readiness blocker (D-28), not implemented.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LAY-13 | Engineer can generate at least one branded canonical document example that combines templates/regions with registered fonts and logo assets. | `BrandedInvoice` recipe scaffold from `Rendro.Recipes.Invoice` (Tiered Composition); `Rendro.image/2` AST + `Rendro.AssetRegistry` (Phase 28); `Rendro.register_embedded_font/3` (Phase 26); `Rendro.Branded` path resolver via `Application.app_dir/2`; B612 + 64×64 PNG bytes shipped in `priv/branded/`. |
| QUAL-07 | Maintainer can verify typography and asset determinism through committed regression tests, docs-contract coverage, and example proof. | `test/rendro/recipes/branded_invoice_test.exs` (regression: page count, line breaks, image XObject, font dict, byte-identical two-run); `test/docs_contract/branding_contract_test.exs` + `branding_claims_test.exs` (4 verified fences + structural %Rendro.Error{} assertions + NOTICE/OFL header check); `pdf_controller_test.exs` (Phoenix example proof: 200, %PDF-, structural asserts on `%Document{}` registries). |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Branded recipe authoring (Tiered Composition) | Pure Core (lib/rendro/recipes) | — | `Rendro.Recipes.Invoice` lives in pure core; `BrandedInvoice` mirrors. |
| Demo asset path resolution | Pure Core (lib/rendro/branded.ex) | — | `Application.app_dir/2` is OTP, no Phoenix coupling; resolves the same in tests/iex/Hex consumers. |
| Font/asset registration | Pure Core (Document → FontRegistry/AssetRegistry) | — | Phase 25/28 already established document-owned registries. |
| Verified docs fence evaluation | Test support (Rendro.Test.DocsContract) | — | Existing harness uses `Code.eval_string/3` in caller process. |
| Phoenix demo branded endpoints | Optional Adapter (Rendro.Adapters.Phoenix) | Example app (examples/phoenix_example) | Adapter `render_pdf/3` and `preview_pdf/2` already exist; example app composes them. |
| Phoenix chooser HTML index | Example app (PageController) | — | Hardcoded HTML via `send_resp/3`; no template engine, no `priv/static`. |
| NOTICE attribution + OFL shipping | Hex package metadata | — | Top-level `NOTICE` file referenced from `mix.exs` `:files`. |
| README ≤2-sentence pointer | Repo orientation surface | — | README hygiene precedent (Phoenix/Ecto/Oban): orientation, not narrative. |
| ExDoc extras grouping | Hex docs build | — | `mix.exs` `:docs[:extras]`; optional `:groups_for_extras` regex map (Oban precedent). |

## Standard Stack

### Core (already in tree, MUST reuse)

| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| `Rendro.Recipes.Invoice` | in-tree | Structural template for `BrandedInvoice` | Locked Tiered Composition contract since Phase 22; D-02 mandates verbatim mirror. |
| `Rendro.FontRegistry` | in-tree | Public font registration; accepts `{:path, _}` and `{:binary, _}` | Phase 25/26; `register_embedded/3` already normalizes path bytes via `File.read/1`. |
| `Rendro.AssetRegistry` | in-tree | Public image registration with intrinsic-bounds extraction | Phase 28; `register_image/3` accepts `{:path, _}` directly via `File.read!/1`. |
| `Rendro.Document` | in-tree | Pipeline builder API used by recipes | Locked since Phase 22. |
| `Rendro.image/2` | in-tree | Public image AST | Phase 28; renders into `Rendro.Block` referencing logical name. |
| `Rendro.Adapters.Phoenix` | in-tree (optional) | `render_pdf/3` + `preview_pdf/2` | Already wired; D-17 reuses. |
| `Rendro.Test.DocsContract` | in-tree (test/support) | `verified_fences/1` + `evaluate!/2` for fence-id discovery and evaluation | Phase 28 precedent. |

### Supporting (already in deps)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:phoenix` (optional) | `~> 1.7` | Phoenix example app router/controller | Example app + Phoenix adapter only. |
| `:plug` (optional) | `~> 1.14` | Plug.Conn, send_resp/3 | Phoenix adapter + chooser controller. |
| `:ex_doc` (only dev/test) | `~> 0.40` | Hex docs build, extras grouping | `mix docs` build, ships hex.pm site. |

### No New Dependencies Required

Phase 29 is intentionally a "use what we have" phase. No new hex deps. The font and PNG are committed bytes. The docs-contract harness already exists. Phoenix and Plug are already optional deps. ExDoc is already configured.

**Installation:** None. All required modules exist; new code adds files only.

**Version verification:** Confirmed B612-Regular.ttf canonical filename and bytes via GitHub raw download from `polarsys/b612` (153,192 bytes, OFL 1.1 in name table; identical bytes mirrored at `google/fonts/ofl/b612/B612-Regular.ttf`). [VERIFIED: 2026-05-01 HTTP HEAD + curl download].

## Architecture Patterns

### System Architecture Diagram

```
                                Phase 29 Branded Document Path
                                ──────────────────────────────

  User data (map) ──────────────► Rendro.Recipes.BrandedInvoice.document(data)
                                            │
                                            │  (validates data.brand at boundary; D-04)
                                            ▼
                       Rendro.Branded.font_path/0    Rendro.Branded.logo_path/0
                                │                              │
                                │  Application.app_dir(:rendro, "priv/branded/...")
                                ▼                              ▼
                  ┌──────────────────────────┐    ┌─────────────────────────┐
                  │ priv/branded/fonts/      │    │ priv/branded/images/    │
                  │   B612-Regular.ttf       │    │   rendro-logo.png       │
                  │   (SIL OFL 1.1, 153 KB)  │    │   (64×64 RGBA, <2 KB)   │
                  └──────────────────────────┘    └─────────────────────────┘
                                │                              │
                                ▼                              ▼
                Rendro.Document.register_embedded_font     Rendro.Document.register_image
                                │                              │
                                └──────────────┬───────────────┘
                                               ▼
                              Rendro.Document.new
                                |> add_template (BrandedInvoice.page_template — adds :logo region)
                                |> set_template
                                |> reduce add_section (BrandedInvoice.sections — uses Rendro.image/2 + brand font)
                                               │
                                               ▼
                                       Rendro.render(doc)
                                               │
                                               ▼
                              build → compose → measure → paginate → render → validate
                              (each stage consumes resolved font descriptor and asset bytes
                               that were normalized at registration; Phase 26 D-13/D-14)
                                               │
                                               ▼
                                    {:ok, pdf_binary}  ─────► writer emits:
                                                                /Type /Font /Subtype /TrueType
                                                                /FontFile2 (embedded B612)
                                                                /Type /XObject /Subtype /Image
                                                                /F_BRAND_HEADING ... Tj operators
                                                                /IM_COMPANY_LOGO Do operator


                  Verification surface  (3 lanes)

  ┌──────────────────────────────────────────────────────────────────────────────┐
  │  Lane 1: BrandedInvoice unit + regression                                    │
  │    test/rendro/recipes/branded_invoice_test.exs                              │
  │    - page_template/1, sections/2, document/2 unit tests                      │
  │    - render through full pipeline → page count, header line breaks,          │
  │      image XObject in PDF, font dict structure (D-27)                        │
  │    - byte-identical two-run regression (D-25; internal-only, D-30)           │
  │                                                                              │
  │  Lane 2: docs-contract                                                       │
  │    test/docs_contract/branding_contract_test.exs                             │
  │    - asserts the four fence IDs from D-21 in guides/branding.md              │
  │    - evaluates each via DocsContract.evaluate!/2                             │
  │    test/docs_contract/branding_claims_test.exs                               │
  │    - README pointer text present                                             │
  │    - mix.exs :extras includes guides/branding.md                             │
  │    - NOTICE present + OFL header substring                                   │
  │    - structural %Rendro.Error{} or registry-exception assertion (D-26)       │
  │                                                                              │
  │  Lane 3: Phoenix example proof                                               │
  │    examples/phoenix_example/.../pdf_controller_test.exs                      │
  │    - GET /branded/download → 200, %PDF- magic bytes                          │
  │    - structural: BrandedInvoice.document/1 registered ≥1 font + ≥1 image     │
  │    - existing source-level legacy-Rendro.flow check unchanged                │
  └──────────────────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

New files (Phase 29 surface):
```
lib/rendro/
├── branded.ex                               # NEW — Rendro.Branded.font_path/0, .logo_path/0
└── recipes/
    └── branded_invoice.ex                   # NEW — sibling of invoice.ex, mirrors Tiered Composition

priv/branded/                                # NEW directory
├── fonts/
│   └── B612-Regular.ttf                     # NEW (~150 KB, SIL OFL 1.1)
└── images/
    └── rendro-logo.png                      # NEW (64×64 RGBA, <2 KB)

scripts/
└── render_logo.exs                          # OPTIONAL (D-09 says MAY ship)

guides/
└── branding.md                              # NEW — verified ExDoc extra

test/rendro/recipes/
└── branded_invoice_test.exs                 # NEW — regression coverage (D-25/D-27)

test/docs_contract/
├── branding_contract_test.exs               # NEW — verifies four fences
└── branding_claims_test.exs                 # NEW — README pointer, NOTICE/OFL, structural %Rendro.Error{}

examples/phoenix_example/lib/phoenix_example_web/controllers/
└── page_controller.ex                       # NEW — GET / chooser HTML

NOTICE                                       # NEW top-level file (B612 OFL 1.1 verbatim)
```

Modified files:
```
lib/rendro/recipes.ex                        # Add Rendro.Recipes.branded_invoice/1 delegate
mix.exs                                      # :files enumeration, :extras adds guides/branding.md, :licenses audit
README.md                                    # ≤2-sentence "Branded Documents" pointer subsection
examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex  # Add branded_download/2, branded_preview/2
examples/phoenix_example/lib/phoenix_example_web/router.ex                       # Add /branded/* + / routes
examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs  # Add two describe blocks
.planning/ROADMAP.md                         # Append v1.3 readiness blockers subsection to Phase 999.1
```

### Pattern 1: Tiered Composition Mirror

**What:** `BrandedInvoice` exposes the same three public functions as `Invoice` — `document/2`, `page_template/1`, `sections/2`. Differences are entirely interior.

**When to use:** Always — locked by D-02.

**Example (skeletal — mirror invoice.ex line by line, override only marked sections):**

```elixir
# Source: lib/rendro/recipes/invoice.ex (mirror this structure verbatim per D-02)
defmodule Rendro.Recipes.BrandedInvoice do
  @moduledoc """
  Branded canonical invoice recipe using the Tiered Composition pattern.

  Differs from `Rendro.Recipes.Invoice` only in:
    * `page_template/1` adds a `:logo` region beside `:header`.
    * `sections/2` includes the brand logo via `Rendro.image/2` and authors
      header text using a brand-named logical font.
    * `document/2` registers the brand font and logo on the returned document
      before assembling templates and sections.

  ## Usage

  ### Zero-to-one
      data = %{id: "INV-001", date: ~D[2026-01-15], items: [...],
               brand: %{font_name: :brand_heading, logo_name: :company_logo}}
      doc  = Rendro.Recipes.BrandedInvoice.document(data)
      {:ok, pdf} = Rendro.render(doc)
  """

  @doc """
  Returns a `%Rendro.PageTemplate{}` with FOUR named regions: `:logo`, `:header`, `:body`, `:footer`.

  ## Examples

      iex> Rendro.Recipes.BrandedInvoice.page_template()
      %Rendro.PageTemplate{name: :branded_invoice, ...}
  """
  @spec page_template(keyword()) :: Rendro.PageTemplate.t()
  def page_template(opts \\ []) do
    defaults = [name: :branded_invoice]
    # mirror invoice's region list, plus a :logo region
    Rendro.page_template(Keyword.merge(defaults, opts))
  end

  @doc """
  Returns a list of `%Rendro.Section{}` structs mapping content to
  `:logo`, `:header`, `:body`, and `:footer` regions.
  """
  @spec sections(map(), keyword()) :: [Rendro.Section.t()]
  def sections(data, _opts \\ []) do
    validate_data!(data)  # boundary validation per D-04, METHODOLOGY "Boundary Validation First"
    [
      logo_section(data),
      header_section(data),
      body_section(data),
      footer_section(data)
    ]
  end

  @doc """
  Assembles and returns a fully composed `%Rendro.Document{}` with the brand
  font and logo asset already registered.
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

    Enum.reduce(secs, base_doc, &Rendro.Document.add_section(&2, &1))
  end

  # Private builders + boundary validator
  defp validate_data!(%{brand: %{font_name: f, logo_name: l}} = _data)
       when is_atom(f) and is_atom(l), do: :ok
  defp validate_data!(other),
    do: raise ArgumentError, "BrandedInvoice requires data.brand.font_name and data.brand.logo_name as atoms; got: #{inspect(other)}"

  # ... logo_section, header_section, body_section, footer_section follow Invoice precedent
end
```

### Pattern 2: `Rendro.Branded` Path Resolver

**What:** Tiny module that wraps `Application.app_dir(:rendro, "priv/...")` calls.

**When to use:** Always — locked by D-10.

**Example:**

```elixir
defmodule Rendro.Branded do
  @moduledoc """
  Demo assets for the canonical branded recipe and getting-started examples.

  These are NOT a built-in font or default logo. The `BrandedInvoice` recipe
  registers them through the existing public `Rendro.Document.register_embedded_font/3`
  and `Rendro.Document.register_image/3` APIs. Adopters who copy the recipe
  to author their own brand should swap these helpers for their own asset bytes.
  """

  @doc "Absolute path to the demo brand font (B612 Regular, SIL OFL 1.1)."
  @spec font_path() :: Path.t()
  def font_path, do: Application.app_dir(:rendro, "priv/branded/fonts/B612-Regular.ttf")

  @doc "Absolute path to the demo brand logo (64×64 RGBA PNG)."
  @spec logo_path() :: Path.t()
  def logo_path, do: Application.app_dir(:rendro, "priv/branded/images/rendro-logo.png")
end
```

`Application.app_dir/2` is the canonical Elixir convention for resolving `priv/` resources from a hex-installed library — `tzdata`, `gettext`, `cldr` all use this exact pattern. It works identically in `mix test`, `iex -S mix`, doctests, and downstream consumers depending on `:rendro` from Hex. [CITED: hexdocs.pm/elixir Application.app_dir/2 docs; tzdata/gettext/cldr precedent].

### Anti-Patterns to Avoid

- **Reading `priv/branded/...` via raw `File.read!/1` against a hardcoded relative path.** Breaks the moment the package is consumed from Hex. Always go through `Application.app_dir/2`.
- **Auto-registering the brand font/logo on `Rendro.Document.new/0`.** Explicitly rejected by D-11 — would imply a free default brand identity Rendro doesn't deliver.
- **Inlining font/logo bytes as base64 in fixtures or in the example app.** Breaks D-07 (single source of truth) and D-18 (no asset duplication into example).
- **Adding a fifth `elixir`-fenced verified block to `guides/branding.md`.** D-21 caps cardinality at four (matches integrations precedent).
- **Adding any verified fence to README.md.** D-24 explicitly forbids; README stays orientation-grade.
- **Asserting on `%Rendro.Error{}` message strings.** D-26 says structural reason-field shape only.
- **Editing `lib/rendro/recipes/invoice.ex`.** Frozen by D-06.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Locating shipped `priv/` assets | Hardcoded `Path.expand(__DIR__)` chains | `Application.app_dir(:rendro, "priv/...")` | Only OTP-canonical path; works from Hex consumer apps. |
| Font byte normalization | Raw `File.read!/1` then pass binary downstream | `Rendro.Document.register_embedded_font/3` with `{:path, _}` | `FontRegistry.register_embedded/3` already normalizes to owned bytes (Phase 26 D-02/D-03). |
| Image byte parsing | Custom PNG/JPEG header parsing | `Rendro.AssetRegistry.register_image/3` | Already extracts width/height/mime via `Rendro.ImageParser.parse/1`. |
| Logo PNG generation at runtime | Pillow / ImageMagick / stb_image_write subprocess | Commit pre-rendered 64×64 RGBA PNG bytes | D-09 — runtime generation introduces nondeterminism + dep. |
| Verified fence ID discovery | Custom regex walker | `Rendro.Test.DocsContract.verified_fences/1` | Locked harness; line is `# docs-contract: <id>` inside the fence body. |
| Verified fence evaluation | Spawning isolated processes | `Rendro.Test.DocsContract.evaluate!/2` | Uses `Code.eval_string/3` in caller process with `import ExUnit.Assertions` already prepended. |
| Phoenix HTML chooser page | Eex template + view module + layout | `send_resp(conn, 200, hardcoded_html_string)` | D-16 — flat file count, no template directory. |
| OFL license verbatim text authoring | Re-deriving / paraphrasing | Copy `OFL.txt` verbatim from `polarsys/b612` (or `google/fonts/ofl/b612/OFL.txt` — identical bytes) | NOTICE files MUST contain the canonical text per OFL 1.1 condition #2. |
| PDF page-count / font-dict / XObject assertions in tests | Custom PDF parser | Substring assertions on the rendered binary | Existing pattern in `test/rendro/pdf/writer_test.exs` and `test/rendro/deterministic_test.exs`: `assert pdf =~ "/Type /XObject"`, `assert pdf =~ "/Count 1"`, `assert pdf =~ "/F_BRAND"`, etc. |

**Key insight:** Every "how do we test/assert X" question for Phase 29 has an existing precedent in the test suite. Phase 29 should add ZERO new test helpers; it should compose what's already there.

## Runtime State Inventory

> Phase 29 is greenfield (new files + small additive edits to existing files). No rename, refactor, or migration. **Section omitted; not applicable.**

## Common Pitfalls

### Pitfall 1: `:files` whitelist silently drops `priv/branded/**`

**What goes wrong:** D-12 changes `mix.exs` `package: [files: [...]]` to an explicit list. Once `:files` is set, Hex no longer auto-includes `priv/`. If `priv/branded/fonts/B612-Regular.ttf` is not enumerated, the published Hex tarball will lack the font bytes — and `Application.app_dir(:rendro, "priv/branded/fonts/B612-Regular.ttf")` returns a path to a non-existent file in downstream consumers. Tests pass locally but the recipe blows up the moment someone installs Rendro from Hex.

**Why it happens:** Default `:files` is the lib/priv/etc whitelist. Going from "default" to "explicit list" loses the implicit `priv` entry unless re-added.

**How to avoid:**
- Use a `mix hex.build` + tarball-extract preflight assertion (D-25 claims-test verifies presence of `priv/branded/**` in the built tarball, not just the source tree).
- Verify with `mix hex.build && tar -tzf rendro-X.Y.Z.tar | grep priv/branded`.

**Warning signs:** `Application.app_dir(:rendro, "priv/branded/...")` returns a path that does not exist when running the example or downstream tests against the installed dep.

### Pitfall 2: `licenses: ["UNLICENSED"]` blocks `mix hex.publish`

**What goes wrong:** Current `mix.exs` declares `licenses: ["UNLICENSED"]`. Hex's package validation requires SPDX-valid identifiers. `UNLICENSED` is not SPDX-valid; `mix hex.publish` (or even `mix hex.build` with `--check-licenses`) will reject it. The B612 font's OFL-1.1 is a third-party-included asset license (lives in NOTICE), NOT the package license. The package's own license must be a real SPDX value (e.g., `Apache-2.0`, `MIT`, `BSD-3-Clause`).

**Why it happens:** Pre-public packages often use `UNLICENSED` as a placeholder. Phase 29 ships toward release readiness, so this becomes a real blocker.

**How to avoid:**
- D-12 says "audit `licenses:`" — the planner should explicitly decide the v1.x license (likely `Apache-2.0` to match Elixir core, or `MIT`) and update `mix.exs`. Do NOT add `OFL-1.1` to `:licenses` — that confuses Hex consumers about what license they get when they depend on `:rendro`.
- Whatever license is chosen, add a top-level `LICENSE` file matching it (Apache-2.0 has its own NOTICE-handling rules, see ASF policy — but those rules apply to combinations of Apache-2.0 code; OFL inclusion is a separate attribution channel via the new top-level `NOTICE`).

**Warning signs:** `mix hex.build` warning, `mix hex.publish --dry-run` rejection, hex.pm UI rendering of licenses field as "Unknown."

This is technically out of scope for D-13 (which only mandates the NOTICE) but in scope for D-28's v1.3 release-blockers list. Flag it explicitly there.

### Pitfall 3: Doctest can't register a path-based font without an existing file

**What goes wrong:** D-23 requires three doctests on `BrandedInvoice`: `page_template/1`, `sections/2`, `document/2`. The third needs "minimal data + a registered font + registered image." If the doctest tries to register the brand font via `{:path, "/some/path/B612-Regular.ttf"}` literal-string path, the path is wrong. If it tries `Rendro.Branded.font_path/0`, that resolves correctly under `mix test` because `:rendro`'s priv is on disk relative to the project — BUT the registration happens inside `BrandedInvoice.document/2` itself, so the doctest just needs to call `BrandedInvoice.document(data)` and assert on the returned struct. The brand font/logo are registered by `document/2`'s body.

**Why it happens:** Confusing "doctest sets up the font" with "the function under test sets up the font."

**How to avoid:**
- Doctest 1 (`page_template/1`): asserts shape of returned `%Rendro.PageTemplate{}`. No font/image needed.
- Doctest 2 (`sections/2`): asserts shape of returned sections list. Needs a `data.brand` map present so `validate_data!/1` passes; no actual font/asset registration.
- Doctest 3 (`document/2`): calls `document(data)` and asserts on `doc.page_template`, `doc.font_registry.fonts`, `doc.asset_registry.assets`. The recipe itself does the registration internally via `Rendro.Branded.font_path/0` — and during `mix test` the priv/ dir IS on disk, so `Application.app_dir(:rendro, "priv/...")` succeeds.

The doctest pattern is the existing `Rendro.Recipes.Invoice` style: simple data literal in, struct field assertion out. Five lines, no fixture setup needed.

### Pitfall 4: `Rendro.AssetRegistry.register_image/3` raises on invalid binaries (does not return `{:error, _}`)

**What goes wrong:** D-26 says fence 4 (`branding-missing-asset-diagnostic`) should "assert a typed `%Rendro.Error{}` (or equivalent diagnostic tuple) is returned with structural fields." But the current `Rendro.AssetRegistry.register_image/3` RAISES `Rendro.AssetRegistry.InvalidAssetError` — it does NOT return `{:error, _}`. Similarly, `Rendro.FontRegistry.register_embedded/3` succeeds at registration time even with junk bytes; the error surfaces at preflight as `{:invalid_embedded_font, %{...}}`, which becomes an `%Rendro.Error{stage: :build, reason: {:invalid_embedded_font, _}}` after going through the pipeline.

**Why it happens:** Two registries chose different failure modes (Phase 26 vs Phase 28 design choice).

**How to avoid for fence 4:** The fence should reference an UNREGISTERED logical name from a section, not invalid registration bytes. The shape will be:

- Author a `%Rendro.Image{logical_name: :totally_bogus}` block, no matching registration.
- `Rendro.render(doc)` returns `{:error, %Rendro.Error{stage: :_, reason: ...}}`.
- Assert structurally on the `%Rendro.Error{stage: ..., reason: ...}` shape (probably `:render` stage, `reason` containing `:totally_bogus` or wrapped tuple — verify by running it).

OR (simpler): use an unregistered logical font name in `Rendro.text(..., font: :missing)` — `FontRegistry.resolve/3` returns `{:error, {:unknown_logical_font, :missing}}`, which surfaces as `%Rendro.Error{}` from the pipeline.

The planner should run a quick `iex` probe during execution to confirm the exact shape, but the fence assertion will look like:

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

This satisfies D-26 (structural %Rendro.Error{} field shape, NOT message strings) and D-21 (the diagnostic fence demonstrates the failure mode for a missing asset).

### Pitfall 5: B612 file size != CONTEXT.md estimate

**What goes wrong:** D-08 estimates ~52 KB; actual is ~150 KB. If the QUAL-07 regression test asserts `byte_size(File.read!(font_path)) < 60_000` (per CONTEXT.md), it will fail on the very first commit.

**Why it happens:** Author of CONTEXT.md may have looked at a subset/desubsetted derivative or misremembered.

**How to avoid:**
- Use the actual size as the assertion: `assert byte_size(...) == 153_192` (exact, since the bytes are committed and won't change without intent). 
- D-14's "+55 KB" delta projection becomes "+159 KB" — still well under the 8 MB Hex limit.
- The planner SHOULD update the regression assertion AND surface this to the user as a CONTEXT.md correction in the planning summary.

**Warning signs:** Asserting "<60 KB" → first test run fails on B612-Regular.ttf size; or asserting "tarball size < 90 KB" → fails the moment the new font is included.

### Pitfall 6: Phoenix example test for branded recipe assumes registries are populated

**What goes wrong:** D-19 says "structural assertion that `BrandedInvoice.document/1` registered at least one font and one image on the returned `%Document{}`." `Rendro.FontRegistry.new/0` already seeds `:default => helvetica`, so `map_size(doc.font_registry.fonts)` is always ≥1 even without registration. A naive test "≥1 font" passes vacuously.

**Why it happens:** Default Helvetica registration is Phase 25's design.

**How to avoid:**
- Assert specifically: `assert Map.has_key?(doc.font_registry.fonts, data.brand.font_name)` — confirms the brand font was registered explicitly.
- AND: `assert match?(%{source: :embedded}, doc.font_registry.fonts[data.brand.font_name])` — confirms it's the embedded brand font, not a built-in alias.
- Asset registry is fine to test with `map_size(doc.asset_registry.assets) >= 1` because `AssetRegistry.new/0` ships empty.

## Code Examples

### Verified-fence ID format (locked harness)

```
# docs-contract: <fence-id>
```

A literal Elixir comment line, anywhere inside the fence body, that matches `~r/^\s*#\s*docs-contract:\s*(?<id>[[:alnum:]_-]+)\s*$/m`. Source: `test/support/docs_contract.ex` line 4. Every verified `elixir` fence MUST carry exactly one such line; missing id raises during fence discovery.

### Fence evaluation mechanics

```elixir
# Source: test/support/docs_contract.ex
def evaluate!(code, file) do
  Code.eval_string("import ExUnit.Assertions\n#{code}", [], file: file)
end
```

Evaluated in the caller's process. `ExUnit.Assertions` is auto-imported (so `assert` works inside fences). No isolated process, no additional bindings. The contract test file is a normal `ExUnit.Case, async: false` (see `integrations_contract_test.exs`) so caller-process state is whatever the test setup leaves it.

`elixir-schematic` fences are NOT evaluated. The contract test simply skips them (the regex in `verified_fences/1` filters `lang == "elixir"` only).

### Phoenix chooser controller (D-16)

```elixir
# Source: hand-author per D-16; no existing precedent in the example app
defmodule PhoenixExampleWeb.PageController do
  use PhoenixExampleWeb, :controller

  @chooser_html ~S"""
  <!doctype html>
  <html>
    <head><title>Rendro Demo</title></head>
    <body>
      <h1>Rendro Demo</h1>
      <ul>
        <li><a href="/download">Unbranded invoice — attachment</a></li>
        <li><a href="/preview">Unbranded invoice — inline preview</a></li>
        <li><a href="/branded/download">Branded invoice with logo + custom font — attachment</a></li>
        <li><a href="/branded/preview">Branded invoice with logo + custom font — inline preview</a></li>
      </ul>
    </body>
  </html>
  """

  def index(conn, _params) do
    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_resp(200, @chooser_html)
  end
end
```

`use PhoenixExampleWeb, :controller` already imports `Plug.Conn` and `Phoenix.Controller`; `send_resp/3` and `put_resp_content_type/2` are available without explicit `import`. The router pipe-through already sets `:accepts ["json"]` — for the index page, swap to a new pipeline `:browser` that accepts `["html"]`, OR just put the index route outside the existing `:api` scope. (Existing example app uses `:api` for everything; cleanest minimal change is to add a `:browser` pipeline accepting `["html"]` and place the index under it.)

### `mix.exs` `:files` enumeration (D-12)

```elixir
# Source: hand-author per D-12; defaults documented at hexdocs.pm Mix.Tasks.Hex.Publish
defp package do
  [
    licenses: ["Apache-2.0"],  # CHANGE FROM "UNLICENSED"; see Pitfall 2
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
```

The `~w(...)` literal lists each path the tarball MUST include. Globs work (`priv/branded/**` is implied by `priv/branded` directory match per Hex semantics). Adding `LICENSE`, `NOTICE`, and `CHANGELOG.md` as explicit entries follows the Hex defaults closely. [CITED: hexdocs.pm/hex Mix.Tasks.Hex.Publish — default `:files` includes lib/priv/.formatter.exs/mix.exs/README*/LICENSE*/CHANGELOG*/src/c_src/Makefile*]

### `mix.exs` `:extras` and grouping (D-20, D-24)

Current `mix.exs` already has:
```elixir
extras: ["README.md", "guides/integrations.md"]
```

Phase 29 adds `guides/branding.md`:
```elixir
extras: ["README.md", "guides/integrations.md", "guides/branding.md"]
```

Optional grouping (Oban precedent):
```elixir
docs: [
  main: "Rendro",
  source_url: @source_url,
  extras: ["README.md", "guides/integrations.md", "guides/branding.md"],
  groups_for_extras: [
    Guides: ~r/guides\/.+/
  ]
]
```

Both `guides/integrations.md` and `guides/branding.md` then appear under a "Guides" section in the hex.pm sidebar. README stays at the top. [CITED: github.com/oban-bg/oban_web/blob/main/mix.exs `groups_for_extras` regex pattern].

### NOTICE file (D-13) — verbatim B612 OFL 1.1

The file MUST contain the verbatim 93-line OFL.txt as shipped in `polarsys/b612/OFL.txt` (and identically mirrored at `google/fonts/ofl/b612/OFL.txt`). The first 7 lines are:

```
Copyright 2012 The B612 Project Authors (https://github.com/polarsys/b612)

This Font Software is licensed under the SIL Open Font License, Version 1.1.
This license is copied below, and is also available with a FAQ at:
http://scripts.sil.org/OFL


-----------------------------------------------------------
SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
-----------------------------------------------------------
```

Followed by PREAMBLE / DEFINITIONS / PERMISSION & CONDITIONS (5 numbered conditions) / TERMINATION / DISCLAIMER. Total 93 lines, 4,470 bytes. The `branding_claims_test.exs` (D-13) MUST assert:

1. `File.exists?("NOTICE")`
2. NOTICE content =~ `"SIL OPEN FONT LICENSE Version 1.1"`
3. NOTICE content =~ `"Copyright 2012 The B612 Project Authors"`
4. NOTICE content =~ `"http://scripts.sil.org/OFL"`

The font file's own internal name table (`strings B612-Regular.ttf | grep -i license`) ALSO contains the OFL declaration: `"This Font Software is licensed under the SIL Open Font License, Version 1.1. ..."` — verified empirically. This satisfies OFL 1.1 condition #2 ("can be included either as stand-alone text files, human-readable headers or in the appropriate machine-readable metadata fields"). The NOTICE file is the stand-alone text channel. Both should ship.

**Format:** Plain text (`NOTICE`, no extension). Top-level (sibling of `README.md`, `mix.exs`). The Apache Software Foundation's third-party-license policy is the canonical precedent for this filename and location. [CITED: apache.org/legal/resolved.html — "every Apache-licensed product must contain LICENSE and NOTICE"; OFL inclusion follows the same channel].

### Logo PNG generation (D-09 — hand-author)

The cleanest path for a deterministic 64×64 RGBA PNG <2 KB without an external tool is Erlang's `:zlib` directly. Approximate sketch (the agent's discretion permits any aesthetic within the byte budget):

```elixir
# Optional: scripts/render_logo.exs (D-09 says this MAY ship for regeneration provenance)
# Build a 64×64 RGBA buffer of a simple geometric mark — solid background + simple shape.
# Encode as PNG: 8-byte signature + IHDR + IDAT (zlib-compressed) + IEND.

png_signature = <<137, 80, 78, 71, 13, 10, 26, 10>>

ihdr = chunk("IHDR", <<64::32, 64::32, 8, 6, 0, 0, 0>>)
# 8 = bit depth, 6 = color type RGBA

raw = build_pixels(64, 64)  # filtered scanlines (filter byte 0 prefix per row)
idat = chunk("IDAT", :zlib.compress(raw))
iend = chunk("IEND", <<>>)

File.write!("priv/branded/images/rendro-logo.png", png_signature <> ihdr <> idat <> iend)

defp chunk(type, data) when byte_size(type) == 4 do
  crc = :erlang.crc32(type <> data)
  <<byte_size(data)::32, type::binary, data::binary, crc::32>>
end
```

This is pure Erlang/Elixir, no external deps. Byte-stable across runs. The actual committed bytes can be authored once and verified via `byte_size(File.read!("priv/branded/images/rendro-logo.png")) < 2_000`. The script is OPTIONAL per D-09; if shipped, it lives at `scripts/render_logo.exs`. If not shipped, the bytes still get committed once — the script just exists for auditable regeneration.

[CITED: PNG file format spec, Erlang `:zlib` module standard library].

### Hand-author of canonical PNG bytes (D-09 alternative)

The agent can also use ImageMagick / Pillow as a one-time author (NOT as a runtime dep) and commit the result. Phase 28 fixtures use a 2×2 PNG via `Base.decode64!/1`; Phase 29's logo can be authored similarly with a pre-encoded byte literal in the optional script and a checked-in `.png` file. The contract is "bytes are committed; runtime contract is `File.read!/1`." [VERIFIED: Phase 28 `test/rendro/asset_registry_test.exs` uses `Base.decode64!/1` for tiny PNGs].

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| README-as-narrative-grade landing page (kitchen-sink) | README-as-orientation, `guides/` for narrative | Phoenix/Ecto/Oban ~2020 | D-24 follows precedent. |
| Auto-include `priv/` via Hex defaults | Explicit `:files` whitelist when shipping non-trivial third-party assets | Hex 1.x stable | D-12 reflects this. |
| Single-license `licenses:` field with optional `OFL` for fonts | Project license in `:licenses`, third-party attributions in NOTICE | OFL 1.1 (2007) + Apache NOTICE convention | Phase 29 ships NOTICE; v1.3 release-readiness ensures `:licenses` is SPDX-valid. |
| Test-only host-path font discovery | Library-shipped demo font in `priv/` resolved via `Application.app_dir/2` | tzdata/cldr/gettext precedent | D-07/D-10 follow this. |
| Verified docs via custom toolchain (Prawn `manual/`) | Verified docs via ExUnit + ExDoc `extras:` + fenced-code evaluation | Phoenix `guides/` + Rendro Phase 23–24 precedent | Already locked harness. |

**Deprecated/outdated:**
- `licenses: ["UNLICENSED"]` in current `mix.exs` — blocks `mix hex.publish`. Capture in v1.3 readiness blockers (D-28).
- The README's "Phoenix Integration" subsection currently uses an `elixir-schematic` fence pointing to `Rendro.Recipes.Invoice.document/1`. After D-24 adds the "Branded Documents" pointer subsection, the README explicitly names two recipes (unbranded + branded). Existing schematic fence stays unchanged; just one new ≤2-sentence subsection appears between "Tiered Composition" and "Phoenix Integration."

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Choosing `Apache-2.0` as the v1.x SPDX license is the right call (vs MIT, BSD-3-Clause). | Common Pitfalls #2; mix.exs example | If the user prefers MIT, the planner should swap. The choice does not affect any other Phase 29 task; it's a single string in `mix.exs`. The CONTEXT.md does not lock this — D-12 only mandates "audit." Surface as a question for the planner-discuss step. |
| A2 | The exact %Rendro.Error{} stage and reason returned by an unregistered-image render is `:render` stage with a tuple containing `:totally_bogus`. | Pitfall 4 | Low — fence 4's structural assertion uses pattern-match without committing to the exact stage atom (`stage in [:build, :compose, :measure, :render]`). The planner / executor MUST run `iex` once during execution to confirm and tighten if a single stage is reliably returned. |
| A3 | The committed B612-Regular.ttf bytes will be exactly 153,192 bytes (size from polarsys/b612 master, mirrored at google/fonts; both identical). | Pitfall 5; QUAL-07 regression assertion | Low — this is a verified content-length from two sources. The planner should commit the file once and assert `==` with the actual byte_size on first commit. If a later font upstream version changes, the assertion breaks deliberately, prompting maintainer review. |
| A4 | The Phoenix example app currently uses a `:api` pipeline accepting `["json"]` only; adding a `:browser` pipeline with `["html"]` for the new `GET /` index route is the cleanest minimal change. | Pattern: chooser controller; D-16 | Low — confirmed by reading `examples/phoenix_example/.../router.ex`. If the agent prefers to put `text/html` directly via `put_resp_content_type/2` without a separate pipeline, that also works. Either is methodology-compliant. |
| A5 | Doctest 3 (`document/2`) succeeds during `mix test` because `Application.app_dir(:rendro, "priv/branded/...")` resolves to a real on-disk file in the project tree. | Pitfall 3 | Low — this is the standard Elixir convention. Confirmed identical pattern works in tzdata/cldr. The doctest will fail only if `priv/branded/B612-Regular.ttf` is not present — which is exactly the pre-condition Phase 29 establishes by committing those bytes. |

## Open Questions

1. **What SPDX license should v1.x ship as? (Apache-2.0, MIT, or BSD-3-Clause?)**
   - What we know: Current `licenses: ["UNLICENSED"]` is invalid for hex.pm. METHODOLOGY/PROJECT.md don't lock a specific SPDX value.
   - What's unclear: User's preference. Apache-2.0 matches Elixir core; MIT is the Elixir-community default per official library guidelines.
   - Recommendation: Surface to user in the planning summary as a one-line decision. Default recommendation: `Apache-2.0` (compatible with all OFL-1.1-attributed assets, NOTICE-friendly per ASF policy, matches Elixir core). Either way, this is captured in v1.3 release-readiness blockers (D-28) — it doesn't block Phase 29 task execution as long as `:licenses` is left UNLICENSED for now and added to the v1.3 list.

2. **Does the chooser index page get a one-line "what is Rendro" header?**
   - What we know: D-16 says "hardcoded HTML chooser listing all four PDF endpoints with one-line captions." Discretion item explicitly: "Whether the index page chooser also embeds a one-line 'what is Rendro' header above the route list."
   - Recommendation: Include a one-line header. Cost is one HTML line; benefit is non-zero context for an adopter who lands on the demo cold. Minimal scope creep.

3. **Does `scripts/render_logo.exs` ship?**
   - What we know: D-09 makes it OPTIONAL.
   - Recommendation: Ship it. Auditability ("how were these bytes generated?") is exactly the kind of provenance Rendro's truthful-docs ethos values, AND it's ~30 lines. Cost is trivial.

4. **Exact stage/reason of the missing-asset-diagnostic %Rendro.Error{}**
   - What we know: `Rendro.AssetRegistry.fetch/2` returns `:error` for unregistered logical names (not `{:error, _}`). The pipeline downstream of measure/paginate/render — when it hits an unresolvable image — produces a typed error. The exact tuple shape needs an `iex` probe.
   - Recommendation: The planner should add a Wave-0 task: 5-line `iex` probe to confirm the exact `%Rendro.Error{stage: ..., reason: ...}` shape, and lock the fence assertion to whatever is observed. If the shape is currently inconsistent (e.g., raises instead of returning `{:error, _}`), that's a real Phase 29 fix item, not a docs-contract authoring concern.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compile/test | ✓ | `~> 1.19` | — |
| `:phoenix` | Phoenix example app + adapter | ✓ (optional dep) | `~> 1.7` | — |
| `:plug` | Phoenix adapter | ✓ (optional dep) | `~> 1.14` | — |
| `:ex_doc` | `mix docs` build, hex.pm extras | ✓ (dev/test only) | `~> 0.40` | — |
| `:telemetry` | Pipeline diagnostics | ✓ | `~> 1.4` | — |
| Erlang `:zlib` (stdlib) | Optional `scripts/render_logo.exs` PNG encoding | ✓ | OTP-bundled | If not available, hand-author PNG bytes once with ImageMagick / Pillow as a one-time tool, then commit. |
| `mix hex.build` | `branding_claims_test.exs` tarball-presence assertion (Pitfall 1 mitigation) | ✓ | OTP-bundled | — |
| `curl` (download upstream B612-Regular.ttf bytes once) | Phase 29 setup task | ✓ | system | If unavailable, use `wget` or `:httpc` directly. The bytes are then committed; this is one-time. |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None — all paths covered.

## Validation Architecture

`workflow.nyquist_validation: true` is set in `.planning/config.json` — this section is REQUIRED.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Elixir 1.19) |
| Config file | `mix.exs` `aliases.ci` and `test/test_helper.exs` |
| Quick run command | `mix test test/rendro/recipes/branded_invoice_test.exs test/docs_contract/branding_contract_test.exs test/docs_contract/branding_claims_test.exs` |
| Full suite command | `mix ci` (runs format, hex.build, compile --warnings-as-errors, test, docs, credo, dialyzer) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LAY-13 | `BrandedInvoice.page_template/1` returns `%Rendro.PageTemplate{}` with four named regions (`:logo`, `:header`, `:body`, `:footer`) | unit | `mix test test/rendro/recipes/branded_invoice_test.exs:<line>` | ❌ Wave 0 |
| LAY-13 | `BrandedInvoice.sections/2` returns four sections mapped to four regions; `data.brand` boundary validation is hard-failing (D-04) | unit | `mix test test/rendro/recipes/branded_invoice_test.exs` | ❌ Wave 0 |
| LAY-13 | `BrandedInvoice.document/2` returns `%Rendro.Document{}` with brand font registered (`source: :embedded`) and brand logo registered | unit | `mix test test/rendro/recipes/branded_invoice_test.exs` | ❌ Wave 0 |
| LAY-13 | Branded document doctests pass (page_template/1, sections/2, document/2) | doctest | `mix test --include doctest` | ❌ Wave 0 |
| LAY-13 | Phoenix example `GET /branded/download` returns 200 with `%PDF-` magic bytes | integration | `cd examples/phoenix_example && mix test test/phoenix_example_web/controllers/pdf_controller_test.exs` | ❌ Wave 0 |
| LAY-13 | `Rendro.Recipes.branded_invoice/1` delegates correctly | unit | `mix test test/rendro/recipes/branded_invoice_test.exs` | ❌ Wave 0 |
| QUAL-07 | Full pipeline render of `BrandedInvoice.document(@sample)` produces correct page count, header line breaks, image XObject inclusion, font dictionary structure (D-27) | regression | `mix test test/rendro/recipes/branded_invoice_test.exs:<regression>` | ❌ Wave 0 |
| QUAL-07 | Two consecutive `BrandedInvoice.document(@sample)` renders produce byte-identical PDFs (internal regression, D-25; not public contract per D-30) | regression | `mix test test/rendro/recipes/branded_invoice_test.exs:<byte-identity>` | ❌ Wave 0 |
| QUAL-07 | Four verified fences in `guides/branding.md` evaluate without raising (D-21) | docs-contract | `mix test test/docs_contract/branding_contract_test.exs` | ❌ Wave 0 |
| QUAL-07 | Fence 4 (`branding-missing-asset-diagnostic`) asserts structurally on `%Rendro.Error{}` field shape, not message strings (D-26) | docs-contract | `mix test test/docs_contract/branding_contract_test.exs` | ❌ Wave 0 |
| QUAL-07 | README contains "Branded Documents" pointer text (D-24) | claim | `mix test test/docs_contract/branding_claims_test.exs` | ❌ Wave 0 |
| QUAL-07 | `mix.exs` `:extras` includes `guides/branding.md` (D-20) | claim | `mix test test/docs_contract/branding_claims_test.exs` | ❌ Wave 0 |
| QUAL-07 | Top-level `NOTICE` file exists with verbatim B612 OFL 1.1 substring (D-13) | claim | `mix test test/docs_contract/branding_claims_test.exs` | ❌ Wave 0 |
| QUAL-07 | `priv/branded/fonts/B612-Regular.ttf` exists, has expected byte size (153,192) (D-08, corrected) | claim | `mix test test/docs_contract/branding_claims_test.exs` | ❌ Wave 0 |
| QUAL-07 | `priv/branded/images/rendro-logo.png` exists, byte size < 2_000 (D-09) | claim | `mix test test/docs_contract/branding_claims_test.exs` | ❌ Wave 0 |
| QUAL-07 | `mix hex.build` tarball includes `priv/branded/**` (Pitfall 1 mitigation) | claim | `mix test test/docs_contract/branding_claims_test.exs` (or release-preflight task) | ❌ Wave 0 |
| QUAL-07 | Phoenix example controller tests assert document has registered brand font + brand image (D-19, Pitfall 6) | integration | `cd examples/phoenix_example && mix test` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/rendro/recipes/branded_invoice_test.exs test/docs_contract/branding_contract_test.exs test/docs_contract/branding_claims_test.exs` (the new files)
- **Per wave merge:** `mix test` (full unit + doctest + docs-contract suite)
- **Phase gate:** `mix ci` green (format + hex.build + compile-warnings-as-errors + test + docs + credo --strict + dialyzer) before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/rendro/recipes/branded_invoice_test.exs` — covers LAY-13 (recipe shape) + QUAL-07 (regression: page count, line breaks, XObject, font dict, byte-identical two-run)
- [ ] `test/docs_contract/branding_contract_test.exs` — covers QUAL-07 (4 verified fences via `DocsContract.verified_fences/1` + `evaluate!/2`)
- [ ] `test/docs_contract/branding_claims_test.exs` — covers QUAL-07 (README pointer, mix.exs extras, NOTICE+OFL, font size, logo size, tarball presence, structural %Rendro.Error{})
- [ ] Two new `describe` blocks in `examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` — covers LAY-13 Phoenix integration proof
- [ ] No new framework install needed — ExUnit already configured, `Rendro.Test.DocsContract` helpers already exist, no new deps.
- [ ] No new shared fixtures needed — sample data lives in test files (mirrors `invoice_test.exs` precedent).

## Security Domain

`security_enforcement` is absent from `.planning/config.json`. Per agent instructions: "absent = enabled." However, this phase has minimal security surface — no authentication, no input from untrusted sources at runtime (the recipe takes typed Elixir maps), no cryptography, no session management, no network I/O. The font and logo bytes are committed library-owned assets, not user-uploaded content. The relevant ASVS controls reduce to:

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — (no auth surface in this phase) |
| V3 Session Management | no | — (no sessions) |
| V4 Access Control | no | — (no access boundaries; library is pure data transformation) |
| V5 Input Validation | yes | `BrandedInvoice.validate_data!/1` raises `ArgumentError` on missing/malformed `data.brand` (D-04, METHODOLOGY "Boundary Validation First"). Existing `Rendro.AssetRegistry.register_image/3` validates image bytes via `Rendro.ImageParser.parse/1` before storing. Existing `Rendro.FontRegistry.register_embedded/3` normalizes path bytes eagerly (Phase 26 D-02/D-03). |
| V6 Cryptography | no | — (no cryptographic operations introduced; PDF metadata writer remains the same) |
| V12 File Handling | yes | `Rendro.Branded.font_path/0` and `.logo_path/0` resolve through `Application.app_dir(:rendro, "priv/...")` — no user-controlled path concatenation, no path traversal possible. The bytes are library-owned shipped assets. |
| V14 Configuration | yes | `mix.exs` `:files` enumeration is the configuration surface that ensures shipped tarball contains the expected assets (Pitfall 1 mitigation via tarball-presence claim test). |

### Known Threat Patterns for Elixir/OTP + ExDoc-shipped library

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal in user-controlled file path | Tampering | Library uses no user-controlled paths in this phase; `Application.app_dir/2` is hardcoded literals only. |
| Compressed-stream bomb in PNG IDAT (zlib decompression amplification) | Denial of Service | Logo PNG bytes are committed library assets, not user uploads. Logo is 64×64 fixed dimensions; decompressed size is bounded at ~16 KB raw RGBA. No amplification surface. |
| TrueType parsing exploit on malformed font | Tampering | Font bytes are library-owned, parsed once at registration via `Rendro.PDF.FontParser`, with errors surfaced as typed `{:invalid_embedded_font, ...}` (Phase 26 D-10). No runtime user-supplied fonts in the branded path. |
| Verified-guide fence allowing arbitrary code execution at test time | Tampering / Repudiation | `Code.eval_string/3` runs in caller process; fences are committed source under `guides/`. Same risk profile as any test source file. Verified by code review at PR time, like all source. |
| License/attribution drift on third-party assets | Repudiation (legal) | NOTICE presence + OFL header substring asserted in claims test (D-13); font's own internal name table independently carries the license declaration. |

The phase introduces no new attack surface beyond what Phase 25/26/28 already established for font/asset registration.

## Sources

### Primary (HIGH confidence — code-grounded or directly verified)

- `/Users/jon/projects/rendro/lib/rendro/recipes/invoice.ex` — Tiered Composition reference implementation; structural template for `BrandedInvoice`.
- `/Users/jon/projects/rendro/lib/rendro/recipes.ex` — delegate convention for `branded_invoice/1`.
- `/Users/jon/projects/rendro/lib/rendro/font_registry.ex` — `register_embedded/3` accepts `{:path, _}` and `{:binary, _}`; normalizes path bytes via `File.read/1`.
- `/Users/jon/projects/rendro/lib/rendro/asset_registry.ex` — `register_image/3` accepts both source kinds; raises `InvalidAssetError` on parse failure (Pitfall 4).
- `/Users/jon/projects/rendro/lib/rendro/document.ex` — pipeline builder API: `register_embedded_font/3`, `register_image/3`, `add_template/2`, `set_template/2`, `add_section/2`.
- `/Users/jon/projects/rendro/lib/rendro/error.ex` — `%Rendro.Error{stage, reason, details, ...}` shape used by D-26 fence-4 assertion.
- `/Users/jon/projects/rendro/lib/rendro/adapters/phoenix.ex` — `render_pdf/3`, `preview_pdf/2` reused by branded controller actions.
- `/Users/jon/projects/rendro/test/support/docs_contract.ex` — `verified_fences/1` regex (`# docs-contract: <id>` line) and `evaluate!/2` (`Code.eval_string` with `import ExUnit.Assertions`).
- `/Users/jon/projects/rendro/test/docs_contract/integrations_contract_test.exs` — fence-existence + evaluate-each precedent.
- `/Users/jon/projects/rendro/test/docs_contract/integrations_claims_test.exs` — structural `%Rendro.Error{}` assertion precedent (D-26).
- `/Users/jon/projects/rendro/test/rendro/pdf/writer_test.exs` — PDF substring assertion patterns: `/Type /XObject`, `/Subtype /Image`, `/Width N`, `/Height N`, `/F_BRAND`, `/FontDescriptor`, `/FontFile2` (D-27 mechanics).
- `/Users/jon/projects/rendro/test/rendro/deterministic_test.exs` — byte-identical-two-renders pattern (D-25).
- `/Users/jon/projects/rendro/test/rendro/recipes/invoice_test.exs` — recipe regression test pattern (page_template / sections / document describes).
- `/Users/jon/projects/rendro/test/rendro/asset_registry_test.exs` — Phase 28 register_image pattern + Base.decode64! tiny-PNG fixture pattern.
- `/Users/jon/projects/rendro/examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` — `@demo_invoice`, `download/2`, `preview/2` precedent for branded actions.
- `/Users/jon/projects/rendro/examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` — describe-block structure to mirror.
- `/Users/jon/projects/rendro/examples/phoenix_example/lib/phoenix_example_web/router.ex` — current `:api` pipeline; needs `:browser` for HTML index.
- `/Users/jon/projects/rendro/mix.exs` — current `package`, `docs`, `extras`; `licenses: ["UNLICENSED"]` flagged.
- `/Users/jon/projects/rendro/README.md` — current "Tiered Composition" / "Phoenix Integration" section seam where pointer slots in.
- `/Users/jon/projects/rendro/guides/integrations.md` — fence-cardinality precedent (4 verified `elixir` + multiple `elixir-schematic`).
- HTTP HEAD on `https://github.com/polarsys/b612/raw/master/fonts/ttf/B612-Regular.ttf` and download → 153,192 bytes [VERIFIED 2026-05-01].
- GitHub API listing of `google/fonts/ofl/b612/` → identical byte count for B612-Regular.ttf, `OFL.txt` is 4,470 bytes [VERIFIED 2026-05-01].
- Verbatim OFL.txt download → 93 lines beginning with "Copyright 2012 The B612 Project Authors..." [VERIFIED 2026-05-01].

### Secondary (MEDIUM confidence — official docs cross-referenced)

- [hexdocs.pm/hex Mix.Tasks.Hex.Publish](https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html) — `:files` defaults, `:licenses` SPDX requirement.
- [hexdocs.pm/elixir library-guidelines](https://hexdocs.pm/elixir/library-guidelines.html) — versioning, license, code formatting, doc requirements.
- [github.com/oban-bg/oban_web mix.exs](https://github.com/oban-bg/oban_web/blob/main/mix.exs) — `groups_for_extras` regex precedent.
- [openfontlicense.org official text](https://openfontlicense.org/) — OFL 1.1 canonical license text (cross-verified against shipped OFL.txt).
- [apache.org/legal/resolved](https://www.apache.org/legal/resolved.html) — NOTICE file conventions.
- [github.com/polarsys/b612](https://github.com/polarsys/b612) — canonical B612 source repo; OFL.txt and TTF bytes mirror identically at google/fonts.
- [hexdocs.pm/elixir Application module docs](https://hexdocs.pm/elixir/Application.html) — `app_dir/2` resolves correctly across path/hex/umbrella deps.

### Tertiary (LOW confidence — flagged for validation)

- The exact `%Rendro.Error{}` stage and reason tuple returned by an unregistered-image render is not source-verified in this research. The planner / executor MUST run a one-line `iex` probe during execution to confirm and tighten the fence-4 assertion. Marked as A2 in Assumptions Log.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every reused module is in-tree and verified by direct read.
- Architecture: HIGH — the architecture mirrors locked Phase 22 / 25 / 26 / 28 patterns; the only new module (`Rendro.Branded`) is 8 lines of `Application.app_dir/2` wrapping.
- Pitfalls: HIGH — Pitfalls 1, 2, 5 are factual corrections grounded in Hex docs / SPDX rules / verified file size. Pitfall 3, 4, 6 are derived from reading the existing harness/registry source.
- Validation Architecture: HIGH — every test file maps to existing precedent; nothing requires new infra.
- B612 sourcing: HIGH — file bytes verified by direct download from two independent canonical sources (polarsys/b612 + google/fonts), byte-identical.
- License recommendations: MEDIUM — `Apache-2.0` recommendation surfaced for user confirmation (A1).

**Research date:** 2026-05-01

**Valid until:** 2026-05-31 (30 days; the only fast-moving inputs are upstream B612 file size and Hex `:files` semantics — both stable for years; revisit if `mix.exs` license validation rules change in a Hex release).
