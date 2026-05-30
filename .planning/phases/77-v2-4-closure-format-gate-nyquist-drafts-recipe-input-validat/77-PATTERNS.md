# Phase 77: v2.4 Closure — Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 5 (all MODIFIED — closure phase, no new files)
**Analogs found:** 5 / 5 (all analogs are in-file or sibling-recipe — strongest possible match)

> **Closure-phase note:** No new files are created. Every "analog" here is a pattern that
> already exists *in the same file* or in a *sibling recipe* (`statement.ex`). The executor
> replicates the existing structured-`ArgumentError` template rather than inventing one.
> The canonical template lives in `lib/rendro/recipes/statement.ex`.

> **Audit line-number drift (verified during mapping):** the audit cited line numbers that
> are slightly off against the current tree. Use the corrected pointers below:
> - D-09 discarded reduce: audit said `705-711`; actual is `statement.ex:676-682` —
>   the `Enum.map_reduce` in `maybe_validate_summary!/1` whose `rows` result is dropped via
>   `_ = rows` (line 682). The `fold_balance/2` `map_reduce` at `407-410` is **correct** (rows ARE used) — do NOT touch it.
> - D-09 capacity comment: `statement.ex:293-297` (confirmed).
> - D-09 mean-vs-median + `14.4`: the magic `14.4` is at `statement.ex:311` (inside
>   `typical_row_h`), with the surrounding comment at `308-309`. Audit's `376-383/380`
>   does not match current content — `376-383` is the block/section emit. Map `14.4` → named attribute at line 311.
> - D-07 dead binding: `certificate.ex:180` (`_content_w`, confirmed).

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `lib/rendro/recipes/statement.ex` | recipe (validation + builder) | transform / request-response | **in-file** `validate_period!/1`, `validate_lines!/1` (lines 498-520) | canonical (self) |
| `lib/rendro/recipes/receipt.ex` | recipe (validation + builder) | transform / request-response | `statement.ex` `validate_period!/1` + `validate_line_date!/2` | exact (sibling) |
| `lib/rendro/recipes/certificate.ex` | recipe (validation + builder) | transform / request-response | `statement.ex` `validate_line_date!/2` + `validate_required_keys!/1` | exact (sibling) |
| `test/rendro/recipes/statement_test.exs` | test | request-response (negative path) | **in-file** "Float line amount raises" test (lines 439-448) | canonical (self) |
| `mix.exs` | config (ExDoc) | config | **in-file** `extras` / `groups_for_extras` block (lines 106-128) | canonical (self) |

## Shared / Canonical Pattern (replicated everywhere)

### Structured-`ArgumentError` validation template
**Source:** `lib/rendro/recipes/statement.ex` — guard-failing clause + heredoc body.
**Apply to:** every new validation clause in `statement.ex` (D-05), `receipt.ex` (D-06), `certificate.ex` (D-07).

The pattern is **two function clauses**: a passing guard clause that returns `:ok`, then a
catch-all clause that raises the `What:/Where:/Why:/Next:` heredoc. The `Why:` line names the
received type via `Rendro.Recipes.Pagination.type_name/1`.

`statement.ex:498-509` (`validate_period!/1` — the map-shape analog, copy for `:account`/`:customer`):

```elixir
defp validate_period!(%{from: %Date{}, to: %Date{}}), do: :ok

defp validate_period!(value) do
  raise ArgumentError, """
  Rendro.Recipes.Statement.document/2 — invalid :period shape.

  What:  :period must be a map with :from and :to Date values.
  Where: Rendro.Recipes.Statement.validate_data!/1
  Why:   Received: #{inspect(value)}.
  Next:  Use %{from: ~D[YYYY-MM-DD], to: ~D[YYYY-MM-DD]}.
  """
end
```

`statement.ex:576-587` (`validate_line_date!/2` — the `%Date{}` analog, copy for Receipt/Certificate `:date`):

```elixir
defp validate_line_date!(%Date{}, _idx), do: :ok

defp validate_line_date!(value, idx) do
  raise ArgumentError, """
  Rendro.Recipes.Statement.document/2 — invalid line :date at index #{idx}.

  What:  Each line's :date must be a %Date{} struct.
  Where: Rendro.Recipes.Statement.validate_data!/1
  Why:   lines[#{idx}].date = #{inspect(value)}.
  Next:  Use the ~D[YYYY-MM-DD] sigil or Date.new!/3.
  """
end
```

`statement.ex:589-600` (`validate_line_description!/2` — the `is_binary` analog, copy for Certificate `:body`):

```elixir
defp validate_line_description!(value, _idx) when is_binary(value), do: :ok

defp validate_line_description!(value, idx) do
  raise ArgumentError, """
  ...
  What:  Each line's :description must be a string.
  ...
  Why:   lines[#{idx}].description = #{inspect(value)}.
  Next:  Pass a binary string, e.g. "Invoice #1".
  """
end
```

**`type_name/1` helper** (`lib/rendro/recipes/pagination.ex:76-82`) — already used in `statement.ex:493, 517, 622`. Reuse verbatim in the `Why:` line whenever the message states the received type:

```elixir
def type_name(value) when is_binary(value), do: "String"
def type_name(value) when is_integer(value), do: "Integer"
def type_name(value) when is_float(value), do: "Float"
def type_name(value) when is_atom(value), do: "Atom"
def type_name(value) when is_list(value), do: "List"
def type_name(value) when is_map(value), do: "Map"
def type_name(_value), do: "Unknown"
```

## Pattern Assignments

### `lib/rendro/recipes/statement.ex` (recipe — D-05 + D-09)

**Analog:** in-file (self).

**D-05 — `:account`/`:customer` shape validation.**
Currently `validate_data!/1` (lines 443-451) validates `period`, `opening_balance`, `lines` but
**not** `:account` — a non-map `:account` flows to `header_section/2` line 257
(`Map.get(account, :name, "")`) and raises `BadMapError`. Add a `validate_account!/1` clause
modeled on `validate_period!/1` and call it inside `validate_data!/1`:

```elixir
# Add to validate_data!/1 body (after validate_period!, before validate_lines!):
defp validate_data!(data) do
  validate_required_keys!(data)
  validate_opening_balance!(data.opening_balance)
  validate_period!(data.period)
  validate_account!(data.account)      # <-- NEW
  validate_lines!(data.lines)
  ...
end

# New clause — copy validate_period!/1 shape:
defp validate_account!(%{name: name}) when is_binary(name), do: :ok

defp validate_account!(value) do
  raise ArgumentError, """
  Rendro.Recipes.Statement.document/2 — invalid :account shape.

  What:  :account must be a map with a string :name.
  Where: Rendro.Recipes.Statement.validate_data!/1
  Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
  Next:  Use %{name: "Acme Corp"}.
  """
end
```
> Discretion (per D-05/CONTEXT): whether to also enforce `:name` presence vs. only map-shape.
> The audit's failure mode is "non-map raises `BadMapError`", so a map-shape guard is the floor.
> `header_section/2` uses `Map.get(account, :name, "")`, so a missing `:name` already degrades gracefully —
> prefer the map-shape guard and let the planner decide whether `:name` is also required.

**D-09 cosmetic cleanups (must NOT change rendered output):**

1. **Capacity comment** `statement.ex:293-297` — currently claims the formula mirrors
   `measure.ex body_capacity/1` with full header+footer subtraction. Audit: the real behavior is a
   conservative ~8% under-pack with no overflow risk. Rewrite the comment only; leave
   `capacity = @body_height - @header_height - @footer_height` (line 297) numerically unchanged.

2. **`14.4` magic number** `statement.ex:311` — extract to a named module attribute near the
   other geometry constants (lines 86-112). Comment at 308-309 ("Estimate a typical row height")
   is fine; if it implies mean-vs-median misleadingly, tighten it.
   ```elixir
   # near top, with other @-constants:
   @default_row_height 14.4   # fallback typical row height (pt) when no rows measured

   # line 310-314 becomes:
   typical_row_h =
     if Enum.empty?(row_heights) do
       @default_row_height
     else
       Enum.sum(row_heights) / length(row_heights)
     end
   ```
   > Discretion (D-09): exact attribute name is the planner's call.

3. **Discarded `map_reduce`** `statement.ex:676-682` — in `maybe_validate_summary!/1`, the
   `Enum.map_reduce` builds `rows` only to discard them (`_ = rows`, line 682). Only
   `derived_closing` is used. Replace with `Enum.reduce`:
   ```elixir
   # BEFORE (676-682):
   {rows, derived_closing} =
     Enum.map_reduce(lines, ob, fn %{amount: amt}, bal ->
       nb = Decimal.add(bal, amt)
       {nb, nb}
     end)
   _ = rows

   # AFTER (mirror maybe_validate_closing_balance!/1 line 656, which already uses reduce):
   derived_closing =
     Enum.reduce(lines, ob, fn %{amount: amt}, bal -> Decimal.add(bal, amt) end)
   ```
   > **Do NOT touch `fold_balance/2` (lines 405-413)** — its `map_reduce` result *is* used.

---

### `lib/rendro/recipes/receipt.ex` (recipe — D-06)

**Analog:** `statement.ex` `validate_period!/1` (map shape) + `validate_line_date!/2` (`%Date{}`).

**Current state:** `validate_data!/1` (lines 373-378) validates `required_keys`, `lines`, and
optional `totals` — but **not** `:customer` or `:date`.
- `:customer` (non-map) → `header_section/2` line 248 `Map.get(customer, :name, "")` raises `BadMapError`.
- `:date` (non-`%Date{}`) → `header_section/2` line 256 `fmt_date.(date)` → `Rendro.Format.date/1`
  raises `FunctionClauseError`.

**Replicate:** add `validate_customer!/1` and `validate_date!/1` clauses (Receipt-namespaced
`Where:` lines) and call them in `validate_data!/1`:

```elixir
defp validate_data!(data) do
  validate_required_keys!(data)
  validate_customer!(data.customer)   # <-- NEW (copy statement validate_account!/1)
  validate_date!(data.date)           # <-- NEW (copy statement validate_line_date!/2)
  validate_lines!(data.lines)
  maybe_validate_totals!(data)
  :ok
end

defp validate_customer!(%{name: name}) when is_binary(name), do: :ok
defp validate_customer!(value) do
  raise ArgumentError, """
  Rendro.Recipes.Receipt.document/2 — invalid :customer shape.

  What:  :customer must be a map with a string :name.
  Where: Rendro.Recipes.Receipt.validate_data!/1
  Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
  Next:  Use %{name: "Acme Corp"}.
  """
end

defp validate_date!(%Date{}), do: :ok
defp validate_date!(value) do
  raise ArgumentError, """
  Rendro.Recipes.Receipt.document/2 — invalid :date type.

  What:  :date must be a %Date{} struct.
  Where: Rendro.Recipes.Receipt.validate_data!/1
  Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
  Next:  Use the ~D[YYYY-MM-DD] sigil or Date.new!/3.
  """
end
```

**WR-01..06 follow-ups in `maybe_validate_totals!/1` (lines 476-525):**
- The `:totals.total` branch (496-522) recomputes `expected_total` with optional tax/discount and
  validates via `Decimal.equal?/2`. The audit notes this is **asymmetric** vs `:subtotal` (482-494) —
  planner should make the total check shape-consistent with the subtotal check, not add new behavior.
- Brand validation does not apply to Receipt (Certificate-only) — the "fragile clause ordering"
  note (WR-01..06) refers to `certificate.ex` `validate_brand!/1`, see below.

---

### `lib/rendro/recipes/certificate.ex` (recipe — D-07 + D-09)

**Analog:** `statement.ex` `validate_line_date!/2` (`%Date{}`) + `validate_line_description!/2` (`is_binary`).

**Current state:** `validate_data!/1` (lines 200-238) checks required keys (`:title`, `:recipient`,
`:date`), a 2000-byte body-length cap, and `validate_brand!/1`. It does **not** type-check:
- `:date` — consumed at `body_section/3` line 190 `fmt_date.(data.date)` → raises `FunctionClauseError` on non-`%Date{}`.
- `:body` — consumed at line 189 `Rendro.text(body_text, ...)`; line 225 only checks length
  *when* `is_binary(body)`, so a non-binary `:body` silently skips the guard and fails downstream.

**Replicate:** add `%Date{}` and `is_binary` guard clauses (Certificate-namespaced). Insert the
`:date` check in `validate_data!/1`, and convert the existing `if is_binary(body)` length check
into a binary-type guard + length guard:

```elixir
# inside validate_data!/1, after the missing-keys block:
validate_date!(data.date)               # <-- NEW

body = Map.get(data, :body, "")
validate_body!(body)                    # <-- NEW (type) — keep the 2000-byte cap inside it

# new clauses:
defp validate_date!(%Date{}), do: :ok
defp validate_date!(value) do
  raise ArgumentError, """
  Rendro.Recipes.Certificate.document/2 — invalid :date type.

  What:  :date must be a %Date{} struct.
  Where: Rendro.Recipes.Certificate.validate_data!/1
  Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
  Next:  Use the ~D[YYYY-MM-DD] sigil or Date.new!/3.
  """
end

defp validate_body!(body) when is_binary(body) and byte_size(body) > 2000 do
  raise ArgumentError, """ ... (existing 2000-byte message, lines 226-234) """
end
defp validate_body!(body) when is_binary(body), do: :ok
defp validate_body!(value) do
  raise ArgumentError, """
  Rendro.Recipes.Certificate.document/2 — invalid :body type.

  What:  :body must be a string.
  Where: Rendro.Recipes.Certificate.validate_data!/1
  Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
  Next:  Pass a binary string (max 2000 bytes).
  """
end
```
> **`validate_brand!/1` clause ordering (WR-01..06)** — lines 240-257 are guard-ordered
> `nil` → full-match → `%{font_name:}` bad → `%{logo_name:}` bad → catch-all. These existing
> brand-error messages are **single-line** (not the `What:/Where:/Why:/Next:` template). The planner
> may leave them or upgrade them to the heredoc template for consistency; the audit only flags
> ordering fragility, not the message format.

**D-09 dead binding** `certificate.ex:180` — `_content_w = template.width - template.margin_left -
template.margin_right` is computed and never used (the `_` prefix already silences the warning, but
the audit wants it removed for clarity). Delete the binding (and the 2-line comment at 178-179 that
references it). No output change.

---

### `test/rendro/recipes/statement_test.exs` (test — D-08 analog source)

**Analog:** in-file, the `describe "V8: validate_data!/1 rejects malformed input"` block
(lines 430-513). The canonical negative-path shape (lines 439-448):

```elixir
test "Float line amount raises ArgumentError mentioning Decimal" do
  data = %{
    fixture_data(0)
    | lines: [%{date: ~D[2026-05-01], description: "X", amount: 100.0}]
  }

  assert_raise ArgumentError, ~r/Decimal|float/i, fn ->
    Statement.document(data)
  end
end
```

Plus the simpler shape-only form (lines 456-462):

```elixir
test "malformed period raises ArgumentError" do
  data = fixture_data(0) |> Map.put(:period, "2026-05")

  assert_raise ArgumentError, fn ->
    Statement.document(data)
  end
end
```

**Replicate for D-08** in `receipt_test.exs` and `certificate_test.exs`: one
`assert_raise ArgumentError, ~r/.../, fn -> Recipe.document(bad_data) end` per new validation clause —
start from a valid fixture, `Map.put` the malformed key, assert the raise. Use a `~r/.../i` matching
the key name (e.g. `~r/customer/i`, `~r/date/i`, `~r/body/i`) to bind the test to the message, mirroring
`~r/balance/i` (line 474) and `~r/closing_balance/i` (line 500). Tests must keep the full suite green
and the tree `mix format`-clean (D-08/D-10).

> **No `receipt_test.exs`/`certificate_test.exs` negative-path block was searched/extracted** —
> the planner adds the new blocks there; this file (`statement_test.exs`) is purely the *style* analog.

---

### `mix.exs` (config — D-03 ExDoc wiring + D-01/D-10 aliases)

**Analog:** in-file `docs/0` `extras` + `groups_for_extras` (lines 106-128).

**D-03 — wire `guides/user_flows_and_jtbd.md`.** Add the guide to `extras` (lines 106-114) AND to a
`groups_for_extras` group (lines 115-128). Existing structure:

```elixir
extras: [
  "README.md",
  "guides/integrations.md",
  "guides/branding.md",
  "guides/api_stability.md",
  "guides/viewer_evidence.md",
  "guides/page_primitive.md",
  "guides/recipes.md"          # <-- add "guides/user_flows_and_jtbd.md" here
],
groups_for_extras: [
  Guides: [
    "guides/branding.md",
    "guides/integrations.md"   # <-- candidate group for the JTBD guide
  ],
  Policies: [...],
  "Recipes & Primitives": [
    "guides/page_primitive.md",
    "guides/recipes.md"
  ]
],
```
> Discretion (D-03/CONTEXT): which group the JTBD guide lands in (`Guides` is the natural home).
> Also consider adding it to `skip_undefined_reference_warnings_on:` (lines 96-104) if it references
> modules, consistent with `recipes.md`/`page_primitive.md` there. **If wiring trips a docs-contract
> test** (`test/docs_contract/recipes_claims_test.exs`), tighten the guide's language to stay within
> `priv/support_matrix.json` rather than dropping the wiring (D-03).

**D-01/D-10 — aliases** (`mix.exs:61-73`): the `ci` alias runs `format --check-formatted` **first**:
```elixir
defp aliases do
  [
    ci: [
      "format --check-formatted",   # <-- the gate that is currently RED (D-01)
      "hex.build",
      "compile --warnings-as-errors",
      "test",
      ...
    ]
  ]
end
```
> There is **no separate `format` alias** — `mix format` is the built-in task. The terminal gate
> (D-10) is `mix format --check-formatted` exiting 0 from a clean tree, then `mix ci` passing its
> first step. No edit to the aliases block is required for D-01; the fix is running `mix format` and
> committing. Mapped here only because CONTEXT D-01/D-10 asked to note it.

## No Analog Found

None. Every modified file has an in-file or sibling-recipe analog. This is a closure phase replicating
an already-canonical pattern.

## Metadata

**Analog search scope:** `lib/rendro/recipes/` (statement, receipt, certificate, pagination),
`test/rendro/recipes/statement_test.exs`, `mix.exs`.
**Files scanned:** 6 read in full + 2 grep-targeted.
**Pattern extraction date:** 2026-05-29
