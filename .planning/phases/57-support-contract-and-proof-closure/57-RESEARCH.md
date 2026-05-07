# Phase 57: Support Contract and Proof Closure - Research

**Researched:** 2026-05-06 [VERIFIED: current session date]
**Domain:** Truthful support-matrix publication, docs-contract closure, and proof-lane separation for unsigned signature widgets and artifact-first signing preparation [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md; VERIFIED: .planning/milestones/v2.0-ROADMAP.md]
**Confidence:** HIGH [VERIFIED: repo inspection; VERIFIED: targeted tests; CITED: https://pdf-lib.js.org/docs/api/classes/pdfsignature; CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html; CITED: https://hexapdf.gettalong.org/documentation/digital-signatures/signing-pdfs-howto.html]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Support matrix shape
- **D-01:** Keep unsigned signature authoring inside the existing `forms` family. Phase 55's `Rendro.signature_field/2` contract remains part of authored form support, not a new top-level signature taxonomy.
- **D-02:** Add a sibling top-level `signing_preparation` family in `priv/support_matrix.json` for the Phase 56 artifact-first post-render seam. Do not bury artifact preparation under `forms`.
- **D-03:** Do not introduce a broad top-level `signatures` family in Phase 57. That would create unnecessary taxonomy churn and imply a larger subsystem than Rendro truthfully supports today.
- **D-04:** Keep the support matrix family-first and explicit, following existing `forms`, `embedded_files`, `links`, and `protection` precedent rather than adding a generic `"surfaces"` wrapper.
- **D-05:** The new `signing_preparation` family should stay narrow and product-facing: express only the prepared-artifact contract and explicitly unsupported trust/compliance narratives. Do not let the family name or leaves read like full digital-signature support.

### Public wording split
- **D-06:** Split public documentation into separate support-boundary sections for:
  - unsigned signature fields/widgets
  - signing preparation
- **D-07:** Add one very short shared preamble that explains the lifecycle at a high level:
  - author unsigned placeholder
  - render artifact
  - prepare artifact for an external signer
  - external signing and verification remain outside Rendro core
- **D-08:** Keep that preamble brief and policy-oriented, not architectural. Its job is to prevent category confusion, not to explain the implementation.
- **D-09:** Do not publish one blended “signature support” section. That wording invites readers to collapse authored placeholders, prepared artifacts, viewer behavior, and cryptographic validity into a single claim.
- **D-10:** Each section must state three things in order:
  - the narrow supported surface
  - the proof lane that backs that surface
  - the unsupported narratives that remain outside contract

### Viewer-proof posture
- **D-11:** Default all signature-related viewer rows to `unverified` in Phase 57 unless a named viewer/surface pair already has recorded checklist evidence.
- **D-12:** Keep viewer claims per surface and per viewer. Do not publish a blanket signature-viewer claim.
- **D-13:** Treat structural correctness and viewer behavior as separate proof lanes. A structurally correct unsigned or prepared artifact does not imply a supported viewer experience.
- **D-14:** If the team wants momentum on future promotion, track one internal proof candidate only. Do not leak “targeted for verification” or similar soft-support language into the public contract.
- **D-15:** Do not attempt viewer promotion in Phase 57 unless the evidence already exists before the claim is written. Public support must follow proof, not planned proof.

### Proof artifact scope
- **D-16:** Keep automated structural proof and docs-contract synchronization as the merge-blocking source of truth.
- **D-17:** Add one terse Phase 57 verification note that enumerates unsupported claims by canonical name and points to the exact proof lanes that justify the public contract.
- **D-18:** That verification note must not restate long prose. It should list exact supported and unsupported claim names only, using the same vocabulary as `priv/support_matrix.json`, `guides/api_stability.md`, and docs-contract tests.
- **D-19:** Do not introduce a new structured proof-manifest system in Phase 57. The milestone should close with high-signal evidence, not tooling churn.

### Product and DX posture
- **D-20:** Rendro should continue the library-style Elixir posture used in Ecto, Plug, Phoenix, and Oban: explicit seams, explicit accepted shapes, explicit unsupported cases, and narrow product-facing contracts instead of broad capability umbrellas.
- **D-21:** The overall public story for Phase 57 is:
  - unsigned signature field authoring is supported through the existing forms contract
  - artifact-first signing preparation is supported as a separate post-render contract
  - digital signatures, signer identity/trust, tamper evidence, PAdES/LTV/TSA/OCSP/CRL, and broad viewer guarantees remain unsupported or unverified unless separately proven
- **D-22:** Downstream GSD work should shift routine policy synthesis left by default: prefer one cohesive recommendation set that optimizes for truthful small contracts, least surprise DX, and explicit boundaries. Escalate only when a choice materially changes product semantics, widens public trust claims, or commits Rendro to a substantially broader signing/compliance posture.

### the agent's Discretion
- Exact nested key names under `signing_preparation`, provided they stay small, stable, and non-cryptographic in tone.
- Exact guide heading names and ordering, provided authored unsigned widgets and artifact preparation stay clearly separate.
- Exact verification-note format, provided it remains terse, canonical, and aligned with machine-readable claim names.

### Deferred Ideas (OUT OF SCOPE)
- A broad top-level `signatures` taxonomy in the support matrix.
- Any wording that says or implies “digital signing is supported.”
- Viewer promotion for signature-related surfaces without recorded checklist evidence.
- A new structured proof-manifest framework or generic claim-schema system.
- In-core cryptographic signing, signer identity/trust workflows, tamper-evidence claims, compliance/archive narratives, or broad viewer guarantees.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TRUST-01 | `priv/support_matrix.json` publishes signature-field and signing-preparation support separately from unsupported `digital_signatures` and compliance claims. [VERIFIED: .planning/REQUIREMENTS.md] | Keep `forms` for unsigned authored/widget support, add a new top-level `signing_preparation` family, and keep all signing/trust/compliance negatives explicit and machine-readable. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md; VERIFIED: priv/support_matrix.json; VERIFIED: test/docs_contract/forms_claims_test.exs] |
| TRUST-02 | Public docs explicitly distinguish unsigned signature fields and signing preparation from cryptographic signatures, tamper evidence, and PAdES/LTV/TSA/OCSP/CRL support. [VERIFIED: .planning/REQUIREMENTS.md] | Split `guides/api_stability.md` into a short lifecycle preamble plus two small sections, and freeze both with family-owned docs-contract assertions. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md; VERIFIED: guides/api_stability.md; VERIFIED: test/docs_contract/forms_claims_test.exs; VERIFIED: test/docs_contract/protection_claims_test.exs] |
| TRUST-03 | Signature-related viewer rows default to `unverified` until recorded evidence exists, and structural proof remains distinct from viewer or cryptographic validity proof. [VERIFIED: .planning/REQUIREMENTS.md] | Keep structural proof in `test/rendro/pdf/writer_test.exs` and `test/rendro/sign_test.exs`, keep docs truth in docs-contract lanes, and record any viewer evidence only in a terse phase verification artifact before promotion. [VERIFIED: test/rendro/pdf/writer_test.exs; VERIFIED: test/rendro/sign_test.exs; VERIFIED: .planning/phases/55-signature-field-authoring-contract/55-VALIDATION.md; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-VALIDATION.md] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep `rendro` core pure and free of hard Phoenix, Oban, or admin-tool dependencies. [VERIFIED: AGENTS.md]
- Preserve deterministic and advisory verification lane separation in CI and docs. [VERIFIED: AGENTS.md]
- Treat documentation claims as contracts and do not claim unsupported capabilities. [VERIFIED: AGENTS.md]
- Prefer optional dependency guards for integrations. [VERIFIED: AGENTS.md]
- Preserve the data-first pipeline `build -> compose -> measure -> paginate -> render -> validate`. [VERIFIED: AGENTS.md]
- Keep one engine behind both fixed-position and flow APIs. [VERIFIED: AGENTS.md]
- Treat errors and telemetry as product behavior, not afterthoughts. [VERIFIED: AGENTS.md]

## Summary

Phase 57 is a contract-closure phase, not a runtime-expansion phase. The writer seam and artifact-first preparation seam already exist in repo code and tests, while the public support contract still reflects the narrower Phase 55 story where `forms.widgets.signature` is `unsupported` and no `signing_preparation` family exists yet. [VERIFIED: test/rendro/pdf/writer_test.exs; VERIFIED: test/rendro/sign_test.exs; VERIFIED: priv/support_matrix.json; VERIFIED: guides/api_stability.md]

The strongest planning move is to keep the family split literal. Use `forms` for unsigned authored and rendered signature widgets, add one narrow sibling `signing_preparation` family for `Rendro.Sign.prepare/2`, and give each family its own docs-contract owner. The closest in-repo analog is Phase 53 protection closure for a new top-level trust-sensitive family, while the closest signature-specific analog is Phase 55’s authored-helper split that named the unsigned placeholder without overclaiming digital signing. [VERIFIED: .planning/phases/53-delivery-threading-and-truthful-support-contract/53-VERIFICATION.md; VERIFIED: .planning/phases/55-signature-field-authoring-contract/55-02-SUMMARY.md; VERIFIED: .planning/phases/56-writer-and-external-signing-preparation-seam/56-PATTERNS.md]

The main risk is semantic bleed between proof lanes. `test/rendro/pdf/writer_test.exs` and `test/rendro/sign_test.exs` prove structure and preparation metadata only; they do not prove viewer behavior or cryptographic validity. Public wording and the support matrix must say that explicitly, and any signature-related viewer row must remain `unverified` until a named viewer/surface checklist exists in a phase validation or verification artifact. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md; VERIFIED: test/rendro/pdf/writer_test.exs; VERIFIED: test/rendro/sign_test.exs; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-VALIDATION.md]

**Primary recommendation:** Plan Phase 57 as two narrow slices: one slice updates `priv/support_matrix.json`, `guides/api_stability.md`, and docs-contract ownership for `forms` plus the new `signing_preparation` family; the second slice closes structural-proof references, default-`unverified` viewer posture, and one terse canonical verification note that names supported and unsupported claims without inventing new tooling. [VERIFIED: .planning/milestones/v2.0-ROADMAP.md; VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Machine-readable support contract publication | API / Backend | CDN / Static | `priv/support_matrix.json` is repo-owned contract data that is later published through docs and package artifacts. [VERIFIED: priv/support_matrix.json; VERIFIED: .planning/PROJECT.md] |
| Human-facing support-boundary wording | CDN / Static | API / Backend | `guides/api_stability.md` is the canonical published narrative, but its truth is enforced by repo tests. [VERIFIED: guides/api_stability.md; VERIFIED: test/docs_contract/forms_claims_test.exs; VERIFIED: test/docs_contract/protection_claims_test.exs] |
| Structural proof for unsigned widgets and prepared artifacts | API / Backend | Database / Storage | Writer and signing-preparation tests execute inside the Elixir runtime against generated artifact bytes. [VERIFIED: test/rendro/pdf/writer_test.exs; VERIFIED: test/rendro/sign_test.exs] |
| Manual viewer-proof recording | Browser / Client | API / Backend | Any viewer promotion depends on behavior in Preview/Acrobat, but the evidence must be recorded back into phase artifacts and contract files. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-VALIDATION.md; VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] |
| Unsupported-claim verification note | API / Backend | CDN / Static | The note is a phase artifact generated from repo truth surfaces and consumed by milestone closeout, not a runtime feature. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md; VERIFIED: .planning/phases/50-support-boundary-and-proof-closure/50-VERIFICATION.md; VERIFIED: .planning/phases/53-delivery-threading-and-truthful-support-contract/53-VERIFICATION.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 [VERIFIED: mix --version] | Runs the phase’s tests, docs-contract entrypoints, and planning-time verification commands. [VERIFIED: mix --version; VERIFIED: mix.exs] | Every Phase 57 proof surface is Mix-native already; there is no need for external planning tooling. [VERIFIED: scripts/verify_docs.exs; VERIFIED: lib/mix/tasks/docs.contract.ex] |
| ExUnit | bundled with Elixir 1.19.5 [VERIFIED: mix --version] | Owns docs-contract tests plus writer/sign structural regressions. [VERIFIED: test/docs_contract/forms_claims_test.exs; VERIFIED: test/docs_contract/protection_claims_test.exs; VERIFIED: test/rendro/sign_test.exs; VERIFIED: test/rendro/pdf/writer_test.exs] | The repo already expresses support-boundary truth as focused ExUnit slices rather than prose-only checks. [VERIFIED: scripts/verify_docs.exs; VERIFIED: lib/mix/tasks/docs.contract.ex] |
| `Mix.Tasks.Docs.Contract` | repo-local [VERIFIED: lib/mix/tasks/docs.contract.ex; VERIFIED: rg probe] | Canonical wrapper around `scripts/verify_docs.exs` for semantic-claim drift detection. [VERIFIED: lib/mix/tasks/docs.contract.ex; VERIFIED: scripts/verify_docs.exs] | Existing repo convention already points all docs verification through `mix docs.contract`. [VERIFIED: lib/mix/tasks/verify.ex; VERIFIED: test/mix/tasks/docs_contract_task_test.exs] |
| `priv/support_matrix.json` + `guides/api_stability.md` | repo-local [VERIFIED: local files] | Canonical machine-readable and human-readable support contracts. [VERIFIED: priv/support_matrix.json; VERIFIED: guides/api_stability.md] | Earlier trust-sensitive phases treat these as the single truth surfaces and freeze them with tests. [VERIFIED: .planning/phases/50-support-boundary-and-proof-closure/50-VERIFICATION.md; VERIFIED: .planning/phases/53-delivery-threading-and-truthful-support-contract/53-VERIFICATION.md] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Poppler `pdfinfo` | 26.04.0 on host [VERIFIED: pdfinfo -v] | Existing structural validator precedent for “structure only” wording in public docs. [VERIFIED: priv/support_matrix.json; VERIFIED: guides/api_stability.md; VERIFIED: pdfinfo -v] | Use in wording and proof-lane references when explaining structural validation boundaries; Phase 57 does not need a new validator. [VERIFIED: guides/api_stability.md; VERIFIED: .planning/phases/50-support-boundary-and-proof-closure/50-VERIFICATION.md] |
| `qpdf` | 12.3.2 on host [VERIFIED: qpdf --version] | Host capability for future external-signing or protected-PDF proof work, but not a required new Phase 57 contract surface. [VERIFIED: qpdf --version; VERIFIED: .planning/STATE.md] | Mention only when a later proof lane needs real external tooling; do not let its presence widen the Phase 57 signing story. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] |
| Preview.app | present on host [VERIFIED: host probe] | Potential manual viewer lane for future signature proof rows. [VERIFIED: host probe] | Use only if a recorded signature-specific checklist is actually executed before claim promotion. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] |
| Adobe Acrobat Reader | unknown on host [VERIFIED: host probe] | Potential manual viewer lane, but not guaranteed locally. [VERIFIED: host probe] | Treat as manual/external availability, not as a planning assumption. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-VALIDATION.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extending `forms` only | Introduce a broad top-level `signatures` family | Rejected by locked scope because it implies a broader subsystem and creates taxonomy churn. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] |
| Family-owned docs-contract lanes | One monolithic “all trust claims” test file | Worse because earlier phases already split claims by family and public surface, which keeps drift local and auditable. [VERIFIED: test/docs_contract/forms_claims_test.exs; VERIFIED: test/docs_contract/protection_claims_test.exs; VERIFIED: scripts/verify_docs.exs] |
| Existing structural tests plus terse verification note | New proof-manifest framework | Rejected by locked scope because Phase 57 should close the milestone with high-signal evidence, not tooling churn. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] |
| Per-surface `unverified` rows | Blanket “signature viewers supported/unverified” statement | Worse because existing project precedent is per viewer and per surface, not family-wide badges. [VERIFIED: .planning/phases/50-support-boundary-and-proof-closure/50-VERIFICATION.md; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md] |

**Installation:**
```bash
mix deps.get
```
[VERIFIED: mix.exs]

**Version verification:** Elixir/Mix `1.19.5`, Poppler `26.04.0`, and `qpdf 12.3.2` were verified locally for planning. [VERIFIED: mix --version; VERIFIED: pdfinfo -v; VERIFIED: qpdf --version]

## Architecture Patterns

### System Architecture Diagram

```text
Phase 55 unsigned authoring contract
(`forms.authored_helpers.signature_field`)
    |
    v
Phase 56 writer + preparation proof
(`test/rendro/pdf/writer_test.exs` + `test/rendro/sign_test.exs`)
    |
    +--> unsigned widget proof --------------------+
    |                                              |
    |                                              v
    |                                   `forms.widgets.signature`
    |                                   + signature-specific viewer rows
    |
    +--> artifact-preparation proof ---------------+
                                                   |
                                                   v
                                   `signing_preparation.*`
                                   capability/behavior/boundary leaves
                                                   |
                                                   v
                              `guides/api_stability.md`
                              short lifecycle preamble
                              + separate widget and preparation sections
                                                   |
                                                   v
                                 docs-contract lanes
                   (`forms_claims_test.exs` + dedicated signing-preparation lane)
                                                   |
                                                   v
                                phase verification note
                         canonical supported/unsupported claim names only
                                                   |
                                                   v
                            future manual viewer proof may promote
                         exact viewer/surface rows, never blanket claims
```
[VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md; VERIFIED: test/rendro/pdf/writer_test.exs; VERIFIED: test/rendro/sign_test.exs; VERIFIED: test/docs_contract/forms_claims_test.exs; VERIFIED: scripts/verify_docs.exs]

### Recommended Project Structure
```text
priv/
└── support_matrix.json                  # canonical machine-readable claims
guides/
└── api_stability.md                     # canonical human-facing support wording
test/
├── docs_contract/
│   ├── forms_claims_test.exs            # forms + unsigned signature widget claims
│   └── signing_preparation_claims_test.exs  # new top-level family lane [ASSUMED]
└── rendro/
    ├── pdf/writer_test.exs              # unsigned widget structural proof
    └── sign_test.exs                    # preparation manifest structural proof
.planning/phases/57-support-contract-and-proof-closure/
├── 57-RESEARCH.md
├── 57-VALIDATION.md                     # proof-lane map and any viewer evidence [ASSUMED]
└── 57-VERIFICATION.md                   # terse canonical claim closure note [ASSUMED]
```

### Pattern 1: Family-Sibling Contract Closure
**What:** Keep unsigned widgets in `forms`, add `signing_preparation` as a sibling family, and let each family own its own narrow claims. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md]
**When to use:** When a new public claim is about post-render preparation rather than authored form semantics. [VERIFIED: .planning/phases/56-writer-and-external-signing-preparation-seam/56-CONTEXT.md]
**Example:**
```json
// Source: repo support-matrix pattern + Phase 57 decisions
{
  "forms": {
    "authored_helpers": {
      "signature_field": "supported_unsigned_placeholder_only"
    },
    "widgets": {
      "signature": "supported_unsigned_widget_only"
    }
  },
  "signing_preparation": {
    "capabilities": {
      "external_artifact_prepare": "supported"
    },
    "behaviors": {
      "final_byte_handoff": "supported",
      "adapter_local_metadata": "supported"
    },
    "boundaries": {
      "digital_signatures": "unsupported",
      "tamper_evidence": "unsupported",
      "pades_ltv_tsa_ocsp_crl": "unsupported"
    }
  }
}
```
[VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md; VERIFIED: priv/support_matrix.json; VERIFIED: .planning/phases/55-signature-field-authoring-contract/55-02-SUMMARY.md]

### Pattern 2: Separate Public Wording by Lifecycle Step
**What:** Use one short lifecycle preamble, then one section for unsigned widgets and one section for signing preparation. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md]
**When to use:** Whenever a reader might collapse authored placeholders, prepared bytes, and actual digital signatures into one support claim. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md; VERIFIED: guides/api_stability.md]
**Example:**
```markdown
<!-- Source: Phase 57 wording pattern -->
Author unsigned placeholder -> render artifact -> prepare artifact for an external signer.
External signing, cryptographic validity, and viewer verification remain outside Rendro core.

## Unsigned Signature Fields
- Supported surface: authored unsigned placeholders and rendered unsigned signature widgets.
- Proof lane: structural writer tests only.
- Unsupported narratives: digital signatures, tamper evidence, compliance, blanket viewer support.

## Signing Preparation
- Supported surface: `Rendro.Sign.prepare/2` over rendered `%Rendro.Artifact{}` bytes.
- Proof lane: preparation manifest tests only.
- Unsupported narratives: signer identity/trust, CMS validity, PAdES/LTV/TSA/OCSP/CRL.
```
[VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md; VERIFIED: guides/api_stability.md; VERIFIED: test/rendro/sign_test.exs; VERIFIED: test/rendro/pdf/writer_test.exs]

### Pattern 3: Three Proof Lanes, No Cross-Promotion
**What:** Keep support-contract tests, structural tests, and viewer evidence distinct, with no lane inferring results for another. [VERIFIED: .planning/phases/47-form-validation-and-viewer-proof-closure/47-RESEARCH.md; VERIFIED: .planning/phases/50-support-boundary-and-proof-closure/50-VERIFICATION.md; VERIFIED: .planning/phases/55-signature-field-authoring-contract/55-VALIDATION.md]
**When to use:** For every signature-related claim in Phase 57. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md]
**Example:**
```text
docs-contract lane      => proves wording + support_matrix lockstep
writer/sign test lane   => proves structure + manifest semantics
manual viewer lane      => proves exact viewer/surface behavior only
```
[VERIFIED: scripts/verify_docs.exs; VERIFIED: test/rendro/pdf/writer_test.exs; VERIFIED: test/rendro/sign_test.exs; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-VALIDATION.md]

### Closest Analogs

| Analog | Why It Matches | What to Copy | What Not to Copy |
|--------|----------------|--------------|------------------|
| Phase 53 `protection` closure | New top-level trust-sensitive family with explicit negatives and family-owned docs-contract lane. [VERIFIED: .planning/phases/53-delivery-threading-and-truthful-support-contract/53-VERIFICATION.md] | Small sibling family, explicit boundary leaves, synchronized matrix/guide/tests. [VERIFIED: test/docs_contract/protection_claims_test.exs; VERIFIED: guides/api_stability.md] | Do not reuse protection vocabulary like “advisory permissions” or imply security/compliance semantics. [VERIFIED: guides/api_stability.md] |
| Phase 55 unsigned signature helper closure | Same milestone, same surface, already distinguishes authored helper from unsupported digital signing. [VERIFIED: .planning/phases/55-signature-field-authoring-contract/55-02-SUMMARY.md] | Preserve `forms.authored_helpers.signature_field` and the narrow unsigned wording. [VERIFIED: priv/support_matrix.json; VERIFIED: test/docs_contract/forms_claims_test.exs] | Do not leave `forms.widgets.signature` stuck at `unsupported` now that writer proof exists. [VERIFIED: test/rendro/pdf/writer_test.exs; VERIFIED: priv/support_matrix.json] |
| PDFBox `ExternalSigningSupport` | Official example of a narrow external-signing seam that separates “content to sign” from “set signature bytes”. [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html] | Keep the preparation contract artifact-first and final-byte oriented. [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html; VERIFIED: test/rendro/sign_test.exs] | Do not widen Rendro into the signer/CMS owner. [VERIFIED: .planning/phases/56-writer-and-external-signing-preparation-seam/56-CONTEXT.md] |
| pdf-lib `PDFSignature` | Officially recognizes signature fields while explicitly not offering specialized digital-signature creation/reading APIs. [CITED: https://pdf-lib.js.org/docs/api/classes/pdfsignature] | Honest “field support is not full digital-signature support” wording. [CITED: https://pdf-lib.js.org/docs/api/classes/pdfsignature] | Do not market mere field recognition as signing support. [CITED: https://pdf-lib.js.org/docs/api/classes/pdfsignature] |
| HexaPDF signing guide | Separates field creation/appearance from signing and warns that post-sign appearance modification is more involved. [CITED: https://hexapdf.gettalong.org/documentation/digital-signatures/signing-pdfs-howto.html] | Keep visual unsigned widget creation separate from later signing workflow. [CITED: https://hexapdf.gettalong.org/documentation/digital-signatures/signing-pdfs-howto.html; VERIFIED: test/rendro/pdf/writer_test.exs] | Do not import broader signing feature expectations or certificate flows into core docs. [CITED: https://hexapdf.gettalong.org/documentation/digital-signatures/signing-pdfs-howto.html] |
| ExUnit doctest contract posture | Official Elixir precedent for executable documentation. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html] | Treat guide wording as executable contract and fail drift in CI. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html; VERIFIED: scripts/verify_docs.exs] | Do not rely on prose review alone. [VERIFIED: lib/mix/tasks/docs.contract.ex] |

### Anti-Patterns to Avoid
- **Blended “signature support” section:** It collapses authored widgets, prepared artifacts, and cryptographic validity into one ambiguous promise. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md]
- **Leaving signature widget viewer meaning implicit:** Existing `forms.viewers` support for text/checkbox/radio must not be read as proof for signature widgets. [VERIFIED: priv/support_matrix.json; VERIFIED: guides/api_stability.md]
- **Reusing structural proof as viewer proof:** Passing writer or preparation tests does not justify any viewer promotion. [VERIFIED: test/rendro/pdf/writer_test.exs; VERIFIED: test/rendro/sign_test.exs; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-VALIDATION.md]
- **Overloading protection docs/tests for signing preparation:** `signing_preparation` is a separate family and deserves its own lane. [VERIFIED: .planning/phases/53-delivery-threading-and-truthful-support-contract/53-VERIFICATION.md; VERIFIED: scripts/verify_docs.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| New support-matrix taxonomy | Broad `signatures` umbrella or generic `surfaces` wrapper | Existing family-first sibling structure with `forms` + `signing_preparation` | Locked scope explicitly prefers small sibling families and rejects taxonomy churn. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] |
| Unified trust-claims test file | One large semantic-claims suite for every trust-sensitive feature | Existing family-owned docs-contract lanes plus one new signing-preparation lane | The repo already scales claim ownership by family and script lane, which keeps failures local. [VERIFIED: scripts/verify_docs.exs; VERIFIED: test/docs_contract/forms_claims_test.exs; VERIFIED: test/docs_contract/protection_claims_test.exs] |
| New proof-manifest framework | Extra schema/tooling to model supported/unsupported claims | A terse phase verification note using canonical claim names | Locked scope explicitly forbids framework churn and wants a high-signal note instead. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] |
| Digital-signature terminology in core docs | “Signing support”, “trust”, “compliance”, or “tamper-proof” shorthand | Explicit negative leaves and narrow lifecycle wording | Official analogs show how quickly signature docs widen into certificate/compliance narratives. [CITED: https://pdf-lib.js.org/docs/api/classes/pdfsignature; CITED: https://hexapdf.gettalong.org/documentation/digital-signatures/signing-pdfs-howto.html] |

**Key insight:** Phase 57 should publish two small truthful contracts, not one aspirational signature story. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Promoting `forms.widgets.signature` Without Isolating Viewer Meaning
**What goes wrong:** The matrix starts saying signature widgets are supported, but the only public viewer rows still belong to the broader forms family and can be misread as proof for signature widgets. [VERIFIED: priv/support_matrix.json]
**Why it happens:** The current forms matrix shape was sufficient when all supported widgets shared the same viewer posture. Signature widgets break that assumption. [VERIFIED: priv/support_matrix.json; VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md]
**How to avoid:** Add explicit signature-specific viewer rows and default them to `unverified`, rather than inheriting existing `forms.viewers` proof. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md; ASSUMED: signature-specific viewer row naming]
**Warning signs:** `guides/api_stability.md` starts saying “Apple Preview supports forms” near signature wording without a surface qualifier. [VERIFIED: guides/api_stability.md]

### Pitfall 2: Hiding Signing Preparation Inside Forms
**What goes wrong:** Artifact-first preparation gets documented as a form feature, which blurs authored-state ownership and makes `Rendro.Sign.prepare/2` look like a widget convenience instead of a post-render seam. [VERIFIED: .planning/phases/56-writer-and-external-signing-preparation-seam/56-CONTEXT.md]
**Why it happens:** Both concerns involve signatures, but they live on different sides of the render boundary. [VERIFIED: .planning/phases/56-writer-and-external-signing-preparation-seam/56-CONTEXT.md; VERIFIED: AGENTS.md]
**How to avoid:** Keep `forms` for authored/rendered unsigned widgets and `signing_preparation` for prepared-artifact claims only. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md]
**Warning signs:** Proposed keys or prose mention `prepare` under `forms.*` or describe `Rendro.Sign.prepare/2` before the render step is named. [VERIFIED: test/rendro/sign_test.exs; VERIFIED: guides/api_stability.md]

### Pitfall 3: Using Structural Tests to Smuggle in Digital-Signature Claims
**What goes wrong:** Because `test/rendro/sign_test.exs` proves `/ByteRange` or placeholder metadata exists, docs start implying real signing, trust, or compliance support. [VERIFIED: test/rendro/sign_test.exs]
**Why it happens:** PDF signature preparation vocabulary is close to digital-signature vocabulary, so narrow implementation facts can sound broader than they are. [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html; CITED: https://hexapdf.gettalong.org/documentation/digital-signatures/signing-pdfs-howto.html]
**How to avoid:** Keep all trust/compliance leaves explicitly unsupported and require every guide section to name its proof lane and unsupported narratives. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md]
**Warning signs:** Phrases like “ready for signing”, “trusted”, “valid signature”, or “PAdES compatible” appear without a new proof lane. [VERIFIED: test/docs_contract/forms_claims_test.exs; VERIFIED: test/docs_contract/protection_claims_test.exs]

### Pitfall 4: Reusing the Wrong Docs-Contract Owner
**What goes wrong:** All new assertions get stuffed into `forms_claims_test.exs`, making the new `signing_preparation` family look like an implementation detail instead of a public contract. [VERIFIED: scripts/verify_docs.exs; VERIFIED: test/docs_contract/forms_claims_test.exs]
**Why it happens:** `forms_claims_test.exs` already mentions signatures from Phase 55, so it is tempting to keep piling on. [VERIFIED: test/docs_contract/forms_claims_test.exs]
**How to avoid:** Keep `forms_claims_test.exs` for `forms.*` and add one dedicated lane for the new top-level `signing_preparation` family. [VERIFIED: scripts/verify_docs.exs; VERIFIED: .planning/phases/53-delivery-threading-and-truthful-support-contract/53-VERIFICATION.md; ASSUMED: exact new filename]
**Warning signs:** `forms_claims_test.exs` starts asserting `Rendro.Sign.prepare/2` wording or `signing_preparation.*` leaves directly. [ASSUMED]

## Code Examples

Verified patterns from repo and official sources:

### Existing Docs-Contract Owner Pattern
```elixir
# Source: test/docs_contract/forms_claims_test.exs
test "public forms wording stays narrow and matches the provisional matrix posture" do
  guide = File.read!("guides/api_stability.md")
  assert guide =~ "Structural validation through `pdfinfo`/Poppler proves PDF structure only."
  refute guide =~ "digital signatures are supported"
end
```
[VERIFIED: test/docs_contract/forms_claims_test.exs]

### Existing Canonical Docs Verification Entry Point
```bash
# Source: repo docs-contract lane
mix docs.contract
mix run scripts/verify_docs.exs
```
[VERIFIED: lib/mix/tasks/docs.contract.ex; VERIFIED: scripts/verify_docs.exs]

### External-Signing Seam Analog
```text
// Source: PDFBox ExternalSigningSupport
getContent()      -> bytes to sign
setSignature(...) -> write CMS bytes back into PDF
```
[CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| One broad “signature support” label | Split authored-widget and preparation contracts with explicit negatives | Required by locked Phase 57 decisions on 2026-05-06. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] | Planner should produce two small contract slices, not one blended docs pass. [VERIFIED: .planning/milestones/v2.0-ROADMAP.md] |
| Signature field recognition treated as signing support | Field support described separately from actual digital-signature APIs | Current official pdf-lib docs already take the narrow field-only stance. [CITED: https://pdf-lib.js.org/docs/api/classes/pdfsignature] | Rendro should follow the same honesty in public wording. [CITED: https://pdf-lib.js.org/docs/api/classes/pdfsignature] |
| Field creation and signing collapsed conceptually | Field creation/appearance and signing separated by lifecycle step | Current HexaPDF signing guide keeps field creation before signing and visual appearance before signature application. [CITED: https://hexapdf.gettalong.org/documentation/digital-signatures/signing-pdfs-howto.html] | Phase 57 guide sections should mirror lifecycle separation, not merge them. [CITED: https://hexapdf.gettalong.org/documentation/digital-signatures/signing-pdfs-howto.html] |
| Prose-only docs review | Executable docs-contract checks | Current ExUnit doctest/docs-contract culture and repo scripts already enforce executable documentation posture. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html; VERIFIED: lib/mix/tasks/docs.contract.ex; VERIFIED: scripts/verify_docs.exs] | Phase 57 should add or extend claim tests, not rely on review comments. [VERIFIED: scripts/verify_docs.exs] |

**Deprecated/outdated:**
- `forms.widgets.signature: "unsupported"` is now stale relative to Phase 56 structural proof and should be replaced with narrow unsigned-widget support wording in Phase 57. [VERIFIED: priv/support_matrix.json; VERIFIED: test/rendro/pdf/writer_test.exs]
- A guide sentence that says Phase 55 “does not yet claim rendered signature-widget support” becomes outdated once Phase 57 publishes the Phase 56 proof-backed widget contract. [VERIFIED: guides/api_stability.md; VERIFIED: test/rendro/pdf/writer_test.exs]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The cleanest Phase 57 docs-contract split is to add `test/docs_contract/signing_preparation_claims_test.exs` rather than extend only `forms_claims_test.exs`. [ASSUMED] | Recommended Project Structure / Common Pitfalls | Low; if the team prefers another filename, the planner should still preserve family-owned lane separation. |
| A2 | Phase 57 will create `57-VALIDATION.md` and `57-VERIFICATION.md` as the local proof-lane and closeout artifacts, matching recent repo closure phases. [ASSUMED] | Recommended Project Structure / Validation Architecture | Low; if another artifact name is used, the essential requirement is still one terse canonical unsupported-claims note plus lane mapping. |
| A3 | Signature-specific viewer rows will need a new nested key under `forms` rather than reusing `forms.viewers` semantics. [ASSUMED] | Common Pitfalls / Support-matrix guidance | Medium; if the project chooses a different naming shape, planners must still ensure signature widget viewer proof is not inherited implicitly. |

## Open Questions

1. **What exact key name should carry signature-widget viewer rows inside `forms`?**
   - What we know: locked decisions require per-surface per-viewer claims and default-`unverified` posture, while current `forms.viewers` rows already describe broader form support. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md; VERIFIED: priv/support_matrix.json]
   - What's unclear: the exact nested key name is not locked in context. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md]
   - Recommendation: choose the smallest explicit name that cannot be read as applying to all forms widgets, then freeze it in both tests and the verification note. [ASSUMED]

2. **Should the new signing-preparation docs-contract lane also assert the lifecycle preamble?**
   - What we know: the preamble is shared across both signature sections and must stay brief. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md]
   - What's unclear: whether ownership of that shared paragraph should live in `forms_claims_test.exs`, the new signing-preparation lane, or both. [ASSUMED]
   - Recommendation: put the preamble assertion in the new signing-preparation lane and keep `forms_claims_test.exs` focused on `forms.*` semantics, to avoid duplicate ownership. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix tasks and tests | ✓ [VERIFIED: elixir probe] | 1.19.5 [VERIFIED: elixir --version] | — |
| Mix | docs-contract and targeted tests | ✓ [VERIFIED: mix probe] | 1.19.5 [VERIFIED: mix --version] | — |
| Poppler `pdfinfo` | structural-proof wording precedent and any structural validation reruns | ✓ [VERIFIED: pdfinfo -v] | 26.04.0 [VERIFIED: pdfinfo -v] | Existing writer/sign tests already prove core structure even without rerunning Poppler. [VERIFIED: test/rendro/pdf/writer_test.exs; VERIFIED: test/rendro/sign_test.exs] |
| `qpdf` | future external-tool proof work if later needed | ✓ [VERIFIED: qpdf --version] | 12.3.2 [VERIFIED: qpdf --version] | Not required for the Phase 57 docs-contract slice itself. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] |
| Preview.app | manual viewer evidence for exact viewer/surface rows | ✓ [VERIFIED: host probe] | app present [VERIFIED: host probe] | Leave rows `unverified` if no recorded checklist is produced. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] |
| Adobe Acrobat Reader | manual viewer evidence for exact viewer/surface rows | ? [VERIFIED: host probe] | — | Treat as manual/external dependency; do not assume availability. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-VALIDATION.md] |

**Missing dependencies with no fallback:**
- None for the planning/documentation slice itself. [VERIFIED: environment probe]

**Missing dependencies with fallback:**
- Adobe Acrobat Reader availability is unknown locally; fallback is to keep any Acrobat signature row `unverified` until human proof exists. [VERIFIED: host probe; VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + repo `mix docs.contract` task. [VERIFIED: lib/mix/tasks/docs.contract.ex; VERIFIED: test files] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/docs_contract/forms_claims_test.exs test/rendro/sign_test.exs test/rendro/pdf/writer_test.exs`. [VERIFIED: local file set; VERIFIED: targeted baseline test run] |
| Full suite command | `mix test test/docs_contract/forms_claims_test.exs test/docs_contract/protection_claims_test.exs test/rendro/sign_test.exs test/rendro/pdf/writer_test.exs && mix docs.contract`. [VERIFIED: targeted baseline test run; VERIFIED: lib/mix/tasks/docs.contract.ex; VERIFIED: scripts/verify_docs.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TRUST-01 | Support matrix publishes unsigned widget support separately from signing-preparation and keeps explicit unsupported trust/compliance leaves. [VERIFIED: .planning/REQUIREMENTS.md] | docs-contract | `mix test test/docs_contract/forms_claims_test.exs` plus a new signing-preparation semantic-claims lane. [VERIFIED: test/docs_contract/forms_claims_test.exs; ASSUMED: new lane file] | ✅ forms lane exists / ❌ new signing-preparation lane missing. [VERIFIED: ls test/docs_contract] |
| TRUST-02 | Guide wording separates unsigned widgets from artifact preparation and repeats unsupported narratives literally. [VERIFIED: .planning/REQUIREMENTS.md] | docs-contract | `mix docs.contract` after updating `guides/api_stability.md` and the family-owned tests. [VERIFIED: lib/mix/tasks/docs.contract.ex; VERIFIED: scripts/verify_docs.exs] | ✅ existing framework / ❌ Phase 57-specific assertions not yet present. [VERIFIED: guides/api_stability.md; VERIFIED: test/docs_contract/forms_claims_test.exs] |
| TRUST-03 | Signature-related viewer rows default to `unverified`, and structural proof remains distinct from viewer or cryptographic validity proof. [VERIFIED: .planning/REQUIREMENTS.md] | structural + docs-contract + manual record | `mix test test/rendro/sign_test.exs test/rendro/pdf/writer_test.exs` for structural proof; `mix docs.contract` for wording sync; manual checklist only if a viewer row is promoted. [VERIFIED: test/rendro/sign_test.exs; VERIFIED: test/rendro/pdf/writer_test.exs; VERIFIED: lib/mix/tasks/docs.contract.ex] | ✅ structural files exist / ❌ phase-specific viewer record not yet created. [VERIFIED: ls .planning/phases/57-support-contract-and-proof-closure; ASSUMED: future validation artifact] |

### Sampling Rate
- **Per task commit:** `mix test test/docs_contract/forms_claims_test.exs test/rendro/sign_test.exs test/rendro/pdf/writer_test.exs`. [VERIFIED: targeted baseline test run]
- **Per wave merge:** `mix docs.contract`. [VERIFIED: lib/mix/tasks/docs.contract.ex; VERIFIED: scripts/verify_docs.exs]
- **Phase gate:** run full docs-contract plus any targeted manual viewer checklist before changing a signature-related viewer row from `unverified`. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-VALIDATION.md]

### Wave 0 Gaps
- [ ] Add the new `signing_preparation` family to `priv/support_matrix.json` with narrow capability/behavior/boundary leaves. [VERIFIED: priv/support_matrix.json; VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md]
- [ ] Replace stale “rendered signature-widget support not yet claimed” wording in `guides/api_stability.md` with the Phase 57 split contract. [VERIFIED: guides/api_stability.md; VERIFIED: test/rendro/pdf/writer_test.exs]
- [ ] Add a dedicated signing-preparation docs-contract lane and wire it into `scripts/verify_docs.exs`. [VERIFIED: scripts/verify_docs.exs; ASSUMED: exact file name]
- [ ] Decide and freeze the exact nested key for signature-widget viewer rows under `forms`. [ASSUMED]
- [ ] Create the terse canonical verification note listing supported and unsupported claim names only. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md; ASSUMED: artifact path]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | No user-authentication surface is introduced by this library contract phase. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] |
| V3 Session Management | no [VERIFIED: phase scope] | No session state or browser auth behavior is introduced. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] |
| V4 Access Control | no [VERIFIED: phase scope] | The phase publishes claims; it does not add authorization logic. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] |
| V5 Input Validation | yes [VERIFIED: phase domain] | Keep docs-contract assertions literal so unsupported-signing claims fail immediately if introduced. [VERIFIED: test/docs_contract/forms_claims_test.exs; VERIFIED: scripts/verify_docs.exs] |
| V6 Cryptography | yes [VERIFIED: phase domain] | Preserve the explicit boundary that cryptographic signing, trust, tamper evidence, and compliance claims remain unsupported. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md; VERIFIED: guides/api_stability.md; CITED: https://pdf-lib.js.org/docs/api/classes/pdfsignature] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Overclaiming preparation as actual signing | Spoofing | Keep `signing_preparation.boundaries.digital_signatures` and related negatives explicit in the matrix and guide. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] |
| Inheriting viewer support across surfaces without evidence | Repudiation | Publish per-surface per-viewer rows and default new signature-related rows to `unverified`. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] |
| Ambiguous lifecycle wording that collapses render and post-render seams | Tampering | Use the shared preamble plus two separate sections in `guides/api_stability.md`. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md] |
| Drift between support matrix and public docs | Information Disclosure | Keep `mix docs.contract` as the canonical merge-blocking truth lane. [VERIFIED: lib/mix/tasks/docs.contract.ex; VERIFIED: scripts/verify_docs.exs] |

## Sources

### Primary (HIGH confidence)
- `AGENTS.md` - project constraints, architecture, and workflow expectations. [VERIFIED: local file]
- `.planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md` - locked scope, support-matrix shape, wording split, proof-lane requirements. [VERIFIED: local file]
- `.planning/milestones/v2.0-ROADMAP.md` - phase split, requirements, success criteria. [VERIFIED: local file]
- `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/milestones/v2.0-REQUIREMENTS.md` - active milestone truth, phase requirement IDs, and product posture. [VERIFIED: local files]
- `.planning/phases/56-writer-and-external-signing-preparation-seam/56-CONTEXT.md` and `56-PATTERNS.md` - immediate upstream contract and local analog mapping. [VERIFIED: local files]
- `priv/support_matrix.json`, `guides/api_stability.md`, `scripts/verify_docs.exs` - live contract surfaces and docs-contract entrypoint. [VERIFIED: local files]
- `test/docs_contract/forms_claims_test.exs`, `test/docs_contract/protection_claims_test.exs`, `test/rendro/sign_test.exs`, `test/rendro/pdf/writer_test.exs` - current automated proof surfaces. [VERIFIED: local files]
- Prior closure precedent: `.planning/phases/50-support-boundary-and-proof-closure/50-VERIFICATION.md`, `.planning/phases/53-delivery-threading-and-truthful-support-contract/53-VERIFICATION.md`, `.planning/phases/54-proof-closure-and-release-tail/54-VALIDATION.md`, `.planning/phases/55-signature-field-authoring-contract/55-VALIDATION.md`. [VERIFIED: local files]
- Current targeted run: `mix test test/docs_contract/forms_claims_test.exs test/docs_contract/protection_claims_test.exs test/rendro/sign_test.exs test/rendro/pdf/writer_test.exs` -> `62 tests, 0 failures` on 2026-05-06. [VERIFIED: current session targeted test run]

### Secondary (MEDIUM confidence)
- PDFBox `ExternalSigningSupport` - narrow external signing seam with “get content” and “set signature” split. [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html]
- pdf-lib `PDFSignature` docs - explicit field recognition without specialized digital-signature creation APIs. [CITED: https://pdf-lib.js.org/docs/api/classes/pdfsignature]
- HexaPDF signing guide - explicit field/appearance creation before signing and broader signing lifecycle context. [CITED: https://hexapdf.gettalong.org/documentation/digital-signatures/signing-pdfs-howto.html]
- ExUnit.DocTest docs - executable documentation precedent. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html]
- Ecto.Enum docs - finite explicit vocabulary precedent for stable public shapes. [CITED: https://hexdocs.pm/ecto/Ecto.Enum.html]
- Oban.Worker docs - explicit option-surface precedent for narrow, named contracts. [CITED: https://hexdocs.pm/oban/Oban.Worker.html]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - almost entirely repo-local and environment-probed, with external analogs verified against official docs. [VERIFIED: repo inspection; VERIFIED: environment probe; CITED: official docs above]
- Architecture: HIGH - Phase 57 directly follows local closure patterns from Phases 53-56 and existing docs-contract machinery. [VERIFIED: .planning/phases/53-delivery-threading-and-truthful-support-contract/53-VERIFICATION.md; VERIFIED: .planning/phases/56-writer-and-external-signing-preparation-seam/56-PATTERNS.md; VERIFIED: scripts/verify_docs.exs]
- Pitfalls: HIGH - risks are explicit in locked scope and visible in the current gap between repo proof and published contract. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md; VERIFIED: priv/support_matrix.json; VERIFIED: guides/api_stability.md]

**Research date:** 2026-05-06 [VERIFIED: current session date]
**Valid until:** 2026-06-05 for repo-local planning assumptions; re-check official analog docs if Phase 57 planning slips or if support-matrix naming decisions expand beyond the current locked scope. [VERIFIED: stable local sources; CITED: official docs above]

## RESEARCH COMPLETE

- Support-matrix recommendation: keep `forms` for unsigned widgets, add sibling `signing_preparation`, and publish explicit negative trust/compliance leaves. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md]
- Guide recommendation: short shared lifecycle preamble, then separate unsigned-widget and preparation sections, each naming supported surface, proof lane, and unsupported narratives. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md]
- Test-lane recommendation: keep `forms_claims_test.exs` for `forms.*`, add one dedicated signing-preparation claims lane, and continue using `mix docs.contract` as the merge-blocking entrypoint. [VERIFIED: scripts/verify_docs.exs; VERIFIED: test/docs_contract/forms_claims_test.exs; ASSUMED: new lane filename]
- Proof recommendation: keep structural tests, docs-contract tests, and manual viewer evidence separate; no viewer promotion without recorded per-viewer per-surface proof. [VERIFIED: .planning/phases/57-support-contract-and-proof-closure/57-CONTEXT.md; VERIFIED: test/rendro/sign_test.exs; VERIFIED: test/rendro/pdf/writer_test.exs]
