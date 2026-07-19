# R3 — Example-Data Library Architecture (Milestone A / A1)

**Lens:** software/library architecture for shipping example data cleanly — layout, schema
discipline, loader design, packaging (Hex tarball), byte-determinism, forward-compat with B/C/D.
**Scope:** Phase A1 only (no `lib/` product change). SEED-002 Milestone A.
**Date:** 2026-07-10 · **Confidence:** HIGH (grounded in repo patterns + verified prior art)

---

## 0. What the repo already tells us (the constraints that decide everything)

Five in-tree facts drive every recommendation below. All were read directly, not assumed.

1. **The Hex `package` `files` list is an *exact allowlist*, and it does NOT currently ship most of
   `priv/`.** From `mix.exs`:
   ```elixir
   files: ~w(lib assets/rendro priv/branded bench/results guides
             .formatter.exs mix.exs README.md ADOPTION.md LICENSE NOTICE CHANGELOG.md)
   ```
   Only `priv/branded` ships. `priv/support_matrix.json`, `priv/public_api.json`, `priv/schemas/`
   are **governance/CI artifacts that never enter the tarball** — they are validated in the repo,
   not read at a consumer's runtime. There is an exact-allowlist tarball content audit (v2.5 REL) that
   fails CI on any file drift. So "does `priv/examples/` ship?" is a *deliberate allowlist decision*,
   not a default.

2. **Priv is resolved two different ways depending on run context.**
   - Product code that must work *installed*: `Application.app_dir(:rendro, "priv/branded/...")`
     (`lib/rendro/branded.ex`). This works because `priv/branded` is in the allowlist.
   - Dev/bench code run *from the repo root* uses plain repo-relative `File.read!`
     (`bench/comparison/run.exs` → `"bench/comparison/fixtures/invoice_data.json"`;
     `invoice_rendro.exs` likewise). Bench is **not** in the tarball, so it can only use repo paths.

3. **"Out of the public API manifest" has a mechanical definition already.** `priv/public_api.json`
   is generated from modules carrying `@moduledoc tags: [:stable|:adapter]`. `@moduledoc false`
   modules are *automatically excluded* — that is exactly how the six engine internals
   (`PDF.CidFont`, `Text.Shaper`, `Audit`, `Format`, …) were hidden in v2.5. The
   `public_api_contract_test.exs` lane additionally asserts those internals stay `:hidden` behind a
   `Code.ensure_loaded?` guard. **A `@moduledoc false` loader in `lib/` is therefore public-API-invisible
   by construction, yet compiles in every env and ships in the tarball.**

4. **In-tree JSON-Schema validation is a settled discipline.** `priv/schemas/*.schema.json`
   (JSON-Schema 2020-12, `$id`, `additionalProperties` locked at the leaf, `if/then` conditionals —
   see `support_matrix.schema.json`) are validated by a `@moduledoc false` validator
   (`Rendro.ViewerEvidence.Validator`) using **JSV** (`{:jsv, "~> 0.18", only: [:dev,:test],
   runtime: false}`), driven from a `test/docs_contract/*_claims_test.exs` lane. JSON is parsed with the
   **built-in `JSON`** module (not `jason`) — see `brand.gen.ex` and `invoice_rendro.exs`.

5. **`--check` drift-gate codegen is the established pattern** (`mix brand.gen` / `--check`) and
   **hash-checked deterministic artifacts** are established (`mix rendro.launch_artifacts.*`,
   `rendro.comparison.check`, `rendro.livebook.check` — all in the **advisory** CI lane, never a
   required gate). The example library should slot into these existing rails, not invent new ones.

**The single most important consequence:** the loader belongs in `lib/` as `@moduledoc false`
(not `test/support/`, which only compiles in `:test` and would be invisible to the bench harness and
to Livebook). And the fixtures should ship (small JSON is cheap; it unlocks Livebook/C/consumer use),
gated by the exact-allowlist audit + a text-only rule mirroring the existing `brand/` binary ban.

---

## 1. Directory layout (proposed, forward-compatible with B/C/D)

### The primary-axis decision: `domain → business → family`

The plan carries two phrasings that look contradictory: A0 says "per-domain `DOMAIN.md` …
co-located under `priv/examples/<domain>/` … reused across that domain's families," while the gallery
axis is "family/domain-primary, brand-tagged." These reconcile once you separate **storage** from
**presentation**:

- A single fictional **business** (e.g. *Nimbus Analytics*) owns documents in **multiple families**
  (invoice + statement + receipt). *Halden & Roe* appears in Invoice *and* Statement (AR aging).
- `DOMAIN.md` is **per-domain** and is *reused across that domain's families* → it must sit at a level
  **above** family.
- Milestone C stores **example-brand palettes + logos-as-data per business**, reused across that
  business's family documents → they must sit at the **business** level, above family.

Therefore the only storage tree where both `DOMAIN.md` (domain-scoped) and C's `brand.json`/`logo.svg`
(business-scoped) have a natural, non-restructuring home is **domain → business → family**. The gallery
(A6/C) *presents* family-primary by **indexing across** this tree — presentation axis ≠ storage axis.

### Proposed tree

```
priv/
  examples/
    README.md                         # A1: what this corpus is, the id grammar, determinism rules
    <domain>/                         # business DOMAIN (industry), e.g. saas_subscription, banking,
      DOMAIN.md                       #   A0: domain-language glossary, personas, JTBD, reading context,
                                      #   conventions. One per domain, reused across its families.
      <business>/                     # fictional brand, e.g. nimbus_analytics, halden_and_roe
        invoice.json                  # A1: family fixture (schema-validated)
        statement.json                # A1
        receipt.json                  # A1
        # --- additive, arrives in later milestones; A1 leaves these absent ---
        brand.json                    # C (SEED-004): example-brand palette/theme-tokens-as-data
        logo.svg                      # C: example-brand logo-as-DATA (text SVG, never raster)
        invoice__vat.json             # A: family *flavor* variant (double-underscore suffix)
  schemas/
    examples.schema.json              # A1: NEW — per-fixture structural contract (mirrors the two
                                      #   existing schemas' 2020-12 discipline)
    # (optional, C-era) examples_index.schema.json
  # (optional, A1 or deferred to C) examples/index.json  — generated, --check-gated catalog manifest
```

**Concrete A1 seed instance (the de-quarantined invoice):**

```
priv/examples/saas_subscription/nimbus_analytics/invoice.json     # promoted invoice_data.json
priv/examples/saas_subscription/DOMAIN.md                         # A0 SaaS-subscription domain notes
```

**Fixture identity grammar (the loader key):** the path minus the `priv/examples/` prefix and `.json`
suffix — e.g. `"saas_subscription/nimbus_analytics/invoice"`. Stable, greppable, human-readable,
usable as a gallery slug, and monotonically extensible by C.

### Why this survives B/C/D without a restructure

| Milestone | What it adds to `priv/examples/` | Restructure needed? |
|-----------|----------------------------------|---------------------|
| **A1** | domain/business/family fixtures + `DOMAIN.md` + schema | — (creates it) |
| **A3** | new families `payslip.json` / `ticket.json` under existing businesses | No — new leaf files |
| **A4/A6** | more `<business>/` dirs to fill the family×domain matrix; gallery *indexes* the tree | No |
| **B** (theming) | **nothing** — themes are *code* (`lib/rendro/theme*`), never data | No (by design) |
| **C** (presets/catalog) | `brand.json` + `logo.svg` dropped **into existing `<business>/` dirs**; catalog reads the same tree, brand-tagged | No — additive files in existing dirs |
| **D** (Studio) | reads the same fixtures + `brand.json` as preview inputs | No — read-only consumer |

This is the crux of the lens: **design systems = code, brands = data** (plan §Reconciliation). Keeping
`priv/examples/` purely *data* (fixtures + domain notes + brand tokens/logos) and every *system*
(recipes, `Theme`, presets) in `lib/` is what prevents A1 from painting B/C/D into a corner.

---

## 2. Fixture + schema design

### 2.1 Fixture shape

The promoted `invoice_data.json` is already a good skeleton (`fixture_id`, `paper`, `currency`,
`issuer`/`customer` with real address parts, `invoice` header, `items[]`, `totals`). A1 formalizes an
**envelope + family-payload** shape so all six families share one contract:

```jsonc
{
  "schema_version": "1",
  "fixture_id": "invoice_v1",                 // stable, unique; used by bench guard + tests
  "family": "invoice",                        // enum: invoice|statement|receipt|certificate|payslip|ticket
  "domain": "saas_subscription",              // must equal the parent <domain> dir (test-enforced)
  "business": "Nimbus Analytics",             // display name of the fictional brand
  "title": "Monthly platform subscription",   // gallery/catalog label
  "paper": "us_letter",                       // us_letter | a4
  "currency": "USD",                          // ISO 4217
  "parties": {
    "issuer":   { "name": "...", "street": "...", "city": "...", "region": "OR",
                  "postal_code": "97205", "country": "US" },
    "customer": { "name": "...", "street": "...", "city": "...", "region": "TX",
                  "postal_code": "78701", "country": "US" }
  },
  "invoice": { "id": "INV-2026-001", "date": "2026-06-11",
               "due_date": "2026-07-11", "terms": "Net 30" },
  "line_items": [
    { "name": "...", "description": "...", "qty": "1", "unit_price": "79.00" }
  ],
  "totals": { "subtotal": "4740.00", "tax": "379.20",
              "tax_rate": "0.08", "tax_label": "Sales Tax", "total": "5119.20" }
}
```

**Money encoding — locked: decimal strings** (`"79.00"`, pattern `^-?\d+(\.\d+)?$`), *not* JSON floats
and *not* raw integer minor-units.
- **Decimal-safe / exact:** maps 1:1 to `Decimal.new/1`, which is exact and deterministic — the
  same guarantee `Rendro.Format` + the Statement recipe already rely on (PROJECT Key Decision: "exact
  signed Decimal").
- **Never floats:** JSON float parsing is non-deterministic across languages/rounding — fatal for the
  A5 byte-determinism goldens and the cross-language bench.
- **Currency-exponent-agnostic:** strings carry their own scale, so JPY (0 dp) / BHD (3 dp) / VAT
  fixtures need no special-casing — directly serves the A5 "currency/locale" stress dimension and the
  VAT-flavor matrix entries.
- **Migration note:** the existing fixture uses integer `price_cents` (7900) + `*_cents` totals. This
  is *also* Decimal-safe, so de-quarantine can move bytes verbatim first (§4) and normalize
  `price_cents → unit_price` string **in the same commit that updates the sole consumer**
  (`invoice_rendro.exs`, which today computes `div(price_cents,100)` → identical value `79.00`).

Family-specific payloads (`statement` transactions + carried/brought-forward balances, `payslip`
earnings/deductions/net, `ticket` event/seat/barcode-as-data, `certificate` recipient/credential)
attach as sibling keys selected by `family` via `if/then` (or `oneOf`) — exactly the conditional
pattern in `support_matrix.schema.json`'s `viewer_row`.

### 2.2 `priv/schemas/examples.schema.json` (sketch)

Mirrors the two existing schemas: 2020-12, `$id`, strict leaves, family-conditional required blocks.

```jsonc
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "examples.schema.json",
  "title": "Rendro Example Fixture",
  "type": "object",
  "required": ["schema_version", "fixture_id", "family", "domain", "business", "paper", "currency"],
  "properties": {
    "schema_version": { "const": "1" },
    "fixture_id":     { "type": "string", "pattern": "^[a-z0-9_]+$" },
    "family":  { "enum": ["invoice","statement","receipt","certificate","payslip","ticket"] },
    "domain":  { "type": "string", "pattern": "^[a-z0-9_]+$" },
    "business":{ "type": "string", "minLength": 1 },
    "title":   { "type": "string" },
    "paper":   { "enum": ["us_letter","a4"] },
    "currency":{ "type": "string", "pattern": "^[A-Z]{3}$" },
    "parties": { "$ref": "#/$defs/parties" },
    "line_items": { "type": "array", "items": { "$ref": "#/$defs/line_item" } },
    "totals":  { "$ref": "#/$defs/totals" }
  },
  "allOf": [
    { "if":   { "properties": { "family": { "const": "invoice" } } },
      "then": { "required": ["parties","invoice","line_items","totals"] } }
    // …one branch per family: statement/receipt/certificate/payslip/ticket
  ],
  "$defs": {
    "money":     { "type": "string", "pattern": "^-?\\d+(\\.\\d+)?$" },
    "address":   { "type": "object", "additionalProperties": false,
                   "required": ["name","country"],
                   "properties": { "name":{"type":"string"}, "street":{"type":"string"},
                     "city":{"type":"string"}, "region":{"type":"string"},
                     "postal_code":{"type":"string"}, "country":{"type":"string","pattern":"^[A-Z]{2}$"} } },
    "parties":   { "type": "object", "additionalProperties": false,
                   "properties": { "issuer": {"$ref":"#/$defs/address"},
                                   "customer": {"$ref":"#/$defs/address"} } },
    "line_item": { "type": "object", "additionalProperties": false,
                   "required": ["name","qty","unit_price"],
                   "properties": { "name":{"type":"string"}, "description":{"type":"string"},
                     "qty": {"$ref":"#/$defs/money"}, "unit_price": {"$ref":"#/$defs/money"} } },
    "totals":    { "type": "object", "additionalProperties": false,
                   "required": ["subtotal","total"],
                   "properties": { "subtotal": {"$ref":"#/$defs/money"}, "tax": {"$ref":"#/$defs/money"},
                     "tax_rate": {"$ref":"#/$defs/money"}, "tax_label": {"type":"string"},
                     "total": {"$ref":"#/$defs/money"} } }
  }
}
```

### 2.3 Mapping fixtures → recipe data contracts

Fixtures are the **normalized superset**; each recipe is fed a **thin projection** of the fixture
(exactly how `invoice_rendro.exs` maps today). The fixture is NOT the recipe's argument struct — it is
domain data that a small mapper reshapes into the recipe's expected map. This preserves the plan's
layering: A1 introduces no `lib/` change and does *not* couple the fixture schema to any recipe's public
argument shape (which only changes in A2's additive invoice-anatomy upgrade). The mapper functions live
alongside the loader (`Rendro.Examples`, `@moduledoc false`) or in the example scripts, so the public
recipe contract stays owned by A2, not A1.

### 2.4 Schema-enforcement lane

Add `test/docs_contract/examples_fixtures_test.exs` (a 15th docs-contract lane, folded into the
existing required `test` job — no new required CI context, per the v2.5 lockstep convention): for every
`priv/examples/**/*.json`, assert (a) it validates against `examples.schema.json` via JSV, (b) its
`domain` field equals its parent `<domain>` directory, (c) a sibling `DOMAIN.md` exists at the domain
level, (d) money fields parse via `Decimal.new/1` without exception. This mirrors
`ViewerEvidence.Validator` exactly.

---

## 3. Loader design

### Placement decision: `lib/rendro/examples.ex`, `@moduledoc false`

| Option | Compiles in | Ships in tarball | Usable by bench (`mix run`, dev env) | Usable by tests | Usable by Livebook/consumer | In public_api.json? |
|--------|-------------|------------------|--------------------------------------|-----------------|-----------------------------|---------------------|
| `test/support/examples.ex` | `:test` only | ❌ | ❌ (bench runs in `:dev`) | ✅ | ❌ | n/a |
| **`lib/rendro/examples.ex` `@moduledoc false`** | **all envs** | **✅** | **✅** | **✅** | **✅** | **❌ (excluded by `@moduledoc false`)** |
| `lib/mix/tasks/rendro/examples.ex` (Mix task) | all envs | ✅ | task only, not a callable API | awkward | ❌ (not a library API) | task modules excluded |

`test/support/` is disqualified by the bench harness alone: the comparison runner and
`invoice_rendro.exs` run under `mix run` in `:dev`, where `test/support` is not compiled. Only a `lib/`
module reaches **all four consumers** (tests, bench, Livebook, guides) *and* ships so a consumer can call
it. `@moduledoc false` makes it public-API-invisible **by construction** — the same mechanism that hid
the six v2.5 internals — with zero risk of it leaking into `priv/public_api.json`.

### Sketch

```elixir
defmodule Rendro.Examples do
  @moduledoc false
  # Dev/test/guide-scoped loader for the priv/examples corpus.
  # NOT public API: @moduledoc false ⇒ excluded from priv/public_api.json (same rule as the
  # six v2.5 engine internals). Do NOT add `@moduledoc tags:`. Asserted-hidden by
  # public_api_contract_test.exs (add to the known-internal list, guarded by Code.ensure_loaded?).

  @subdir "examples"

  # Resolve installed priv first (works for consumers/Livebook via app_dir); fall back to the
  # repo tree so bench / `mix run` from source works even pre-install. Mirrors branded.ex's app_dir
  # use, plus the repo-relative fallback that bench already relies on.
  defp base do
    installed = Application.app_dir(:rendro, "priv/#{@subdir}")
    if File.dir?(installed), do: installed, else: Path.join(["priv", @subdir])
  end

  @spec path(String.t()) :: String.t()
  def path(id), do: Path.join(base(), id <> ".json")   # id: "saas_subscription/nimbus_analytics/invoice"

  @spec load!(String.t()) :: map()
  def load!(id), do: id |> path() |> File.read!() |> JSON.decode!()   # built-in JSON, no jason

  @spec load(String.t()) :: {:ok, map()} | {:error, term()}
  def load(id) do
    with {:ok, bin} <- File.read(path(id)), {:ok, data} <- JSON.decode(bin), do: {:ok, data}
  end

  @spec list() :: [String.t()]                 # all fixture ids, sorted (deterministic)
  def list do
    root = base()
    Path.wildcard(Path.join(root, "**/*.json"))
    |> Enum.reject(&(Path.basename(&1) == "index.json"))
    |> Enum.map(&(Path.relative_to(&1, root) |> String.replace_suffix(".json", "")))
    |> Enum.sort()
  end
end
```

**Keeping it out of the public tier — the enforcement:** (1) `@moduledoc false` (auto-exclusion);
(2) add `Rendro.Examples` to the "known internal, must stay `:hidden`" assertion list in
`public_api_contract_test.exs`, behind the existing `Code.ensure_loaded?` guard so a *rename/delete*
also fails, not just a re-expose. This is the exact pattern used for `Text.Shaper`/`Audit`/`Format` et al.

**Guides/Livebook usage in the advisory lane:** `guides/livebook/first_invoice.livemd` and
`guides/recipes.md` can call `Rendro.Examples.load!("saas_subscription/nimbus_analytics/invoice")`.
Because the module ships and resolves via `app_dir`, a consumer running the Livebook via
`Mix.install([:rendro])` gets the same fixture bytes — provided `priv/examples` is in the allowlist
(§5). The `rendro.livebook.check` advisory lane already exercises the Livebook, so this is covered by
existing CI with no new required gate.

---

## 4. De-quarantine + bench repoint (safe, reversible sequence)

The comparison lane renders a PDF and measures cold-start/RSS/image-size; it does **not** hash the JSON,
and `invoice_rendro.exs` consumes only `invoice.id`, `invoice.date`, and `items[]` (name/description/
qty/price). So the rendered-PDF bytes depend only on those fields. Four files reference the fixture:
`bench/comparison/run.exs:10` (`@fixture_path`), `:158-159` (typst `data-path`), `invoice_rendro.exs:2`,
`invoice_typst.typ` (reads `invoice_data.json`), plus `guides/comparison.md:84` and the
`comparison_claims_test.exs` docs-contract assertion.

**Step 1 — move bytes verbatim.**
`git mv bench/comparison/fixtures/invoice_data.json priv/examples/saas_subscription/nimbus_analytics/invoice.json`
(byte-identical; no content edit yet). Add `priv/examples/saas_subscription/DOMAIN.md`.

**Step 2 — repoint consumers to the new path** (or route them through `Rendro.Examples`). Update the
four bench refs + `guides/comparison.md` + the docs-contract path assertion. The Typst tool takes a
`data-path=`; point it at the new absolute/relative path. Keep the `fixture_id == "invoice_v1"` guard
intact — it's a cheap regression tripwire that proves you repointed to the *right* bytes.

**Step 3 — verify the bench lane is unchanged.** Run `mix rendro.comparison.check` (advisory lane) and
confirm `bench/results/comparison.json` still reproduces (the renderer sees identical id/date/items ⇒
identical PDF ⇒ identical measurements within the existing tolerance). This is the go/no-go gate.

**Step 4 — (deferred, couples with A2) normalize money to strings.** Only *after* Step 3 is green,
convert `price_cents`/`*_cents` → `unit_price`/`totals.*` decimal strings **in the same commit** that
updates `invoice_rendro.exs`'s mapper. The rendered value is identical (`7900/100 == "79.00"`), so the
bench stays green; the fixture now conforms to `examples.schema.json`. Keeping normalization decoupled
from the move makes the risky step (Step 1) trivially byte-verifiable and independently revertible.

**Rollback:** each step is a single commit; Step 1 is a pure rename (revert = `git mv` back). No CI
required-gate depends on the bench (comparison is advisory), so a repoint mistake cannot block `main`.

---

## 5. Packaging + determinism

### Should `priv/examples/` ship in the Hex tarball? — **Yes, ship it (text-only, allowlisted).**

Weighing package-size vs example-availability against the exact-allowlist audit:

**For shipping (wins):**
- **Livebook + consumer parity.** `first_invoice.livemd` via `Mix.install([:rendro])` and any HexDocs
  recipe example that calls `Rendro.Examples.load!/1` only work if the fixtures resolve via `app_dir` —
  i.e. only if they ship. This is the "batteries-included" adoption thesis of the whole program.
- **C/D depend on it downstream.** The static configurator, `mix rendro.gen.theme`, and the Studio all
  read `priv/examples/` (incl. C's `brand.json`/`logo.svg`) as inputs; shipping now avoids a
  breaking "suddenly ships" packaging change mid-program.
- **Cost is negligible.** JSON fixtures are ~2–5 KB each; the whole family×domain matrix (~24–30
  fixtures) + `DOMAIN.md` files is well under ~200 KB — trivial next to the already-shipped
  `assets/rendro` gallery PNGs + `manual.pdf`.

**Against (mitigated):**
- **Binary bloat risk lands in C**, not A1 (example-brand logos). **Mitigation — a text-only rule:**
  keep `priv/examples/` to `.json`/`.md`/`.svg` only, enforced by a small test that greps for raster
  extensions — a direct copy of the existing `brand/**/*.{png,jpg,…}` ban in `.gitignore:56-68`. C's
  logos are SVG (logos-as-*data*, per SEED-004). A genuine raster need becomes a deliberate
  allowlist + audit event, never a silent add.
- **Allowlist drift.** Adding the directory means the exact-allowlist tarball audit must be updated once
  (add `priv/examples`); thereafter the audit is the guardrail — every *new* file under it forces a
  conscious allowlist/expected-list update. That is a feature, not friction.

**Allowlist change:** add `priv/examples` to `mix.exs` `package.files` and update the tarball-audit
expected set. Schemas (`priv/schemas/examples.schema.json`) stay **repo-only** (dev/test governance,
consistent with the other two schemas never shipping).

### Byte-determinism requirements (fixtures feed A5 goldens)

A5 hashes the **rendered PDF**, not the JSON, so JSON formatting doesn't change golden hashes — *but*
the fixture input must be byte-reproducible so the golden is reproducible and diffs stay clean:

- **Encoding:** UTF-8, no BOM, LF line endings, exactly one trailing newline.
- **Money:** decimal strings only (§2.1) — never floats.
- **Dates:** ISO-8601 strings.
- **Canonical formatting + `--check` gate:** add `mix rendro.examples.check` (advisory lane, next to
  `rendro.comparison.check`) that validates every fixture against the schema **and** asserts canonical
  formatting (2-space indent, trailing newline; key-sort optional). Model it on `mix brand.gen --check`
  — a STALE result names the offending files and instructs a regen. This is the example-library analogue
  of the `public_api.json`/`support_matrix.json` machine-checked-manifest culture.
- **(Optional, C-era) generated `index.json`:** a hash-checked catalog manifest (id → domain/business/
  family/title/rubric-score) built by the same task, so the gallery/configurator read one manifest
  instead of globbing. Not required for A1; the loader's `list/0` + directory scan suffices initially.

---

## 6. Prior art (how mature libraries ship example/fixture/sample data)

**Elixir / BEAM.**
- **`priv/` is the OTP-standard home for shipped static/seed data**, resolved at runtime via
  `Application.app_dir/2` or `:code.priv_dir/1` — the same call `lib/rendro/branded.ex` already uses.
  Phoenix ships DB migrations and `priv/repo/seeds.exs` here; the convention explicitly covers "seed
  data to load during app boot." Rendro's `priv/examples` + `Rendro.Examples` loader is a
  textbook application of this. ([Phoenix directory structure](https://hexdocs.pm/phoenix/directory_structure.html),
  [`:code.priv_dir` in `_build`](https://elixirforum.com/t/code-priv-dir-my-app-points-to-priv-directory-in-build/26404),
  [static assets in Elixir](https://www.brewinstallbuzzwords.com/posts/elixir-static-assets/))
- **Factory/fake-data libs are `only: :test` and live in `test/support`** so they never ship
  (`{:ex_machina, "~> 2.7", only: :test}`, `{:faker, "~> 0.16", only: :test}`; "Factory modules are
  added inside `test/support` so that they are only compiled in the test environment"). Rendro's twist:
  its examples must *also* serve bench (`:dev`) + Livebook + shipped consumers, so — unlike ExMachina —
  the loader **cannot** live in `test/support`; it must be `lib/` `@moduledoc false`. The corpus is
  *inert data* (like a fixtures dir), not a generator, so it belongs in `priv`, not behind a test-only
  dep. ([ExMachina](https://github.com/beam-community/ex_machina),
  [Test Data Libraries for Elixir — AppSignal](https://blog.appsignal.com/2023/04/25/test-data-libraries-for-elixir.html),
  [ExMachina + Faker in Phoenix](https://nimblehq.co/blog/test-data-phoenix-applications-exmachina-faker))

**Cross-language patterns worth borrowing:**
- **Prawn (Ruby PDF)** ships a `manual/` whose runnable snippets *generate* `prawn-manual.pdf` — a
  self-rendering doc-as-proof. Rendro already mirrors this with `mix rendro.launch_artifacts.gen`
  producing a hash-checked `manual.pdf`; A6 extends it with the realistic corpus. Keeping the *source
  data* (fixtures) separate from the *generated artifact* (PNGs/PDF) is exactly the `priv/examples`
  (input) vs `assets/rendro` (output) split proposed here.
- **ReportLab (Python)** keeps demos/tests *outside* the importable core package so samples don't bloat
  the runtime install — the same instinct behind Rendro's exact-allowlist tarball and the text-only
  rule. The lesson: **let the example corpus grow freely in the repo, gate precisely what ships.**
- **Storybook / component galleries** externalize example *data* (stories/fixtures) from component
  *code* and render a browsable catalog by indexing over that data — precisely the plan's "design
  systems = code, brands = data" boundary and the "gallery indexes the tree, presentation axis ≠ storage
  axis" recommendation in §1.
- **JSON-Schema-validated fixtures** are a mature test-data discipline; Rendro already practices it
  in-tree (JSV + `priv/schemas/*.schema.json` + docs-contract lanes). `examples.schema.json` is a
  same-shaped fourth schema, not a new mechanism.

**What keeps example corpora from bloating core / coupling to test-only code (the two failure modes):**
1. **Bloat →** precise packaging (exact allowlist + text-only rule + tarball audit); data stays tiny
   JSON; generated binaries live in `assets/`, not `priv/examples`.
2. **Test-only coupling →** the loader is inert `@moduledoc false` `lib/` code with no test deps, so it
   serves bench/Livebook/consumers uniformly; the *system* stays in `lib/`, the *data* in `priv/`, and
   neither imports the test factories.

---

## 7. Recommendations (locked)

1. **Layout: `priv/examples/<domain>/<business>/<family>.json`** with `DOMAIN.md` at the domain level.
   Storage axis = domain→business→family; gallery *presentation* axis (family/domain-primary,
   brand-tagged) is achieved by **indexing over** the tree, not by storing that way. **Forward-compat:**
   C drops `brand.json` + `logo.svg` into existing `<business>/` dirs (no restructure); B adds nothing
   (themes are code); D is a read-only consumer.
2. **Fixture money = decimal strings**; envelope (`schema_version/fixture_id/family/domain/business/
   paper/currency`) + family-conditional payloads. **Never JSON floats.**
3. **Schema: `priv/schemas/examples.schema.json`** (2020-12, family-conditional `if/then`, strict
   leaves), validated by a JSV-backed `test/docs_contract/examples_fixtures_test.exs` lane folded into
   the existing required `test` job (no new required CI context). Schema stays **repo-only** (never ships).
4. **Loader: `lib/rendro/examples.ex`, `@moduledoc false`** — `path/1`, `load/1`, `load!/1`, `list/0`;
   `app_dir` resolution with a repo-relative fallback; built-in `JSON`. Kept out of the public tier by
   `@moduledoc false` **and** asserted-hidden in `public_api_contract_test.exs` (Code.ensure_loaded?
   guard). **Not** `test/support` (invisible to bench/Livebook) and **not** a Mix task (not a callable
   library API). **Forward-compat:** C/D consume the same loader; add `brand/2` accessors additively.
5. **De-quarantine in 4 ordered steps** (§4): `git mv` verbatim → repoint the 4 bench refs + guide +
   docs-contract → `mix rendro.comparison.check` green (go/no-go) → normalize money to strings in the
   same commit as the consumer edit. Bench is advisory, so no required gate is at risk; every step is a
   one-commit revert.
6. **Ship `priv/examples/` in the tarball**, added to the `mix.exs` allowlist + tarball audit, **held
   text-only** (`.json`/`.md`/`.svg`) by a test mirroring the existing `brand/` raster ban. Cost is
   negligible; it unlocks Livebook/C/D/consumer use and avoids a later breaking packaging change.
7. **Determinism:** UTF-8/LF/single-trailing-newline; decimal-string money; a `mix rendro.examples.check`
   `--check` drift gate (advisory lane) validating schema + canonical formatting, modeled on
   `mix brand.gen --check`. A generated hash-checked `index.json` is a **C-era** optional optimization,
   not an A1 requirement.

---

## 8. Sanity-check verdict

**The A1 approach is sound and low-risk — proceed as specified, with two sharpenings.** Every A1
ingredient maps onto an *already-proven* repo rail: `priv/` + `app_dir` (branded.ex), `@moduledoc false`
public-API exclusion (six v2.5 internals), JSV + `priv/schemas` + docs-contract validation (viewer
evidence), `--check` drift gates (brand.gen), hash-checked advisory artifacts (launch_artifacts /
comparison / livebook). A1 introduces **no new mechanism and no `lib/` product change** — it is pure
data + one inert loader + governance, exactly as scoped.

**Two sharpenings the plan should absorb:**
- **Loader placement is load-bearing and must be `lib/` `@moduledoc false`, not `test/support`.** The
  plan says "dev/test-scoped loader (out of the public API manifest)," which could be misread as
  `test/support`. That placement would break the bench harness (runs in `:dev`) and Livebook/consumer
  use. `@moduledoc false` in `lib/` is the *only* placement satisfying all four consumers while staying
  out of `public_api.json` — and it already has an enforcement precedent.
- **Split the de-quarantine into "move verbatim" then "normalize money."** Doing both at once would make
  the risky rename hard to byte-verify against the bench. Decoupling makes Step 1 a provable no-op.

**Packaging/coupling risk: LOW, and front-loadable now.** The one real risk (binary bloat) is a
**Milestone-C** concern (example-brand logos), pre-empted here by the text-only rule + exact-allowlist
audit. The one real coupling trap (loader bound to test-only code) is avoided by keeping the loader inert
in `lib/`. Net: A1 as designed does **not** paint B/C/D into a corner — the `data-in-priv / systems-in-lib`
boundary is precisely what keeps theming (B), presets+catalog+configurator (C), and Studio (D) additive.

---

## Sources

- [Phoenix — Directory structure (priv, seeds)](https://hexdocs.pm/phoenix/directory_structure.html) — HIGH
- [`:code.priv_dir` / `Application.app_dir` in `_build`](https://elixirforum.com/t/code-priv-dir-my-app-points-to-priv-directory-in-build/26404) — HIGH
- [Including static assets in an Elixir application](https://www.brewinstallbuzzwords.com/posts/elixir-static-assets/) — MEDIUM
- [ExMachina (factory lib, `only: :test`, `test/support`)](https://github.com/beam-community/ex_machina) — HIGH
- [Test Data Libraries for Elixir — AppSignal](https://blog.appsignal.com/2023/04/25/test-data-libraries-for-elixir.html) — MEDIUM
- [ExMachina + Faker in Phoenix — Nimble](https://nimblehq.co/blog/test-data-phoenix-applications-exmachina-faker) — MEDIUM
- In-repo primary sources (HIGH): `mix.exs` (package allowlist), `lib/rendro/branded.ex` (app_dir),
  `lib/rendro/viewer_evidence/validator.ex` (JSV + priv/schemas), `lib/mix/tasks/brand.gen.ex`
  (`--check` gate), `priv/schemas/{support_matrix,public_api}.schema.json`, `bench/comparison/run.exs` +
  `fixtures/invoice_{data.json,rendro.exs}`, `priv/public_api.json`.
```
