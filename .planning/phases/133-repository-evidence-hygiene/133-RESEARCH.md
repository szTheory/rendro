# Phase 133: Repository & Evidence Hygiene - Research

**Researched:** 2026-08-26  
**Domain:** repository-owned release evidence, archive isolation, package membership, and deterministic maintainer hygiene  
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Replace every active Phase 131 archive read with a repository-owned, version-scoped internal evidence capsule rooted at `evidence/releases/v1.3.4/`. The capsule is excluded from the Hex package and is not runtime application data.
- **D-02:** Make `manifest.json` the capsule's sole durable entry point. It indexes authority-separated records by stable opaque ID, repository-relative path, SHA-256, media type, evidence lane, authority, status, retention policy, and provenance; it does not become a flat copy of every payload fact.
- **D-03:** Separate record responsibilities: `public_prerequisite.json` is the only operational clean-room/release input; `release_identity.json` records sealed candidate/tag/release provenance; `validation.json` carries the durable successful journey identities now asserted from `131-VALIDATION.md`; `journey/index.json` orders attempts; individual structured attempt records and Markdown sidecars preserve evidence and explanation.
- **D-04:** Validate the manifest and authoritative JSON records with existing JSV/repository schema conventions, an explicit JSON Schema draft, `schema_version: 1`, strict record roles, bounded fields, path confinement, and digest verification. Add no Ecto, Phoenix, hosted service, runtime dependency, or parallel quality stack for repository evidence.
- **D-05:** Give scripts and tests one narrow shared loader/validator rather than duplicating hard-coded paths and decoding rules. It must reject traversal, malformed or unknown authority roles, unsupported schema versions, digest mismatch, and release/candidate/tag mismatch before returning operational facts.
- **D-06:** Migrate all active consumers atomically: the clean-room script default, release workflow, clean-room tests, public-release verifier tests, newcomer docs contract, required-checks guardrail, and any verifier candidate-record default or fixture. A focused scan must prove no product, release, workflow, or ordinary regression consumer retains a Phase 131 archive dependency.
- **D-07:** Keep `priv/adoption_evidence/2026-08-21.json` separately governed and package-visible because it supports the public adoption document. Do not add the internal release capsule, journey attempts, schemas, or planning records to that package exception.
- **D-08:** Treat migration as preservation, not re-assertion. Every imported record carries its original source path and digest, source commit where available, separate import time/reason, and sanitized/redaction classification; original observed facts remain distinguishable from migration metadata.
- **D-09:** Preserve all successful, failed, and pre-schema v1.3.4 attempts. Structured JSON is the contract record; Markdown remains a paired explanatory narrative and can never be the only source for a fact used by an active consumer.
- **D-10:** Historical payload bytes, IDs, and meanings are immutable after import. Corrections and changed interpretations append a new record with `supersedes`; they never overwrite or repurpose the original. Manifest/index evolution is append-only for historical entries.
- **D-11:** Keep evidence lanes truthful: schema, digest, path, absence, and package membership are deterministic checks; retained clean-room success is historical advisory evidence; workflow artifacts are expiring transport rather than durable authority; no deterministic test requires live GitHub/Hex access or a retry of an immutable failed attempt.
- **D-12:** Scope the current release advisory job explicitly to v1.3.4 while it consumes a v1.3.4-bound harness and capsule. Do not allow every future `v*.*.*` tag to reuse fixed 1.3.4 facts. A generic future-release evidence framework is deferred rather than smuggled into this migration.
- **D-13:** Do not claim that an embedded digest alone creates independent immutability. Git history, protected branches, and release-tag controls remain the repository authority; the capsule supplies bounded provenance and tamper evidence.
- **D-14:** Move loose tracked Phase 5 and Phase 45 artifacts into their historically correct milestone archives, deriving ownership from archived roadmaps and Git history. Use Git-recognizable moves, update inbound planning references, and leave no redirect stubs or duplicate authoritative copies.
- **D-15:** If an early phase has no provable milestone owner after the historical scan, place it in one explicitly labeled legacy archive with the uncertainty recorded; do not invent provenance or delete unique history merely to make the tree uniform.
- **D-16:** Make the active `.planning/phases/<NN>-<slug>/` shape the sole non-archived phase-artifact form. Completed historical phase material belongs under milestone archives; product and release behavior never consumes either location.
- **D-17:** Establish `scripts/README.md` as the complete tracked-helper inventory. Each retained executable records purpose, stable owner role, supported invocation, inputs/outputs, authority lane, current callers, and a review/removal trigger. Role ownership is preferred over a named individual.
- **D-18:** Retain a helper only when a current workflow, Mix alias/task, documented operator action, or focused test proves its purpose. Remove ownerless or superseded helpers after entry-point/reference checks; do not preserve scripts solely because they once supported a phase.
- **D-19:** Mark planning-aware checks as a narrow `gsd_tooling` class in names, inventory, and policy. These checks may inspect planning because planning structure is their subject; they are not product, release-fact, package, or ordinary-regression consumers.
- **D-20:** Replace the unreferenced broad `scripts/repo_hygiene_check.sh` contract with the single Mix-based hygiene gate unless planning discovers a current documented caller that requires a thin compatibility wrapper. Do not keep two competing canonical hygiene commands.
- **D-21:** Provide one purpose-named deterministic maintainer command, `mix quality.hygiene`, and use that same contract locally, in `ci.fast`, and from the clean release checkout. CI records authoritative execution; local runs provide identical fast feedback.
- **D-22:** Inspect the actual built/unpacked Hex artifact, not only `mix.exs` intent. Compare normalized members with a versioned expected package manifest, report unexpected and missing members, and fail on `.planning`, `evidence`, internal schemas, tests, scripts, CI metadata, caches, editor debris, raw proof artifacts, or internal journey history.
- **D-23:** Model evidence/package eligibility explicitly: runtime/public documentation and intentionally public discovery/adoption assets may ship; durable internal evidence and ephemeral artifacts may not. Package exceptions are narrow, named, owner-bearing, and reviewable rather than broad directory allowlists.
- **D-24:** Validate tracked planning placement with NUL-safe `git ls-files` input. Permit only project-level planning files, the canonical active-phase shape, milestone archives, and explicit GSD-tooling artifacts; fail on loose or misplaced tracked phase material.
- **D-25:** Enforce archive-consumer prohibition across `lib/`, release/proof scripts, workflows, package configuration, and ordinary regression tests. Any GSD-tooling exception must identify its purpose and owner and remain outside product/evidence claims.
- **D-26:** Do not fail merely because unrelated untracked or ignored developer-local files exist. Fail when debris enters the built package, becomes tracked in a forbidden location, or influences an authoritative workflow.
- **D-27:** Make command UX deterministic and accessible: stable ordering; no color-only or emoji-only meaning; concise success output; and failures that state the path, violated rule, why it matters, and the exact next action. Keep backend evidence classifications out of package-consumer and Phoenix-newcomer surfaces.

### the agent's Discretion

- Choose exact internal module/test filenames, schema filenames, manifest formatting, and opaque record-ID spelling while preserving the locked capsule responsibilities, version boundary, authority separation, and stable IDs.
- Choose the narrowest implementation for the shared loader and Mix-based gate using existing dev/test compilation paths and dependencies. Do not widen the public API or runtime package surface.
- Derive the exact Phase 5/45 destination paths from repository history during research/planning and record any genuinely unprovable legacy mapping explicitly.

### Deferred Ideas (OUT OF SCOPE)

- Generalizing the v1.3.4 advisory clean-room job and evidence capsule into a version-agnostic future-release framework — future release-policy work after this bounded migration proves the model.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HYGIENE-01 | Product/release/regression/workflow consumers no longer require archives except explicitly documented planning tooling. | The active-consumer scan identifies the migration sites and a bounded archive-consumer guard. |
| HYGIENE-02 | A versioned, schema-validated durable source contains Phase 131 release and journey facts and serves all consumers. | Capsule record roles, JSV schemas, digest-bound loader, and fixture migration are specified below. |
| HYGIENE-03 | Loose phase files are archived correctly; retained helpers have explicit owners and purposes. | Git history maps Phase 5 to v1.0 and Phase 45 to v1.8; a scripts inventory and retained-caller audit close the rest. |
| HYGIENE-04 | The package excludes internal evidence/debris and automation detects future regressions. | A built-artifact member manifest plus NUL-safe tracked-placement guard is the deterministic enforcement surface. |

## Project Constraints (from AGENTS.md)

- Keep the `rendro` core pure; do not add hard Phoenix, Oban, or admin-tooling dependencies.
- Preserve deterministic and advisory verification-lane separation in CI and documentation.
- Completion coverage must be deterministic, advisory, or explicitly deferred; human feedback cannot block completion.
- Treat documentation claims as contracts; do not claim unsupported capabilities.
- Use optional dependency guards for integrations.
- The project pipeline is `build -> compose -> measure -> paginate -> render -> validate`; two APIs normalize to one render core.

## Summary

Phase 133 is repository-control-plane work, not PDF runtime work. Five active sources consume archived Phase 131 material: the clean-room script default, release workflow, clean-room test, public-release verifier test, and newcomer docs contract; the required-checks guardrail asserts the old workflow path. The Phase 132 ledger classifies this as high-impact `evidence_authority` risk and requires a focused zero-consumer scan plus relevant deterministic/proof gates for closure. [VERIFIED: codebase scan]

Use a version-scoped internal capsule at `evidence/releases/v1.3.4/` with `manifest.json` as the only entry point. Keep JSV schema validation, digest/path checks, and the operational record loader in dev/test-only maintainer code; expose no public API and do not package the capsule. Current `mix.exs` already has an explicit Hex allowlist and JSV as a dev/test dependency, so a `dev/` implementation plus a Mix alias can enforce this without new dependencies or runtime coupling. [VERIFIED: codebase scan]

The existing shell hygiene script is unreferenced and fails merely for an unrelated dirty/untracked worktree, violating D-20 and D-26. Replace it with `mix quality.hygiene`, which builds and inspects the real Hex archive, validates exact normalized membership against a versioned internal expected manifest, checks NUL-safe tracked planning placement, and scans defined operational consumer surfaces for archive reads. [VERIFIED: codebase scan]

**Primary recommendation:** Implement the capsule and one shared maintainer-only loader first; migrate every active Phase 131 consumer atomically; then make `mix quality.hygiene` the single package/placement/archive-consumer gate in local, `ci.fast`, and release-clean-checkout execution. [VERIFIED: codebase scan]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Versioned release-evidence capsule | Repository / maintainer control plane | CI workflow | It is durable source-controlled evidence, not runtime application data. [VERIFIED: codebase scan] |
| Capsule schema, path, digest, and identity checks | Dev/test Elixir tooling | Release/proof scripts | The shared loader provides facts to maintainer scripts and focused tests without expanding `lib/` runtime behavior. [VERIFIED: codebase scan] |
| Clean-room advisory proof | Release workflow | Repository capsule | The workflow transports fresh expiring output while the capsule supplies fixed v1.3.4 prerequisite facts. [VERIFIED: codebase scan] |
| Package-membership enforcement | Mix maintainer command | Hex artifact | `mix hex.build --unpack` is the only authoritative local view of shipped members. [VERIFIED: codebase scan] |
| Planning placement enforcement | Git tracked-file index | `gsd_tooling` | Placement is a planning-structure concern and must not become a product/release input. [VERIFIED: codebase scan] |

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir + Mix | 1.19.5 / OTP 28 | Shared maintainer command and dev/test loader. | Already the project runtime and task mechanism. [VERIFIED: codebase scan] |
| JSV | `~> 0.18`, dev/test only | JSON Schema validation for capsule manifest and authoritative JSON records. | Existing manifests use `JSON.decode!() |> JSV.build!() |> JSV.validate/2`. [VERIFIED: codebase scan] |
| Hex Mix task | installed with current Mix | Build/unpack actual package artifact. | `mix hex.build --unpack` is available and succeeds locally. [VERIFIED: codebase scan] |
| Git | available | NUL-safe tracked planning inventory and Git-recognizable moves. | `git ls-files -z` is the required source of tracked placement truth. [VERIFIED: codebase scan] |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `:crypto` | SHA-256 calculation | Verify every manifest member and imported source digest. [VERIFIED: codebase scan] |
| `JSON` / Jason | Decode JSON evidence and schemas | Decode only after path confinement; feed decoded maps into JSV. [VERIFIED: codebase scan] |
| ExUnit | Contract/negative-path tests | Exercise loader rejections, package diff diagnostics, and consumer-scan exemptions. [VERIFIED: codebase scan] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Dev/test-only loader and alias | Runtime library module | Incorrectly expands the public/runtime package surface for repository evidence. [VERIFIED: codebase scan] |
| JSV schemas | Ad-hoc map checks only | Loses established structural schema convention and makes record-role requirements less reviewable. [VERIFIED: codebase scan] |
| Actual unpacked artifact comparison | `mix.exs` allowlist inspection | Cannot prove the artifact's actual members. [VERIFIED: codebase scan] |

**Installation:** None. Phase 133 uses existing dependencies and installed tooling. [VERIFIED: codebase scan]

## Architecture Patterns

### System Architecture Diagram

```text
Historical Phase 131 sources + journey payloads
                 |
                 | one-time preservation import (source path, digest, commit, redaction)
                 v
evidence/releases/v1.3.4/manifest.json  <-- sole capsule entry point
                 |
       shared loader + JSV schemas + path/digest/identity validation
                 |
       +---------+------------+----------------+
       v                      v                v
clean-room default      release verifier   docs/contract tests
       |                      |                |
       +----------> advisory workflow <--------+
                    (fresh artifact transport, not durable authority)

mix quality.hygiene --> `mix hex.build --unpack` --> normalized package member diff
       |                         |
       v                         +--> reject evidence/.planning/tests/scripts/CI/debris
git ls-files -z --> tracked planning placement policy
operational source scan --> reject archive consumer; allow named gsd_tooling only
```

### Recommended Project Structure

```text
evidence/
└── releases/v1.3.4/                 # internal, excluded from Hex
    ├── manifest.json                 # sole entry point
    ├── public_prerequisite.json      # only operational input
    ├── release_identity.json         # sealed candidate/tag/release history
    ├── validation.json               # durable asserted journey identities
    └── journey/
        ├── index.json                # ordered attempts
        └── <opaque-id>.{json,md}     # structured record plus explanatory sidecar
dev/rendro/repository_evidence.ex     # shared loader/validator, dev/test only
dev/rendro/repository_hygiene.ex      # deterministic command implementation
priv/schemas/release_evidence_*.json  # internal schemas; explicitly excluded from Hex
priv/quality/package-members-v1.json  # versioned expected normalized member manifest; excluded
test/quality/repository_hygiene_test.exs
test/scripts/repository_evidence_test.exs
scripts/README.md
```

### Pattern 1: Fail-closed capsule loader

**What:** One internal module resolves only `manifest.json`, validates it and role-bearing records through JSV, expands each record path against the capsule root, verifies confinement before reading, and verifies each SHA-256 before returning facts. [VERIFIED: codebase scan]

**When to use:** Every active script/test needing v1.3.4 evidence. No consumer may assemble archive/capsule paths or independently decode operational facts. [VERIFIED: codebase scan]

**Example:**

```elixir
# Repository pattern derived from Rendro.PublicApi.Validator. [VERIFIED: codebase scan]
with {:ok, manifest} <- load_and_schema_validate(@manifest_path, @manifest_schema),
     {:ok, record} <- fetch_role(manifest, "public_prerequisite"),
     {:ok, path} <- confined_path(@capsule_root, record["path"]),
     :ok <- verify_sha256(path, record["sha256"]),
     {:ok, payload} <- load_and_schema_validate(path, @prerequisite_schema),
     :ok <- validate_release_binding(payload, manifest) do
  {:ok, payload}
end
```

### Pattern 2: Data inventory, then narrow enforcement

**What:** Keep package eligibility and script ownership as reviewed, versioned repository data; have one deterministic command generate/normalize facts and compare them to that data. [VERIFIED: codebase scan]

**When to use:** Package membership, tracked planning placement, helper inventory, and archive-consumer policies. This avoids broad filesystem cleanliness checks. [VERIFIED: codebase scan]

### Pattern 3: Explicit evidence-lane boundary

**What:** Deterministic checks validate structure, paths, digests, placement, and artifact membership; retained clean-room success remains historical advisory; GitHub workflow artifacts remain expiring transport. [VERIFIED: codebase scan]

**When to use:** Tests and docs must not treat an advisory re-run or live GitHub/Hex probe as a deterministic completion prerequisite. [VERIFIED: codebase scan]

### Anti-Patterns to Avoid

- **Archive path literals in consumers:** reintroduce archived planning as operational state; consume the shared loader instead. [VERIFIED: codebase scan]
- **A flat copied evidence blob:** erases authority boundaries and makes source/digest review impractical; index separate bounded records instead. [VERIFIED: codebase scan]
- **Package checks based only on `mix.exs`:** do not inspect what users receive; build and unpack first. [VERIFIED: codebase scan]
- **Worktree-cleanliness gate:** fails on harmless local files and violates D-26; inspect tracked inputs and package output only. [VERIFIED: codebase scan]
- **Reusable `v*.*.*` advisory job with fixed v1.3.4 facts:** misstates scope; gate the current job to v1.3.4 and defer framework generalization. [VERIFIED: codebase scan]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON structural validation | Custom nested-key validator | Existing JSV + JSON Schema pattern | Existing project schema convention gives precise, testable record contracts. [VERIFIED: codebase scan] |
| Package-content prediction | An inferred allowlist parser | `mix hex.build --unpack` plus normalized diff | The built artifact is the publish boundary. [VERIFIED: codebase scan] |
| Tracked-file enumeration | Shell word-splitting/globs | `git ls-files -z` decoded as NUL-delimited records | Correctly handles spaces and unusual path characters. [VERIFIED: codebase scan] |
| Digest primitive | Home-grown hashing | Erlang `:crypto.hash(:sha256, bytes)` | Existing tests already use this mechanism. [VERIFIED: codebase scan] |

**Key insight:** This phase needs a small, shared repository-control-plane implementation, not a new application subsystem or quality framework. [VERIFIED: codebase scan]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Phase 131 prerequisite, candidate, validation narrative, and all success/failure/pre-schema journey files carry the v1.3.4 facts. [VERIFIED: codebase scan] | Preservation import into immutable capsule records with original path/digest/commit metadata; no fact rewrite. |
| Live service config | Release workflow carries the archive prerequisite path and runs on every semver tag. [VERIFIED: codebase scan] | Code/workflow edit: point at capsule and scope the advisory job to v1.3.4; no remote state migration. |
| OS-registered state | None found in tracked repository inspection; no launchd/systemd/Task Scheduler/pm2 registration is represented. [VERIFIED: codebase scan] | None. |
| Secrets/env vars | `HEX_API_KEY` is only workflow publish configuration; evidence files/tests explicitly reject secret/home-path leakage. [VERIFIED: codebase scan] | Do not import secrets; retain redaction scanning and keep workflow secret name unchanged. |
| Build artifacts | `mix hex.build --unpack` creates a local package archive/unpack tree; current artifact includes `priv/adoption_evidence` and benchmark raw files through package allowlist. [VERIFIED: codebase scan] | Build in a temp directory during hygiene check, normalize members, and compare them to expected package data; do not track generated artifact. |

## Common Pitfalls

### Pitfall 1: Treating historical facts as fresh proof

**What goes wrong:** A successful retained journey is read as a current release prerequisite or failed attempts are re-run/rewritten. [VERIFIED: codebase scan]

**How to avoid:** Label retained journey records advisory and immutable; deterministic validation proves their identity, integrity, and redaction only. [VERIFIED: codebase scan]

### Pitfall 2: Path traversal through manifest records

**What goes wrong:** A manifest path escapes the capsule or a sidecar/symlink is read outside its expected root. [VERIFIED: codebase scan]

**How to avoid:** Reject absolute paths, `..` components, non-regular files, roots that differ after expansion, unexpected extensions/media types, and any digest mismatch before decode/return. [VERIFIED: codebase scan]

### Pitfall 3: Losing source-versus-import provenance

**What goes wrong:** Imported records overwrite or blur original observation fields with migration metadata. [VERIFIED: codebase scan]

**How to avoid:** Keep payload facts and immutable source metadata distinct from `imported_at`, `import_reason`, and sanitization classification; changes append `supersedes`. [VERIFIED: codebase scan]

### Pitfall 4: Under-testing the package boundary

**What goes wrong:** A future `mix.exs` allowlist change silently ships planning, evidence, scripts, tests, or raw proof. [VERIFIED: codebase scan]

**How to avoid:** Compare exact sorted paths from the unpacked archive with a reviewed expected manifest and separately prohibit sensitive path classes. [VERIFIED: codebase scan]

### Pitfall 5: Broad hygiene becomes a developer-hostile CI gate

**What goes wrong:** A local untracked scratch file causes unrelated release/CI failure. [VERIFIED: codebase scan]

**How to avoid:** Never inspect arbitrary untracked/ignored files; only inspect Git-tracked placement, declared operational consumers, and the built package. [VERIFIED: codebase scan]

## Code Examples

### JSV validation with stable error normalization

```elixir
# Existing Rendro.PublicApi.Validator pattern. [VERIFIED: codebase scan]
schema = "priv/schemas/release_evidence_manifest.schema.json"
         |> File.read!()
         |> JSON.decode!()
         |> JSV.build!()

case JSV.validate(manifest, schema) do
  {:ok, _} -> :ok
  {:error, error} -> {:error, JSV.normalize_error(error) |> inspect(limit: :infinity)}
end
```

### Deterministic hygiene alias placement

```elixir
# Keep task implementation in dev/, then use the same alias in all maintainers' paths.
"quality.hygiene": [&quality_hygiene/1],
"ci.fast": [
  "format --check-formatted",
  "quality.hygiene",
  # existing fast-gate steps follow
]
```

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Archive planning files and `priv/journey_evidence` are read directly by active scripts/tests/workflow. | A versioned, schema/digest-bound repository capsule owns current v1.3.4 evidence facts. | Historical planning returns to archive-only status. [VERIFIED: codebase scan] |
| `scripts/repo_hygiene_check.sh` rejects dirty/untracked worktrees and invokes broad `mix ci`. | `mix quality.hygiene` checks only tracked placement, operational archive dependencies, and actual package contents. | Local feedback matches CI without false failures from developer-local state. [VERIFIED: codebase scan] |
| `mix.exs` is the only package-boundary defense. | Actual unpacked-member manifest is a deterministic contract. | Package drift is detected at the artifact boundary. [VERIFIED: codebase scan] |

## Assumptions Log

All findings are based on the locked phase context, repository source/history, or locally executed commands; no unverified external package or framework claims are used.

## Open Questions

1. **Exact current package member manifest**
   - What we know: the package build succeeds and the explicit allowlist currently ships public adoption evidence; it also exposes `bench/results/raw/*` in the unpacked artifact. [VERIFIED: codebase scan]
   - What's unclear: whether every benchmark raw JSON/PDF member is intentionally public under D-22/D-23.
   - Recommendation: capture the full normalized current list, classify each non-runtime member with owner/reason, and remove raw proof artifacts unless the owner records a narrow public package exception.

2. **Retained script inventory ownership**
   - What we know: `repo_hygiene_check.sh` and `render_logo.exs` have no current caller in the scanned workflow/Mix/docs/test surfaces; `audit_branch_protection.exs` also has no scanned caller. [VERIFIED: codebase scan]
   - What's unclear: whether maintainers invoke any of these as undocumented operator procedures.
   - Recommendation: document a current role/invocation/review trigger in `scripts/README.md` or remove each after the required entry-point/reference check; do not preserve legacy shell hygiene.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | loader, tests, hygiene alias | yes | Elixir 1.19.5 / OTP 28 / Mix 1.19.5 | — |
| Hex Mix task | actual package build | yes | bundled task; `mix hex.build --unpack` succeeds | — |
| Git | tracked placement audit and moves | yes | repository command available | — |
| `shasum` / `tar` | local inspection support | yes | system tools available | implementation should use Elixir `:crypto` and Mix build output |
| Node | existing Phase 132 governance only | yes in existing project usage | not required by hygiene implementation | no new Node dependence |

**Missing dependencies with no fallback:** None. [VERIFIED: codebase scan]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit under Elixir 1.19.5; existing Node built-in runner for Phase 132 governance. [VERIFIED: codebase scan] |
| Config file | `test/test_helper.exs`; no separate test framework config found. [VERIFIED: codebase scan] |
| Quick run command | `mix test test/quality/repository_hygiene_test.exs test/scripts/repository_evidence_test.exs -x` |
| Full deterministic suite | `mix ci.fast` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HYGIENE-01 | Active operational sources have no archive consumer; named GSD tooling exceptions are explicit. | unit/contract | `mix test test/quality/repository_hygiene_test.exs -x` | Wave 0 |
| HYGIENE-02 | Manifest/records validate; loader rejects traversal, role/version/digest/binding failures; active consumers resolve capsule facts. | unit/contract | `mix test test/scripts/repository_evidence_test.exs test/scripts/phoenix_clean_room_proof_test.exs test/scripts/public_release_verifier_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs -x` | Wave 0 / existing consumers |
| HYGIENE-03 | Git-tracked planning paths obey canonical/milestone forms; script inventory covers retained executables. | unit/contract | `mix test test/quality/repository_hygiene_test.exs -x` | Wave 0 |
| HYGIENE-04 | Unpacked archive exactly matches expected manifest and rejects prohibited classes. | integration/contract | `mix quality.hygiene` | Wave 0 |

### Sampling Rate

- **Per task commit:** focused ExUnit command for the modified contract.
- **Per wave merge:** `mix quality.hygiene` and affected migration tests.
- **Phase gate:** `mix ci.fast`; run `mix ci.proofs` separately as proof-lane evidence, retaining unavailable advisory/remote results as explicit deferral rather than a completion blocker. [VERIFIED: codebase scan]

### Wave 0 Gaps

- [ ] `test/quality/repository_hygiene_test.exs` — HYGIENE-01, HYGIENE-03, HYGIENE-04 contract and negative cases.
- [ ] `test/scripts/repository_evidence_test.exs` — HYGIENE-02 manifest/record/loader negative-path tests.
- [ ] `dev/rendro/repository_evidence.ex` and `dev/rendro/repository_hygiene.ex` — dev/test-only implementation loaded through the `mix.exs` alias.
- [ ] Versioned expected package-member manifest and capsule JSON schemas/records.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No user authentication surface. [VERIFIED: codebase scan] |
| V3 Session Management | no | No session surface. [VERIFIED: codebase scan] |
| V4 Access Control | yes | File scope/manifest authority is enforced by confined roots, strict roles, and Git repository controls; do not claim digest-only immutability. [VERIFIED: codebase scan] |
| V5 Input Validation | yes | JSV schemas, bounded fields, strict enums, explicit schema version, path confinement, and digest checks. [VERIFIED: codebase scan] |
| V6 Cryptography | yes | Use `:crypto` SHA-256 for tamper detection only; do not hand-roll cryptography or represent a digest as independent retention authority. [VERIFIED: codebase scan] |

### Known Threat Patterns for repository evidence

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Manifest traversal / absolute path | Tampering, information disclosure | Reject before read; expand relative to fixed root and require resulting path to stay inside it. [VERIFIED: codebase scan] |
| Record substitution or stale role | Tampering | Strict role enum, schema version, candidate/tag/release binding, and SHA-256 verification. [VERIFIED: codebase scan] |
| Secret/local path inclusion in retained evidence | Information disclosure | Preserve current redaction assertions; scan imported JSON/Markdown for key names, home paths, PID/port, and binary proof bytes. [VERIFIED: codebase scan] |
| Package leakage | Information disclosure | Build/unpack then exact member diff plus prohibited-path checks. [VERIFIED: codebase scan] |
| Planning data becomes executable authority | Elevation of privilege / tampering | Archive-consumer scan; only named `gsd_tooling` may inspect planning for its own structural purpose. [VERIFIED: codebase scan] |

## Sources

### Primary (HIGH confidence)

- Repository source and tests (`mix.exs`, `scripts/phoenix_clean_room_proof.exs`, `scripts/verify_public_release.exs`, `scripts/repo_hygiene_check.sh`, `.github/workflows/release.yml`, focused tests) — consumer inventory, existing conventions, command behavior. [VERIFIED: codebase scan]
- `.planning/phases/133-repository-evidence-hygiene/133-CONTEXT.md` — locked D-01 through D-27 decisions and bounded scope. [VERIFIED: project context]
- `.planning/QUALITY.md` and `.planning/quality/baselines/132-initial.json` — QL-002 owner, evidence boundary, and closure requirement. [VERIFIED: project context]
- Git history and archived roadmaps — Phase 5 belongs to v1.0 and Phase 45 belongs to v1.8. [VERIFIED: git history]
- Local `mix hex.build --unpack` and tool probes — artifact-build viability and available environment. [VERIFIED: local command]

### Secondary (MEDIUM confidence)

- None; this phase is repository-specific and required no external technical research.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all tools/dependencies/patterns are present in repository and locally exercised.
- Architecture: HIGH — locked decisions prescribe the capsule and hygiene boundary; integration points are code-scanned.
- Pitfalls: HIGH — directly evidenced by archive consumers, broad shell script behavior, and package build inspection.

**Research date:** 2026-08-26  
**Valid until:** 2026-09-25 (repository-specific research; refresh after package/consumer topology changes)
