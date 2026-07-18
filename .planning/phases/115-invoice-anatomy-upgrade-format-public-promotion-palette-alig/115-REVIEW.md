---
phase: 115-invoice-anatomy-upgrade-format-public-promotion-palette-alig
reviewed: 2026-07-18T18:51:47Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - lib/mix/tasks/rendro/api.gen.ex
  - lib/rendro.ex
  - lib/rendro/cell.ex
  - lib/rendro/format.ex
  - lib/rendro/pipeline/paginate.ex
  - lib/rendro/recipes/invoice.ex
  - lib/rendro/table.ex
  - priv/public_api.json
  - test/docs_contract/public_api_contract_test.exs
  - test/rendro/public_api/manifest_test.exs
  - test/rendro/recipes/invoice_byte_identity_test.exs
  - test/rendro/recipes/invoice_opts_threading_test.exs
  - test/rendro/recipes/invoice_test.exs
  - test/rendro/table_byte_identity_test.exs
  - test/rendro/table_cell_align_test.exs
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 115: Code Review Report

**Reviewed:** 2026-07-18T18:51:47Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

This phase adds invoice anatomy fields (issuer/customer/due_date/terms/totals) with
"errors-as-product" validation (INV-06), promotes `Rendro.Format` to a public
adapter-tier module, adds opt-in `cell_align: :right` to tables/cells (INV-05), and
threads a `:palette` seam through the invoice recipe (INV-07). Byte-identity goldens
guard the toy invoice path and the no-`cell_align` table path.

The core logic is generally sound and well-tested. `Rendro.Format.money/1` rounding,
grouping, and negative-wrapping are correct; the Decimal-vs-Float type gating and the
`Decimal.equal?/2` (not `==`) totals reconciliation are done right; float prices are
stringified before `Decimal.new/1` which correctly avoids float drift; and the
`cell_align` right-offset is properly gated so the default (`:left`) path stays
byte-identical.

Two robustness defects stand out. First, the "errors-as-product" contract (INV-06)
is only partially enforced: line-item shape is essentially unvalidated, so malformed
items produce raw `KeyError`/`BadMapError`/`FunctionClauseError` instead of the
instructive `ArgumentError` the surrounding fields all raise. Second, the right-align
offset has an unsafe fallback that pushes non-text cell content off the right edge.
Neither is a security or data-loss issue, so both are WARNINGs.

## Warnings

### WR-01: Line-item shape is not validated — malformed items crash raw instead of erroring as product (INV-06 gap)

**File:** `lib/rendro/recipes/invoice.ex:500-525`, `:218-226`, `:628-630`

**Issue:** The recipe validates `:issuer`, `:customer`, `:due_date`, `:terms`, and
`:totals` shapes with instructive `ArgumentError`s, and validates that `:items` is a
list — but it never validates the shape of the individual line items.
`validate_item_price!/2` only rejects `%Decimal{}`; its catch-all
`validate_item_price!(_price, _idx), do: :ok` accepts *anything else*, including a
missing price (`nil`), strings, atoms, and lists. Consequences:

- A missing/non-numeric `:price` passes validation, then either renders silently as
  `"$"` / `"$abc"` in `body_section/2` (`"$#{item.price}"`, line 226), or crashes in
  `item_line_total/1` (line 628, `Decimal.new(to_string(price))` → `Decimal.Error`)
  when `:totals` is present.
- A missing or non-integer `:qty` crashes at `Integer.to_string(item.qty)` (line 225)
  with `ArgumentError`/`KeyError`, and at `item_line_total/1` with a
  `FunctionClauseError` (pattern requires `%{qty: qty, price: price}`).
- A non-map item (e.g. `items: [1, 2]`) raises `BadMapError` at
  `Map.get(item, :price)` inside `validate_items!/1` (line 503).

This directly contradicts the INV-06 "errors-as-product" goal that the rest of the
module is built around: the toy path and the optional-field paths raise clean,
instructive errors, but the most common data (line items) does not.

**Fix:** Validate each item in `validate_items!/1` before use — presence of `:name`,
`:qty`, `:price`, that the item is a map, that `:qty` is an integer, and that
`:price` is a bare number (Integer or Float). For example:

```elixir
defp validate_items!(items) do
  items
  |> Enum.with_index()
  |> Enum.each(fn {item, idx} -> validate_item!(item, idx) end)
end

defp validate_item!(item, idx) when not is_map(item) do
  raise ArgumentError, "...index #{idx}: item must be a map %{name:, qty:, price:}; got #{inspect(item)}"
end

defp validate_item!(item, idx) do
  unless is_binary(Map.get(item, :name)), do: raise ArgumentError, "...index #{idx}: :name must be a string"
  unless is_integer(Map.get(item, :qty)),  do: raise ArgumentError, "...index #{idx}: :qty must be an integer"
  validate_item_price_present!(Map.get(item, :price), idx)  # reject nil/Decimal/non-number
end
```

### WR-02: `right_align_offset/1` fallback pushes non-text right-aligned cell content off the right edge

**File:** `lib/rendro/pipeline/paginate.ex:635-648`

**Issue:** For a `cell_align: :right` cell, the x-offset is
`max((col_w || 0) - measured_content_width(cell), 0)`. `measured_content_width/1`
returns `0` for any cell whose content is not a measured-text block (the
`measured_content_width(_cell), do: 0` fallback, line 648) — e.g. an image cell or a
nested-block cell. When the fallback fires, the offset becomes the *full column
width*, so the cell's `x` is set to the right edge of the column
(`x + col_w`) and its content renders past the column boundary. That is an overflow /
mis-placement, not the intended "leave in place" behavior. The default (`:left`) path
is unaffected, and text cells (the common case) measure correctly, so this only bites
when the opt-in `cell_align: :right` is applied to a column containing non-text cells.

**Fix:** Treat "content width unknown" as "no offset" rather than "offset by the whole
column." Either widen `measured_content_width/1` to cover the block/image cases, or
short-circuit the offset when the width is indeterminate:

```elixir
defp right_align_offset(%Rendro.Cell{width: col_w} = cell) do
  case measured_content_width(cell) do
    w when is_number(w) and w > 0 -> max((col_w || 0) - w, 0)
    _ -> 0  # unknown content width → do not shift (stay left-flush)
  end
end
```

## Info

### IN-01: `document/2` validates the data map twice

**File:** `lib/rendro/recipes/invoice.ex:173-176`

**Issue:** `document/2` calls `validate_data!(data)` (line 174) and then calls
`sections(data, opts)` (line 176), which itself calls `validate_data!(data)` (line
148). The full validation pass — including the O(n) item scan and the totals
reconciliation reduce over all items — runs twice for every `document/2` call.
Harmless but redundant.

**Fix:** Drop the explicit `validate_data!/1` in `document/2` and rely on the one in
`sections/2`, or extract an internal `build_sections/2` that assumes pre-validated
data and have both public entry points validate exactly once.

### IN-02: Body chunking capacity double-subtracts header/footer already excluded from the body region

**File:** `lib/rendro/recipes/invoice.ex:239`

**Issue:** `@body_height` (line 41) is already computed as
`page_height - 2*margin - header_height - footer_height`, i.e. the body region height
*after* removing the header and footer bands. `body_section/2` then computes
`capacity = @body_height - @header_height - @footer_height` (line 239), subtracting the
header and footer heights a second time. The result under-fills each table page by
~80pt, producing more pages than necessary. It is conservative (never overflows, so
not a correctness bug), and the "kept with the last rows" test (invoice_test.exs:337)
bakes in this exact formula, but the formula does not match the geometry its own
comment describes.

**Fix:** If the intent is to reserve the body region's full height, use
`capacity = @body_height` (minus only the measured table `header_h` and the totals
reservation). If the double subtraction is deliberately mirroring Receipt/Statement,
add a comment explaining why the already-excluded bands are subtracted again, and
re-baseline the boundary test accordingly.

### IN-03: `Rendro.Format.label/1` is now public but raises `FunctionClauseError` on unsupported keys

**File:** `lib/rendro/format.ex:108`

**Issue:** `label/1` has only a guarded head
(`when is_map_key(@labels, key)`) and no fallback clause. Now that `Rendro.Format` is
a public adapter-tier module, `Rendro.Format.label(:unknown)` raises a bare
`FunctionClauseError` rather than a clean, instructive error naming the supported keys.
`money/1` and `date/1` are similarly strict (raise on non-`Decimal`/non-`Date`), which
is arguably acceptable for a documented contract, but `label/1` is the most likely to
be called with a caller-chosen atom.

**Fix:** Optionally add a catch-all that raises an `ArgumentError` listing the
supported keys, e.g. `def label(key), do: raise ArgumentError, "unsupported label
#{inspect(key)}; supported: #{inspect(Map.keys(@labels))}"`. If the strict clause is
intentional, document that unsupported keys raise.

---

_Reviewed: 2026-07-18T18:51:47Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
