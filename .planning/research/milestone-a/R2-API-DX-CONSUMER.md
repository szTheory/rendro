# R2 — API / DX from the CONSUMER's perspective (Milestone A / SEED-002)

**Lens:** a Phoenix/Elixir developer calling Rendro. API elegance from the caller's side, principle of least surprise, errors-as-product, backward-compat. Engine internals stay hidden.

**Scope covered:** A2 (Invoice anatomy upgrade + `Rendro.Format` promotion), A3 (new `Payslip` + `Ticket` recipes), the errors-as-product boundary, and the `opts` forward-compat seam that Milestone B threads `theme:` through.

**Confidence:** HIGH on the family-consistency recommendations (grounded directly in `receipt.ex` / `statement.ex` / `certificate.ex` / `pagination.ex` / `public_api.json`), MEDIUM on the exact Payslip/Ticket field names (design proposals, not yet ratified by A0 domain research).

---

## 0. The one hard constraint, restated in caller terms

Today this call works and is covered by `test/rendro/recipes/invoice_test.exs` and `test/rendro/recipes_facade_drift_test.exs`:

```elixir
Rendro.Recipes.Invoice.document(%{
  id: "INV-042",
  date: ~D[2026-04-30],
  items: [
    %{name: "Widget A", qty: 3, price: 200},   # price is a bare integer
    %{name: "Widget B", qty: 1, price: 500}
  ]
})
```

The header must still contain `INVOICE #INV-042`, the body must still contain the item names, and the drift test asserts `Rendro.Recipes.invoice(data, []) == Rendro.Recipes.Invoice.document(data, [])`. **Byte-identical output for legacy inputs is the non-negotiable acceptance gate.** Every recommendation below is engineered so the toy call's rendered bytes do not move.

Two subtle byte-identity facts I verified so we can safely adopt the family helpers:

- `"#{~D[2026-04-30]}"` == `"2026-04-30"` == `Rendro.Format.date(~D[2026-04-30])` (both are `Date.to_iso8601/1`). **We can route `%Date{}` dates through `Rendro.Format.date/1` without changing legacy bytes.**
- Legacy line money is `"$#{item.price}"` → `"$200"`. `Rendro.Format.money/1` requires a `%Decimal{}` and emits `"$200.00"`. These differ, so **the legacy `price` path must stay on raw interpolation; `Format.money/1` is opt-in via a `%Decimal{}` value.**

---

## 1. Invoice A2 — additive data contract

### 1.1 Design principle: additive layering, per-value opt-in, no magic modes

The family already has the answer. `Receipt`/`Statement` carry `customer`/`account`, `totals`/`summary`, Decimal money, and a `validate_data!/1` boundary. Invoice should grow toward that shape **without renaming a single existing key** and **without introducing a hidden "rich mode vs toy mode" flag**. The rule of least surprise: a new key does nothing unless you pass it; a money value formats richly only when it is a `%Decimal{}`.

### 1.2 Before / after `data` map

**Before (frozen, still valid forever):**

```elixir
%{
  id: "INV-042",
  date: ~D[2026-04-30],
  items: [%{name: "Widget A", qty: 3, price: 200}]
}
```

**After (all new keys optional; shown fully populated):**

```elixir
%{
  # --- legacy core (unchanged shape, still the only required keys) ---
  id:    "INV-2026-042",
  date:  ~D[2026-04-30],
  items: [
    # legacy line: bare number price -> "$1,200" via interpolation (unchanged)
    %{name: "Onboarding", qty: 1, price: 1200},
    # rich line: Decimal price -> Rendro.Format.money/1 -> "$3,000.00"
    %{name: "Seats (10 × $300)", qty: 10, price: Decimal.new("300.00")}
  ],

  # --- new optional anatomy (additive; absent => not rendered) ---
  issuer:   %{name: "Marigold Studio", address: ["114 Kiln Rd", "Portland, OR 97204"], email: "ar@marigold.studio"},
  customer: %{name: "Northwind Provisions", address: ["9 Dockside Way", "Seattle, WA 98101"]},
  due_date: ~D[2026-05-30],
  terms:    "Net 30. Late balances accrue 1.5%/mo.",
  currency: %{symbol: "$", label: "USD"},   # display-only; engine stays locale-free
  totals:   %{
    subtotal: Decimal.new("4200.00"),
    tax:      Decimal.new("378.00"),
    discount: Decimal.new("0.00"),
    total:    Decimal.new("4578.00")
  }
}
```

**Resulting call is identical in arity — only the data grows:**

```elixir
{:ok, pdf} = Rendro.Recipes.Invoice.document(data) |> Rendro.render()
```

### 1.3 Key-by-key shape + rationale

| Key | Shape | Required? | Rendered as | Rationale |
|-----|-------|-----------|-------------|-----------|
| `:id` | `String.t()` | yes (legacy) | `INVOICE #<id>` header | unchanged |
| `:date` | `Date.t()` \| `String.t()` | yes (legacy) | `Date: <iso>` — `%Date{}` via `Format.date/1`, string passthrough | Date path adopts family formatter byte-identically |
| `:items` | `[%{name, qty, price}]`, `price` = `number()` \| `Decimal.t()` | yes (legacy) | table rows | per-value money opt-in |
| `:issuer` | `%{name: String, address: [String], ...}` | no | header "from" block | mirrors `customer` shape |
| `:customer` | `%{name: String, address: [String], ...}` | no | header "bill to" block | **reuse Receipt's `%{name: ...}` core** so shapes rhyme across the family |
| `:due_date` | `Date.t()` | no | header/terms line via `Format.date/1` | |
| `:terms` | `String.t()` | no | footer/terms line | |
| `:currency` | `%{symbol: String, label: String}` | no | display label only | keeps `Format` locale-free; symbol/label is presentation |
| `:totals` | `%{subtotal, tax, discount, total}` all `Decimal.t()` | no | totals block kept with last table rows | mirrors `Receipt.totals` verbatim |

**Money type rule (the errors-as-product line):**
- Legacy `items[].price` as a bare `number()` → stays on `"$#{price}"` interpolation. **Not newly rejected** (a Float here previously "worked"; rejecting it would be a breaking change). Documented as the legacy path; Decimal recommended.
- Every **new** money surface — `items[].price` when a `%Decimal{}`, and all of `:totals.*` — is **Decimal-only and rejects Float instructively**, copying `Receipt.validate_line_amount!/2` word-for-word in spirit (What/Where/Why/Next). This gives the "opt into correctness" story without a breaking change to the toy path.

### 1.4 Totals: caller-supplied-and-validated (mirror Statement/Receipt), never auto-rendered

Two independent decisions:

1. **Render only when present.** A toy invoice shows no totals block today; auto-deriving-and-rendering one would move legacy bytes. So the totals block is emitted **iff `:totals` is present** — exactly `Receipt.build_totals_blocks/2`'s `when is_map(totals)` guard. Absent ⇒ no block ⇒ byte-identical legacy output.
2. **Validate, don't compute-from-scratch.** When `:totals` is supplied, treat it as a caller assertion and check it with `Decimal.equal?/2`, mirroring `Receipt.maybe_validate_totals!/1` and `Statement.maybe_validate_closing_balance!/1`:
   - Internal arithmetic always checked: `total == subtotal + tax − discount` (Decimal).
   - Cross-check against line items **only when every item carries a `%Decimal{}` price** (i.e. the caller has opted into Decimal money): `subtotal == Σ (qty × price)`. If items are legacy integer-priced, skip the line cross-check (we can't assert money correctness on a path that never promised it) and validate internal arithmetic only.

This matches the shipped Key Decision *"carried/brought-forward totals are computed in recipe `sections/2`… caller-supplied closing balances validated via `Decimal.equal?/2`."* The consumer gets a loud, instructive mismatch error instead of a silently wrong PDF.

### 1.5 How the toy call keeps working — the default-fill map

| Absent key | Default behavior |
|------------|------------------|
| `:issuer` / `:customer` | header renders only `INVOICE #<id>` + `Date:` (today's two blocks) |
| `:due_date` / `:terms` | no extra lines |
| `:currency` | none — line/total money uses `Format.money/1`'s `$` (Decimal) or raw interpolation (legacy) |
| `:totals` | **no totals block emitted** (byte-identical) |
| `price` as `number()` | `"$#{price}"` interpolation (byte-identical) |

Net: `document(%{id:, date:, items:})` walks exactly the legacy code paths.

### 1.6 Totals-block "keep with the last rows"

The plan requires the totals block to stay with the last table rows across a page break. `Receipt` already appends the totals as a trailing block after the last per-page table block (`table_blocks ++ totals_blocks`) with `break_before: false`, relying on the shared `Rendro.Recipes.Pagination` chunker so it lands on the final page. **A2 should reuse `Rendro.Recipes.Pagination.chunk_rows_into_pages/2` and the Receipt totals-append pattern verbatim** rather than invent keep-with logic — this is a solved problem in the family and keeps the recipe thin (Key Decision: recipes reuse the shared private pagination helper).

---

## 2. `Rendro.Format` promotion

### 2.1 Public surface — keep it minimal; i18n is a recipe-opts concern, not a Format concern

Recommended public surface: **exactly the three functions it already exports — `money/1`, `date/1`, `label/1`.** Do **not** add `:formatters`/`:labels` hooks *into* `Format`. That override seam already exists one layer up, in `Rendro.Recipes.Pagination`:

```elixir
# already shipped — the i18n seam lives at the recipe opts layer
fmt_amount = Rendro.Recipes.Pagination.formatter(opts, :amount, &Rendro.Format.money/1)
fmt_date   = Rendro.Recipes.Pagination.formatter(opts, :date, &Rendro.Format.date/1)
lbl        = Rendro.Recipes.Pagination.label_resolver(opts)   # merges opts[:labels] over Format.label/1
```

So a caller does i18n **without Format ever becoming locale-aware**:

```elixir
Rendro.Recipes.Invoice.document(data,
  formatters: [amount: &MyApp.Money.eur/1, date: &MyApp.Locale.date/1],
  labels: %{subtotal: "Zwischensumme", total: "Gesamt"}
)
```

This is exactly the shipped Key Decision: *"`Rendro.Format` is pure and locale-free by construction… i18n is a caller-supplied `:formatters`/`:labels` override, never core."* Promoting the module must **not** dilute that; keep `Format` a dumb, deterministic default.

One additive nicety worth considering (LOW-priority, defer unless A4 needs it): widen `label/1`'s key set to include invoice-family labels (`:subtotal`, `:tax`, `:discount`, `:total`, `:due_date`, `:bill_to`) so recipes and callers resolve labels through one table. This is additive and keeps `label/1` the single label source of truth.

### 2.2 Tier + manifest + docs

- **Tier: `:adapter`** (per plan and consistent with all five recipes). Adapter = Tier-2 Evolving, which is the right stability posture for a formatting helper.
- **Module change:** `@moduledoc false` → a real `@moduledoc` (the existing function docs are already HexDocs-grade) + `@moduledoc tags: [:adapter]`.
- **`priv/public_api.json` diff** (insert in alphabetical position, between `Rendro.FontRegistry.*` and `Rendro.FormField`):

```json
"Elixir.Rendro.Format": {
  "functions": [
    "date/1",
    "label/1",
    "money/1"
  ],
  "tier": "adapter",
  "types": []
}
```

- **`@spec` requirement:** the Phase-79 contract lane only enforces `@spec` on **stable**-tier functions. `Format` is adapter tier, so specs are optional — but all three already have `@spec`, so keep them (free win). No backfill needed.
- **Migration note:** purely **additive** (a hidden module becomes public). No caller breaks. CHANGELOG / `guides/upgrading` line: *"`Rendro.Format` is now a public adapter-tier module (`money/1`, `date/1`, `label/1`) — the deterministic, locale-free default formatter used by the recipes. Override per-recipe via `opts[:formatters]` / `opts[:labels]`."*

### 2.3 Risk in promoting a currently-private module — the one real gotcha

**Phase 78 explicitly made `Rendro.Format` `@moduledoc false` as one of "six accidentally-public engine internals," and Phase 79's `public_api_contract_test.exs` asserts those six internals stay `:hidden`.** Promoting Format is therefore **not** a one-file change — you must:

1. Remove `Format` from the contract test's expected-hidden set (the assertion "these six internals remain hidden" becomes five).
2. Add the manifest entry above; the byte-compare drift test then passes.
3. Confirm the "every manifested module carries exactly one tier tag" check sees the new `@moduledoc tags: [:adapter]`.

If A2 edits `format.ex` but forgets the contract test, CI fails **red at the drift lane** (which is the system working — but the plan must budget for editing the test, not just the module). This is the highest-friction step in A2; flag it in the phase plan.

Secondary risk: once public (even adapter tier) the three signatures are a commitment. Keeping the surface at three functions minimizes what you owe. `money/1`'s exact formatting (`$1,234.50`, parens for negatives) becomes an observable contract — but it is already golden-tested and stable, so this is acceptable.

---

## 3. Payslip + Ticket — recipe shapes

Both ride the same three-rung signatures every recipe exposes, registered identically in `public_api.json` (adapter tier, `document/2` + `page_template/1` + `sections/2`) and the `Rendro.Recipes` facade (`payslip/1,2`, `ticket/1,2`).

### 3.1 Payslip — a flow recipe (A4, same skeleton as Statement/Receipt)

Payslip is structurally a Statement/Receipt sibling: header + paginated body tables + footer, with **net pay as the single visual anchor** (rubric hierarchy = 5). It reuses `Rendro.Recipes.Pagination` and `Rendro.measure_rows/4`.

```elixir
@spec page_template(keyword()) :: Rendro.PageTemplate.t()
@spec sections(map(), keyword()) :: [Rendro.Section.t()]
@spec document(map(), keyword()) :: Rendro.Document.t()
```

**Data contract:**

```elixir
%{
  # --- required ---
  employer: %{name: "Rivet Payroll", address: ["…"]},   # %{name: String} core, mirrors customer/account
  employee: %{name: "Dana Okafor", id: "E-4471"},
  period:   %{from: ~D[2026-06-01], to: ~D[2026-06-30]},  # reuse Statement's period shape verbatim
  pay_date: ~D[2026-07-05],
  earnings:   [%{description: "Base salary", amount: Decimal.new("5200.00")}],
  deductions: [%{description: "Federal tax", amount: Decimal.new("910.00")},
               %{description: "Health",      amount: Decimal.new("180.00")}],
  totals: %{
    gross:      Decimal.new("5200.00"),   # == Σ earnings
    deductions: Decimal.new("1090.00"),   # == Σ deductions
    net:        Decimal.new("4110.00")    # == gross − deductions  (THE key fact)
  },

  # --- optional ---
  ytd: %{gross: Decimal.new("31200.00"), net: Decimal.new("24660.00")}
}
```

**Validation (mirror Statement/Receipt):** required keys present; `period` is `%{from: Date, to: Date}`; `pay_date` a `%Date{}`; every `earnings`/`deductions` amount a `%Decimal{}` (Float rejected instructively); and `totals` validated with `Decimal.equal?/2` — `gross == Σearnings`, `net == gross − Σdeductions`. Net-pay block is emitted last and kept with the deductions table via the same trailing-block trick as Receipt totals.

### 3.2 Ticket — a fixed-box recipe (not A4 flow) that still honors the 3-rung pattern

The three rungs are about **composition levels, not page size** — `Certificate` already proves a recipe can own its own geometry (landscape default, `PageSize.resolve/2`, zero hardcoded numerics). Ticket is the small-box analogue:

- **`page_template/1`** returns a small fixed-size template (default a standard event-ticket box, e.g. `{w, h}` in points; overridable via `page_size:` / `{width, height}` like Certificate), with a single flow/fixed region. **All geometry derived from the page dimensions — no hardcoded A4 numerics** (Key Decision from Certificate).
- **`sections/2`** returns one section placing a handful of fields into the box. No pagination, no chunker — a ticket is single-page by definition. If content overflows the box the engine's existing fit-validation raises a typed `:content_overflow` (this is the desired failure mode, per the A5 stress matrix "single row taller than body → typed error").
- **`document/2`** assembles as usual.

**Minimal, least-surprising data map:**

```elixir
%{
  # --- required ---
  title:  "Aurora Live — Midsummer Session",
  holder: %{name: "Dana Okafor"},   # %{name: String} core again
  starts_at: ~D[2026-07-18],        # Date or a preformatted String
  venue:  %{name: "Cedar Hall", city: "Portland, OR"},
  serial: "TIX-8F42-0091",          # rendered as text; NOT a barcode/QR (no such primitive — see risk)

  # --- optional ---
  subtitle: "Doors 7:00 PM",
  seat:     %{section: "A", row: "12", seat: "7"},
  price:    Decimal.new("48.00")    # Decimal => Format.money/1
}
```

**Consistency note:** `holder`, `venue`, `employer`, `customer`, `issuer`, `account` all share the `%{name: String.t(), ...}` core so a Phoenix dev learns one party-map shape once. That is the single biggest DX lever across the family — keep it uniform.

---

## 4. errors-as-product — the validation boundary

### 4.1 Raise `ArgumentError`, not `Rendro.Error`

Verified in `statement.ex` line 442's own comment: *"raising an instructive `ArgumentError` (NOT `Rendro.Error`, which is a plain defstruct and not a defexception)."* `public_api.json` confirms `Rendro.Error` exports `from_stage/3` + `t/0` — it is a struct for pipeline diagnostics, **not raisable**. So the recipe boundary must raise `ArgumentError` with the shipped four-part message block:

```
Rendro.Recipes.Invoice.document/2 — <one-line what>.

What:  <what must be true>
Where: Rendro.Recipes.Invoice.validate_data!/1
Why:   <the offending value, via Rendro.Recipes.Pagination.type_name/1>
Next:  <the exact fix>
```

Use `Rendro.Recipes.Pagination.type_name/1` for the human-readable type in `Why:` (already shared). *(Aside: the prompt mentions `Rendro.Error`; the codebase reality is `ArgumentError`. Recommendation follows the code, not the prompt.)*

### 4.2 Add `validate_data!/1` to Invoice — additive strictness only

Invoice currently has **no** `validate_data!/1`; its private builders pattern-match `%{id: id, date: date}` / `%{items: items}`, so a missing key today leaks a `FunctionClauseError` — precisely the Phase-77 footgun. A2 must add `validate_data!/1` called first in both `sections/2` and `document/2` (the shipped pattern). Crucially, **it may only reject inputs that already crash today**:

- Required: `:id` (binary), `:date` (`%Date{}` or binary), `:items` (list of maps each with `:name`, `:qty`, `:price`). These were already implicitly required — we're upgrading a `FunctionClauseError` into an instructive `ArgumentError`, never rejecting a previously-working call.
- Optional keys validated **only when present**: `:customer`/`:issuer` are `%{name: binary}`; `:due_date` a `%Date{}`; `:terms` a binary; `:totals` money all `%Decimal{}` with Float rejected; `:totals` arithmetic checked via `Decimal.equal?/2`.
- **Do not** newly reject a legacy numeric `items[].price` (backward-compat).

Payslip/Ticket get the full Receipt-grade `validate_data!/1` from day one (no legacy path to protect).

### 4.3 The must-never-leak list

`BadMapError`, `FunctionClauseError`, `KeyError`, `Decimal` arithmetic exceptions on Float, and `struct!/2` `KeyError` from opts (see §5). Every one of these must be intercepted at `validate_data!/1` (data) or the `Keyword.take` filter (opts) before it reaches a builder.

---

## 5. `opts` forward-compat — keep the `theme:` seam clean for Milestone B

### 5.1 The latent bug in `Invoice.page_template/1` (fix in A2)

`Invoice.page_template/1` and `BrandedInvoice.page_template/1` do:

```elixir
Rendro.page_template(Keyword.merge(defaults, opts))   # <-- opts flow straight into struct!
```

`Statement.page_template/1` already fixed this exact hazard:

```elixir
# Recipe-level opts (:labels, :formatters, ...) must NOT reach page_template struct!/2.
template_opts =
  Keyword.take(opts, [:name, :width, :height, :margin_top, :margin_right,
                      :margin_bottom, :margin_left, :regions])
Rendro.page_template(Keyword.merge(defaults, template_opts))
```

**Recommendation:** A2/A3 adopt the `Keyword.take` whitelist in `Invoice`, `Payslip`, and `Ticket` `page_template/1`. Without it, the moment Milestone B calls `Invoice.document(data, theme: my_theme)`, `theme:` reaches `struct!(%Rendro.PageTemplate{}, ...)` and raises `KeyError` — a leaked engine internal, the opposite of errors-as-product. Fixing it now makes B's `theme:` seam a no-op change at the template rung.

### 5.2 Thread opts uniformly; keep the opts map OPEN

- `document/2` → passes the same `opts` to both `page_template/1` and `sections/2` (shipped pattern; preserve).
- **Do not add a closed allowlist over the top-level `opts` keyword.** Certificate uses a closed allowlist only for the nested `border:` *map*, never for `opts` itself — correct. If A2/A3 rejected unknown opts keys, B could not add `:theme` additively. Leave `opts` open; recipes consume the keys they know (`:formatters`, `:labels`, `:page_number_opts`, `:name`, geometry) and ignore the rest.
- **Reserve `:theme` semantically now** by simply never using that key for anything else in A. B will resolve it once at `document/2` (`Rendro.Theme.resolve(opts[:theme] || Rendro.Theme.default())`) and thread the resolved struct down — A just has to not collide with the name and not choke on an unknown key.

### 5.3 Money/label overrides already forward-compatible

New recipes should format via `Rendro.Recipes.Pagination.formatter/3` + `label_resolver/1` (not by calling `Rendro.Format` directly), so a caller's `:formatters`/`:labels`/(future `:theme`) all ride the same open opts map. This is the seam that keeps core locale-free while B layers theming on top.

---

## 6. Prior art — did right / did wrong

Grounded in the libraries named in the brief plus idiomatic Elixir. Sources listed at the end.

| Library | Did RIGHT (adopt) | Did WRONG (avoid) | Lesson for Rendro |
|---------|-------------------|-------------------|-------------------|
| **Prawn** (Ruby) | Solid low-level table primitive (`prawn-table`) | No batteries-included invoice — everyone hand-rolls; imperative bounding-box coordinate math; totals hand-computed → display/compute drift | A thin declarative recipe over primitives is exactly the value; the proliferation of 3rd-party `prawn_invoice`/`invoice_printer` gems *proves* the recipe layer is wanted |
| **invoice_printer / prawn_invoice** (Ruby gems) | A data-map → PDF invoice with sensible defaults (the recipe idea) | Config sprawl; template overrides leak Prawn internals | Validates Rendro's `document(data)` shape; keep the escape hatch (rungs) so overrides don't leak geometry |
| **ReportLab Platypus** (Python) | Declarative flowables + document templates = Rendro's flow model | Two competing APIs (canvas vs Platypus); global stylesheet mutation is leaky | One composition model (the 3 rungs), no second imperative path |
| **WeasyPrint** (Python) | Designers reuse CSS | HTML/CSS semantics, heavier/less deterministic, browser-ish | Explicit Rendro anti-model (PROJECT out-of-scope) — determinism > CSS familiarity |
| **Typst** | **Named optional args + strong defaults; templates are functions you adapt** — the north star for "adapt an example" ergonomics | It's a whole new language (learning curve) | Rendro's `opts` keyword + defaults + 3-rung *is* this pattern in Elixir; lean into defaults so the toy call stays one line |
| **@react-pdf/renderer** (JS) | Component composition; props-with-defaults mental model | Flexbox layout; JS runtime → cross-version non-determinism; silent style coercion | Composition yes; silent coercion no — reject Float money loudly |
| **Gotenberg** | Trivial to call | Chromium-as-a-service: network dep, non-deterministic | Anti-model — Rendro's pure-Elixir determinism is the differentiator |
| **LaTeX invoice templates** | High craft; adopt-a-`.tex` | Legendarily opaque errors; fragile macro overrides (leaky internals) | The errors-as-product bar exists *because* of TeX; keep failures instructive |
| **Ecto changeset / `embedded_schema`** | `cast` + `validate_required` cleanly separates optional vs required; **additive fields need no migration**; "required is stronger than optional"; structured validation | Over-nesting embeds gets verbose | `validate_data!/1` is Rendro's `cast`+`validate_required`; grow the map additively (exactly A2) |
| **Phoenix generators** | Generate code you own and adapt | Scaffolds can drift from library | Blueprint for Milestone C's "copy the snippet"; recipes are the runtime analogue |
| **Req** | Open keyword opts with great defaults; **adding an option never breaks callers** | — | Keep `opts` open; never require a previously-optional key |
| **Oban** | Rich opts with defaults (unique, backoff) | Option surface sprawled across versions | Define the shape deliberately (esp. `Theme` in B); resist per-recipe config sprawl now |
| **Swoosh / Bamboo** | Inert `%Email{}` struct built by a pipeline + swappable adapter; helper builders; sensible defaults | — | Mirrors `%Rendro.Document{}` + `Rendro.Format` adapter tier; the inert-value-you-compose pattern is proven idiom |

**Extracted footguns to actively avoid:** over-configuration (Oban), breaking additive changes / renamed keys (avoid — never rename `items`→`lines`), leaky internals (Prawn boxes, LaTeX macros, the `struct!` KeyError in §5.1), and silent coercion (Float money → rounding — Rendro rejects it loudly).

**Extracted wins to bank:** named-args + defaults (Typst), `cast`/`validate_required` (Ecto), open opts + defaults (Req), inert struct + builder + adapter boundary (Swoosh/Bamboo), and the "generate/adapt an example you own" ergonomic (Phoenix gen / Typst).

---

## 7. Recommendations (LOCKED)

1. **Invoice A2 = additive layering, zero renames.** Keep `:id`/`:date`/`:items` frozen and byte-identical. Add optional `:issuer`, `:customer`, `:due_date`, `:terms`, `:currency`, `:totals`. Absent ⇒ not rendered.
2. **Per-value money opt-in.** `items[].price` as a bare number → legacy `"$#{price}"`. As a `%Decimal{}` → `Rendro.Format.money/1`. All new money fields (`:totals.*`) are Decimal-only and **reject Float instructively**. No hidden "rich mode" flag.
3. **Totals: validate, don't auto-render.** Emit the totals block only when `:totals` is present; validate it as a caller assertion with `Decimal.equal?/2` (`total == subtotal + tax − discount`; cross-check line sum only when items are Decimal). Reuse `Rendro.Recipes.Pagination` for keep-with-last-rows.
4. **Reuse the family shapes.** `customer`/`issuer`/`employer`/`venue`/`holder`/`account` all share `%{name: String.t(), ...}`. `period` = `%{from: Date, to: Date}`. `totals` = Receipt's map. Learn-once ergonomics.
5. **Add `Invoice.validate_data!/1`** (called first in `sections/2` and `document/2`), raising the four-part `ArgumentError` via `Pagination.type_name/1`. Additive strictness only — never reject a previously-working toy call. Payslip/Ticket get full validation from day one.
6. **Promote `Rendro.Format` to adapter tier with a 3-function surface** (`money/1`, `date/1`, `label/1`). Keep it locale-free; i18n stays at the recipe `opts` layer (`formatter/3`, `label_resolver/1`). Update `public_api.json` **and** the Phase-79 contract test's expected-hidden set (remove Format) — budget this in the plan; it is the highest-friction step.
7. **Payslip = Statement-shaped flow recipe** (net pay is the anchor). **Ticket = Certificate-shaped fixed-box recipe** (own geometry, no A4 numerics, single page, overflow → typed error). Both on the exact 3-rung signatures, both in `public_api.json` + `support_matrix.json` + the `Rendro.Recipes` facade.
8. **Fix the opts→struct leak now.** Adopt `Statement`'s `Keyword.take` whitelist in `Invoice`/`Payslip`/`Ticket` `page_template/1`. Keep top-level `opts` **open** (no allowlist) so B can add `:theme` additively. Format via `Pagination.formatter/3`, never `Rendro.Format` directly, so `:formatters`/`:labels`/`:theme` all ride one map.

---

## 8. Sanity-check verdict

**The A2/A3 approach is sound, low-risk, and squarely idiomatic — GREEN with two flags.** A2 is a textbook additive-evolution move: the family already demonstrates every pattern A2 needs (Decimal money, `totals` with `Decimal.equal?/2`, `customer` maps, `validate_data!/1`, shared pagination), so A2 is mostly *porting proven code into `invoice.ex`* rather than inventing anything. Backward-compat is structurally guaranteed because the legacy keys are frozen and every new key/behavior is gated on presence or on a `%Decimal{}` value — the toy call provably re-walks the old code paths and emits identical bytes. Payslip slots in as a Statement sibling; Ticket generalizes Certificate's geometry-owned single-page pattern, so the 3-rung contract holds without strain.

**DX risks to manage (both cheap to mitigate):**

- **Risk 1 — the `Rendro.Format` promotion is a cross-cutting edit, not a one-liner.** Phase 78 deliberately hid `Format` and Phase 79 asserts it stays hidden. If the plan edits only `format.ex` + the manifest but not `public_api_contract_test.exs`, CI goes red at the drift lane. Mitigation: treat "edit the contract test's hidden set" as an explicit plan task. (This is the single most likely source of a surprised red build in Milestone A.)
- **Risk 2 — money-type ambiguity on `items[].price`.** The "bare number = legacy, Decimal = rich" per-value rule is the only mildly magical part of the design. It is defensible (local, predictable, additive) but must be documented loudly in the Invoice `@moduledoc` with a before/after example, or a caller mixing integer and Decimal prices in one `items` list could be surprised by mixed `$200` / `$3,000.00` formatting. Mitigation: one doc example + an A5 stress cell covering a mixed-price line list.

Neither risk touches determinism, the core pipeline, or backward-compat. The opts-leak fix (§5.1) is a genuine latent bug this milestone should fix regardless of B, and doing so pre-clears B's `theme:` seam for free. **Proceed as specified.**

---

## Sources

- [Prawn — invoice example (devsigner)](https://github.com/devsigner/prawn-invoice-example) · [prawn-table example](https://github.com/prawnpdf/prawn-table/wiki/Prawn-Table-Example) · [prawn_invoice (westonganger)](https://github.com/westonganger/prawn_invoice) · [invoice_printer (strzibny)](https://github.com/strzibny/invoice_printer)
- [Ecto — Embedded Schemas guide](https://hexdocs.pm/ecto/embedded-schemas.html) · [Ecto — Data mapping and validation](https://hexdocs.pm/ecto/data-mapping-and-validation.html) · [Ecto.Changeset](https://hexdocs.pm/ecto/Ecto.Changeset.html)
- In-repo primary sources: `lib/rendro/recipes/{invoice,receipt,statement,branded_invoice,certificate,pagination}.ex`, `lib/rendro/format.ex`, `priv/public_api.json`, `priv/schemas/public_api.schema.json`, `test/rendro/recipes/invoice_test.exs`, `test/rendro/recipes_facade_drift_test.exs`, `.planning/PROJECT.md` (Key Decisions), and the Milestone-A spec `~/.claude/plans/btw-what-is-rendro-spicy-giraffe.md`.
- Prior-art knowledge (Typst named-args/templates, ReportLab Platypus, WeasyPrint, @react-pdf/renderer, Gotenberg, LaTeX invoice templates, Req/Oban/Swoosh/Bamboo/Phoenix generators): from training knowledge, cross-checked against the above where retrievable.
