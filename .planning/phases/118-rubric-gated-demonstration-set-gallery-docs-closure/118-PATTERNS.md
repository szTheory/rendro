# Phase 118: Rubric-gated demonstration set, gallery & docs closure - Pattern Map

**Mapped:** 2026-07-19
**Files analyzed:** 20 (6 fixtures, 5 DOMAIN.md, 1 schema, 1 transform module, 1 lib edit, 1 manifest, 3 tests, docs/support surfaces)
**Analogs found:** 18 / 20 (2 have no in-repo analog — the JSON→recipe transform for 5 non-invoice families, and the D-05 demo-cites-DOMAIN.md contract)

> **Read this first (the two least-obvious analogs):**
> 1. **Fixture→recipe transform** (`§ src/…examples_data.ex`) — the only existing analog is a lossy `.exs` bench script; you must author a faithful per-family transform. This is the single largest concealed task.
> 2. **Schema generalization** (`§ priv/schemas/examples.schema.json`) — the current schema hard-requires `invoice`+`items`; every new fixture fails the required test lane until it is generalized. Do this *before* landing any new fixture.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `priv/examples/statement/<biz>/statement.json` | fixture (data) | transform (input) | `priv/examples/invoice/acme-phoenix-saas/invoice.json` | exact |
| `priv/examples/receipt/<biz>/receipt.json` | fixture (data) | transform (input) | same | exact |
| `priv/examples/certificate/<biz>/certificate.json` | fixture (data) | transform (input) | same | exact |
| `priv/examples/payslip/aurora-live/payslip.json` | fixture (data) | transform (input) | same | exact |
| `priv/examples/ticket/aurora-live/ticket.json` | fixture (data) | transform (input) | same | exact |
| `priv/examples/<domain>/DOMAIN.md` ×5 | docs (data) | static | `priv/examples/invoice/DOMAIN.md` | exact |
| `priv/schemas/examples.schema.json` | schema (config) | validation | itself (generalize in place) | self / role-match |
| `lib/rendro/examples_data.ex` (or similar, `@moduledoc false`) | transform module (lib) | transform (JSON→recipe) | `bench/comparison/fixtures/invoice_rendro.exs` | partial (script, lossy) |
| `lib/rendro/launch_artifacts.ex` | gallery generator (lib) | batch render/hash | itself (extend in place) | self |
| `priv/quality/rubric_scores.json` | manifest (data) | append-only | its own `stress_exemption` block + schema `$defs.score_entry` | exact |
| `test/docs_contract/accessibility_overclaim_test.exs` | test | request-response (file scan) | `test/docs_contract/branding_claims_test.exs` | role-match |
| `test/docs_contract/domain_md_contract_test.exs` | test | file scan | itself (strengthen in place) | self |
| `test/docs_contract/rubric_manifest_contract_test.exs` | test | manifest validation | itself (extend `passed?/2` reuse) | self |
| D-05 demo-cites-DOMAIN.md check | test | file scan | domain_md / rubric_manifest test | partial (no exact analog) |
| `priv/support_matrix.json`, `README.md`, `guides/*.md`, `first_invoice.livemd`, `examples/phoenix_example`, `mix.exs` | docs/config | static | existing rows/blocks (generated-block discipline) | role-match |
| `assets/rendro/artifacts.json` + `assets/rendro/gallery/*.png` | build artifact | regenerated | `mix rendro.launch_artifacts.gen` output | self (never hand-edit) |

---

## Pattern Assignments

### `priv/examples/<domain>/<business>/<family>.json` ×5 (fixture, transform-input)

**Analog:** `priv/examples/invoice/acme-phoenix-saas/invoice.json` (full, 95 lines)

**Contract to mirror (D-03):** top-level `fixture_id`, optional `paper`/`currency`, `issuer`/`customer` as `party` objects, **money as decimal strings** matching `^-?[0-9]+\.[0-9]{2}$` (never JSON floats), integer `qty`, optional empty `"brand": {"logo": null}` S4 slot.

**Structure to copy** (invoice.json lines 1-95):
```json
{
  "fixture_id": "invoice_v1",
  "paper": "us_letter",
  "currency": "USD",
  "issuer":   { "name": "Rendro Systems", "street": "…", "city": "…", "region": "OR", "postal_code": "…", "country": "US" },
  "customer": { "name": "Acme Phoenix SaaS", "street": "…", … },
  "invoice":  { "id": "INV-CMP-2026-001", "date": "2026-06-11", "due_date": "2026-07-11", "terms": "Net 30" },
  "items":    [ {"name": "…", "description": "…", "qty": 1, "price": "79.00"} ],
  "totals":   { "subtotal": "4740.00", "tax": "379.20", "total": "5119.20" },
  "brand":    { "logo": null }
}
```

**Per-family payload keys** — each fixture must carry the atom-keyed shape its recipe's `validate_data!/1` requires (see the transform section below for the exact required keys per family). The JSON keys are string versions of those atoms; money/date values are strings the transform coerces.

**Business names (D-02):** Payslip + Ticket = **Aurora Live** (`priv/examples/payslip/aurora-live/…`, `priv/examples/ticket/aurora-live/…`). Statement/Receipt/Certificate get one fictional business each (planner discretion). Note Pitfall 5: the payslip *recipe test* uses employer `"Aurora Textiles Co."` — the new fixture should consciously pick one Aurora identity; fictional-only, no real PII (Payslip is the acute risk).

---

### `priv/examples/<domain>/DOMAIN.md` ×5 (docs, static)

**Analog:** `priv/examples/invoice/DOMAIN.md` (full, 95 lines)

**Four required headings (D-04, enforced by `domain_md_contract_test.exs:4-9`):**
```markdown
## Domain Language
## Personas & Jobs-to-be-Done
## Reading Context
## Layout & Typographic Conventions
```

**Section shape to mirror** (invoice/DOMAIN.md):
- **Domain Language** — bulleted **Nouns** ("the things on the page") + **Verbs and events** ("the lifecycle"), each `**Term** — definition`.
- **Personas & Jobs-to-be-Done** — 2-3 personas, each labeled primary/secondary/tertiary, stating "the ONE fact each reader needs first."
- **Reading Context** — the real situations (queue/triage, fast first scan, slower second read, print vs screen).
- **Layout & Typographic Conventions** — the visual grammar (what is most prominent, table/money alignment, arithmetic ladder). This is the anchor the rubric scores against.

---

### `priv/schemas/examples.schema.json` (schema — GENERALIZE, finding #2)

**Analog:** itself (generalize in place, 74 lines read).

**Current invoice-only requirement (the blocker) — line 7:**
```json
"required": ["fixture_id", "issuer", "customer", "invoice", "items"],
```
`examples_schema_contract_test.exs` globs `priv/examples/**/*.json` and validates *every* fixture against this single shape, so a payslip/ticket/statement fixture goes red until this is generalized.

**Reusable `$defs` to KEEP** (lines 55-72):
```json
"money_string": { "type": "string", "pattern": "^-?[0-9]+\\.[0-9]{2}$" },
"party": { "type": "object", "required": ["name"], "properties": { "name": …, "street": …, "city": …, "region": …, "postal_code": …, "country": … } }
```

**Generalization approach (Open Question #1 recommendation):** single file, add a `family` discriminator + `allOf`/`if-then` per-family branch (or a `oneOf` over per-family sub-shapes). Reuse `money_string`/`party`. Verify JSV (draft-2020-12) handles the chosen construct. Keep `additionalProperties: true` at top level. Every one of the six fixture shapes must validate.

---

### `lib/rendro/examples_data.ex` — NEW transform module (finding #1, the biggest concealed task)

**Analog (partial, ADAPT don't copy):** `bench/comparison/fixtures/invoice_rendro.exs:8-23` — the ONLY existing JSON→recipe transform, and it is lossy.

**Pattern to adapt** (bench script, lines 8-23):
```elixir
items =
  Enum.map(data["items"], fn item ->
    %{
      name: "#{item["name"]} - #{item["description"]}",
      qty: item["qty"],
      price: Decimal.new(item["price"]) |> Decimal.to_integer()   # ← BUG for demos: drops cents
    }
  end)

invoice = %{
  id: data["invoice"]["id"],
  date: Date.from_iso8601!(data["invoice"]["date"]),
  items: items
}
Rendro.Recipes.Invoice.document(invoice)
```

**Critical deltas from the analog (INV-02):**
- **DO NOT** `Decimal.to_integer/1` — keep faithful `Decimal.new(str)` money (the bench's integer coercion is a lossy simplification the demos must not inherit).
- Coerce ISO date strings via `Date.from_iso8601!/1`; money strings via `Decimal.new/1`.
- String keys → atom keys, per family.
- Make it a `@moduledoc false` module (asserted absent from `public_api.json`, like `Rendro.Examples`) with a `transform_<family>/1` per family. Needs its own unit test for the six shapes (Wave-0 gap).

**Exact atom-keyed target shapes each `document/2` requires** (from each recipe's `validate_data!/1` — mirror precisely or you get `KeyError`/`FunctionClauseError`, Pitfall 1). All recipes are `def document(data, opts \\ [])` (`@spec document(map(), keyword()) :: Rendro.Document.t()`):

| Family | Required top-level atom keys (from `validate_data!/1`) | Notable value types |
|--------|-------------------------------------------------------|---------------------|
| **invoice** | `:id`, `:date`, `:items[]` (`:name`,`:qty`,`:price`) | `:date` = `Date.t()`, `:price` = `Decimal.t()` |
| **statement** | `:period` (`:from`,`:to`), `:account` (`:name`), `:opening_balance`, `:lines[]` (`:date`,`:description`,`:amount`) | balances/amounts = `Decimal.t()`, dates = `Date.t()`; optional `:closing_balance`, `:summary` |
| **receipt** | `:title`, `:date`, `:customer` (`:name`), `:lines[]` (`:description`,`:amount`) | `:amount` = `Decimal.t()`; optional `:totals` (`:subtotal`,`:total`) |
| **certificate** | `:title`, `:recipient`, `:date` | `:date` = `Date.t()`; optional `:body`, `:seal_line`, `:brand`; `document(data, border: true)` for keyline frame |
| **payslip** | `:employer` (`:name`,`:address`), `:employee` (`:name`,`:id`,`:tax_code`), `:period` (`:from`,`:to`), `:pay_date`, `:earnings[]` (`:description`,`:amount`,`:ytd`), `:deductions[]`, `:net_pay` | all money = `Decimal.t()`, dates = `Date.t()`; `:net_pay` must reconcile (earnings − deductions); optional `:payment_method` (masked `···· 4321`) |
| **ticket** | `:issuer` (`:name`), `:title`, `:placement[]` (`:label`,`:value`), `:code` (`:reference`, optional `:image`) | strings only; optional `:subtitle` (≤200), `:terms` (≤600); `:code.image` registers as `:ticket_code` asset |

*(Concrete payslip/ticket shapes verified in `test/rendro/recipes/{payslip,ticket}_test.exs` — reuse them as fixture-authoring references.)*

---

### `lib/rendro/launch_artifacts.ex` (gallery generator — the one real `lib/` edit, D-06/D-07/D-13)

**Analog:** itself (extend in place; `@moduledoc false`, stays out of `public_api.json`).

**(D-06) Repoint the dispatch** — replace inline `*_data/*` builders (`:838-903`) with fixture-sourced data. Current dispatch (`:255-286`):
```elixir
def source_document_for(%{id: id}), do: build_source_document(id)
def source_document_for(%{"id" => id}), do: build_source_document(id)   # accepts atom AND string key

defp build_source_document("invoice") do
  invoice_data()                         # ← replace: Rendro.Examples.load!("invoice/acme-phoenix-saas/invoice.json") |> transform_invoice()
  |> Rendro.Recipes.Invoice.document()
  |> apply_launch_table_style()          # ← keep for table families (invoice/branded_invoice/statement/receipt_report)
end
```
Keep `apply_launch_table_style/1` (`:297-299`) for table families; certificate/ticket/payslip choose their own polish (certificate already uses `document(data, border: true)`, `:284-286`). **`branded_invoice` keeps its synthesized brand refs** (`%{font_name: :brand_heading, logo_name: :company_logo}`, `:850-854`) layered over invoice fixture data — the S4 fixture slot is empty this milestone (Assumption A1).

**(D-07) Add Payslip + Ticket tiles** to `@gallery_specs` (`:39-94`). Entry shape to copy (per spec, `:40-49`):
```elixir
%{
  id: "payslip",
  title: "Payslip",
  module: Rendro.Recipes.Payslip,
  png_path: Path.join(@gallery_dir, "payslip.png"),
  asset_name: :gallery_payslip,       # atom, registered for the manual PDF embedded image
  fit: {320, 452},                    # portrait families; certificate (landscape) uses {390, 276}
  alt: "…",
  caption: "…"
}
```
List order == gallery order == required manifest id order (enforced `:458`). Net = 7 tiles: invoice, branded_invoice, statement, receipt_report, certificate, payslip, ticket.

Also extend `@expected_gallery_dimensions` (`:26-32`, advisory-tier; let the first container `.gen` report actual dims — likely `{794,1123}` for both new portrait tiles, Open Q #3) and add manual `recipe_page` wiring for the 2 tiles.

**(D-13) S6 tags** — three coordinated edits:
1. `build_gallery_entries/1` entry map (`:340-356`) — add `"theme"`, `"mode"`, `"preset"` (placeholder `null`; `"light"` defensible only for `mode`).
2. `ordered_gallery_entry/1` (`:942-959`) — append the 3 keys after `"caption"` for stable key order:
```elixir
defp ordered_gallery_entry(entry) do
  ordered_object([
    {"id", entry["id"]}, {"title", entry["title"]}, {"recipe_module", entry["recipe_module"]},
    {"png_path", …}, {"png_sha256", …}, {"source_pdf_sha256", …}, {"page", …}, {"dpi", …},
    {"width_px", …}, {"height_px", …}, {"renderer_kind", …}, {"renderer_version", …},
    {"alt", entry["alt"]}, {"caption", entry["caption"]}
    # + {"theme", …}, {"mode", …}, {"preset", …}   ← append here
  ])
end
```
3. `@gallery_required_keys` (`:25`) — **keep S6 keys OUT** of required (D-13 says optional); instead add a shape check that tolerates absence so older readers never break.

**Generated docs blocks (never hand-edit inside markers):** README (`@readme_start`/`@readme_end`, `:34-35`) and `guides/recipes.md` (`@recipes_start`/`@recipes_end`, `:36-37`) regenerate via `replace_block!`; `collect_docs_block_errors/2` (`:584-598`) fails the required check on drift. Both blocks iterate `manifest["gallery"]`, so the 2 new tiles flow in automatically on regen.

---

### `priv/quality/rubric_scores.json` (manifest — APPEND 6 entries, D-10/S5)

**Analog:** the file's own `stress_exemption` block + schema `$defs.score_entry` (`rubric_scores.schema.json:91-140`). Current `scores: []`; `stress_exemption` stays intact.

**Score-entry shape to append** (schema-valid; D-10 `justifications` is a sibling of `dimension_scores`, never inside it — `dimension_scores` is `additionalProperties: false`):
```json
{
  "demo_id": "invoice-acme-phoenix-saas",
  "domain": "invoice",
  "family": "invoice",
  "domain_md": "priv/examples/invoice/DOMAIN.md",
  "dimension_scores": {
    "information_architecture": 4, "content_hierarchy": 5, "domain_fit": 4,
    "reader_affordances": 4, "typographic_craft": 4, "restraint_cohesion": 4
  },
  "gate_results": { "reading_order": true, "print_safety": true },
  "passed": true,
  "recorded_at": "2026-07-19",
  "justifications": { "content_hierarchy": "Total due is the single dominant number…" }
}
```

**Gotchas:**
- `demo_id` must be **disjoint** from the 62 stress ids (D-12/D-15iii) — use the demonstration namespace with a business segment (`"invoice-acme-phoenix-saas"`, `"payslip-aurora-live"`); hyphen + business guarantees disjointness from `{family}_{dimension}` ids.
- `stress_exempt` MUST be absent/false on every entry (D-15ii tripwire, `rubric_manifest_contract_test.exs:103-107`).
- `passed` must be computed by the **exact** `passed?/2` arithmetic (below), never asserted independently (D-11).
- `domain_md` field is the recommended D-05 citation mechanism (schema `additionalProperties: true` permits it).

**The `passed?/2` arithmetic to mirror** (`rubric_manifest_contract_test.exs:33-45` — DO NOT re-derive):
```elixir
defp passed?(dimension_scores, gate_results) do
  hierarchy_ok? = dimension_scores["content_hierarchy"] == 5
  other_cores_ok? =
    dimension_scores |> Map.delete("content_hierarchy") |> Map.values() |> Enum.all?(&(&1 >= 4))
  gates_ok? = gate_results |> Map.values() |> Enum.all?(&(&1 == true))
  hierarchy_ok? and other_cores_ok? and gates_ok?
end
```

---

### `test/docs_contract/accessibility_overclaim_test.exs` — NEW (D-14)

**Analog:** `test/docs_contract/branding_claims_test.exs` (full, 108 lines) — clone the tripwire discipline (`use ExUnit.Case, async: true`, `File.read!` per path, `assert`/`refute content =~ term`).

**New assertion (whole-file first cut; refine to per-section proximity if too coarse, A2):**
```elixir
@showcase_terms ["production-grade"]                              # discretion: extend list
@accessibility_terms ["PDF/UA", "tagged PDF", "screen reader",
                      "reading order", "accessible", "accessibility conformance"]

test "no showcase wording co-occurs with an accessibility claim" do
  for path <- ["README.md" | Path.wildcard("guides/**/*.md")] do
    content = File.read!(path)
    if Enum.any?(@showcase_terms, &String.contains?(content, &1)) do
      for term <- @accessibility_terms do
        refute content =~ term, "#{path}: '#{term}' must not co-occur with showcase wording (D-14)"
      end
    end
  end
end
```
Honest affordances stay: logical reading order (a rubric *gate*, not a public claim), human-readable Ticket reference, byte-determinism.

---

### `test/docs_contract/domain_md_contract_test.exs` — MAYBE strengthen (D-04, discretion)

**Analog:** itself (28 lines). Currently asserts "at least one" (`:12-15`) and "every DOMAIN.md has 4 headings" (`:17-26`). Optional strengthening: from "at least one" to "a DOMAIN.md **per demonstrated domain**." Recommended, but may stay additive if over-coupling risk. The 4-heading loop already covers new files via the `priv/examples/*/DOMAIN.md` glob.

---

### D-05 demo-cites-DOMAIN.md check — NEW (no exact analog)

**Partial analog:** the file-scan style of `domain_md_contract_test.exs` + the manifest-read style of `rubric_manifest_contract_test.exs`. Recommendation (Open Q #2): assert each score entry's `domain_md` path exists on disk AND each demonstrated domain has a DOMAIN.md. Lowest new surface; bounds the citation so it can't silently rot.

---

## Shared Patterns

### `@moduledoc false` (keep new lib code out of the public API)
**Source:** `lib/rendro/examples.ex:2`, `lib/rendro/launch_artifacts.ex:2`
**Apply to:** the new transform module AND the `launch_artifacts.ex` edits.
`Rendro.Examples` is asserted absent from `public_api.json` (`public_api_contract_test.exs:90`). The new transform module must be `@moduledoc false` and similarly excluded.

### Defensive fixture loading (don't hand-roll File.read!)
**Source:** `lib/rendro/examples.ex:13-22`
```elixir
def load!(relative_path) do
  safe = safe!(relative_path)                     # Path.safe_relative/1 traversal guard
  :rendro |> Application.app_dir(@base_dir) |> Path.join(safe) |> File.read!() |> JSON.decode!()
end
```
**Apply to:** the transform module's fixture reads — always `Rendro.Examples.load!("<domain>/<business>/<family>.json")`, never a bare `File.read!` (the guard + `app_dir` resolution matter for shipped consumers).

### Deterministic ordered-JSON manifest encoding
**Source:** `launch_artifacts.ex:912-962` (`encode_manifest/1`, `ordered_gallery_entry/1`, `ordered_object/1` = `Jason.OrderedObject`)
**Apply to:** any S6 key addition — slot into the fixed key order; the `\n`-terminated pretty encode is already contract-gated.

### Generated-block docs discipline (never hand-edit)
**Source:** `launch_artifacts.ex:34-37` (markers), `:584-598` (`collect_docs_block_errors/2`)
**Apply to:** README + `guides/recipes.md` gallery blocks — regenerate via `mix rendro.launch_artifacts.gen`; hand edits fail the required drift check.

### Tarball text-only / exclusion assertions (clone, don't re-parse)
**Source:** `branding_claims_test.exs:41-86` using `Rendro.Test.HexBuildCache.get_build_output/0`
**Apply to:** verifying new `priv/examples/**` domains ship text-only (`.json`/`.md`/`.svg`) and that goldens/raster_refs stay excluded (`mix.exs` `defp package` `files:` allowlist already lists `priv/examples`).

### Rasterization (don't shell to pdfium)
**Source:** `Rendro.Adapters.Pdfium.render(pdf, dpi: 96, pages: "1")` (`launch_artifacts.ex:336`)
**Apply to:** gallery PNGs AND D-09 rubric self-scoring rasters — isolated tmp dir, list-form args. **Container-gated** (see below).

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/rendro/examples_data.ex` (per-family transform) | transform module | JSON→recipe | Only analog is a single-family, **lossy** `.exs` bench script; 5 of 6 families have no transform at all. Author fresh, keeping faithful Decimal money. |
| D-05 demo-cites-DOMAIN.md contract | test | file scan | No existing "manifest-field-references-a-real-path" contract; compose from domain_md + rubric_manifest test styles. |

---

## Environment Constraint (affects sequencing, not patterns)

`pdfium-cli` is **not on this dev machine** and its pin is Linux-only (`priv/pdfium_pin.json` → `pdfium-webassembly-linux-amd64`, v0.11.0). Route SHOW-03 regen (`mix rendro.launch_artifacts.gen`) + D-09 raster self-scoring through the **pinned CI container** (Phase-117 precedent). The **required source-PDF SHA-256 lane** is byte-stable/portable — document-shape correctness, all contract tests, schema validation, and the rubric arithmetic run locally **without** pdfium. Plan local waves first; container-gated regen/scoring is a bounded final wave.

## Metadata

**Analog search scope:** `priv/examples/`, `priv/schemas/`, `priv/quality/`, `lib/rendro/`, `lib/rendro/recipes/`, `test/docs_contract/`, `test/rendro/recipes/`, `bench/comparison/fixtures/`
**Files scanned:** ~20 (all cited by direct read, 2026-07-19)
**Pattern extraction date:** 2026-07-19
