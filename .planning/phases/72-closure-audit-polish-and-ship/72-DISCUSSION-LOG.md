# Phase 72: Closure — Audit, Polish, and Ship - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 72-closure-audit-polish-and-ship
**Areas discussed:** Required-check audit capture, Staleness enforcement at ship, Ship mechanics, Verification ledger depth, Guide polish bar, Deferred polish items

**Mode:** User requested research-backed recommendations for all areas (subagent research + prompts cross-reference); Claude synthesized coherent locked decisions without further user Q&A.

---

## Required-check audit capture

| Option | Description | Selected |
|--------|-------------|----------|
| A — Manual `gh api` snapshot in VERIFICATION only | Point-in-time attestation; no drift detection | Partial (ledger supplement) |
| B — Committed baseline JSON + diff audit | `priv/guardrails/required_status_checks.json` + offline test + live audit script | ✓ |
| C — Human checklist only | Honor-system tick boxes | |

**User's choice:** B-lite + A (committed minimal contract + offline ExUnit wiring test + live audit script at close + milestone snapshot in VERIFICATION)
**Notes:** v2.2 showed artifact closure ≠ operational closure. Elixir OSS libs (Ecto, Phoenix, Oban) don't commit branch protection — Rendro is an outlier because signing/live-proof lanes are product behavior. BCD/caniuse pattern: commit contract, validate in CI, diff at close — not audit GitHub settings on every PR. Baseline minimum: `test`, `signing-live-proof`, `long-lived-live-proof`, `release-proof`. `viewer-evidence-live-proof` stays advisory (Phase 68 D-18). Fix PITFALLS drift on separate `viewer-evidence-schema` required check.

---

## Staleness enforcement at ship

| Option | Description | Selected |
|--------|-------------|----------|
| A — `--strict` local/closure audit only | Implement flag; advisory default on PRs | ✓ |
| B — Wire into docs-contract / CI | Calendar-bomb on `main` every 180 days | |
| C — Advisory-only forever | No `--strict`; D-17 Phase 72 unimplemented | |

**User's choice:** A — implement `mix rendro.viewer_evidence validate --strict` (staleness fatal); keep default advisory; run both at Phase 72 close; document Appendix D in guide
**Notes:** Browserslist/npm/RubyGems/Elixir precedent: structural honesty merge-blocking, temporal refresh operator-owned. GUARDRAIL-02 is CI-lane preservation, not staleness — do not conflate.

---

## Ship mechanics

| Option | Description | Selected |
|--------|-------------|----------|
| A — Full Hex publish 0.3.0 via release-please | Not viable — 0.3.0 already on Hex at `ba023c9` | |
| B — Git tag only, defer Hex | Leaves adopter contract gap | |
| C — Verification artifacts only | Audit without matching Hex artifact | |
| D — Ship `v0.3.1` via existing tag workflow | CHANGELOG split; `release.preflight`; separate from `v2.3` milestone tag | ✓ |

**User's choice:** D — Phase 72 owns `0.3.1` Hex publish; `/gsd-complete-milestone` owns `v2.3` planning tag only. Order: Phase 72 → audit-milestone → complete-milestone.
**Notes:** Jason/ExDoc lesson: published package is the contract surface. `0.3.0` CHANGELOG must be frozen as published; v2.3 viewer work moves to `0.3.1` patch section.

---

## Verification ledger depth

| Option | Description | Selected |
|--------|-------------|----------|
| A — Hand-written 26-cell table | Full ledger but drifts from matrix | |
| B — Summary + trust-sensitive spot-check only | Too thin for milestone close | Partial |
| C — Machine-verifiable only (Phase 70 style) | Best agent ergonomics; misses ROADMAP ledger wording | Partial |
| Hybrid B+C | JSON export + spot-check + must-haves + GUARDRAIL table | ✓ |

**User's choice:** Hybrid — `list --json` as canonical ledger in VERIFICATION; 8–12 trust-sensitive spot-check rows; Phase 70 must-haves table; defer `v2.3-MILESTONE-AUDIT.md` regen to `/gsd-audit-milestone`

---

## Guide polish bar

| Option | Description | Selected |
|--------|-------------|----------|
| A — Full prose audit pass | High cost; dual-source drift risk | |
| B — Docs-contract green + drift-fix | Machine-led, surgical | ✓ (B+) |
| C — Matrix truth if green | Blind spots on Phase 71 recording path | |

**User's choice:** B+ — extend `viewer_evidence.md` Automated path for Phase 71 trust-sensitive CI recording; drift-fix `api_stability.md`; harden path asserts in docs-contract; skip stylistic rewrites
**Notes:** MDN BCD separation preserved — matrix = claim, evidence = observation, guide = procedure.

---

## Deferred polish items

| Item | IN Phase 72? | Selected |
|------|--------------|----------|
| `mix rendro.viewer_evidence init` | No | OUT → v2.4 |
| Hex `files:` for `priv/viewer_evidence/` | No | OUT (repo-checkout model) |
| Negative hex.build exclusion test | Optional | IN if trivial |
| Committed required-checks baseline | Yes | IN (GUARDRAIL-02) |
| Promote `viewer-evidence-live-proof` to required | No | OUT at close |

**User's choice:** Per table above — closure verifies and ships, does not expand operator surface area.

---

## Claude's Discretion

- Guardrail script vs Mix task naming
- VERIFICATION JSON embedding mechanism
- Plan split across 72-01/02/03
- Whether negative hex.build test ships in 72 or later

## Deferred Ideas

- release-please adoption
- Scheduled branch-protection drift CI
- `validate --strict` in release.preflight (optional post-v2.3)
- Full Hex operator workspace packaging (matrix + schemas + evidence together)
