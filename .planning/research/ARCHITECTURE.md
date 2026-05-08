# Project Research — Architecture for v2.3 Viewer Proof & Interop Closure

**Domain:** Recorded per-viewer evidence, support-matrix promotion, and docs-contract enforcement for a deterministic PDF library that has shipped through v2.2.
**Researched:** 2026-05-08
**Confidence:** HIGH (every recommendation maps to an existing, code-resident pattern in the v1.5/v1.8/v1.9/v1.10/v2.0/v2.1/v2.2 stack and was verified against the current `priv/support_matrix.json`, `guides/api_stability.md`, `test/docs_contract/*.exs`, and `scripts/verify_docs.exs` files in the repo on the research date).

## Executive Summary

The v2.3 milestone does not need new pipeline machinery, new `Rendro.*` runtime modules, or a new CI lane. It needs a **disciplined, file-system-first contract** that mirrors the same pattern Rendro already uses for `priv/support_matrix.json` + `guides/api_stability.md` + `test/docs_contract/*_claims_test.exs`: one canonical machine-readable artifact, one human-readable mirror, and a docs-contract test that fails when the two drift.

Concretely:

- **Recorded evidence lives at `priv/viewer_evidence/<surface>/<viewer>.md`**, one file per (surface × viewer) cell, with YAML frontmatter (machine-readable: viewer name, viewer version, OS, fixture path, date checked, per-behavior pass/fail) and a Markdown body (human-readable checklist narrative). This matches the "one cell, one document" pattern Rendro already uses for `.planning/phases/<n>-VERIFICATION.md` records.
- **Promotion in `priv/support_matrix.json` becomes additive**: a viewer row that is `"status": "supported"` MUST also carry `"evidence": "priv/viewer_evidence/<surface>/<viewer>.md"`; an explicit-deferral row carries `"evidence_deferred": "<short prose reason>"` instead. Existing readers (the `mix test` lanes for v1.5/v1.8/v1.9/v1.10/v2.0/v2.1/v2.2) only read the keys they already check; new keys are ignored by old assertions and validated by new ones.
- **No new runtime module is needed.** A read-only `Rendro.Support.ViewerEvidence` loader is over-engineering for v2.3 because nothing inside the running library reads viewer evidence at runtime — it is a build-time and audit-time contract. The minimum surface is a tiny `Mix.Tasks.Rendro.ViewerEvidence` task that wraps file-system convention with three sub-commands (`list`, `validate`, `missing`). This task is the operator's entry point and the test seam.
- **The docs-contract test extension is one new file**: `test/docs_contract/viewer_evidence_claims_test.exs`. It (a) parses every viewer row in `priv/support_matrix.json`, (b) asserts that `status: "supported"` rows have an `evidence:` pointer to a file that exists and parses, (c) asserts `evidence_deferred` rows carry no broken pointer, and (d) asserts every recorded evidence file is referenced by exactly one row in the matrix (no orphan evidence). It plugs into `scripts/verify_docs.exs` as the eighth lane.
- **No new required CI lane.** Viewer-evidence schema validation is a deterministic, no-external-tools check, so it correctly belongs **inside the existing test job** (which already runs the docs-contract lanes through `scripts/verify_docs.exs`). A separate `viewer-evidence-schema` lane would suggest the check needs an external runtime — it does not. The "engine-level proof is automated; per-viewer evidence is recorded manual proof" framing is preserved precisely because the **evidence files are recorded by hand**, but the **schema around the evidence is validated by the existing automated lane**.
- **The operator-grade recipe path is `guides/viewer_evidence.md`**, listed under `groups_for_extras: [Policies: ...]` next to `guides/api_stability.md`. Operators discover it through HexDocs and through the existing `mix help` surface for the new task. `priv/viewer_evidence/README.md` is rejected because Rendro's pattern keeps `priv/` machine-readable and `guides/` human-readable.
- **Build order across 5 phases (68–72)**: schema + module + test (Phase 68, prerequisite) → recipe + first cell to prove the recipe works end-to-end (Phase 69) → record remaining shipped surfaces (Phases 70–71, executable in parallel waves) → matrix promotion + ship (Phase 72). The first phase is the only blocker for everything else; the recording phases are mostly independent.

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                       Existing Rendro architecture (unchanged)                │
├──────────────────────────────────────────────────────────────────────────────┤
│  Core deterministic pipeline:                                                 │
│    build → compose → measure → paginate → render → validate                   │
│  Public boundaries: Rendro.render/2, Rendro.signature_field/2,                │
│    Rendro.form_field/3, Rendro.Sign.{prepare,sign,augment,validate}/2,        │
│    Rendro.Protect, Rendro.Artifact                                            │
│  Optional adapters: Rendro.Adapters.{Poppler, PyHanko, Pdfsig, Qpdf, ...}     │
└────────────────────────────────────┬─────────────────────────────────────────┘
                                     │ (Rendro engine produces artifacts;
                                     │  v2.3 records what humans saw in viewers)
┌────────────────────────────────────┴─────────────────────────────────────────┐
│                v2.3 viewer-evidence contract (additive layer)                 │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│   ┌──────────────────────────────┐      ┌─────────────────────────────────┐   │
│   │ priv/viewer_evidence/        │      │ priv/support_matrix.json        │   │
│   │   <surface>/                 │◄─────┤   <surface>.viewers.<viewer>:   │   │
│   │     <viewer>.md              │  ref │     status: supported           │   │
│   │     (YAML frontmatter +      │      │     evidence: priv/viewer_      │   │
│   │      Markdown checklist)     │      │       evidence/<s>/<v>.md       │   │
│   └──────────────┬───────────────┘      └────────────────┬────────────────┘   │
│                  │                                       │                     │
│                  │   read by                             │   read by           │
│                  ▼                                       ▼                     │
│   ┌─────────────────────────────────────────────────────────────────────┐    │
│   │ test/docs_contract/viewer_evidence_claims_test.exs (NEW)             │    │
│   │   - rejects supported rows missing evidence pointer                  │    │
│   │   - rejects evidence pointers to nonexistent files                   │    │
│   │   - rejects orphan evidence files (no row references them)           │    │
│   │   - accepts evidence_deferred prose as a valid non-promotion         │    │
│   │   - asserts guides/viewer_evidence.md exists and lists the recipe    │    │
│   │   - asserts guides/api_stability.md prose matches promoted rows      │    │
│   └─────────────────────────────────────────────────────────────────────┘    │
│                  │                                                            │
│                  │   wired into                                               │
│                  ▼                                                            │
│   ┌─────────────────────────────────────────────────────────────────────┐    │
│   │ scripts/verify_docs.exs  (existing — adds one lane entry)            │    │
│   │ guides/viewer_evidence.md  (NEW — operator-grade recipe)             │    │
│   │ Mix.Tasks.Rendro.ViewerEvidence  (NEW — list/validate/missing)       │    │
│   │ guides/api_stability.md  (extended — viewer-evidence wording)        │    │
│   └─────────────────────────────────────────────────────────────────────┘    │
│                                                                                │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Status (new vs modified) |
|-----------|----------------|--------------------------|
| `priv/viewer_evidence/<surface>/<viewer>.md` | Canonical recorded evidence per (surface × viewer) cell. YAML frontmatter is machine-readable, Markdown body is human-readable. **One file per cell, no exceptions.** | NEW directory and files |
| `priv/support_matrix.json` (existing) | Canonical machine-readable support contract. v2.3 adds an `evidence:` key to promoted viewer rows and `evidence_deferred:` prose to known-not-supported rows. | MODIFIED (additive only — no key removed, no key renamed, no nesting changed) |
| `guides/api_stability.md` (existing) | Human-readable mirror of `priv/support_matrix.json`. v2.3 extends it with per-promoted-row prose and a pointer to the recipe. | MODIFIED |
| `guides/viewer_evidence.md` | Operator-grade recipe explaining how to record evidence for a new (surface × viewer) cell. Single canonical entry point. | NEW |
| `Mix.Tasks.Rendro.ViewerEvidence` | Tooling task with three sub-commands: `list` (every cell with status), `validate` (parse all evidence files; non-zero exit on schema violations), `missing` (every shipped surface × every named viewer for which evidence is not yet recorded). | NEW (single small task module) |
| `test/docs_contract/viewer_evidence_claims_test.exs` | The docs-contract test that enforces the additive contract above. Runs in the existing `mix test` job and through `scripts/verify_docs.exs`. | NEW test file |
| `scripts/verify_docs.exs` (existing) | Aggregator script that runs every docs-contract lane. v2.3 adds one line. | MODIFIED (one-line addition) |
| `mix.exs` (existing) | v2.3 adds `guides/viewer_evidence.md` to the `extras:` list and the `groups_for_extras: [Policies: ...]` group. | MODIFIED (two-line addition) |
| `Rendro.Support.ViewerEvidence` runtime module | Read-only loader at runtime. **Rejected for v2.3** — nothing inside the running library reads viewer evidence at runtime; the contract is build-time and audit-time only. | NOT BUILT |
| New CI lane (`viewer-evidence-schema`) | Separate required job for evidence schema validation. **Rejected for v2.3** — the check has no external-tool runtime and folds correctly into the existing `test` job through the docs-contract lane. | NOT BUILT |

## Recommended Project Structure

```
priv/
├── support_matrix.json                  # existing — extended additively
├── support/                             # existing — unchanged
│   └── pyhanko_validate.py
└── viewer_evidence/                     # NEW directory (one file per cell)
    ├── forms/
    │   ├── adobe_acrobat_reader.md      # NEW
    │   ├── apple_preview.md             # NEW (consolidates v1.8 Phase 47 record)
    │   ├── chrome_pdfium.md             # NEW (or absent if deferred)
    │   └── pdfjs.md                     # NEW (or absent if deferred)
    ├── signature_widget/
    │   ├── adobe_acrobat_reader.md
    │   └── apple_preview.md
    ├── signing_preparation/
    │   ├── adobe_acrobat_reader.md
    │   └── apple_preview.md
    ├── signed_artifact/
    │   ├── adobe_acrobat_reader.md
    │   └── apple_preview.md
    ├── long_lived_signed_artifact/
    │   ├── adobe_acrobat_reader.md
    │   └── apple_preview.md
    ├── embedded_files/
    │   └── adobe_acrobat_reader.md      # NEW (consolidates v1.9 Phase 50 record)
    ├── links/
    │   ├── adobe_acrobat_reader.md      # NEW (consolidates v1.9 Phase 50 record)
    │   └── apple_preview.md             # NEW (consolidates v1.9 Phase 50 record)
    └── protection/
        └── apple_preview.md             # NEW (consolidates v1.10 Phase 54 record)

guides/
├── api_stability.md                     # existing — extended with v2.3 wording
├── branding.md                          # existing — unchanged
├── integrations.md                      # existing — unchanged
└── viewer_evidence.md                   # NEW — single operator-grade recipe entry point

lib/mix/tasks/
└── rendro/
    └── viewer_evidence.ex               # NEW — Mix.Tasks.Rendro.ViewerEvidence

test/docs_contract/
├── embedded_artifact_claims_test.exs    # existing — unchanged
├── forms_claims_test.exs                # existing — unchanged
├── integrations_claims_test.exs         # existing — unchanged
├── integrations_contract_test.exs       # existing — unchanged
├── protection_claims_test.exs           # existing — unchanged
├── readme_doctest_test.exs              # existing — unchanged
├── signing_claims_test.exs              # existing — unchanged
└── viewer_evidence_claims_test.exs      # NEW — eighth lane

scripts/
└── verify_docs.exs                      # existing — adds one lane entry

mix.exs                                  # existing — adds guide entry to extras
```

### Structure Rationale

- **`priv/viewer_evidence/<surface>/<viewer>.md` (one file per cell)** — Mirrors the existing pattern where `priv/` holds canonical machine-readable contracts (`support_matrix.json`, `support/pyhanko_validate.py`). The single-file-per-cell rule means evidence is independently referenceable from `priv/support_matrix.json` (one row → one path), independently auditable in `git log` (one cell's history is one file's history), and independently deferrable (a viewer that does not implement signature validation has no file at all and gets `evidence_deferred:` in the matrix). One big `priv/viewer_evidence.md` would force every promotion to touch one document and would obscure per-cell history. Per-milestone `.planning/phases/<n>-VIEWER-EVIDENCE.md` is rejected because per-milestone phases are archived after a milestone ships, and v2.3 records evidence that must outlive any single phase.
- **`guides/viewer_evidence.md` (one canonical recipe entry point)** — Mirrors `guides/api_stability.md` and `guides/integrations.md`. Lives in the `mix.exs` `extras:` list, ships in HexDocs under the existing `Policies` group, and is the URL operators see when they ask "how do I add evidence for a new cell?". `priv/viewer_evidence/README.md` is rejected because `priv/` is the machine-readable contract directory and operator-facing prose belongs in `guides/`. `mix help rendro.viewer_evidence` is good and should exist as the **second** entry point (the task module's `@moduledoc`), but the canonical operator path stays the published guide.
- **`Mix.Tasks.Rendro.ViewerEvidence` lives in `lib/mix/tasks/rendro/`** — The conventional Elixir location for `mix` tasks. Keeps the `Rendro.*` runtime namespace free of build-time concerns. The task is a thin wrapper over the file system; it intentionally has no public Elixir API and is not part of the public contract.
- **`test/docs_contract/viewer_evidence_claims_test.exs`** — Sits alongside the existing six docs-contract tests. The naming convention is established (`<family>_claims_test.exs`); the new file does not break the pattern.

## Architectural Patterns

### Pattern 1: One Canonical Machine-Readable Contract + One Human-Readable Mirror + One Docs-Contract Test

**What:** The shipped pattern that v2.3 must extend (not invent). Rendro already runs this for forms, signing, embedded artifacts, and protection.

**When to use:** Every public claim that can drift between `priv/`, `guides/`, and `test/`.

**Trade-offs:** Pro — single source of truth; every claim is enforceable in CI. Con — three files must be edited together, but that is exactly the point: the docs-contract test refuses to let them drift.

**Example (the pattern v2.3 inherits, from the existing `protection_claims_test.exs`):**

```elixir
# docs-contract:viewer_evidence_promotion_v2_3
test "support matrix promotes viewer rows only when evidence file exists" do
  matrix = "priv/support_matrix.json" |> File.read!() |> Jason.decode!()

  for {family, family_data} <- matrix,
      is_map(family_data),
      Map.has_key?(family_data, "viewers"),
      {viewer, viewer_data} <- family_data["viewers"],
      is_map(viewer_data) do
    case viewer_data["status"] do
      "supported" ->
        assert pointer = viewer_data["evidence"],
               "#{family}.#{viewer} is `supported` but has no `evidence:` pointer"
        assert File.exists?(pointer),
               "#{family}.#{viewer} `evidence:` points to missing file: #{pointer}"
        assert pointer == "priv/viewer_evidence/#{family}/#{viewer}.md",
               "#{family}.#{viewer} `evidence:` must use the canonical path"

      "unverified" ->
        # Either no evidence (expected) OR explicit deferral prose.
        cond do
          Map.has_key?(viewer_data, "evidence_deferred") ->
            assert is_binary(viewer_data["evidence_deferred"])
            refute Map.has_key?(viewer_data, "evidence"),
                   "#{family}.#{viewer} cannot be both deferred and promoted"

          true ->
            refute Map.has_key?(viewer_data, "evidence"),
                   "#{family}.#{viewer} is `unverified` but carries an `evidence:` pointer"
        end
    end
  end
end
```

This is shape-faithful to the existing tests (`File.read!("priv/support_matrix.json")`, regex/JSON checks, refute-broad-language patterns).

### Pattern 2: First-Party Optional Adapter (NOT Used Here — Reference Only)

**What:** `Rendro.Adapters.Poppler`, `Rendro.Adapters.PyHanko`, `Rendro.Adapters.Pdfsig`, `Rendro.Adapters.Qpdf` — runtime-optional executable wrappers that the engine calls but does not depend on at compile time.

**When NOT to use it (this milestone):** v2.3 records what humans saw in viewers; there is no executable adapter for "Apple Preview opened the PDF and a human ticked five checkboxes." Forcing a `Rendro.Adapters.ViewerEvidence` on this surface would invent a runtime that does not exist and would imply automated viewer testing — which the milestone explicitly defers.

**Why mention it:** The architecture rejects this pattern deliberately, and the rejection is the architectural decision.

### Pattern 3: Frontmatter-First Recorded Artifact

**What:** Every recorded artifact uses YAML frontmatter for machine-readable facts and Markdown body for human-readable prose. Rendro already uses this in `.planning/milestones/v*-MILESTONE-AUDIT.md`, `.planning/phases/*VALIDATION.md`, and `.planning/STATE.md`.

**When to use:** Recorded evidence files where both a tool (test, audit script, mix task) and a human reader need the same information.

**Trade-offs:** Pro — one file serves both audiences; tooling stays simple. Con — YAML/Markdown parsing must be consistent (this is solved by reusing one parser in the new mix task and the new docs-contract test).

**Example shape for `priv/viewer_evidence/protection/apple_preview.md` (consolidates v1.10 Phase 54 evidence into the canonical home):**

```markdown
---
surface: protection
viewer: apple_preview
viewer_version: "11.0"
os: "macOS 26.4.1"
fixture: scripts/protected_viewer_proof_fixture.exs
date_checked: 2026-05-06
recorded_in_phase: 54
status: supported
checks:
  opens_with_open_password: pass
  displays_authored_content_correctly: pass
  advisory_print_behavior: pass
  advisory_copy_behavior: pass
  save_and_reopen_readability: pass
---

# Apple Preview × protection (recorded 2026-05-06)

Recorded against the Phase 54 protected fixture (`scripts/protected_viewer_proof_fixture.exs`)
on macOS 26.4.1, Apple Preview 11.0.

## Checklist

- [x] **opens_with_open_password** — Preview prompted for the open password and unlocked the document.
- [x] **displays_authored_content_correctly** — All authored text, table cells, and embedded image rendered as in the unprotected reference fixture.
- [x] **advisory_print_behavior** — Preview honored the advisory print flag for this fixture (note: advisory only, not enforcement).
- [x] **advisory_copy_behavior** — Preview honored the advisory copy flag for this fixture (note: advisory only, not enforcement).
- [x] **save_and_reopen_readability** — Re-saving via Preview kept the artifact openable with the same open password.

## Boundary notes

This evidence does not promote any other surface or any other viewer. It does
not prove signer trust, tamper evidence, or PDF/A compliance. The advisory
permission checks are recorded as honor-system observations, not enforcement.
```

### Pattern 4: Schema Validation Folded Into Existing `mix test` Lane (NOT a New CI Lane)

**What:** The existing `mix test` lane in `.github/workflows/ci.yml` already runs every docs-contract lane through `scripts/verify_docs.exs`. v2.3 adds one line to that script. The check stays inside the `test` job because it has no external-tool runtime.

**When to use:** Whenever the new check is a deterministic, in-Elixir validation of a recorded artifact.

**Trade-offs:** Pro — the gate is already required on `main` via the `test` job; nothing else needs to be added to branch protection. Con — none. (A separate `viewer-evidence-schema` lane would be theatre.)

**Example (the one-line edit to `scripts/verify_docs.exs`):**

```elixir
lanes = [
  {"README doctest lane", ["test", "test/docs_contract/readme_doctest_test.exs"]},
  {"Integration contract lane", ["test", "test/docs_contract/integrations_contract_test.exs"]},
  {"Integration semantic-claims lane", ["test", "test/docs_contract/integrations_claims_test.exs"]},
  {"Forms semantic-claims lane", ["test", "test/docs_contract/forms_claims_test.exs"]},
  {"Signing semantic-claims lane", ["test", "test/docs_contract/signing_claims_test.exs"]},
  {"Embedded artifact semantic-claims lane", ["test", "test/docs_contract/embedded_artifact_claims_test.exs"]},
  {"Protection semantic-claims lane", ["test", "test/docs_contract/protection_claims_test.exs"]},
  # NEW lane (v2.3):
  {"Viewer evidence semantic-claims lane", ["test", "test/docs_contract/viewer_evidence_claims_test.exs"]}
]
```

## Data Flow

### Authoring Flow (Operator Records New Evidence)

```
[Operator opens guides/viewer_evidence.md]
        ↓
[Operator runs: mix rendro.viewer_evidence missing]
        ↓
[Task lists every shipped surface × every named viewer with no recorded evidence]
        ↓
[Operator picks a (surface × viewer) cell to record]
        ↓
[Operator opens the named PDF fixture in the viewer, walks the checklist]
        ↓
[Operator writes priv/viewer_evidence/<surface>/<viewer>.md (frontmatter + body)]
        ↓
[Operator runs: mix rendro.viewer_evidence validate]
        ↓
[Task confirms frontmatter parses and every recorded check has pass/fail]
        ↓
[Operator updates priv/support_matrix.json:
   - status: "supported"
   - evidence: "priv/viewer_evidence/<surface>/<viewer>.md"]
        ↓
[Operator updates guides/api_stability.md prose]
        ↓
[mix test runs the docs-contract lane → passes only if all three are consistent]
        ↓
[PR opens; CI runs; main is protected by the test job]
```

### Validation Flow (CI)

```
[git push → GitHub Actions]
        ↓
[mix ci → mix test]
        ↓
[scripts/verify_docs.exs runs eight lanes]
        ↓
[viewer_evidence_claims_test.exs reads priv/support_matrix.json]
        ↓
[For every viewer row:
   - "supported" → assert evidence file exists at canonical path
   - "supported" → assert evidence frontmatter matches checklist in body
   - "unverified" + evidence_deferred → assert deferred prose is non-empty
   - "unverified" + no evidence_deferred → assert no evidence: pointer
   - every priv/viewer_evidence/**/*.md → assert one matrix row references it]
        ↓
[Pass or fail — main branch protection enforces]
```

### Deferral Flow (When a Viewer Cannot Be Promoted)

```
[Operator inspects the surface in the viewer]
        ↓
[Viewer fundamentally does not implement the surface — e.g., Apple Preview does
 not validate cryptographic signatures, so signed_artifact × apple_preview cannot
 record a meaningful pass/fail checklist]
        ↓
[Operator does NOT create priv/viewer_evidence/<surface>/<viewer>.md]
        ↓
[Operator updates priv/support_matrix.json:
   - status: "unverified"
   - evidence_deferred: "Apple Preview does not implement signature validation;
                         see guides/api_stability.md for the deferred boundary."]
        ↓
[Operator updates guides/api_stability.md to name the deferral]
        ↓
[Docs-contract test passes: explicit deferral is a valid non-promotion]
```

### Key Data Flows

1. **Recording flow:** Human-driven. Operator produces a single Markdown file at the canonical path; mix task validates schema; matrix row is updated to point at it.
2. **Promotion flow:** Strictly additive over `priv/support_matrix.json`. A row's `status:` flips from `unverified` → `supported` only when the `evidence:` pointer is added in the same commit.
3. **Deferral flow:** A row's `status:` stays `unverified` and gains `evidence_deferred:` prose. Used when a viewer cannot be checked because the viewer itself does not implement the surface.
4. **Audit flow:** `mix rendro.viewer_evidence list` is operator-grade reporting. It walks both the matrix and the evidence directory and prints a table: `surface × viewer → status, evidence path, last recorded date`. This is also what the milestone-close audit will use.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 5 cells (today: forms × Apple Preview, embedded_files × Acrobat, links × Acrobat, links × Apple Preview, protection × Apple Preview) | File-system convention is plenty. No tooling needed beyond the validate task. |
| 30 cells (v2.3 closeout target: ~6 surfaces × ~4–5 viewers, where a meaningful subset are recorded and the rest are explicit deferrals) | Still file-system + mix task. The `missing` sub-command becomes the primary operator interface. |
| 100+ cells (hypothetical, if v2.4+ adds new viewers or new surfaces) | Consider extracting `Rendro.Support.ViewerEvidence` as a real module to avoid duplicated parsing across the mix task and the docs-contract test. **Do not pre-build this for v2.3** — wait until duplication actually appears. |

### Scaling Priorities

1. **First bottleneck (v2.3 itself):** Hand-recording evidence for every shipped surface × every named viewer. Mitigation: do not try to record every cell; explicit-defer the cells that cannot be meaningfully recorded (e.g., signed_artifact × apple_preview, since Preview does not validate signatures). The deferral path is a first-class status, not a fallback.
2. **Second bottleneck (post-v2.3):** Schema drift between mix-task validation and docs-contract validation. Mitigation: write the parser once, in plain Elixir (`File.read!/1` + a minimal frontmatter splitter), and call it from both. If duplication grows, promote it to `lib/rendro/support/viewer_evidence.ex` later — but not now.

## Anti-Patterns

### Anti-Pattern 1: New `Rendro.Support.ViewerEvidence` Runtime Module Before It Is Needed

**What people do:** Add `lib/rendro/support/viewer_evidence.ex` as a public read-only loader on day one because "the architecture should have a module."

**Why it's wrong:** Nothing inside the running library reads viewer evidence at runtime. Adding a public module commits Rendro to a stable API for a build-time-and-audit-time concern. It also widens the `Rendro.*` namespace into operational tooling, which the existing pattern (mix tasks live under `Mix.Tasks.Rendro.*`, runtime concerns live under `Rendro.*`) deliberately separates.

**Do this instead:** Keep all of v2.3's logic inside `Mix.Tasks.Rendro.ViewerEvidence` and `test/docs_contract/viewer_evidence_claims_test.exs`. If duplication grows in a later milestone, extract to a private module then. The architecture is "minimum surface that closes the gap."

### Anti-Pattern 2: Embedding Evidence Directly Inside `priv/support_matrix.json`

**What people do:** Inline the entire checklist (date, OS, version, every check, prose) into each viewer row, turning `priv/support_matrix.json` into a 2,000-line evidence ledger.

**Why it's wrong:** Breaks the "machine-readable contract is short and stable; human-readable mirror is long and prose" separation that already governs `priv/support_matrix.json` + `guides/api_stability.md`. Diffs become unreviewable. The existing v1.5/v1.8/v1.9/v1.10/v2.0/v2.1/v2.2 readers (regex matchers in `*_claims_test.exs`) start matching against prose they never expected.

**Do this instead:** Keep `priv/support_matrix.json` short. Promoted rows carry a single `evidence:` string pointer. The full record lives in the per-cell Markdown file.

### Anti-Pattern 3: A Separate Required CI Lane for Viewer-Evidence Schema

**What people do:** Add a `viewer-evidence-schema` job to `.github/workflows/ci.yml` that runs `mix test test/docs_contract/viewer_evidence_claims_test.exs` and require it on `main`.

**Why it's wrong:** The existing required `test` job already runs the file. Adding a second job duplicates compilation, doubles CI minutes, and (worst) implies that viewer-evidence schema is somehow a different category of proof from the other docs-contract lanes. It is not. Engine-level proof (long-lived-live-proof, structural validation) needs a separate lane because it has external-tool runtimes; viewer-evidence schema is in-Elixir and folds into `test`.

**Do this instead:** Add the new test file. Add the new line to `scripts/verify_docs.exs`. The `test` job is already required on `main`. Ship.

### Anti-Pattern 4: Promoting a Viewer Row Without a Recorded File

**What people do:** Flip `"status": "unverified"` to `"status": "supported"` in `priv/support_matrix.json` based on a Slack message or a phase summary.

**Why it's wrong:** Breaks the v1.9 / v1.10 precedent that promotion requires a recorded checklist. The whole point of v2.3 is to make this impossible to do silently.

**Do this instead:** The new docs-contract test refuses any `"supported"` viewer row that does not also carry an `evidence:` key pointing to a file at `priv/viewer_evidence/<surface>/<viewer>.md`. The test fails the build. Ergo, promotion-without-file becomes a syntactic impossibility.

### Anti-Pattern 5: Implicit Deferral

**What people do:** Leave a viewer row at `"status": "unverified"` with no further information, hoping readers will infer that the viewer was checked-and-found-wanting.

**Why it's wrong:** The matrix cannot distinguish "we have not yet checked this cell" from "this cell cannot be checked because the viewer does not implement the surface." Both look like `unverified`. That ambiguity is exactly what the milestone is closing.

**Do this instead:** Use `evidence_deferred:` prose for known-not-supported cells. Leave bare `unverified` only for cells that still need recording. The mix task's `missing` sub-command lists bare `unverified` cells; explicit-deferred cells are filtered out because they are intentionally non-promotions.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Adobe Acrobat Reader, Apple Preview, Chrome PDFium, PDF.js | Human walks the recorded checklist; no automated integration | Viewer integration is intentionally manual. Automated viewer testing is **out of scope** for v2.3 and arguably forever — see Anti-Pattern 2 in `PITFALLS.md`. |
| `pdfinfo`, `pdfsig`, `pyhanko`, `qpdf` | Already integrated through existing `Rendro.Adapters.*` | v2.3 changes nothing about adapter integration. Structural proof and viewer proof remain explicitly separate evidence lanes. |
| `certomancer` | Already integrated via the `long-lived-live-proof` CI fixture | v2.3 changes nothing here either. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `priv/support_matrix.json` ↔ `priv/viewer_evidence/*.md` | One-way reference: matrix row → evidence file path | Enforced by `viewer_evidence_claims_test.exs`. Orphan evidence files (no row references them) and dangling pointers (row references missing file) both fail. |
| `priv/viewer_evidence/*.md` ↔ `guides/api_stability.md` | Mirror: every promoted row mentioned in prose | Enforced by extending the existing `*_claims_test.exs` pattern (each family's claims test gains a "promotion mentions evidence" assertion). |
| `Mix.Tasks.Rendro.ViewerEvidence` ↔ `priv/viewer_evidence/` | Read-only file system walk | Task does not write evidence files. Operator writes them by hand; task only reports and validates. |
| `test/docs_contract/viewer_evidence_claims_test.exs` ↔ `priv/support_matrix.json` and `priv/viewer_evidence/` | Read-only file system + JSON parse | Single test file consolidates all schema invariants. No new test runtime. |
| `scripts/verify_docs.exs` ↔ new test file | One-line aggregator entry | Inherits the existing `mix shell` exit-code pattern. |
| `mix.exs` `extras:` ↔ `guides/viewer_evidence.md` | HexDocs publishing | New guide ships in the `Policies` group alongside `guides/api_stability.md`. |
| Existing `*_claims_test.exs` files (forms, signing, embedded, protection) | **Unchanged for v2.3** | Each existing claims test continues to enforce its family's narrow regex assertions. The new viewer-evidence test enforces the cross-family schema invariants. **Do not merge concerns.** |

## Suggested Build Order (5 Phases, 68–72)

The build order is dictated by hard dependencies: the schema must exist before any cell can be recorded; cells must be recorded before any matrix row can be promoted; and the recipe must be ready before broad recording starts (otherwise the first three cells set the canonical pattern by accident).

### Phase 68 — Viewer Evidence Schema, Task, and Docs-Contract Lane (PREREQUISITE)

**Status:** prerequisite for all subsequent phases.

**Scope:**
- Create `priv/viewer_evidence/` directory (empty, with a `.gitkeep`).
- Add `Mix.Tasks.Rendro.ViewerEvidence` with `list`, `validate`, `missing` sub-commands.
- Add `test/docs_contract/viewer_evidence_claims_test.exs` with the schema invariants (see Pattern 1 example).
- Add the lane to `scripts/verify_docs.exs`.
- Document evidence schema (frontmatter keys, body checklist convention) in the moduledoc of the new mix task.

**Done means:**
- `mix rendro.viewer_evidence validate` runs against an empty directory and passes.
- `mix rendro.viewer_evidence missing` lists every shipped (surface × viewer) pair with no recorded evidence.
- `mix test test/docs_contract/viewer_evidence_claims_test.exs` passes against the unchanged `priv/support_matrix.json` (because no row currently claims `evidence:`, so no constraint is violated).

**Why first:** Nothing else can be recorded until the schema and the validator exist. Recording first and validating later is the exact failure mode v2.3 is designed to prevent.

### Phase 69 — Operator Recipe + First Cell End-to-End

**Status:** depends on Phase 68. Sets the recording pattern that Phases 70–71 follow.

**Scope:**
- Add `guides/viewer_evidence.md` with the operator-grade recipe.
- Add it to `mix.exs` `extras:` and `groups_for_extras: [Policies: ...]`.
- Record exactly one cell **completely** end-to-end as the canonical example. Recommended cell: **forms × Apple Preview**, because the v1.8 Phase 47 record already exists and consolidating it into `priv/viewer_evidence/forms/apple_preview.md` proves the schema is faithful to existing recorded evidence without inventing new viewer testing.
- Promote that one row in `priv/support_matrix.json` (add `evidence:` pointer).
- Update `guides/api_stability.md` prose if needed to mention the canonical evidence path.

**Done means:**
- One full cycle has been walked: human checklist → frontmatter file → matrix promotion → docs-contract test passes.
- The recipe in `guides/viewer_evidence.md` references the just-created file as its worked example.
- A second person could follow the recipe to record a second cell without asking questions.

**Why second:** The first cell is the recipe's smoke test. If the schema or the recipe is wrong, this is when it surfaces — before five more cells get recorded against a broken pattern.

### Phase 70 — Record Already-Validated Surfaces (Wave 1)

**Status:** depends on Phase 69. Independent of Phase 71 and can run in parallel.

**Scope:** Consolidate already-recorded evidence from prior milestones into the canonical home.
- `priv/viewer_evidence/embedded_files/adobe_acrobat_reader.md` (from v1.9 Phase 50)
- `priv/viewer_evidence/links/adobe_acrobat_reader.md` (from v1.9 Phase 50)
- `priv/viewer_evidence/links/apple_preview.md` (from v1.9 Phase 50)
- `priv/viewer_evidence/protection/apple_preview.md` (from v1.10 Phase 54)
- Promote each corresponding row in `priv/support_matrix.json`.
- Update `guides/api_stability.md` prose to point at evidence files for already-promoted rows.

**Done means:** Every viewer row that was already `"status": "supported"` before v2.3 now also carries an `evidence:` pointer. **No regression in published support.**

**Why third:** This phase only consolidates existing evidence. It does not require operator manual checking. It is the lowest-risk phase and proves the schema accepts every shape of evidence the project has previously recorded.

### Phase 71 — Record New Trust-Sensitive Surfaces and Explicit Deferrals (Wave 2)

**Status:** depends on Phase 69. Can run in parallel with Phase 70 (different files, no merge conflicts).

**Scope:** Walk each remaining (surface × viewer) cell and record either evidence or explicit deferral.
- `signature_widget × {acrobat, apple_preview, chrome_pdfium, pdfjs}` — record where viewer renders the unsigned widget; explicit-defer where the viewer offers no UI for unsigned signature placeholders.
- `signing_preparation × {acrobat, apple_preview, chrome_pdfium, pdfjs}` — record artifact-open behavior for prepared-but-unsigned outputs; explicit-defer where the surface is meaningless from a viewer perspective.
- `signed_artifact × {acrobat, apple_preview, chrome_pdfium, pdfjs}` — record signature-presence and signature-validity UI in viewers that implement signature validation; explicit-defer Apple Preview (does not validate signatures), explicit-defer PDFium/PDF.js per their actual behavior.
- `long_lived_signed_artifact × {acrobat, apple_preview, chrome_pdfium, pdfjs}` — record timestamp/revocation surface in viewers that surface them; explicit-defer the rest.
- `forms × {acrobat, chrome_pdfium, pdfjs}` — record the four-check forms checklist in each, or explicit-defer.
- `embedded_files × apple_preview` — record open/extract behavior or explicit-defer per the v1.9 outcome (Preview did not surface the embedded file in its UI — this is a candidate for `evidence_deferred:` if the viewer behavior has not changed).
- `protection × adobe_acrobat_reader` — record the five-check protection checklist, or explicit-defer.

**Done means:** Every (shipped-surface × named-viewer) cell in `priv/support_matrix.json` carries either:
1. `"status": "supported"` + `evidence:` pointer to a recorded file, OR
2. `"status": "unverified"` + `evidence_deferred:` prose explaining why no checklist exists, OR
3. (rare) bare `"status": "unverified"` for cells that are intentionally still pending future work — should be the empty set at v2.3 close.

**Why fourth:** This is the bulk of the milestone's manual labor. It is gated by Phase 69 because the recipe must be in place; it is parallel with Phase 70 because the files are disjoint.

### Phase 72 — Closure: Matrix Audit, Guide Polish, and Ship

**Status:** depends on Phases 70 and 71.

**Scope:**
- Run `mix rendro.viewer_evidence list` and confirm every cell is in one of the three states above.
- Run `mix rendro.viewer_evidence missing` and confirm the output is empty (or expected-empty).
- Polish `guides/api_stability.md` so the prose for every family mentions the canonical evidence pointers and the deferral language.
- Polish `guides/viewer_evidence.md` so the worked example is current and the explicit-deferral language is documented.
- Update `priv/support_matrix.json` once more if any row state changed during polish.
- Run `mix verify` and `mix test`.
- Generate `72-VERIFICATION.md` (the standard milestone-close artifact) recording the final cell-by-cell ledger.
- Tag and ship.

**Done means:** The milestone ships. Every viewer claim in Rendro's published support contract is either backed by a file or explicitly deferred with prose. The recipe is published. The mix task is documented. No silent `unverified` rows remain.

**Why last:** Closure phases historically carry milestone-readiness gates (changelog, version bump, retrospective, audit). v2.3 follows the same pattern.

### Dependency Graph

```
Phase 68 (schema/task/test)  ─────► Phase 69 (recipe + first cell)
                                          │
                                          ├────► Phase 70 (consolidate already-validated)
                                          │              │
                                          │              ├────► Phase 72 (closure & ship)
                                          │              │
                                          └────► Phase 71 (record new + defer rest)
                                                         │
                                                         └────────────────┘
```

Phase 68 is the only blocker. Phase 69 is the recipe smoke test. Phases 70 and 71 are independent and can be done in parallel waves. Phase 72 is the standard milestone-close ritual.

## Sources

- `/Users/jon/projects/rendro/priv/support_matrix.json` (verified 2026-05-08) — canonical machine-readable contract; the additive shape recommendation is checked against the live file.
- `/Users/jon/projects/rendro/guides/api_stability.md` (verified 2026-05-08) — human-readable mirror; the per-family prose pattern is the model for v2.3's extension.
- `/Users/jon/projects/rendro/test/docs_contract/protection_claims_test.exs` (verified 2026-05-08) — direct precedent for the new `viewer_evidence_claims_test.exs`. The new test is shape-faithful to this one.
- `/Users/jon/projects/rendro/test/docs_contract/embedded_artifact_claims_test.exs` (verified 2026-05-08) — second precedent; demonstrates the per-surface, per-viewer regex pattern v2.3 inherits.
- `/Users/jon/projects/rendro/scripts/verify_docs.exs` (verified 2026-05-08) — aggregator that gains a single new lane entry.
- `/Users/jon/projects/rendro/.github/workflows/ci.yml` (verified 2026-05-08) — confirms the `test` job is required on `main` and already runs `mix ci`, which already runs the docs-contract lanes; therefore no new CI lane is needed.
- `/Users/jon/projects/rendro/lib/rendro/adapters/poppler.ex` (verified 2026-05-08) — pattern reference for first-party-optional adapters; the v2.3 architecture **rejects** this pattern for viewer evidence and the source confirms why the pattern exists (executable runtime wrappers, not human checklist recording).
- `/Users/jon/projects/rendro/lib/rendro/sign.ex` (verified 2026-05-08) — pattern reference for narrow public boundaries; the v2.3 architecture **does not extend** this pattern.
- `/Users/jon/projects/rendro/mix.exs` (verified 2026-05-08) — confirms `extras:` and `groups_for_extras: [Policies: ...]` is the canonical surface for new policy guides.
- `/Users/jon/projects/rendro/.planning/PROJECT.md` (verified 2026-05-08) — milestone scope, constraints, key decisions for v2.3.
- `/Users/jon/projects/rendro/.planning/MILESTONE-ARC.md` (verified 2026-05-08) — confirms v2.3 is "viewer proof & interop closure," not a new feature family.
- `/Users/jon/projects/rendro/.planning/milestones/v1.10-MILESTONE-AUDIT.md` (verified 2026-05-08) — confirms the prior precedent that "viewer rows remain `unverified` until recorded evidence exists; structural validation alone is not viewer proof."
- `/Users/jon/projects/rendro/.planning/milestones/v1.9-MILESTONE-AUDIT.md` (verified 2026-05-08) — confirms the recorded-checklist promotion pattern that v2.3 generalizes into a permanent contract.
- `/Users/jon/projects/rendro/scripts/protected_viewer_proof_fixture.exs` (verified 2026-05-08) — existing pattern for fixture scripts; the recipe in `guides/viewer_evidence.md` will reference fixture scripts like this one for each surface.

---
*Architecture research for: v2.3 Viewer Proof & Interop Closure*
*Researched: 2026-05-08*
