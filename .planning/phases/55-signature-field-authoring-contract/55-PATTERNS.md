# Phase 55: Signature Field Authoring Contract - Patterns

**Mapped:** 2026-05-06
**Phase:** 55 - Signature Field Authoring Contract

## Planned File Patterns

| Planned File | Role | Closest Analog | Why |
|--------------|------|----------------|-----|
| `lib/rendro.ex` | Public builder helper | `lib/rendro.ex` `form_field/3`, `link/2`, `render_protected/3` | Public contract helpers live here and normalize into existing structs. |
| `lib/rendro/form_field.ex` | Shared authored widget carrier | existing `field_type` and struct defaults | Phase 55 should extend the same model rather than fork it. |
| `lib/rendro/rules/check_form_fields.ex` | Field-local and document-wide validation | existing text/checkbox/radio checks | Signature-specific boundary rejection belongs in the same rule module. |
| `test/rendro_builders_test.exs` | Public helper regression coverage | current `form_field/3` builder tests | Best analog for proving `Rendro.signature_field/2` DX and normalization. |
| `test/rendro/rules/check_form_fields_test.exs` | Raw validation-tuple coverage | existing invalid-type and radio tests | Best analog for replacing the old invalid-type contract with signature-specific rejections. |
| `test/rendro/pipeline/validate_test.exs` | Validate-stage error-envelope coverage | current aggregate form validation tests | Best analog for proving typed signature errors surface before render. |
| `guides/api_stability.md` | Public support-boundary wording | current forms + protection sections | Trust-sensitive claims are documented here with narrow wording. |
| `priv/support_matrix.json` | Machine-readable support contract | `forms.widgets.signature`, `unsupported.digital_signatures` | Best place to keep unsigned field support distinct from actual digital signatures. |
| `test/docs_contract/forms_claims_test.exs` | Docs-contract lock | current forms contract tests | Prevents drift between support matrix and prose. |

## Code Excerpts To Reuse

### Public builder normalization in `lib/rendro.ex`
```elixir
@spec form_field(String.t(), String.t(), keyword()) :: Block.t()
def form_field(name, value \\ "", attrs \\ []) do
  {field_attrs, block_attrs} =
    Keyword.split(attrs, [:font, :size, :type, :checked, :group, :export_value])

  field = struct!(FormField, Keyword.merge(field_attrs, name: name, value: value))
  struct!(Block, Keyword.put(block_attrs, :content, field))
end
```

### Shared field-type model in `lib/rendro/form_field.ex`
```elixir
@type field_type :: :text | :checkbox | :radio

defstruct [
  :name,
  type: :text,
  value: "",
  font: "Helvetica",
  size: 12,
  checked: false,
  group: nil,
  export_value: "Yes"
]
```

### Clause-per-invariant validation in `lib/rendro/rules/check_form_fields.ex`
```elixir
def check(%FormField{type: type}, _doc) when type not in @supported_types,
  do: {:error, {:invalid_form_field_type, type}}

defp check_size_contract(%FormField{type: :radio, group: group})
     when not (is_binary(group) and byte_size(group) > 0),
     do: {:error, {:missing_required_key, :group}}
```

### Validate-stage aggregation in `lib/rendro/pipeline/validate.ex`
```elixir
case walk(doc, doc, rules) do
  [] ->
    {:ok, doc}

  errors ->
    {:error,
     Rendro.Error.from_stage(:validate, :structural_corruption, %{details: %{errors: errors}})}
end
```

### Docs-contract assertion style in `test/docs_contract/forms_claims_test.exs`
```elixir
assert matrix =~ ~s|\"text\": \"supported\"|
assert matrix =~ ~s|\"checkbox\": \"supported\"|
assert matrix =~ ~s|\"radio\": \"supported\"|
assert matrix =~ ~s|\"signature\": \"unsupported\"|
```

## Recommended Reuse Strategy

- Mirror the existing `form_field/3` helper style when adding `signature_field/2`: split field attrs from block attrs, normalize into `%FormField{}`, and return a normal `%Block{}`.
- Keep signature-specific validation in `CheckFormFields` as explicit clauses and helper functions instead of introducing a second validator.
- Reuse existing builder/rule/pipeline/docs-contract test structure so Phase 55 stays a narrow contract phase with predictable verification lanes.
- Treat docs/support changes as synchronization work, not as a second feature track.
