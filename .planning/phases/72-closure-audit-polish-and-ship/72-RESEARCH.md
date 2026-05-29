# Phase 72 Research: Closure — Audit, Polish, and Ship

**Researched:** 2026-05-29  
**Phase:** 72-closure-audit-polish-and-ship  
**Requirements:** GUARDRAIL-02  
**Depends on:** Phase 70 and Phase 71 (complete)  
**Purpose:** Answer “What do I need to know to PLAN this phase well?” — not task breakdown.

---

## 1. Executive Summary

Phase 72 closes **GUARDRAIL-02** and the v2.3 milestone through **audit ritual + publication closure**, not new matrix recording. Phase 71 already terminalized all 26 cells (`missing` empty: **17 supported**, **9 explicit_deferral**, **0 unverified**). Phase 72 delivers five load-bearing artifacts:

1. **Committed required-check contract** — `priv/guardrails/required_status_checks.json` + offline `test/guardrails/required_checks_contract_test.exs` wiring `ci.yml` / `verify_docs.exs` to the baseline.
2. **Live branch-protection audit** — `scripts/audit_branch_protection.exs` (or thin Mix wrapper) comparing live GitHub `main` protection to the baseline; snapshot in `72-VERIFICATION.md`.
3. **`mix rendro.viewer_evidence validate --strict`** — staleness warnings (>180 days on `supported` rows) become fatal; default `validate` stays advisory (Phase 68 D-17).
4. **`72-VERIFICATION.md`** — B+C hybrid ledger (machine JSON + trust-sensitive spot-check + must-haves table + GUARDRAIL-02 audit).
5. **Hex `v0.3.1` ship** — CHANGELOG/`mix.exs` reconciliation; tag-push via existing `release.yml`.

**Critical planner insight:** Live GitHub protection **already matches** the v2.3-close baseline (four required contexts, `strict: true`, `viewer-evidence-live-proof` advisory only). Phase 72’s GUARDRAIL-02 value is making that state **durable in-repo** (contract test + JSON baseline) and **re-auditable at close** — not discovering a gap today. The v2.2 lesson (artifact closure ≠ operational closure) is addressed by D-01’s B-lite pattern: commit contract, offline CI wiring test, live audit snapshot — not checklist theatre.

**PITFALLS drift to fix:** `PITFALLS.md` §7 still lists `viewer-evidence-schema` as a separate required check. Phase 68 D-18 folded structural viewer-evidence enforcement into the `test` job (lane 8 via `mix test` / `mix docs.contract`). Baseline JSON, audit docs, and any PITFALLS cross-references in Phase 72 artifacts must reflect **actual** protection, not the outdated “fourth required check” wording.

**Ship ordering (D-15):** Phase 72 execute → `v0.3.1` on Hex → `/gsd-audit-milestone v2.3` → `/gsd-complete-milestone v2.3`. Milestone tag `v2.3` is planning-only; Hex tag is `v0.3.1`.

---

## 2. Current State Audit

### 2.1 Matrix terminal state (operator CLI)

**Commands run 2026-05-29:**

```bash
mix rendro.viewer_evidence list
# Viewer evidence: 26 cells (supported=17, unverified=0, explicit_deferral=9)

mix rendro.viewer_evidence missing
# Exit 0 — No unverified cells.

mix rendro.viewer_evidence validate
# Exit 0 — Viewer evidence validation passed. (no legacy warnings, no staleness warnings)
```

**Summary JSON** (`mix rendro.viewer_evidence list --json`):

```json
{"summary":{"total":26,"supported":17,"unverified":0,"explicit_deferral":9},"cells":[...]}
```

All `supported` rows have `recorded_at` **2026-05-28** or **2026-05-29** — well inside the 180-day staleness window, so `validate --strict` will also exit 0 at ship time unless dates are artificially aged in tests.

**17 evidence pointers** in `priv/support_matrix.json` (canonical paths):

| Surface | Viewer | Evidence path |
|---------|--------|---------------|
| forms | adobe_acrobat_reader, apple_preview, chrome_pdfium | `priv/viewer_evidence/forms/*.md` |
| forms (signature_widget_viewers) | adobe_acrobat_reader, apple_preview, chrome_pdfium | `priv/viewer_evidence/signature_widget/*.md` |
| signing_preparation | adobe_acrobat_reader | `priv/viewer_evidence/signing_preparation/adobe_acrobat_reader.md` |
| signing_preparation | apple_preview, chrome_pdfium | inherit `signature_widget` pointers |
| signing (signed_artifact) | adobe_acrobat_reader, chrome_pdfium | `priv/viewer_evidence/signed_artifact/*.md` |
| signing.long_lived | adobe_acrobat_reader | `priv/viewer_evidence/long_lived_signed_artifact/adobe_acrobat_reader.md` |
| embedded_files | adobe_acrobat_reader | `priv/viewer_evidence/embedded_files/adobe_acrobat_reader.md` |
| links | adobe_acrobat_reader, apple_preview | `priv/viewer_evidence/links/*.md` |
| protection | adobe_acrobat_reader, apple_preview | `priv/viewer_evidence/protection/*.md` |

**9 explicit_deferral rows** (matrix `evidence_deferred` — all ≥40 chars, named viewer behavior):

| Cell | Reason substring (matrix) |
|------|---------------------------|
| forms × pdfjs | save-and-reopen round-trip failed |
| signature_widget × pdfjs | mozilla/pdf.js#4202 |
| signing_preparation × pdfjs | mozilla/pdf.js#4202 |
| signed_artifact × apple_preview | does not validate /Sig |
| signed_artifact × pdfjs | no /Sig validation UI |
| long_lived × apple_preview, chrome_pdfium, pdfjs | no LTV indicators |
| embedded_files × apple_preview | Attachments UI gap |

### 2.2 CI topology today (`.github/workflows/ci.yml`)

| Job | `needs` | Merge-blocking on `main` | Semantic class | Primary command |
|-----|---------|--------------------------|----------------|-----------------|
| `test` | — | **required** | `deterministic` | `mix ci` |
| `viewer-evidence-live-proof` | `test` | **advisory** (not in protection) | `behavioral_live_proof` | `mix test --include live_pdf_tools` (7 adapter test files) |
| `signing-live-proof` | `test` | **required** | `behavioral_live_proof` | `mix test --include live_signing test/rendro/adapters/signing_live_test.exs` |
| `long-lived-live-proof` | `test` | **required** | `behavioral_live_proof` | `mix test --include live_pdf_tools test/rendro/adapters/signing_live_test.exs` |
| `release-proof` | `test` | **required** | `release` | `mix run scripts/release_preflight_proof.exs --current-version-tag --worktree "$RUNNER_TEMP/rendro-release-proof"` |

**Folded into `test` / `mix ci` (not separate required contexts per D-18):**

- Eight docs-contract lanes via `scripts/verify_docs.exs` (lane 8 = `viewer_evidence_claims_test.exs`)
- Structural validation, format, hex.build, credo, dialyzer (`mix.exs` `:ci` alias lines 62–70)
- Matrix JSON Schema (tier-A) via `test/docs_contract/viewer_evidence_claims_test.exs` + `mix test` path

**`mix ci` alias** does **not** invoke `mix docs.contract` directly; lane 8 runs because `mix test` includes `test/docs_contract/*.exs`. `mix release.preflight` Phase 2 **does** run `mix docs.contract` explicitly.

### 2.3 Live GitHub branch protection (2026-05-29)

```bash
gh api repos/szTheory/rendro/branches/main/protection
```

**Normalized snapshot:**

```json
{
  "strict": true,
  "contexts": ["test", "signing-live-proof", "release-proof", "long-lived-live-proof"]
}
```

- `viewer-evidence-live-proof` is **not** required — matches Phase 68 D-18 / Phase 72 D-32.
- Pre-v2.3 baseline contexts are the **same four names**; v2.3 added advisory `viewer-evidence-live-proof` job without promoting it to required. Semantics of the four required jobs are unchanged (folded viewer-evidence schema into `test`, not diluted signing/long-lived lanes).

### 2.4 Guardrails artifacts — absent today

| Path | Status |
|------|--------|
| `priv/guardrails/required_status_checks.json` | **missing** — Phase 72 deliverable |
| `test/guardrails/required_checks_contract_test.exs` | **missing** |
| `scripts/audit_branch_protection.exs` | **missing** |
| `.planning/phases/72-closure-audit-polish-and-ship/72-VERIFICATION.md` | **missing** |

### 2.5 `validate --strict` — not implemented

**Mix task** (`lib/mix/tasks/rendro/viewer_evidence.ex`):

- `parse_args!` accepts only `list`, `missing`, `validate`, `record` — no `--strict` flag.
- `run_validate/1` calls `Validator.run_full/3` then `partition_warnings/1`:
  - **Advisory:** `"missing promotion-complete"` OR `"is older than"` (staleness).
  - **Fatal:** everything else.
- Exit 0 when only advisory warnings remain (lines 54–60 moduledoc, 203–217 `run_validate`).

**Validator** (`lib/rendro/viewer_evidence/validator.ex`):

- `staleness_warnings/1` — `@staleness_days 180`; compares matrix `recorded_at` on `supported` rows to `Date.utc_today()`.
- No `strict` option on `run_full/3` today; staleness always appended to warnings list, never errors.

**Implementation path (minimal diff):**

1. `parse_args!`: for `validate`, accept `["validate", "--strict"]` (order: `validate --strict` or add `pop_strict_flag` alongside `--json`).
2. Thread `strict?: true` into `run_validate/1`.
3. When `strict?`, treat staleness warnings as **fatal** (either reclassify in `partition_warnings/2` or pass opt to `Validator.run_full/3` that promotes staleness to `{:error, ...}`).
4. Update moduledoc exit-code table: `validate --strict` → exit 1 on staleness; scope **staleness only** (legacy promotion warnings already zero in production).
5. **Do not** wire into `mix ci`, docs-contract lane 8, or branch protection (D-09).

**Test strategy:**

- Unit: `Validator.staleness_warnings/1` with fixture matrix + backdated `recorded_at`.
- Mix task: `capture_shell_messages` asserting `validate --strict` exits 1 when staleness present, 0 on production matrix.
- No production matrix change needed for green ship — all dates fresh.

### 2.6 `priv/guardrails/required_status_checks.json` — recommended schema

Per D-02, D-03 — planner discretion on exact layout; recommended shape:

```json
{
  "schema_version": 1,
  "branch": "main",
  "strict": true,
  "policy": "additive_only",
  "since_milestone": "v2.3",
  "required_contexts": [
    "long-lived-live-proof",
    "release-proof",
    "signing-live-proof",
    "test"
  ],
  "contexts": [
    {
      "name": "test",
      "semantic_class": "deterministic",
      "ci_job": "test",
      "command": "mix ci",
      "notes": "Includes mix test (8 docs-contract lanes), format, hex.build, compile --warnings-as-errors, docs, credo, dialyzer. Viewer-evidence schema/lint folded here per Phase 68 D-18 — not a separate required context."
    },
    {
      "name": "signing-live-proof",
      "semantic_class": "behavioral_live_proof",
      "ci_job": "signing-live-proof",
      "command": "mix test --include live_signing test/rendro/adapters/signing_live_test.exs"
    },
    {
      "name": "long-lived-live-proof",
      "semantic_class": "behavioral_live_proof",
      "ci_job": "long-lived-live-proof",
      "command": "mix test --include live_pdf_tools test/rendro/adapters/signing_live_test.exs"
    },
    {
      "name": "release-proof",
      "semantic_class": "release",
      "ci_job": "release-proof",
      "command": "mix run scripts/release_preflight_proof.exs --current-version-tag --worktree <isolated>"
    }
  ],
  "advisory_contexts": [
    {
      "name": "viewer-evidence-live-proof",
      "semantic_class": "behavioral_live_proof",
      "ci_job": "viewer-evidence-live-proof",
      "command": "mix test --include live_pdf_tools test/rendro/adapters/*_viewer_evidence_live_test.exs (7 files)",
      "notes": "Phase 71 structural-proxy evidence regen; not required on main per D-18/D-32."
    }
  ],
  "supersedes_planning_refs": {
    "pitfalls_7_viewer_evidence_schema_required": false,
    "rationale": "Structural viewer-evidence enforcement folds into test job; no fourth required GitHub context."
  }
}
```

**Pre-v2.3 vs v2.3 close mapping (D-20):** Required context **set is identical**; semantics **unchanged** for all four. v2.3 **additive** change is the advisory `viewer-evidence-live-proof` job + in-tree evidence tooling — not a new required context.

### 2.7 `scripts/audit_branch_protection.exs` — implementation patterns

**Goal (D-05):** Fetch live protection → normalize `{strict, contexts}` → fail if baseline `required_contexts` ⊄ live OR `strict` is false.

**GitHub API endpoint:**

```
GET /repos/{owner}/{repo}/branches/{branch}/protection
```

**Auth:** `GITHUB_TOKEN` with `repo` + admin read (or fine-grained equivalent). Fork PR CI must **not** call this (D-04).

**Implementation options:**

| Approach | Pros | Cons |
|----------|------|------|
| **`gh api` via `System.cmd`** | Matches operator env; no new deps; easy in scripts | Requires `gh` installed locally |
| **`:req` HTTP** (already dev/test dep) | Pure Elixir; script-only | Must parse JSON; token header wiring |
| **`mix rendro.guardrails.audit`** wrapper | Discoverable via `mix help` | Extra module surface |

**Recommended:** Standalone `scripts/audit_branch_protection.exs` using `:req` (consistent with pure-core script pattern) with optional `gh api` fallback comment in moduledoc. Exit 0 prints normalized JSON to stdout; exit 1 prints gap diff to stderr.

**Normalization logic:**

```elixir
live_contexts =
  protection
  |> get_in(["required_status_checks", "contexts"])
  |> Enum.map(& &1["context"])
  |> Enum.sort()

live_strict = get_in(protection, ["required_status_checks", "strict"])

missing = baseline_required -- live_contexts
# fail if missing != [] or live_strict != true
```

**Repo identity:** Read `mix.exs` `@source_url` or hardcode `szTheory/rendro` from package metadata — prefer parsing `source_url` for portability.

### 2.8 `test/guardrails/required_checks_contract_test.exs` — assertions

Offline contract test (D-04) — **no GitHub API**. Suggested describe blocks:

1. **Baseline file integrity**
   - `priv/guardrails/required_status_checks.json` parses; `required_contexts` sorted; `strict == true`; `policy == "additive_only"`.

2. **`ci.yml` job names**
   - File contains job keys: `test`, `signing-live-proof`, `long-lived-live-proof`, `release-proof`, `viewer-evidence-live-proof`.
   - Every `required_contexts` entry has matching `jobs.<name>:` block.

3. **Behavioral command wiring**
   - `signing-live-proof` step contains `mix test --include live_signing` and `signing_live_test.exs`.
   - `long-lived-live-proof` contains `mix test --include live_pdf_tools` and `signing_live_test.exs`.
   - `viewer-evidence-live-proof` contains `live_pdf_tools` and `trust_sensitive_viewer_evidence_live_test.exs` (advisory job still wired).

4. **Docs-contract lane count**
   - `scripts/verify_docs.exs` registers exactly eight lanes; lane 8 is `viewer_evidence_claims_test.exs`.
   - Mirror existing registration test in `viewer_evidence_claims_test.exs` describe `"docs-contract lane registration"` — guardrails test can duplicate or import shared helper to avoid drift.

5. **Baseline ↔ ci.yml alignment**
   - Each `contexts[].ci_job` in JSON exists in `ci.yml`.
   - `required_contexts` in JSON equals sorted required job names from JSON `contexts` where `semantic_class != advisory`.

**Not in scope:** Proving GitHub UI settings in default `mix ci` (fork safety).

### 2.9 `72-VERIFICATION.md` structure (D-17 B+C hybrid)

Follow `70-VERIFICATION.md` frontmatter + must-haves table, extended per D-17–D-21:

```markdown
---
status: passed | gaps_found
phase: 72-closure-audit-polish-and-ship
verified: <ISO timestamp>
requirements: [GUARDRAIL-02]
score: N/N
---

# Phase 72 Verification Report

## Must-Haves Verified
| # | Criterion | Status | Evidence |
...

## Matrix Ledger (machine export)
< fenced output of `mix rendro.viewer_evidence list --json` OR script-trimmed table >

## Trust-Sensitive Spot-Check (~8–12 rows)
| surface | viewer | status | spot-check note |
| signature_widget | pdfjs | explicit_deferral | #4202 reason matches matrix + api_stability |
| signed_artifact | apple_preview | explicit_deferral | /Sig validation gap |
| signing_preparation | apple_preview | supported | inherits signature_widget pointer (D-15) |
| long_lived_signed_artifact | * | explicit_deferral batch | LTV indicators |
| forms | adobe_acrobat_reader | supported | recipe smoke / evidence path |
| signature_widget | chrome_pdfium | supported | viewer_kind honesty (pdfium-cli) |
...

## GUARDRAIL-02 Required-Check Audit
| context | pre-v2.3 | v2.3 close | semantics changed |
| test | required | required | no — viewer-evidence folded in |
| signing-live-proof | required | required | no |
| long-lived-live-proof | required | required | no |
| release-proof | required | required | no |
| viewer-evidence-live-proof | n/a | advisory | n/a |

### Live audit snapshot
Command: `mix run scripts/audit_branch_protection.exs` (or documented equivalent)
Timestamp: ...
```json
{ "strict": true, "contexts": [...] }
```

## Automated Checks Run
```bash
mix rendro.viewer_evidence missing
mix rendro.viewer_evidence validate
mix rendro.viewer_evidence validate --strict
mix docs.contract
mix test test/guardrails/required_checks_contract_test.exs
mix release.preflight  # at v0.3.1 tag
```

## Gaps
(none | explicit gap list — never silent pass per D-06)
```

**Do not** hand-maintain a 26-row table duplicating `priv/support_matrix.json` (D-17).

**Blocker note (D-21):** `69-VERIFICATION.md` and `71-VERIFICATION.md` are **absent** (only 68 and 70 have verifier artifacts). `/gsd-audit-milestone v2.3` may flag this — backfill during Phase 72 or immediately before milestone audit.

### 2.10 Guide polish gaps

#### `guides/viewer_evidence.md` (D-24)

| Gap | Current | Target |
|-----|---------|--------|
| Automated path scope | Phase 70 rows only (lines 33–57) | Add Phase 71 `record` commands + link `trust_sensitive_viewer_evidence_live_test.exs` |
| Manual step 1 | "Exit code **1** when unverified cells exist (**expected today**)" (line 81) | Stale — update to exit 0 at v2.3 close |
| Manual step 6 | Legacy promotion warnings note (line 129) | Stale post Phase 70/71 — tier-B complete |
| Appendix D | No `--strict` | Document default vs `--strict` staleness gate (D-10) |
| Worked example | `forms × chrome_pdfium` only | Keep; optionally cross-link trust-sensitive evidence files |

**Already good:** Prerequisites (Hex omits `priv/viewer_evidence/`), matrix/observation split, deferral templates (UPSTREAM_ISSUE, etc.), Appendix E mentions `viewer-evidence-live-proof`.

#### `guides/api_stability.md` (D-25)

Drift-fix audit — **supported paths:**

| Evidence path | In guide prose? | In `viewer_evidence_claims_test` path list? |
|---------------|-----------------|---------------------------------------------|
| `forms/chrome_pdfium.md` | ✓ line 52 | **missing** from assert list (only in separate guide test) |
| `signature_widget/chrome_pdfium.md` | ✓ line 56 | **missing** from assert list |
| signing_preparation inherit rows | ✓ prose lines 68–70 | N/A (inherit pointers) |

**Deferral mirror:** All nine `evidence_deferred` strings have matching prose in `api_stability.md` (grep confirmed). Optional matrix-driven test (D-26): each deferral reason substring (≥40 chars) appears in guide — not yet implemented.

#### `test/docs_contract/viewer_evidence_claims_test.exs` (D-26)

Harden path asserts — add to `"api stability guide mirrors..."` list:

- `priv/viewer_evidence/forms/chrome_pdfium.md`
- `priv/viewer_evidence/signature_widget/chrome_pdfium.md`

Optional: `Matrix.load!()` → enumerate `explicit_deferral` → assert `guides/api_stability.md` contains `String.slice(reason, 0, 40)`.

### 2.11 CHANGELOG / `mix.exs` reconciliation (D-12–D-14)

**Current state:**

| Artifact | Value | Issue |
|----------|-------|-------|
| `mix.exs` `@version` | `"0.3.0"` | Must bump to `0.3.1` |
| Git tag | `v0.3.0` at `ba023c9` (`chore: prepare v0.3.0 release`) | Already on Hex; do not re-publish |
| `CHANGELOG.md` | `## [0.3.0] - Unreleased` contains **all** v2.3 Viewer Evidence bullets | Must split per D-13 |

**Target reconciliation:**

1. Freeze `## [0.3.0] - 2026-05-08` as historically published (pre–v2.3 viewer-evidence recording milestone content only — what `ba023c9` actually shipped).
2. Create `## [0.3.1] - <ship-date>` with entire `#### Viewer Evidence (v2.3)` section moved from 0.3.0 draft.
3. Bump `mix.exs` to `0.3.1`; tag `v0.3.1` → triggers `release.yml`.

**`mix release.preflight` coupling:**

- `check_changelog_release_tail/1` expects `## [#{version}] - Unreleased` in CHANGELOG — at tag time, either keep Unreleased until preflight passes then date-stamp, or adjust check if ship workflow dates on publish.
- Phase 2 runs `mix ci`, `mix docs.contract`, `hex.build --unpack`, `hex.publish --dry-run`.

**`release.yml` gap (D-14):**

Current workflow runs only `mix ci` before `mix hex.publish` — **not** `mix release.preflight`. The `release-proof` **CI job** runs `release_preflight_proof.exs` in isolated worktree on every `main` push, but tag publish path is lighter.

Optional hardening: add step `mix release.preflight` in `release.yml` after checkout (requires exact tag already on HEAD — true for tag-push trigger).

### 2.12 Optional negative `hex.build` test (D-30)

Pattern from `test/docs_contract/branding_claims_test.exs` lines 41–56:

```elixir
test "built tarball excludes operator-only priv paths" do
  # mix hex.build → tar -tzf → refute priv/viewer_evidence/
  # refute priv/support_matrix.json
end
```

Documents intentional repo-only operator model (D-29). Planner discretion: ship in Phase 72 or defer v2.4.

### 2.13 Phase verification coverage gap

| Phase | VERIFICATION.md |
|-------|-----------------|
| 68 | ✓ |
| 69 | **missing** |
| 70 | ✓ |
| 71 | **missing** |
| 72 | **to create** |

---

## 3. Implementation Recommendations by CONTEXT Decision Area

### Area 1 — Required-check audit (D-01–D-07, D-31)

1. Land `priv/guardrails/required_status_checks.json` first — single source for offline test + audit script.
2. Add `test/guardrails/required_checks_contract_test.exs` in same wave as JSON.
3. Implement `scripts/audit_branch_protection.exs` reading baseline JSON; document `GITHUB_TOKEN` in guide or script header.
4. Run live audit at Phase 72 close; paste normalized JSON + mapping table into `72-VERIFICATION.md`.
5. Add one-line comment in Phase 72 SUMMARY or RESEARCH cross-ref correcting PITFALLS §7 checklist item (`viewer-evidence-schema` not a required context).

### Area 2 — Staleness `--strict` (D-08–D-11)

1. Extend `parse_args!` / `run_validate` only — avoid changing `Validator.run_full` contract unless needed.
2. Update `guides/viewer_evidence.md` Appendix D + one sentence in Automated path closure ritual.
3. Closure commands: both `validate` and `validate --strict` exit 0; record in VERIFICATION.
4. Add mix task test for `--strict` using synthetic backdated matrix fixture in `test/support/`.

### Area 3 — Ship mechanics (D-12–D-16)

1. **Order within closure PR:** CHANGELOG split → `mix.exs` bump → verify `mix release.preflight` green with disposable tag (`release_preflight_proof.exs --current-version-tag`).
2. Tag `v0.3.1` on merged commit; `release.yml` publishes to Hex.
3. Do **not** adopt release-please; do **not** run `/gsd-complete-milestone` inside Phase 72 execute.

### Area 4 — Verification ledger (D-17–D-21)

1. Generate ledger from `mix rendro.viewer_evidence list --json` at close — script or fenced paste.
2. Spot-check table: prioritize cells listed in D-19 (pdfjs #4202, Preview signed_artifact, signing_prep inheritance, long-lived batch, forms×acrobat, pdfium promoted rows).
3. Backfill `69-VERIFICATION.md` / `71-VERIFICATION.md` if milestone audit blocks (can be lightweight retrospectives citing existing SUMMARYs).

### Area 5 — Guide polish (D-22–D-27)

1. Surgical edits only — no full prose audit.
2. Gates: `mix docs.contract` 8/8, `missing` 0, both validates, GUARDRAIL-02 audit, guardrails contract test.
3. Extend docs-contract path asserts; optional deferral substring test.

### Area 6 — Explicitly out (D-28–D-32)

- No `mix rendro.viewer_evidence init`
- No Hex `files:` for `priv/viewer_evidence/` or `priv/support_matrix.json`
- No promote `viewer-evidence-live-proof` to required
- Required-checks baseline is **IN** (not optional)

---

## 4. File-by-File Change Map

| File | Action | Details |
|------|--------|---------|
| `priv/guardrails/required_status_checks.json` | **Create** | Normalized baseline per §2.6 |
| `test/guardrails/required_checks_contract_test.exs` | **Create** | Offline ci.yml + verify_docs wiring per §2.8 |
| `scripts/audit_branch_protection.exs` | **Create** | Live GitHub audit per §2.7 |
| `lib/mix/tasks/rendro/viewer_evidence.ex` | **Modify** | `--strict` flag on `validate` |
| `lib/rendro/viewer_evidence/validator.ex` | **Modify** (optional) | `strict:` opt on `run_full` if cleaner than task-level reclassification |
| `test/mix/tasks/viewer_evidence_task_test.exs` | **Modify** | `--strict` exit code tests |
| `guides/viewer_evidence.md` | **Modify** | Phase 71 automated path, Appendix D `--strict`, stale manual steps |
| `guides/api_stability.md` | **Modify** | Drift-fix only if deferral/substring test finds gaps |
| `test/docs_contract/viewer_evidence_claims_test.exs` | **Modify** | Missing supported path asserts; optional deferral mirror |
| `test/docs_contract/branding_claims_test.exs` or new test | **Modify** (optional) | Negative hex.build excludes operator priv paths |
| `CHANGELOG.md` | **Modify** | 0.3.0 freeze + 0.3.1 section per D-13 |
| `mix.exs` | **Modify** | `@version "0.3.1"` |
| `.github/workflows/release.yml` | **Modify** (optional) | Add `mix release.preflight` step |
| `.planning/phases/72-.../72-VERIFICATION.md` | **Create** | Closure ledger per §2.9 |
| `.planning/phases/69-.../69-VERIFICATION.md` | **Create** (if needed) | Milestone audit backfill |
| `.planning/phases/71-.../71-VERIFICATION.md` | **Create** (if needed) | Milestone audit backfill |

**Explicitly do NOT modify:**

- `priv/support_matrix.json` cell statuses (closure only audits)
- `.github/workflows/ci.yml` required job semantics (additive advisory job already present)
- Branch protection settings (already correct; audit verifies)
- `mix.exs` `package/0` `files:` list (operator priv stays repo-only)

---

## 5. Recommended Plan Split

Per D-32 discretion — one auditable closure wave on `main`, internal plan split acceptable:

| Wave | Plan ID | Deliverable | Blocking? |
|------|---------|-------------|-----------|
| **W1 — Guardrails contract** | 72-01 | JSON baseline + offline contract test + audit script | Blocks GUARDRAIL-02 close |
| **W2 — Staleness gate + ledger** | 72-02 | `--strict`, `72-VERIFICATION.md` draft with CLI + audit outputs | Blocks ship ritual |
| **W3 — Polish + publish** | 72-03 | Guide fixes, docs-contract hardening, CHANGELOG/0.3.1, optional hex negative test + release.yml | Single public-contract + Hex wave |

**Verification gate before merge:**

```bash
mix test test/guardrails/required_checks_contract_test.exs
mix rendro.viewer_evidence missing          # exit 0
mix rendro.viewer_evidence validate         # exit 0
mix rendro.viewer_evidence validate --strict # exit 0
GITHUB_TOKEN=... mix run scripts/audit_branch_protection.exs
mix docs.contract                           # 8/8
mix test test/docs_contract/
# Pre-tag:
mix run scripts/release_preflight_proof.exs --current-version-tag --worktree /tmp/rendro-preflight
```

---

## 6. Risks and Pitfalls

| Pitfall | Phase 72 risk | Mitigation |
|---------|---------------|------------|
| **#7 CI dilution (PITFALLS)** | Documenting wrong required-check list (`viewer-evidence-schema` as required) | D-07; baseline JSON `supersedes_planning_refs`; audit compares live GitHub |
| **v2.2 operational gap** | Checklist-only closure without live audit | D-01 B-lite + `audit_branch_protection.exs` + VERIFICATION snapshot |
| **Calendar bomb** | Wiring `--strict` into `mix ci` / branch protection | D-09 explicit opt-in only |
| **CHANGELOG semver lie** | 0.3.0 on Hex predates v2.3 viewer work | D-12/D-13 patch 0.3.1; do not re-tag 0.3.0 |
| **Preflight / CHANGELOG mismatch** | `release.preflight` expects `Unreleased` header | Date-stamp at tag or adjust tail check in same PR |
| **Fork PR CI** | GitHub API in `mix ci` | D-04 — audit script manual/close-only |
| **False green staleness** | Production dates fresh; `--strict` untested | Fixture with `recorded_at` >180 days in unit test |
| **Hand-maintained 26-row ledger** | VERIFICATION duplicates matrix | D-17 machine export + spot-check only |
| **Missing 69/71 VERIFICATION** | Milestone audit blocker | D-21 backfill before `/gsd-audit-milestone` |
| **Hex packages operator priv** | Adopters think they can record from Hex | Prerequisites in guide; optional negative tarball test |
| **release.yml lighter than CI** | Tag publish skips full preflight | D-14 optional `mix release.preflight` in release workflow |

---

## 7. Validation Architecture

Nyquist-oriented verification map: **how each deliverable is verified**, sampling, CI lanes.

| Deliverable | Verification method | Blocking? | CI lane |
|-------------|---------------------|-----------|---------|
| Matrix terminal state | `mix rendro.viewer_evidence list` + `missing` | Yes (closure gate) | Operator / VERIFICATION |
| Evidence structural honesty | `validate` + docs-contract lane 8 | Yes | `test` job → `mix test` |
| Staleness strict gate | `validate --strict` at ship | Yes (closure only) | **Not** in CI |
| Required-check JSON baseline | Contract test reads JSON + `ci.yml` | Yes | `test` job |
| Live branch protection | `audit_branch_protection.exs` + token | Yes (close ritual) | **Not** in default CI |
| GUARDRAIL-02 semantics | Offline test asserts behavioral commands unchanged | Yes | `test` job |
| Guide/matrix alignment | `viewer_evidence_claims_test.exs` + optional deferral mirror | Yes | `test` job |
| Hex publish integrity | `mix release.preflight` + `release.yml` | Yes | `release-proof` job + tag workflow |
| Operator priv excluded from Hex | Optional negative `hex.build` test | Advisory | `test` job |
| Trust-sensitive behavioral truth | Phase 71 live tests (advisory job) | Advisory on merge | `viewer-evidence-live-proof` |
| Signing / long-lived spine | Unchanged live-proof commands | Yes | required contexts |

**Test mapping (requirement → proof):**

| Requirement | Automated proof | Manual proof |
|-------------|-----------------|--------------|
| GUARDRAIL-02 lanes preserved | `required_checks_contract_test.exs` | Live audit script at close |
| GUARDRAIL-02 list grew never shrank | Baseline JSON `policy: additive_only` + live audit ⊇ baseline | VERIFICATION mapping table |
| No behavioral lane diluted | Contract test asserts `live_signing` / `live_pdf_tools` commands | Review `ci.yml` diff (should be empty for required jobs) |
| Viewer-evidence structural lane | Lane 8 + folded into `test` context | — |
| Milestone matrix closure | `missing` exit 0; `list` aggregates | Spot-check rows in VERIFICATION |
| Adopter contract gap closed | Hex 0.3.1 ships viewer claims | CHANGELOG accuracy review |

**CI lane topology (unchanged at close):**

```
branch protection (main)
  ├── test                    ← mix ci (+ docs-contract via mix test)
  ├── signing-live-proof      ← behavioral
  ├── long-lived-live-proof   ← behavioral
  └── release-proof           ← release_preflight_proof.exs

advisory (not required):
  └── viewer-evidence-live-proof
```

**Sampling strategy:**

- **100% automated** for committed contracts: JSON baseline, ci.yml wiring, docs-contract lanes, matrix JSV, promotion-complete.
- **100% at close** for live GitHub protection (single API call, normalized diff).
- **Spot-check (~8–12 rows)** for trust-sensitive cells in VERIFICATION — not 26-row hand table.
- **Human-only** for milestone archive tags (`v2.3`) — separate from Hex publish.

**Nyquist Dimension 8 note:** Staleness strictness is intentionally **operator/release-gated** (Browserslist precedent) — document in Validation Architecture that advisory vs blocking separation is product behavior, not a validation gap.

---

## 8. Open Questions for Planner Discretion (RESOLVED)

1. **`audit_branch_protection.exs` vs `mix rendro.guardrails.audit`:** Script-only keeps Mix task surface small; wrapper improves discoverability. *Default:* script + document in VERIFICATION; skip Mix task unless operator ergonomics demand it.

2. **VERIFICATION JSON embed:** Fenced paste of `list --json` vs `mix run scripts/embed_viewer_ledger.exs` generating compact table. *Default:* fenced JSON (audit packet immutability) with optional script if output size bothers reviewers.

3. **Negative hex.build test in Phase 72 vs v2.4:** Low cost, locks D-29 honesty. *Recommendation:* include in 72-03 if time permits.

4. **Deferral mirror test shape:** Substring ≥40 chars from matrix vs full reason match. *Default:* ≥40 chars per D-26 to tolerate prose editing.

5. **69/71 VERIFICATION backfill scope:** Full Nyquist replay vs lightweight PASS artifacts citing SUMMARY metrics. *Default:* lightweight PASS stubs before milestone audit — unblock `/gsd-audit-milestone`.

6. **`release.yml` preflight step:** Adds latency to publish; catches tag-only gaps. *Default:* add `mix release.preflight` per D-14 optional hardening — strong recommendation given 0.3.1 is adopter contract fix.

7. **CHANGELOG 0.3.0 historical content:** Need `git show v0.3.0:CHANGELOG.md` at execute time to split bullets accurately — planner should assign task to diff tag vs HEAD.

8. **PITFALLS.md edit in Phase 72:** CONTEXT implies reconcile drift in baseline/audit docs; editing `PITFALLS.md` itself is not listed in file map. *Default:* fix via `required_status_checks.json` `supersedes_planning_refs` + VERIFICATION note; optional follow-up doc PR.

---

## Canonical References for Planner

| Document | Use |
|----------|-----|
| `72-CONTEXT.md` | User decisions D-01–D-32 (binding) |
| `70-VERIFICATION.md` | Must-haves + automated checks format precedent |
| `68-CONTEXT.md` | D-17 staleness advisory; D-18 no new required check |
| `.planning/REQUIREMENTS.md` | GUARDRAIL-02 definition |
| `.planning/ROADMAP.md` | Phase 72 success criteria |
| `.planning/research/PITFALLS.md` | §7 CI dilution — reconcile at close |
| `.planning/milestones/v2.2-MILESTONE-AUDIT.md` | Branch protection closeout precedent |
| `priv/support_matrix.json` | Terminal 26-cell state |
| `.github/workflows/ci.yml` | Job names and commands for contract test |
| `test/docs_contract/branding_claims_test.exs` | hex.build tarball assertion pattern |

---

## RESEARCH COMPLETE
