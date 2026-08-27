# Phase 132: Quality Baseline & Triage - Research

**Researched:** 2026-08-26
**Domain:** Repository-native quality evidence, ledger governance, and deterministic Elixir/Mix verification
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Ledger Form and Audience
- **D-01:** Use one human-first, repository-native `.planning/QUALITY.md` as the canonical current finding ledger. It must be concise, Git-reviewable, usable offline, and independent of archived phase artifacts.
- **D-02:** Organize the ledger around the compatibility contract, baseline registry/reference, disposition rules, active findings, resolved/rejected findings, deferred triggers, and a baseline-versus-final section populated in Phase 137.
- **D-03:** The ledger serves maintainers, reviewers, contributors, and downstream planning agents. Product code, package contents, release workflows, and ordinary regression tests must not consume it as executable state.
- **D-04:** Do not introduce Ecto, a hosted dashboard, GitHub Issues, or generated machine data as the canonical ledger. Structured companion evidence is appropriate only where machine validation adds value.

### Finding Identity and History
- **D-05:** Give every finding a permanent, opaque, sequential ID such as `QL-001`. Never encode severity, area, owner phase, or filename in the ID; never renumber or reuse IDs.
- **D-06:** Deduplicate by underlying cause plus compatibility/ownership boundary. Multiple tools, files, or symptoms become evidence on one finding when they share that boundary; keep separate findings when ownership, blast radius, remediation, or verification differs.
- **D-07:** Use the lifecycle `observed -> triaged`, then `accepted -> in_progress -> verified -> closed`, with explicit `rejected`, `deferred`, `accepted_risk`, and `superseded` branches where applicable.
- **D-08:** Preserve resolved, rejected, deferred, reopened, related, and superseded relationships. Rely on Git for line-level history while retaining the finding's opened date, meaningful state changes, disposition, closing evidence, and resolution reference in the ledger.
- **D-09:** Reopen an existing ID only when new evidence invalidates its prior disposition. Create a new related ID for a distinct regression or recurrence.

### Baseline Evidence
- **D-10:** Use two evidence layers: commit normalized, schema-valid, redacted baseline snapshots and keep large raw logs/binaries as bounded, hash-bound CI artifacts. `QUALITY.md` links the durable normalized snapshot and its raw evidence references.
- **D-11:** Each normalized evidence item records a stable item ID, schema version, exact source SHA, UTC capture time, clean/dirty worktree state, OS and toolchain identities, dependency-lock identity where relevant, renderer identity where relevant, registered command, evidence lane, normalized result, `passed | failed | unavailable` status, unavailability reason, raw-output SHA-256/byte count/location/expiry, and redaction classification.
- **D-12:** Register and reuse the existing project contracts rather than inventing parallel commands: `mix ci.fast`, `mix ci.proofs`, `mix ci.advisory`, xref stats and compile-connected diagnostics, coverage/slow-test diagnostics, `mix hex.build`, and the existing public API/catalog contracts.
- **D-13:** Preserve deterministic, proof, advisory, and human-review authority boundaries. Unavailable advisory evidence remains explicitly unavailable and cannot be coerced to zero, failure, or success. Local reproduction is valid evidence; the pinned primary CI environment remains authoritative for CI-only evidence.
- **D-14:** Keep the initial Phase 132 baseline immutable. Phase 137 adds a final snapshot and before/after comparison rather than overwriting the starting evidence. Do not commit raw generated logs, PDFs, PNGs, or reports merely for offline completeness, and never use caches as evidence.

### Risk and Disposition Governance
- **D-15:** Use an evidence-gated qualitative rubric, not a calculated composite score. Record `impact`, `confidence`, `compatibility risk`, `evidence quality`, optional likelihood where meaningful, and a justified qualitative priority as independent fields.
- **D-16:** Use `low | medium | high` for impact and confidence. Use `none | bounded_internal | public_api | rendered_bytes | evidence_authority` for compatibility risk. Use `signal | reproducible | contract_backed | independently_reviewed` for evidence quality.
- **D-17:** High priority means a credible threat to a supported contract, rendered-byte guarantee, security boundary, release/package correctness, CI authority, or truthful evidence. Medium means demonstrated bounded maintenance/test/docs/workflow cost without a current public-contract break. Low/signal means an observation or preference without demonstrated harm.
- **D-18:** Allowed dispositions are `repair`, `defer`, `reject_signal`, rare time-bounded `accept_risk`, and `superseded`. A signal alone cannot justify a repair.
- **D-19:** High findings must be repaired or rejected with evidence before Phase 137. Medium findings receive a bounded repair or a concrete trigger-backed deferral. Low/style signals do not create standalone churn and may only be addressed incidentally inside an already-justified change.
- **D-20:** A repair requires an owner phase, scope boundary, focused verification, relevant full gate, before/after statement, and resolution reference. A deferral requires a concrete event trigger, evidence-refresh rule, and owner. `reject_signal` records why evidence is insufficient and what would reopen it. `accept_risk` requires compensating evidence/control, an owner, and an expiry or review event.
- **D-21:** Labels, severity changes, improved diagnostic counts, or unrelated green tests cannot close a finding. Closure requires the predeclared proof and compatibility evidence.
- **D-22:** Owner routing follows the roadmap: Phase 133 owns repository/evidence hygiene, Phase 134 architecture/readability, Phase 135 tests and CI authority, Phase 136 the six catalog cells, and Phase 137 final evidence reconciliation. Phase 132 owns classification.

### Maintainer Experience
- **D-23:** Optimize the ledger for the maintainer JTBD: reproduce the baseline, understand why a finding matters, see the evidence boundary, and know exactly what action or proof closes it.
- **D-24:** Use plain domain language: `baseline`, `evidence item`, `finding`, `disposition`, `owner phase`, `verification`, `trigger`, and `closure`. Follow Rendro's current voice: lead with concrete facts, state limits beside claims, explain failures with next actions, and avoid opaque scores, hype, or enterprise ceremony.

### the agent's Discretion
- Choose the exact companion snapshot directory, schema filenames, and repository-owned validation mechanism while preserving the human-first canonical ledger and archive-independent evidence contract.
- Choose the precise Markdown table/layout and whether long evidence references use footnotes or compact linked subsections, provided ordinary Git diffs remain scannable.
- Choose focused contract-test mechanics for IDs, required fields, transitions, and evidence references. Do not turn free-form ledger prose into a pseudo-database or add a runtime dependency.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Keep the `rendro` core pure: no hard dependency on Phoenix, Oban, or admin tooling. [VERIFIED: AGENTS.md]
- Preserve deterministic and advisory verification lane separation in CI and documentation. [VERIFIED: AGENTS.md]
- Treat documentation claims as contracts; do not claim unsupported capabilities. [VERIFIED: AGENTS.md]
- Use optional dependency guards for integrations. [VERIFIED: AGENTS.md]
- Preserve the data-first render pipeline and the two-API/one-engine design; this phase must not alter either. [VERIFIED: AGENTS.md]
- File changes are occurring through the GSD planning workflow. [VERIFIED: AGENTS.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUDIT-01 | Reproduce a dated architecture, dependency, test, CI/CD, documentation, packaging, release-evidence, and catalog baseline using existing tooling. | The baseline registry uses the existing aliases, Mix xref diagnostics, package build, API manifest, and catalog contracts; every execution is a normalized, SHA-bound evidence item. [VERIFIED: `mix.exs`, repository scan] |
| AUDIT-02 | Maintain one durable current ledger independent of completed phase artifacts. | `.planning/QUALITY.md` is the sole decision ledger; normalized records live in a stable `.planning/quality/` companion directory, not an archived phase directory. [VERIFIED: 132-CONTEXT.md] |
| AUDIT-03 | Record evidence, impact, confidence, compatibility risk, disposition, owner, verification, status, and applicable trigger for every finding. | A schema validates machine facts while focused tests validate ledger headings, permanent IDs, required Markdown fields, lifecycle/disposition vocabulary, and resolvable evidence references. [VERIFIED: existing JSV/schema contract pattern] |
| AUDIT-04 | Repair/reject high risk, bound/defer medium risk, and prevent low-value standalone churn. | The qualitative disposition rubric explicitly routes findings to 133–137 and prohibits a repair without evidence, scope, proof, and compatible full gate. [VERIFIED: 132-CONTEXT.md] |
</phase_requirements>

## Summary

Phase 132 should create a small maintainer control plane, not a quality subsystem. The canonical surface is one concise `.planning/QUALITY.md`; it points to immutable, normalized JSON snapshots and bounded raw CI artifacts. Existing Mix, public-API, catalog, documentation-contract, package, and workflow contracts produce the baseline. [VERIFIED: 132-CONTEXT.md; `mix.exs`; repository scan]

The ledger must separate observations from accepted work. A measured diagnostic is not a remediation mandate: the current compile-connected xref baseline has 135 tracked files, five compile edges, and zero compile-connected cycles, so no architecture repair should be created solely from xref topology. [VERIFIED: local `mix xref graph --format stats --label compile-connected` and `--format cycles --label compile-connected`, 2026-08-26] Conversely, the current archive scan finds active scripts, release workflow, and tests reading Phase 131 milestone artifacts; that is one deduplicated evidence-authority candidate for Phase 133, not three unrelated findings. [VERIFIED: repository scan]

**Primary recommendation:** Create `.planning/QUALITY.md` plus versioned `.planning/quality/` JSON schema/snapshots; validate structural facts with the existing JSV test pattern and validate concise ledger contracts with a dedicated maintenance test, while keeping the regular product/package/release paths independent from the ledger. [VERIFIED: 132-CONTEXT.md; existing `test/docs_contract/rubric_manifest_contract_test.exs`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Human-readable current ledger | Repository documentation | — | Maintainers make qualitative dispositions; it is intentionally not runtime or package state. [VERIFIED: 132-CONTEXT.md] |
| Normalized baseline records and schema | Repository quality-control plane | Test tooling | Machine validation adds value for identity, hashes, lanes, and required fields without replacing ledger judgment. [VERIFIED: 132-CONTEXT.md; existing JSV contracts] |
| Baseline collection | Local/CI tooling | GitHub artifact storage | Existing Mix commands collect local evidence; primary CI is authoritative for CI-only evidence and retains bounded raw output. [VERIFIED: 132-CONTEXT.md; `mix.exs`] |
| Finding triage and routing | Repository documentation | Roadmap/planning | The ledger routes accepted work to phases 133–137; Phase 132 classifies rather than repairs. [VERIFIED: 132-CONTEXT.md] |
| Product rendering and public API | Library core | Catalog evidence | Compatibility is recorded and verified, but this phase does not change the render pipeline or public surface. [VERIFIED: AGENTS.md; ROADMAP.md] |

## Standard Stack

### Core

| Library/tool | Version | Purpose | Why standard |
|--------------|---------|---------|--------------|
| Elixir/Mix | Elixir 1.19.5 / OTP 28 | Existing aliases, xref, test diagnostics, package build, and tooling execution. | The local toolchain matches the locked project stack and CI configuration. [VERIFIED: `elixir --version`; `mix.exs`; `.github/workflows/ci.yml`] |
| ExUnit | bundled with Elixir 1.19.5 | Focused ledger/schema contract tests. | Existing project test framework; no runtime dependency. [VERIFIED: `mix.exs`; repository test scan] |
| JSV | 0.22.0 locked | Validate normalized JSON records against a repository-owned schema. | Existing manifests use `JSON.decode!`, `JSV.build!`, and `JSV.validate/2` in isolated contract tests. [VERIFIED: `mix.lock`; `test/docs_contract/rubric_manifest_contract_test.exs`] |

### Supporting

| Tool | Current command or location | Purpose | When to use |
|------|-----------------------------|---------|-------------|
| Deterministic lane | `mix ci.fast` | Format, package build, compile, regular tests with slowest diagnostics, docs, Credo, and Dialyzer. | Record one evidence item for required committed-state quality. [VERIFIED: `mix.exs`] |
| Proof lane | `mix ci.proofs` | Live viewer/signing and release-preflight proof. | Record explicit proof outcomes; local evidence is useful, while primary CI owns CI-only authority. [VERIFIED: `mix.exs`; 132-CONTEXT.md] |
| Advisory lane | `mix ci.advisory` | Raster, launch/comparison/livebook, PDF.js, and dependency audits. | Preserve `unavailable` with a reason and rerun trigger; never convert it to pass/fail by omission. [VERIFIED: `mix.exs`; 132-CONTEXT.md] |
| Dependency-shape diagnostics | `mix xref graph --format stats --label compile-connected` and `--format cycles --label compile-connected` | Locate recompilation topology and cycles. | Treat output as a question generator, then inspect responsibility/change cost before accepting a repair. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Xref.html] |
| Existing quality contracts | `priv/public_api.json`, `priv/quality/rubric_scores.json`, schemas, and tests | Preserve public API and catalog evidence contracts. | Register source artifacts and focused verification in the baseline, rather than duplicating their facts. [VERIFIED: repository scan] |

### Alternatives Considered

| Instead of | Could use | Tradeoff |
|------------|-----------|----------|
| Repository Markdown ledger plus normalized companion JSON | Ecto/hosted dashboard/GitHub Issues | Rejected by locked decisions; these add state, access, and archival dependence without helping offline review. [VERIFIED: 132-CONTEXT.md] |
| Existing Mix/JSV contracts | New quality SaaS, runtime library, or calculated debt score | Rejected: no demonstrated coverage gap and a composite score would falsely automate qualitative disposition. [VERIFIED: 132-CONTEXT.md; `.planning/research/STACK.md`] |
| Bounded raw CI artifacts plus committed normalized facts | Commit raw logs, PDFs, PNGs, reports, or caches | Rejected by locked evidence durability and repository-noise constraints. [VERIFIED: 132-CONTEXT.md] |

**Installation:** None. Phase 132 adds no external package. [VERIFIED: 132-CONTEXT.md; `mix.exs`]

## Architecture Patterns

### System Architecture Diagram

```text
existing repository commands and contracts
  ├─ mix ci.fast / ci.proofs / ci.advisory
  ├─ xref + coverage + slow-test diagnostics
  ├─ hex.build + public API + catalog contracts
  └─ workflow/release/docs scans
             |
             v
    normalized baseline snapshot (committed, schema-valid, redacted)
             |                            \
             |                             -> raw CI logs/binaries (hash-bound, expiry recorded)
             v
 .planning/QUALITY.md (human decision surface)
  ├─ compatibility contract + baseline registry
  ├─ active / resolved / rejected findings
  └─ disposition + owner + proof + trigger
             |
             +--> Phase 133: durable evidence hygiene
             +--> Phase 134: architecture/readability, only if accepted
             +--> Phase 135: test/CI authority
             +--> Phase 136: six catalog cells
             \--> Phase 137: final snapshot and reconciliation
```

### Recommended Project Structure

```text
.planning/
├── QUALITY.md                         # canonical human-first current ledger
└── quality/
    ├── schema/
    │   └── baseline-v1.schema.json    # structural contract for normalized facts
    └── baselines/
        └── 132-initial.json           # immutable initial snapshot; Phase 137 adds, never replaces
test/
└── quality/
    └── baseline_ledger_contract_test.exs # focused schema/ledger/reference checks
```

The `.planning/quality/` companion location is preferred over `priv/` because this control-plane evidence must be durable and reviewable but is neither package content nor a public runtime artifact. [VERIFIED: 132-CONTEXT.md; `mix.exs` package/runtime separation]

### Pattern 1: Human decision record + machine-verifiable evidence

**What:** Keep prose dispositions and closure reasoning in `QUALITY.md`; place only repeatable identity/provenance/result fields in versioned JSON.

**When to use:** Every baseline run and every accepted/rejected/deferred finding.

**Example:**

```json
{
  "schema_version": 1,
  "snapshot_id": "baseline-132-initial",
  "source_sha": "<40-lowercase-hex>",
  "captured_at_utc": "2026-08-26T00:00:00Z",
  "worktree": "clean",
  "evidence_items": [
    {
      "id": "EV-ARCH-001",
      "command": "mix xref graph --format stats --label compile-connected",
      "lane": "deterministic",
      "status": "passed",
      "raw_output": {
        "sha256": "<64-lowercase-hex>",
        "bytes": 1234,
        "location": "GitHub Actions artifact/run-…",
        "expires_at": "2026-09-09T00:00:00Z"
      },
      "redaction": "none"
    }
  ]
}
```

The exact schema must additionally require toolchain/OS identity, lock identity when relevant, renderer identity when relevant, normalized result, and an unavailability reason exactly when `status` is `unavailable`. [VERIFIED: 132-CONTEXT.md]

### Pattern 2: Evidence-gated lifecycle and closure

**What:** Create a ledger row only after recording evidence and compatibility boundary; then move through the locked lifecycle without renumbering its ID.

**When to use:** Triage and later closure across Phases 133–137.

```text
observed -> triaged -> accepted -> in_progress -> verified -> closed
                  ├-> rejected (insufficient evidence; reopening condition)
                  ├-> deferred (owner + concrete event trigger + refresh rule)
                  ├-> accepted_risk (owner + control + expiry/review event)
                  └-> superseded (related replacement ID)
```

For a `repair`, require owner phase, scope boundary, focused check, relevant full gate, before/after statement, and resolution reference before closure. [VERIFIED: 132-CONTEXT.md]

### Pattern 3: One cause/boundary, one finding

**What:** Aggregate related source locations and tools into one finding when they share underlying cause, compatibility boundary, owner, and verification; split only when those differ.

**When to use:** Current Phase 131 archive references should become one Phase 133 evidence-authority finding with multiple evidence links, unless the baseline proves a distinct owner or closure path. [VERIFIED: 132-CONTEXT.md; repository scan]

### Anti-Patterns to Avoid

- **Machine-first Markdown database:** Do not encode every field in table syntax or parse the ledger as product state; JSON is only for structural evidence. [VERIFIED: 132-CONTEXT.md]
- **Metric-triggered refactor:** Do not create architecture work from module size, xref counts, coverage, or slow-test output without demonstrated impact and a verification plan. [VERIFIED: `.planning/research/PITFALLS.md`; local xref baseline]
- **Raw artifact commits:** Do not commit generated logs/PDFs/PNGs/reports or treat cache hits as evidence. [VERIFIED: 132-CONTEXT.md]
- **Authority collapse:** Do not mark a locally unavailable advisory command as pass, fail, or zero; record it as unavailable with its rerun trigger. [VERIFIED: 132-CONTEXT.md]
- **Premature architecture finding:** The observed zero compile-connected cycles is a baseline result, not evidence that the internal architecture has no maintainability risk. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Xref.html]

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|-------------|-------------|-----|
| Dependency topology | Custom static dependency analyzer | `mix xref` stats/cycles/trace | Mix already distinguishes compile, export, and runtime edges and provides focused graph queries. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Xref.html] |
| Schema validation | Ad hoc JSON field parser | Existing `JSON` + JSV schema/test pattern | The repository already validates contract manifests and mutation failures this way. [VERIFIED: `test/docs_contract/rubric_manifest_contract_test.exs`] |
| Quality score | Numeric debt/severity calculator | Locked independent impact/confidence/risk/evidence fields and qualitative priority | Composite numbers conceal evidence gaps and conflict with D-15. [VERIFIED: 132-CONTEXT.md] |
| Ledger history | Separate database/history store | Permanent IDs, meaningful state facts, relationships, and Git history | The ledger remains offline, reviewable, and archive-independent. [VERIFIED: 132-CONTEXT.md] |
| CI evidence retention | Repository copies of raw output | Hash-bound GitHub artifacts with expiry plus committed normalized facts | Artifact retention is bounded and configurable; raw output cannot be the durable truth. [CITED: https://docs.github.com/en/enterprise-cloud@latest/actions/tutorials/store-and-share-data] |

**Key insight:** This phase gains reliability by linking existing authoritative contracts into one decision surface; it should not duplicate tool results or create an automated quality judgment engine. [VERIFIED: 132-CONTEXT.md; `.planning/research/STACK.md`]

## Common Pitfalls

### Pitfall 1: Treating a diagnostic as a finding

**What goes wrong:** A xref, coverage, slow-test, file-size, or lint signal is routed as a repair with no demonstrated contract or maintenance harm.

**Why it happens:** Diagnostics are easy to count, while responsibility collisions and behavioral loss require human evidence.

**How to avoid:** Record the diagnostic as evidence, then require impact, compatibility boundary, scope, and proof before `repair`; otherwise use `reject_signal` or a trigger-backed deferral. [VERIFIED: 132-CONTEXT.md; `.planning/research/PITFALLS.md`]

**Warning signs:** The row has no before/after claim, focused check, or reason beyond “consistency.” [VERIFIED: `.planning/research/PITFALLS.md`]

### Pitfall 2: Making archived planning executable again

**What goes wrong:** The new ledger or snapshot points product/release/test behavior at completed phase artifacts.

**Why it happens:** Historical evidence is convenient to reuse.

**How to avoid:** Keep `QUALITY.md` and `.planning/quality/` as current durable control-plane state, and route removal of existing Phase 131 consumers to one Phase 133 finding. [VERIFIED: 132-CONTEXT.md; repository scan]

**Warning signs:** A new command/test/workflow reads `.planning/phases/*` or `.planning/milestones/*` for runtime/release behavior. [VERIFIED: repository scan]

### Pitfall 3: Claiming unavailable advisory evidence is decisive

**What goes wrong:** A missing local renderer is summarized as “no failures,” “zero drift,” or “passed.”

**Why it happens:** A single pass/fail column is convenient but destroys evidence authority.

**How to avoid:** Require `passed | failed | unavailable`, make `unavailability_reason` conditional for the last state, and document primary-CI rerun ownership. [VERIFIED: 132-CONTEXT.md]

**Warning signs:** Empty raw-output references, a cache identifier used as evidence, or missing rerun trigger. [VERIFIED: 132-CONTEXT.md]

### Pitfall 4: Closing by labels or unrelated green gates

**What goes wrong:** A finding is closed after a severity downgrade, generic CI green run, or an unrelated test pass.

**Why it happens:** Closure fields are not predeclared at triage.

**How to avoid:** Validate that each repair records focused verification, full gate, compatibility evidence, before/after result, and resolution reference. [VERIFIED: 132-CONTEXT.md]

**Warning signs:** A `closed` row lacks a closure section or its verification does not address the originally recorded compatibility risk. [VERIFIED: 132-CONTEXT.md]

## Code Examples

Verified repository patterns:

### Schema-backed baseline test

```elixir
defmodule Rendro.Quality.BaselineLedgerContractTest do
  use ExUnit.Case, async: true

  @snapshot_path ".planning/quality/baselines/132-initial.json"
  @schema_path ".planning/quality/schema/baseline-v1.schema.json"

  test "initial snapshot has structurally valid evidence items" do
    schema = @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()
    snapshot = @snapshot_path |> File.read!() |> JSON.decode!()

    assert {:ok, _} = JSV.validate(snapshot, schema)
  end
end
```

This deliberately mirrors existing isolated manifest tests and should be expanded with mutation checks for required evidence/finding fields, fixed enums, SHA formats, conditional unavailable reasons, and reference existence—not a parser for narrative Markdown. [VERIFIED: `test/docs_contract/rubric_manifest_contract_test.exs`; `test/rendro/viewer_evidence/validator_test.exs`]

### Focused architecture baseline commands

```bash
mix xref graph --format stats --label compile-connected
mix xref graph --format cycles --label compile-connected
```

These commands identify compile-connected health; use `mix xref trace` only after a diagnostic identifies a concrete seam worth investigating. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Xref.html]

## State of the Art

| Old approach | Current approach | When changed | Impact |
|--------------|------------------|--------------|--------|
| Phase-specific artifacts and prose as operational evidence | One current ledger plus durable normalized evidence, with archived research remaining reference-only | This milestone, beginning in Phase 132 | Makes later milestone archival safe while preserving factual provenance. [VERIFIED: 132-CONTEXT.md; STATE.md] |
| A single “quality” interpretation | Deterministic, proof, advisory, and human-review lanes with explicit authority | Existing project contract | Prevents local/tool availability from being overstated. [VERIFIED: `mix.exs`; 132-CONTEXT.md] |

**Deprecated/outdated:** Creating a repair solely from a metric or holding raw CI output in Git for convenience is not compatible with the locked phase policy. [VERIFIED: 132-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The proposed `.planning/quality/schema/` and `.planning/quality/baselines/` names are the best discretionary layout. | Architecture Patterns | Low: planner can change names without changing the ledger/evidence contract. |
| A2 | A dedicated `test/quality/baseline_ledger_contract_test.exs` is the best focused validation mechanism. | Recommended Project Structure / Validation | Medium: it must remain a maintenance contract, not product or release executable state. |

## Resolved Questions

1. **Which baseline executions complete locally on the capture SHA, and how are unavailable lanes represented?**
   - What we know: Elixir 1.19.5/OTP 28, Mix, Git, SHA-256 utilities, and jq are available locally. [VERIFIED: local environment probe]
   - Resolution: Execute every locally available registered command on the exact capture SHA. Record unavailable advisory/remote items with their concrete reason and rerun/attachment trigger, then add primary-CI raw-artifact metadata only after the authoritative run. Availability is evidence data, not a prerequisite for truthful classification. [RESOLVED: D-12, D-13]

2. **What invocation boundary keeps the focused ledger contract outside ordinary regression execution?**
   - What we know: D-03 prohibits ordinary regression behavior from consuming the ledger as executable state, while the phase explicitly authorizes focused contract-test mechanics. [VERIFIED: 132-CONTEXT.md]
   - Resolution: Keep it isolated under `test/quality/`, default-exclude its purpose tag, and invoke it only through `mix quality.baseline`; ordinary `mix test` and `mix ci.fast` do not run it. [RESOLVED: D-03]

### Resolution

The focused ledger contract is a purpose-named maintenance lane, not part of the ordinary regression glob. Tag the module `@moduletag :quality_ledger_contract`, add `quality_ledger_contract: true` to the default exclusions in `test/test_helper.exs`, and expose only the explicit alias `mix quality.baseline`, which runs `mix test --include quality_ledger_contract --only quality_ledger_contract test/quality/baseline_ledger_contract_test.exs`. `mix test` and `mix ci.fast` remain separate and must not invoke this alias. Planning verification runs `mix quality.baseline` for ledger/schema claims and `mix ci.fast` separately for ordinary regression claims. [RESOLVED: D-03; revision decision 2026-08-26]

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / OTP | Mix baseline, schema tests, xref | ✓ | Elixir 1.19.5 / OTP 28 | — [VERIFIED: `elixir --version`] |
| Mix | Existing baseline commands | ✓ | Bundled with Elixir 1.19.5 | — [VERIFIED: local environment probe] |
| Git | Exact source SHA and clean/dirty capture | ✓ | 2.41.0 | — [VERIFIED: `git --version`] |
| SHA-256 utility | Raw-output identity | ✓ | `sha256sum` and `shasum` available | Use the present platform utility. [VERIFIED: local environment probe] |
| jq | Existing workflow/catalog metadata inspection | ✓ | 1.7.1 | JSON decoder/JSV in Mix tests. [VERIFIED: `jq --version`] |
| GitHub Actions artifact service | Authoritative CI-only raw evidence | Not locally probeable | — | Record local reproduction as local and attach primary-CI evidence after remote run. [VERIFIED: 132-CONTEXT.md] |
| Pinned PDFium renderer | Raster/catalog advisory evidence | Not established by this probe | — | Mark advisory item unavailable with rerun trigger; do not synthesize a result. [VERIFIED: 132-CONTEXT.md] |

**Missing dependencies with no fallback:** None for creating the ledger/schema and capturing local deterministic evidence. [VERIFIED: local environment probe]

**Missing dependencies with fallback:** Remote CI and PDFium evidence have a truthful `unavailable` state plus a rerun/attachment path; they do not block Phase 132 classification. [VERIFIED: 132-CONTEXT.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit bundled with Elixir 1.19.5. [VERIFIED: `mix.exs`; repository test scan] |
| Config file | `test/test_helper.exs`. [VERIFIED: repository scan] |
| Quick run command | `mix quality.baseline` — purpose-tagged Wave 0 maintenance contract, default-excluded from ordinary test execution. [RESOLVED] |
| Full suite command | `mix ci.fast`; `mix ci.proofs` and `mix ci.advisory` are recorded separately as their locked lanes. [VERIFIED: `mix.exs`; 132-CONTEXT.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test type | Automated command | File exists? |
|--------|----------|-----------|-------------------|-------------|
| AUDIT-01 | Snapshot structurally records all registered baseline domains, command/lane/status/provenance, stable SIG candidates, and unavailable facts. | schema + focused contract | `mix quality.baseline` | ❌ Wave 0 |
| AUDIT-02 | Ledger is current, references durable companion facts, and does not rely on completed phase artifacts for its own references. | static contract | `mix quality.baseline` | ❌ Wave 0 |
| AUDIT-03 | Every discovered SIG is classified exactly once and every finding has ID, evidence, risk/disposition/owner/verification/status fields and applicable trigger; enums and transitions are constrained. | mutation + inverse static contract | `mix quality.baseline` | ❌ Wave 0 |
| AUDIT-04 | Accepted high/medium/low routing and closure/deferral requirements are represented in active findings and explicit non-action classifications. | static contract + review | `mix quality.baseline` plus human review of evidence | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix quality.baseline` once Wave 0 creates the explicit maintenance contract. [RESOLVED]
- **Per wave merge:** run `mix quality.baseline` for maintenance-contract claims and `mix ci.fast` separately for ordinary regression claims; execute/report proof and advisory lanes separately rather than collapsing their authority. [VERIFIED: `mix.exs`; 132-CONTEXT.md]
- **Phase gate:** All registered baseline commands have a normalized result, status, and source identity; high/medium finding dispositions meet D-19/D-20. [VERIFIED: 132-CONTEXT.md]

### Wave 0 Gaps

- [ ] `.planning/QUALITY.md` — canonical ledger with compatibility contract, baseline registry, lifecycle/disposition rules, active/historical/deferred sections, and Phase 137 placeholder.
- [ ] `.planning/quality/schema/baseline-v1.schema.json` — normalized snapshot/evidence-item contract.
- [ ] `.planning/quality/baselines/132-initial.json` — source-SHA-bound initial snapshot with no raw artifact payloads.
- [ ] `test/quality/baseline_ledger_contract_test.exs` — JSV validation plus focused mutation/reference/ledger contract checks.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase 132 has no user authentication surface. [VERIFIED: phase scope] |
| V3 Session Management | No | Phase 132 has no session surface. [VERIFIED: phase scope] |
| V4 Access Control | Yes, CI boundary | Preserve existing read-only evidence authority and do not introduce repo-write/publish behavior. [VERIFIED: 132-CONTEXT.md; `.planning/research/STACK.md`] |
| V5 Input Validation | Yes | JSON schema validates controlled field formats/enums; raw external outputs are hash-bound and redacted before committed normalization. [VERIFIED: 132-CONTEXT.md; existing JSV pattern] |
| V6 Cryptography | Yes, integrity only | Use SHA-256 identities already required for raw output; do not implement cryptography. [VERIFIED: 132-CONTEXT.md] |

### Known Threat Patterns for the quality control plane

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Raw CI artifact or log is modified, expires, or cannot be located | Tampering / Repudiation | Record SHA-256, byte count, location, expiry, source SHA, and redaction classification in committed normalized evidence. [VERIFIED: 132-CONTEXT.md] |
| Advisory/local result is claimed as primary CI proof | Spoofing | Record evidence lane/authority and preserve `unavailable`; attach primary CI artifact only after the pinned run. [VERIFIED: 132-CONTEXT.md] |
| Finding closure hides unsupported risk | Tampering | Require predeclared focused proof, full gate, compatibility evidence, before/after statement, and resolution reference. [VERIFIED: 132-CONTEXT.md] |
| Raw output contains sensitive data | Information disclosure | Redact before commit; keep only bounded artifacts and record redaction class. [VERIFIED: 132-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- [132-CONTEXT.md](/Users/jon/projects/rendro/.planning/phases/132-quality-baseline-triage/132-CONTEXT.md) — locked ledger, lifecycle, evidence, disposition, compatibility, and ownership decisions.
- [mix.exs](/Users/jon/projects/rendro/mix.exs) — registered CI lanes and dev/test-only quality dependencies.
- [Rubric manifest contract test](/Users/jon/projects/rendro/test/docs_contract/rubric_manifest_contract_test.exs) — existing schema, mutation, and identity contract pattern.
- Local 2026-08-26 commands: `elixir --version`, `mix xref graph --format stats --label compile-connected`, `mix xref graph --format cycles --label compile-connected`, archive-reference scan, and tool availability probe.

### Secondary (MEDIUM confidence)

- [Mix xref documentation](https://hexdocs.pm/mix/Mix.Tasks.Xref.html) — graph labels, compile-connected analysis, stats/cycles, and trace use.
- [GitHub artifact retention documentation](https://docs.github.com/en/enterprise-cloud@latest/actions/tutorials/store-and-share-data) — individual artifact retention and repository/organization limit boundary.

### Tertiary (LOW confidence)

- None, except the explicitly logged repository-layout and test-inclusion assumptions.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — all recommended tools are installed/locked repository capabilities; no new package is proposed.
- Architecture: HIGH — the ledger/evidence contract is locked in context and repository seams were inspected.
- Pitfalls: HIGH — archive consumption and lane boundaries are directly observable; official Mix docs support xref interpretation.

**Research date:** 2026-08-26
**Valid until:** 2026-09-25 for stable repository patterns; refresh before changing CI authority or toolchain versions.
