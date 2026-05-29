# Phase 76: Reference Phoenix App, CI, and Documentation Closure - Research

**Researched:** 2026-05-29
**Domain:** Elixir / Phoenix reference app modernization, GitHub Actions CI isolation, ExDoc guides + in-repo docs-contract enforcement
**Confidence:** HIGH (all findings code-grounded against the live repository at HEAD; no external dependency discovery required)

## Summary

Phase 76 is an **adoption-closure** phase with zero new engine capability and zero new runtime dependencies. Every decision (D-01..D-16) in `76-CONTEXT.md` was verified against source and is accurate. The work splits cleanly into four independent surfaces: (1) modernize the existing hand-rolled minimal Phoenix example in place, (2) demonstrate three more recipes through the existing adapter/controller idiom, (3) add a graph-disconnected advisory CI job + update the in-repo guardrail manifest, and (4) author two HexDocs guides bounded by the two existing docs-contract harnesses.

The single highest-value verification result: **the recipe `page_template` atoms and `document/2` data-map shapes are now confirmed exactly from source**, and the Certificate recipe has a **body-only template (no `:header`/`:footer` regions)** — so its structural test must differ from Statement/Receipt (which have all three). The adapter API names in CONTEXT (`render_pdf/3`, `preview_pdf/2`) are correct. The guardrail contract test's single-element advisory destructure (`[advisory] = ...`) is confirmed present and will break with a second advisory entry. The docs-contract fence harness only verifies fences tagged exactly ` ```elixir ` — `elixir-schematic` fences are intentionally excluded, which is the mechanism for showing illustrative-but-not-executed code.

**Primary recommendation:** Treat this phase as four parallelizable workstreams (app, CI, guides, docs-tests). Author correct fixtures and structural assertions directly from the verified data contracts and `page_template` atoms in this document; do not regenerate the Phoenix app; copy the existing controller/test/guide idioms verbatim and extend.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Recipe → `%Document{}` assembly | Library (`Rendro.Recipes.*`) | — | Recipes own data validation + layout; controller only supplies data |
| PDF byte rendering | Library (`Rendro.render/1`) | — | Engine owns rendering; never re-implemented in the example |
| HTTP response (attachment/inline) | Adapter (`Rendro.Adapters.Phoenix`) | API controller | Adapter sets content-type/disposition; controller just calls it |
| Sample data | API controller (module attributes) | — | D-06: inline `@demo_*` attributes, no shared SampleData module |
| Route wiring | Frontend server (Phoenix router `:api` scope) | — | Mirrors existing `/branded/*` routes |
| CI exercise of the example | CI (GitHub Actions `example-phoenix` job) | — | Graph-disconnected advisory job; no tier coupling |
| Required-vs-advisory check policy | Repo manifest (`priv/guardrails/...json`) + contract test | — | In-repo source of truth; live branch-protection managed externally |
| Guide ↔ claim bounding | Test tier (`test/docs_contract/*`) | Docs (`guides/*.md`) | Tests bound prose to `priv/support_matrix.json` + proof lanes |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REF-01 | `examples/phoenix_example` is `mix`-runnable with a README + non-stale dep constraints (Phoenix `~> 1.8`, Jason `~> 1.4`, Elixir `~> 1.19`) | Verified current `mix.exs` constraints and `mix.lock` resolutions (Phoenix 1.8.5, jason 1.4.4, plug 1.19.1, bandit 1.10.4). Confirmed missing `PhoenixExampleWeb.ErrorJSON` (load-bearing bug, D-03). Validation: `mix deps.get && mix compile --warnings-as-errors && mix phx.server` boot. |
| REF-02 | Reference app demonstrates all five recipes through `Rendro.Adapters.Phoenix` | Adapter API confirmed: `render_pdf/3` (attachment, default `"document.pdf"`), `preview_pdf/2` (inline). Existing Invoice/BrandedInvoice controller actions are the idiom to clone. Three new recipes' `document/2` shapes + `page_template` atoms verified from source. |
| REF-03 | Isolated `example-phoenix` CI job runs `mix test`; not required; never blocks engine lanes | Full `ci.yml` job graph read; "Verify Phoenix Example" step (lines 31-35) confirmed for removal; `viewer-evidence-live-proof` advisory precedent located; `required_status_checks.json` + contract test exact shape captured. |
| CONTRACT-02 | PAGE primitive + each recipe documented in HexDocs guides; docs-contract tests reject out-of-matrix claims | Both harnesses verified: `Rendro.Test.DocsContract.verified_fences/1` + `evaluate!/2` (fence harness), and `*_claims_test.exs` semantic-claims pattern. Support-matrix rows (`page_numbering`, `statement`, `receipt_report`, `certificate`) + `unsupported` array captured exactly. `mix.exs docs/0` extras/groups read. `verify_docs.exs` lane format captured. |
</phase_requirements>

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Phoenix Reference-App Modernization Strategy**
- **D-01:** Upgrade the existing scaffold **in place** — do NOT regenerate with `mix phx.new`. The app is a hand-rolled minimal Phoenix 1.8-line app (its `mix.lock` resolves Phoenix 1.8.5 / jason 1.4.4 / plug 1.19.1) with deliberately zero generator boilerplate (no Ecto/assets/LiveView/daisyUI/gettext). Regeneration would re-add the boilerplate the app was built to omit and force re-porting all recipe controllers.
- **D-02:** Final dep constraints for `examples/phoenix_example/mix.exs`: `{:phoenix, "~> 1.8"}`, `{:jason, "~> 1.4"}`, `{:plug, "~> 1.18"}` (bandit 1.10 already requires `~> 1.18`; current `~> 1.14` is misleadingly low), `{:bandit, "~> 1.0"}`, `{:rendro, path: "../.."}`. Set `elixir: "~> 1.19"` to match the root library.
- **D-03:** **Load-bearing bug fix:** `config/config.exs` references `PhoenixExampleWeb.ErrorJSON` (render_errors handler) but no such module exists. Add a minimal `lib/phoenix_example_web/controllers/error_json.ex` so render-error handling is not broken.
- **D-04:** Verification gate after edits: `mix deps.get && mix compile --warnings-as-errors && mix phx.server` to confirm REF-01 `mix`-runnable + clean re-lock. Author the README documenting setup + each demonstrated recipe.

**Recipe Demonstration Surface**
- **D-05:** Extend the **existing plain dead-controller pattern** — do NOT introduce LiveView or a shared SampleData module. Add one `download` + one `preview` action per new recipe (Statement, Receipt, Certificate) on `PDFController`, mirroring the shipped Invoice/BrandedInvoice surface that already calls `render_pdf/3` (attachment) and `preview_pdf/2` (inline).
- **D-06:** Sample data lives as **inline module attributes** on `PDFController` (consistent with current `@demo_invoice`/`@demo_branded_invoice`). Fixture shapes (confirm against recipe moduledocs during planning): Statement `%{period: %{from,to}, account: %{name}, opening_balance: Decimal, lines: [%{date, description, amount(Decimal)}]}`; Receipt `%{title, date, customer: %{name}, lines: [%{description, amount(Decimal)}], totals?: %{subtotal, total}}`; Certificate `%{title, recipient, date, body?, seal_line?}` (landscape A4 default; no brand for base demo).
- **D-07:** Index page (`page_controller.ex`) gains download + preview links per new recipe. Routes mirror existing `/branded/*` in the `:api` scope: `/statement/{download,preview}`, `/receipt/{download,preview}`, `/certificate/{download,preview}`.
- **D-08:** Per-recipe `mix test` assertions (mirror existing Invoice/Branded tests): `status == 200`; `content-type =~ "application/pdf"`; `binary_part(resp_body, 0, 5) == "%PDF-"`; plus one structural assertion re-running `document/2` and asserting `%Rendro.Document{}` with the recipe's expected `page_template` atom + non-empty sections (confirm each atom against source before writing).

**CI Isolation Mechanism**
- **D-09:** New `example-phoenix` job uses `needs: []` (**fully independent**, not `needs: test`). Graph-disconnected so it can neither gate nor be gated by `test` / `signing-live-proof` / `long-lived-live-proof` / `release-proof`, and always produces its own visible green/red signal.
- **D-10:** Job runs `working-directory: examples/phoenix_example` → `mix deps.get && mix test`, with `otp-version: '28'` / `elixir-version: '1.19.5'` matching the other jobs. **No `continue-on-error`** — REF-03 wants failure visible-but-non-blocking, and `continue-on-error` would mask red as green.
- **D-11:** **Remove** the now-redundant "Verify Phoenix Example" step (≈lines 31-35) from the required `test` job so Phoenix deps no longer run inside a required lane.
- **D-12:** Record non-required status in `priv/guardrails/required_status_checks.json` by adding `example-phoenix` to `advisory_contexts` (do NOT touch `required_contexts`/`contexts`). Update `test/guardrails/required_checks_contract_test.exs`: it currently destructures a single-element advisory list (`[advisory] = ...`) which breaks with two entries — switch to an `Enum.find/2` lookup and add an assertion that the `example-phoenix` advisory entry exists (notes reference "not required" / "REF-03") and is absent from `required_contexts`. No live GitHub branch-protection change is encoded in-repo.

**Guides + Docs-Contract Enforcement**
- **D-13:** Author **two** new guides (not six): `guides/page_primitive.md` (PAGE primitive) and a consolidated `guides/recipes.md` (one `##` section per canonical recipe). The support matrix has exactly four new surface rows (`page_numbering`, `statement`, `receipt_report`, `certificate`) and NO separate `invoice`/`branded_invoice` rows — so the recipes guide's Invoice/BrandedInvoice section is a **pointer to `guides/branding.md`** (no new claims).
- **D-14:** Wire both guides into root `mix.exs` `docs/0` `extras:` (after `guides/viewer_evidence.md`) and add a `groups_for_extras:` group `"Recipes & Primitives": ["guides/page_primitive.md", "guides/recipes.md"]`. Add to `skip_undefined_reference_warnings_on:` if needed.
- **D-15:** Reuse the project's **two existing harnesses, invent nothing new.** (1) Runnable API examples → tag elixir fences `# docs-contract: <id>` and verify via `Rendro.Test.DocsContract.verified_fences/1` + `evaluate!/2`. (2) Capability/scope claims → `*_claims_test.exs` that `File.read!` the guide, `assert guide =~ <backed phrase>` AND asserts the matching `priv/support_matrix.json` capability is `"supported"`, and `refute guide =~ <out-of-scope phrase>` for entries in the matrix `"unsupported"` array (`full_pdf_compliance`, `digital_signatures`). (3) Proof-lane linkage → assert each cited row's `evidence:` path exists on disk.
- **D-16:** New test files (3): `test/docs_contract/page_primitive_claims_test.exs` (cross-checks `page_numbering` row), `test/docs_contract/recipes_claims_test.exs` (cross-checks `statement`/`receipt_report`/`certificate` rows + asserts each row's evidence path exists), `test/docs_contract/recipes_contract_test.exs` (fence verification over both guides, mirroring `branding_contract_test.exs`). Register two semantic-claims lanes in `scripts/verify_docs.exs` (Recipes + Page-primitive); the fence-contract test runs in the normal suite like branding's does.

### Claude's Discretion
- README prose/structure, exact guide wording and example selection, fixture sample values, and `docs-contract` fence ids — all left to planning/execution, constrained by the decisions above and the existing guides' tone.

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed within phase scope. (The missing `PhoenixExampleWeb.ErrorJSON` module was captured as D-03, not deferred, since it blocks REF-01.)
- From REQUIREMENTS "Out of Scope": no new engine capabilities, no new recipes, no changes to engine-critical proof lanes, no making the example CI job a required branch-protection check.
</user_constraints>

## Standard Stack

No new dependencies. The phase reuses the in-repo and example-app stacks verbatim.

### Reference-app dependencies (verified versions)
| Library | Current constraint | Target constraint (D-02) | Lock-resolved version `[VERIFIED: mix.lock]` |
|---------|--------------------|--------------------------|----------------------------------------------|
| phoenix | `~> 1.7` | `~> 1.8` | 1.8.5 |
| jason | `~> 1.2` | `~> 1.4` | 1.4.4 |
| plug | `~> 1.14` | `~> 1.18` | 1.19.1 |
| bandit | `~> 1.0` | `~> 1.0` (unchanged) | 1.10.4 (requires `plug ~> 1.18`) |
| rendro | `path: "../.."` | `path: "../.."` (unchanged) | local path |
| elixir (project) | `~> 1.15` | `~> 1.19` | toolchain Elixir 1.19.5 / OTP 28 |

**Why bump plug to `~> 1.18`:** `mix.lock` shows `bandit 1.10.4` already declares `{:plug, "~> 1.18"}`, and `plug 1.19.1` is resolved. The current `~> 1.14` constraint is misleadingly low — the real floor is 1.18. `[VERIFIED: examples/phoenix_example/mix.lock line 2, 11]`

### Recipe / adapter surface (verified from source)
| Module | Function | Arity | Return / behavior | Source |
|--------|----------|-------|-------------------|--------|
| `Rendro.Adapters.Phoenix` | `render_pdf/3` | `(conn, doc, filename \\ "document.pdf")` | 200 + `content-type: application/pdf` + `content-disposition: attachment; filename="..."` + `%PDF-` body | `lib/rendro/adapters/phoenix.ex:15` |
| `Rendro.Adapters.Phoenix` | `preview_pdf/2` | `(conn, doc)` | 200 + `application/pdf` + `content-disposition: inline` + `%PDF-` body | `lib/rendro/adapters/phoenix.ex:31` |
| `Rendro.Recipes.Statement` | `document/2` | `(data, opts \\ [])` | `%Rendro.Document{page_template: :statement}` | `lib/rendro/recipes/statement.ex:231` |
| `Rendro.Recipes.Receipt` | `document/2` | `(data, opts \\ [])` | `%Rendro.Document{page_template: :receipt}` | `lib/rendro/recipes/receipt.ex:227` |
| `Rendro.Recipes.Certificate` | `document/2` | `(data, opts \\ [])` | `%Rendro.Document{page_template: :certificate}` | `lib/rendro/recipes/certificate.ex:140` |
| `Rendro.Recipes.Invoice` | `document/1,2` | — | `page_template: :invoice` (3 regions: header/body/footer) | `lib/rendro/recipes/invoice.ex` |
| `Rendro.Recipes.BrandedInvoice` | `document/1,2` | — | `page_template: :branded_invoice` (regions incl. `:logo`, `>= 4`) | `lib/rendro/recipes/branded_invoice.ex:50` |

**Installation:** No `npm`/`pip`/`cargo`. App-side: `cd examples/phoenix_example && mix deps.get`.

## Package Legitimacy Audit

No external packages are added by this phase. All dependencies (`phoenix`, `jason`, `plug`, `bandit`, `rendro`) are already resolved in `examples/phoenix_example/mix.lock` and are mature, high-trust Hex packages (Phoenix core, Plug core, Jason, Bandit). The only constraint changes are version-floor bumps to already-installed packages. **No legitimacy gate required.**

| Package | Registry | Source Repo | Disposition |
|---------|----------|-------------|-------------|
| phoenix | Hex | phoenixframework/phoenix | Already present; floor bump `~>1.7`→`~>1.8` |
| jason | Hex | michalmuskala/jason | Already present; floor bump `~>1.2`→`~>1.4` |
| plug | Hex | elixir-plug/plug | Already present; floor bump `~>1.14`→`~>1.18` |
| bandit | Hex | mtrudel/bandit | Already present; unchanged |
| rendro | local path | this repo | Unchanged |

## Verified Recipe Data Contracts (for D-06 fixtures + D-08 tests)

### Statement (`page_template == :statement`; 3 regions: header/body/footer)
Required keys (validated in `validate_data!/1`, `statement.ex:443-471`):
- `:period` — `%{from: Date.t(), to: Date.t()}` (both must be `%Date{}`)
- `:account` — `%{name: String.t()}`
- `:opening_balance` — **`Decimal.t()`** (Float raises an instructive `ArgumentError`)
- `:lines` — `[%{date: Date.t(), description: String.t(), amount: Decimal.t()}]`

Forbidden: a per-line `:balance` key raises (recipe computes it). Optional: `:closing_balance` (Decimal, validated against the fold), `:summary`.

Verified fixture (correct, copy-ready):
```elixir
%{
  period: %{from: ~D[2026-05-01], to: ~D[2026-05-31]},
  account: %{name: "Acme Corp"},
  opening_balance: Decimal.new("1000.00"),
  lines: [
    %{date: ~D[2026-05-02], description: "Invoice #1", amount: Decimal.new("500.00")},
    %{date: ~D[2026-05-15], description: "Payment",   amount: Decimal.new("-200.00")}
  ]
}
```

### Receipt (`page_template == :receipt`; 3 regions: header/body/footer)
Required keys (`receipt.ex:380-398`):
- `:title` — `String.t()`
- `:date` — `Date.t()`
- `:customer` — `%{name: String.t()}`
- `:lines` — `[%{description: String.t(), amount: Decimal.t()}]` (Decimal required, Float raises)

Optional: `:totals` — `%{subtotal: Decimal, total: Decimal, tax?: Decimal, discount?: Decimal}`; when present, `subtotal` is validated against the sum of line amounts and `total` against `subtotal + tax - discount` (so supply consistent values or omit).

Verified fixture:
```elixir
%{
  title: "Payment Receipt",
  date: ~D[2026-05-29],
  customer: %{name: "Acme Corp"},
  lines: [
    %{description: "Widget A", amount: Decimal.new("29.99")},
    %{description: "Widget B", amount: Decimal.new("49.99")}
  ],
  totals: %{subtotal: Decimal.new("79.98"), total: Decimal.new("79.98")}
}
```

### Certificate (`page_template == :certificate`; **ONLY 1 region: `:body`**)
Required keys (`certificate.ex:200-238`):
- `:title` — `String.t()`
- `:recipient` — `String.t()`
- `:date` — `Date.t()`

Optional: `:body` (string, default `""`, **must be ≤ 2000 bytes** or raises), `:seal_line` (string, default `""`), `:brand` (`%{font_name: atom(), logo_name: atom()}`). Default orientation is **landscape A4**; base demo per D-06 uses **no brand**.

Verified fixture:
```elixir
%{
  title: "Certificate of Completion",
  recipient: "Jane Smith",
  date: ~D[2026-05-29],
  body: "For outstanding contribution to deterministic PDF generation.",
  seal_line: "Authorized Signature"
}
```

> **CRITICAL for D-08 test authoring:** Certificate's `page_template/1` builds **a single `:body` region** (`certificate.ex:89-100`) — NOT header/body/footer. The Statement/Receipt structural test asserts three regions `[:header, :body, :footer]`; the Certificate structural test must instead assert exactly one `:body` region. Reusing the Statement assertion verbatim for Certificate will fail.

## Architecture Patterns

### System Architecture Diagram

```
                         examples/phoenix_example  (mix-runnable, in-place upgrade)
HTTP GET /statement/download
        │
        ▼
   Router (:api scope) ──► PDFController.statement_download/2
                                   │  reads @demo_statement (inline module attr, D-06)
                                   ▼
                        Rendro.Recipes.Statement.document(@demo_statement)
                                   │  returns %Rendro.Document{page_template: :statement}
                                   ▼
                        Rendro.Adapters.Phoenix.render_pdf(conn, doc, "statement.pdf")
                                   │  calls Rendro.render(doc) ──► {:ok, pdf_binary}
                                   ▼
                  conn 200 · content-type application/pdf · disposition attachment · "%PDF-" body
   (preview action identical but → preview_pdf/2 → disposition: inline)

   PageController.index/2 ──► static HTML chooser listing all download/preview links (D-07)

  ────────────────────────────────────────────────────────────────────────────────────
   CI (.github/workflows/ci.yml)
     test ──needs──► signing-live-proof, long-lived-live-proof, release-proof, viewer-evidence-live-proof
     example-phoenix  (needs: []  ── graph-disconnected; gates nothing, gated by nothing; D-09)
                          working-directory: examples/phoenix_example → mix deps.get && mix test

  ────────────────────────────────────────────────────────────────────────────────────
   Docs (HexDocs)
     mix.exs docs/0 extras ──► guides/page_primitive.md, guides/recipes.md  (group "Recipes & Primitives")
                                   ▲                                ▲
   test/docs_contract/page_primitive_claims_test.exs    recipes_claims_test.exs / recipes_contract_test.exs
        cross-check priv/support_matrix.json rows + evidence: paths on disk + fence eval
```

### Pattern 1: Controller action pair per recipe (clone the Invoice idiom)
**What:** For each new recipe add two thin actions on `PDFController` reading an inline `@demo_*` attribute.
**Source:** `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex:19-41`
```elixir
@demo_statement %{ # ...verified fixture above... }

def statement_download(conn, _params) do
  doc = Rendro.Recipes.Statement.document(@demo_statement)
  RendroPhoenix.render_pdf(conn, doc, "statement.pdf")
end

def statement_preview(conn, _params) do
  doc = Rendro.Recipes.Statement.document(@demo_statement)
  RendroPhoenix.preview_pdf(conn, doc)
end
```
(`alias Rendro.Adapters.Phoenix, as: RendroPhoenix` is already at the top of the controller.)

### Pattern 2: Router — extend the `:api` scope (D-07)
**Source:** `router.ex:18-25`. Add inside the existing `:api` scope, mirroring `/branded/*`:
```elixir
get "/statement/download", PDFController, :statement_download
get "/statement/preview", PDFController, :statement_preview
get "/receipt/download", PDFController, :receipt_download
get "/receipt/preview", PDFController, :receipt_preview
get "/certificate/download", PDFController, :certificate_download
get "/certificate/preview", PDFController, :certificate_preview
```

### Pattern 3: ConnCase test triplet per recipe (D-08)
**Source:** `test/phoenix_example_web/controllers/pdf_controller_test.exs`. Three assertion kinds per recipe, mirroring the existing Invoice block:
1. HTTP: `get(conn, "/statement/download")` → `conn.status == 200` and `get_resp_header(conn, "content-type") |> hd() =~ "application/pdf"`.
2. Magic bytes: `binary_part(conn.resp_body, 0, 5) == "%PDF-"`.
3. Structural: re-run `document/2` on the same fixture, assert `%Rendro.Document{}` and `doc.page_template == :statement|:receipt|:certificate`, and assert the region set. **Statement/Receipt:** `[:header, :body, :footer]`. **Certificate:** single `:body` region only (see CRITICAL note above).

### Pattern 4: Minimal `ErrorJSON` module (D-03 — load-bearing fix)
`config/config.exs:8` registers `formats: [json: PhoenixExampleWeb.ErrorJSON]` but the module does not exist (confirmed: not in the file tree). Phoenix 1.8 error views expose `template/2`-style functions or a `render/2`. Add a minimal module under `lib/phoenix_example_web/controllers/error_json.ex` returning a JSON map keyed by status (e.g. `Phoenix.Controller.status_message_from_template/1`). The README boot gate (`mix phx.server`) plus a 404/500 path is the validation.

### Pattern 5: Advisory CI job (clone non-required encoding from `viewer-evidence-live-proof`, but `needs: []`)
**Source:** `ci.yml:37-89` for the non-required *encoding* (a job that is simply not listed in `required_contexts`). **Do NOT copy its `needs: test`** — D-09 mandates `needs: []` so the example signal is never suppressed when engine `test` is red.
```yaml
  example-phoenix:
    runs-on: ubuntu-latest
    # no `needs:` → graph-disconnected
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          otp-version: '28'
          elixir-version: '1.19.5'
      - name: Run example app tests
        working-directory: examples/phoenix_example
        run: |
          mix deps.get
          mix test
```
No `continue-on-error` (D-10). Remove the `test` job's "Verify Phoenix Example" step at `ci.yml:31-35` (D-11).

### Pattern 6: Docs-contract fence harness — only ` ```elixir ` fences are verified
**Source:** `test/support/docs_contract.ex:5-18`. The fence regex captures any `[[:alnum:]_-]+` language tag, but `verified_fences/1` **filters `lang == "elixir"`**. Every captured elixir fence MUST contain a `# docs-contract: <id>` line or `verified_fences/1` raises. Fences with placeholder `...` or illustrative-only code use the ` ```elixir-schematic ` tag (see `guides/branding.md:45`) and are silently skipped. `evaluate!/2` wraps code with `import ExUnit.Assertions` and runs `Code.eval_string`, so each verified fence must be a self-contained, assertion-bearing snippet free of `...`/`%{...}` placeholders (`branding_contract_test.exs:22-25` refutes those).

### Pattern 7: Semantic-claims test (bound prose to matrix + proof)
**Source:** `viewer_evidence_claims_test.exs`, `integrations_claims_test.exs`, `branding_claims_test.exs`. Pattern per D-15:
```elixir
guide = File.read!("guides/recipes.md")
matrix = Jason.decode!(File.read!("priv/support_matrix.json"))
# (a) backed claim present
assert guide =~ "Page X of Y"
# (b) matrix capability is supported
assert matrix["statement"]["capabilities"]["running_footer_page_number"] == "supported"
# (c) out-of-scope claims absent (matrix "unsupported" array)
refute guide =~ "digital signatures"   # full_pdf_compliance, digital_signatures
# (d) cited evidence path exists on disk
assert File.exists?(matrix["statement"]["evidence"])
```

### Recommended file structure (what this phase touches)
```
examples/phoenix_example/
├── mix.exs                                              # D-02 dep bumps
├── README.md                                            # NEW (D-04)
├── config/config.exs                                    # unchanged (already references ErrorJSON)
├── lib/phoenix_example_web/
│   ├── controllers/pdf_controller.ex                    # +6 actions, +3 @demo_* attrs (D-05/06)
│   ├── controllers/error_json.ex                        # NEW (D-03)
│   ├── controllers/page_controller.ex                   # +6 chooser links (D-07)
│   └── router.ex                                        # +6 routes (D-07)
└── test/phoenix_example_web/controllers/pdf_controller_test.exs   # +3 recipe blocks (D-08)

.github/workflows/ci.yml                                 # remove step (D-11), add example-phoenix job (D-09/10)
priv/guardrails/required_status_checks.json              # +advisory_contexts entry (D-12)
test/guardrails/required_checks_contract_test.exs        # refactor [advisory]→Enum.find + new assert (D-12)

guides/page_primitive.md                                 # NEW (D-13)
guides/recipes.md                                        # NEW (D-13)
mix.exs                                                  # docs extras + groups_for_extras (D-14)
test/docs_contract/page_primitive_claims_test.exs        # NEW (D-16)
test/docs_contract/recipes_claims_test.exs               # NEW (D-16)
test/docs_contract/recipes_contract_test.exs             # NEW (D-16)
scripts/verify_docs.exs                                  # +2 lanes (D-16)
```

### Anti-Patterns to Avoid
- **Regenerating the app with `mix phx.new`** (D-01) — re-adds omitted boilerplate, breaks the minimal intent.
- **Adding `needs: test` to `example-phoenix`** — suppresses the example signal when engine `test` is red (D-09). Copy the precedent's non-required *encoding*, not its `needs`.
- **`continue-on-error: true`** on the example job — masks red as green (D-10).
- **Reusing Statement's 3-region structural assertion for Certificate** — Certificate has a single `:body` region; the assertion will fail.
- **Float amounts in fixtures** — all recipe `amount`/balance keys require `%Decimal{}`; Float raises an `ArgumentError`.
- **Verified fences with `...` placeholders** — `evaluate!/2` runs the code; placeholders break it. Use ` ```elixir-schematic ` for illustrative snippets.
- **Claiming capabilities not in `priv/support_matrix.json`** — semantic-claims tests `refute` `full_pdf_compliance` / `digital_signatures` language.
- **Touching `required_contexts`/`contexts`** in the guardrail manifest — `additive_only` policy; only `advisory_contexts` gets the new entry.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PDF byte rendering in the controller | Manual `Rendro.render` + header juggling | `Rendro.Adapters.Phoenix.render_pdf/3` / `preview_pdf/2` | Adapter already sets content-type/disposition and handles `Rendro.Error` |
| Document assembly from data | Hand-built `%Document{}` / `Rendro.flow` | `Rendro.Recipes.<Recipe>.document/2` | Recipes own validation + layout; controller is data-only |
| Docs fence verification | New test harness | `Rendro.Test.DocsContract.verified_fences/1` + `evaluate!/2` | Harness exists; CONTRACT-02 only adds new guide paths |
| Claim-bounding tests | New assertion framework | `*_claims_test.exs` `File.read! + assert/refute + matrix lookup` pattern | Two-harness discipline is established (D-15) |
| Recording required-vs-advisory CI status | Live GitHub branch-protection edit | `priv/guardrails/required_status_checks.json` manifest + contract test | In-repo source of truth; branch protection managed externally |

**Key insight:** Every mechanism this phase needs already exists in the repo. The work is extension and wiring, not invention.

## Common Pitfalls

### Pitfall 1: Certificate structural assertion copied from Statement/Receipt
**What goes wrong:** Test asserts `[:header, :body, :footer]` regions for Certificate and fails.
**Why:** Certificate's `page_template/1` derives a single `:body` region from geometry (`certificate.ex:89-100`); there is no header/footer.
**How to avoid:** Assert exactly one region named `:body` for Certificate; keep the three-region assertion for Statement/Receipt.
**Warning signs:** `MatchError` / failing `region_names` assertion only on the Certificate test.

### Pitfall 2: Guardrail contract test single-element destructure
**What goes wrong:** `[advisory] = baseline["advisory_contexts"]` (`required_checks_contract_test.exs:33`) raises `MatchError` once a second advisory entry (`example-phoenix`) exists.
**Why:** It assumes exactly one advisory context.
**How to avoid (D-12):** Refactor to `Enum.find(baseline["advisory_contexts"], &(&1["name"] == "viewer-evidence-live-proof"))`; add an `Enum.find` assertion for `example-phoenix` (notes reference "not required" / "REF-03") and `refute "example-phoenix" in baseline["required_contexts"]`.
**Warning signs:** `required_checks_contract_test.exs` fails on the advisory describe block.

### Pitfall 3: `ci.yml` job-name contract test count
**What goes wrong:** `required_checks_contract_test.exs:41-55` iterates `@required_contexts ++ ["viewer-evidence-live-proof"]` asserting each `"  #{job}:"` exists in `ci.yml`. Adding `example-phoenix` is fine for that loop, but if the planner also extends the iterated list, it must keep `example-phoenix` in the **advisory** set, never `@required_contexts`.
**How to avoid:** Add `example-phoenix` only to the advisory side of any contract assertion; do not add it to `@required_contexts`.

### Pitfall 4: Plug constraint too low after Phoenix 1.8 bump
**What goes wrong:** Leaving `plug ~> 1.14` while bandit 1.10 requires `~> 1.18` is misleading and may confuse a `mix deps.update`.
**How to avoid (D-02):** Set `plug ~> 1.18`. `mix.lock` already resolves 1.19.1.
**Warning signs:** None at runtime today (lock already correct), but the constraint misrepresents the real floor.

### Pitfall 5: `verify_docs.exs` lane-count contract
**What goes wrong:** `required_checks_contract_test.exs:90-100` asserts `verify_docs.exs` registers **exactly eight** lanes. Adding the two new D-16 lanes makes it ten and breaks that assertion.
**Why:** The lane-count test is a hard-coded `== 8`.
**How to avoid:** When adding the Recipes + Page-primitive lanes to `verify_docs.exs`, update the lane-count assertion in `required_checks_contract_test.exs:96` from `8` to `10` (and keep the viewer-evidence lane-8 substring assertion or move it appropriately). This is an in-scope edit the planner must include.
**Warning signs:** `docs-contract lane count` test fails after editing `verify_docs.exs`.

### Pitfall 6: ExDoc `skip_undefined_reference_warnings_on` and `mix docs` in `mix ci`
**What goes wrong:** `mix ci` runs `docs`; new guides referencing modules/functions can emit undefined-reference warnings that fail strict docs.
**How to avoid (D-14):** Mirror branding/integrations — add the two new guide paths to `skip_undefined_reference_warnings_on:` if warnings appear. Prefer fully-qualified, real references first.

## Code Examples

### Statement controller action (verified fixture + adapter call)
```elixir
# Source: examples/phoenix_example/.../pdf_controller.ex (idiom) + statement.ex moduledoc (shape)
@demo_statement %{
  period: %{from: ~D[2026-05-01], to: ~D[2026-05-31]},
  account: %{name: "Acme Corp"},
  opening_balance: Decimal.new("1000.00"),
  lines: [
    %{date: ~D[2026-05-02], description: "Invoice #1", amount: Decimal.new("500.00")},
    %{date: ~D[2026-05-15], description: "Payment", amount: Decimal.new("-200.00")}
  ]
}

def statement_download(conn, _params) do
  doc = Rendro.Recipes.Statement.document(@demo_statement)
  RendroPhoenix.render_pdf(conn, doc, "statement.pdf")
end
```

### Certificate structural test (single :body region)
```elixir
# Source: certificate.ex:89-100 (template geometry)
test "certificate document has a single geometry-derived body region" do
  doc = Rendro.Recipes.Certificate.document(@demo_certificate)
  assert %Rendro.Document{} = doc
  assert doc.page_template == :certificate
  assert [template] = doc.page_templates
  assert template.name == :certificate
  region_names = Enum.map(template.regions, & &1.name)
  assert region_names == [:body]
end
```

### Semantic-claims test for page_numbering row
```elixir
# Source: viewer_evidence_claims_test.exs pattern + support_matrix.json:384-394
guide = File.read!("guides/page_primitive.md")
matrix = Jason.decode!(File.read!("priv/support_matrix.json"))
assert guide =~ "Page X of Y"
assert matrix["page_numbering"]["capabilities"]["single_pass_substitution"] == "supported"
assert matrix["page_numbering"]["capabilities"]["deterministic_output"] == "supported"
assert File.exists?(matrix["page_numbering"]["evidence"])  # test/rendro/pipeline/paginate_test.exs
refute guide =~ "digital signatures"
```

## Runtime State Inventory

> This phase is partly a rename-adjacent / additive refactor (CI manifest, lane counts). The relevant non-file state is CI-system contract state, captured below.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no datastores touched. Verified: phase is code/config/docs only. | None |
| Live service config | **Live GitHub branch-protection required-status-check list** is the only out-of-repo state. It is managed externally and intentionally NOT changed by this phase (REQUIREMENTS "Out of Scope" + D-12). The in-repo manifest is the source of truth; a human/operator reconciles branch protection separately. | None in-repo. Operator note in README/PR: `example-phoenix` must NOT be added as a required check. |
| OS-registered state | None. | None |
| Secrets/env vars | None. The new CI job needs no secrets/tokens (it only runs `mix deps.get && mix test`). The guardrail contract test explicitly `refute`s any `GITHUB_TOKEN`/`gh api` reference (`required_checks_contract_test.exs:131-139`). | None |
| Build artifacts | `examples/phoenix_example/erl_crash.dump` exists in the tree (stale crash dump) and `_build`/`deps` (gitignored). CI runs a fresh `mix deps.get`, so no stale-lock risk. | Optionally delete the stray `erl_crash.dump`; not load-bearing. |

**Hard-coded contract counts that will drift (the real "runtime state" of this phase):**
- `required_checks_contract_test.exs:96` asserts **exactly 8** docs-contract lanes in `verify_docs.exs`. Adding 2 lanes (D-16) requires bumping this to **10**.
- `required_checks_contract_test.exs:33` `[advisory] = ...` assumes **exactly 1** advisory context. Adding `example-phoenix` requires the `Enum.find/2` refactor (D-12).
These are not file-grep findings — they are assertion invariants that break silently if missed. Verified by reading the contract test in full.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phoenix example verified inside required `test` job (compile-only) | Isolated advisory `example-phoenix` job running `mix test` | This phase (REF-03/D-09..D-11) | Phoenix-dep failures no longer block engine merge gates |
| `mix.exs` `phoenix ~> 1.7`, `plug ~> 1.14`, `jason ~> 1.2`, `elixir ~> 1.15` | `phoenix ~> 1.8`, `plug ~> 1.18`, `jason ~> 1.4`, `elixir ~> 1.19` | This phase (REF-01/D-02) | Constraints match resolved lock + root library |
| 8 docs-contract lanes | 10 docs-contract lanes (+ Recipes, + Page-primitive) | This phase (CONTRACT-02/D-16) | Lane-count contract assertion must move 8→10 |

**Deprecated/outdated:** None. No deprecated APIs involved.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5 / OTP 28) `[VERIFIED: elixir --version]` |
| Library config | root `mix.exs`; `mix ci` alias = format-check, hex.build, compile --warnings-as-errors, test, docs, credo --strict, dialyzer (`mix.exs:63-72`) |
| Example-app config | `examples/phoenix_example/test/test_helper.exs` (`ExUnit.start()`) + `test/support/conn_case.ex` |
| Quick run (library) | `mix test test/<file>` |
| Quick run (example) | `cd examples/phoenix_example && mix test` |
| Full library suite | `mix ci` (or `mix test`) |
| Docs lanes | `mix run scripts/verify_docs.exs` (lanes run individually) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REF-01 | App compiles clean & boots on new constraints | smoke | `cd examples/phoenix_example && mix compile --warnings-as-errors` then `mix phx.server` (manual boot) | ✅ app exists; constraints edited |
| REF-01 | README documents setup + each recipe | manual/grep | claims test optionally asserts README substrings (branding precedent) | ❌ Wave 0 (README new) |
| REF-02 | Each recipe renders 200 + application/pdf + %PDF- via adapter | integration (ConnCase) | `cd examples/phoenix_example && mix test test/phoenix_example_web/controllers/pdf_controller_test.exs` | ✅ test file exists; +3 blocks |
| REF-02 | Each `document/2` returns correct `%Document{}` + page_template + regions | unit (structural) | same file | ✅ +3 structural assertions |
| REF-03 | Isolated `example-phoenix` job runs `mix test`, not required | CI + contract test | `mix test test/guardrails/required_checks_contract_test.exs` | ✅ contract test exists; refactor + assertions |
| REF-03 | Engine lanes unchanged & still required | contract test | same file (`@required_contexts` unchanged, lane count) | ✅ |
| CONTRACT-02 | Guide fences evaluate | docs-contract fence | `mix test test/docs_contract/recipes_contract_test.exs` | ❌ Wave 0 (new) |
| CONTRACT-02 | Guide claims bounded by matrix + evidence on disk | docs-contract claims | `mix test test/docs_contract/recipes_claims_test.exs test/docs_contract/page_primitive_claims_test.exs` | ❌ Wave 0 (new) |
| CONTRACT-02 | Guides wired into ExDoc, no undefined-ref warnings | docs build | `mix docs` (inside `mix ci`) | ✅ mix.exs edited |

### Sampling Rate
- **Per task commit:** the touched file's quick `mix test <file>` (library) or `cd examples/phoenix_example && mix test` (app).
- **Per wave merge:** full library suite `mix test` + example-app `mix test` + `mix run scripts/verify_docs.exs`.
- **Phase gate:** `mix ci` green (root) AND example-app `mix test` green AND `mix phx.server` boots, before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `examples/phoenix_example/README.md` — REF-01 setup + per-recipe docs (new file).
- [ ] `examples/phoenix_example/lib/phoenix_example_web/controllers/error_json.ex` — D-03 (new module; unblocks clean boot).
- [ ] `guides/page_primitive.md`, `guides/recipes.md` — CONTRACT-02 (new guides).
- [ ] `test/docs_contract/page_primitive_claims_test.exs`, `recipes_claims_test.exs`, `recipes_contract_test.exs` — D-16 (new test files).
- [ ] No framework install needed — ExUnit + ConnCase + DocsContract harness all present.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | all build/test | ✓ | 1.19.5 `[VERIFIED]` | — |
| Erlang/OTP | runtime | ✓ | 28 (erts 16.3) `[VERIFIED]` | — |
| mix | build/test | ✓ | 1.19.5 `[VERIFIED]` | — |
| Hex deps (phoenix/plug/jason/bandit) | example app | ✓ (resolved in mix.lock) | per lock | — |
| GitHub Actions runners (ubuntu-latest, setup-beam) | CI job execution | n/a (cloud) | otp 28 / elixir 1.19.5 per ci.yml | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None. CI signing/viewer tools (pdfium, poppler, pyHanko, certomancer) are NOT needed by the `example-phoenix` job — it runs only `mix deps.get && mix test`.

## Security Domain

> `security_enforcement` is not present in `.planning/config.json`; default-enabled. This phase is documentation/CI/example-app surface with **no new attack surface, no auth, no crypto, no user input handling** — the example app serves only static demo data.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Example app has no auth |
| V3 Session Management | no | No sessions |
| V4 Access Control | no | Public demo endpoints serving fixed data |
| V5 Input Validation | minimal | Controllers ignore params (`_params`); recipes already validate data maps via `validate_data!/1` |
| V6 Cryptography | no | Engine-critical signing lanes explicitly out of scope |
| V14 Configuration / Supply chain | yes | Dep version bumps to high-trust Hex packages; no new packages. CI job runs no secrets (`GITHUB_TOKEN` refute already enforced by the guardrail test) |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| CI job leaks token / runs untrusted secrets | Information Disclosure | `example-phoenix` uses no secrets; guardrail contract test refutes token references in-repo |
| Supply-chain via new dependency | Tampering | No new packages; only floor bumps to already-locked Phoenix/Plug/Jason |
| Doc claims overstate capability (trust erosion) | Repudiation/Spoofing | docs-contract claims tests `refute` out-of-matrix claims (`full_pdf_compliance`, `digital_signatures`) |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Minimal Phoenix 1.8 `ErrorJSON` module (status-message map) satisfies `render_errors` config in this app | Pattern 4 / D-03 | Low — boot gate (`mix phx.server` + a 404) catches an incorrect shape; Phoenix 1.8 `ErrorJSON` convention is a `def render("404.json", _)`-style or `status_message_from_template/1` map |
| A2 | Adding 2 lanes to `verify_docs.exs` requires bumping the `== 8` lane-count assertion to `== 10` | Pitfall 5 | Low — directly observed assertion; if planner registers lanes differently the count still must match reality |
| A3 | `groups_for_extras` key `"Recipes & Primitives"` and `extras` insertion point (after `guides/viewer_evidence.md`) match D-14 intent | D-14 / structure | Low — cosmetic ExDoc grouping; `mix docs` validates |

**Note:** All package names and API names in this research are `[VERIFIED]` against repository source (not assumed). The only `[ASSUMED]` items are the three above, all low-risk and gate-caught.

## Open Questions

1. **Exact Phoenix 1.8 `ErrorJSON` callback shape**
   - What we know: `config.exs` registers `formats: [json: PhoenixExampleWeb.ErrorJSON]`; the module is missing.
   - What's unclear: whether this app's Phoenix 1.8 wiring expects `def render("404.json", _assigns)` returning a map, or the newer `def render(template, _), do: %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}` convention.
   - Recommendation: implement the `status_message_from_template/1` convention (Phoenix 1.7+ generator default) and validate by booting + hitting a non-existent route; the planner can include a tiny test asserting a JSON error body.

2. **README claim assertions (REF-01)**
   - What we know: branding precedent asserts README substrings in a claims test.
   - What's unclear: whether to add README substring assertions for the example app's README (it lives under `examples/`, not packaged).
   - Recommendation: keep README validation as the manual boot gate + optional substring check inside the example app's own test suite; do not over-engineer.

## Sources

### Primary (HIGH confidence) — all repository source read in full
- `examples/phoenix_example/{mix.exs, mix.lock, config/config.exs}` and full `lib/`/`test/` tree
- `lib/rendro/adapters/phoenix.ex`, `lib/rendro/recipes/{statement,receipt,certificate}.ex`, `invoice.ex`/`branded_invoice.ex` (page_template names)
- `.github/workflows/ci.yml`, `priv/guardrails/required_status_checks.json`, `test/guardrails/required_checks_contract_test.exs`
- `mix.exs` (root) `docs/0` + `aliases/0`; `test/support/docs_contract.ex`; `test/docs_contract/{branding_contract,branding_claims,viewer_evidence_claims,integrations_claims}_test.exs`
- `priv/support_matrix.json` (rows 384-433), `scripts/verify_docs.exs`, `guides/branding.md`, `guides/viewer_evidence.md`
- `.planning/{REQUIREMENTS.md, ROADMAP.md}`, `76-CONTEXT.md`
- `elixir --version` / `mix --version` (toolchain confirmation)

### Secondary / Tertiary
- None required — phase is fully code-grounded; no external/web sources used.

## Metadata

**Confidence breakdown:**
- Reference-app facts (deps, files, missing ErrorJSON, controller idiom): HIGH — read every file directly.
- Recipe data contracts + page_template atoms: HIGH — read all three recipe sources; Certificate single-region caveat confirmed.
- CI isolation + guardrail contract: HIGH — full ci.yml + manifest + contract test read; lane-count and advisory-destructure pitfalls confirmed by line.
- Docs-contract harness + matrix bounding: HIGH — harness, both test patterns, and matrix rows read directly.

**Research date:** 2026-05-29
**Valid until:** 2026-06-28 (stable; recheck only if dep floors or `verify_docs.exs` lane count change before planning)
