# Phase 76: Reference Phoenix App, CI, and Documentation Closure - Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 16 (6 new, 10 modified)
**Analogs found:** 16 / 16 (every touched file has an in-repo analog — this phase is extension + wiring, not invention)

## File Classification

| New/Modified File | New? | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|------|-----------|----------------|---------------|
| `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` | modify | controller | request-response | same file (Invoice/BrandedInvoice actions) | exact (self) |
| `examples/phoenix_example/lib/phoenix_example_web/controllers/error_json.ex` | NEW | controller (error view) | request-response | Phoenix 1.8 ErrorJSON convention (no in-app analog) | role-match (convention) |
| `examples/phoenix_example/lib/phoenix_example_web/router.ex` | modify | route | request-response | same file (`/branded/*` routes) | exact (self) |
| `examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex` | modify | controller (HTML chooser) | request-response | same file (`@chooser_html` `<li>` entries) | exact (self) |
| `examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` | modify | test (ConnCase) | request-response | same file (Invoice/Branded describe blocks) | exact (self) |
| `examples/phoenix_example/mix.exs` | modify | config | n/a | same file (`deps/0`, `project/0`) | exact (self) |
| `examples/phoenix_example/README.md` | NEW | docs | n/a | repo conventions / branding pointer | role-match |
| `.github/workflows/ci.yml` | modify | config (CI) | event-driven | same file (`viewer-evidence-live-proof` job) | exact (self, encoding only) |
| `priv/guardrails/required_status_checks.json` | modify | config (manifest) | n/a | same file (`advisory_contexts[0]` entry) | exact (self) |
| `test/guardrails/required_checks_contract_test.exs` | modify | test (contract) | n/a | same file (advisory describe + lane-count test) | exact (self) |
| `guides/page_primitive.md` | NEW | docs (guide) | n/a | `guides/branding.md` / `guides/viewer_evidence.md` | role-match (tone/fence) |
| `guides/recipes.md` | NEW | docs (guide) | n/a | `guides/branding.md` | role-match (tone/fence) |
| `mix.exs` (root) | modify | config | n/a | same file (`docs/0`) | exact (self) |
| `test/docs_contract/page_primitive_claims_test.exs` | NEW | test (claims) | n/a | `test/docs_contract/viewer_evidence_claims_test.exs` | role-match |
| `test/docs_contract/recipes_claims_test.exs` | NEW | test (claims) | n/a | `test/docs_contract/viewer_evidence_claims_test.exs` | role-match |
| `test/docs_contract/recipes_contract_test.exs` | NEW | test (fence) | n/a | `test/docs_contract/branding_contract_test.exs` | exact (role) |
| `scripts/verify_docs.exs` | modify | config (lane registry) | n/a | same file (`lanes` list) | exact (self) |

---

## Pattern Assignments

### `pdf_controller.ex` (controller, request-response) — D-05/D-06

**Analog:** same file, `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex:1-42`

**Idiom to clone** (an inline `@demo_*` attr + a `_download`/`_preview` action pair; `alias Rendro.Adapters.Phoenix, as: RendroPhoenix` already exists at line 3):
```elixir
# pdf_controller.ex:19-29 (Invoice pair — the exact shape to mirror)
def download(conn, _params) do
  doc = Rendro.Recipes.Invoice.document(@demo_invoice)
  RendroPhoenix.render_pdf(conn, doc, "example.pdf")
end

def preview(conn, _params) do
  doc = Rendro.Recipes.Invoice.document(@demo_invoice)
  RendroPhoenix.preview_pdf(conn, doc)
end
```

**Fixtures to add** (verified Decimal-typed shapes from RESEARCH §"Verified Recipe Data Contracts"; Float raises `ArgumentError`):
```elixir
@demo_statement %{
  period: %{from: ~D[2026-05-01], to: ~D[2026-05-31]},
  account: %{name: "Acme Corp"},
  opening_balance: Decimal.new("1000.00"),
  lines: [
    %{date: ~D[2026-05-02], description: "Invoice #1", amount: Decimal.new("500.00")},
    %{date: ~D[2026-05-15], description: "Payment", amount: Decimal.new("-200.00")}
  ]
}
@demo_receipt %{
  title: "Payment Receipt", date: ~D[2026-05-29],
  customer: %{name: "Acme Corp"},
  lines: [
    %{description: "Widget A", amount: Decimal.new("29.99")},
    %{description: "Widget B", amount: Decimal.new("49.99")}
  ],
  totals: %{subtotal: Decimal.new("79.98"), total: Decimal.new("79.98")}
}
@demo_certificate %{
  title: "Certificate of Completion", recipient: "Jane Smith", date: ~D[2026-05-29],
  body: "For outstanding contribution to deterministic PDF generation.",
  seal_line: "Authorized Signature"
}
```
New actions: `statement_download/2`, `statement_preview/2`, `receipt_download/2`, `receipt_preview/2`, `certificate_download/2`, `certificate_preview/2` — each a 1:1 clone of the Invoice pair with `Rendro.Recipes.{Statement|Receipt|Certificate}.document/1` and filenames `"statement.pdf"` / `"receipt.pdf"` / `"certificate.pdf"`.

---

### `error_json.ex` (NEW — controller/error view, request-response) — D-03

**Analog:** No in-app analog exists (the module is referenced by `config/config.exs:7` `formats: [json: PhoenixExampleWeb.ErrorJSON]` but is missing — load-bearing bug). Use the Phoenix 1.7+/1.8 generator-default `status_message_from_template/1` convention (RESEARCH Pattern 4 / Open Question 1 / Assumption A1).

**Pattern to write:**
```elixir
defmodule PhoenixExampleWeb.ErrorJSON do
  # Renders e.g. "404.json" / "500.json" into a JSON error body.
  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
```
**Validation gate (D-04):** `mix compile --warnings-as-errors` + `mix phx.server` boot + hitting a non-existent route returns the JSON body. Optionally add a tiny ConnCase test asserting the 404 JSON shape (RESEARCH Open Question 1).

---

### `router.ex` (route, request-response) — D-07

**Analog:** same file, `examples/phoenix_example/lib/phoenix_example_web/router.ex:18-25` (the `:api` scope).

**Pattern** — add six routes inside the existing `:api` scope, mirroring `/branded/*` (lines 23-24):
```elixir
# existing precedent:
get "/branded/download", PDFController, :branded_download
get "/branded/preview", PDFController, :branded_preview
# add (D-07):
get "/statement/download", PDFController, :statement_download
get "/statement/preview", PDFController, :statement_preview
get "/receipt/download", PDFController, :receipt_download
get "/receipt/preview", PDFController, :receipt_preview
get "/certificate/download", PDFController, :certificate_download
get "/certificate/preview", PDFController, :certificate_preview
```

---

### `page_controller.ex` (controller / HTML chooser, request-response) — D-07

**Analog:** same file, `examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex:4-22` (the `@chooser_html` heredoc + `<li><a>` list).

**Pattern** — extend the `<ul>` (lines 14-19) with six new `<li>` entries mirroring the existing ones:
```html
<li><a href="/branded/download">Branded invoice with logo + custom font - attachment download</a></li>
<!-- add download + preview <li> per new recipe (Statement, Receipt, Certificate) -->
```
The `index/2` action (lines 24-28) is unchanged — it just `send_resp`s the static HTML.

---

### `pdf_controller_test.exs` (test / ConnCase, request-response) — D-08

**Analog:** same file, `examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs`.

**Three assertion kinds per recipe** (mirror lines 22-68 for Invoice; declare matching `@statement_data` / `@receipt_data` / `@certificate_data` module attrs that equal the controller's `@demo_*`):

1. **HTTP + magic bytes** (clone lines 24-37 / the compact Branded form lines 72-77):
```elixir
test "returns 200 with application/pdf content-type and PDF magic bytes", %{conn: conn} do
  conn = get(conn, "/statement/download")
  assert conn.status == 200
  assert get_resp_header(conn, "content-type") |> hd() =~ "application/pdf"
  assert binary_part(conn.resp_body, 0, 5) == "%PDF-"
end
```

2. **Structural — Statement & Receipt (THREE regions)** (clone lines 44-68):
```elixir
doc = Rendro.Recipes.Statement.document(@statement_data)
assert %Rendro.Document{} = doc
assert doc.page_template == :statement          # :receipt for the receipt block
assert [template] = doc.page_templates
region_names = Enum.map(template.regions, & &1.name)
assert :header in region_names
assert :body in region_names
assert :footer in region_names
assert doc.sections != []
```

3. **Structural — Certificate (SINGLE `:body` region — do NOT copy the 3-region block)** (`certificate.ex:89-100` confirms one region; RESEARCH CRITICAL note + Pitfall 1):
```elixir
doc = Rendro.Recipes.Certificate.document(@certificate_data)
assert %Rendro.Document{} = doc
assert doc.page_template == :certificate
assert [template] = doc.page_templates
assert template.name == :certificate
region_names = Enum.map(template.regions, & &1.name)
assert region_names == [:body]                  # exactly one, body-only
```

> The existing "Source-level check" describe block (lines 98-140) asserts the controller calls `Rendro.Recipes.Invoice.document` and refutes legacy `Rendro.flow([`. Leave it as-is; optionally extend its `assert source =~ ...` lines to cover the three new recipe calls.

---

### `examples/phoenix_example/mix.exs` (config) — D-02

**Analog:** same file, `examples/phoenix_example/mix.exs:8` (`elixir:`) and `:25-33` (`deps/0`).

**Edits** (floor bumps — `mix.lock` already resolves above these floors):
```elixir
# project/0 line 8:  elixir: "~> 1.15"  ->  elixir: "~> 1.19"
# deps/0 lines 27-31:
{:phoenix, "~> 1.8"},   # was ~> 1.7
{:plug, "~> 1.18"},     # was ~> 1.14 (bandit 1.10 floor is 1.18)
{:bandit, "~> 1.0"},    # unchanged
{:jason, "~> 1.4"},     # was ~> 1.2
{:rendro, path: "../.."} # unchanged
```

---

### `examples/phoenix_example/README.md` (NEW — docs) — D-04

**Analog:** repo README/guide tone; no app-local README exists. Document: setup (`cd examples/phoenix_example && mix deps.get`), boot (`mix phx.server`), and one section per demonstrated recipe with its `/download` + `/preview` route. Keep it minimal — the arriving-engineer north star (CONTEXT §specifics). The example app's own test suite may optionally assert README substrings (branding precedent, RESEARCH Open Question 2 — do not over-engineer).

---

### `.github/workflows/ci.yml` (config / CI, event-driven) — D-09/D-10/D-11

**Analog:** same file, `.github/workflows/ci.yml:37-89` (`viewer-evidence-live-proof`) for the **non-required encoding only** (a job simply absent from `required_contexts`). The `test` job header (lines 12-23) is the setup-beam template.

**Edit 1 — remove** the "Verify Phoenix Example" step from the required `test` job (lines 31-35):
```yaml
      - name: Verify Phoenix Example      # DELETE this whole step (D-11)
        run: |
          cd examples/phoenix_example
          mix deps.get
          mix compile
```

**Edit 2 — add** a graph-disconnected advisory job. Clone the setup-beam block (lines 19-23: `otp-version: '28'`, `elixir-version: '1.19.5'`) but **omit `needs:`** (NOT `needs: test` — that is the precedent's wiring and is wrong here per D-09) and **no `continue-on-error`** (D-10):
```yaml
  example-phoenix:
    runs-on: ubuntu-latest
    # no `needs:` -> graph-disconnected (D-09); no continue-on-error (D-10)
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Setup Beam
        uses: erlef/setup-beam@v1
        with:
          otp-version: '28'
          elixir-version: '1.19.5'
      - name: Run example app tests
        working-directory: examples/phoenix_example
        run: |
          mix deps.get
          mix test
```

---

### `priv/guardrails/required_status_checks.json` (config / manifest) — D-12

**Analog:** same file, `advisory_contexts[0]` (`priv/guardrails/required_status_checks.json:40-47`).

**Edit** — append a second entry to `advisory_contexts` (do NOT touch `required_contexts` lines 7-12 or `contexts` lines 13-39 — `additive_only` policy):
```json
{
  "name": "example-phoenix",
  "semantic_class": "example_app",
  "ci_job": "example-phoenix",
  "command": "mix deps.get && mix test",
  "notes": "Phase 76 reference Phoenix app smoke; not required on main per REF-03/D-09."
}
```
(Notes string must contain "not required" and a "REF-03" reference — the contract test asserts both, see next file.)

---

### `test/guardrails/required_checks_contract_test.exs` (test / contract) — D-12 + Pitfalls 2,3,5

**Analog:** same file. Three coupled edits:

1. **Advisory destructure (Pitfall 2)** — `required_checks_contract_test.exs:33` `[advisory] = baseline["advisory_contexts"]` raises `MatchError` with two entries. Refactor to `Enum.find/2` and add an `example-phoenix` assertion:
```elixir
# replace lines 30-37
viewer = Enum.find(baseline["advisory_contexts"], &(&1["name"] == "viewer-evidence-live-proof"))
assert viewer["notes"] =~ "not required"
assert viewer["notes"] =~ "D-32"

example = Enum.find(baseline["advisory_contexts"], &(&1["name"] == "example-phoenix"))
assert example, "example-phoenix advisory context must exist"
assert example["notes"] =~ "not required"
assert example["notes"] =~ "REF-03"
refute "example-phoenix" in baseline["required_contexts"]
```

2. **ci.yml job-name loop (Pitfall 3)** — line 44 iterates `@required_contexts ++ ["viewer-evidence-live-proof"]`. Add `example-phoenix` to the **advisory side** of this list (never `@required_contexts` line 8):
```elixir
for job <- @required_contexts ++ ["viewer-evidence-live-proof", "example-phoenix"] do
  assert ci =~ "  #{job}:"
end
```

3. **Lane-count contract (Pitfall 5)** — line 95 `assert length(lane_entries) == 8`. Bump to `10` after registering the two new lanes in `verify_docs.exs`:
```elixir
assert length(lane_entries) == 10   # was 8 (D-16 adds Recipes + Page-primitive lanes)
```

> Leave the `mix ci` alias assertion (lines 102-118), behavioral-wiring tests (58-88), and fork-safe `refute` block (131-140) untouched.

---

### `guides/page_primitive.md` + `guides/recipes.md` (NEW — docs/guide) — D-13

**Analog:** `guides/branding.md` (tone, structure, fence style) and `guides/viewer_evidence.md`.

**Fence discipline** (RESEARCH Pattern 6; `docs_contract.ex:5-18`):
- Runnable, assertion-bearing snippets use ` ```elixir ` and MUST carry a `# docs-contract: <id>` line — `verified_fences/1` raises otherwise. Example (`branding.md:20-36`):
```elixir
# docs-contract: branding-register-assets
doc =
  Rendro.Document.new()
  |> Rendro.Document.register_embedded_font(:brand_heading, {:path, Rendro.Branded.font_path()})
assert Map.has_key?(doc.font_registry.fonts, :brand_heading)
```
- Illustrative/placeholder snippets use ` ```elixir-schematic ` (silently skipped) — `branding.md:45-53`. Verified fences must be self-contained and free of `...` / `%{...}` (the contract test refutes those).

**Scope bounding** — `recipes.md`'s Invoice/BrandedInvoice section is a **pointer to `guides/branding.md`** (no new claims; the matrix has no `invoice`/`branded_invoice` rows). Document only matrix-backed capabilities: page_numbering ("Page X of Y", first-page suppression), statement/receipt (multi-page table continuation, running footer), certificate (geometry-derived layout, multi-page size). Never claim `full_pdf_compliance` or `digital signatures` (matrix `unsupported` array — claims tests `refute` them).

---

### `mix.exs` (root, config) — D-14

**Analog:** same file, `docs/0` (`mix.exs:93-171`).

**Edits:**
```elixir
# extras: (after line 109 "guides/viewer_evidence.md")
"guides/page_primitive.md",
"guides/recipes.md"

# groups_for_extras: (add a new group, lines 111-120 region)
"Recipes & Primitives": [
  "guides/page_primitive.md",
  "guides/recipes.md"
]

# skip_undefined_reference_warnings_on: (lines 96-102) — add both guide paths IF mix docs warns
"guides/page_primitive.md",
"guides/recipes.md"
```
Validate with `mix docs` (runs inside `mix ci`); prefer fully-qualified real references first (Pitfall 6).

---

### `test/docs_contract/page_primitive_claims_test.exs` + `recipes_claims_test.exs` (NEW — test/claims) — D-16

**Analog:** `test/docs_contract/viewer_evidence_claims_test.exs` (the `File.read!` guide + assert/refute + matrix-lookup + evidence-path pattern).

**Pattern (per D-15, RESEARCH Pattern 7):**
```elixir
guide = File.read!("guides/page_primitive.md")
matrix = Jason.decode!(File.read!("priv/support_matrix.json"))
# (a) backed claim present
assert guide =~ "Page X of Y"
# (b) matrix capability is supported
assert matrix["page_numbering"]["capabilities"]["single_pass_substitution"] == "supported"
assert matrix["page_numbering"]["capabilities"]["deterministic_output"] == "supported"
# (c) out-of-scope claims absent (matrix "unsupported" array: full_pdf_compliance, digital_signatures)
refute guide =~ "digital signatures"
# (d) cited evidence path exists on disk
assert File.exists?(matrix["page_numbering"]["evidence"])  # test/rendro/pipeline/paginate_test.exs
```

**Verified matrix rows + evidence paths to cross-check** (all rows present, evidence files on disk):
| Row | Capabilities (all `"supported"`) | Evidence path |
|-----|----------------------------------|---------------|
| `page_numbering` | `single_pass_substitution`, `deterministic_output`, `suppress_on_first_page` | `test/rendro/pipeline/paginate_test.exs` |
| `statement` | `multi_page_table_continuation`, `running_footer_page_number`, `deterministic_output` | `test/rendro/recipes/statement_test.exs` |
| `receipt_report` | `multi_page_table_continuation`, `running_footer_page_number`, `deterministic_output` | `test/rendro/recipes/receipt_test.exs` |
| `certificate` | `geometry_derived_layout`, `multi_page_size`, `branded_output`, `deterministic_output` | `test/rendro/recipes/certificate_test.exs` |

`page_primitive_claims_test.exs` → `page_numbering` row only. `recipes_claims_test.exs` → `statement` + `receipt_report` + `certificate` rows, each asserting `File.exists?(...evidence...)`.

---

### `test/docs_contract/recipes_contract_test.exs` (NEW — test/fence) — D-16

**Analog:** `test/docs_contract/branding_contract_test.exs` (the full file — fence-ID listing + evaluable/placeholder-free check).

**Pattern** (clone lines 6-26, retargeted at both new guides):
```elixir
alias Rendro.Test.DocsContract

test "guides/recipes.md fences are evaluable and placeholder-free" do
  fences = DocsContract.verified_fences("guides/recipes.md")
  Enum.each(fences, fn %{code: code} ->
    refute String.contains?(code, "...")
    refute String.contains?(code, "%{...}")
    DocsContract.evaluate!(code, "guides/recipes.md")
  end)
end
# repeat for "guides/page_primitive.md"
```
Optionally assert the exact ordered fence-ID list (branding line 9-14) once fence ids are chosen. This test runs in the normal suite (like branding's), NOT as a verify_docs lane (D-16).

---

### `scripts/verify_docs.exs` (config / lane registry) — D-16

**Analog:** same file, the `lanes` list (`scripts/verify_docs.exs:7-16`).

**Edit** — append two **claims** lanes (the fence-contract test is NOT a lane):
```elixir
{"Recipes semantic-claims lane", ["test", "test/docs_contract/recipes_claims_test.exs"]},
{"Page-primitive semantic-claims lane", ["test", "test/docs_contract/page_primitive_claims_test.exs"]}
```
This makes 10 lanes total → the lane-count assertion in `required_checks_contract_test.exs:95` must move `8 → 10` (see that file's edit; coupled). The lane-entry regex `~r/\{"[^"]+", \["test", "test\/docs_contract\/[^"]+"\]\}/` matches this exact tuple shape — keep the formatting identical.

---

## Shared Patterns

### Adapter call (all new controller actions)
**Source:** `lib/rendro/adapters/phoenix.ex:15` (`render_pdf/3`) + `:31` (`preview_pdf/2`); idiom at `pdf_controller.ex:19-29`.
**Apply to:** every new `*_download` (attachment) and `*_preview` (inline) action.
```elixir
RendroPhoenix.render_pdf(conn, doc, "<recipe>.pdf")  # attachment, 200 + application/pdf + %PDF-
RendroPhoenix.preview_pdf(conn, doc)                 # inline,    200 + application/pdf + %PDF-
```
Never hand-roll `Rendro.render` + header juggling; the adapter owns content-type/disposition and `Rendro.Error` handling.

### Document assembly (all new controller actions + structural tests)
**Source:** `lib/rendro/recipes/{statement,receipt,certificate}.ex` `document/2`.
**Apply to:** controllers and the structural test blocks.
```elixir
Rendro.Recipes.Statement.document(@demo_statement)     # %Document{page_template: :statement}
Rendro.Recipes.Receipt.document(@demo_receipt)         # %Document{page_template: :receipt}
Rendro.Recipes.Certificate.document(@demo_certificate) # %Document{page_template: :certificate}
```
Controllers are data-only; recipes own validation (`validate_data!/1`) and layout. All `amount`/balance keys require `%Decimal{}` (Float raises `ArgumentError`).

### Semantic-claims discipline (both new claims tests + both guides)
**Source:** `viewer_evidence_claims_test.exs` + `priv/support_matrix.json` `unsupported: ["full_pdf_compliance", "digital_signatures"]`.
**Apply to:** every claims test and guide prose.
- `assert guide =~ <backed phrase>` AND `assert matrix[row]["capabilities"][cap] == "supported"`.
- `refute guide =~ "digital signatures"` (and avoid full-PDF-compliance language).
- `assert File.exists?(matrix[row]["evidence"])`.

### Fence harness (both new guides + the fence-contract test)
**Source:** `test/support/docs_contract.ex:7-23`.
**Apply to:** every ` ```elixir ` fence in the new guides.
- Verified fences need `# docs-contract: <id>`, must be self-contained + assertion-bearing, and free of `...`/`%{...}`.
- Illustrative code uses ` ```elixir-schematic ` (skipped by `verified_fences/1`).

### Additive-only guardrail discipline (manifest + contract test + CI)
**Source:** `required_status_checks.json:5` `"policy": "additive_only"`.
**Apply to:** all three CI-isolation files.
- New CI signal lands ONLY in `advisory_contexts` / advisory side of test loops; `required_contexts` and `@required_contexts` stay frozen.
- Two hard-coded contract counts drift silently and MUST be updated together: advisory destructure (`[advisory]` → `Enum.find`) and lane count (`8` → `10`).

---

## No Analog Found

| File | Role | Reason | Fallback |
|------|------|--------|----------|
| `examples/phoenix_example/lib/phoenix_example_web/controllers/error_json.ex` | error view | No `ErrorJSON`/`ErrorHTML` module exists in the example app (the app is deliberately generator-free). | Phoenix 1.7+/1.8 generator convention `def render(t,_), do: %{errors: %{detail: Phoenix.Controller.status_message_from_template(t)}}` — RESEARCH Pattern 4 / Assumption A1 (gate-caught by `mix phx.server` boot). |

`examples/phoenix_example/README.md` has no in-repo file analog but inherits root README / guide tone, so it is not a true "no analog" gap.

---

## Metadata

**Analog search scope:** `examples/phoenix_example/{lib,test,config,mix.exs}`, `.github/workflows/`, `priv/guardrails/`, `priv/support_matrix.json`, `test/guardrails/`, `test/docs_contract/`, `test/support/docs_contract.ex`, `scripts/`, root `mix.exs`, `guides/`, `lib/rendro/recipes/certificate.ex`.
**Files read in full for excerpts:** 12 source/test/config files + targeted matrix-row + certificate-region reads.
**Pattern extraction date:** 2026-05-29
