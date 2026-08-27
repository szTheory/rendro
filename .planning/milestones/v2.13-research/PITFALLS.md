# Pitfalls Research

**Domain:** Stewardship of a deterministic PDF catalog, adoption ledger, and Phoenix evaluator journey
**Researched:** 2026-08-19
**Confidence:** HIGH for project-specific controls; MEDIUM for external-service behavior

## Evidence Classes Used Below

- **Deterministic gate:** reproducible repository check (schema, generated artifact, hash, manifest arithmetic, focused test).
- **Advisory evidence:** pinned renderer/viewer or network result; useful but never a substitute for a deterministic gate.
- **Human evidence:** named, bounded full-size visual review. It records judgment and provenance; it is not executable proof.

Suggested ownership: **Phase 130 — catalog quality/evidence ratchet** owns the twelve-cell work and its provenance. **Phase 131 — adoption refresh and Phoenix newcomer journey** owns pull-based demand review, runnable newcomer validation, and public-claim closure. If roadmap numbering changes, retain these ownership boundaries.

## Critical Pitfalls

### Pitfall 1: Subjective-score laundering

**What goes wrong:**
Scores are raised from `needs_work` to pass because a change appears improved, a reviewer remembers the prior render, or `passed: true` is treated as a separately editable assertion. A local repair is then described as a general design, accessibility, print, PDF/UA, WCAG, or universal-viewer result.

**Why it happens:**
The existing rubric deliberately includes human judgment, and the strict threshold makes a score increase feel like project completion. The Phase 127 record shows all twelve targeted cells fail because hierarchy is 4; the dark receipt also has affordance/craft/cohesion deficits. Visual comparison without an exact evidence identity invites confirmation bias.

**How to avoid:**
- Freeze the rubric dimensions and threshold arithmetic before editing; recompute `passed` only from dimensions and gates.
- Require one per-cell review record with the exact catalog ID, full PNG and source-PDF SHA-256, viewer/tool version, page, reviewer, review date, before/after rationale, and an explicit scope boundary.
- Review at readable native/full size in canonical family then light/dark order. Do not let contact-sheet thumbnails, generated prose, or a changed label act as a score source.
- Preserve lower scores where the evidence does not clear the strict bar; use `needs_work` rather than inventing partial success.

**Warning signs:**
- A changed `passed` field or quality label without changed dimensions and a matching review record.
- Generic justification such as “looks polished,” missing hashes, reviewer, or the exact cell.
- A score of 5 with no stated focal element and no comparative evidence; dark cells suddenly lose their screen-only disclosure.

**Verification hooks:**
- **Deterministic:** manifest-contract test recomputes verdicts; generator/check rejects catalog-to-rubric ID, hash, label, and disposition drift.
- **Human:** signed, per-cell full-size review explicitly records score deltas and holds negatives/limitations.

**Phase to address:** Phase 130.

---

### Pitfall 2: Artifact and provenance drift

**What goes wrong:**
The catalog JSON, raster/PDF bytes, hashes, rubric score file, SIGN-OFF table, and configurator index cease to describe the same render. A reviewer approves one artifact while a generator later publishes another, or an old PDF hash is attached to a new PNG.

**Why it happens:**
The catalog is a multi-hop pipeline: fixture → preset/recipe/font registration → deterministic PDF → pinned-PDFium PNG → manifest/rubric → static configurator. Previous work intentionally retained historical evidence references while layering bounded repair provenance, which makes an unstructured “refresh all files” especially hazardous.

**How to avoid:**
- Treat catalog generation as the sole writer for generated catalog fields; never hand-edit generated hashes, dimensions, renderer metadata, or quality labels.
- Add an explicit provenance map keyed by catalog ID that binds PNG hash, PDF hash, page/page-count, renderer pin, rubric record, sign-off record, and review date; make stale/missing links fail the check.
- Regenerate every affected artifact from a clean state, run byte/hash checks, and update source evidence and review text in the same narrowly scoped change.
- Keep historical and newly reviewed evidence distinguishable: say which bytes are current and which reference is retained only for contract compatibility.

**Warning signs:**
- `mix rendro.catalog.check` passes only after manually altering JSON; a SIGN-OFF hash prefix differs from `catalog.json`; unchanged hash paired with a claimed visual change.
- A review refers to “the catalog” rather than one ID/page/render pin; an exact preview is unavailable but a quality status changes.

**Verification hooks:**
- **Deterministic:** clean-generation/check command, SHA comparison, schema/manifest cross-reference test, and configurator index check.
- **Advisory:** pinned renderer output is labeled renderer-specific and recorded with version/pin, not promoted into byte determinism.
- **Human:** reviewer opens the hash-addressed current assets, not a browser-cache or thumbnail substitute.

**Phase to address:** Phase 130; Phase 131 must consume only the checked catalog.

---

### Pitfall 3: Treating advisory render tools as required, portable truth

**What goes wrong:**
An unavailable PDFium/Chromium/Playwright/container result blocks a deterministic catalog update, or a host-specific raster is blessed as the baseline. Conversely, an advisory viewer run is called a universal rendering or compliance guarantee.

**Why it happens:**
The Windows ledger documents real environment variance: the pinned Linux PDFium binary is unavailable on macOS ARM, ARM can need an x86 wrapper, and the project declares Linux CI as pixel authority for certain baselines. Renderer output is valuable visual evidence, but is not portable proof of PDF semantics.

**How to avoid:**
- Define deterministic completion without any host-specific external executable: fixture/render tests, generator/schema/hash/manifest checks, and documented expected bytes where applicable.
- Make the pinned Linux/container lane the sole baseline authority; local non-Linux output is diagnostic only and never committed as a replacement baseline.
- Preflight tool availability/version/pin and report `SKIPPED—environment` separately from `FAILED—artifact`. Do not auto-install binaries or silently bless fallbacks.
- Keep advisory output and human review in a separate CI lane/status from merge-blocking deterministic checks.

**Warning signs:**
- `PATH`/architecture errors interpreted as quality regressions; `*-darwin.png` appears in a diff; CI requirement says “PDFium must pass locally.”
- A document claims “renders everywhere,” “print-safe,” or “accessible” based solely on one renderer screenshot.

**Verification hooks:**
- **Deterministic:** host-independent test suite and generated-artifact checks pass with advisory tools absent.
- **Advisory:** pin/SHA and Linux/container provenance recorded; the lane reports unavailable/failed distinctly.
- **Human:** review notes identify the viewer/renderer and do not broaden it into compliance certification.

**Phase to address:** Phase 130, with the newcomer journey in Phase 131 tested independently of advisory binaries.

---

### Pitfall 4: Stale, unreviewable, or miscounted adoption evidence

**What goes wrong:**
The ledger repeats an old Hex snapshot as current, counts stars/reactions/generic i18n wishes, double-counts a requester, treats a PR as non-maintainer without review, or silently converts partial evidence into a trigger.

**Why it happens:**
The demand gate requires all three families in the same review window and has strict identity, organization/app, production/evaluation-blocker, time-window, download, and contributor rules. A quiet project naturally has sparse evidence, which pressures a reviewer to substitute easy-to-measure activity.

**How to avoid:**
- Treat the baseline and every snapshot as an immutable dated observation with source URL/API endpoint, query/filter, raw values, reviewer, and retrieval outcome.
- Re-evaluate every candidate against the written qualifying rules; count at most one requester/org/use case in the window and document rejections.
- Record an explicit `HOLD`, `HOLD-noise`, `ACCUMULATING`, or `TRIGGER` decision for each threshold family and the composite; do not infer “no change” from absence of a fetch.
- Link evidence instead of scraping/copying private data. Anonymized reports must state that they are private and remain subject to the existing cap.

**Warning signs:**
- A table with a new conclusion but no retrieval date/source URL; values that omit `downloads.week`; “interest” lacks job, script/language, blocker, and requester/org identity.
- A merged PR is counted without author/maintainer screening; data outside the same 90-day/review window is combined.

**Verification hooks:**
- **Deterministic:** ledger-format/decision-contract test checks required fields, threshold arithmetic, dates, duplicate count groups, and that no trigger is recorded with a missing family.
- **Advisory/network:** live Hex/GitHub result includes retrieval time, request URL/query, pagination/rate-limit outcome, and raw response digest; failures produce `UNAVAILABLE`, not zero.
- **Human:** maintainer signs the classification of qualifying/rejected signals and contributor identity/materiality.

**Phase to address:** Phase 131.

---

### Pitfall 5: Accidental outreach or telemetry expansion

**What goes wrong:**
“Refresh adoption” turns into campaigns, unsolicited contact, tracking pixels/private analytics, social-counter collection, or automated issue/PR labeling/comments. This violates the deliberately quiet, pull-based posture and can fabricate demand.

**Why it happens:**
Adoption work is often equated with growth activity, whereas this milestone asks only to refresh reviewable evidence and decide whether a demand gate moves.

**How to avoid:**
- Put an explicit non-goals contract in the plan and acceptance tests: no outreach, announcements, marketing automation, private analytics, social counters, or GitHub writes.
- Use read-only public queries and existing inbound reports; require explicit maintainer action for any label/change, with a recorded rationale.
- Make collection scripts default to dry-run/read-only and redact or avoid personal data not needed for the counting rules.

**Warning signs:**
- New API tokens with write scopes; workflow steps posting comments/labels; a “refresh” task contains recipient lists, tracking IDs, or scheduling.
- Ledger signals appear immediately after activity initiated by the project rather than inbound demand.

**Verification hooks:**
- **Deterministic:** review diff/workflow/scripts for forbidden write endpoints, telemetry dependencies, tracking assets, and `gh issue/PR edit` calls; test read-only mode.
- **Human:** maintainer confirms the review was pull-based and each ledger action is an observation, not a solicitation.

**Phase to address:** Phase 131.

---

### Pitfall 6: A Phoenix newcomer journey that proves only the maintainer environment

**What goes wrong:**
Docs and Livebook appear coherent, but a clean Phoenix developer cannot discover the right dependency, install it, choose/customize a catalog example, generate an output, or verify what is deterministic versus advisory. A checked-in `_build`, local path dependency, cached docs, or preinstalled Node tool masks the failure.

**Why it happens:**
Existing flows already span guide → canonical snippet → Livebook conversion/execution → themed PDF/download, plus a static browse/pick/copy surface. They can be individually green while their handoff, package surface, or fresh-project assumptions drift.

**How to avoid:**
- Specify a clean-room, time-bounded newcomer script: public discovery page → dependency/install → Phoenix-compatible invocation with no Phoenix hard dependency in core → one catalog choice → deliberate customization → PDF artifact → deterministic verification command and clear advisory boundary.
- Use only published/public inputs and a temporary clean project/cache policy; enumerate prerequisites and give a bounded failure diagnostic for missing optional tools.
- Assert copied snippets equal canonical formatter output and test links/routes/assets from the public entry point, not only source files.

**Warning signs:**
- Steps say “run the example” without package/version, expected output, cleanup, or explanation of which verification is authoritative.
- Test passes only with repository checkout, local assets, existing Mix cache, or a local browser/PDFium installation.
- Phoenix wording implies a runtime Phoenix dependency or server requirement in Rendro core.

**Verification hooks:**
- **Deterministic:** isolated install/compile/run fixture, canonical-snippet equality, generated PDF assertion, docs-link/asset tests, and absence of core Phoenix dependency.
- **Advisory:** optional browser/Livebook exercise reports environment/version and never gates the core path.
- **Human:** a reviewer follows the public instructions cold and records friction, ambiguity, and the exact command/output.

**Phase to address:** Phase 131; Phase 130 must stabilize the catalog API/evidence it uses first.

---

### Pitfall 7: Over-broad cleanup disguised as stewardship

**What goes wrong:**
A focused twelve-cell/ledger/journey milestone reformats unrelated source, regenerates every launch asset, modifies core layout or rendering behavior, removes old evidence, or “fixes” open Windows ledger entries that were intentionally scoped/deferred. Regression surface expands far beyond the stated goal.

**Why it happens:**
Quality work crosses generated artifacts and docs; old anomalies look tempting to repair. Yet this milestone explicitly adds no core capability family, and the prior audit preserves catalog isolation, no hard Phoenix/Node runtime dependency, and separate deterministic/advisory lanes.

**How to avoid:**
- Begin each task with an allowlist of catalog IDs, evidence files, journey docs/tests, and generated outputs; require justification for any source/layout/runtime diff.
- Keep cleanup mechanical and reversible, in a separately reviewed commit/plan only if it directly unblocks an acceptance criterion.
- Preserve the Windows ledger’s ownership/status semantics; do not close an item merely because a related artifact changed.

**Warning signs:**
- A quality-only change touches unrelated recipe rendering, core dependencies, lockfiles, or broad image directories.
- “Regenerate all” produces large unrelated hash churn; a window is closed without exact reproduction, deterministic test, and appropriate approval.

**Verification hooks:**
- **Deterministic:** path/diff allowlist, focused regression matrix for impacted recipes, catalog check, and full required CI lane.
- **Human:** reviewer approves scope exceptions and verifies open-window status remains truthful.

**Phase to address:** Phase 130 for catalog scope; Phase 131 for docs/adoption scope.

---

### Pitfall 8: Documentation overclaims and boundary erasure

**What goes wrong:**
Upgraded catalog labels or a successful newcomer path are marketed as universal quality, accessibility, PDF/UA, WCAG, print safety, browser parity, global text shaping, or “production-ready for every document.” The adoption decision is also phrased as demand validation when the gate is actually still blocked.

**Why it happens:**
“Pass,” “verified,” and screenshots are easily read as broader product claims. Current artifacts intentionally bound dark cells as screen-oriented, define the catalog as a limited human review, and keep shaping behind a conditional gate.

**How to avoid:**
- Define permitted claim language beside each evidence class. Every quality/copy change must state artifact scope, reviewer/tool scope, and exclusions.
- Keep the exact dark-cell boundary disclosure unless a separately supported print claim exists; do not delete negative evidence to make catalog cards cleaner.
- Contract-test docs/README/Hex/ExDoc/configurator copy against a denylist of unsupported claims and a required-boundaries list.
- State adoption outcomes as the recorded decision (`HOLD`, `ACCUMULATING`, or `TRIGGER`) with threshold evidence, not a narrative of momentum.

**Warning signs:**
- Bare terms such as “accessible,” “standards-compliant,” “works in all viewers,” “print-ready,” or “shaping supported” without narrowly matching proof.
- A status goes green while boundaries/exclusions disappear; docs disagree with the manifest or ADOPTION ledger.

**Verification hooks:**
- **Deterministic:** docs-contract tests scan public surfaces for banned overclaims and required boundary wording; links and code snippets remain checked.
- **Human:** claim review compares every sentence with the specific artifact, deterministic test, advisory run, or signed review it cites.

**Phase to address:** Phase 131, with Phase 130 preserving catalog-boundary metadata.

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|---|---|---|---|
| Hand-edit generated catalog hashes/statuses | Fast-looking release | Provenance becomes unverifiable and next generation overwrites it | Never |
| One composite screenshot for 12 cells | Cheap review | Hides text fit, hierarchy, and dark-cell defects | Only as navigation before full-size per-cell review |
| Make PDFium/Chromium mandatory on every host | Simple binary pass/fail story | Blocks valid work on unsupported hosts and confuses advisory evidence with correctness | Never; pin it as an advisory/Linux-authority lane |
| Record only latest adoption totals | Small ledger | Cannot establish baseline, threshold window, or source audit trail | Never |
| Turn refresh scripts into API writers | Faster triage | Accidental outreach/labels and unreproducible state | Never without explicit separate authorization |
| Broad regeneration/cleanup | Fewer apparent loose ends | Unrelated hash churn and core regressions | Only when diff allowlist and evidence show it directly unblocks a milestone criterion |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|---|---|---|
| Catalog generator ↔ rubric ↔ static configurator | Updating only the visible catalog label | Bind ID/hash/disposition across generated manifest, rubric and index; run generation/check before review |
| Pinned PDFium/Chromium ↔ CI | Assuming local host pixels equal the Linux baseline | Keep a SHA-pinned Linux/container authority; local runs are diagnostic, and unavailable tools are reported separately |
| Hex/GitHub public APIs ↔ adoption ledger | Treating partial, paginated, rate-limited output as zero or complete | Capture query/date/pagination/rate-limit status; use `UNAVAILABLE` and retain prior observation rather than inventing a value |
| GitHub issue list ↔ contributor count | Counting PRs returned by Issues endpoints or skipping labels/pages | Use PR-specific review/query, follow pagination, and screen maintainer/bot/materiality explicitly |
| Docs/configurator/Livebook ↔ Phoenix path | Testing source snippets rather than the public copied path | Verify public link → copied canonical snippet → clean project artifact, with optional tools clearly optional |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|---|---|---|---|
| Rendering all catalog cells repeatedly while tuning one | Slow reviews and accidental global churn | Target the twelve IDs; run full generation only at controlled checkpoints | Immediately on constrained CI/ARM hosts |
| Unbounded public API scans | Rate-limit responses, slow reviews, incomplete lists | Use exact labels/date window, pagination, cached dated observations, and bounded retry/backoff | As issue/PR history grows or unauthenticated limits are reached |
| Browser/PDFium installed in the main test path | Newcomer CI fails before core tests | Isolate optional tools in advisory lanes; preflight and skip with reason | Any environment missing the pin/runtime |

## Security and Privacy Mistakes

| Mistake | Risk | Prevention |
|---|---|---|
| Copying private adopter identity or document details into a public ledger | Privacy breach and trust loss | Store only allowed anonymized aggregate evidence; link public sources and cap private counts |
| Using write-scoped tokens for a read-only adoption refresh | Accidental labels/comments/outreach | Use unauthenticated/read-only queries where possible; no token in scripts/logs; explicit authorization for any write |
| Running unpinned downloaded renderer binaries | Supply-chain and misleading evidence risk | Verify the existing pin/SHA and keep binaries outside the deterministic core lane |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---|---|---|
| “Scored” card without a scope/boundary | Evaluators infer guarantees Rendro does not make | Pair disposition with concise evidence scope and dark-mode screen-only disclosure |
| Newcomer guide hides the verification boundary | User mistakes a PDF download for a universal quality claim | Explain the deterministic command, then label viewer/visual review as advisory/bounded |
| Catalog customization path does not name canonical source | Copied code drifts from generator/Livebook output | Make the public path emit and test the one canonical formatter/snippet |

## Looks Done But Isn't Checklist

- [ ] **Each of 12 cells:** status, score dimensions, calculated verdict, current PNG/PDF hashes, renderer pin, and review record all agree.
- [ ] **Quality uplift:** a named full-size reviewer saw the exact current asset; no quality/compliance generalization was introduced.
- [ ] **Advisory lane:** unavailable PDFium/Chromium is reported separately from deterministic success/failure; no host-specific baseline was blessed.
- [ ] **Adoption refresh:** every source observation is dated/reviewable and every threshold family has an explicit decision; unavailable network data is not zero.
- [ ] **Pull-based posture:** no telemetry, campaign, social count, automated label/comment, or other outbound/write action was added.
- [ ] **Phoenix newcomer journey:** a clean public install/copy/customize/render/verify path succeeds without a core Phoenix/Node/browser dependency.
- [ ] **Public copy:** docs, configurator, and ledger retain bounded quality, dark-mode, and shaping-gate language.
- [ ] **Scope:** any changed path outside the allowlist is justified against an acceptance criterion; open Windows entries remain accurately open.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---|---|---|
| Score laundering | MEDIUM | Revert disposition/claims, restore calculated values, regenerate from source, and redo a hash-addressed independent review |
| Provenance drift | HIGH | Stop publication, identify last consistent generated commit, regenerate cleanly, reconcile all references, and append a correction record rather than silently rewriting history |
| Advisory environment failure | LOW/MEDIUM | Mark advisory lane unavailable, preserve deterministic results, use declared Linux/container authority later, and do not bless local substitutes |
| Miscounted/stale adoption data | MEDIUM | Mark the review superseded, retain raw dated observation, correct count groups/decision, and re-run qualifying review without outreach |
| Accidental outreach/write | HIGH | Stop automation, disclose/revert the external action where possible, remove credentials, document impact, and return to read-only pull-based collection |
| Newcomer journey failure | MEDIUM | Reproduce in a clean fixture, fix the first public handoff, add a regression test, and update prerequisites/boundaries without broadening core dependencies |
| Documentation overclaim | HIGH | Remove/correct claim promptly, restore required boundary text, add a contract test, and link the corrected claim to its exact evidence class |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---|---|---|
| Subjective-score laundering | 130 — catalog quality/evidence ratchet | Calculated manifest verdict plus hash-addressed human per-cell sign-off |
| Artifact/provenance drift | 130 — catalog quality/evidence ratchet | Clean generator/check, schema/hash cross-reference, exact review asset |
| Advisory tool/host dependence | 130 — catalog quality/evidence ratchet | Core deterministic lane green without tools; pinned advisory lane reports provenance/availability |
| Over-broad catalog cleanup | 130 — catalog quality/evidence ratchet | Diff allowlist, focused matrix, scope approval |
| Stale/unreviewable adoption evidence | 131 — adoption refresh/newcomer journey | Dated source ledger, threshold/decision contract, human classification review |
| Accidental outreach/telemetry | 131 — adoption refresh/newcomer journey | Read-only script/workflow audit and maintainer pull-based attestation |
| Phoenix path works only locally | 131 — adoption refresh/newcomer journey | Clean public install/copy/customize/render/verify fixture and cold human walkthrough |
| Documentation overclaims | 131 — adoption refresh/newcomer journey | Public-copy contract tests plus evidence-to-claim review |

## Sources

- Project evidence: [ADOPTION.md](../../ADOPTION.md), reviewed 2026-08-19 — HIGH.
- Project evidence: [Windows ledger](../WINDOWS.md), reviewed 2026-08-19 — HIGH.
- Project evidence: [v2.12 milestone audit](../milestones/v2.12-MILESTONE-AUDIT.md), reviewed 2026-08-19 — HIGH.
- Project evidence: [catalog manifest](../../assets/rendro/catalog.json), [rubric manifest](../../priv/quality/rubric_scores.json), and [reader-quality sign-off](../../priv/quality/SIGN-OFF.md), reviewed 2026-08-19 — HIGH.
- External operational evidence: [GitHub REST API rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api), [pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api), and [issues endpoint behavior](https://docs.github.com/en/rest/issues/issues) — MEDIUM for project application.

---
*Pitfalls research for: Rendro v2.13 Quality Ratchet & Adoption Readiness*
*Researched: 2026-08-19*
