---
phase: 29
plan: 05
type: execute
wave: 2
depends_on: [03]
files_modified:
  - guides/branding.md
autonomous: true
requirements: [QUAL-07]
requirements_addressed: [QUAL-07]

must_haves:
  truths:
    - "guides/branding.md exists at top-level guides/ directory and mirrors guides/integrations.md structure with FIVE named subsections: Overview, Registering brand fonts, Registering logo assets, BrandedInvoice tiered composition, Failure diagnostics (D-20)"
    - "Exactly FOUR verified `elixir` fences each carrying a `# docs-contract: <id>` comment line: branding-register-assets, branding-tiered-document, branding-tiered-template, branding-missing-asset-diagnostic (D-21)"
    - "AT MOST ONE elixir-schematic fence (compile-only, NOT evaluated by harness) showing where to drop a MyApp.Branding setup module (D-22)"
    - "Fence 1 (branding-register-assets): registers brand font + image on a fresh Rendro.Document.new/0 via Rendro.Document.register_embedded_font/3 + register_image/3 with {:path, _} from Rendro.Branded; asserts both registries reflect the registration"
    - "Fence 2 (branding-tiered-document): calls Rendro.Recipes.BrandedInvoice.document/1 with a literal data map; asserts rendered PDF starts with %PDF- magic bytes AND contains at least one font-dict reference and one image XObject reference"
    - "Fence 3 (branding-tiered-template): composes via page_template/1 + sections/2 + Rendro.Document.new |> add_template |> set_template |> reduce add_section (escape-hatch path) — same data, manual assembly; asserts active template name and section regions"
    - "Fence 4 (branding-missing-asset-diagnostic): references an UNREGISTERED logical name (per Pitfall 4 — NOT junk bytes); asserts {:error, %Rendro.Error{stage: stage, reason: reason}} = Rendro.render(doc) with stage in [:asset_resolve, :build, :compose, :measure, :render, :pipeline] (defensive set membership) AND reason != nil — STRUCTURAL only, NEVER message strings (D-26)"
    - "Each fence body MUST NOT contain `...` ellipsis or `%{...}` skeleton placeholders — these break Code.eval_string evaluation in the harness (per integrations_contract_test.exs precedent)"
    - "guides/branding.md uses no host-system discovery; all asset paths come from Rendro.Branded (D-31)"
    - "Failure-diagnostics subsection ships a Markdown table with columns 'Error tuple | When it occurs | What to check' mirroring guides/integrations.md precedent"
  artifacts:
    - path: "guides/branding.md"
      provides: "Verified ExDoc extra documenting brand-font + brand-asset registration, BrandedInvoice tiered composition, and missing-asset diagnostic"
      contains: ["# Branding", "## Overview", "## Registering brand fonts", "## Registering logo assets", "## BrandedInvoice tiered composition", "## Failure diagnostics", "# docs-contract: branding-register-assets", "# docs-contract: branding-tiered-document", "# docs-contract: branding-tiered-template", "# docs-contract: branding-missing-asset-diagnostic", "Rendro.Recipes.BrandedInvoice", "Rendro.Branded", "%Rendro.Error{"]
  key_links:
    - from: "guides/branding.md"
      to: "lib/rendro/recipes/branded_invoice.ex (Plan 03)"
      via: "Fence 2 calls Rendro.Recipes.BrandedInvoice.document/1; Fence 3 calls page_template/1 + sections/2"
      pattern: "Rendro\\.Recipes\\.BrandedInvoice"
    - from: "guides/branding.md"
      to: "lib/rendro/branded.ex (Plan 02)"
      via: "Fence 1 calls Rendro.Branded.font_path/0 + logo_path/0"
      pattern: "Rendro\\.Branded\\.(font|logo)_path"
    - from: "guides/branding.md"
      to: "test/docs_contract/branding_contract_test.exs (Plan 06)"
      via: "Fence IDs are discovered by Rendro.Test.DocsContract.verified_fences/1 and evaluated by evaluate!/2"
      pattern: "# docs-contract: branding-"
---

<objective>
Ship `guides/branding.md` — a verified ExDoc extra mirroring `guides/integrations.md` structure (D-20) with EXACTLY four verified `elixir` fences carrying `# docs-contract: <id>` lines (D-21) and AT MOST ONE non-evaluated `elixir-schematic` fence for app scaffolding (D-22).

Five named subsections in this exact order (D-20):
1. Overview
2. Registering brand fonts
3. Registering logo assets
4. BrandedInvoice tiered composition
5. Failure diagnostics

The four verified fence IDs (D-21):
- `branding-register-assets` — manual registration on fresh document
- `branding-tiered-document` — zero-to-one path via `BrandedInvoice.document/1`
- `branding-tiered-template` — escape-hatch path via `page_template/1` + `sections/2` + manual assembly
- `branding-missing-asset-diagnostic` — typed `%Rendro.Error{}` shape on missing asset (Pitfall 4 — UNREGISTERED logical name, NOT junk bytes; D-26 — structural assertions only, no message strings)

This plan implements D-20, D-21, D-22, and contributes the fence bodies that D-26 (structural error shape) is verified against in Plan 06's contract test.

Purpose: Without this guide, the docs-contract harness in Plan 06 has nothing to evaluate. The guide is also the only narrative-grade docs surface for branded recipes (README is bounded to ≤2 sentences per D-24).

Output: One new ~250-300 line Markdown file at `guides/branding.md`. No code changes; test wiring lives in Plans 06 and 08.
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

# Mirror analog (verified ExDoc extra precedent):
@guides/integrations.md

# Modules referenced by fences:
@lib/rendro/recipes/branded_invoice.ex
@lib/rendro/branded.ex
@lib/rendro/document.ex
@lib/rendro/error.ex

# Verified-fence harness (Plan 06 consumes these):
@test/support/docs_contract.ex

<interfaces>
<!-- Fence-discovery regex (locked harness): -->
# docs-contract: <fence-id>
# Regex: ~r/^\s*#\s*docs-contract:\s*(?<id>[[:alnum:]_-]+)\s*$/m
# Source: test/support/docs_contract.ex line 4-5

<!-- Fence evaluation: -->
def evaluate!(code, file) do
  Code.eval_string("import ExUnit.Assertions\n#{code}", [], file: file)
end
# `assert` works inside fences without explicit import. `elixir-schematic` is filtered out.

<!-- %Rendro.Error{} shape (lib/rendro/error.ex): -->
%Rendro.Error{
  stage: atom(),       # :build | :compose | :measure | :render | :asset_resolve | :pipeline | ...
  reason: term(),      # never nil for real errors
  details: map() | nil,
  what: String.t(),    # human-readable — DO NOT assert in fences (D-26)
  where: String.t(),   # human-readable — DO NOT assert
  why: String.t(),     # human-readable — DO NOT assert
  next: String.t(),    # human-readable — DO NOT assert
  render_id: String.t() | nil
}
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Author guides/branding.md with five subsections, four verified fences, one schematic fence, and failure-diagnostics table</name>
  <read_first>
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-CONTEXT.md (D-20, D-21, D-22, D-26, D-31)
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-RESEARCH.md ("Code Examples: Verified-fence ID format" lines 516-535; "Pitfall 4" lines 457-488; "NOTICE file" lines 622-646; A2 in Assumptions Log re fence-4 stage)
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-PATTERNS.md (`guides/branding.md` analog section, lines 259-326; "Failure-diagnostics table pattern" lines 296-305; "Fence 4 (missing-asset diagnostic) pattern" lines 307-326; "Schematic-fence pattern" lines 280-294)
    - guides/integrations.md (mirror target — read entire file for header structure, fence cardinality, schematic fence format, failure-diagnostics table format)
    - lib/rendro/recipes/branded_invoice.ex (Plan 03 — confirms public surface for fence bodies)
    - lib/rendro/branded.ex (Plan 02 — confirms font_path/0 + logo_path/0 are available)
    - lib/rendro/error.ex (confirms %Rendro.Error{} field shape for fence 4 + diagnostics table)
    - test/support/docs_contract.ex (confirms `# docs-contract: <id>` regex and Code.eval_string evaluator)
  </read_first>
  <files>
    - guides/branding.md (NEW)
  </files>
  <action>
    Author `guides/branding.md` with the five-subsection structure mandated by D-20 and the four verified fences mandated by D-21. Mirror `guides/integrations.md` structure verbatim — same heading hierarchy, same fence-ID-comment convention, same failure-diagnostics table style.

    Suggested skeleton (executor MAY adjust prose for natural reading; fence IDs and structural asserts are LOCKED):

    ````markdown
    # Branding

    Branded canonical documents in Rendro combine a registered embedded font, a
    registered image asset, and the canonical Tiered Composition recipe surface.
    The branded path is locked behind the same truthful-contract guarantees as
    every other Rendro public API: typed errors at the boundary, no silent
    fallback, no system-font discovery, no remote asset fetching.

    This guide ships four verified examples that the docs-contract test suite
    evaluates on every CI run. If a fence drifts from the public API, CI fails
    before the guide is rendered to hex.pm.

    ## Overview

    There are three ways to compose a branded document, in increasing levels
    of explicitness:

      1. **Recipe** — `Rendro.Recipes.BrandedInvoice.document/1` is the
         zero-to-one path. Pass a data map with a `:brand` field; receive a
         fully assembled `%Rendro.Document{}` ready for `Rendro.render/1`.
      2. **Tiered composition** — `page_template/1` + `sections/2` give
         layout-only and content-only views of the recipe. Compose them
         manually with the document builder API for fine-grained control.
      3. **Manual** — `Rendro.Document.register_embedded_font/3` and
         `Rendro.Document.register_image/3` are the public registration
         primitives. Any branded document, recipe-driven or not, ultimately
         goes through these.

    Demo brand assets ship in `priv/branded/`: `B612-Regular.ttf` (SIL OFL
    1.1) and a small geometric `rendro-logo.png` mark. The `Rendro.Branded`
    module exposes their resolved paths via the canonical `Application.app_dir/2`
    convention. These are demo assets — NOT a built-in font or default logo;
    adopters who copy the recipe should swap the `Rendro.Branded` calls for
    their own asset bytes.

    ## Registering brand fonts

    The branded recipe registers its font through the public document
    builder API. Manual registration follows the same shape:

    ```elixir
    # docs-contract: branding-register-assets
    doc =
      Rendro.Document.new()
      |> Rendro.Document.register_embedded_font(
           :brand_heading,
           {:path, Rendro.Branded.font_path()})
      |> Rendro.Document.register_image(
           :company_logo,
           {:path, Rendro.Branded.logo_path()})

    assert Map.has_key?(doc.font_registry.fonts, :brand_heading)
    assert match?(%{source: :embedded}, doc.font_registry.fonts[:brand_heading])
    assert Map.has_key?(doc.asset_registry.assets, :company_logo)
    ```

    The `{:path, Path.t()}` source tuple is the canonical way to register
    library-shipped binaries; the registries normalize the bytes internally.
    For adopter-supplied bytes, `{:binary, binary()}` is also accepted.

    ## Registering logo assets

    `Rendro.Document.register_image/3` accepts the same `{:path, _}` /
    `{:binary, _}` source tuples and parses image headers eagerly to extract
    intrinsic width, height, and MIME type at registration time. The asset
    registry is the single source of truth for the logical-name → bytes
    mapping; the recipe and any author who calls `Rendro.image/2` reference
    the same logical names.

    ## BrandedInvoice tiered composition

    The recipe's zero-to-one path:

    ```elixir
    # docs-contract: branding-tiered-document
    data = %{
      id: "INV-2026-101",
      date: ~D[2026-04-30],
      items: [
        %{name: "Consulting", qty: 10, price: 2500},
        %{name: "Support",     qty: 1,  price: 500}
      ],
      brand: %{font_name: :brand_heading, logo_name: :company_logo}
    }

    doc = Rendro.Recipes.BrandedInvoice.document(data)
    assert doc.page_template == :branded_invoice

    {:ok, pdf} = Rendro.render(doc)
    assert is_binary(pdf)
    assert binary_part(pdf, 0, 5) == "%PDF-"
    assert pdf =~ "/FontFile2"
    assert pdf =~ "/Type /XObject"
    ```

    The escape-hatch path that composes layout and content explicitly:

    ```elixir
    # docs-contract: branding-tiered-template
    data = %{
      id: "INV-2026-102",
      date: ~D[2026-04-30],
      items: [%{name: "Consulting", qty: 1, price: 1000}],
      brand: %{font_name: :brand_heading, logo_name: :company_logo}
    }

    template = Rendro.Recipes.BrandedInvoice.page_template()
    sections = Rendro.Recipes.BrandedInvoice.sections(data)

    doc =
      Rendro.Document.new()
      |> Rendro.Document.register_embedded_font(
           data.brand.font_name,
           {:path, Rendro.Branded.font_path()})
      |> Rendro.Document.register_image(
           data.brand.logo_name,
           {:path, Rendro.Branded.logo_path()})
      |> Rendro.Document.add_template(template)
      |> Rendro.Document.set_template(template.name)
      |> then(fn d ->
           Enum.reduce(sections, d, &Rendro.Document.add_section(&2, &1))
         end)

    assert doc.page_template == :branded_invoice
    region_targets = Enum.map(doc.sections, & &1.region) |> Enum.sort()
    assert region_targets == [:body, :footer, :header, :logo]
    ```

    For application-level scaffolding (a setup module that registers brand
    assets once at boot), drop something like this in your application
    namespace. This fence is compile-only — the docs-contract harness skips
    `elixir-schematic` blocks:

    ```elixir-schematic
    defmodule MyApp.Branding do
      @moduledoc "Application-level brand registration helpers."

      def register(doc) do
        doc
        |> Rendro.Document.register_embedded_font(
             :brand_heading,
             {:path, Rendro.Branded.font_path()})
        |> Rendro.Document.register_image(
             :company_logo,
             {:path, Rendro.Branded.logo_path()})
      end
    end
    ```

    ## Failure diagnostics

    Branded documents reach a typed error if a section references an
    unregistered logical name. The pipeline surfaces a `%Rendro.Error{}`
    with structural fields the test surface can pattern-match on. Asserting
    on `:stage` (set membership) and `:reason` (non-nil) is stable across
    error-message wording changes.

    ```elixir
    # docs-contract: branding-missing-asset-diagnostic
    template = Rendro.Recipes.BrandedInvoice.page_template()

    doc =
      Rendro.Document.new()
      |> Rendro.Document.add_template(template)
      |> Rendro.Document.set_template(:branded_invoice)
      |> Rendro.Document.add_section(
           Rendro.section(
             name: :branded_invoice_logo,
             region: :logo,
             content: [Rendro.block(Rendro.image(:unregistered_logo, width: 64, height: 64))]
           )
         )

    assert {:error, %Rendro.Error{stage: stage, reason: reason}} = Rendro.render(doc)
    assert stage in [:asset_resolve, :build, :compose, :measure, :render, :pipeline]
    assert reason != nil
    # Structural only — DO NOT assert on .what / .why / .next message strings.
    ```

    Common error tuples and what to check:

    | Error tuple | When it occurs | What to check |
    |---|---|---|
    | `{:error, %Rendro.Error{stage: :render, reason: {:unregistered_image, name}}}` | A section references a logical image name that was never registered on the document. | Confirm `Rendro.Document.register_image/3` was called with the same atom; check the recipe's `data.brand.logo_name` matches the logical name used in `Rendro.image/2`. |
    | `{:error, %Rendro.Error{stage: :measure, reason: {:unknown_logical_font, name}}}` | A text node references a logical font name that was never registered. | Confirm `Rendro.Document.register_embedded_font/3` was called for that atom; check the recipe's `data.brand.font_name` matches the font passed to `Rendro.text/2`. |
    | `{:error, %Rendro.Error{stage: :build, reason: {:invalid_embedded_font, _}}}` | The font bytes failed parsing during registration normalization. | Confirm `priv/branded/fonts/B612-Regular.ttf` exists and was not truncated; rerun `mix deps.compile rendro --force`. |
    | `ArgumentError` (raised, not tuple) | `data.brand.font_name` or `data.brand.logo_name` is missing or non-atom. | The recipe boundary validation hard-fails at entry. Pass `data.brand` with both keys as atoms. |

    The `%Rendro.Error{}` struct also carries `:what`, `:where`, `:why`,
    and `:next` human-readable string fields. These are intended for
    log/UI presentation and stable string formats are NOT a public contract;
    pattern-match on `:stage` and `:reason` for programmatic handling.

    ## Determinism

    With `Rendro.render(doc, deterministic: true)`, two consecutive renders
    of the same `%Rendro.Document{}` produce identical bytes. This is the
    contract surface for embedding Rendro in regression suites and golden-file
    harnesses. Whole-PDF byte identity is NOT a public guarantee for the
    branded path across versions; structural assertions on font dictionary
    entries and image XObject presence are the durable proof channel.
    ````

    Concrete requirements:
    - File path EXACTLY `guides/branding.md` (sibling of existing `guides/integrations.md`).
    - First line is `# Branding` (the title; no leading metadata).
    - Five subsection headings (`## Overview`, `## Registering brand fonts`, `## Registering logo assets`, `## BrandedInvoice tiered composition`, `## Failure diagnostics`) — these are the D-20-named five.
    - The "Determinism" subsection at the end is allowed (Claude's discretion per D-20 — internal organization beyond the five named subsections).
    - EXACTLY 4 verified `elixir` fences with `# docs-contract: <id>` lines, IDs being EXACTLY: `branding-register-assets`, `branding-tiered-document`, `branding-tiered-template`, `branding-missing-asset-diagnostic`.
    - AT MOST ONE `elixir-schematic` fence (the `MyApp.Branding` example above is the only one).
    - No `...` ellipsis or `%{...}` skeleton placeholder INSIDE any verified `elixir` fence body — `Code.eval_string` cannot evaluate those, and the `integrations_contract_test.exs` precedent guards `refute String.contains?(code, "...")`.
    - Fence 4's structural assertion uses `stage in [:asset_resolve, :build, :compose, :measure, :render, :pipeline]` (defensive set per A2 in Assumptions Log — exact stage will be locked at execution time after iex probe).
    - Fence 4 references an UNREGISTERED logical name (`:unregistered_logo`), NOT junk bytes (Pitfall 4 — `Rendro.AssetRegistry.register_image/3` raises on junk bytes; that path doesn't yield a `{:error, _}` tuple).
    - Each fence body ends WITHOUT a trailing `# docs-contract: ` extra line — exactly one comment-line ID per fence (matched by the regex in `test/support/docs_contract.ex` line 5).
    - DO NOT add a fifth `elixir` fence. D-21 caps cardinality at four; the contract test in Plan 06 will assert `Enum.map(fences, & &1.id) == [those 4 IDs]` exactly.
    - DO NOT call any `Rendro.Adapters.Phoenix` API in any fence — that's `guides/integrations.md`'s territory.
    - DO NOT introduce new public APIs in the guide that don't exist on `Rendro.Document` / `Rendro.Recipes.BrandedInvoice` / `Rendro.Branded` (Plans 02 + 03 lock the public surface).
    - The Failure-diagnostics table column order is `Error tuple | When it occurs | What to check` (D-20 mirror of `guides/integrations.md`).
    - DO NOT assert on `%Rendro.Error{}` `.what`, `.where`, `.why`, or `.next` string fields anywhere — D-26 forbids it. Reinforced by the comment line in fence 4 and the closing prose in the failure-diagnostics section.

    Verify the guide compiles via the harness:
    ```bash
    mix run -e '
      fences = Rendro.Test.DocsContract.verified_fences("guides/branding.md")
      ids = Enum.map(fences, & &1.id)
      IO.inspect(ids, label: "fence_ids")
      true = ids == [
        "branding-register-assets",
        "branding-tiered-document",
        "branding-tiered-template",
        "branding-missing-asset-diagnostic"
      ]
    '
    ```

    Note on iex probe for fence 4 (per RESEARCH.md A2): once Plans 03 + 04 are landing, run a one-line iex check to find the exact stage atom returned by an unregistered-image render, and tighten the `stage in [...]` set accordingly. The defensive set above accepts any of those stage atoms; tightening to a single atom is preferred but not required for Plan 05's acceptance — Plan 06's docs-contract test re-evaluates the fence body and will catch a mismatch.
  </action>
  <acceptance_criteria>
    - `test -f guides/branding.md` exits 0
    - `head -1 guides/branding.md | grep -Fq '# Branding'` exits 0  (title line)
    - `grep -cE '^## (Overview|Registering brand fonts|Registering logo assets|BrandedInvoice tiered composition|Failure diagnostics)$' guides/branding.md` outputs exactly `5`
    - `grep -cE '^# docs-contract:' guides/branding.md` outputs exactly `4`
    - `grep -Fq '# docs-contract: branding-register-assets' guides/branding.md` exits 0
    - `grep -Fq '# docs-contract: branding-tiered-document' guides/branding.md` exits 0
    - `grep -Fq '# docs-contract: branding-tiered-template' guides/branding.md` exits 0
    - `grep -Fq '# docs-contract: branding-missing-asset-diagnostic' guides/branding.md` exits 0
    - `grep -cE '^```elixir-schematic$' guides/branding.md` outputs at most `1`  (D-22 — at most one schematic)
    - `grep -cE '^```elixir$' guides/branding.md` outputs exactly `4`  (D-21 — exactly four verified `elixir` fences)
    - `grep -Fq 'Rendro.Recipes.BrandedInvoice' guides/branding.md` exits 0
    - `grep -Fq 'Rendro.Branded.font_path' guides/branding.md` exits 0
    - `grep -Fq 'Rendro.Branded.logo_path' guides/branding.md` exits 0
    - `grep -Fq 'register_embedded_font' guides/branding.md` exits 0
    - `grep -Fq 'register_image' guides/branding.md` exits 0
    - `grep -Fq '%Rendro.Error{stage:' guides/branding.md` exits 0
    - `grep -Fq 'reason: reason' guides/branding.md` exits 0
    - `grep -Fq ':unregistered_logo' guides/branding.md` exits 0  (Pitfall 4 — unregistered name, not junk bytes)
    - Anti-pattern absence: `! grep -Fq '%Rendro.Error{what:' guides/branding.md`  (D-26 — never assert .what)
    - Anti-pattern absence: `! grep -Fq '%Rendro.Error{why:' guides/branding.md`  (D-26)
    - Anti-pattern absence: `! grep -Fq '%Rendro.Error{next:' guides/branding.md`  (D-26)
    - Verified-fence body cleanliness: each verified fence body MUST NOT contain literal `...` ellipsis. Run: `awk '/^```elixir$/{flag=1; next} /^```$/{flag=0} flag {print}' guides/branding.md | grep -Fq '...'` MUST exit non-zero (i.e., no ellipsis in any verified fence body).
    - Failure-diagnostics table header line is present: `grep -Fq 'Error tuple | When it occurs | What to check' guides/branding.md` exits 0
    - `mix run -e 'ids = Rendro.Test.DocsContract.verified_fences("guides/branding.md") |> Enum.map(& &1.id); IO.inspect(ids); true = ids == ["branding-register-assets","branding-tiered-document","branding-tiered-template","branding-missing-asset-diagnostic"]'` exits 0
  </acceptance_criteria>
  <verify>
    <automated>test -f guides/branding.md && head -1 guides/branding.md | grep -Fq '# Branding' && [ "$(grep -cE '^## (Overview|Registering brand fonts|Registering logo assets|BrandedInvoice tiered composition|Failure diagnostics)$' guides/branding.md)" = "5" ] && [ "$(grep -cE '^# docs-contract:' guides/branding.md)" = "4" ] && [ "$(grep -cE '^```elixir$' guides/branding.md)" = "4" ] && grep -Fq '# docs-contract: branding-register-assets' guides/branding.md && grep -Fq '# docs-contract: branding-tiered-document' guides/branding.md && grep -Fq '# docs-contract: branding-tiered-template' guides/branding.md && grep -Fq '# docs-contract: branding-missing-asset-diagnostic' guides/branding.md && grep -Fq ':unregistered_logo' guides/branding.md && ! grep -Fq '%Rendro.Error{what:' guides/branding.md && mix run -e 'ids = Rendro.Test.DocsContract.verified_fences("guides/branding.md") |> Enum.map(& &1.id); true = ids == ["branding-register-assets","branding-tiered-document","branding-tiered-template","branding-missing-asset-diagnostic"]'</automated>
  </verify>
  <done>
    guides/branding.md exists with the five D-20-mandated subsections, exactly four D-21 verified `elixir` fences (IDs branding-register-assets / branding-tiered-document / branding-tiered-template / branding-missing-asset-diagnostic), at most one D-22 schematic fence (MyApp.Branding scaffolding), and a failure-diagnostics Markdown table mirroring guides/integrations.md format. Fence 4 references an unregistered logical name (Pitfall 4) and asserts structurally on %Rendro.Error{stage, reason} field shape (D-26) — never message strings. Rendro.Test.DocsContract.verified_fences/1 returns exactly the four expected IDs in expected order.
  </done>
</task>

</tasks>

<verification>
- `mix run -e 'Rendro.Test.DocsContract.verified_fences("guides/branding.md") |> Enum.map(& &1.id) |> IO.inspect()'` outputs exactly `["branding-register-assets", "branding-tiered-document", "branding-tiered-template", "branding-missing-asset-diagnostic"]`
- The four verified fence bodies are evaluable via `Code.eval_string` (Plan 06's contract test will exercise this — Plan 05's acceptance only requires the harness can DISCOVER the fences).
- `grep -c '^```elixir$' guides/branding.md` outputs exactly `4` (D-21 cardinality)
- `grep -c '^```elixir-schematic$' guides/branding.md` outputs at most `1` (D-22 cardinality)
- The five D-20 subsections appear in the exact required order at the start of each subsection block.
- No `%Rendro.Error{}` `.what` / `.why` / `.next` / `.where` field assertions anywhere in the file (D-26 enforcement).
- No `Path.expand(__DIR__)` or `File.cwd!` calls anywhere in the file (D-31 carried forward).
- `git status` shows `guides/branding.md` as a new file; no other files modified by this plan.
</verification>

<success_criteria>
- `guides/branding.md` is a verified ExDoc extra mirroring `guides/integrations.md`'s structure exactly (D-20).
- Exactly four verified `elixir` fences carry the four D-21 IDs (set membership AND ordering verified by Plan 06's contract test).
- At most one `elixir-schematic` fence shows where to drop a `MyApp.Branding` setup module (D-22).
- Fence 4 (`branding-missing-asset-diagnostic`) uses an UNREGISTERED logical name (not junk bytes — Pitfall 4 mitigation) and asserts structurally on `%Rendro.Error{stage, reason}` only — no message string `.what`/`.why`/`.next` assertions (D-26).
- Failure-diagnostics subsection ships a three-column Markdown table mirroring `guides/integrations.md`'s "Error tuple | When it occurs | What to check" format.
- The guide is self-contained — every public API mentioned exists in Plans 02 + 03 outputs (`Rendro.Branded`, `Rendro.Recipes.BrandedInvoice`, `Rendro.Document.register_*`, `Rendro.image/2`, `Rendro.section/1`, `Rendro.block/1`).
- No system-font discovery, no host paths, no remote fetching anywhere (D-31 carried forward).
</success_criteria>

<output>
After completion, create `.planning/phases/29-branded-recipes-docs-and-proof-closure/29-05-SUMMARY.md` documenting:
- Total LOC of `guides/branding.md`
- Confirmation of exactly 4 verified `elixir` fences (IDs in canonical order) and exactly 1 (or 0) `elixir-schematic` fence
- The exact `stage in [...]` set used in Fence 4 (post-iex probe — locked atom set; pre-probe uses defensive multi-atom set per A2)
- Confirmation that no message-string assertions exist on `%Rendro.Error{}` fields (`.what` / `.why` / `.next` / `.where`)
- The five D-20 subsection titles in source order, plus any additional Claude's-discretion subsections (e.g., "Determinism")
</output>
</content>
</invoke>