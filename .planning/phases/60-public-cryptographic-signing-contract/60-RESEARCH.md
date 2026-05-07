# Phase 60: Public Cryptographic-Signing Contract - Research

**Researched:** 2026-05-07 [VERIFIED: system date]  
**Domain:** Public signing API contract, typed redacted failure taxonomy, and signed-artifact metadata boundaries for Rendro's artifact-first signing seam. [VERIFIED: user prompt; .planning/ROADMAP.md; .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md]  
**Confidence:** HIGH [VERIFIED: codebase inspection, official-doc cross-checks, and local verification commands]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Public API shape
- **D-01:** The canonical public signing API is `Rendro.Sign.sign/2` over a rendered `%Rendro.Artifact{}`.
- **D-02:** Keep `Rendro.render_signed/3` as convenience sugar only. It is not the conceptual center of the contract.
- **D-03:** Keep `Rendro.Sign.prepare/2` as the explicit advanced seam for external, remote, or delayed signing workflows. It is not the default happy path for ordinary users.
- **D-04:** Do not add signing options to `Rendro.render/2` or `Rendro.render_to_artifact/2`. Rendering and signing remain visibly separate phases.
- **D-05:** Do not introduce a root-level `Rendro.sign/2` or `Rendro.sign/3` in this phase. The focused `Rendro.Sign` namespace is the right Elixir shape for a trust-sensitive post-render transform.
- **D-06:** The render-to-sign phase boundary is intentionally user-visible because it carries determinism, retry semantics, storage/handoff behavior, and support-boundary meaning.

### Error contract
- **D-07:** Keep the public signing failure shape as `{:error, %Rendro.Error{stage: :sign, reason: reason, details: redacted_details}}`.
- **D-08:** Use stable typed reason tuples as the public classification surface rather than public exception structs or per-error modules.
- **D-09:** Use a hybrid contract: narrow stable `reason` values for caller pattern matching, plus redacted `details` for observability and operator triage.
- **D-10:** Signing failures must classify invalid option shape, invalid field selection, unsupported artifact state, malformed adapter configuration, missing executables, and adapter/runtime tool failures as distinct error categories.
- **D-11:** Do not expose raw option values, file paths, passphrases, raw stderr/stdout, certificate subject data, PKCS#11/NSS identifiers, or other secret-bearing adapter details in public `reason`, `why`, `next`, or metadata.
- **D-12:** Preflight field selection in Rendro before invoking the signing adapter so external tools cannot silently widen the contract by creating or guessing fields.

### Signed-artifact metadata posture
- **D-13:** Signed artifacts must advertise non-determinism explicitly by setting `metadata.deterministic` to `false`.
- **D-14:** Keep shared signer-produced metadata narrow and declarative: signed status, explicit field identity, and adapter identity are enough for the public core contract.
- **D-15:** Keep adapter-local metadata in a separate namespaced bucket so the shared metadata contract does not absorb tool-specific semantics.
- **D-16:** Do not store signer identity, certificate trust posture, revocation/timestamp state, compliance labels, raw CMS/PKCS#7 material, or other validation-oriented claims in shared signing metadata.
- **D-17:** Validation/trust posture belongs in a separate validator-produced surface, not in signer-produced metadata. Signing proves a cryptographic event happened; trust and policy evaluation are separate concerns.

### Product, architecture, and DX posture
- **D-18:** Preserve Rendro's artifact-first trust-sensitive architecture: core owns PDF preparation and signing-seam orchestration; optional adapters own concrete signer execution.
- **D-19:** Name APIs and docs by transform stage and boundary semantics (`prepare`, `sign`, `validate`) rather than overloaded umbrella terms that hide what happened to the bytes.
- **D-20:** Optimize for one cohesive recommendation set by default: explicit staged API, narrow typed errors, minimal shared metadata, and truthful support boundaries.
- **D-21:** Shift this preference left for downstream GSD work in this repo: default to recommendation-first synthesis for routine API/policy decisions, and escalate only when a choice materially affects public API shape, determinism guarantees, security posture, or adapter boundaries.

### the agent's Discretion
- Exact helper naming and docs emphasis around `Rendro.render_signed/3`, provided `Rendro.Sign.sign/2` remains the canonical contract.
- Exact signing reason tuple names, provided they stay compact, stable, and secret-free.
- Exact shape of the adapter-local metadata bucket, provided shared signing metadata stays small and non-trust-bearing.

### Deferred Ideas (OUT OF SCOPE)
- Root-level `Rendro.sign/*` convenience APIs.
- Adding signing options directly to `Rendro.render/2` or `Rendro.render_to_artifact/2`.
- Making `Rendro.Sign.prepare/2` the default signing story for ordinary users.
- Shared signing metadata for certificate identity, trust verdicts, revocation/timestamp state, or compliance labels.
- Multi-signature workflows, remote-signing resumption protocols, HSM/KMS/PKCS#11-specific product surfaces, and long-lived-signature narratives.
- Viewer promotion or broad “digital signatures are supported” wording without exact proof per surface.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SIGN-04 | Engineers can sign a rendered `%Rendro.Artifact{}` through a narrow public API that preserves the shipped unsigned/preparation seam instead of replacing it. [VERIFIED: .planning/REQUIREMENTS.md] | Keep `Rendro.Sign.sign/2` canonical, keep `Rendro.render_signed/3` as sugar, and keep `Rendro.Sign.prepare/2` as the explicit advanced seam. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/sign.ex; lib/rendro.ex] |
| SIGN-05 | Signing rejects invalid field selection, malformed adapter configuration, and unsupported runtime state with typed, redacted errors before secrets leak into logs or metadata. [VERIFIED: .planning/REQUIREMENTS.md] | Preflight field selection in `Rendro.Sign`, keep `%Rendro.Error{stage: :sign, reason, details}` as the public envelope, and add direct tests for malformed sign options, invalid adapter-local config, missing executables, and adapter/runtime failures. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/sign.ex; lib/rendro/error.ex; test/rendro/sign_test.exs; test/rendro/error_test.exs] |
| SIGN-06 | Signed artifacts expose explicit non-deterministic signing state and safe adapter metadata without persisting private key material, passphrases, or raw tool output. [VERIFIED: .planning/REQUIREMENTS.md] | Keep shared metadata to `metadata.deterministic == false` plus a narrow `metadata.signing` map, and keep adapter-local facts under a separate namespaced bucket with secret-free values only. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/sign.ex; lib/rendro/adapters/py_hanko.ex; test/rendro/sign_test.exs; test/rendro/adapters/py_hanko_test.exs] |
</phase_requirements>

## Summary

Phase 60 should plan around one public center: `Rendro.Sign.sign/2` over a rendered unsigned `%Rendro.Artifact{}`. That shape already matches Rendro's established artifact-first trust-sensitive pattern in `Rendro.Protect.password/2`, the roadmap, and the Phase 60 locked decisions. `Rendro.render_signed/3` should stay a thin delegation seam, and `Rendro.Sign.prepare/2` should remain the advanced placeholder-oriented path for remote or delayed signing workflows rather than becoming the default story. [VERIFIED: .planning/ROADMAP.md; .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; .planning/phases/51-protection-api-contract-and-validation/51-CONTEXT.md; lib/rendro/protect.ex; lib/rendro/sign.ex; lib/rendro.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html]

The biggest planning risk is not missing functionality; it is contract drift between the draft implementation and the locked boundary. The current draft `sign/2` does not preflight that the requested field exists before adapter invocation, which would allow an adapter such as pyHanko to silently create a field and widen the contract beyond Rendro-owned unsigned widgets. The current `Rendro.Error` message generation also contains draft leakage between `:protect`, `:prepare`, and `:sign`, so several `:sign`-stage failures can render preparation- or protection-worded `why` text unless the planner explicitly tightens the taxonomy. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/sign.ex; lib/rendro/error.ex] [CITED: https://docs.pyhanko.eu/en/v0.25.1/cli-guide/signing.html]

The second risk is scope creep into later phases. The current worktree already contains `guides/api_stability.md`, `priv/support_matrix.json`, `test/docs_contract/signing_claims_test.exs`, `lib/rendro/adapters/py_hanko.ex`, and `lib/rendro/adapters/pdfsig.ex`, but the roadmap assigns first-party signing/validation adapters to Phase 61 and public support-matrix plus guide closure to Phase 62. Phase 60 should therefore lock the public API, redacted failure surface, and metadata contract first; if any docs or support files are touched in this phase, they should stay narrowly API-contract-oriented and avoid proof-backed support claims that belong downstream. [VERIFIED: .planning/ROADMAP.md; guides/api_stability.md; priv/support_matrix.json; test/docs_contract/signing_claims_test.exs; lib/rendro/adapters/py_hanko.ex; lib/rendro/adapters/pdfsig.ex; git status --short]

**Primary recommendation:** Plan Phase 60 as two contracts-only plans: `60-01` for public API shape plus typed redacted sign failures, and `60-02` for signed-artifact metadata plus deterministic-boundary proof, while explicitly deferring proof-backed support claims and live-tool narratives to Phases 61-62. [VERIFIED: .planning/ROADMAP.md; .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; guides/api_stability.md; priv/support_matrix.json]

## Project Constraints (from AGENTS.md)

- Keep `rendro` core pure and free of hard Phoenix, Oban, or admin-tool dependencies. [VERIFIED: AGENTS.md]
- Preserve deterministic and advisory verification lane separation in CI and docs. [VERIFIED: AGENTS.md]
- Treat documentation claims as contracts and do not claim unsupported capabilities. [VERIFIED: AGENTS.md]
- Prefer optional dependency guards and compile/runtime checks for integrations. [VERIFIED: AGENTS.md]
- Keep the architecture artifact-first with `build -> compose -> measure -> paginate -> render -> validate`, and treat errors and telemetry as product behavior. [VERIFIED: AGENTS.md]
- No project-local skills were found under `.claude/skills/` or `.agents/skills/`. [VERIFIED: directory listing during research]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public `Rendro.Sign.sign/2` contract | API / Backend | — | This is the library-owned post-render transform surface that accepts an artifact, validates options, and orchestrates adapter execution. [VERIFIED: lib/rendro/sign.ex; .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md] |
| `Rendro.render_signed/3` convenience wrapper | API / Backend | — | The top-level helper only renders to an artifact and delegates to `Rendro.Sign.sign/2`; it should not own independent semantics. [VERIFIED: lib/rendro.ex; lib/rendro/sign.ex; .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md] |
| Signed-artifact metadata contract | API / Backend | Database / Storage | The library owns the metadata shape, while downstream storage or delivery surfaces may persist the artifact and its metadata later. [VERIFIED: lib/rendro/sign.ex; lib/rendro/artifact.ex; .planning/STATE.md] |
| Adapter-local signer execution | API / Backend | — | Core Rendro should validate and wrap, but concrete signer invocation remains in optional adapter modules behind `Rendro.Sign.Adapter`. [VERIFIED: lib/rendro/sign/adapter.ex; lib/rendro/adapters/py_hanko.ex; AGENTS.md] |
| Support-matrix and guide claims | CDN / Static | API / Backend | These are documentation contracts derived from the API and proof lanes, and the roadmap places their closure after adapter and live-proof work. [VERIFIED: .planning/ROADMAP.md; guides/api_stability.md; priv/support_matrix.json] |

## Standard Stack

Phase 60 does not need new Hex dependencies. It should use the existing Rendro core modules, ExUnit, and the repo's canonical docs-contract harness. [VERIFIED: mix.exs; test tree; scripts/verify_docs.exs]

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 [VERIFIED: `elixir --version`] | Runtime for the signing-contract code and tests. [VERIFIED: mix.exs; `elixir --version`] | Matches the declared project runtime and CI toolchain. [VERIFIED: AGENTS.md; .github/workflows/ci.yml] |
| ExUnit | bundled with Elixir 1.19.5 [VERIFIED: mix.exs; `mix --version`] | Contract tests for sign-stage behavior, redaction, and metadata boundaries. [VERIFIED: test/rendro/sign_test.exs; test/rendro/error_test.exs] | Existing proof lanes already use ExUnit for public-contract verification. [VERIFIED: mix.exs; test tree] |
| `Rendro.Sign` | repo-local current worktree [VERIFIED: lib/rendro/sign.ex] | Canonical public signing surface and advanced preparation seam. [VERIFIED: lib/rendro/sign.ex; .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md] | Already matches the locked artifact-first namespace direction. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/sign.ex] |
| `Rendro.Error` | repo-local current worktree [VERIFIED: lib/rendro/error.ex] | Stable typed `%Rendro.Error{}` envelope for `:sign` failures. [VERIFIED: lib/rendro/error.ex] | The locked decisions explicitly keep `%Rendro.Error{stage: :sign, reason, details}` as the public error shape. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Rendro.Artifact` | repo-local current worktree [VERIFIED: lib/rendro/artifact.ex] | Wraps transformed bytes and metadata after signing. [VERIFIED: lib/rendro/artifact.ex; lib/rendro/sign.ex] | Use for every post-render transform rather than inventing a signing-only carrier. [VERIFIED: lib/rendro/protect.ex; lib/rendro/sign.ex] |
| `Rendro.Sign.Adapter` | repo-local current worktree [VERIFIED: lib/rendro/sign/adapter.ex] | Optional adapter behavior for signer execution and adapter-local metadata. [VERIFIED: lib/rendro/sign/adapter.ex] | Use for fake adapters in Phase 60 tests and for real adapters in Phase 61. [VERIFIED: test/rendro/sign_test.exs; .planning/ROADMAP.md] |
| `mix docs.contract` | repo-local Mix task [VERIFIED: lib/mix/tasks/docs.contract.ex; scripts/verify_docs.exs] | Canonical docs-contract entry point. [VERIFIED: lib/mix/tasks/docs.contract.ex; scripts/verify_docs.exs] | Use as a secondary proof lane when phase-owned docs are touched; do not let it substitute for direct sign/error tests. [VERIFIED: scripts/verify_docs.exs; .planning/ROADMAP.md] |
| `pyhanko` CLI | external executable, not installed locally [VERIFIED: lib/rendro/adapters/py_hanko.ex; `command -v pyhanko`] | Future real signer backend behind the optional adapter boundary. [VERIFIED: lib/rendro/adapters/py_hanko.ex; .planning/ROADMAP.md] | Not required for Phase 60 unit-contract work; Phase 61 owns the first-party adapter and Phase 62 owns the live proof lane. [VERIFIED: .planning/ROADMAP.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Rendro.Sign.sign/2` as the canonical surface | Root-level `Rendro.sign/2` | Root-level placement hides the trust-sensitive post-render boundary and conflicts with the locked namespace decision. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| `Rendro.render_signed/3` as sugar only | Make `render_signed/3` the primary API | That would blur render and sign into one conceptual step and weaken the visible unsigned/preparation boundary. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro.ex] |
| Stable reason tuples on `%Rendro.Error{}` | Public exception structs or per-error modules | Tuples preserve pattern-matching stability while avoiding an explosion of public modules for adapter- and boundary-specific failures. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/error.ex] [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html] |
| Explicit staged `prepare -> sign -> validate` vocabulary | One broad “signature support” umbrella | Staged vocabulary matches established libraries and keeps trust/validation claims separable from signing itself. [VERIFIED: .planning/phases/56-writer-and-external-signing-preparation-seam/56-CONTEXT.md; .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html] [CITED: https://docs.pyhanko.eu/en/v0.25.1/cli-guide/validation.html] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** No new Hex packages are required for Phase 60. The local research environment provides `Elixir 1.19.5`, `Mix 1.19.5`, `pdfsig 26.04.0`, `OpenSSL 3.6.2`, and `qpdf 12.3.2`; `pyhanko` is not installed. [VERIFIED: `elixir --version`; `mix --version`; `pdfsig -v`; `openssl --version`; `qpdf --version`; `command -v pyhanko`]

## Concrete Touch Points and Plan Split

### Plan 60-01: Signing API option contract, field validation, and typed error taxonomy

- `lib/rendro/sign.ex` should own canonical option normalization, explicit field preflight for `sign/2`, unsupported-artifact checks, and the `render_signed/3` delegation seam. The current file already has option normalization and prepared/signed artifact guards, but it does not verify that `sign/2` targets a real unsigned signature widget before adapter invocation. [VERIFIED: lib/rendro/sign.ex] [CITED: https://docs.pyhanko.eu/en/v0.25.1/cli-guide/signing.html]
- `lib/rendro/error.ex` should own the final stable `:sign` reason taxonomy and operator-facing `what/why/next` strings. The current draft contains cross-stage wording drift, including preparation-worded `why` text for generic `:sign` field failures and a protection-worded fallback for unknown adapter failures. [VERIFIED: lib/rendro/error.ex]
- `lib/rendro/sign/adapter.ex` should remain a narrow optional behavior seam only; do not widen it with validator or trust semantics in this phase. [VERIFIED: lib/rendro/sign/adapter.ex; AGENTS.md]
- `test/rendro/sign_test.exs` and `test/rendro/error_test.exs` should become the contract lock for sign-stage field validation, malformed adapter config, missing executable guidance, unsupported artifact state, and secret-free details. The current tests cover the happy path, malformed top-level options, and prepared-artifact rejection, but they do not yet cover public `sign/2` field-preflight failures or full malformed adapter config coverage through the public API. [VERIFIED: test/rendro/sign_test.exs; test/rendro/error_test.exs; mix test test/rendro/sign_test.exs test/rendro/error_test.exs test/docs_contract/signing_claims_test.exs]

### Plan 60-02: Signed-artifact metadata, redaction coverage, and deterministic-vs-signed behavior proof

- `lib/rendro/sign.ex` should lock the shared metadata contract to `metadata.deterministic == false` plus a narrow `metadata.signing` map, with adapter-local details isolated in `metadata.signing_adapter`. The current draft already follows that shape. [VERIFIED: lib/rendro/sign.ex; test/rendro/sign_test.exs]
- `lib/rendro/adapters/py_hanko.ex` is useful as a source of secret-free adapter-local metadata examples such as `tool`, `credential_source`, `chain_count`, and `passphrase_supplied`, but those keys should remain adapter-local, not shared-core contract. [VERIFIED: lib/rendro/adapters/py_hanko.ex; test/rendro/adapters/py_hanko_test.exs]
- `guides/api_stability.md`, `priv/support_matrix.json`, and `test/docs_contract/signing_claims_test.exs` already contain signed-artifact support language, but the roadmap assigns proof-backed support closure to later phases. The planner should either keep these files untouched in Phase 60 or limit changes to contract wording that does not imply shipped first-party support or live validation proof. [VERIFIED: .planning/ROADMAP.md; guides/api_stability.md; priv/support_matrix.json; test/docs_contract/signing_claims_test.exs; git status --short]

## Architecture Patterns

### System Architecture Diagram

```text
%Rendro.Document{}
  |
  v
Rendro.render_to_artifact/2
  |
  v
unsigned %Rendro.Artifact{metadata.deterministic?}
  |
  +--> Rendro.Sign.prepare/2
  |      |
  |      +--> placeholder patch + manifest
  |      +--> optional adapter-local preparation metadata
  |      `--> prepared artifact for remote/delayed workflows
  |
  `--> Rendro.Sign.sign/2
         |
         +--> normalize public opts
         +--> verify unsigned artifact state
         +--> verify requested field maps to a Rendro-authored unsigned /Sig widget
         +--> call optional signing adapter
         +--> wrap signed bytes
         `--> shared metadata: deterministic=false + narrow signing map

Signed artifact
  |
  +--> adapter-local metadata only
  `--> future validator surface owns trust / integrity / revocation / compliance posture
```

This staged flow matches Rendro's artifact-first architecture and mirrors the established external-signing split documented by PDFBox and pyHanko. [VERIFIED: AGENTS.md; .planning/phases/56-writer-and-external-signing-preparation-seam/56-CONTEXT.md; lib/rendro/sign.ex] [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html] [CITED: https://docs.pyhanko.eu/en/v0.25.1/cli-guide/signing.html]

### Recommended Project Structure

```text
lib/
├── rendro.ex                    # render_signed/3 sugar only
├── rendro/sign.ex               # public sign/prepare contract, field preflight, metadata wrapping
├── rendro/sign/adapter.ex       # optional signer behavior boundary
├── rendro/error.ex              # stable :sign error vocabulary and guidance
└── rendro/artifact.ex           # post-render transform carrier

test/
├── rendro/sign_test.exs         # happy path, public option contract, metadata contract
├── rendro/error_test.exs        # public wording/redaction contract
└── rendro/adapters/py_hanko_test.exs  # adapter-local option normalization examples
```

Keep support-matrix and guide closure outside this structure unless the phase intentionally accepts downstream scope. [VERIFIED: .planning/ROADMAP.md; git status --short]

### Pattern 1: Canonical Artifact-First Signing

**What:** Public signing should always accept an already rendered unsigned artifact, not a document or prepared placeholder artifact. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/sign.ex]
**When to use:** For the canonical API and all primary docs/examples. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md]
**Example:**
```elixir
# Source: test/rendro/sign_test.exs
{:ok, artifact} = Rendro.render_to_artifact(doc, deterministic: true)

{:ok, signed} =
  Rendro.Sign.sign(artifact,
    field: "customer_signature",
    adapter: FakeSignerAdapter,
    adapter_opts: [key: "/tmp/key.pem", cert: "/tmp/cert.pem"]
  )
```

### Pattern 2: Public Tuple Reasons + Redacted Details

**What:** Keep `error.reason` stable and small for pattern matching, and put only redacted triage facts in `error.details`. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/sign.ex; lib/rendro/error.ex]
**When to use:** For invalid field selection, invalid adapter configuration, missing executable, prepared/signed artifact misuse, and adapter/runtime failures. [VERIFIED: .planning/REQUIREMENTS.md; lib/rendro/error.ex]
**Example:**
```elixir
# Source: lib/rendro/sign.ex + lib/rendro/error.ex
{:error,
 %Rendro.Error{
   stage: :sign,
   reason: {:invalid_option, :adapter_opts, value},
   details: %{adapter: Rendro.Adapters.PyHanko, field: "customer_signature", adapter_opt_keys: [:cert, :key]}
 }}
```

### Pattern 3: Shared Metadata Narrow, Validator Metadata Separate

**What:** Treat signing metadata as proof that a signing transform occurred, not as a trust verdict. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/sign.ex]
**When to use:** For all metadata stored on signed artifacts and for all docs wording in this phase. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md]
**Example:**
```elixir
# Source: lib/rendro/sign.ex
%{
  deterministic: false,
  signing: %{
    status: :signed,
    field: "customer_signature",
    adapter: Rendro.Adapters.PyHanko
  },
  signing_adapter: %{
    tool: :pyhanko,
    credential_source: :pemder,
    chain_count: 1,
    passphrase_supplied: true
  }
}
```

### Anti-Patterns to Avoid

- **Field auto-creation during `sign/2`:** pyHanko can create a field if it does not exist; Rendro should reject that at its own boundary to preserve the authored unsigned-widget contract. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/sign.ex] [CITED: https://docs.pyhanko.eu/en/v0.25.1/cli-guide/signing.html]
- **Render-time signing options:** Do not add signing keys to `Rendro.render/2` or `Rendro.render_to_artifact/2`; that collapses render and trust-sensitive transform semantics. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md]
- **Shared metadata that implies trust or compliance:** Do not store signer identity, revocation status, timestamps, PAdES labels, or certificate trust hints in `metadata.signing`. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md] [CITED: https://docs.pyhanko.eu/en/v0.25.1/cli-guide/validation.html] [CITED: https://www.gnupg.org/gph/en/manual/x332.html]
- **Using support-matrix proof language as a substitute for API-contract proof:** The roadmap places live-tool support closure later. Phase 60 should prove boundary semantics with unit/docs tests, not by publishing broader support claims early. [VERIFIED: .planning/ROADMAP.md; guides/api_stability.md; priv/support_matrix.json]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Public failure classification | Public exception-module hierarchy | Stable `reason` tuples on `%Rendro.Error{}` | Tuples are easier to pattern match, version, and redact than a large exception taxonomy. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/error.ex] [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html] |
| Signer execution in core | In-core key custody or crypto implementation | Optional adapter boundary behind `Rendro.Sign.Adapter` | AGENTS and the roadmap keep trust-sensitive ecosystem work optional and outside pure core. [VERIFIED: AGENTS.md; .planning/ROADMAP.md; lib/rendro/sign/adapter.ex] |
| Trust/compliance conclusions in signer metadata | Ad hoc validation flags on signed artifacts | Separate validator-produced surface in later phases | pyHanko and GnuPG both distinguish cryptographic validity from trust configuration; Rendro should do the same. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md] [CITED: https://docs.pyhanko.eu/en/v0.25.1/cli-guide/validation.html] [CITED: https://www.gnupg.org/gph/en/manual/x332.html] |
| Placeholder/signing collapse | One broad “sign” helper that also owns prepare semantics | Keep `prepare/2` and `sign/2` as sibling stages | PDFBox and the prior Rendro phases both show that staged signing avoids hidden state and boundary confusion. [VERIFIED: .planning/phases/56-writer-and-external-signing-preparation-seam/56-CONTEXT.md; lib/rendro/sign.ex] [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html] |

**Key insight:** The hard problem in this phase is boundary ownership, not cryptographic capability. The planner should spend effort locking who is allowed to claim what, not adding more signer features. [VERIFIED: .planning/ROADMAP.md; .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Allowing `sign/2` to Sign Any Field Name the Adapter Accepts
**What goes wrong:** The adapter creates or guesses a field that Rendro never authored, widening the public contract beyond unsigned existing-field signing. [VERIFIED: lib/rendro/sign.ex; .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md]  
**Why it happens:** pyHanko's `--field` option can create a field if it does not already exist. [CITED: https://docs.pyhanko.eu/en/v0.25.1/cli-guide/signing.html]  
**How to avoid:** Preflight field existence and type inside `Rendro.Sign.sign/2` before adapter invocation, using the same rendered-widget lookup discipline as preparation. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/sign.ex]  
**Warning signs:** A missing or mistyped field name reaches the adapter and produces a signed output instead of a typed `:sign` error. [VERIFIED: lib/rendro/sign.ex]

### Pitfall 2: Cross-Stage Error Wording Drift
**What goes wrong:** Sign-stage failures render preparation- or protection-specific `why` text, confusing callers and making the public taxonomy unstable. [VERIFIED: lib/rendro/error.ex]  
**Why it happens:** `Rendro.Error.from_stage/3` currently keys many `why` clauses only by reason tuple, not by stage. [VERIFIED: lib/rendro/error.ex]  
**How to avoid:** Add sign-specific `why` and `next_step` clauses for all public reason tuples Phase 60 exposes, and test them directly through `Rendro.Error` and `Rendro.Sign.sign/2`. [VERIFIED: lib/rendro/error.ex; test/rendro/error_test.exs]  
**Warning signs:** `error.stage == :sign` but `error.why` contains “protection” or “signing preparation”. [VERIFIED: lib/rendro/error.ex]

### Pitfall 3: Publishing Support Claims Before the Proof Lane Exists
**What goes wrong:** Guides or support-matrix rows imply shipped pyHanko/pdfsig support before the roadmap's adapter and live-proof phases land. [VERIFIED: .planning/ROADMAP.md; guides/api_stability.md; priv/support_matrix.json; test/docs_contract/signing_claims_test.exs]  
**Why it happens:** Draft implementation files and docs are already present in the worktree. [VERIFIED: git status --short]  
**How to avoid:** Keep Phase 60 focused on contract tests and narrow API docs, and defer proof-backed support wording to Phases 61-62 unless the milestone order is intentionally changed. [VERIFIED: .planning/ROADMAP.md]  
**Warning signs:** `priv/support_matrix.json` or `guides/api_stability.md` become merge-blocking evidence for Phase 60 requirement closure. [VERIFIED: .planning/ROADMAP.md; scripts/verify_docs.exs]

### Pitfall 4: Treating “signed” as “trusted”
**What goes wrong:** The artifact metadata or docs imply signer identity, certificate trust, timestamp validity, or compliance posture simply because a cryptographic signature was added. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; guides/api_stability.md]  
**Why it happens:** Validation and trust are separate questions from signature creation, and both pyHanko and GnuPG document that separation explicitly. [CITED: https://docs.pyhanko.eu/en/v0.25.1/cli-guide/validation.html] [CITED: https://www.gnupg.org/gph/en/manual/x332.html]  
**How to avoid:** Keep shared signing metadata declarative and move trust/evidence semantics to the future validator surface. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md]  
**Warning signs:** New metadata keys mention trust, certificate subjects, revocation, OCSP, CRL, TSA, LTV, or PAdES. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/sign.ex]

## Code Examples

Verified patterns from the current repo and official docs:

### Canonical convenience sugar remains secondary
```elixir
# Source: lib/rendro.ex
def render_signed(%Document{} = doc, render_opts \\ [], sign_opts)
    when is_list(render_opts) and is_list(sign_opts) do
  with {:ok, artifact} <- render_to_artifact(doc, render_opts) do
    Sign.sign(artifact, sign_opts)
  end
end
```

### Explicit external-signing split in a mature PDF library
```text
# Source: PDFBox ExternalSigningSupport
getContent()    -> get PDF content to be signed
setSignature()  -> set CMS signature bytes to PDF
```

This is the same ownership split Rendro should preserve between `prepare`, `sign`, and later `validate`. [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Broad “signature support” umbrella | Explicit staged vocabulary: author unsigned field, prepare artifact, sign artifact, validate artifact. [VERIFIED: .planning/phases/55-signature-field-authoring-contract/55-CONTEXT.md; .planning/phases/56-writer-and-external-signing-preparation-seam/56-CONTEXT.md; .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] | Rendro adopted this across Phases 55-57. [VERIFIED: .planning/STATE.md; roadmap/history docs] | Keeps support claims truthful and prevents trust/compliance leakage. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] |
| Field creation during signing for convenience | Existing Rendro-authored field selection only. [VERIFIED: .planning/phases/55-signature-field-authoring-contract/55-CONTEXT.md; .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md] | Locked before Phase 60 planning. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md] | Preserves visible unsigned-field ownership and avoids adapter-defined semantics. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md] |
| Signed output treated as just another deterministic render result | Signed output explicitly marked non-deterministic. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/sign.ex] | Current draft and roadmap already align here. [VERIFIED: lib/rendro/sign.ex; .planning/ROADMAP.md] | Maintains honest retry/cache/storage semantics. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md] |

**Deprecated/outdated:**
- Treating signer execution, trust validation, and compliance claims as one feature bundle is outdated for this repo and contradicted by the current roadmap. [VERIFIED: .planning/ROADMAP.md; .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md]  
- Relying on support-matrix or viewer wording to stand in for live signer proof is outdated because Phases 61-62 separate those responsibilities explicitly. [VERIFIED: .planning/ROADMAP.md]

## Assumptions Log

All material claims in this research were verified in the codebase, by local command, or by official documentation. No `[ASSUMED]` claims remain. [VERIFIED: this file]

## Open Questions

1. **Should the current draft support-matrix and guide changes stay in Phase 60 at all?**
   - What we know: the worktree already contains signed-artifact support wording and docs-contract coverage, but the roadmap assigns proof-backed support closure to Phases 61-62. [VERIFIED: .planning/ROADMAP.md; guides/api_stability.md; priv/support_matrix.json; test/docs_contract/signing_claims_test.exs; git status --short]
   - What's unclear: whether the maintainer wants to keep that downstream work staged but unshipped, or explicitly pull it back so Phase 60 stays contract-only. [VERIFIED: current worktree state; roadmap]
   - Recommendation: plan Phase 60 assuming those files are out of scope for requirement closure; if they are touched, keep the wording narrower than the current draft and avoid using them as primary proof. [VERIFIED: .planning/ROADMAP.md; scripts/verify_docs.exs]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Contract code + tests | ✓ [VERIFIED: `elixir --version`] | 1.19.5 [VERIFIED: `elixir --version`] | — |
| Mix | Test and docs-contract commands | ✓ [VERIFIED: `mix --version`] | 1.19.5 [VERIFIED: `mix --version`] | — |
| `pyhanko` CLI | Future real signing adapter and live signing proof | ✗ [VERIFIED: `command -v pyhanko`] | — | Use fake adapters and public-boundary tests in Phase 60; real-tool proof is downstream. [VERIFIED: test/rendro/sign_test.exs; .planning/ROADMAP.md] |
| `pdfsig` | Future validation adapter and live proof | ✓ [VERIFIED: `command -v pdfsig`; `pdfsig -v`] | 26.04.0 [VERIFIED: `pdfsig -v`] | Not required for Phase 60 requirement closure. [VERIFIED: .planning/ROADMAP.md] |
| OpenSSL | Future signing fixture generation | ✓ [VERIFIED: `command -v openssl`; `openssl --version`] | 3.6.2 [VERIFIED: `openssl --version`] | Not required for Phase 60 requirement closure. [VERIFIED: .planning/ROADMAP.md] |
| `qpdf` | Existing protection/live proof tooling | ✓ [VERIFIED: `command -v qpdf`; `qpdf --version`] | 12.3.2 [VERIFIED: `qpdf --version`] | Not required for Phase 60 requirement closure. [VERIFIED: .planning/ROADMAP.md] |

**Missing dependencies with no fallback:**
- None for Phase 60 itself. `pyhanko` is missing locally, but the roadmap puts real-tool signing work in later phases and Phase 60 can close through fake adapters plus contract tests. [VERIFIED: .planning/ROADMAP.md; test/rendro/sign_test.exs; `command -v pyhanko`]

**Missing dependencies with fallback:**
- `pyhanko` for real signer execution. Fallback for this phase is unit-level fake adapters and redaction/metadata proof without live signing. [VERIFIED: test/rendro/sign_test.exs; .planning/ROADMAP.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5. [VERIFIED: mix.exs; `mix --version`] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/rendro/sign_test.exs test/rendro/error_test.exs` [VERIFIED: mix test test/rendro/sign_test.exs test/rendro/error_test.exs test/docs_contract/signing_claims_test.exs] |
| Full suite command | `mix test && mix docs.contract` [VERIFIED: mix.exs; lib/mix/tasks/docs.contract.ex; mix docs.contract] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SIGN-04 | `Rendro.Sign.sign/2` is the canonical artifact-first seam, `render_signed/3` is sugar, and prepared artifacts are rejected. [VERIFIED: .planning/REQUIREMENTS.md; lib/rendro/sign.ex; lib/rendro.ex] | unit | `mix test test/rendro/sign_test.exs` | ✅ [VERIFIED: test/rendro/sign_test.exs] |
| SIGN-05 | Invalid field selection, malformed adapter config, unsupported artifact state, missing executable, and adapter/runtime failures return typed redacted sign errors. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md] | unit | `mix test test/rendro/sign_test.exs test/rendro/error_test.exs` | ✅ [VERIFIED: test/rendro/sign_test.exs; test/rendro/error_test.exs] |
| SIGN-06 | Signed artifacts expose non-deterministic state plus safe shared/adapter-local metadata without secrets. [VERIFIED: .planning/REQUIREMENTS.md; lib/rendro/sign.ex] | unit | `mix test test/rendro/sign_test.exs test/rendro/adapters/py_hanko_test.exs` | ✅ [VERIFIED: test/rendro/sign_test.exs; test/rendro/adapters/py_hanko_test.exs] |

### Sampling Rate

- **Per task commit:** `mix test test/rendro/sign_test.exs test/rendro/error_test.exs` [VERIFIED: local passing command family; mix test test/rendro/sign_test.exs test/rendro/error_test.exs test/docs_contract/signing_claims_test.exs]
- **Per wave merge:** `mix test test/rendro/sign_test.exs test/rendro/error_test.exs test/rendro/adapters/py_hanko_test.exs` [VERIFIED: test files present]
- **Phase gate:** `mix test && mix docs.contract`, but Phase 60 requirement closure should rely on the sign/error unit lanes rather than future-phase support-claim assertions. [VERIFIED: mix.exs; mix docs.contract; .planning/ROADMAP.md]

### Wave 0 Gaps

- [ ] Add a direct `sign/2` test for missing or mistyped field names that proves Rendro rejects the call before adapter invocation. [VERIFIED: test/rendro/sign_test.exs; lib/rendro/sign.ex]
- [ ] Add public-boundary tests for malformed adapter-local config, missing executable, and adapter/runtime failures through `Rendro.Sign.sign/2`, not only through `Rendro.Adapters.PyHanko`. [VERIFIED: test/rendro/sign_test.exs; test/rendro/adapters/py_hanko_test.exs]
- [ ] Add wording tests that ensure `:sign` failures never emit preparation/protection wording in `error.why` or `error.next`. [VERIFIED: lib/rendro/error.ex; test/rendro/error_test.exs]
- [ ] Decide whether `test/docs_contract/signing_claims_test.exs` remains a Phase 60 gate or is deferred to the later support-contract phase as the roadmap suggests. [VERIFIED: .planning/ROADMAP.md; test/docs_contract/signing_claims_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | Not part of the public signing contract. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md] |
| V3 Session Management | no [VERIFIED: phase scope] | Not part of the public signing contract. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md] |
| V4 Access Control | no [VERIFIED: phase scope] | The library does not own runtime authorization policy here. [VERIFIED: AGENTS.md; phase scope] |
| V5 Input Validation | yes [VERIFIED: SIGN-05; phase scope] | Validate `field`, option shapes, adapter module contracts, and adapter-local config before execution. [VERIFIED: .planning/REQUIREMENTS.md; lib/rendro/sign.ex; lib/rendro/adapters/py_hanko.ex] |
| V6 Cryptography | yes [VERIFIED: phase scope] | Keep signing as adapter-owned execution, never hand-roll crypto or key custody in core, and separate signing from trust validation. [VERIFIED: AGENTS.md; .planning/ROADMAP.md; lib/rendro/sign/adapter.ex] [CITED: https://docs.pyhanko.eu/en/v0.25.1/cli-guide/validation.html] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret leakage in `reason`, `details`, or metadata | Information Disclosure | Redact adapter opts to safe key names only, never store paths, passphrases, raw tool output, or certificate identity in shared surfaces. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/sign.ex; lib/rendro/adapters/py_hanko.ex] |
| Adapter silently signs a different or newly created field | Tampering | Preflight field existence/type in `Rendro.Sign.sign/2` before calling the adapter. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/sign.ex] [CITED: https://docs.pyhanko.eu/en/v0.25.1/cli-guide/signing.html] |
| Confusing signed output with trusted or compliant output | Spoofing | Keep signing metadata narrow and move trust/compliance claims to later validator/proof surfaces. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; .planning/ROADMAP.md] [CITED: https://docs.pyhanko.eu/en/v0.25.1/cli-guide/validation.html] [CITED: https://www.gnupg.org/gph/en/manual/x332.html] |
| Reusing prepared artifacts on the canonical sign path | Tampering | Reject prepared artifacts through a dedicated `:prepared_artifact_not_signable` reason. [VERIFIED: lib/rendro/sign.ex; test/rendro/sign_test.exs] |
| Raw tool failures surfacing in public operator text | Information Disclosure | Normalize to typed adapter/runtime failure reasons and keep raw stderr/stdout out of the public envelope. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/error.ex; test/rendro/adapters/py_hanko_test.exs] |

## Sources

### Primary (HIGH confidence)
- `/.planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md` - locked API, error, and metadata decisions. [VERIFIED: codebase read]
- `/.planning/REQUIREMENTS.md` - `SIGN-04`, `SIGN-05`, `SIGN-06` phase requirements. [VERIFIED: codebase read]
- `/.planning/ROADMAP.md` - phase split, downstream adapter/proof ordering, and success criteria. [VERIFIED: codebase read]
- `/lib/rendro/sign.ex`, `/lib/rendro.ex`, `/lib/rendro/error.ex`, `/lib/rendro/sign/adapter.ex`, `/lib/rendro/adapters/py_hanko.ex`, `/lib/rendro/adapters/pdfsig.ex` - live public seam and draft implementation details. [VERIFIED: codebase read]
- `/test/rendro/sign_test.exs`, `/test/rendro/error_test.exs`, `/test/rendro/adapters/py_hanko_test.exs`, `/test/docs_contract/signing_claims_test.exs` - current proof coverage and gaps. [VERIFIED: codebase read]
- `https://docs.pyhanko.eu/en/v0.25.1/cli-guide/signing.html` - field handling, signer flows, and long-lived-signature scope. [CITED: official docs]
- `https://docs.pyhanko.eu/en/v0.25.1/cli-guide/validation.html` - separation between cryptographic integrity, trust, incremental updates, and timestamp/revocation concerns. [CITED: official docs]
- `https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html` - explicit external-signing content/signature split. [CITED: official docs]
- `https://hexdocs.pm/phoenix/Phoenix.Token.html` - explicit `sign`/`verify` vocabulary and typed result precedent. [CITED: official docs]
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - focused namespace and explicit staged-operation precedent. [CITED: official docs]

### Secondary (MEDIUM confidence)
- `https://hexdocs.pm/plug_crypto/Plug.Crypto.html` - namespace and crypto-boundary precedent for explicit helper modules. [CITED: official docs]
- `https://github.com/vbuch/node-signpdf` - placeholder-first signing separation and fragility warning around string-based placeholder handling. [CITED: official repository]
- `https://www.gnupg.org/gph/en/manual/x332.html` - trust-versus-validity separation analogy. [CITED: official docs]

### Tertiary (LOW confidence)
- None. [VERIFIED: this file]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 60 does not require new dependencies, and the relevant runtime/test tooling was verified locally. [VERIFIED: mix.exs; `elixir --version`; `mix --version`; environment checks]
- Architecture: HIGH - The contract shape is locked by Phase 60 context and reinforced by live repo patterns plus official staged-signing references. [VERIFIED: .planning/phases/60-public-cryptographic-signing-contract/60-CONTEXT.md; lib/rendro/sign.ex] [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html] [CITED: https://docs.pyhanko.eu/en/v0.25.1/cli-guide/signing.html]
- Pitfalls: HIGH - The main pitfalls are directly visible in the current draft implementation and roadmap phase ordering. [VERIFIED: lib/rendro/sign.ex; lib/rendro/error.ex; .planning/ROADMAP.md; git status --short]

**Research date:** 2026-05-07 [VERIFIED: system date]  
**Valid until:** 2026-06-06 for repo-local contract research, or earlier if the signing worktree changes materially. [VERIFIED: current worktree state]
