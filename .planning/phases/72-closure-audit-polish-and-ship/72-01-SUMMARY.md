---
phase: 72-closure-audit-polish-and-ship
plan: 01
subsystem: testing
tags: [guardrails, ci, github, branch-protection, contract-test, elixir]

requires:
  - phase: 71-record-new-trust-sensitive-surfaces-and-explicit-deferrals
    provides: Terminal 26-cell matrix and advisory viewer-evidence-live-proof CI job
provides:
  - Committed v2.3 required-check baseline JSON
  - Offline fork-safe CI wiring contract test
  - Live branch-protection audit script for close ritual
affects:
  - 72-02-verification-ledger
  - 72-03-guide-polish-and-ship
  - GUARDRAIL-02

tech-stack:
  added: []
  patterns:
    - "Machine-readable priv/guardrails baseline + offline contract test + close-only live audit script"
    - "Additive-only branch protection policy documented in JSON with supersedes_planning_refs"

key-files:
  created:
    - priv/guardrails/required_status_checks.json
    - test/guardrails/required_checks_contract_test.exs
    - scripts/audit_branch_protection.exs
  modified: []

key-decisions:
  - "Standalone scripts/audit_branch_protection.exs using Req instead of mix rendro.guardrails.audit wrapper"
  - "Fork-safe self-check uses word-boundary and split-string patterns to avoid false positives on 'required' substrings"

patterns-established:
  - "GUARDRAIL-02 B-lite: committed JSON baseline, offline wiring proof in mix test, live GitHub audit at close only"
  - "viewer-evidence-live-proof documented as advisory; structural enforcement folded into test context per Phase 68 D-18"

requirements-completed: [GUARDRAIL-02]

duration: 15min
completed: 2026-05-29
---

# Phase 72 Plan 01: GUARDRAIL-02 Durable Baseline Summary

**Committed required-check contract with offline CI wiring proof and close-ritual live branch-protection audit script — four sorted required contexts on main, advisory viewer-evidence-live-proof, PITFALLS §7 drift corrected via supersedes_planning_refs.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-29T12:30:00Z
- **Completed:** 2026-05-29T12:45:00Z
- **Tasks:** 3 completed
- **Files modified:** 3 created

## Accomplishments

- Landed `priv/guardrails/required_status_checks.json` as the single source of truth for v2.3 close required contexts (`test`, `signing-live-proof`, `long-lived-live-proof`, `release-proof`) with `strict: true`, `policy: additive_only`, and per-context semantic class + command mapping.
- Added `test/guardrails/required_checks_contract_test.exs` — 11 fork-safe assertions covering JSON integrity, `ci.yml` job wiring, behavioral command strings, eight docs-contract lanes, and `mix ci` alias steps.
- Implemented `scripts/audit_branch_protection.exs` — fetches live GitHub protection via Req, normalizes `{strict, contexts}`, fails on gaps; excluded from `mix ci`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create required-check baseline JSON** - `b983681` (feat)
2. **Task 2: Add offline required-checks contract test** - `30be35e` (test)
3. **Task 3: Implement live branch-protection audit script** - `405b876` (feat)

**Plan metadata:** pending (docs commit after STATE/ROADMAP update)

## Files Created/Modified

- `priv/guardrails/required_status_checks.json` — v2.3 close baseline with four required contexts, advisory `viewer-evidence-live-proof`, and `supersedes_planning_refs`
- `test/guardrails/required_checks_contract_test.exs` — offline GUARDRAIL-02 wiring contract (no GitHub API)
- `scripts/audit_branch_protection.exs` — close-ritual live audit comparing live protection ⊇ baseline

## Decisions Made

- Used standalone `scripts/audit_branch_protection.exs` per plan default (no Mix task wrapper) to keep surface area small.
- Advisory job command in JSON uses explicit seven-file list from `ci.yml` rather than glob shorthand for contract fidelity.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fork-safe self-check false positives**
- **Found during:** Task 2 (offline contract test)
- **Issue:** Literal `refute source =~ "Req"` and `"gh api"` matched substrings in `required` and the assertion lines themselves.
- **Fix:** Switched to `\bReq\.` word boundary and `Enum.join` for `gh api` / `GITHUB_TOKEN` patterns.
- **Files modified:** `test/guardrails/required_checks_contract_test.exs`
- **Verification:** `mix test test/guardrails/required_checks_contract_test.exs` — 11 tests, 0 failures
- **Committed in:** `30be35e` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Minor test harness fix only; no scope or semantics change.

## Issues Encountered

None beyond the self-check false-positive fixed during Task 2.

## User Setup Required

None for offline contract test. Live audit requires `GITHUB_TOKEN` with repo admin read — documented in script moduledoc; capture deferred to 72-02.

## Verification

```bash
python3 -c "import json; d=json.load(open('priv/guardrails/required_status_checks.json')); assert d['strict']==True; assert d['required_contexts']==sorted(['test','signing-live-proof','long-lived-live-proof','release-proof']); assert len(d['contexts'])==4"
# JSON OK

mix test test/guardrails/required_checks_contract_test.exs
# 11 tests, 0 failures

mix compile && elixir -e 'content=File.read!("scripts/audit_branch_protection.exs"); if content =~ "mix ci", do: raise("found"); if not (content =~ "required_status_checks.json"), do: raise("missing"); IO.puts("OK")'
# audit script static check OK
```

## Self-Check: PASSED

- All three task artifacts exist on disk
- Three atomic task commits present (`b983681`, `30be35e`, `405b876`)
- Contract test green (11/11)
- JSON parses with four sorted required contexts
- Audit script references baseline JSON and is absent from `mix ci`

## Next Phase Readiness

- Ready for 72-02: run live audit with token and capture snapshot in `72-VERIFICATION.md`; implement `validate --strict`.
- GUARDRAIL-02 durable baseline is committed; live operational proof is the 72-02 close ritual.

---
*Phase: 72-closure-audit-polish-and-ship*
*Completed: 2026-05-29*
