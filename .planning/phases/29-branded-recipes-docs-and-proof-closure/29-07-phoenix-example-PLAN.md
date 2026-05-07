---
phase: 29
plan: 07
type: execute
wave: 3
depends_on: [03]
files_modified:
  - examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex
  - examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex
  - examples/phoenix_example/lib/phoenix_example_web/router.ex
  - examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs
autonomous: true
requirements: [LAY-13]
requirements_addressed: [LAY-13]

must_haves:
  truths:
    - "GET /branded/download endpoint returns 200 + application/pdf content-type with %PDF- magic bytes (D-15)"
    - "GET /branded/preview endpoint returns 200 + inline PDF preview (D-15)"
    - "GET / serves a hardcoded HTML chooser listing all four PDF endpoints with one-line captions; no priv/static, no LiveView, no template directory (D-16)"
    - "PDFController.branded_download/2 and PDFController.branded_preview/2 actions call Rendro.Recipes.BrandedInvoice.document(@demo_branded_invoice) and reuse RendroPhoenix.render_pdf/3 + preview_pdf/2 (D-17)"
    - "@demo_branded_invoice is built from @demo_invoice (Map.put with :brand) — same data feeds both unbranded and branded recipes; example app does NOT vendor or copy font/logo bytes (D-17, D-18)"
    - "Router has a new :browser pipeline accepting [\"html\"] for GET /; existing :api scope retains /download + /preview UNCHANGED and adds /branded/download + /branded/preview (D-15, A4)"
    - "PageController.index/2 uses Plug.Conn.send_resp/3 with @chooser_html heredoc; no Eex template, no view module"
    - "Two new describe blocks in pdf_controller_test.exs: GET /branded/download (200 + %PDF- magic bytes) AND BrandedInvoice recipe structural assertions; existing source-level legacy-Rendro.flow check stays UNCHANGED (D-19)"
    - "BrandedInvoice structural test asserts Map.has_key?(doc.font_registry.fonts, brand.font_name) AND match?(%{source: :embedded}, ...) — Pitfall 6 mitigation, NOT vacuous map_size >= 1"
    - "BrandedInvoice structural test asserts Map.has_key?(doc.asset_registry.assets, brand.logo_name) AND length(template.regions) >= 4 AND :logo in region_names"
  artifacts:
    - path: "examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex"
      provides: "Existing controller + new branded_download/2 and branded_preview/2 actions + @demo_branded_invoice attribute"
      exports: ["download/2", "preview/2", "branded_download/2", "branded_preview/2"]
    - path: "examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex"
      provides: "Hardcoded HTML chooser at GET /"
      exports: ["index/2"]
    - path: "examples/phoenix_example/lib/phoenix_example_web/router.ex"
      provides: "Updated routes: GET / via :browser pipeline; existing /download + /preview unchanged; new /branded/download + /branded/preview via :api"
    - path: "examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs"
      provides: "Two new describe blocks for branded routes + structural assertions"
  key_links:
    - from: "examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex"
      to: "lib/rendro/recipes/branded_invoice.ex (Plan 03)"
      via: "Rendro.Recipes.BrandedInvoice.document(@demo_branded_invoice) calls"
      pattern: "Rendro\\.Recipes\\.BrandedInvoice"
    - from: "examples/phoenix_example/lib/phoenix_example_web/router.ex"
      to: "PageController + PDFController"
      via: "Phoenix routes /, /branded/download, /branded/preview"
      pattern: "get \"/.*\".*Controller"
    - from: "examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs"
      to: "GET /branded/download response"
      via: "conn |> get(\"/branded/download\") + body magic byte assertion"
      pattern: "/branded/(download|preview)"
---

<objective>
Wire the Phoenix example app to demonstrate `Rendro.Recipes.BrandedInvoice` end-to-end (D-15..D-19): two new PDF endpoints (`/branded/download`, `/branded/preview`), a new HTML chooser at `/` listing all four routes (D-16), and matching controller tests asserting on response shape AND document structure (D-19, Pitfall 6).

Per D-18 the example app does NOT vendor font/logo bytes — `BrandedInvoice.document/2` resolves them via `Application.app_dir(:rendro, "priv/branded/...")` internally. Per D-17 the same `@demo_invoice` data feeds both recipes (with `:brand` field added for the branded variant) so the demo shows "same data, two recipes."

This plan implements D-15, D-16, D-17, D-18, D-19 and re-affirms Pitfall 6 (non-vacuous registry assertions) in the controller tests.

Output: 1 new controller (`page_controller.ex`), 3 modified files (existing PDFController, router, controller test), ~80-120 net new LOC across the example app.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/REQUIREMENTS.md
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-CONTEXT.md
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-RESEARCH.md
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-PATTERNS.md
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-VALIDATION.md
@.planning/phases/29-branded-recipes-docs-and-proof-closure/29-03-PLAN.md

# Existing controllers + router (modify these):
@examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex
@examples/phoenix_example/lib/phoenix_example_web/router.ex
@examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs

# Module under test (Plan 03 output):
@lib/rendro/recipes/branded_invoice.ex

# Adapter API:
@lib/rendro/adapters/phoenix.ex
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add branded actions + @demo_branded_invoice to PDFController and create PageController</name>
  <read_first>
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-CONTEXT.md (D-15, D-16, D-17, D-18)
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-RESEARCH.md ("Phoenix chooser controller (D-16)" lines 537-566; A4 line 703)
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-PATTERNS.md (`page_controller.ex` analog lines 596-650; `pdf_controller.ex` MODIFIED analog lines 654-691)
    - examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex (existing controller; mirror branded actions on top)
    - lib/rendro/recipes/branded_invoice.ex (Plan 03 output)
    - lib/rendro/adapters/phoenix.ex (RendroPhoenix.render_pdf/3 + preview_pdf/2 reused)
  </read_first>
  <files>
    - examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex (MODIFIED — add @demo_branded_invoice + branded_download/2 + branded_preview/2)
    - examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex (NEW)
  </files>
  <action>
    **Step 1 — Modify PDFController** (`examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex`):

    Read the existing module first. It looks like (per PATTERNS.md analog):
    ```elixir
    defmodule PhoenixExampleWeb.PDFController do
      use PhoenixExampleWeb, :controller
      alias Rendro.Adapters.Phoenix, as: RendroPhoenix

      @demo_invoice %{
        id: "INV-2026-001",
        date: ~D[2026-04-30],
        items: [
          %{name: "Consulting Services", qty: 10, price: 2_500},
          %{name: "Support Plan", qty: 1, price: 500}
        ]
      }

      def download(conn, _params), do: ...
      def preview(conn, _params), do: ...
    end
    ```

    Add IMMEDIATELY BELOW the existing `@demo_invoice` attribute:
    ```elixir
    @demo_branded_invoice Map.put(@demo_invoice, :brand, %{
      font_name: :brand_heading,
      logo_name: :company_logo
    })
    ```

    Add two new actions IMMEDIATELY BELOW the existing `preview/2` action:
    ```elixir
    def branded_download(conn, _params) do
      doc = Rendro.Recipes.BrandedInvoice.document(@demo_branded_invoice)
      RendroPhoenix.render_pdf(conn, doc, "branded_example.pdf")
    end

    def branded_preview(conn, _params) do
      doc = Rendro.Recipes.BrandedInvoice.document(@demo_branded_invoice)
      RendroPhoenix.preview_pdf(conn, doc)
    end
    ```

    Concrete requirements:
    - DO NOT modify the existing `download/2` or `preview/2` action bodies (D-15 says existing endpoints stay unchanged).
    - DO NOT add `@font_path` or `@logo_path` module attributes; the example app does NOT vendor asset bytes (D-18).
    - The brand atoms MUST be `:brand_heading` and `:company_logo` — these are the canonical logical names used in Plans 03, 04, 05, 06.
    - The new actions reuse the SAME `@demo_invoice` plus `:brand` field (D-17 — "same data, two recipes" demonstration).

    **Step 2 — Create PageController** (`examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex`):

    Author NEW file:
    ```elixir
    defmodule PhoenixExampleWeb.PageController do
      use PhoenixExampleWeb, :controller

      @chooser_html ~S"""
      <!doctype html>
      <html lang="en">
        <head>
          <meta charset="utf-8">
          <title>Rendro Demo</title>
        </head>
        <body>
          <h1>Rendro Demo</h1>
          <p>Choose a PDF to render with Rendro:</p>
          <ul>
            <li><a href="/download">Unbranded invoice — attachment download</a></li>
            <li><a href="/preview">Unbranded invoice — inline preview</a></li>
            <li><a href="/branded/download">Branded invoice (logo + custom font) — attachment download</a></li>
            <li><a href="/branded/preview">Branded invoice (logo + custom font) — inline preview</a></li>
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

    Concrete requirements:
    - File path EXACTLY `examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex`.
    - Module name `PhoenixExampleWeb.PageController`.
    - HTML lives in a single `@chooser_html` heredoc (`~S"""..."""`); no string interpolation needed (the four route paths are static).
    - The HTML lists EXACTLY the four PDF routes (D-16): `/download`, `/preview`, `/branded/download`, `/branded/preview`.
    - Each `<li>` includes a one-line caption per D-16.
    - Per RESEARCH.md Open Question #2 + Claude's discretion: include a one-line "Choose a PDF to render with Rendro" header (cost is one HTML line; benefit is non-zero context for an adopter who lands cold).
    - DO NOT use a Phoenix template directory, EEx, or LiveView (D-16 explicitly forbids).
    - DO NOT add a layout module or use `priv/static` (D-16).

    Verify both:
    ```bash
    cd examples/phoenix_example && mix compile --warnings-as-errors
    ```
  </action>
  <acceptance_criteria>
    - `grep -Eq '^\s*def branded_download\(conn, _params\) do$' examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` exits 0
    - `grep -Eq '^\s*def branded_preview\(conn, _params\) do$' examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` exits 0
    - `grep -Fq 'Rendro.Recipes.BrandedInvoice.document(@demo_branded_invoice)' examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` exits 0
    - `grep -Fq '@demo_branded_invoice' examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` exits 0
    - `grep -Fq 'Map.put(@demo_invoice, :brand,' examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` exits 0
    - `grep -Fq ':brand_heading' examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` exits 0
    - `grep -Fq ':company_logo' examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` exits 0
    - `grep -Fq 'RendroPhoenix.render_pdf(conn, doc, "branded_example.pdf")' examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` exits 0
    - `grep -Fq 'RendroPhoenix.preview_pdf(conn, doc)' examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` exits 0
    - Existing actions preserved: `grep -Eq '^\s*def download\(conn, _params\) do$' examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex && grep -Eq '^\s*def preview\(conn, _params\) do$' examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` exits 0
    - `test -f examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex` exits 0
    - `grep -Eq '^defmodule PhoenixExampleWeb\.PageController do$' examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex` exits 0
    - `grep -Fq '@chooser_html' examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex` exits 0
    - `grep -Fq 'href="/download"' examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex` exits 0
    - `grep -Fq 'href="/preview"' examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex` exits 0
    - `grep -Fq 'href="/branded/download"' examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex` exits 0
    - `grep -Fq 'href="/branded/preview"' examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex` exits 0
    - `grep -Fq 'send_resp(200' examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex` exits 0
    - `grep -Fq 'put_resp_content_type("text/html")' examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex` exits 0
    - Anti-pattern absence: example app does NOT vendor asset bytes — `! find examples/phoenix_example -name '*.ttf' -o -name '*.png' | grep -v 'node_modules\|priv/static\|deps' | grep -q .` (no font/png files committed in the example app outside priv/static if any)
    - `cd examples/phoenix_example && mix compile --warnings-as-errors` exits 0
  </acceptance_criteria>
  <verify>
    <automated>cd examples/phoenix_example && mix compile --warnings-as-errors && grep -Fq 'Rendro.Recipes.BrandedInvoice.document(@demo_branded_invoice)' lib/phoenix_example_web/controllers/pdf_controller.ex && grep -Fq '@demo_branded_invoice' lib/phoenix_example_web/controllers/pdf_controller.ex && test -f lib/phoenix_example_web/controllers/page_controller.ex && grep -Fq 'href="/branded/download"' lib/phoenix_example_web/controllers/page_controller.ex && grep -Fq 'send_resp(200' lib/phoenix_example_web/controllers/page_controller.ex</automated>
  </verify>
  <done>
    PDFController has @demo_branded_invoice (Map.put @demo_invoice :brand) plus branded_download/2 and branded_preview/2 actions reusing RendroPhoenix.render_pdf/preview_pdf. PageController exists with @chooser_html heredoc listing all four PDF routes. Existing PDFController download/2 and preview/2 are unchanged. Example app compiles cleanly with --warnings-as-errors.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Update router with :browser pipeline + new routes; add controller-test describe blocks</name>
  <read_first>
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-CONTEXT.md (D-15, D-16, D-19; Pitfall 6 from RESEARCH.md)
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-PATTERNS.md (`router.ex` MODIFIED analog lines 695-737; `pdf_controller_test.exs` MODIFIED analog lines 741-805)
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-RESEARCH.md (A4 — :browser pipeline addition vs put_resp_content_type alone, line 703)
    - examples/phoenix_example/lib/phoenix_example_web/router.ex (existing — modify)
    - examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs (existing — append two describe blocks)
  </read_first>
  <files>
    - examples/phoenix_example/lib/phoenix_example_web/router.ex (MODIFIED — add :browser pipeline + new routes)
    - examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs (MODIFIED — append 2 describe blocks)
  </files>
  <action>
    **Step 1 — Update router** (`examples/phoenix_example/lib/phoenix_example_web/router.ex`):

    The existing router (per PATTERNS.md analog lines 700-714) looks like:
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

    Update to:
    ```elixir
    defmodule PhoenixExampleWeb.Router do
      use PhoenixExampleWeb, :router

      pipeline :browser do
        plug :accepts, ["html"]
      end

      pipeline :api do
        plug :accepts, ["json"]
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
    end
    ```

    Concrete requirements:
    - The new `:browser` pipeline accepts `["html"]` (per RESEARCH.md A4).
    - The `GET /` route maps to `PageController.index/2` via the new `:browser` pipeline.
    - Existing `/download` and `/preview` routes stay UNCHANGED in the `:api` scope.
    - New `/branded/download` and `/branded/preview` routes go in the SAME `:api` scope (PDF responses, even though PDF isn't strictly JSON; matches existing pattern).

    **Step 2 — Append describe blocks to pdf_controller_test.exs** (`examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs`):

    Add a private fixture `@branded_data` (mirror of existing `@invoice_data` but with `:brand`) at the top of the test module if not already present, then append two describe blocks:

    ```elixir
    # Add at module level (mirror of existing @invoice_data, with :brand added):
    @branded_data Map.put(@invoice_data, :brand, %{
      font_name: :brand_heading,
      logo_name: :company_logo
    })

    describe "GET /branded/download" do
      test "returns 200 with application/pdf content-type", %{conn: conn} do
        conn = get(conn, "/branded/download")
        assert conn.status == 200
        assert get_resp_header(conn, "content-type") |> hd() =~ "application/pdf"
      end

      test "response body begins with PDF magic bytes", %{conn: conn} do
        conn = get(conn, "/branded/download")
        body = conn.resp_body
        assert is_binary(body)
        assert byte_size(body) > 0
        assert binary_part(body, 0, 5) == "%PDF-"
      end
    end

    describe "BrandedInvoice recipe structural assertions" do
      test "document has :branded_invoice page_template with four regions including :logo" do
        doc = Rendro.Recipes.BrandedInvoice.document(@branded_data)

        assert %Rendro.Document{} = doc
        assert doc.page_template == :branded_invoice

        assert [template] = doc.page_templates
        assert template.name == :branded_invoice
        assert length(template.regions) >= 4

        region_names = Enum.map(template.regions, & &1.name)
        assert :logo in region_names
        assert :header in region_names
        assert :body in region_names
        assert :footer in region_names
      end

      test "document has the brand font registered with source: :embedded (Pitfall 6 — non-vacuous)" do
        doc = Rendro.Recipes.BrandedInvoice.document(@branded_data)

        # NOT map_size(...) >= 1 — that's vacuously true (default Helvetica seed).
        assert Map.has_key?(doc.font_registry.fonts, @branded_data.brand.font_name)
        assert match?(%{source: :embedded},
                      doc.font_registry.fonts[@branded_data.brand.font_name])
      end

      test "document has the brand logo registered in asset_registry" do
        doc = Rendro.Recipes.BrandedInvoice.document(@branded_data)
        assert Map.has_key?(doc.asset_registry.assets, @branded_data.brand.logo_name)
      end
    end
    ```

    Concrete requirements:
    - Append (do not overwrite) — existing describe blocks (`GET /download`, `GET /preview`, `Invoice recipe structural assertions`, `Source-level check: controller uses canonical recipe`) stay unchanged (D-19 explicit).
    - The `@branded_data` module attribute is built from `@invoice_data` (same data, +`:brand`) — mirrors D-17.
    - Brand atom values MUST be `:brand_heading` and `:company_logo` (canonical Phase 29 names).
    - Pitfall 6 mitigation: brand-font registry check uses `Map.has_key?/2` + `match?(%{source: :embedded}, ...)`, NEVER `map_size(...) >= 1`.
    - Asset-registry check uses `Map.has_key?/2` (asset_registry starts empty per Phase 28, so `map_size >= 1` would also be valid here — but use `Map.has_key?` for consistency and explicit-naming clarity).
    - DO NOT modify the existing source-level legacy-`Rendro.flow` check describe block (D-19).

    Verify:
    ```bash
    cd examples/phoenix_example && mix test
    ```
  </action>
  <acceptance_criteria>
    - `grep -Eq 'pipeline :browser do' examples/phoenix_example/lib/phoenix_example_web/router.ex` exits 0
    - `grep -Fq 'plug :accepts, ["html"]' examples/phoenix_example/lib/phoenix_example_web/router.ex` exits 0
    - `grep -Fq 'get "/", PageController, :index' examples/phoenix_example/lib/phoenix_example_web/router.ex` exits 0
    - `grep -Fq 'get "/branded/download", PDFController, :branded_download' examples/phoenix_example/lib/phoenix_example_web/router.ex` exits 0
    - `grep -Fq 'get "/branded/preview", PDFController, :branded_preview' examples/phoenix_example/lib/phoenix_example_web/router.ex` exits 0
    - Existing routes preserved: `grep -Fq 'get "/download", PDFController, :download' examples/phoenix_example/lib/phoenix_example_web/router.ex && grep -Fq 'get "/preview", PDFController, :preview' examples/phoenix_example/lib/phoenix_example_web/router.ex` exits 0
    - `grep -cE 'describe "(GET /branded/download|BrandedInvoice recipe structural assertions)"' examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` outputs `2`
    - `grep -Fq '@branded_data' examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` exits 0
    - `grep -Fq 'Map.has_key?(doc.font_registry.fonts' examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` exits 0
    - `grep -Fq 'source: :embedded' examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` exits 0
    - `grep -Fq '/branded/download' examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` exits 0
    - `grep -Fq '"%PDF-"' examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` exits 0
    - Existing describe blocks preserved: `grep -cE 'describe "(GET /download|GET /preview|Invoice recipe|Source-level check)' examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` outputs at least `4`
    - Anti-pattern absence: `! grep -Fq 'map_size(doc.font_registry.fonts) >= 1' examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` (Pitfall 6)
    - `cd examples/phoenix_example && mix compile --warnings-as-errors` exits 0
    - `cd examples/phoenix_example && mix test` exits 0 (all describe blocks pass: existing + 2 new)
  </acceptance_criteria>
  <verify>
    <automated>cd examples/phoenix_example && mix compile --warnings-as-errors && grep -Eq 'pipeline :browser do' lib/phoenix_example_web/router.ex && grep -Fq 'get "/", PageController, :index' lib/phoenix_example_web/router.ex && grep -Fq 'get "/branded/download", PDFController, :branded_download' lib/phoenix_example_web/router.ex && [ "$(grep -cE 'describe "(GET /branded/download|BrandedInvoice recipe structural assertions)"' test/phoenix_example_web/controllers/pdf_controller_test.exs)" = "2" ] && grep -Fq 'source: :embedded' test/phoenix_example_web/controllers/pdf_controller_test.exs && ! grep -Fq 'map_size(doc.font_registry.fonts) >= 1' test/phoenix_example_web/controllers/pdf_controller_test.exs && mix test</automated>
  </verify>
  <done>
    Router has new :browser pipeline + GET / route via PageController; existing :api scope retains /download + /preview unchanged AND adds /branded/download + /branded/preview. pdf_controller_test.exs has @branded_data + two new describe blocks (GET /branded/download with 200/%PDF-/content-type assertions + BrandedInvoice structural assertions with non-vacuous Pitfall-6 registry check). Existing source-level legacy-Rendro.flow check unchanged. Example app compiles + all tests pass.
  </done>
</task>

</tasks>

<verification>
- `cd examples/phoenix_example && mix compile --warnings-as-errors` exits 0
- `cd examples/phoenix_example && mix test` exits 0 with all describe blocks passing
- Routes: `mix phx.routes 2>/dev/null` (or read router.ex directly) shows `/`, `/download`, `/preview`, `/branded/download`, `/branded/preview` (5 routes total).
- The example app's router has both `:browser` and `:api` pipelines; `:browser` only carries `GET /`.
- The example app's PDFController has 4 actions: `download/2`, `preview/2`, `branded_download/2`, `branded_preview/2`.
- The example app does NOT contain font or PNG bytes vendored from `priv/branded/` (D-18 — assets resolve via `Application.app_dir(:rendro, ...)` from the dep).
- Pitfall 6 mitigation enforced via grep gate (no `map_size >= 1` patterns).
</verification>

<success_criteria>
- All four PDF endpoints respond with `%PDF-` magic bytes and `application/pdf` content-type (the two existing + two new).
- The chooser HTML at `GET /` lists all four PDF routes with one-line captions (D-16).
- `BrandedInvoice.document(@demo_branded_invoice)` is the demonstrated wiring (D-17, D-18 — example app does not vendor bytes; resolution flows through `Application.app_dir(:rendro, ...)`).
- Controller test asserts both response shape (200 + magic bytes) AND document shape (page_template name, region count, brand font with source: :embedded, logo registration) per D-19.
- Pitfall 6 mitigation enforced — no vacuous `map_size >= 1` registry assertions.
- Existing source-level legacy-`Rendro.flow` test untouched (D-19 explicit).
</success_criteria>

<output>
After completion, create `.planning/phases/29-branded-recipes-docs-and-proof-closure/29-07-SUMMARY.md` documenting:
- Net diff size per modified file (LOC added/removed)
- Final number of describe blocks in pdf_controller_test.exs (target: existing 4 + 2 new = 6)
- Pass/fail count per `cd examples/phoenix_example && mix test`
- Confirmation that the example app does NOT vendor `:rendro` asset bytes (no .ttf/.png files outside dep tree)
- The exact route table from router.ex (5 routes: /, /download, /preview, /branded/download, /branded/preview)
</output>
</content>
</invoke>