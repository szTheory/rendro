# Phase 97 Validation Strategy

## Overview

This document outlines the testing and validation strategy to satisfy the **Nyquist rule** for Phase 97 (Location Tracking & Primitives). The `gsd-plan-checker` requires explicit automated verification strategies to ensure that all structural modifications, coordinate extraction, and deterministic error behaviors mandated by requirements **ANC-01**, **ANC-02**, and **ANC-03** are correctly verified and fully covered.

## Requirement Coverage (Nyquist Matrix)

| Requirement | Description | Validation Strategy | Automated Test Path |
|-------------|-------------|---------------------|---------------------|
| **ANC-01** | Explicit `id` block attributes | Unit compilation checks & integration usage in downstream rules | `mix compile` (Plan 01) |
| **ANC-02** | Accumulate `[page, :XYZ, x, y, nil]` destinations | TDD integration tests asserting exact coordinate, nested traversal, and format mapping from `Paginate` into `doc.metadata.anchors` | `mix test test/rendro/pipeline/paginate_test.exs` (Plan 02) |
| **ANC-03** | Deterministic duplicate `id` errors | Pre-layout and Post-layout TDD tests verifying `CheckIds` and `Paginate` reject duplicates with formatted errors | `mix test test/rendro/rules/check_ids_test.exs`<br>`mix test test/rendro/pipeline/paginate_test.exs` |

## Detailed Test Scenarios

### 1. Structural Primitives (ANC-01)
- **Target Files:** `lib/rendro/block.ex`, `lib/rendro/metadata.ex`
- **Validation:** 
  - Ensure the `id` field exists on `Rendro.Block.t()` and defaults to `nil`.
  - Ensure `Metadata.t()` correctly initializes an empty `%{} ` map for `anchors`.
- **Command:** `mix compile` (Compilation proves struct presence; further testing is implicit via dependent tests).

### 2. Pre-layout Structural Duplicate Prevention (ANC-03)
- **Target Files:** `lib/rendro/rules/check_ids.ex`, `test/rendro/rules/check_ids_test.exs`
- **Validation (TDD):**
  - **Happy Path:** A document tree with no IDs or entirely unique IDs passes the `check/2` rule returning `:ok`.
  - **Error Path:** A document tree with identically named IDs in different nested block depths returns `{:errors, [{:duplicate_id, "foo"}]}`, guaranteeing failure *before* expensive layout processing begins.
- **Command:** `mix test test/rendro/rules/check_ids_test.exs`

### 3. Safe Fragmentation Edge Case (ANC-02 / ANC-03 Protection)
- **Target Files:** `lib/rendro/fragmentable.ex`, `test/rendro/fragmentable_test.exs`
- **Validation (TDD):**
  - **Scenario:** A block with `id: "exec-summary"` exceeds page boundaries and is fragmented across multiple pages.
  - **Assertion:** The initial fragment retains `id: "exec-summary"`. The trailing `rem_block` explicitly drops the identifier (receives `id: nil`).
  - **Why:** Prevents legitimate multi-page blocks from artificially triggering duplicate ID validation errors during post-layout pagination/anchor accumulation.
- **Command:** `mix test test/rendro/fragmentable_test.exs`

### 4. Anchor Accumulation & Coordinate Extraction (ANC-02)
- **Target Files:** `lib/rendro/pipeline/paginate.ex`, `test/rendro/pipeline/paginate_test.exs`
- **Validation (TDD):**
  - **Format Check:** Assert the accumulated anchor maps precisely to `%{ "my_id" => [page_idx, :XYZ, x, y, nil] }`.
  - **Coordinate Correctness:** Ensure `x` and `y` default to `0` if undefined on the block, and map strictly to the physical `left/top` location finalized after layout.
  - **Nested Blocks:** Ensure the anchor accumulation traversal actively finds IDs deeply nested inside structured elements (e.g., children of columns or tables).
- **Command:** `mix test test/rendro/pipeline/paginate_test.exs`

### 5. Post-Layout Duplicate Safeguard (ANC-03)
- **Target Files:** `lib/rendro/pipeline/paginate.ex`, `lib/rendro/error.ex`, `test/rendro/pipeline/paginate_test.exs`
- **Validation (TDD):**
  - **Scenario:** If a duplicate ID circumvents structural checks (e.g. dynamically injected post-validation).
  - **Assertion:** Anchor accumulation explicitly traps it, throwing an internal `{:error, :duplicate_anchor_id, id}`.
  - **Error Translation:** Assert `Paginate.run/1` gracefully catches this and halts, returning a fully formatted, deterministic `Rendro.Error` generated via `Rendro.Error.from_stage(:paginate, :duplicate_anchor_id, %{id: id})`.
- **Command:** `mix test test/rendro/pipeline/paginate_test.exs`
