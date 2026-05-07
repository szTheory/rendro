# Rendro Milestone Arc

**Last updated:** 2026-05-07
**Purpose:** Preserve the recommended multi-milestone sequence so milestone-definition work does not reopen already-set architectural tradeoffs unless the project direction materially changes.

## Active Strategic Arc

### Production-Ready Trust and Adoption

- **Intent:** Move Rendro from “truthful and technically impressive” to “easy to trust and practical to adopt” without widening the public contract faster than proof can support it.
- **Ordering logic:** Finish the trust-sensitive signing stack first, then close viewer/interoperability gaps, then package the strongest batteries-included adoption path, and only then take on very large new capability families that would reshape the core.

## Last Shipped Milestone

### v2.1 Cryptographic Signing & Signed-Artifact Proof

- **Status:** shipped
- **Why now:** Extended the shipped unsigned/preparation seam into one truthful cryptographic-signing and signed-artifact-validation path without widening the core contract into generic trust or compliance claims.
- **Scope shipped:**
  - Artifact-first cryptographic signing through `Rendro.Sign.sign/2`
  - First-party optional runtime adapters for signing and signed-artifact validation
  - Proof-backed support language that separates signature integrity, certificate trust, viewer posture, and deferred compliance narratives
- **Non-goals held:** 
  - In-core certificate management, key custody, or signer workflows by default
  - Long-lived-signature and revocation evidence
  - PAdES/LTV/TSA/OCSP/CRL and blanket compliance claims

## Active Milestone

### v2.2 Long-Lived Signatures & Compliance Evidence

- **Status:** active
- **Why next:** This is the highest-leverage prerequisite between “Rendro can sign” and “Rendro supports a production-credible signed-document workflow.” It deepens the shipped signing seam without prematurely jumping to viewer promises or broad enterprise marketing.
- **Scope recommendation:**
  - Artifact-first timestamp and revocation evidence support over the shipped signing seam
  - Validator-backed classification for integrity, timestamp, revocation, and narrow compliance posture
  - Exact support-matrix, docs, and operator recipe updates tied to live proof
- **Non-goals:**
  - Blanket compliance branding or vague “enterprise signing” narratives
  - Viewer promotion without named recorded proof
  - Multi-signature workflows, HSM orchestration, or signer-identity products

## Next Candidates

### v2.3 Viewer Proof & Interop Closure

- **Status:** candidate
- **Why after v2.2:** Once long-lived evidence is proof-backed, the biggest remaining trust gap is surface-by-surface viewer evidence. Users need to know what actually works in Acrobat, Preview, PDFium, and PDF.js before broader adoption claims get stronger.
- **Scope recommendation:**
  - Recorded viewer checklists for forms, protection, signature widgets, signing preparation, and signed artifacts
  - Support-matrix promotion only where exact surface/viewer evidence exists
  - Troubleshooting and operator guidance for proven vs unverified viewer paths
- **Non-goals:**
  - Blanket “works in standard viewers” wording
  - New trust-sensitive feature families unrelated to interop proof
  - Compliance expansion beyond the exact evidence already shipped

### v2.4 Batteries-Included Workflow & Adoption Closure

- **Status:** candidate
- **Why after v2.3:** Once trust and interop boundaries are explicit, Rendro can package one opinionated, easy-to-adopt path that feels complete for real Phoenix teams instead of forcing them to assemble the story themselves.
- **Scope recommendation:**
  - Canonical end-to-end Phoenix/Oban/Mailglass/Threadline workflows
  - Richer batteries-included recipes, fixtures, and onboarding paths
  - Release/documentation polish aimed at shortening time-to-first-production-use
- **Non-goals:**
  - App-specific scaffolds or hosted services
  - Reopening low-level trust semantics already fixed in earlier milestones
  - Broad new engine capability families that belong in separate milestones

### v2.5 Global Text Shaping & Script Support

- **Status:** conditional_candidate
- **Why later:** Honest Unicode boundaries remain a real adoption limit, but this is a large core investment that should land only after nearer-term trust/adoption blockers are closed or clear demand makes it the top priority.
- **Scope recommendation:**
  - A proof-backed path for complex shaping and RTL support
  - Explicit font/script support boundaries and validation surfaces
  - A clear architecture decision on how to preserve core product honesty while expanding script coverage
- **Non-goals:**
  - Marketing “supports every language” without proof
  - Silent fallback shaping or browser-runtime dependencies
  - Bundling this work into unrelated trust milestones

## Arc Rules

- Treat unsigned field authoring, cryptographic signing, long-lived evidence, viewer proof, and broader adoption packaging as separate milestone layers unless a future proof-backed design shows they can be merged safely.
- Keep core focused on deterministic authored surfaces and optional adapters focused on environment-specific trust operations.
- Keep `priv/support_matrix.json`, docs-contract tests, live proof lanes, and milestone scope in lockstep before claiming any new signing, compliance, or viewer boundary.
- Prefer closing the highest-leverage prerequisite in the active arc before jumping to disconnected feature work.
- Re-evaluate the `v2.5` global text-shaping candidate only if adoption demand or customer pressure makes it more urgent than the remaining trust-and-adoption milestones.
