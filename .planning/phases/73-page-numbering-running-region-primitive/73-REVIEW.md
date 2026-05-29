---
phase: 73-page-numbering-running-region-primitive
reviewed: 2026-05-29T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - lib/rendro.ex
  - lib/rendro/pipeline/compose.ex
  - lib/rendro/pipeline/measure.ex
  - lib/rendro/pipeline/paginate.ex
  - lib/rendro/running_content.ex
  - lib/rendro/section.ex
  - test/rendro/deterministic_test.exs
  - test/rendro/flow_test.exs
  - test/rendro/pipeline/measure_test.exs
  - test/rendro/pipeline/paginate_test.exs
  - test/rendro_builders_test.exs
findings:
  critical: 3
  warning: 3
  info: 2
  total: 8
status: issues_found
---

# Phase 73: Code Review Report

**Reviewed:** 2026-05-29
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Phase 73 adds `{{page_number}}`/`{{total_pages}}` token substitution, `RunningContent` fn-blocks,
and per-page suppression to the pagination pipeline. The determinism contract (D-09/D-10/D-11)
is mostly sound: `replace_page_numbers/3` correctly freezes run widths and block heights, and
`body_capacity` is computed from declared geometry before pagination runs.

Three blockers were found: a `raise`-inside-`try/catch` mismatch that lets a running-content
exception escape as an unhandled crash rather than a structured `{:error, ...}` tuple; an
incorrect overlap predicate for the header region in `body_capacity/1` that can under- or
over-subtract capacity when the header is positioned entirely below the body start; and a silent
last-writer-wins collision in `compose.ex` when two sections target the same region with
different `suppress_on` values.

Three warnings were found: the `flow_layout/1` fallback uses a naive subtract-always formula
that diverges from the overlap-aware formula in `measure.ex`; a `Rendro.Text` block that passes
through `replace_page_numbers/3` is mutated but its `block.height` and `block.width` are also
left unchanged (correct per D-10), but the `Rendro.Text` path does not update `block.height` —
this is consistent but undocumented; and `maybe_validate_region_fit` is called after
`evaluate_fn_blocks` which means blocks returned by user functions are validated for fit but
the `RunningContent` wrapper block's own height (which was measured before evaluation) is used
for nothing, silently discarded.

---

## Critical Issues

### CR-01: `evaluate_fn_blocks` re-raises `Rendro.Error` which escapes the outer `try/catch`

**File:** `lib/rendro/pipeline/paginate.ex:473-477`

**Issue:** The outer `paginate_flow/1` function wraps work in a `try do ... catch` block
(line 22/52) that only catches **throw** expressions (`{:error, :content_overflow, details}` etc.).
Elixir's `catch` clause in a `try` block does NOT catch `raise`-d exceptions — those require
a `rescue` clause.

Inside `evaluate_fn_blocks/3`, when a user function raises, the code rescues and then
`raise`s a `Rendro.Error` struct (line 475). Because `Rendro.Error` is not a native Erlang
term, Elixir wraps it in an ErlangError when thrown with `raise`, which does not match any
catch clause. The result: a user function error produces an unhandled `** (Rendro.Error) ...`
crash instead of `{:error, %Rendro.Error{}}`.

Verified empirically:
```elixir
try do
  raise RuntimeError, message: "test"
catch
  {:error, _} -> :caught  # never reached
end
# => ** (RuntimeError) test
```

The rescue in `evaluate_fn_blocks` correctly builds a structured `Rendro.Error`, but then
re-raises it instead of returning it as a value or converting it to a throw that the outer
handler can catch.

**Fix:** Either convert the re-raise to a throw so the outer `catch` can handle it, or add a
`rescue` arm in `paginate_flow/1`. The throw approach is the least invasive and consistent with
the existing error-propagation pattern in this module:

```elixir
# In evaluate_fn_blocks/3 — replace raise with throw:
rescue
  reason ->
    error = Rendro.Error.from_stage(
      :paginate,
      {:running_content_error, inspect(reason)},
      %{details: %{page_num: page_num}}
    )
    throw({:error, :running_content_error, error})
```

Then add a matching catch arm in `paginate_flow/1`:
```elixir
catch
  {:error, :content_overflow, details} ->
    {:error, Rendro.Error.from_stage(:paginate, :content_overflow, %{details: details})}

  {:error, :unsupported_table_split_policy, details} ->
    {:error, Rendro.Error.from_stage(:paginate, :unsupported_table_split_policy, %{details: details})}

  {:error, :running_content_error, error} ->
    {:error, error}
```

Alternatively, add a `rescue` clause to the outer `try` in `paginate_flow/1` to catch any
re-raised `Rendro.Error` and return it as `{:error, error}`.

---

### CR-02: Header overlap predicate in `body_capacity/1` is incomplete — can over-subtract when header is below body

**File:** `lib/rendro/pipeline/measure.ex:449-454`

**Issue:** The overlap detection for the header region uses:

```elixir
body_y < header_region.y + header_region.height
```

A correct 1-D interval overlap test for `[body_y, body_y + body_h)` vs
`[header_y, header_y + header_h)` requires BOTH:
- `body_y < header_y + header_h` (body starts before header ends)
- `header_y < body_y + body_h` (header starts before body ends)

The second condition is missing. This means a header positioned entirely below the body's
bottom edge still satisfies the condition, causing its full height to be subtracted from
`body_capacity`.

**Example:** body at y=100, height=400 (bottom=500). Header at y=600, height=30. The
check `body_y(100) < header_region.y(600) + header_region.height(30) = 630` is `true`,
so `header_h = 30` is subtracted — but the header does not overlap the body at all.
This over-reduces `body_capacity` by 30, which can push documents into overflow when the
body has enough room.

The footer condition (line 459: `body_y + body_h >= footer_region.y`) also has the same
class of incompleteness: it does not check `footer_region.y + footer_region.height > body_y`,
so a footer positioned entirely above the body's top edge would also be subtracted. In
practice, templates are declared with sensible geometry so this is less likely to trigger, but
the header case is a real hazard for non-standard template layouts.

**Fix:**

```elixir
header_h =
  if header_region && is_number(header_region.height) && is_number(header_region.y) &&
       is_number(body_y) && is_number(body_h) &&
       body_y < header_region.y + header_region.height &&
       header_region.y < body_y + body_h do
    header_region.height
  else
    0
  end

footer_h =
  if footer_region && is_number(footer_region.height) && is_number(footer_region.y) &&
       is_number(body_y) && is_number(body_h) &&
       body_y + body_h > footer_region.y &&
       footer_region.y + footer_region.height > body_y do
    footer_region.height
  else
    0
  end
```

---

### CR-03: Multiple sections targeting the same region with different `suppress_on` silently loses all but the last

**File:** `lib/rendro/pipeline/compose.ex:90-94`

**Issue:** `region_suppress_on` is built with `Map.new/1` applied to a list of
`{region_atom, suppress_on_value}` tuples. `Map.new/1` on a list with duplicate keys keeps
the last value; earlier entries are discarded without warning.

If two sections both target `:footer` but one has `suppress_on: :first` and another has no
suppression (i.e., `suppress_on: {:pages, [3]}`), composing them results in one of the two
suppress rules being silently discarded. Because suppression applies to the region as a
whole (not per-section), the "last wins" behavior is non-obvious and makes multi-section
documents with per-section suppression unpredictable.

Additionally, D-07 specifies that suppress_on is a section-level attribute, but the
implementation collapses it to region-level, meaning all sections targeting the same region
share a single suppress_on value. This is a design deviation not documented in the code.

**Fix — minimal (guard against silent loss):** Detect duplicates and raise an
`ArgumentError` when two sections targeting the same region supply conflicting `suppress_on`
values:

```elixir
region_suppress_on =
  doc.sections
  |> Enum.filter(&(&1.suppress_on != nil))
  |> Enum.reduce(%{}, fn section, acc ->
    region = section.region || :body
    case Map.fetch(acc, region) do
      {:ok, existing} when existing != section.suppress_on ->
        raise ArgumentError,
              "Conflicting suppress_on for region #{inspect(region)}: #{inspect(existing)} vs #{inspect(section.suppress_on)}"
      _ ->
        Map.put(acc, region, section.suppress_on)
    end
  end)
```

Or, if multiple suppress rules per region are intended to be supported, change the data
structure to a list and update `apply_suppression/3` to evaluate all rules with OR semantics.

---

## Warnings

### WR-01: `flow_layout/1` fallback diverges from `measure.ex` overlap-aware formula

**File:** `lib/rendro/pipeline/paginate.ex:518-546`

**Issue:** `flow_layout/1` — the fallback path used when no composed layout is present
(i.e. when the document is passed to `Paginate.run/1` without going through
`Compose`+`Measure`) — computes `body_capacity` as:

```elixir
body_capacity: body_region.height - header_h - footer_h
```

where `header_h` and `footer_h` are obtained from `template.regions` unconditionally. This
is the naive subtract-always formula, not the overlap-aware formula used in `measure.ex`.

While in normal usage the full pipeline runs `Compose → Measure → Paginate` and this
fallback is only hit in unit tests that call `Paginate.run` directly, the fallback is also
reachable when documents use `%Rendro.Document{content: ..., header: ..., footer: ...}` without
sections or templates (tested in `PaginateTest` "flow_layout/1 fallback" test). If the default
`PageTemplate` header and footer regions are ever given non-zero heights, this fallback would
diverge from the `measure.ex` calculation, producing inconsistent pagination in test vs
production environments.

**Fix:** Extract the overlap-aware formula from `measure.ex` into a shared module or
replicate the full conditional check in `paginate.ex:flow_layout/1`, or add a call to
`Measure.body_capacity/1` from `paginate.ex` instead of re-implementing the formula.

---

### WR-02: `evaluate_fn_blocks/3` discards the outer `RunningContent` block height; no region-fit validation for dynamically generated blocks

**File:** `lib/rendro/pipeline/paginate.ex:460-484`

**Issue:** When `evaluate_fn_blocks/3` processes a `RunningContent` block, it calls
`fun.({page_num, total})` and returns the resulting list of blocks directly, discarding the
outer `%Rendro.Block{content: %RunningContent{}, height: ...}` wrapper. The outer block's
`height` field (which was set by the caller and used to reserve region space in any capacity
calculation) is silently dropped.

The blocks returned by the user function may have heights that differ from the outer block's
declared height, causing region overflow for the dynamically-returned blocks. The
`maybe_validate_region_fit` call at line 416 does catch final overflow, so the user will get
an error, but the error message may be confusing because the measured height (from the
`RunningContent` wrapper block) no longer matches the rendered blocks.

More critically, if the returned blocks are taller than the outer block declared, they will
overflow the region while the `body_capacity` calculation assumed the outer wrapper height.
There is no validation that the total height of the returned blocks does not exceed the outer
block's declared height.

**Fix:** After `evaluate_fn_blocks` returns its list, sum the heights and compare against the
original outer block's height, emitting a diagnostic or error if they diverge significantly.
Alternatively, document that the outer `RunningContent` block's `height:` field is advisory
and only used if no blocks are returned.

---

### WR-03: `Rendro.Text` path in `replace_page_numbers/3` mutates content but not `block.height` or `block.width`; undocumented divergence from `MeasuredText` path

**File:** `lib/rendro/pipeline/paginate.ex:425-431`

**Issue:** For an un-measured `Rendro.Text` block (i.e., a block whose content has not been
through the `Measure` pipeline — which can occur on fixed pages or in unit tests that bypass
measure), `replace_page_numbers/3` replaces the token strings inside `text.content` but
leaves `block.height` and `block.width` unchanged. This is correct per D-10.

However, unlike the `MeasuredText` path, there is no comment explaining this is intentional,
and there is no test exercising the `Rendro.Text` branch of `replace_page_numbers/3`. The
`MeasuredText` branch has the explicit comment `# NOTE: run.width intentionally NOT updated
(D-10)`, but the `Rendro.Text` branch carries no such note.

If a future contributor adds height/width recomputation to the `Rendro.Text` branch "to keep
it consistent with measured output," that would reintroduce the D-10 violation. The absence
of a freeze-geometry test for the `Rendro.Text` path means that regression would go
undetected.

**Fix:** Add the same intent comment to the `Rendro.Text` arm:

```elixir
%Rendro.Text{content: text} = t ->
  new_text =
    text
    |> String.replace("{{page_number}}", Integer.to_string(page_num))
    |> String.replace("{{total_pages}}", Integer.to_string(total))

  # NOTE: block.height and block.width intentionally NOT recomputed (D-10)
  %{block | content: %{t | content: new_text}}
```

---

## Info

### IN-01: `Rendro.Error.from_stage/3` called with `{:running_content_error, ...}` has no `next_step` or `why` handler

**File:** `lib/rendro/pipeline/paginate.ex:475`, `lib/rendro/error.ex`

**Issue:** `evaluate_fn_blocks/3` raises `Rendro.Error.from_stage(:paginate, {:running_content_error, inspect(reason)}, ...)`.
There is no matching `why/2` or `next_step/2` clause in `error.ex` for this reason tuple.
The `why/2` fallback `when is_atom(reason)` does not match because `{:running_content_error, string}`
is a 2-tuple; it falls through to `Exception.format_banner(:error, reason)` which will
produce a generic Erlang-style error description. The `next_step/2` fallback returns the
generic "Inspect stage inputs and rerun with telemetry..." message.

While not a crash, the user-visible error for a bad running-content function will be
unhelpful: the formatted error will show a raw exception banner rather than actionable
guidance.

**Fix:** Add specific clauses to `error.ex`:

```elixir
defp why(_stage, {:running_content_error, reason}),
  do: "Running-content function raised an error: #{reason}"

defp next_step(:paginate, {:running_content_error, _reason}) do
  "Ensure the running-content function is a pure, terminating fn {page_number, total_pages} -> [Block.t()] | nil and does not raise."
end
```

---

### IN-02: `Section.t()` content typespec allows `Rendro.RunningContent.t()` at the top level but `Compose.normalize_section/2` maps blocks through `compose_block/1` which has no clause for `RunningContent`

**File:** `lib/rendro/section.ex:19`, `lib/rendro/pipeline/compose.ex:113-119`

**Issue:** `Section.t()` declares `content: [Rendro.Block.t() | Rendro.RunningContent.t()]`
(section.ex:19), implying that a bare `%Rendro.RunningContent{}` (not wrapped in a
`%Rendro.Block{}`) is a valid section content element.

`normalize_section/2` in compose.ex calls `Enum.map(section.content, &compose_block/1)`.
`compose_block/1` has clauses for `%Rendro.Block{content: %Rendro.Table{}}`, for plain
`%Rendro.Block{}`, and a catch-all `block -> block`. A bare `%Rendro.RunningContent{}`
would pass through the catch-all unchanged.

Later in `paginate.ex`, `evaluate_fn_blocks/3` matches on `block.content` which assumes
the element is a `%Rendro.Block{}` with a `.content` field. A bare `%Rendro.RunningContent{}`
has no `.content` field; accessing `block.content` on it would raise a `KeyError`.

In practice, the tests always wrap `RunningContent` in a `%Rendro.Block{}` (see
`paginate_test.exs:726`), so this path is not exercised. However, the typespec misleads
callers into thinking bare `RunningContent` structs are valid content elements.

**Fix:** Tighten the `Section.t()` typespec to require `RunningContent` to be wrapped in a
`Block`:

```elixir
@type t :: %__MODULE__{
  ...
  content: [Rendro.Block.t()],
  ...
}
```

Or, add a `compose_block/1` clause that wraps a bare `RunningContent` in a `Block`:

```elixir
defp compose_block(%Rendro.RunningContent{} = rc),
  do: %Rendro.Block{content: rc}
```

---

_Reviewed: 2026-05-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
