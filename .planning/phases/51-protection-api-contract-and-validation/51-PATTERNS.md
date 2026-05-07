---
phase: 51
slug: protection-api-contract-and-validation
status: ready
created: 2026-05-06
updated: 2026-05-06
---

# Phase 51: Protection API Contract and Validation - Pattern Map

**Mapped:** 2026-05-06
**Scope analyzed:** artifact-first protection API, typed protect-stage errors, optional qpdf runtime seam, and password-safe metadata/audit behavior

## Reusable Patterns

### 1. Public helper namespaces stay explicit and narrow

**Primary analogs:** `lib/rendro.ex`, `lib/rendro/protect.ex`, `lib/rendro/form_field.ex`

- Rendro already prefers explicit product seams such as `Rendro.form_field/3` instead of hidden attrs or overloaded render options.
- `Rendro.Protect.password/2` already matches that style and should remain the canonical surface.

**Implication for Phase 51**

- Keep protection as a dedicated namespace rather than pushing it into `Rendro.render/2`.
- Keep `Rendro.render_protected/3` thin and obviously delegating.

### 2. Typed stage errors are the standard failure envelope

**Primary analogs:** `lib/rendro/error.ex`, `lib/rendro/pipeline/validate.ex`, `test/rendro/error_test.exs`

- The repo already uses `Rendro.Error.from_stage/3` for actionable failure context.
- The existing `:protect` stage wording and next-step guidance should remain the one envelope for public protection failures.

**Implication for Phase 51**

- Invalid protection input should become `Rendro.Error` at the public boundary.
- Adapter-specific raw failures may exist internally, but callers should receive typed `:protect` errors with redacted details.

### 3. Optional executable-backed adapters rely on injectable runtime seams

**Primary analogs:** `lib/rendro/adapters/qpdf.ex`, `lib/rendro/adapters/poppler.ex`, `test/rendro/adapters/qpdf_test.exs`

- Runtime executable lookup and command execution are already injectable through application env in qpdf tests.
- Missing executables return data, not raised exceptions or compile-time failures.

**Implication for Phase 51**

- Keep qpdf optional and runtime-detected.
- Harden operational behavior, especially temp-dir cleanup and failure redaction, without changing the dependency posture.

### 4. Artifact transforms preserve the source artifact contract

**Primary analogs:** `lib/rendro/artifact.ex`, `test/rendro/artifact_test.exs`

- `Rendro.Artifact.wrap/3` preserves diagnostics and merges metadata.
- Transform-style surfaces in Rendro should reuse the source artifact rather than invent a parallel result container.

**Implication for Phase 51**

- Protected output should continue to be a normal `%Rendro.Artifact{}`.
- Metadata updates should stay minimal and explicit, with `deterministic: false` and a narrow `metadata.protection` map.

### 5. Security-sensitive metadata is scrubbed before it crosses audit or docs boundaries

**Primary analogs:** `lib/rendro/audit.ex`, `test/docs_contract/protection_claims_test.exs`, `guides/integrations.md`

- The project already has a generic password-key scrubber and already documents that downstream delivery seams should not accept password payloads.
- Docs-contract tests lock security wording and support-matrix claims together.

**Implication for Phase 51**

- Add or keep regression proof that protection-specific details remain safe when scrubbed for audit/logging.
- Reconcile docs and support wording only where it serves the locked protection contract.

## Candidate File Targets

| File | Role | Best analog | Notes |
|------|------|-------------|-------|
| `lib/rendro/protect.ex` | public API + normalization | `lib/rendro.ex` explicit helper style | Current home for validation and redaction; keep unless extraction materially improves clarity. |
| `lib/rendro/protect/adapter.ex` | adapter behavior | existing optional adapter behaviors | Minimal contract; avoid widening beyond `protect/2`. |
| `lib/rendro/adapters/qpdf.ex` | runtime executable seam | `lib/rendro/adapters/poppler.ex` | Likely hardening target for cleanup and failure behavior. |
| `lib/rendro/error.ex` | typed `:protect` envelope | existing stage clauses | Lock exact reason coverage and next-step guidance. |
| `lib/rendro/artifact.ex` | metadata merge boundary | existing `wrap/3` tests | Keep protection metadata narrow and stable. |
| `lib/rendro/audit.ex` | audit redaction seam | existing recursive scrub pattern | Use for proof that password material does not escape. |
| `test/rendro/protect_test.exs` | public contract proof | existing phase tests | Extend for option-shape, redaction, and non-leak regressions. |
| `test/rendro/adapters/qpdf_test.exs` | adapter proof | existing injectable runner tests | Extend for failure and cleanup paths as needed. |
| `test/rendro/artifact_test.exs` | metadata proof | existing wrap tests | Useful for narrow `metadata.protection` assertions. |
| `test/docs_contract/protection_claims_test.exs` | wording and support contract | existing docs-contract lane | Touch only if code truth changes and docs must be brought back in sync. |
