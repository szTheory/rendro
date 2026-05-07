# Phase 53: Delivery Threading and Truthful Support Contract - Research

**Researched:** 2026-05-06 [VERIFIED: local environment]  
**Domain:** Protected-artifact delivery threading, first-party storage example semantics, and support-contract closure for the `protection` family [VERIFIED: repo inspection]  
**Confidence:** HIGH [VERIFIED: repo inspection]

<user_constraints>
## User Constraints (from CONTEXT.md)

_Verbatim copy from `.planning/phases/53-delivery-threading-and-truthful-support-contract/53-CONTEXT.md`. [VERIFIED: repo inspection]_

### Locked Decisions
- **D-01:** Keep `Rendro.Adapters.Oban.RenderWorker` render-only in Phase 53. Do not add a first-party protected async worker or queue-aware orchestrator. [VERIFIED: repo inspection]
- **D-02:** The canonical async protected-delivery story is application-owned: `build -> render_to_artifact -> protect -> store/deliver`, with secrets fetched at execution time inside the application boundary rather than persisted in Oban args. [VERIFIED: repo inspection]
- **D-03:** Rendro should ship one strong copyable recipe for protected async delivery instead of a new orchestration API: identifiers in job args, late password resolution, and explicit downstream storage/delivery handoff. [VERIFIED: repo inspection]
- **D-04:** Keep `Rendro.Storage` itself narrow: protected bytes must persist and retrieve without the storage seam learning passwords. [VERIFIED: repo inspection]
- **D-05:** Do not widen the `Rendro.Storage` behaviour so every adapter must round-trip full artifact metadata. [VERIFIED: repo inspection]
- **D-06:** First-party storage examples and first-party simple adapters that support `get/2` should preserve `artifact.metadata.protection` across reload via an explicit sidecar/manifest or equivalent metadata envelope, so Rendro’s own examples do not drop protection semantics after retrieval. [VERIFIED: repo inspection]
- **D-07:** Docs must distinguish clearly between the narrow behaviour contract and richer first-party example patterns, so custom adapters are not over-promised while least-surprise DX is preserved. [VERIFIED: repo inspection]
- **D-08:** Keep Mailglass transport-only. Do not add `attach_protected_pdf/4`, `protect:` options, or any delivery-adapter-owned protection policy. [VERIFIED: repo inspection]
- **D-09:** `attach_pdf/3` should remain the plain render-and-attach convenience path for unprotected PDFs only. [VERIFIED: repo inspection]
- **D-10:** The canonical protected-delivery path is `Rendro.Protect.password/2` first, then `Rendro.Adapters.Mailglass.attach_artifact/3`. [VERIFIED: repo inspection]
- **D-11:** Mailglass docs, moduledoc, and docs-contract tests should make the boundary explicit: Mailglass transports already-protected bytes but never accepts, persists, derives, or manages password material. [VERIFIED: repo inspection]
- **D-12:** Preserve the existing family-first `protection` support-matrix shape from Phase 50 rather than redesigning it into a larger taxonomy. [VERIFIED: repo inspection]
- **D-13:** Add a small explicit `protection.boundaries` subsection to the machine-readable contract for the highest-risk misreads:
  - external-hook-only posture
  - password material does not belong in persisted async job args
  - delivery/storage seams transport protected artifacts, not passwords [VERIFIED: repo inspection]
- **D-14:** Keep the rest of the `protection` family compact and product-facing: capabilities, algorithms, behaviors, viewers. [VERIFIED: repo inspection]
- **D-15:** Human docs and docs-contract tests must lock the same boundary story as the matrix: password-to-open is supported through an external artifact-first hook; advisory permissions are honor-system only; protection is not signing, tamper evidence, compliance, or native in-core encryption. [VERIFIED: repo inspection]
- **D-16:** Shift the user’s preference left into downstream GSD work for this phase and similar work: default to one cohesive recommendation set that already optimizes for least surprise, truthful boundaries, Elixir/Phoenix idioms, and strong DX rather than escalating menus of equivalent options. [VERIFIED: repo inspection]
- **D-17:** Escalate only if a choice would materially change product semantics, widen the public support claim, or move Rendro toward framework-like orchestration rather than a narrow library boundary. [VERIFIED: repo inspection]

### Claude's Discretion
- Exact naming of the new support-matrix `boundaries` leaves, as long as they remain small, explicit, and policy-level rather than seam-exhaustive. [VERIFIED: repo inspection]
- Exact shape of the first-party sidecar/manifest storage example, as long as it preserves `metadata.protection` without implying every storage adapter must do the same. [VERIFIED: repo inspection]
- Exact wording and placement of async protected-delivery recipes in guides, as long as late secret resolution and application-owned orchestration remain the normative path. [VERIFIED: repo inspection]

### Deferred Ideas (OUT OF SCOPE)
- A first-party protected async worker or queue-aware orchestrator. [VERIFIED: repo inspection]
- Delivery-adapter APIs such as `attach_protected_pdf/4` or `protect:` options on `attach_pdf/3`. [VERIFIED: repo inspection]
- Widening `Rendro.Storage` so all adapters must round-trip rich artifact metadata. [VERIFIED: repo inspection]
- A large support-matrix taxonomy for every protection nuance, validator mode, or delivery seam. [VERIFIED: repo inspection]
- Native in-core encryption, digital signatures, tamper-evidence claims, PDF/A/compliance narratives, or broader security marketing. [VERIFIED: repo inspection]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADAPT-03 | Existing artifact-delivery seams continue to work with already-protected artifacts without learning password material themselves. [VERIFIED: `.planning/REQUIREMENTS.md`] | Keep `Rendro.Protect.password/2` as the only protection-policy owner, keep `Rendro.Adapters.Mailglass.attach_artifact/3` as the protected transport seam, keep `Rendro.Adapters.Oban.RenderWorker` render-only, and make first-party storage examples preserve `metadata.protection` on reload without widening `Rendro.Storage`. [VERIFIED: repo inspection][CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| TRUST-01 | `priv/support_matrix.json` publishes a dedicated `protection` family covering password-to-open, advisory permissions, unsupported native encryption, and unsupported compliance/signature narratives. [VERIFIED: `.planning/REQUIREMENTS.md`] | Extend the existing `protection` family with a compact `boundaries` subsection instead of redesigning the matrix, then lock that shape with docs-contract tests. [VERIFIED: repo inspection] |
| TRUST-02 | Public docs distinguish password-to-open from advisory permissions and explicitly state that protection is not digital signing, tamper evidence, or PDF/A/compliance support. [VERIFIED: `.planning/REQUIREMENTS.md`] | Close wording drift across `guides/api_stability.md`, `guides/integrations.md`, Mailglass moduledoc, and docs-contract tests so every public surface repeats the same narrow story. [VERIFIED: repo inspection][CITED: https://qpdf.readthedocs.io/en/latest/cli.html] |
</phase_requirements>

## Summary

Phase 53 should be planned as two tightly-coupled closures: first, protect the existing delivery/storage seams from semantic drift; second, make the `protection` support contract explicitly machine-readable and human-readable in the same words. The repo already has the right runtime shape for `ADAPT-03`: `Rendro.Protect.password/2` produces a normal `%Rendro.Artifact{}` with narrow `metadata.protection`, `Rendro.Adapters.Mailglass.attach_artifact/3` transports any artifact bytes without receiving secrets, and `Rendro.Adapters.Oban.RenderWorker` stays render-only and already rejects any broader queue contract in docs. [VERIFIED: repo inspection]

The main repo-local gap is first-party retrieval semantics, not transport. `Rendro.Storage.Local.put/2` persists only the PDF bytes and `get/2` reconstructs a blank `%Rendro.Artifact{metadata: %{}}`, which means a protected artifact loses `metadata.protection` and `metadata.deterministic` after reload even though Phase 51 established those fields as meaningful product behavior. Phase 53 should fix that in Rendro-owned examples with a sidecar or manifest pattern while leaving `Rendro.Storage` itself narrow and unchanged. [VERIFIED: repo inspection]

The main documentation gap is that the current `protection` family and guides say the right high-level things but still leave the highest-risk operational boundaries implicit. Phase 53 should add a compact `protection.boundaries` subsection to `priv/support_matrix.json`, then repeat that same contract in `guides/api_stability.md`, `guides/integrations.md`, Mailglass moduledoc, and docs-contract tests: password-to-open is supported through an external artifact-first hook; advisory permissions are viewer-honored-at-best; delivery and storage seams transport protected bytes, not password material; and none of this is native encryption, signing, tamper evidence, or compliance support. [VERIFIED: repo inspection][CITED: https://qpdf.readthedocs.io/en/latest/cli.html]

**Primary recommendation:** keep all runtime APIs as they are, upgrade only the first-party storage example semantics plus support-contract wording/tests, and make the canonical async protected-delivery recipe application-owned with identifiers-in-jobs and late secret resolution. [VERIFIED: repo inspection][CITED: https://hexdocs.pm/oban/Oban.Worker.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Protection policy and password validation | API / Backend | — | `Rendro.Protect.password/2` already owns the public protection contract and should remain the only place that accepts password material. [VERIFIED: repo inspection] |
| Async orchestration for protected delivery | Application job layer | API / Backend | The locked Phase 53 shape is application-owned `build -> render_to_artifact -> protect -> store/deliver`, not a Rendro-owned worker/orchestrator. [VERIFIED: repo inspection][CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| Persisted job payload | Database / Storage | Application job layer | Oban stores worker args as JSON/JSONB-backed maps with string keys, which is exactly why password material should stay out of job args. [CITED: https://hexdocs.pm/oban/Oban.Worker.html][CITED: https://hexdocs.pm/oban/Oban.Job.html] |
| Protected-byte transport to email | Adapter boundary | Application job layer | `Rendro.Adapters.Mailglass.attach_artifact/3` already consumes an artifact and never needs passwords or protection options. [VERIFIED: repo inspection] |
| Artifact reload semantics in first-party examples | Storage adapter | Database / Storage | `Rendro.Storage.Local.get/2` currently rebuilds blank metadata; preserving `metadata.protection` belongs in the first-party adapter implementation, not the global behavior. [VERIFIED: repo inspection] |
| Protection support language | Docs / Contract tier | Test / CI | `priv/support_matrix.json`, `guides/api_stability.md`, `guides/integrations.md`, and docs-contract tests are the authoritative public contract surfaces for this phase. [VERIFIED: repo inspection] |

## Project Constraints

- Keep Rendro core pure and optional-adapter-first; no Phase 53 recommendation should introduce a hard dependency on Mailglass, Oban, or a new storage/encryption package. [VERIFIED: AGENTS.md][VERIFIED: repo inspection]
- Keep docs claims as contracts; machine-readable and human-readable protection wording must land together. [VERIFIED: AGENTS.md][VERIFIED: repo inspection]
- Preserve the existing architecture where operational features compose around artifacts after render rather than widening `Rendro.render/2` or document-authored state. [VERIFIED: AGENTS.md][VERIFIED: repo inspection]
- Preserve deterministic versus advisory proof-lane separation; Phase 53 closes delivery/support language, not viewer-proof promotion. [VERIFIED: AGENTS.md][VERIFIED: repo inspection]

## Standard Stack

### Core
| Library / Surface | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| `Rendro.Protect` | repo-local | Canonical artifact-first protection boundary | It already normalizes options, redacts password material, and emits the narrow `metadata.protection` contract that downstream delivery should preserve rather than reinterpret. [VERIFIED: repo inspection] |
| `Rendro.Artifact` | repo-local | Stable transport wrapper for render, protect, store, and deliver seams | `wrap/3` already preserves metadata across post-render transforms, making artifact threading the right composition point. [VERIFIED: repo inspection] |
| `Rendro.Storage` | repo-local behavior | Narrow persistence contract | The behavior already says `put/2`, `get/2`, and `delete/2`; Phase 53 should not widen it to require rich metadata round-tripping. [VERIFIED: repo inspection] |
| `Rendro.Storage.Local` | repo-local example adapter | First-party simple storage example | It is the natural place to preserve protection metadata with a sidecar or manifest because it already owns both `put/2` and `get/2`. [VERIFIED: repo inspection] |
| `Rendro.Adapters.Mailglass` | repo-local optional adapter | Protected-artifact delivery transport | `attach_artifact/3` already transports artifact bytes without any password API. [VERIFIED: repo inspection] |
| `Rendro.Adapters.Oban.RenderWorker` | repo-local optional adapter | Render-only async worker seam | The worker already accepts only builder, args, storage, and policies; docs already warn against password/protection job args. [VERIFIED: repo inspection][CITED: https://hexdocs.pm/oban/Oban.Worker.html] |

### Supporting
| Library / Surface | Version | Purpose | When to Use |
|-------------------|---------|---------|-------------|
| `priv/support_matrix.json` | repo-local contract | Machine-readable protection claims | Use as the canonical source for `protection.capabilities`, `algorithms`, `behaviors`, `boundaries`, and `viewers`. [VERIFIED: repo inspection] |
| `guides/api_stability.md` | repo-local guide | Human-readable support boundary | Use for the normative “what protection is and is not” language. [VERIFIED: repo inspection] |
| `guides/integrations.md` | repo-local guide | Async and delivery recipe guidance | Use for the canonical identifiers-in-jobs, late-secret-resolution, and `attach_artifact/3` recipe. [VERIFIED: repo inspection] |
| Docs-contract tests | repo-local | Contract drift prevention | Use `test/docs_contract/protection_claims_test.exs` and `test/docs_contract/integrations_claims_test.exs` to lock wording and matrix shape together. [VERIFIED: repo inspection] |
| Oban | `~> 2.17` in repo deps | Optional job runner ecosystem reference | Use only for recipe wording and worker-shape truth; do not add new Oban-only APIs in Rendro. [VERIFIED: repo inspection][CITED: https://hexdocs.pm/oban/Oban.Worker.html] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Application-owned protected async recipe | First-party protected worker/orchestrator | Rejected because it would widen Rendro from a narrow library boundary into queue orchestration semantics. [VERIFIED: repo inspection] |
| Narrow `Rendro.Storage` plus richer first-party example | Global metadata round-trip behavior | Rejected because it would over-promise every storage adapter’s semantics. [VERIFIED: repo inspection] |
| `attach_artifact/3` for protected delivery | `attach_pdf/3` with `protect:` or a new `attach_protected_pdf/4` | Rejected because it would push password/policy knowledge into the delivery adapter. [VERIFIED: repo inspection] |
| Compact `protection.boundaries` leaves | Large protection taxonomy | Rejected because the repo’s existing support-matrix style is family-first, product-facing, and intentionally small. [VERIFIED: repo inspection] |

## Architecture Patterns

### System Architecture Diagram

```text
Oban job args / app trigger
  - business identifiers only
  - never passwords
        |
        v
application-owned worker/service
  - build_document(args)
  - Rendro.render_to_artifact(doc)
        |
        v
late secret resolution
  - fetch open/owner passwords at execution time
  - outside persisted job args
        |
        v
Rendro.Protect.password/2
  - AES-256 only
  - emits metadata.protection
        |
        +----------------------+
        |                      |
        v                      v
first-party storage example    Mailglass transport
  - persist bytes + manifest     - attach_artifact/3
  - get/2 rebuilds metadata      - bytes only, no passwords
        |                      |
        +-----------+----------+
                    |
                    v
public contract surfaces
  - support_matrix.json
  - api_stability.md
  - integrations.md
  - docs-contract tests
```

### Recommended Project Structure

```text
lib/rendro/
├── protect.ex                        # password-bearing public boundary
├── artifact.ex                       # metadata-preserving wrapper
├── storage.ex                        # narrow behavior contract
├── storage/local.ex                  # first-party byte + manifest example
└── adapters/
    ├── mailglass.ex                  # transport-only delivery seam
    └── oban/render_worker.ex         # render-only async seam

guides/
├── integrations.md                   # canonical async + delivery recipes
└── api_stability.md                  # canonical protection support wording

priv/
└── support_matrix.json               # machine-readable protection contract

test/
├── docs_contract/                    # wording + matrix lockstep
└── rendro/adapters/                  # Mailglass / Oban / storage regressions
```

### Pattern 1: Application-owned protected async delivery
**What:** Keep the current render worker narrow and document the protected workflow as `build -> render_to_artifact -> late secret lookup -> protect -> store/deliver`. [VERIFIED: repo inspection][CITED: https://hexdocs.pm/oban/Oban.Worker.html]  
**When to use:** Any Oban-backed or application-managed background delivery of protected PDFs. [VERIFIED: repo inspection]  
**Why:** Oban job args are persisted JSON/JSONB-backed maps with string keys, so putting password material there would intentionally widen the secret surface. [CITED: https://hexdocs.pm/oban/Oban.Worker.html][CITED: https://hexdocs.pm/oban/Oban.Job.html]  
**Example:**
```elixir
# Source: repo seams + Oban worker semantics
def perform(%Oban.Job{args: %{"invoice_id" => invoice_id}}) do
  doc = MyApp.InvoiceDocument.build_document(%{"invoice_id" => invoice_id})
  {:ok, artifact} = Rendro.render_to_artifact(doc)

  passwords = MyApp.SecretStore.fetch_pdf_passwords!(invoice_id)

  {:ok, protected} =
    Rendro.Protect.password(artifact,
      open_password: passwords.open,
      owner_password: passwords.owner,
      advisory_permissions: [:print]
    )

  :ok = MyApp.Delivery.deliver_protected_invoice(protected, invoice_id)
end
```
[VERIFIED: repo inspection][CITED: https://hexdocs.pm/oban/Oban.Worker.html]

### Pattern 2: First-party storage example preserves protection metadata with a sidecar
**What:** Persist PDF bytes at the requested path and persist a tiny adjacent manifest containing only the metadata Rendro itself already treats as product behavior, then rebuild the artifact from both on `get/2`. [VERIFIED: repo inspection]  
**When to use:** In `Rendro.Storage.Local` or any Rendro-owned example storage adapter that implements `get/2`. [VERIFIED: repo inspection]  
**Why:** `Local.get/2` currently returns `%Rendro.Artifact{metadata: %{}}`, which drops `metadata.protection` and `metadata.deterministic` after reload. [VERIFIED: repo inspection]  
**Example:**
```elixir
# Source: recommended Phase 53 example pattern
metadata_manifest = %{
  deterministic: artifact.metadata[:deterministic],
  protection: artifact.metadata[:protection],
  page_count: artifact.metadata[:page_count]
}

File.write!(path, artifact.binary)
File.write!(path <> ".artifact.json", Jason.encode!(metadata_manifest))
```
[ASSUMED]

### Pattern 3: Mailglass stays transport-only
**What:** Keep `attach_pdf/3` as the unprotected convenience API and keep protected delivery on `attach_artifact/3` only. [VERIFIED: repo inspection]  
**When to use:** Any docs, moduledoc, examples, or tests involving protected email delivery. [VERIFIED: repo inspection]  
**Why:** `attach_artifact/3` already accepts a `%Rendro.Artifact{}` and consumes only `artifact.binary`; adding password options would duplicate or relocate protection policy. [VERIFIED: repo inspection]  
**Example:**
```elixir
# Source: existing adapter seam
{:ok, protected} = Rendro.Protect.password(artifact, open_password: "...", owner_password: "...")
email_with_attachment =
  Rendro.Adapters.Mailglass.attach_artifact(email, protected, "invoice.pdf")
```
[VERIFIED: repo inspection]

### Pattern 4: Support matrix and docs say the same boundary in the same phase
**What:** Add `protection.boundaries` leaves in `priv/support_matrix.json` and assert the same concepts textually in docs-contract tests. [VERIFIED: repo inspection]  
**When to use:** Any change to `protection` family wording or async/delivery guidance. [VERIFIED: repo inspection]  
**Recommended leaves:**  
- `external_hook_only` [VERIFIED: repo inspection]  
- `passwords_in_persisted_job_args` [VERIFIED: repo inspection]  
- `delivery_seams_transport_bytes_not_passwords` [VERIFIED: repo inspection]  
- `storage_examples_preserve_metadata_not_passwords` [ASSUMED]  

### Anti-Patterns to Avoid

- **Do not add a first-party protected Oban worker:** it changes Rendro from a library recipe provider into a queue orchestration framework. [VERIFIED: repo inspection]
- **Do not add `protect:` to `attach_pdf/3` or create `attach_protected_pdf/4`:** it would move password policy into the delivery adapter. [VERIFIED: repo inspection]
- **Do not widen `Rendro.Storage` to require full metadata round-trips for every adapter:** Phase 53 only needs better first-party example semantics. [VERIFIED: repo inspection]
- **Do not describe advisory permissions as security enforcement:** qpdf’s own docs say restrictions may not be enforced and readers may ignore them. [CITED: https://qpdf.readthedocs.io/en/latest/cli.html]
- **Do not let storage reload silently erase `metadata.protection`:** first-party examples should not teach users that raw bytes are equivalent to a full artifact contract. [VERIFIED: repo inspection]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Protected async orchestration | First-party protected worker stack | One documented application-owned recipe | The repo already has the right seams; Phase 53 is clarification and contract closure, not a new runtime subsystem. [VERIFIED: repo inspection] |
| Global storage metadata contract | New required behavior callbacks for metadata manifests | Narrow `Rendro.Storage` + richer `Rendro.Storage.Local` example | Keeps custom adapters unconstrained while making Rendro-owned examples truthful. [VERIFIED: repo inspection] |
| Delivery-time protection policy | Mailglass-side password options | `Rendro.Protect.password/2` before `attach_artifact/3` | Keeps password material and crypto policy at the artifact boundary. [VERIFIED: repo inspection] |
| Security marketing taxonomy | Large matrix of vague “secure PDF” narratives | Small explicit `protection.boundaries` leaves plus direct prose | More specific and easier to lock with docs-contract tests. [VERIFIED: repo inspection] |

**Key insight:** Phase 53 does not need new capability to satisfy `ADAPT-03`; it needs semantic preservation and wording closure around seams that already exist. [VERIFIED: repo inspection]

## Common Pitfalls

### Pitfall 1: Protected artifact semantics disappear after storage reload
**What goes wrong:** A protected artifact is stored and later reloaded as a blank-metadata `%Rendro.Artifact{}`, so downstream code can no longer tell it was protected or non-deterministic. [VERIFIED: repo inspection]  
**Why it happens:** `Rendro.Storage.Local.get/2` currently reconstructs only `binary`, `hash`, empty `diagnostics`, and `%{}` metadata. [VERIFIED: repo inspection]  
**How to avoid:** Preserve a narrow sidecar or manifest in Rendro-owned examples and rebuild `metadata.deterministic` plus `metadata.protection` on `get/2`. [VERIFIED: repo inspection][ASSUMED]  
**Warning signs:** `Local.get/2` tests assert only bytes/hash and never assert metadata preservation for protected artifacts. [VERIFIED: repo inspection]

### Pitfall 2: Passwords leak into persisted async payloads
**What goes wrong:** Job args start carrying open/owner passwords or password references as part of Rendro’s documented worker contract. [VERIFIED: repo inspection]  
**Why it happens:** It is tempting to make the worker “convenient,” but Oban persists args as JSON/JSONB-backed maps and stringifies keys. [CITED: https://hexdocs.pm/oban/Oban.Worker.html][CITED: https://hexdocs.pm/oban/Oban.Job.html]  
**How to avoid:** Keep Oban args to business identifiers only and resolve secrets inside the application boundary during `perform/1`. [VERIFIED: repo inspection][CITED: https://hexdocs.pm/oban/Oban.Worker.html]  
**Warning signs:** Docs mention `"open_password"` or `"owner_password"` in worker args examples. [VERIFIED: repo inspection]

### Pitfall 3: Mailglass wording implies it manages protection
**What goes wrong:** Users infer that `attach_pdf/3` can “just handle” protection or that Mailglass stores/derives passwords. [VERIFIED: repo inspection]  
**Why it happens:** The adapter already has both `attach_pdf/3` and `attach_artifact/3`, but the distinction is only partially stressed today. [VERIFIED: repo inspection]  
**How to avoid:** Make docs and moduledoc explicit that `attach_pdf/3` is unprotected render-and-attach only, while protected delivery is `Protect.password/2` then `attach_artifact/3`. [VERIFIED: repo inspection]  
**Warning signs:** New examples skip the artifact step when showing protected delivery. [VERIFIED: repo inspection]

### Pitfall 4: Support language says “encryption” more broadly than the repo proves
**What goes wrong:** Users infer native encryption, signing, tamper evidence, or compliance support from high-level wording. [VERIFIED: repo inspection]  
**Why it happens:** The current `protection` family is narrow but does not yet make the operational boundaries first-class leaves. [VERIFIED: repo inspection]  
**How to avoid:** Add `protection.boundaries` and repeat those boundaries word-for-word in docs-contract tests. [VERIFIED: repo inspection]  
**Warning signs:** Docs introduce phrases like “secure PDFs,” “signed,” or “compliant” without equally explicit negation. [VERIFIED: repo inspection]

## Code Examples

### Canonical protected delivery recipe
```elixir
# Source: repo seams
{:ok, artifact} = Rendro.render_to_artifact(doc)

{:ok, protected} =
  Rendro.Protect.password(artifact,
    open_password: open_password,
    owner_password: owner_password,
    advisory_permissions: [:print]
  )

email =
  Rendro.Adapters.Mailglass.attach_artifact(email, protected, "invoice.pdf")
```
[VERIFIED: repo inspection]

### Canonical async recipe with identifiers in jobs
```elixir
# Source: recommended Phase 53 docs recipe
def perform(%Oban.Job{args: %{"invoice_id" => invoice_id}}) do
  doc = MyApp.InvoiceDocument.build_document(%{"invoice_id" => invoice_id})
  {:ok, artifact} = Rendro.render_to_artifact(doc)
  passwords = MyApp.SecretStore.fetch_pdf_passwords!(invoice_id)

  with {:ok, protected} <-
         Rendro.Protect.password(artifact,
           open_password: passwords.open,
           owner_password: passwords.owner,
           advisory_permissions: [:print]
         ),
       {:ok, identifier} <- MyApp.ProtectedStorage.put(protected, invoice_id) do
    {:ok, identifier}
  end
end
```
[ASSUMED][CITED: https://hexdocs.pm/oban/Oban.Worker.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Protected delivery as an implied adapter concern | Protected delivery is explicitly artifact-first and adapter-agnostic | Locked in Phase 51 and reiterated in Phase 53 context. [VERIFIED: repo inspection] | Keeps passwords out of Mailglass and Oban adapter APIs. [VERIFIED: repo inspection] |
| Raw bytes treated as sufficient storage reload state | First-party examples should rebuild artifact metadata from bytes plus sidecar/manifest | Locked in Phase 53 discussion/context. [VERIFIED: repo inspection] | Avoids semantic loss after retrieval without widening `Rendro.Storage`. [VERIFIED: repo inspection] |
| High-level protection wording only | Explicit `protection.boundaries` leaves + matching prose | Planned for Phase 53. [VERIFIED: repo inspection] | Makes the highest-risk misreads executable in docs-contract tests. [VERIFIED: repo inspection] |

**Deprecated/outdated:** Treating `Rendro.Storage.Local.get/2`’s current blank metadata reconstruction as a truthful example for protected artifacts is outdated for Phase 53’s locked direction. [VERIFIED: repo inspection]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Rendro.Storage.Local` can add a tiny sidecar/manifest without conflicting with any undocumented first-party API promises beyond the existing `path` option. [ASSUMED] | Architecture Patterns / Common Pitfalls | Medium — if there is an unstated packaging or path-compatibility constraint, the plan may need a different example-storage mechanism. |
| A2 | Adding a fourth `protection.boundaries.storage_examples_preserve_metadata_not_passwords` leaf would help docs clarity without over-expanding the matrix. [ASSUMED] | Architecture Patterns | Low — the plan can fall back to the three explicitly locked leaves if this feels too detailed. |
| A3 | The illustrative sidecar example can reasonably use an adjacent JSON manifest file such as `path <> ".artifact.json"` without introducing misleading first-party semantics. [ASSUMED] | Architecture Patterns / Code Examples | Low — the planner can swap the exact manifest format or path convention without changing the phase semantics. |
| A4 | The canonical async recipe should be documented with application-owned secret resolution via an app-specific secret store helper rather than a narrower repo-provided helper. [ASSUMED] | Architecture Patterns / Code Examples | Low — the exact helper name is schematic, but the late-secret-resolution posture must remain. |
| A5 | If the phase is delayed materially, external Oban/qpdf docs should be rechecked after 2026-06-05 even though the repo-local seam guidance is likely still valid. [ASSUMED] | Metadata | Low — only the freshness estimate changes, not the locked repo-local recommendations. |

## Open Questions (RESOLVED)

1. **Should `Rendro.Storage.Local` write the sidecar beside the PDF by default or only when metadata exists?** [RESOLVED]
   - Decision: write the tiny first-party manifest beside the PDF by default, even when the preserved metadata envelope is small. [RESOLVED]
   - Why: consistent write/read/delete behavior is the least-surprise option for Rendro-owned examples and avoids conditional retrieval branches that would otherwise make protected-artifact reload semantics harder to reason about. [VERIFIED: phase context][VERIFIED: repo inspection]
   - Guardrails: the manifest remains minimal and password-safe, storing only the small artifact metadata envelope already considered product behavior; delete-path cleanup should remove the adjacent manifest together with the PDF in the first-party adapter so orphan-sidecar behavior is not left ambiguous. [VERIFIED: phase context][ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` / ExUnit | Docs-contract and adapter regression runs | ✓ [VERIFIED: local environment] | Elixir `1.19.5`, OTP `28` [VERIFIED: local environment] | — |
| `pdfinfo` | Existing structural-validation lane, but not central to Phase 53 implementation | ✓ [VERIFIED: local environment] | `26.04.0` [VERIFIED: local environment] | — |
| `qpdf` | Existing protection proof lane and docs references, but not required to implement Phase 53 wording/storage work | ✗ [VERIFIED: local environment] | — | Reuse hermetic tests and docs-contract lane; Phase 53 should not depend on live qpdf execution. [VERIFIED: repo inspection] |
| Oban dependency | Optional worker examples and compile-time adapter presence | repo-optional [VERIFIED: repo inspection] | `~> 2.17` in `mix.exs` [VERIFIED: repo inspection] | Keep guidance schematic and guard adapter tests the same way the repo already does. [VERIFIED: repo inspection] |

**Missing dependencies with no fallback:**
- None for the core Phase 53 docs/storage/test closure. [VERIFIED: repo inspection]

**Missing dependencies with fallback:**
- `qpdf` is missing locally, but Phase 53 planning can rely on docs-contract, Mailglass/Oban/storage tests, and existing hermetic protection seams without blocking. [VERIFIED: local environment][VERIFIED: repo inspection]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix test tasks. [VERIFIED: repo inspection] |
| Config file | none; test lanes are driven by `mix test` and `scripts/verify_docs.exs`. [VERIFIED: repo inspection] |
| Quick run command | `mix test test/docs_contract/protection_claims_test.exs test/docs_contract/integrations_claims_test.exs` [VERIFIED: repo inspection] |
| Full suite command | `mix test && mix run scripts/verify_docs.exs` [VERIFIED: repo inspection] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADAPT-03 | Protected artifacts move through Mailglass/storage seams without password-bearing APIs or persisted Oban args. [VERIFIED: `.planning/REQUIREMENTS.md`] | unit + docs-contract | `mix test test/rendro/adapters/mailglass_test.exs test/rendro/adapters/oban/render_worker_test.exs test/docs_contract/integrations_claims_test.exs` [VERIFIED: repo inspection] | ✅ partial coverage exists; storage metadata round-trip coverage is missing. [VERIFIED: repo inspection] |
| TRUST-01 | `protection` family publishes dedicated capability/boundary wording. [VERIFIED: `.planning/REQUIREMENTS.md`] | docs-contract | `mix test test/docs_contract/protection_claims_test.exs` [VERIFIED: repo inspection] | ✅ exists, but needs `boundaries` assertions. [VERIFIED: repo inspection] |
| TRUST-02 | Public docs clearly distinguish password-to-open, advisory permissions, and unsupported narratives. [VERIFIED: `.planning/REQUIREMENTS.md`] | docs-contract | `mix run scripts/verify_docs.exs` [VERIFIED: repo inspection] | ✅ exists, but Mailglass/moduledoc + integrations wording should be tightened. [VERIFIED: repo inspection] |

### Sampling Rate
- **Per task commit:** `mix test test/docs_contract/protection_claims_test.exs test/docs_contract/integrations_claims_test.exs` [VERIFIED: repo inspection]
- **Per wave merge:** `mix test test/rendro/adapters/mailglass_test.exs test/rendro/adapters/oban/render_worker_test.exs test/rendro/end_to_end_pipeline_test.exs && mix run scripts/verify_docs.exs` [VERIFIED: repo inspection]
- **Phase gate:** Full docs-contract lane plus affected adapter/storage tests green before `/gsd-verify-work`. [VERIFIED: repo inspection]

### Wave 0 Gaps
- [ ] `test/rendro/storage/local_test.exs` — add explicit protected-artifact round-trip coverage for `metadata.deterministic` and `metadata.protection`. [VERIFIED: repo inspection]
- [ ] `test/rendro/end_to_end_pipeline_test.exs` — extend the stored-artifact reload path or add a sibling test proving protected metadata survives first-party storage retrieval. [VERIFIED: repo inspection]
- [ ] `test/docs_contract/protection_claims_test.exs` — add `protection.boundaries` shape assertions and explicit negative-claim assertions for signing/compliance/native encryption wording. [VERIFIED: repo inspection]
- [ ] `test/docs_contract/integrations_claims_test.exs` — add explicit assertions that protected async examples use identifiers in job args and `attach_artifact/3` for protected delivery. [VERIFIED: repo inspection]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | — |
| V3 Session Management | no [VERIFIED: phase scope] | — |
| V4 Access Control | no [VERIFIED: phase scope] | — |
| V5 Input Validation | yes [VERIFIED: phase scope] | Keep password-bearing input confined to `Rendro.Protect.password/2`; keep Oban/storage/delivery seams from accepting protection secrets. [VERIFIED: repo inspection] |
| V6 Cryptography | yes [VERIFIED: phase scope] | Keep crypto claims narrow and delegated to the external qpdf adapter; do not reframe advisory permissions as enforcement. [VERIFIED: repo inspection][CITED: https://qpdf.readthedocs.io/en/latest/cli.html] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret persistence in async payloads | Information Disclosure | Keep job args to identifiers only and resolve passwords at execution time in app code. [VERIFIED: repo inspection][CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| Secret/policy confusion in delivery adapters | Tampering / Information Disclosure | Keep Mailglass transport-only and route all protection through `Rendro.Protect.password/2`. [VERIFIED: repo inspection] |
| Support-language overclaim (“secure”, “signed”, “compliant”) | Repudiation | Lock the machine-readable and human-readable contract together with docs-contract tests. [VERIFIED: repo inspection] |
| Metadata loss on storage reload | Integrity | Preserve `metadata.protection` and `metadata.deterministic` in Rendro-owned example storage reload flows. [VERIFIED: repo inspection] |

## Sources

### Primary (HIGH confidence)
- Repo inspection of required Phase 53 artifacts and implementation seams: `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/METHODOLOGY.md`, `.planning/milestones/v1.10-ROADMAP.md`, `.planning/phases/53-delivery-threading-and-truthful-support-contract/53-CONTEXT.md`, `.planning/phases/53-delivery-threading-and-truthful-support-contract/53-DISCUSSION-LOG.md`, `.planning/phases/50-support-boundary-and-proof-closure/50-CONTEXT.md`, `.planning/phases/51-protection-api-contract-and-validation/51-CONTEXT.md`, `.planning/phases/52-qpdf-adapter-and-structural-validation/52-CONTEXT.md`, `.planning/phases/50-support-boundary-and-proof-closure/50-01-PLAN.md`, `.planning/phases/52-qpdf-adapter-and-structural-validation/52-01-PLAN.md`, `.planning/phases/52-qpdf-adapter-and-structural-validation/52-02-PLAN.md`, `lib/rendro/protect.ex`, `lib/rendro/artifact.ex`, `lib/rendro/storage.ex`, `lib/rendro/storage/local.ex`, `lib/rendro/adapters/mailglass.ex`, `lib/rendro/adapters/oban/render_worker.ex`, `guides/integrations.md`, `guides/api_stability.md`, `priv/support_matrix.json`, `test/docs_contract/protection_claims_test.exs`, `test/docs_contract/integrations_claims_test.exs`, `test/rendro/adapters/mailglass_test.exs`, `test/rendro/adapters/oban/render_worker_test.exs`, `test/rendro/end_to_end_pipeline_test.exs`, `mix.exs`. [VERIFIED: repo inspection]

### Secondary (MEDIUM confidence)
- Oban.Worker docs: https://hexdocs.pm/oban/Oban.Worker.html — current official worker semantics for `perform/1`, persisted JSON/JSONB args, and stringified keys. [CITED: https://hexdocs.pm/oban/Oban.Worker.html]
- Oban.Job docs: https://hexdocs.pm/oban/Oban.Job.html — current official job type and map/database insertion semantics. [CITED: https://hexdocs.pm/oban/Oban.Job.html]
- qpdf CLI docs: https://qpdf.readthedocs.io/en/latest/cli.html — current official wording that restrictions may not be enforced and readers may ignore them. [CITED: https://qpdf.readthedocs.io/en/latest/cli.html]

### Tertiary (LOW confidence)
- None. [VERIFIED: source review]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - nearly all recommendations are anchored directly in existing repo seams and locked context. [VERIFIED: repo inspection]
- Architecture: HIGH - the phase boundary and rejected alternatives are explicitly locked in `53-CONTEXT.md` and `53-DISCUSSION-LOG.md`. [VERIFIED: repo inspection]
- Pitfalls: HIGH - the main failure modes are observable directly in current code/docs/tests, especially `Storage.Local.get/2`, Oban docs wording, and current Mailglass/integrations patterns. [VERIFIED: repo inspection][CITED: https://hexdocs.pm/oban/Oban.Worker.html]

**Research date:** 2026-05-06 [VERIFIED: local environment]  
**Valid until:** 2026-06-05 for repo-local seam guidance; re-check external Oban/qpdf docs if the phase is delayed materially. [ASSUMED]

## RESEARCH COMPLETE
