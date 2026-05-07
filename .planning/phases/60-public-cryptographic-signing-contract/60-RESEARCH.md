# Phase 60: Public Cryptographic-Signing Contract - Research

**Researched:** 2026-05-07
**Domain:** Public signing API contract, typed redacted signing failures, shared signed-artifact metadata posture, and truthful support-boundary alignment
**Confidence:** High

<user_constraints>
## Locked Decisions

- `Rendro.Sign.sign/2` is the canonical public signing API over a rendered `%Rendro.Artifact{}`.
- `Rendro.render_signed/3` stays convenience sugar only; it is not the conceptual center of the contract.
- `Rendro.Sign.prepare/2` remains the explicit advanced seam for external, remote, or delayed signing workflows.
- `Rendro.render/2` and `Rendro.render_to_artifact/2` must not absorb signing options.
- Public signing failures stay `{:error, %Rendro.Error{stage: :sign, reason: reason, details: redacted_details}}`.
- Public reason values stay stable, typed, compact, and secret-free.
- Signed artifacts must set `metadata.deterministic` to `false`.
- Shared signing metadata stays narrow: signed status, field identity, adapter identity; validator/trust posture stays separate.
- Shared signing metadata must not persist signer identity, certificate trust posture, revocation/timestamp state, compliance labels, or raw CMS/PKCS#7 material.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SIGN-04 | Engineers can sign a rendered `%Rendro.Artifact{}` through a narrow public API that preserves the shipped unsigned/preparation seam instead of replacing it. | Keep `Rendro.Sign.sign/2` canonical, keep `Rendro.render_signed/3` as sugar, and add preflight artifact/field checks so the public contract stays artifact-first and explicit. |
| SIGN-05 | Signing rejects invalid field selection, malformed adapter configuration, and unsupported runtime state with typed, redacted errors before secrets leak into logs or metadata. | Add preflight field validation in `Rendro.Sign`, normalize sign-stage reason tuples in `Rendro.Error`, and keep `details` limited to safe option summaries and adapter key names. |
| SIGN-06 | Signed artifacts expose explicit non-deterministic signing state and safe adapter metadata without persisting private key material, passphrases, or raw tool output. | Split shared `metadata.signing` from adapter-local metadata, scrub or whitelist adapter metadata, and add proof tests for non-determinism plus redaction boundaries. |
</phase_requirements>

## Repo Reality

The repo already contains a draft Phase 60 implementation surface:

- `lib/rendro/sign.ex` defines `sign/2`, `prepare/2`, and `render_signed/3`.
- `lib/rendro/adapters/py_hanko.ex` defines a first-party pyHanko adapter boundary.
- `guides/api_stability.md`, `priv/support_matrix.json`, and `test/docs_contract/signing_claims_test.exs` already publish signing claims.

That means Phase 60 planning should not assume greenfield work. The real job is to tighten the contract around the current code so it matches the milestone boundary truthfully.

## Key Findings

### 1. The public API shape is close, but the sign boundary still needs explicit preflight ownership

`Rendro.Sign.sign/2` already preserves the intended artifact-first seam and rejects prepared or already-signed artifacts. That aligns with the locked boundary.

The main missing piece is field-level preflight. Today `sign/2` does not verify that the requested field exists as a Rendro-authored unsigned signature widget before invoking the adapter. That leaves invalid field selection to the external tool, which weakens the public error contract and risks widening the adapter's role.

**Planning implication:** Phase 60-01 should make `Rendro.Sign` own explicit field existence/signature-widget validation before adapter invocation.

### 2. The sign-stage error taxonomy is incomplete and partially conflated with protection wording

`lib/rendro/error.ex` already contains sign-stage cases, but the coverage is uneven:

- generic `{:invalid_option, option, value}` wording still reads as protection-focused
- generic `{:adapter_failure, adapter, reason}` wording still says "Protection adapter ..."
- `sign/2` currently depends on adapter-returned reasons for some invalid-field and runtime cases that should be normalized at the public seam

**Planning implication:** Phase 60-01 should tighten stable sign-stage reason tuples and make `what/why/next` sign-specific for malformed adapter config, invalid field selection, unsupported artifact state, missing executable, and tool/runtime failures.

### 3. Shared vs adapter-local signing metadata is not fully enforced yet

Current signed-artifact wrapping in `sign/2` is directionally correct:

- shared `metadata.signing` contains `status`, `field`, and `adapter`
- signed artifacts set `metadata.deterministic` to `false`
- adapter-local data lives in `metadata.signing_adapter`

The remaining risk is that `sign/2` currently trusts any map returned by the adapter. The shipped pyHanko metadata is narrow, but the public contract is not yet enforced against future adapter leakage such as credential paths, passphrase indicators with too much detail, raw stderr/stdout, or certificate/trust semantics.

**Planning implication:** Phase 60-02 should add metadata-shape enforcement or scrubbing at the core seam, plus regression tests proving secret-bearing or trust-bearing keys cannot land in shared metadata and are constrained in adapter-local metadata.

### 4. The support surfaces are already ahead of the roadmap and may need tightening

`guides/api_stability.md` and `priv/support_matrix.json` already describe signed-artifact support, the pyHanko path, and `pdfsig` validation posture. That work logically belongs downstream of this phase's public contract and the later adapter/proof phases.

Phase 60 does not need to remove the signing story outright, but it should make sure the published claims do not exceed what the public contract and current tests actually prove. In particular:

- public wording must stay narrow around `sign/2`, `render_signed/3`, non-determinism, and explicit boundary separation from trust/compliance
- shared metadata claims must stay small and validation/trust-free
- if any support-matrix leaves imply stronger first-party proof than current phase evidence justifies, the plan should tighten them

**Planning implication:** Phase 60-02 should include a docs/support lane only for public-contract truthfulness, not for broad support promotion.

## Recommended Plan Split

### 60-01: Signing API option contract, field validation, and typed error taxonomy

Own:

- `lib/rendro/sign.ex`
- `lib/rendro/error.ex`
- `lib/rendro/adapters/py_hanko.ex`
- `test/rendro/sign_test.exs`
- `test/rendro/error_test.exs`

Focus:

- preflight field validation before adapter invocation
- stable sign-stage reason tuples
- redacted option details
- clear separation between public seam ownership and adapter runtime failures

### 60-02: Signed-artifact metadata, redaction coverage, and deterministic-vs-signed behavior proof

Own:

- `lib/rendro/sign.ex`
- `lib/rendro/adapters/py_hanko.ex`
- `test/rendro/sign_test.exs`
- `guides/api_stability.md`
- `priv/support_matrix.json`
- `test/docs_contract/signing_claims_test.exs`

Focus:

- shared vs adapter-local metadata contract enforcement
- explicit non-deterministic signed-artifact posture
- proof that secrets and trust/compliance narratives do not leak through metadata or docs
- narrow public-contract wording only; no viewer or compliance promotion

## Risks and Anti-Patterns

- Letting the adapter own field selection failure semantics. That would widen the external tool boundary and weaken `SIGN-05`.
- Treating prepared artifacts as the default signing input. The locked contract says `sign/2` operates on the original unsigned artifact, while `prepare/2` remains the advanced seam.
- Storing raw tool output, file paths, passphrases, key material hints, or certificate identity in artifact metadata.
- Publishing signed-artifact claims that imply trust, compliance, or viewer proof.
- Turning `Rendro.render_signed/3` into a second semantic path instead of transparent sugar over `render_to_artifact -> sign`.

## Validation Architecture

Phase 60 can stay Nyquist-compatible with existing ExUnit and docs-contract lanes.

### Quick lanes

- `mix test test/rendro/sign_test.exs`
- `mix test test/rendro/error_test.exs`

### Full phase lanes

- `mix test test/rendro/sign_test.exs test/rendro/error_test.exs test/docs_contract/signing_claims_test.exs`
- `mix run scripts/verify_docs.exs`

### Required proof themes

- preflight invalid-field rejection happens before adapter invocation
- malformed adapter config produces stable sign-stage errors with redacted details
- signed artifacts always flip `metadata.deterministic` to `false`
- shared signing metadata remains compact and validator-free
- adapter-local metadata cannot expose secret-bearing or trust-bearing content
- docs/support wording does not overclaim trust, compliance, or viewer posture

## Recommendation

Plan Phase 60 as a contract-tightening phase over existing draft code, not as first introduction of signing support. The execution work should make the current signing surface explicit, preflighted, redacted, and metadata-safe, while keeping docs/support claims no broader than the public contract and current evidence justify.
