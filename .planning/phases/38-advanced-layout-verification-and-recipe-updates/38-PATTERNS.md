# Phase 38: Advanced Layout Verification & Recipe Updates - Pattern Map

**Mapped:** 2024-05-04
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/recipes/invoice.ex` | recipe | transform | `lib/rendro/recipes/invoice.ex` (self) | exact |
| `test/rendro/recipes/invoice_test.exs` | test | transform | `test/rendro/recipes/invoice_test.exs` (self) | exact |
| `test/rendro/end_to_end_pipeline_test.exs` | test | transform | `test/rendro/end_to_end_pipeline_test.exs` (self) | exact |
| `test/docs_contract/*` | test | contract | `test/docs_contract/branding_contract_test.exs` | role-match |

## Pattern Assignments

### `lib/rendro/recipes/invoice.ex` (recipe, transform)

**Analog:** `lib/rendro/recipes/invoice.ex`

**Table Fragmentation & Layout Pattern** (lines 114-129):
```elixir
  defp body_section(%{items: items} = _data) do
    table_rows =
      Enum.map(items, fn item ->
        [item.name, Integer.to_string(item.qty), "$#{item.price}"]
      end)

    table =
      Rendro.table(table_rows,
        header: ["Item", "Qty", "Price"],
        columns: [{:share, 1}, {:fixed, 50}, {:fixed, 80}]
      )

    Rendro.section(
      name: :invoice_body,
      region: :body,
      content: [Rendro.block(table)]
    )
  end
```
*Note: For Phase 38, this pattern should be expanded to demonstrate advanced layout by including a sufficiently large item list for multi-page table pagination, as well as testing Arabic shaping behavior within these blocks.*

---

### `test/rendro/end_to_end_pipeline_test.exs` (test, transform)

**Analog:** `test/rendro/end_to_end_pipeline_test.exs`

**Visual/Flow Regression & Determinism Pattern** (lines 28-39):
```elixir
    # 2. Worker executes, renders deterministically, and stores the artifact
    assert :ok = RenderWorker.perform(job)

    # 3. Retrieve the stored artifact from Local storage
    assert {:ok, %Artifact{} = artifact} = Local.get(storage_path, [])
    assert is_binary(artifact.binary)
    assert String.starts_with?(artifact.binary, "%PDF-")
```
*Note: This demonstrates asserting byte-for-byte correctness and structural validity using determinism (Phase 38 requires verifying regressions against generated multi-page/Arabic PDFs).*

---

### Docs Contract Tests (test, contract)

**Analog:** `test/docs_contract/branding_contract_test.exs`

**Docs Contract Extraction Pattern** (lines 5-14):
```elixir
  test "guides/branding.md ships exactly the four expected verified fence IDs in order" do
    fences = DocsContract.verified_fences("guides/branding.md")

    assert Enum.map(fences, & &1.id) == [
             "branding-register-assets",
             "branding-tiered-document",
             "branding-tiered-template",
             "branding-missing-asset-diagnostic"
           ]
  end
```

**Docs Contract Evaluation Pattern** (lines 16-24):
```elixir
  test "every guides/branding.md fence body is evaluable and free of skeleton placeholders" do
    fences = DocsContract.verified_fences("guides/branding.md")
    assert length(fences) == 4

    Enum.each(fences, fn %{code: code} ->
      refute String.contains?(code, "...")
      refute String.contains?(code, "%{...}")
      DocsContract.evaluate!(code, "guides/branding.md")
    end)
  end
```
*Note: Phase 38 requires similar strict contract testing to guarantee documentation around Arabic text/table pagination examples is verifiable.*

## Metadata

**Analog search scope:** `lib/rendro/recipes/`, `test/rendro/`, `test/docs_contract/`
**Files scanned:** 4
**Pattern extraction date:** 2024-05-04
