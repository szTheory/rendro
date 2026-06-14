# Phase 97: Location Tracking & Primitives - Research

**Researched:** 2026-06-14
**Domain:** Pagination & Layout Metadata Accumulation
**Confidence:** HIGH

## Summary

The goal of this phase is to establish the primitive required for long-document navigation (like ToC, Outlines, and Cross-References) without causing multi-pass layout oscillations. We need to associate explicit developer-provided `id`s with precise physical coordinates after layout is complete.

**Primary recommendation:** Add an explicit `id` field to `Rendro.Block`. During the `paginate` phase, completely lay out the document. At the end of `Rendro.Pipeline.Paginate.run/1` (when blocks have acquired their absolute physical page `x` and `y` coordinates), traverse the final paginated pages. For every block with an `id`, record `[page_index, :XYZ, x, y, nil]` into a new `anchors: %{}` field in `Rendro.Metadata`. Catch any duplicates during traversal to raise a deterministic error.

<user_constraints>
## User Constraints (from REQUIREMENTS.md)

### Locked Decisions
- **ANC-01:** Add `id` to blocks.
- **ANC-02:** Accumulate `doc.metadata.anchors` in `doc.metadata` during `paginate` using `[page /XYZ left top null]`.
- **ANC-03:** Deterministic errors for duplicate `id`s.

### the agent's Discretion
None explicitly defined; follow architectural constraints of the project (pure Elixir, single-pass).

### Deferred Ideas (OUT OF SCOPE)
None.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ANC-01 | Add `id` to blocks | Modifying `Rendro.Block` struct and types. |
| ANC-02 | Accumulate `doc.metadata.anchors` | Confirmed `Rendro.Pipeline.Paginate.run/1` yields blocks with absolute physical coordinates that can be safely traversed post-layout. |
| ANC-03 | Deterministic errors for duplicate `id`s | Supported via an accumulation loop that checks Map keys and throws a typed `{:error, Rendro.Error}`. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Anchor IDs | Build / Block | — | Explicit developer input on structural elements (`id` attribute). |
| Physical Layout | Measure / Paginate | — | Determines exact geometry (X, Y) and page assignments. |
| Anchor Accumulation | Paginate | Metadata | Must harvest the absolute layout post-pagination, returning `anchors` inside metadata for downstream usage (Validate/Render). |

## Standard Stack

No external stack modifications required.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir (Native) | — | Core logic | Pure functional data transformation for document generation. |

## Package Legitimacy Audit

No external packages installed in this phase.

## Architecture Patterns

### Component Modification
- **`Rendro.Block`:** Add `id: String.t() | nil` (default `nil`).
- **`Rendro.Metadata`:** Add `anchors: %{}` (default `%{}`, typed as `%{optional(String.t()) => list()}`).

### Layout Isolation and Fragment Behavior
When a block is split across multiple pages (e.g. via `Rendro.Fragmentable.split/2` for `Rendro.Block`), we must ensure the `id` is only retained on the **first fragment**. The remaining fragment must have its `id` set to `nil` to prevent duplicate anchor errors.

### Pattern: Traversal Accumulation
**What:** Gathering nested block data without layout side-effects.
**When to use:** Post-pagination, to build document metadata that depends on layout without triggering a re-layout loop.
**Example:**
```elixir
defp collect_anchors(pages) do
  pages
  |> Enum.with_index(1)
  |> Enum.reduce(%{}, fn {page, page_index}, acc ->
    Enum.reduce(page.blocks, acc, &extract_anchors(&1, page_index, &2))
  end)
end

defp extract_anchors(%Rendro.Block{} = block, page_index, acc) do
  acc =
    if block.id do
      if Map.has_key?(acc, block.id) do
        throw({:error, :duplicate_anchor_id, block.id})
      else
        Map.put(acc, block.id, [page_index, :XYZ, block.x || 0, block.y || 0, nil])
      end
    else
      acc
    end
  
  case block.content do
    %Rendro.Table{header: header, rows: rows} ->
      # Recurse into tables/cells
      acc = if header, do: extract_anchors_from_row(header, page_index, acc), else: acc
      Enum.reduce(rows, acc, &extract_anchors_from_row(&1, page_index, &2))
    _ ->
      acc
  end
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Anchor IDs | Implicit slugs | Explicit `id` attribute | Implicit text slugs are brittle and break cross-references when text changes. |
| ToC Pagination | Multi-pass engine | Post-layout token substitution | Multi-pass engines can infinite loop. We strictly preserve single-pass layout constraints. |

## Common Pitfalls

### Pitfall 1: Splitting duplicates IDs
**What goes wrong:** A block with an `id` is split across two pages. Both resulting blocks retain the `id`, causing `ANC-03` to fail with a duplicate ID error.
**Why it happens:** `Rendro.Fragmentable` natively copies the outer wrapper block struct when splitting.
**How to avoid:** Explicitly clear `id: nil` on the `rem_block` inside `Rendro.Fragmentable.split/2` for `Rendro.Block`.

### Pitfall 2: Coordinates Context
**What goes wrong:** Logging `x` and `y` prior to `stack_body_blocks`.
**Why it happens:** Blocks start with relative coords inside `paginate_flow`.
**How to avoid:** `collect_anchors` must happen at the *very end* of `Paginate.run/1`, after all `apply_page_template` and `stack_body_blocks` operations have executed and mapped absolute coordinates.

### Pitfall 3: Nesting Blindness
**What goes wrong:** Only top-level page blocks are checked for anchors, omitting anchored items deep inside tables.
**Why it happens:** A developer put an `id` on a block that acts as a cell in a table.
**How to avoid:** `extract_anchors` must recursively visit `block.content` matching `%Rendro.Table{}` and iterate over its `header` and `rows` -> `cells`.

## Code Examples

### Modifying Paginate run/1
```elixir
  def run(%Document{pages: pages, content: content} = doc) do
    result =
      cond do
        pages != [] -> validate_fixed_pages(doc)
        content != [] or has_flow_layout?(doc) -> paginate_flow(doc)
        true -> {:error, :no_content}
      end

    case result do
      {:ok, paginated_doc} ->
        try do
          anchors = collect_anchors(paginated_doc.pages)
          new_metadata = %{paginated_doc.metadata | anchors: anchors}
          {:ok, %{paginated_doc | metadata: new_metadata}}
        catch
          {:error, :duplicate_anchor_id, id} ->
            {:error, Rendro.Error.from_stage(:paginate, :duplicate_anchor_id, %{id: id})}
        end

      error ->
        error
    end
  end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Naive Page Jump | Precise `XYZ` Dest | This phase | Allows the PDF viewer to maintain exact user zoom and aligns precisely with the top-left of the destination block rather than simply turning the page. |

## Assumptions Log

None.

## Open Questions

None.

## Environment Availability

No external dependencies.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `mix.exs`, `test/test_helper.exs` |
| Quick run command | `mix test test/rendro/pipeline/paginate_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ANC-01 | Add `id` to Block | unit | `mix test test/rendro/block_test.exs` | ❌ Wave 0 |
| ANC-02 | Accumulate `doc.metadata.anchors` with exact `[page /XYZ x y null]` | unit/integration | `mix test test/rendro/pipeline/paginate_test.exs` | ✅ Wave 0 |
| ANC-03 | Deterministic duplicate `id` errors during pagination | unit/integration | `mix test test/rendro/pipeline/paginate_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/pipeline/paginate_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/rendro/block_test.exs` — covers ANC-01 (or may just be implicit in other tests).
- [ ] Needs a focused test for `ANC-02` asserting anchor format `[1, :XYZ, 50, 100, nil]` is returned on document metadata.
- [ ] Needs test for `ANC-03` proving duplicate `id` raises `{:error, %Rendro.Error{}}`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Explicit check for duplicate strings via Map.has_key? |
| V6 Cryptography | no | — |

## Sources

### Primary (HIGH confidence)
- `.planning/research/ARCHITECTURE.md` - Confirms the architecture around accumulating anchors in Paginate.
- `.planning/research/RECOMMENDATIONS.md` - Emphasizes explicit IDs, avoiding multi-pass loop, and using XYZ anchors.
- `lib/rendro/block.ex` - Schema target for ID addition.
- `lib/rendro/pipeline/paginate.ex` - Target where accumulation will natively be implemented.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - native elixir functionality.
- Architecture: HIGH - fully aligns with stated project recommendations.
- Pitfalls: HIGH - identified fragment splitting and relative coordinate issues directly from Rendro.Fragmentable.

**Research date:** 2026-06-14
**Valid until:** 30 days
