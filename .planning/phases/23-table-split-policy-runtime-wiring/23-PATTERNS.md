# Phase 23: Table Split Policy Runtime Wiring - Pattern Map

**Mapped:** 2026-04-30
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/rendro/table.ex` | model | request-response | `lib/rendro/table.ex` | exact |
| `lib/rendro.ex` | utility | request-response | `lib/rendro.ex` | exact |
| `lib/rendro/pipeline/paginate.ex` | service | transform | `lib/rendro/pipeline/paginate.ex` | exact |
| `test/rendro_builders_test.exs` | test | request-response | `test/rendro_builders_test.exs` | exact |
| `test/rendro/pipeline/paginate_test.exs` | test | transform | `test/rendro/pipeline/paginate_test.exs` | exact |
| `test/rendro/flow_test.exs` | test | request-response | `test/rendro/flow_test.exs` | exact |
| `.planning/phases/20-table-layout-maturity/20-VERIFICATION.md` | verification | transform | `.planning/phases/09-ci-and-release-hardening/09-VERIFICATION.md` | strong |
| `.planning/phases/23-table-split-policy-runtime-wiring/23-VERIFICATION.md` | verification | transform | `.planning/phases/16-phoenix-error-boundary-proof/16-VERIFICATION.md` | strong |
| `.planning/REQUIREMENTS.md` / `.planning/ROADMAP.md` | product contract | transform | same files | exact |

## Pattern Assignments

### `lib/rendro/table.ex` (model, request-response)

**Analog:** `lib/rendro/table.ex`

Current contract:

```elixir
defstruct [
  :rows,
  header: nil,
  columns: nil,
  split_policy: :atomic,
  column_widths: nil,
  row_heights: nil,
  header_height: nil
]
```

Phase 23 should preserve the existing public-surface pattern: small explicit struct fields mirrored in `@type`, no hidden policy channel, and no speculative enum growth.

### `lib/rendro.ex` (utility, request-response)

**Analog:** `lib/rendro.ex`

Current builder wrapper pattern:

```elixir
@spec table([Table.row()], keyword()) :: Table.t()
def table(rows, attrs \\ []) do
  struct!(Table, Keyword.put(attrs, :rows, rows))
end
```

If Phase 23 keeps a temporary alias such as `:atomic`, normalize or reject it here so the boundary contract is explicit before pagination runs.

### `lib/rendro/pipeline/paginate.ex` (service, transform)

**Analog:** `lib/rendro/pipeline/paginate.ex`

Current table-routing seam:

```elixir
case block.content do
  %Rendro.Table{} = table when current_h + block_h > max_h ->
    handle_table_split(...)
```

Phase 23 should keep this seam and add an explicit branch on `table.split_policy`. The row-atomic split path already exists; the missing pattern is authored-policy consumption, not new layout mechanics.

### `test/rendro_builders_test.exs` (test, request-response)

**Analog:** `test/rendro_builders_test.exs`

Current builder proof:

```elixir
table = Rendro.table([[\"1\"]], columns: [{:fixed, 100}], split_policy: :atomic)
assert %Table{rows: [[\"1\"]], columns: [{:fixed, 100}], split_policy: :atomic} = table
```

Extend this exact assertion style for the canonical `:row_atomic` value and any temporary alias behavior. Do not rely on docs-only proof for a public builder contract change.

### `test/rendro/pipeline/paginate_test.exs` (test, transform)

**Analog:** `test/rendro/pipeline/paginate_test.exs`

Existing proof patterns already cover:
- table split diagnostics
- impossible keep-group overflow details
- typed paginate errors

Phase 23 should add tests in this same file proving that:
- authored row-atomic policy reaches the split path
- compatibility alias, if retained, resolves to the same runtime semantics
- unsupported policy values fail explicitly instead of silently behaving like row-atomic

### `test/rendro/flow_test.exs` (test, request-response)

**Analog:** `test/rendro/flow_test.exs`

Current end-to-end pattern asserts rendered PDF text plus page count. Use that same proof style for a multi-page table that explicitly sets the new canonical split policy so the runtime contract is proven at the public API level, not just pipeline level.

### `.planning/phases/20-table-layout-maturity/20-VERIFICATION.md` (verification, transform)

**Analog:** `.planning/phases/09-ci-and-release-hardening/09-VERIFICATION.md`

Phase 09 establishes the precedent for historical repair:
- frontmatter marks later closure evidence
- body explains that original execution was incomplete
- authoritative proof is linked from later phases

Phase 20 should reuse that structure so audits can distinguish "what Phase 20 originally shipped" from "what Phase 23 later closed."

### `.planning/phases/23-table-split-policy-runtime-wiring/23-VERIFICATION.md` (verification, transform)

**Analog:** `.planning/phases/16-phoenix-error-boundary-proof/16-VERIFICATION.md`

Use the repo’s standard verification shape:
- `## Goal Achievement`
- requirement-specific sections
- key-link verification
- required artifacts

Phase 23 should make itself the authoritative final closure point for `LAY-10`.

## Shared Patterns

### One Runtime Path Only
Do not add a second pagination engine. `Paginate` already owns continuation and overflow behavior.

### Typed Failure Over Silent Fallback
Unsupported policy values should be rejected or failed explicitly, not coerced silently.

### Historical Truthfulness
Backfilled verification artifacts must say what was missing originally and what later closed it.

## No Analog Found

None. Phase 23 is intentionally a narrow extension of existing table and verification patterns.
