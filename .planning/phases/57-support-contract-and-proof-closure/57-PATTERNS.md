# Phase 57: Support Contract and Proof Closure - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 8
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `priv/support_matrix.json` | config | request-response | `priv/support_matrix.json` | exact |
| `guides/api_stability.md` | docs | request-response | `guides/api_stability.md` | exact |
| `test/docs_contract/forms_claims_test.exs` | test | request-response | `test/docs_contract/forms_claims_test.exs` | exact |
| `test/docs_contract/signing_claims_test.exs` | test | request-response | `test/docs_contract/protection_claims_test.exs` | role-match |
| `scripts/verify_docs.exs` | script | request-response | `scripts/verify_docs.exs` | exact |
| `.planning/phases/57-support-contract-and-proof-closure/57-VERIFICATION.md` | docs | request-response | `.planning/phases/53-delivery-threading-and-truthful-support-contract/53-VERIFICATION.md` | role-match |
| `test/rendro/pdf/writer_test.exs` | test | transform | `test/rendro/pdf/writer_test.exs` | exact |
| `test/rendro/sign_test.exs` | test | transform | `test/rendro/sign_test.exs` | exact |

## Recommended Plan Split

- `57-01`: own `priv/support_matrix.json`, `guides/api_stability.md`, `test/docs_contract/forms_claims_test.exs`, optional `test/docs_contract/signing_claims_test.exs`, and `scripts/verify_docs.exs`.
- `57-02`: own `.planning/phases/57-support-contract-and-proof-closure/57-VERIFICATION.md` plus any minimal assertion updates needed in `test/rendro/pdf/writer_test.exs` or `test/rendro/sign_test.exs` to keep proof lanes explicit.

Reason: the first slice publishes the public contract. The second slice proves the contract stays narrow and explicitly separates structural proof from viewer and cryptographic validity claims.

## Pattern Assignments

### `priv/support_matrix.json`

**Analog:** existing family-first top-level sections (`forms`, `embedded_files`, `links`, `protection`)

Pattern to follow:
- Add one small sibling family rather than a broad wrapper.
- Use positive capability leaves for supported seams.
- Use explicit `boundaries` or `behaviors` leaves for unsupported narratives.
- Keep viewer sections separate from structural/support leaves.

### `guides/api_stability.md`

**Analog:** existing sections `Interactive Forms Support Boundary` and `Protected PDF Support Boundary`

Pattern to follow:
- Start with a one-sentence supported surface.
- Follow with proof-lane clarification.
- End with explicit unsupported claims.
- Name viewers only when a recorded checklist exists.

### `test/docs_contract/forms_claims_test.exs`

**Analog:** current unsigned-placeholder guards

Pattern to follow:
- Assert exact strings for supported claims.
- Refute broad phrases that would widen the trust contract.
- Keep regex/string assertions simple and grep-like rather than parser-heavy.

### `test/docs_contract/signing_claims_test.exs`

**Analog:** `test/docs_contract/protection_claims_test.exs`

Pattern to follow:
- Lock the new `signing_preparation` family, its supported leaves, and its explicit unsupported boundaries.
- Assert guide wording for artifact-first preparation and for what remains unsupported.
- Refute overclaims like "digital signatures are supported", "tamper-evident signing", and blanket viewer guarantees.

### `scripts/verify_docs.exs`

**Analog:** existing lane table

Pattern to follow:
- Add any new claims lane as one explicit entry in `lanes`.
- Keep verification wiring flat and readable.
- Do not create a second verification script for this milestone.

### `57-VERIFICATION.md`

**Analog:** milestone-close verification artifacts from prior trust-sensitive phases

Pattern to follow:
- Keep it terse.
- List canonical supported and unsupported claims only.
- Point each supported claim to an exact proof lane.
- Point viewer posture to recorded evidence or `unverified`, never to intent.

## Concrete Excerpts To Reuse

### Support-matrix family-first precedent

```json
"protection": {
  "capabilities": {
    "password_to_open": "supported"
  }
}
```

### Narrow guide wording precedent

```md
Protection is not compliance, not tamper evidence, and not digital signing.
```

### Docs-contract negative guard precedent

```elixir
refute guide =~ "digital signatures are supported"
refute guide =~ "PAdES is supported"
```

## Anti-Patterns

- Reusing the old Phase 55 wording unchanged after promoting rendered unsigned widgets and signing preparation.
- Mixing support publication and proof-note generation into one vague task that spans too many files.
- Writing verification prose that invents claim names not present in `priv/support_matrix.json` or `guides/api_stability.md`.

