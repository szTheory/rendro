# Phase 72: Closure — Audit, Polish, and Ship - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the v2.3 milestone with an auditable proof that every `(surface × viewer)` cell is terminal (`supported` or `explicit_deferral`), engine-level required CI lanes are preserved unchanged, guides match the matrix, `72-VERIFICATION.md` captures the final ledger, and adopters receive a truthful Hex release.

Phase 71 already recorded all cells (`missing` empty: 17 supported, 9 explicit_deferral, 0 unverified). Phase 72 is **audit ritual + publication closure**, not new recording work.

Out of scope: net-new viewer promotions, matrix schema changes, engine widening, headless-browser GUI automation, `mix rendro.viewer_evidence init`, Hex packaging of `priv/viewer_evidence/` / `priv/support_matrix.json`, promoting `viewer-evidence-live-proof` to required on `main`, staleness blocking in merge CI, milestone audit regeneration (defer to `/gsd-audit-milestone`).

</domain>

<decisions>
## Implementation Decisions

### Required-check audit capture (Area 1 — GUARDRAIL-02 core)
- **D-01:** **B-lite + milestone snapshot** — commit a minimal normalized required-check contract; prove live GitHub protection at close; capture snapshot in `72-VERIFICATION.md`. Reject checklist-only (v2.2 operational-gap pattern) and full raw `gh api` dumps as sole mechanism.
- **D-02:** Add `priv/guardrails/required_status_checks.json` with: `branch: main`, `strict: true`, `policy: additive_only`, `required_contexts` (sorted), `since_milestone`, per-context semantic class (`deterministic` | `behavioral_live_proof` | `release`), and job→command mapping notes.
- **D-03:** **v2.3 close baseline contexts (minimum required on `main`):** `test`, `signing-live-proof`, `long-lived-live-proof`, `release-proof`. Document advisory jobs: `viewer-evidence-live-proof` (structural-proxy regen; not required per Phase 68 D-18). Document folded-into-`test`: docs-contract lane 8, structural validation, `mix ci` steps.
- **D-04:** Add offline `test/guardrails/required_checks_contract_test.exs`: `ci.yml` contains all baseline job names; behavioral jobs still run expected `mix test --include ...` commands; `scripts/verify_docs.exs` still registers eight docs-contract lanes. **No GitHub API in default `mix ci`** (fork PR safety, pure-core boundary).
- **D-05:** Add `scripts/audit_branch_protection.exs` (or thin `mix rendro.guardrails.audit` wrapper): fetch live protection, normalize to `{strict, contexts}`, fail if baseline contexts ⊄ live or `strict` is false. Run at Phase 72 close and optionally before tag; requires `GITHUB_TOKEN` with administration read.
- **D-06:** `72-VERIFICATION.md` records: command run, timestamp, normalized JSON snapshot, explicit mapping table (`test` → `mix ci` + 8 docs-contract lanes). If live audit fails, artifact status is `gaps_found` with explicit gap — not silent pass.
- **D-07:** Fix planning drift: PITFALLS/research references to a separate required `viewer-evidence-schema` check are superseded by Phase 68 D-18 (folded into `test` job). Baseline and audit docs must reflect actual protection, not outdated PITFALLS wording.

### Staleness enforcement at ship (Area 2)
- **D-08:** **Implement `mix rendro.viewer_evidence validate --strict`** — staleness warnings (`recorded_at` > 180 days on `supported` rows) become fatal (exit 1). Scope `--strict` to staleness only; legacy promotion warnings are already cleared.
- **D-09:** **Default `validate` stays advisory** for staleness (Phase 68 D-17 behavior preserved on every PR). Do **not** wire `--strict` into docs-contract lane 8, `mix ci`, or branch protection.
- **D-10:** Phase 72 closure ritual runs both `validate` (exit 0) and `validate --strict` (exit 0 at ship time); record outputs in `72-VERIFICATION.md`. Document in `guides/viewer_evidence.md` Appendix D: default = structural + advisory staleness; `--strict` = operator/release gate when refreshing evidence.
- **D-11:** Rationale (Browserslist/npm/RubyGems/Elixir precedent): structural honesty is merge-blocking; temporal refresh is operator-owned with explicit opt-in strictness — avoids calendar-bomb surprise failures ~180 days after recording.

### Ship mechanics (Area 3)
- **D-12:** **Ship `v0.3.1` on Hex** via existing tag-push `release.yml` workflow — not a re-publish of `0.3.0` (already tagged `ba023c9`). v2.3 viewer-evidence work lands as a **patch** under 0.x semver policy in `guides/api_stability.md`.
- **D-13:** **CHANGELOG reconciliation:** freeze `## [0.3.0] - 2026-05-08` as actually published (pre–v2.3 viewer); move all v2.3 Viewer Evidence bullets to `## [0.3.1] - <ship-date>`. Bump `mix.exs` `@version` to `0.3.1`.
- **D-14:** Pre-tag gate: `mix release.preflight` green at `v0.3.1`; `scripts/release_preflight_proof.exs` with `--current-version-tag`. Optional hardening: add `mix release.preflight` step to `release.yml` before `hex.publish` if not already present.
- **D-15:** **`/gsd-complete-milestone v2.3` is separate:** planning archive + annotated `v2.3` tag only — no Hex publish in complete-milestone. Order: Phase 72 execute → `v0.3.1` on Hex → `/gsd-audit-milestone v2.3` → `/gsd-complete-milestone v2.3`.
- **D-16:** Do **not** adopt release-please in Phase 72 — process change out of closure scope; existing manual tag workflow matches v1.10 precedent.

### Verification ledger depth (Area 4)
- **D-17:** **`72-VERIFICATION.md` = B+C hybrid** — machine-exported full ledger + trust-sensitive spot-check + Phase 70-style must-haves table. Do **not** hand-maintain a 26-row table that duplicates `priv/support_matrix.json`.
- **D-18:** Canonical ledger source: `mix rendro.viewer_evidence list --json` captured at close (fenced JSON in VERIFICATION or script-generated compact table from same output). Summary counts from CLI aggregates, not hand-typed.
- **D-19:** Trust-sensitive spot-check (~8–12 rows): `signature_widget × pdfjs` (#4202 deferral), `signed_artifact × apple_preview`, signing_prep inheritance rows (D-15), long-lived deferral batch, `forms × adobe_acrobat_reader` recipe smoke, 1–2 PDFium promoted rows for `viewer_kind` honesty.
- **D-20:** Include GUARDRAIL-02 required-check audit table (pre-v2.3 baseline vs v2.3 close; semantics-changed column).
- **D-21:** Regenerate `v2.3-MILESTONE-AUDIT.md` via **`/gsd-audit-milestone v2.3` after Phase 72 passes** — not during Phase 72 execute. Backfill `69-VERIFICATION.md` / `71-VERIFICATION.md` if missing (milestone audit blocker).

### Guide polish bar (Area 5)
- **D-22:** **Option B+** — matrix-truth + docs-contract green + surgical guide fixes only. No full prose audit pass.
- **D-23:** Gates (must pass): `mix docs.contract` 8/8; `mix rendro.viewer_evidence missing` exit 0; `validate` + `validate --strict` exit 0; GUARDRAIL-02 live audit; automated checks block in VERIFICATION.
- **D-24:** **Touch `guides/viewer_evidence.md`:** extend Automated path for Phase 71 trust-sensitive surfaces (live-test + `Recorder.record/2` path, link to `trust_sensitive_viewer_evidence_live_test.exs`); keep `forms × chrome_pdfium` worked example; add Appendix D for `--strict`; preserve "matrix = claim, evidence = observation" split (BCD/Can I Use model).
- **D-25:** **Touch `guides/api_stability.md`:** drift-fix only — every `explicit_deferral` reason substring appears in prose; every `supported` row has canonical evidence path or STACK mirror. Skip SemVer/adapter boundary sections unchanged this milestone.
- **D-26:** **Harden `test/docs_contract/viewer_evidence_claims_test.exs`:** add missing supported path asserts (`forms/chrome_pdfium.md`, `signature_widget/chrome_pdfium.md`, etc.); optional matrix-driven test that each `explicit_deferral` → `api_stability` contains ≥40-char reason substring from `evidence_deferred`.
- **D-27:** **Explicitly skip:** re-copying evidence frontmatter into guides; expanding Appendix A GUI tables for trust-sensitive surfaces; readability-only rewrites.

### Deferred polish items (Area 6)
- **D-28:** **`mix rendro.viewer_evidence init` — OUT** of Phase 72. `cp priv/viewer_evidence/_template.md` remains canonical; defer to v2.4 operator DX backlog.
- **D-29:** **Hex `files:` for `priv/viewer_evidence/` — OUT.** Keep intentional repo-only operator model documented in guide prerequisites. Partial Hex shipping (evidence without matrix/schemas) violates documentation honesty and implies broken recording from deps.
- **D-30:** **Optional IN:** negative `hex.build` test asserting tarball **excludes** `priv/viewer_evidence/` and `priv/support_matrix.json` — locks documented contract (mirror `branding_claims_test.exs` pattern).
- **D-31:** **Required-checks baseline — IN** (same as D-02–D-05). This is the load-bearing GUARDRAIL-02 deliverable, not optional polish.
- **D-32:** **Promoting `viewer-evidence-live-proof` to required — OUT** at v2.3 close. Document as advisory; additive promotion is a separate future policy decision.

### Claude's Discretion
- Exact `priv/guardrails/required_status_checks.json` schema layout and error message wording.
- `scripts/audit_branch_protection.exs` vs `mix rendro.guardrails.audit` naming.
- Script to embed `list --json` into VERIFICATION vs fenced paste.
- Whether negative hex.build test ships in Phase 72 or v2.4.
- Exact deferral mirror test shape in docs-contract.
- Plan split (72-01 guardrails, 72-02 verification ledger, 72-03 guide polish + 0.3.1 ship) as long as merge stays one auditable closure wave.

</decisions>

<specifics>
## Specific Ideas

- **BCD / Can I Use model:** machine-readable matrix is canonical; guides explain procedure; VERIFICATION is an indexed audit packet (SOC2 evidence-index pattern), not a second copy of every cell.
- **Browserslist lesson:** warn on stale data by default; strict enforcement is explicit opt-in (`--strict`, not ambient CI calendar bombs).
- **v2.2 lesson:** artifact closure ≠ operational closure — branch protection must be committed + live-audited, not checklist theatre.
- **szTheory OSS DNA:** contract tests for docs/promises; deterministic merge-blocking lane; behavioral live-proof lanes separate; release preflight before publish; verification artifacts are product behavior.
- **Phoenix team DX:** Hex `0.3.1` must match `guides/api_stability.md` viewer claims — `0.3.0` on hex.pm predates v2.3 viewer work; patch release closes the adopter contract gap without republishing consumed semver.
- **Operator happy path preserved:** `missing` → record (CI or manual) → `validate` → promote matrix → `api_stability` + CHANGELOG → docs-contract green.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements and roadmap
- `.planning/ROADMAP.md` — Phase 72 goal, success criteria, pitfall guardrails, cross-milestone guardrails
- `.planning/REQUIREMENTS.md` — GUARDRAIL-02
- `.planning/PROJECT.md` — Documentation honesty, verification as product behavior, v2.3 intent
- `.planning/v2.3-v2.3-MILESTONE-AUDIT.md` — Mid-milestone gap baseline (superseded at close by audit-milestone)

### Phase 68–71 decisions (closure inputs)
- `.planning/phases/68-viewer-evidence-schema-mix-task-and-docs-contract-lane/68-CONTEXT.md` — D-17 staleness advisory; D-18 no new required check
- `.planning/phases/70-consolidate-already-validated-surfaces/70-CONTEXT.md` — Atomic publication; D-26 staleness deferred; 70-VERIFICATION format precedent
- `.planning/phases/71-record-new-trust-sensitive-surfaces-and-explicit-deferrals/71-CONTEXT.md` — All cells closed; CI structural-proxy recording
- `.planning/phases/70-consolidate-already-validated-surfaces/70-VERIFICATION.md` — Must-haves table + command block pattern

### Research and pitfalls
- `.planning/research/PITFALLS.md` — Required-check drift (#7); reconcile viewer-evidence-schema wording with D-18
- `.planning/research/ARCHITECTURE.md` — Phase 72 closure scope
- `.planning/milestones/v2.2-MILESTONE-AUDIT.md` — Branch protection closeout precedent
- `.planning/RETROSPECTIVE.md` — v2.2 operational gap (04142e1)

### Project DNA and prompts
- `prompts/rendro-oss-dna.md` — Contract tests, release safety, honest matrix, optional integration lanes
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — Honest scope, no compliance overclaim
- `AGENTS.md` — Pure core, documentation-as-contract

### Operator recipe and release
- `guides/viewer_evidence.md` — Recording recipe; extend Automated path + Appendix D
- `guides/api_stability.md` — Prose mirror targets; CHANGELOG discipline
- `lib/mix/tasks/rendro/viewer_evidence.ex` — Add `--strict` to validate
- `lib/mix/tasks/release/preflight.ex` — Pre-tag gate
- `scripts/release_preflight_proof.exs` — Isolated worktree proof
- `.github/workflows/ci.yml` — Job names for baseline
- `.github/workflows/release.yml` — Tag → Hex publish
- `mix.exs` — Version bump, package `files:` whitelist (unchanged scope)
- `CHANGELOG.md` — 0.3.0 / 0.3.1 split

### Existing implementation
- `priv/support_matrix.json` — 26-cell terminal state
- `lib/rendro/viewer_evidence/validator.ex` — Staleness warnings source
- `test/docs_contract/viewer_evidence_claims_test.exs` — Docs-contract lane 8
- `test/docs_contract/branding_claims_test.exs` — Negative hex.build test precedent

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Rendro.ViewerEvidence` — `list` / `missing` / `validate` / `record`; extend `validate` with `--strict`
- `Rendro.ViewerEvidence.Validator.staleness_warnings/1` — 180-day logic already implemented
- `scripts/verify_docs.exs` — Eight-lane registry pattern for offline guardrail test
- `scripts/release_preflight_proof.exs` + `Mix.Tasks.Release.Preflight` — Release gate precedent (v1.10)
- `test/docs_contract/branding_claims_test.exs` — `hex.build` tarball assertion pattern
- Phase 70/71 live tests — structural-proxy evidence regen (`viewer-evidence-live-proof` job)

### Established Patterns
- Machine-readable `priv/` contract + human `guides/` mirror + docs-contract enforcement
- Deterministic lanes merge-blocking; behavioral live-proof lanes separate and named in CI
- Phase VERIFICATION = must-haves table + command block + gaps section
- Milestone tag (`v2.3`) orthogonal to Hex semver tag (`v0.3.1`)
- Collection incremental, publication atomic (Phase 70/71 D-19)

### Integration Points
- `priv/guardrails/` — new required-check baseline (new)
- `test/guardrails/` — offline CI wiring contract test (new)
- `scripts/audit_branch_protection.exs` — live GUARDRAIL-02 audit (new)
- `.planning/phases/72-closure-audit-polish-and-ship/72-VERIFICATION.md` — closure ledger
- `guides/viewer_evidence.md`, `guides/api_stability.md` — surgical polish
- `CHANGELOG.md`, `mix.exs` — `0.3.1` ship
- `.github/workflows/release.yml` — optional preflight hardening

</code_context>

<deferred>
## Deferred Ideas

- `mix rendro.viewer_evidence init` scaffold — v2.4 operator DX
- Hex `files:` expansion for operator workspace (`priv/support_matrix.json` + schemas + evidence together, or none) — v2.4 packaging policy
- Promote `viewer-evidence-live-proof` to required on `main` — separate policy decision
- Wire `validate --strict` into `mix release.preflight` or tag workflow — optional post-v2.3 hardening
- Scheduled branch-protection drift CI job — future observability (rendro-oss-dna drift pattern)
- release-please adoption — process change, not closure work
- Staleness blocking in docs-contract / `main` CI — only if explicit re-validation milestone with announced deadline

</deferred>

---

*Phase: 72-closure-audit-polish-and-ship*
*Context gathered: 2026-05-29*
