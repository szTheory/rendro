# Phase 50: Support-Boundary and Proof Closure - Research

**Researched:** 2026-05-06  
**Domain:** Support-contract closure for embedded files and links  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied verbatim from `.planning/phases/50-support-boundary-and-proof-closure/50-CONTEXT.md`. [VERIFIED: codebase grep]

### Locked Decisions
- **D-01:** Phase 50 should extend the existing **family-first nested support matrix** in `priv/support_matrix.json`, not replace it with a generic `"surfaces"` wrapper or a compatibility-database-style schema.
- **D-02:** The top-level family shape should remain explicit and product-facing: existing `forms`, plus new `embedded_files` and `links`.
- **D-03:** `embedded_files` should separate at least:
  - `capabilities`
  - `behaviors`
  - `viewers`
- **D-04:** `links` should separate at least:
  - `targets`
  - `behaviors`
  - `viewers`
- **D-05:** Avoid per-leaf statement objects unless a leaf genuinely needs richer metadata. Default shape should remain simple `"supported" | "unsupported" | "unverified"` values, with named viewer entries only where a proof checklist exists.
- **D-06:** Viewer claims must stay **per surface**, not one blanket `v1.9` viewer status shared across embedded files and links.
- **D-07:** `supported` means a named viewer passed a recorded checklist for that specific surface and behavior set.
- **D-08:** `unverified` is the default posture for authored surfaces that Rendro serializes structurally but has not proven in a named viewer.
- **D-09:** `unsupported` should be reserved for surfaces Rendro does not author or explicitly rejects, not for merely untested viewer behavior.
- **D-10:** Structural validity through `pdfinfo`/Poppler remains valuable but must be documented as a **different proof lane** from viewer interaction, discoverability, extraction, or policy behavior.
- **D-11:** Phase 50 should keep one **merge-blocking automated structural proof lane** and one **separate viewer-evidence lane**, following the Phase 47 pattern rather than inventing a heavier artifact system.
- **D-12:** Structural proof should be the real product contract:
  - deterministic fixtures for embedded files and links
  - writer/validation assertions
  - support-matrix and docs-contract synchronization
- **D-13:** Viewer proof should be the smallest durable manual lane needed to justify named support claims. It should not become a screenshot archive or a broad UX-certification system.
- **D-14:** The minimum recorded manual evidence per viewer check should be:
  - viewer name
  - version if easily available
  - OS
  - fixture name or path
  - date checked
  - pass/fail/unverified per named behavior
  - one short notes field only when behavior is surprising
- **D-15:** Use **`embedded files`** as the canonical public term for PDF-internal file payloads. Do not headline them as `attachments`, because Rendro already uses attachment language for delivery adapters outside the PDF binary.
- **D-16:** Use plain **`links`** in public API/docs prose because `Rendro.link/2` is already the explicit authored surface. Reserve `curated` for support-boundary prose and contract wording where scope fencing matters.
- **D-17:** Public docs should explicitly distinguish:
  - embedded files inside the PDF
  - delivery/email/download attachments outside the PDF
  - links limited to external `http`/`https` URIs and internal page destinations
- **D-18:** Docs should prefer one coherent recommendation set over presenting multiple equivalent ways to describe or consume the same feature.
- **D-19:** Downstream agents should default to **research-backed, cohesive recommendations** that already balance tradeoffs across Elixir ecosystem norms, adjacent-library lessons, truthful support boundaries, and least-surprise DX.
- **D-20:** Escalate to the user only when a choice materially changes product semantics, widens roadmap scope, or creates a high-impact policy tradeoff the maintainer is likely to care about directly.

### the agent's Discretion
- Exact nested key names under `embedded_files` and `links`, as long as they remain explicit, small, and stable.
- Which public docs surface becomes the canonical artifact-support guide, as long as `guides/api_stability.md`, `priv/support_matrix.json`, and docs-contract tests stay aligned.
- Which named viewers, if any, are promoted from `unverified` to `supported`, provided the checklist evidence is committed and wording matches it exactly.

### Deferred Ideas (OUT OF SCOPE)
- A generic top-level `"surfaces"` wrapper for the support matrix.
- BCD-style per-leaf metadata objects everywhere in the matrix.
- Blanket viewer support claims shared across all `v1.9` artifact surfaces.
- Heavy screenshot/archive workflows for viewer proof.
- Security/compliance claims about attachment safety, sandboxing, or encryption policy behavior.
- Any widening into generic annotations, richer URI schemes, named destinations, or delivery-adapter semantics.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TRUST-01 | Rendro publishes one proof-backed support contract for embedded files and curated link annotations across docs and `priv/support_matrix.json`. [VERIFIED: codebase grep] | Keep `guides/api_stability.md` as the single human-facing support guide, extend `priv/support_matrix.json` with `embedded_files` and `links`, add one dedicated docs-claims test file for artifact surfaces, and wire it into `scripts/verify_docs.exs` so all three move together. [VERIFIED: codebase grep] |
| TRUST-02 | Verification distinguishes structural proof from viewer behavior and does not claim support for artifact surfaces or viewers without recorded evidence. [VERIFIED: codebase grep] | Reuse the Phase 47 split: automated structural proof in ExUnit + Poppler, manual viewer evidence recorded in `50-VALIDATION.md`, and status promotion only when the checklist table is filled with passing results for that surface. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 50 should close `v1.9` without widening the PDF surface: extend the existing family-first contract in `priv/support_matrix.json`, keep `guides/api_stability.md` as the one authoritative human-facing support guide, and enforce lockstep with a new artifact-surface docs-claims test plus the existing `scripts/verify_docs.exs` lane. [VERIFIED: codebase grep]

The strongest low-risk design is the same one Phase 47 already proved for forms: one automated structural lane, one separate manual viewer-evidence lane, and one explicit sync point where recorded viewer results update both the matrix and the guide wording. [VERIFIED: codebase grep]

The matrix should stay small and explicit: top-level `forms`, `embedded_files`, and `links`; simple scalar statuses for most leaves; viewer objects only where a checklist exists; and no generic `"surfaces"` wrapper or compatibility-database-style statement objects. That keeps the artifact readable to humans, stable for tests, and aligned with Rendro’s “truthful small contracts” methodology. [VERIFIED: codebase grep]

**Primary recommendation:** Implement Phase 50 in three slices: first add the matrix schema and docs-claims lane with conservative `unverified` viewer posture, then add one combined structural proof fixture plus Phase 50 validation scaffolding, then run manual viewer checks and promote only the specific viewer-surface claims that the recorded table supports. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Machine-readable support contract | API / Backend | — | `priv/support_matrix.json` is versioned repo state owned by the library, not by external viewers or adapters. [VERIFIED: codebase grep] |
| Human-facing support wording | API / Backend | — | `guides/api_stability.md` already carries Rendro’s support-boundary policy and is the current canonical prose surface for forms. [VERIFIED: codebase grep] |
| Structural PDF proof | API / Backend | External validator | Existing writer tests and `Rendro.Adapters.Poppler` prove authored output structure, while `pdfinfo` remains a separate optional external validator rather than the source of semantics. [VERIFIED: codebase grep] |
| Viewer interaction evidence | Browser / Client | API / Backend | Acrobat Reader and Preview own click, discoverability, and extraction behavior after Rendro serializes the PDF; Rendro only owns the fixture and the recorded checklist. [VERIFIED: codebase grep] |
| Status promotion from `unverified` to `supported` | API / Backend | Browser / Client | Support status should be published by repo artifacts only after viewer-side behavior is observed and written back into the phase validation record. [VERIFIED: codebase grep] |

## Project Constraints (from AGENTS.md)

- Keep `rendro` core pure: no hard dependency on Phoenix, Oban, or admin tooling. [VERIFIED: user-provided AGENTS.md]
- Preserve deterministic and advisory verification lane separation in CI and docs. [VERIFIED: user-provided AGENTS.md]
- Treat documentation claims as contracts; do not claim unsupported capabilities. [VERIFIED: user-provided AGENTS.md]
- Prefer optional dependency guards for integrations; Phase 50 should not introduce new runtime dependencies for proof closure. [VERIFIED: user-provided AGENTS.md]
- Use GSD phase artifacts and keep research/planning/execution in sync. [VERIFIED: user-provided AGENTS.md]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 | Host language for docs-contract tests, fixture generators, and support-lane scripts. [VERIFIED: local command] | The repo already targets `~> 1.19` in `mix.exs`, and local tooling reports `1.19.5`. [VERIFIED: codebase grep] [VERIFIED: local command] |
| ExUnit | bundled with Elixir 1.19.5 | Enforce support-matrix and guide lockstep through file-content assertions and fixture-based proof tests. [VERIFIED: codebase grep] [VERIFIED: local command] | All existing docs-contract and Poppler proof lanes already run in ExUnit; Phase 50 needs extension, not a new framework. [VERIFIED: codebase grep] |
| `Rendro.Adapters.Poppler` / `pdfinfo` | Poppler `26.04.0` locally; matrix currently claims `22+` | Structural validation for representative generated PDFs. [VERIFIED: local command] [VERIFIED: codebase grep] | Phase 47 and Phase 48 already use Poppler as the structural proof lane and explicitly separate it from viewer behavior. [VERIFIED: codebase grep] |
| `priv/support_matrix.json` | repo HEAD on 2026-05-06 | Versioned machine-readable support contract. [VERIFIED: codebase grep] | Phase 47 established it as the canonical machine-readable contract surface; Phase 50 should extend, not replace, that artifact. [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `guides/api_stability.md` | repo HEAD on 2026-05-06 | Single human-facing support-boundary guide. [VERIFIED: codebase grep] | Update whenever `priv/support_matrix.json` support claims change. [VERIFIED: codebase grep] |
| `scripts/verify_docs.exs` | repo HEAD on 2026-05-06 | Canonical batch entrypoint for docs-contract lanes. [VERIFIED: codebase grep] | Add the new artifact-surface claims file here so drift fails in the same place forms drift already fails. [VERIFIED: codebase grep] |
| `50-VALIDATION.md` | new phase artifact | Durable manual viewer-evidence record and source of truth for promotion decisions. [VERIFIED: codebase grep] | Use for structural lane description, fixture command, and viewer checklist tables, mirroring the Phase 47 pattern. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Family-first top-level `embedded_files` and `links` | Generic `"surfaces"` wrapper | The wrapper adds indirection without adding truth; the locked phase context explicitly rejects it, and the current forms contract already proves the flatter family-first shape works. [VERIFIED: codebase grep] |
| Dedicated artifact-surface claims test | Extending `forms_claims_test.exs` again | A new file keeps Phase 50 isolated, reduces merge risk, and prevents one ever-growing support-claims test from mixing unrelated surface semantics. [VERIFIED: codebase grep] |
| Markdown checklist tables in `50-VALIDATION.md` | Screenshot archive or JSON evidence store | Phase 47 already proved that a small audited table is enough for support promotion and avoids a heavier evidence system. [VERIFIED: codebase grep] |
| Per-surface viewer status | One blanket `v1.9` viewer status | Embedded files and links have different behavior sets and different viewer variability, so a shared status would overclaim. [VERIFIED: codebase grep] |

**Installation:**
```bash
# No new Hex dependencies are recommended for Phase 50.
# Existing local dependencies used by the proof plan:
mix deps.get
pdfinfo -v
```

**Version verification:** Local commands report Elixir `1.19.5`, Mix `1.19.5`, Node `v22.14.0`, Git `2.41.0`, and Poppler `pdfinfo version 26.04.0`. `mix.exs` still targets Elixir `~> 1.19` and keeps proof tooling inside the existing project stack. [VERIFIED: local command] [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Existing writer/unit tests + combined artifact fixture
                     |
                     v
              Structural proof lane
       (ExUnit + Poppler representative fixture)
                     |
                     v
     support_matrix.json <-> guides/api_stability.md
                     ^
                     |
          docs-claims ExUnit test + verify_docs.exs
                     |
                     v
          merge-blocking published contract

Separate manual lane:

combined fixture path
        |
        v
 named viewer opens PDF
        |
        +--> embedded files: discover / open-extract / save-extract
        |
        +--> links: external handoff / internal navigation
        |
        v
  record table in 50-VALIDATION.md
        |
        v
 update viewer statuses in matrix + guide wording
```

This split matches Phase 47 exactly in the places that matter: automated structure is merge-blocking, manual viewer evidence is a separate recorded lane, and only the recorded table can justify promotion to `supported`. [VERIFIED: codebase grep]

### Recommended Project Structure
```text
priv/
└── support_matrix.json                      # Extend with embedded_files + links

guides/
└── api_stability.md                         # Canonical artifact support wording

scripts/
└── verify_docs.exs                          # Add Phase 50 docs-claims lane

test/
├── docs_contract/embedded_artifact_claims_test.exs
├── rendro/adapters/poppler_test.exs         # Add representative artifact fixture proof
└── support/artifact_support_fixture.ex      # New combined embedded-files + links fixture module

.planning/phases/50-support-boundary-and-proof-closure/
├── 50-RESEARCH.md
└── 50-VALIDATION.md                         # Structural lane + manual evidence tables
```

### Pattern 1: Family-First Nested Support Matrix
**What:** Extend `priv/support_matrix.json` with top-level `embedded_files` and `links` families, using simple string statuses for capabilities/targets/behaviors and small viewer objects only where checklist metadata is needed. [VERIFIED: codebase grep]  
**When to use:** Always for support-boundary publication in Rendro; this is the established forms precedent and the locked Phase 50 direction. [VERIFIED: codebase grep]  
**Example:**
```json
{
  "embedded_files": {
    "capabilities": {
      "document_level": "supported"
    },
    "behaviors": {
      "explicit_metadata": "supported",
      "authored_timestamps": "supported",
      "page_attachment_annotations": "unsupported"
    },
    "viewers": {
      "apple_preview": {
        "status": "unverified",
        "proof": ["discoverable", "open_or_extract", "save_or_extract"]
      },
      "adobe_acrobat_reader": {
        "status": "unverified",
        "proof": ["discoverable", "open_or_extract", "save_or_extract"]
      }
    }
  },
  "links": {
    "targets": {
      "external_uri_http_https": "supported",
      "internal_page": "supported",
      "named_destinations": "unsupported"
    },
    "behaviors": {
      "fragment_rectangles": "supported"
    },
    "viewers": {
      "apple_preview": {
        "status": "unverified",
        "proof": ["external_uri_handoff", "internal_page_navigation"]
      },
      "adobe_acrobat_reader": {
        "status": "unverified",
        "proof": ["external_uri_handoff", "internal_page_navigation"]
      }
    }
  }
}
```
This schema keeps supportable authored behavior separate from viewer-specific evidence and preserves the explicit top-level family shape already chosen for forms. [VERIFIED: codebase grep]

### Pattern 2: Four-File Docs-Contract Change Set
**What:** Treat every support-claim edit as one atomic change across `priv/support_matrix.json`, `guides/api_stability.md`, one dedicated claims test, and `scripts/verify_docs.exs`. [VERIFIED: codebase grep]  
**When to use:** For every Phase 50 support-boundary edit, including initial `unverified` publication and later viewer-status promotion. [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: scripts/verify_docs.exs pattern + Phase 47 precedent
lanes = [
  {"README doctest lane", ["test", "test/docs_contract/readme_doctest_test.exs"]},
  {"Integration contract lane", ["test", "test/docs_contract/integrations_contract_test.exs"]},
  {"Integration semantic-claims lane", ["test", "test/docs_contract/integrations_claims_test.exs"]},
  {"Forms semantic-claims lane", ["test", "test/docs_contract/forms_claims_test.exs"]},
  {"Embedded artifact semantic-claims lane",
   ["test", "test/docs_contract/embedded_artifact_claims_test.exs"]}
]
```
The important planning rule is not the exact file name; it is the atomicity of those four surfaces so docs drift cannot survive a green docs gate. [VERIFIED: codebase grep]

### Pattern 3: Combined Structural Fixture, Separate Manual Interpretation
**What:** Generate one representative PDF fixture that contains at least one embedded file, one external `http` or `https` link, and one internal page link, then use that same fixture for both Poppler structural proof and manual viewer checks. [VERIFIED: codebase grep]  
**When to use:** For milestone closure and viewer-proof efficiency; one fixture reduces maintenance and makes the manual lane reproducible. [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: Phase 47 fixture pattern + Phase 48/49 completed surfaces
path = Path.expand("tmp/artifact_support_fixture.pdf")
path = Rendro.Test.ArtifactSupportFixture.write_fixture(path)
IO.puts(path)
```
One fixture is enough because Phase 48 and 49 already proved their writer seams independently; Phase 50 only needs an integrated witness plus contract closure. [VERIFIED: codebase grep]

### Anti-Patterns to Avoid
- **Generic compatibility database:** The support matrix is a versioned contract artifact, not a browser-compat product. [VERIFIED: codebase grep]
- **Blanket viewer status across surfaces:** A viewer can be supported for forms and still unverified for embedded files or links. [VERIFIED: codebase grep]
- **Guide-only edits:** Changing `guides/api_stability.md` without the matrix, claims test, and docs gate update recreates the exact drift risk Phase 47 closed. [VERIFIED: codebase grep]
- **Calling embedded files “attachments” in headings or support claims:** The repo already uses attachment terminology for delivery adapters, and the milestone context flags this as a product-level confusion risk. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Support publication | New schema framework or statement-object DSL | Extend `priv/support_matrix.json` directly | The current nested JSON contract is already versioned, tested, and understood by the repo. [VERIFIED: codebase grep] |
| Docs drift prevention | Ad hoc grep scripts or manual review | Dedicated ExUnit claims test + `scripts/verify_docs.exs` | Phase 47 already established this lane and proved it catches wording/schema drift together. [VERIFIED: codebase grep] |
| Viewer evidence storage | Screenshot archive, binary artifact bundle, or custom JSON store | Small checklist tables in `50-VALIDATION.md` | The phase only needs durable justification for support claims, not a media archive. [VERIFIED: codebase grep] |
| Cross-viewer automation | UI automation harness for Preview/Acrobat | Manual checklist against a reproducible fixture | The viewer lane is intentionally small and human-audited; automating OS viewers adds complexity without changing product semantics. [VERIFIED: codebase grep] |

**Key insight:** Phase 50 is contract closure, not feature expansion. New infrastructure will create more long-term maintenance than value; the cheapest durable solution is to extend the existing matrix, docs gate, fixture pattern, and validation artifact model. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Conflating structure with support
**What goes wrong:** A green Poppler run gets translated into “viewer support” for embedded files or links. [VERIFIED: codebase grep]  
**Why it happens:** Structural validity is automated and easy to observe, while viewer behavior is manual and slower. [VERIFIED: codebase grep]  
**How to avoid:** Keep structural assertions in ExUnit/Poppler and keep viewer status promotion gated by the checklist tables in `50-VALIDATION.md`. [VERIFIED: codebase grep]  
**Warning signs:** Guide wording says “supported” but the matrix or validation table still says `unverified`. [VERIFIED: codebase grep]

### Pitfall 2: Growing the matrix into a product taxonomy
**What goes wrong:** The support matrix accretes generic wrappers, metadata objects, or many speculative viewer entries. [VERIFIED: codebase grep]  
**Why it happens:** Contract artifacts tend to drift toward “future-proofing” instead of current truth. [VERIFIED: codebase grep]  
**How to avoid:** Add only the families and leaves Phase 50 actually needs: `embedded_files.capabilities|behaviors|viewers` and `links.targets|behaviors|viewers`. [VERIFIED: codebase grep]  
**Warning signs:** New keys describe unimplemented behavior, speculative PDF features, or matrix-only concepts with no matching doc sentence. [VERIFIED: codebase grep]

### Pitfall 3: Mixing support semantics across surfaces
**What goes wrong:** A viewer’s status for forms leaks into embedded files or links, or both `v1.9` surfaces share one combined viewer row. [VERIFIED: codebase grep]  
**Why it happens:** The same viewer names appear in multiple families, which tempts one shared status. [VERIFIED: codebase grep]  
**How to avoid:** Keep one result per viewer per surface, with different proof arrays and checklist tables. [VERIFIED: codebase grep]  
**Warning signs:** The matrix has one `artifact_viewers` block, or the guide says “Preview supports v1.9 artifacts” without naming the surface. [VERIFIED: codebase grep]

### Pitfall 4: Reopening terminology confusion
**What goes wrong:** Public docs imply that PDF embedded files and delivery/email attachments are the same feature. [VERIFIED: codebase grep]  
**Why it happens:** “Attachment” is natural PDF vocabulary, but Rendro already uses that word elsewhere in adapters. [VERIFIED: codebase grep]  
**How to avoid:** Use “embedded files” as the public term and add one explicit sentence distinguishing PDF-internal embedded files from delivery attachments. [VERIFIED: codebase grep]  
**Warning signs:** New docs use “attachments” without the word “delivery” or “embedded” nearby. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from existing repo and official adjacent-library docs:

### Support-Matrix Viewer Object Shape
```json
{
  "apple_preview": {
    "status": "unverified",
    "proof": ["discoverable", "open_or_extract", "save_or_extract"]
  }
}
```
Source: current `forms.viewers.*` pattern in `priv/support_matrix.json`, extended with Phase 50’s per-surface proof names. [VERIFIED: codebase grep]

### Manual Proof Record Shape
```markdown
| Viewer | Version | OS | Fixture | Date | Discoverable | Open/extract | Save/extract | Result | Notes |
|--------|---------|----|---------|------|--------------|--------------|--------------|--------|-------|
| Apple Preview | 16.0 | macOS 26.4.1 | tmp/artifact_support_fixture.pdf | 2026-05-06 | pass | pass | pass | supported | — |
```
Source: Phase 47 manual-proof table shape plus Phase 50 locked evidence fields. [VERIFIED: codebase grep]

### Adjacent-Library Lesson That Sharpens Rendro’s Decision
```text
HexaPDF keeps document-level embedded files in the document catalog /EmbeddedFiles name tree
and models Link annotations separately with rectangle + Dest/A semantics.
```
Source: HexaPDF official docs for `Document::Files`, `Type::EmbeddedFile`, and `Annotations::Link`. [CITED: https://hexapdf.gettalong.org/documentation/api/HexaPDF/Document/Files.html] [CITED: https://hexapdf.gettalong.org/documentation/api/HexaPDF/Type/EmbeddedFile/index.html] [CITED: https://hexapdf.gettalong.org/documentation/api/HexaPDF/Type/Annotations/Link.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Forms-only nested support contract | Family-first contract with `forms`, `embedded_files`, and `links` | Phase 50 target for `v1.9` closure | Keeps the contract explicit as Rendro adds surfaces without falling back to a generic wrapper. [VERIFIED: codebase grep] |
| Structural proof treated as the only durable artifact | Structural proof plus a separate manual viewer-evidence record | Phase 47 precedent, reused in Phase 50 | Allows truthful support promotion without pretending viewer behavior is automated. [VERIFIED: codebase grep] |
| Link semantics hidden inline in some adjacent libraries | Rendro explicit authored links plus narrow proof-backed docs | Prawn still documents inline text `:link`, `:anchor`, and `:local` options | Reinforces Rendro’s choice to keep links explicit and avoid local-file or broad action semantics in the public contract. [CITED: https://prawnpdf.org/docs/prawn/2.5.0/Prawn/Document.html] |

**Deprecated/outdated:**
- Broad “standard viewer” or milestone-wide viewer claims: rejected by Phase 47 and incompatible with Phase 50’s per-surface proof requirement. [VERIFIED: codebase grep]
- A top-level `"surfaces"` wrapper: explicitly deferred and unnecessary for the current contract size. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| None | All material factual claims in this research were verified from the codebase, local environment, or cited official docs. | — | — |

## Open Questions

1. **Which viewers can actually be promoted in this phase?**
   - What we know: Preview.app is present on this machine, Acrobat Reader was not found in `/Applications`, and the Phase 50 context allows leaving viewers `unverified` unless committed proof exists. [VERIFIED: local command] [VERIFIED: codebase grep]
   - What's unclear: Whether the maintainer’s real proof environment includes Acrobat Reader or any other viewer worth checking for embedded files and links. [VERIFIED: local command]
   - Recommendation: Plan for manual evidence as optional promotion work, not a blocker; if Acrobat proof cannot be run, keep Acrobat `unverified` for both new families and ship the truthful narrower contract. [VERIFIED: codebase grep]

2. **Should one combined fixture be the only manual artifact?**
   - What we know: Phase 47 used a single representative forms fixture, and Phases 48 and 49 already proved their seams independently in unit tests. [VERIFIED: codebase grep]
   - What's unclear: Whether one combined PDF is enough to make manual embedded-file discoverability and link navigation checks comfortable in all targeted viewers. [VERIFIED: codebase grep]
   - Recommendation: Default to one combined fixture for low maintenance; split into two viewer fixtures only if a specific viewer’s UI makes one surface materially harder to verify in the combined document. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | ExUnit tests, fixture generators, docs-contract lanes | ✓ | 1.19.5 | — |
| Mix | `mix test`, `mix run scripts/verify_docs.exs` | ✓ | 1.19.5 | — |
| `pdfinfo` / Poppler | Structural proof lane | ✓ | 26.04.0 | If missing in another environment, keep graceful skip behavior already used by Poppler tests. [VERIFIED: codebase grep] |
| Preview.app | Manual macOS viewer proof | ✓ | app present; version manual | If not used, leave Preview `unverified`. [VERIFIED: local command] |
| Adobe Acrobat Reader | Manual viewer proof | ✗ on this machine | — | Leave Acrobat `unverified`; do not block structural/docs closure. [VERIFIED: local command] |

**Missing dependencies with no fallback:**
- None for structural/docs closure. [VERIFIED: codebase grep]

**Missing dependencies with fallback:**
- Acrobat Reader for manual viewer promotion on this machine; the fallback is truthful `unverified` status. [VERIFIED: local command] [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5. [VERIFIED: codebase grep] [VERIFIED: local command] |
| Config file | `test/test_helper.exs`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/rendro/adapters/poppler_test.exs test/docs_contract/forms_claims_test.exs test/docs_contract/embedded_artifact_claims_test.exs && mix run scripts/verify_docs.exs`. [VERIFIED: codebase grep] |
| Full suite command | `mix test`. [VERIFIED: codebase grep] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TRUST-01 | Matrix schema, guide wording, and docs gate stay in sync for embedded files and links. [VERIFIED: codebase grep] | docs contract | `mix test test/docs_contract/embedded_artifact_claims_test.exs && mix run scripts/verify_docs.exs` | ❌ Wave 0 |
| TRUST-02 | Structural proof remains separate from viewer claims, and representative artifact output validates through Poppler when available. [VERIFIED: codebase grep] | unit + integration | `mix test test/rendro/adapters/poppler_test.exs` | ✅ |

### Sampling Rate
- **Per task commit:** run the narrowest touched command from the requirement map. [VERIFIED: codebase grep]
- **Per wave merge:** run the full quick command once. [VERIFIED: codebase grep]
- **Phase gate:** `mix test` plus a completed or explicitly unverified viewer table before `/gsd-verify-work`. [VERIFIED: codebase grep]

### Wave 0 Gaps
- [ ] `test/docs_contract/embedded_artifact_claims_test.exs` — lock `embedded_files` and `links` schema plus guide wording for `TRUST-01`. [VERIFIED: codebase grep]
- [ ] `test/support/artifact_support_fixture.ex` — reusable combined fixture generator for structural and manual proof. [VERIFIED: codebase grep]
- [ ] `50-VALIDATION.md` — structural lane command, fixture command, and manual viewer tables. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 50 is docs/support closure, not auth. [VERIFIED: codebase grep] |
| V3 Session Management | no | Phase 50 does not introduce session state. [VERIFIED: codebase grep] |
| V4 Access Control | no | Viewer proof does not change access-control behavior. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Keep published claims aligned with Phase 48/49 validation boundaries; do not imply support for rejected URI schemes or page attachment annotations. [VERIFIED: codebase grep] |
| V6 Cryptography | no | Encryption and signatures remain deferred beyond `v1.9`. [VERIFIED: codebase grep] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Publishing support claims broader than recorded proof | Repudiation | Claims test + support matrix + guide wording must move together in the same change set. [VERIFIED: codebase grep] |
| Viewer support implied from structural validity alone | Tampering | Keep Poppler and manual viewer evidence in separate documented lanes. [VERIFIED: codebase grep] |
| Reintroducing unsupported link or attachment semantics in docs | Information Disclosure | Explicitly state `http`/`https` and internal page links only; explicitly state no page attachment annotations. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- Local codebase artifacts:
  - `.planning/phases/50-support-boundary-and-proof-closure/50-CONTEXT.md` - locked decisions and discretionary bounds. [VERIFIED: codebase grep]
  - `.planning/phases/47-form-validation-and-viewer-proof-closure/47-VALIDATION.md` - prior split between structural proof and manual viewer evidence. [VERIFIED: codebase grep]
  - `.planning/phases/47-form-validation-and-viewer-proof-closure/47-03-SUMMARY.md` - precedent for promoting only supported viewers backed by recorded proof. [VERIFIED: codebase grep]
  - `.planning/phases/48-embedded-file-core-surface/48-VALIDATION.md` and `48-VERIFICATION.md` - structural-only embedded-file closure. [VERIFIED: codebase grep]
  - `.planning/phases/49-curated-link-annotation-surface/49-VALIDATION.md` and `49-03-SUMMARY.md` - structural-only links closure and writer proof scope. [VERIFIED: codebase grep]
  - `priv/support_matrix.json`, `guides/api_stability.md`, `scripts/verify_docs.exs`, `test/docs_contract/forms_claims_test.exs`, `mix.exs` - current live contract surfaces and tooling. [VERIFIED: codebase grep]
- Local environment commands:
  - `elixir -e 'IO.puts(System.version())'`
  - `mix run -e 'IO.puts(System.version())'`
  - `pdfinfo -v`
  - `sw_vers -productVersion`
  - filesystem checks for `Preview.app` and Acrobat Reader. [VERIFIED: local command]

### Secondary (MEDIUM confidence)
- HexaPDF official docs:
  - https://hexapdf.gettalong.org/documentation/api/HexaPDF/Document/Files.html
  - https://hexapdf.gettalong.org/documentation/api/HexaPDF/Type/EmbeddedFile/index.html
  - https://hexapdf.gettalong.org/documentation/api/HexaPDF/Type/Annotations/Link.html
  These sharpen the decision to keep document-level embedded files and link annotations as separate support families. [CITED: https://hexapdf.gettalong.org/documentation/api/HexaPDF/Document/Files.html] [CITED: https://hexapdf.gettalong.org/documentation/api/HexaPDF/Type/EmbeddedFile/index.html] [CITED: https://hexapdf.gettalong.org/documentation/api/HexaPDF/Type/Annotations/Link.html]
- Prawn official docs:
  - https://prawnpdf.org/docs/prawn/2.5.0/Prawn/Document.html
  This sharpens the decision to avoid inline or broader link semantics in Rendro’s support contract. [CITED: https://prawnpdf.org/docs/prawn/2.5.0/Prawn/Document.html]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommended surfaces already exist in the repo or were verified in the local environment. [VERIFIED: codebase grep] [VERIFIED: local command]
- Architecture: HIGH - the recommendation reuses Phase 47’s proven two-lane closure model and keeps Phase 48/49 proof seams intact. [VERIFIED: codebase grep]
- Pitfalls: HIGH - each pitfall comes directly from current milestone constraints, existing docs-contract patterns, or already-observed terminology/viewer-boundary risks. [VERIFIED: codebase grep]

**Research date:** 2026-05-06  
**Valid until:** 2026-06-05 for repo-local contract/planning guidance; viewer availability should be rechecked at execution time. [VERIFIED: local command] [VERIFIED: codebase grep]
