# Phase 56: Writer and External Signing Preparation Seam - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 8
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/rendro/pdf/writer.ex` | utility | transform | `lib/rendro/pdf/writer.ex` | exact |
| `test/rendro/pdf/writer_test.exs` | test | transform | `test/rendro/pdf/writer_test.exs` | exact |
| `lib/rendro/sign.ex` | service | transform | `lib/rendro/protect.ex` | exact |
| `lib/rendro/sign/adapter.ex` | adapter | transform | `lib/rendro/protect/adapter.ex` | exact |
| `test/rendro/sign_test.exs` | test | transform | protection tests around `Rendro.Protect` style + writer assertions | role-match |
| `guides/api_stability.md` | docs | request-response | `guides/api_stability.md` | exact |
| `priv/support_matrix.json` | config | request-response | `priv/support_matrix.json` | exact |
| `test/docs_contract/forms_claims_test.exs` or a new signing-claims lane | test | request-response | `test/docs_contract/forms_claims_test.exs` | role-match |

## Recommended Plan Split

Follow the roadmap split in [v2.0-ROADMAP.md](/Users/jon/projects/rendro/.planning/milestones/v2.0-ROADMAP.md:33) while still reusing nearby phase patterns:

- `56-01`: writer support only. Own `lib/rendro/pdf/writer.ex`, `test/rendro/pdf/writer_test.exs`, and deterministic regression proof. Keep preparation, docs, and support files out.
- `56-02`: artifact-first signing-preparation seam only. Own `lib/rendro/sign.ex`, optional `lib/rendro/sign/adapter.ex`, `test/rendro/sign_test.exs`, and any prepare-stage error coverage. Depend on `56-01`.
- `57-01` and `57-02`: support-matrix, guide wording, docs-contract, and proof-closure work.

Reason: this keeps Phase 56 aligned with its roadmap requirement mapping: `SIGN-03` lands in the writer slice first, then `PREP-01` through `PREP-03` land in the preparation slice, while the trust-sensitive publication work stays deferred to Phase 57.

## Pattern Assignments

### `lib/rendro/sign.ex`

**Analog:** [lib/rendro/protect.ex](/Users/jon/projects/rendro/lib/rendro/protect.ex:1)

**Artifact-first transform pattern** ([lib/rendro/protect.ex](/Users/jon/projects/rendro/lib/rendro/protect.ex:39)):
```elixir
@spec password(Artifact.t(), options()) :: {:ok, Artifact.t()} | {:error, Error.t()}
def password(%Artifact{} = artifact, opts) when is_list(opts) do
  with {:ok, normalized} <- normalize_opts(opts),
       {:ok, protected_binary} <- normalized.adapter.protect(artifact, normalized) do
    {:ok,
     Artifact.wrap(
       protected_binary,
       artifact,
       %{
         deterministic: false,
         protection: protection_metadata(normalized)
       }
     )}
  else
```

Copy this shape for `Rendro.Sign.prepare/2`: accept `%Rendro.Artifact{}`, normalize a narrow opts list, call one focused module/behavior, then return `Artifact.wrap/3` with only signing-preparation metadata updates.

**Redaction / trust-safe error detail pattern** ([lib/rendro/protect.ex](/Users/jon/projects/rendro/lib/rendro/protect.ex:77)):
```elixir
@spec redact_opts(options() | map()) :: map()
def redact_opts(opts) when is_list(opts) do
  opts
  |> Enum.into(%{})
  |> redact_opts()
end
```

If `prepare/2` can fail on reserved-byte sizing or field lookup, keep error details explicit and non-secret-bearing in the same style.

**Do not widen root render semantics** ([lib/rendro.ex](/Users/jon/projects/rendro/lib/rendro.ex:249)):
```elixir
@spec render_protected(Document.t(), render_options(), keyword()) ::
        {:ok, Artifact.t()} | {:error, Rendro.Error.t()}
def render_protected(%Document{} = doc, render_opts \\ [], protect_opts)
    when is_list(render_opts) and is_list(protect_opts) do
  with {:ok, artifact} <- render_to_artifact(doc, render_opts) do
    Protect.password(artifact, protect_opts)
  end
end
```

Phase 56 should mirror this composition posture, not push signing placeholders into `render/2` or `render_to_artifact/2`.

### `lib/rendro/sign/adapter.ex`

**Analog:** [lib/rendro/protect/adapter.ex](/Users/jon/projects/rendro/lib/rendro/protect/adapter.ex:1)

**Behavior pattern**:
```elixir
@callback protect(Rendro.Artifact.t(), map()) ::
            {:ok, binary()} | {:error, term()}
```

For Phase 56, prefer a narrow prepare behavior returning prepared bytes plus a generic manifest, not signer-specific blobs. Example shape to preserve: one artifact in, one deterministic prepared result out.

### `lib/rendro/artifact.ex`

**Analog:** [lib/rendro/artifact.ex](/Users/jon/projects/rendro/lib/rendro/artifact.ex:37)

**Wrap metadata onto final bytes**:
```elixir
@spec wrap(binary(), t(), map()) :: t()
def wrap(pdf_binary, %__MODULE__{} = source, metadata_updates \\ %{}) do
  %__MODULE__{
    binary: pdf_binary,
    hash: hash_binary(pdf_binary),
    diagnostics: source.diagnostics,
    metadata: Map.merge(source.metadata, metadata_updates)
  }
end
```

Use this for the signing-preparation manifest under a nested metadata key. Do not widen authored document state or create a second artifact carrier.

### `lib/rendro/pdf/writer.ex`

**Analog:** [lib/rendro/pdf/writer.ex](/Users/jon/projects/rendro/lib/rendro/pdf/writer.ex:181)

**Deterministic object allocation pattern**:
```elixir
defp allocate_form_field_nums(form_fields, start_num) do
  {families, radio_groups} =
    Enum.reduce(form_fields, {[], %{}}, fn form_field, {families, radio_groups} ->
      case form_field.field.type do
        :radio ->
          key = {:radio_group, form_field.field.group}
```

Signature widgets should extend this existing family allocation path, not create a separate writer subsystem. Allocation remains explicit, sequential, and type-driven.

**Standalone widget numbering pattern** ([lib/rendro/pdf/writer.ex](/Users/jon/projects/rendro/lib/rendro/pdf/writer.ex:221)):
```elixir
defp allocate_standalone_form_field(form_field, num) do
  base = %{
    type: form_field.field.type,
    field_obj_num: num,
    block: form_field.block,
    field: form_field.field,
    page_index: form_field.page_index,
    widget_obj_num: num
  }
```

For `:signature`, the closest fit is this standalone path. Keep explicit `field_obj_num` and `widget_obj_num` allocation. Do not auto-place or infer hidden widgets.

**Page-local widget emission pattern** ([lib/rendro/pdf/writer.ex](/Users/jon/projects/rendro/lib/rendro/pdf/writer.ex:857)):
```elixir
defp build_form_field_objects(page, page_num, form_field_allocations, page_index, opts) do
  page_allocations = page_form_field_allocations(form_field_allocations, page_index)
```

Add signature serialization through `build_widget_objects/4` so page annotation wiring stays uniform.

**Current widget serialization precedent**:

- Text widgets: [lib/rendro/pdf/writer.ex](/Users/jon/projects/rendro/lib/rendro/pdf/writer.ex:1028)
- Checkbox widgets: [lib/rendro/pdf/writer.ex](/Users/jon/projects/rendro/lib/rendro/pdf/writer.ex:1055)
- Radio widgets: [lib/rendro/pdf/writer.ex](/Users/jon/projects/rendro/lib/rendro/pdf/writer.ex:1095)

The signature variant should copy the same raw-dictionary style:
- explicit `/Type /Annot`
- explicit `/Subtype /Widget`
- explicit `/Rect`
- explicit `/P`
- Rendro-owned `/AP`

But Phase 56 must not follow the text-widget precedent of emitting `/V` during normal render. Decision D-02/D-03 means unsigned render stays placeholder-only.

**AcroForm catalog injection pattern** ([lib/rendro/pdf/writer.ex](/Users/jon/projects/rendro/lib/rendro/pdf/writer.ex:1548)):
```elixir
[
  {"Type", {:name, "Catalog"}},
  {"Pages", {:ref, pages_num, 0}},
  {"AcroForm", acro_form}
]
```

Signature field refs belong in the existing AcroForm `Fields` list. Avoid new catalog-level signing structures in base render.

### `test/rendro/pdf/writer_test.exs`

**Analog:** [test/rendro/pdf/writer_test.exs](/Users/jon/projects/rendro/test/rendro/pdf/writer_test.exs:248)

**Assertion style for widget presence and negative guards**:
```elixir
assert pdf =~ "/Subtype /Widget"
assert pdf =~ "/FT /Btn"
refute pdf =~ "/NeedAppearances"
```

Use this same style for signature widgets:
- assert `/FT /Sig`
- assert widget rect and AcroForm presence
- refute `/V`
- refute `/ByteRange`
- refute `/Contents`
- refute signing-policy keys such as `/Lock` or `/SV`

The existing tests already lock deterministic emitted strings for text, checkbox, and radio widgets ([test/rendro/pdf/writer_test.exs](/Users/jon/projects/rendro/test/rendro/pdf/writer_test.exs:313), [test/rendro/pdf/writer_test.exs](/Users/jon/projects/rendro/test/rendro/pdf/writer_test.exs:344), [test/rendro/pdf/writer_test.exs](/Users/jon/projects/rendro/test/rendro/pdf/writer_test.exs:369)). Copy that style instead of adding parser-heavy tests.

### Phase 57 Docs / Support Contract Files

**Analogs:**
- [guides/api_stability.md](/Users/jon/projects/rendro/guides/api_stability.md:26)
- [priv/support_matrix.json](/Users/jon/projects/rendro/priv/support_matrix.json:10)
- [55-02-PLAN.md](/Users/jon/projects/rendro/.planning/phases/55-signature-field-authoring-contract/55-02-PLAN.md:84)
- [53-02-PLAN.md](/Users/jon/projects/rendro/.planning/phases/53-delivery-threading-and-truthful-support-contract/53-02-PLAN.md:139)

**Support-boundary split pattern**

Phase 55 shows the correct contract-first posture:
- keep `forms.authored_helpers.signature_field` supported while `forms.widgets.signature` stays conservative until serialization exists
- separate authored unsigned placeholder claims from digital-signature claims

Phase 53 shows the correct trust-sensitive docs pattern:
- add small machine-readable leaves instead of redesigning the matrix
- repeat the same narrow boundary in prose
- freeze both with docs-contract tests

For the later Phase 57 trust-contract work, the likely matrix/prose split is:
- promote the rendered signature-widget surface only as far as serialization and structural readiness are truly proven
- add a compact signing-preparation boundary leaf rather than a large new trust taxonomy
- keep `digital_signatures` unsupported and keep viewer/compliance/tamper-evidence claims out

## Shared Patterns

### Artifact-First Post-Render Work

**Source:** [lib/rendro/artifact.ex](/Users/jon/projects/rendro/lib/rendro/artifact.ex:37), [lib/rendro/protect.ex](/Users/jon/projects/rendro/lib/rendro/protect.ex:39), [lib/rendro.ex](/Users/jon/projects/rendro/lib/rendro.ex:253)

Apply to all signing-preparation code:
- render first
- transform `%Rendro.Artifact{}`
- wrap new bytes with `Artifact.wrap/3`
- record only narrow metadata facts

### Deterministic Writer Extension

**Source:** [lib/rendro/pdf/writer.ex](/Users/jon/projects/rendro/lib/rendro/pdf/writer.ex:38), [lib/rendro/pdf/writer.ex](/Users/jon/projects/rendro/lib/rendro/pdf/writer.ex:181), [lib/rendro/pdf/writer.ex](/Users/jon/projects/rendro/lib/rendro/pdf/writer.ex:961)

Apply to signature widget serialization:
- allocate object numbers before building objects
- keep type-specific clauses small
- emit Rendro-owned appearances
- preserve existing AcroForm/Annots wiring

### Trust-Sensitive Docs Closure

**Source:** [53-02-PLAN.md](/Users/jon/projects/rendro/.planning/phases/53-delivery-threading-and-truthful-support-contract/53-02-PLAN.md:19), [55-02-PLAN.md](/Users/jon/projects/rendro/.planning/phases/55-signature-field-authoring-contract/55-02-PLAN.md:15), [guides/api_stability.md](/Users/jon/projects/rendro/guides/api_stability.md:64), [priv/support_matrix.json](/Users/jon/projects/rendro/priv/support_matrix.json:109)

Apply to Phase 56 docs work:
- one machine-readable source
- one canonical prose source
- one docs-contract lane that refutes overclaims as well as omissions

## Pitfalls

- Do not emit `/V` for unsigned signature widgets during ordinary render. Current text fields do; signature widgets must not.
- Do not reserve `/Contents`, `/ByteRange`, `/Filter`, `/SubFilter`, `/Lock`, `/SV`, or `/Reference` in base writer output.
- Do not move signing preparation into `Rendro.render/2` or document authoring state. Keep it artifact-first like protection.
- Do not add signer-specific adapter blobs to core artifact metadata. Keep one narrow generic manifest and reserve namespaced extensions for future adapters.
- Do not mix runtime seam work and support-boundary wording in the same first plan. Phase 53 and 55 both split these successfully.
- Do not promote viewer support, digital-signature validity, tamper evidence, or compliance narratives when only unsigned widget serialization or preparation metadata has landed.

## No Close Analog

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/rendro/sign.ex` manifest schema details | service | transform | No existing core manifest records byte-range coordinates or reserved signature capacity; reuse `Rendro.Protect` API shape but design a new narrow nested metadata contract. |

## Metadata

**Analog search scope:** `.planning/phases/53-*`, `.planning/phases/55-*`, `lib/rendro/*.ex`, `lib/rendro/protect*.ex`, `lib/rendro/pdf/writer.ex`, `test/rendro/pdf/writer_test.exs`, `guides/api_stability.md`, `priv/support_matrix.json`

**Planner-ready summary:**
- Plan 1 should own writer serialization plus artifact-first preparation seam.
- Plan 2 should own support matrix, API stability wording, and docs-contract closure.
- The strongest code analogs are `Rendro.Protect`, `Rendro.Artifact.wrap/3`, and the existing AcroForm widget allocation/build clauses in `Rendro.PDF.Writer`.
