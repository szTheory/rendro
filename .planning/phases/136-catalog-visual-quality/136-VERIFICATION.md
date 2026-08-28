---
phase: 136-catalog-visual-quality
verified: 2026-08-28T17:53:52Z
status: gaps_found
score: 0/4 must-haves verified
behavior_unverified: 9
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 2/4
  gaps_closed: []
  gaps_remaining:
    - "No current exact-SHA, pinned-renderer, six-target human review meets the frozen threshold."
    - "No changed target has complete exact review and canonical-publication provenance."
  regressions: []
gaps:
  - truth: "The only visually changed cells are the six locked Phase 136 targets."
    status: failed
    reason: "Rendering every catalog source PDF against the committed baseline produces five changed IDs, not six: Brutalist Ticket light is byte-stable. The candidate classifier nevertheless requires all six in changed_scored and also couples deterministic scope to prior reviewer status."
    artifacts:
      - path: "lib/rendro/recipes/ticket.ex"
        issue: "The light target's profile treatment does not change its deterministic source-PDF bytes."
      - path: "dev/rendro/catalog.ex"
        issue: "valid_candidate_diff/1 requires six changed_scored IDs, while candidate_status/3 derives that deterministic bucket from advisory review_status."
    missing:
      - "Make the declared target set match real byte behavior without manufacturing drift, and test it by rendering the real catalog against the committed baseline."
      - "Separate exact changed-target classification from scored/unscored reviewer state."
  - truth: "Exact-SHA pinned-renderer evidence and human review give every target hierarchy 5 and every other scored dimension at least 4; misses remain unpromoted."
    status: failed
    reason: "The durable Phase 136 record still says all six targets are unreviewed/unpromoted. Existing Phase 130 records are historical and several target dimensions remain below 4. The convenience gallery is explicitly non-authoritative."
    artifacts:
      - path: "priv/quality/SIGN-OFF.md"
        issue: "Lines 148-175 record the failed run, zero artifacts, and all six targets unreviewed/unpromoted."
      - path: "priv/quality/rubric_scores.json"
        issue: "Contains historical Phase 130 records, not six Phase 136 candidate-bound reviews."
    missing:
      - "One semantically validated exact-SHA review bundle and six complete named reviewer records over hash-bound full-size images."
      - "Actual threshold results retained verbatim, including any miss."
  - truth: "The catalog remains 32 cells with 20 explicitly unscored entries, and every dark record has print_safety:false without broader claims."
    status: failed
    reason: "The 32/20 counts and claim boundary hold, but seven dark unscored dispositions omit print_safety entirely. Plan 01 explicitly says absence is not a passing default; tests weaken the contract by accepting an unscored reason instead."
    artifacts:
      - path: "priv/quality/rubric_scores.json"
        issue: "Seven dark unscored records have no gate_results.print_safety value."
      - path: "test/rendro/catalog_test.exs"
        issue: "The dark-record assertion accepts a reason-only unscored branch instead of requiring boolean false."
    missing:
      - "Represent screen-only print_safety:false for every dark record without promoting unscored visual quality, or obtain an explicit accepted override that changes the roadmap contract."
  - truth: "Every changed record is traceable through source SHA, renderer identity, artifact hashes, human review, and canonical publication provenance."
    status: failed
    reason: "No Phase 136 review/publication records exist, and the current evidence/canonical path is not trustworthy or runnable: count-only validation accepts arbitrary payload identities, the real canonical catalog is rejected as invalid_payload_counts, candidate baseline_commit_sha is set to the candidate SHA, and canonical rollback can delete untouched assets."
    artifacts:
      - path: "dev/rendro/catalog_evidence_bundle.ex"
        issue: "Payload validation checks roles/counts/hashes but not internal catalog IDs, candidate/renderer identities, paths, or cross-payload bindings; canonical/catalog.json is read from images instead of cells."
      - path: ".github/workflows/catalog-evidence.yml"
        issue: "The canonical job still runs jq length on the top-level object and trusted control delegates semantic validation to the count-only bundle validator."
      - path: "dev/rendro/catalog.ex"
        issue: "baseline_commit_sha is false provenance and rollback deletes canonical paths regardless of which rename completed."
    missing:
      - "Closed schema/identity validation for every payload and cross-payload binding to trusted candidate/control/renderer facts."
      - "A real-catalog canonical payload contract, truthful baseline identity, and fault-injected transactional rollback tests."
      - "Six exact human reviews and a successful canonical publication chain after deterministic fixes."
  - truth: "Payslip partial and zero/one/many behavior remains the structured sequential-ledger contract for valid inputs."
    status: failed
    reason: "A valid earnings line with optional ytd omitted raises KeyError in the sequential profile; the selected 282-test phase suite does not cover this path."
    artifacts:
      - path: "lib/rendro/recipes/payslip.ex"
        issue: "ledger_table/12 and money_column_width/4 dereference line.ytd directly despite validation allowing omission/nil."
      - path: "test/rendro/recipes/payslip_test.exs"
        issue: "No sequential-profile regression covers omitted or nil ytd."
    missing:
      - "Use Map.get plus the existing blank formatter in rendering and measurement, with omitted/nil YTD end-to-end tests."
behavior_unverified_items:
  - truth: "Long Invoice facts/items retain deterministic wrapping, geometry, pagination, and caller text under the semantic profile."
    test: "Render held-out long Invoice facts/items twice with semantic_ink:primary_secondary and inspect measured layout/pagination."
    expected: "Bytes match across runs; caller text, geometry, wrapping, and pagination are preserved without clipping."
    why_human: "No active test combines held-out long Invoice content with the Phase 136 profile."
  - truth: "Long Invoice labels/facts retain deterministic measured wrapping without clipping or caller-text changes."
    test: "Exercise the longest independent Invoice label/fact corpus through the profiled render."
    expected: "Measured wrapping preserves complete text and fit."
    why_human: "Only ordinary profile fixtures are tested."
  - truth: "Long Statement ledger facts retain deterministic wrapping, geometry, and pagination under the semantic profile."
    test: "Run a held-out multi-page Statement through semantic_ink:primary_secondary twice."
    expected: "Complete text and geometry are preserved and both renders are byte-identical."
    why_human: "Multi-page determinism is tested only on the default path, not the Phase 136 profile."
  - truth: "Long Statement descriptions/context retain measured wrapping without clipping or caller-text changes."
    test: "Exercise held-out long descriptions and context under the profile."
    expected: "Text is complete and measured into valid regions without clipping."
    why_human: "No held-out profiled test exercises this invariant."
  - truth: "Payslip partial sequential sections allow asymmetric row counts without fake rows."
    test: "Run sequential_measured with one table shorter/empty and valid optional fields."
    expected: "Independent ordered sections render without placeholders and reconciliation remains present."
    why_human: "Existing asymmetric/empty tests do not exercise the sequential profile, and omitted YTD currently crashes."
  - truth: "Payslip zero/one/many sequential tables preserve deterministic section order."
    test: "Exercise zero/one/many rows for each sequential table."
    expected: "Owned headers and ordered reconciliation hold without padding."
    why_human: "The current tests cover a normal case and a many-row continuation, not the full matrix."
  - truth: "Held-out longest Payslip labels/money/continuations preserve flexible descriptions, atomic money, own headers, and reconciliation space."
    test: "Run an independent boundary corpus through sequential_measured."
    expected: "No clipping/abbreviation/shrinkage; money stays atomic and final reconciliation is reserved."
    why_human: "Individual tests cover parts of this invariant but no held-out test covers the complete combination."
  - truth: "Held-out verbatim Payslip descriptions wrap only in the flexible column."
    test: "Use independently selected long descriptions and widest money tokens under the profile."
    expected: "Only description wraps; headers and money remain atomic."
    why_human: "Profile-specific held-out evidence is absent."
  - truth: "Held-out Ticket subtitle, terms, and reference wrap only in prose regions while locator labels/values never wrap or truncate."
    test: "Render independently selected long Ticket prose in light and dark atomic locator profiles."
    expected: "Prose wraps in existing regions; GA/H/24/B and labels remain atomic and complete."
    why_human: "Atomic locator tests exist, but no held-out long-prose profile test exercises this combined invariant."
---

# Phase 136: Catalog Visual Quality Verification Report

**Phase Goal:** The six scored cells with current visual gaps meet the frozen rubric through exact, reviewable evidence without expanding catalog scope or dark-mode claims.
**Verified:** 2026-08-28T17:53:52Z
**Status:** gaps_found
**Re-verification:** Yes — previous gaps remain, and two prior passes were false positives exposed by real-render/schema evidence.

## Goal Achievement

### Observable Truths

| # | Roadmap truth | Status | Evidence |
|---|---|---|---|
| 1 | Only the six locked cells are visually changed. | ✗ FAILED | Real source-PDF rendering produces exactly five changed IDs; Brutalist Ticket light is byte-stable. Synthetic hash-mutation tests hid this. |
| 2 | Exact-SHA pinned-renderer evidence plus human review meets the frozen threshold for all six. | ✗ FAILED | `SIGN-OFF.md` says all six remain unreviewed/unpromoted; no current reviewer-owned records exist. |
| 3 | Exactly 32 cells, 20 unscored, and every dark record has `print_safety:false` without broader claims. | ✗ FAILED | 32/20 and claim boundaries pass, but seven dark unscored dispositions omit `print_safety`; the plan says absence is not a passing default. |
| 4 | Every changed record has complete source/renderer/artifact/review/canonical provenance. | ✗ FAILED | No current review/publication records; semantic bundle validation, canonical shape, baseline identity, and rollback safety are defective. |

**Score:** 0/4 roadmap truths verified (9 distinct plan truths remain present but behavior-unverified; repeated backstops were deduplicated).

### PLAN Must-Have Audit

Every PLAN frontmatter truth was checked in declared order. `Tn` means the nth truth in that plan; repeated Plan 08 backstops were checked against their original Plan 02–04 truth as well.

| Plan | Verified | Failed | Present / behavior unverified | Key evidence |
|---|---|---|---|---|
| 136-01 (10) | T2, T3, T7, T9 | T1, T4, T5, T6, T8, T10 | — | Exact-ID lookup is real, but actual scope is 5/27 and seven dark unscored records omit `print_safety`. |
| 136-02 (16) | T1–T12 | — | T13–T16 | Ordinary Invoice/Statement state/error tests pass; four long-content profile backstops have no direct behavioral test. |
| 136-03 (8) | T1, T2, T4 | T3 | T5–T8 | Sequential happy/continuation tests pass; valid omitted YTD crashes; asymmetric/cardinality/held-out matrix incomplete. |
| 136-04 (6) | T1–T5 | — | T6 | Atomic GA/H/24/B and light/dark geometry have direct tests; long-prose profile backstop does not. |
| 136-05 (13) | T2, T3, T5–T8, T10, T13 | T1, T4, T9, T11, T12 | — | Deferral is truthful, but there is no authoritative full-size review packet and the validator proves counts, not semantic identity. |
| 136-06 (8) | T3, T6–T8 | T1, T2, T4, T5 | — | No-write behavior holds; exact binding/order/digest/canonical predicates do not. |
| 136-07 (5) | T1, T2, T5 | T3, T4 | — | The old exact ref is reachable and failure is recorded, but its run produced no artifact and actual classification is five changes. |
| 136-08 (19) | T4, T5, T7, T8, T10, T11, T18 | T1–T3, T6, T9 | T12–T17, T19 | No six reviews/publication; Payslip partial behavior fails; repeated backstops retain the states above. |

**Plan truth audit:** 46 verified, 23 failed, 16 present/behavior-unverified entries across 85 declarations. The 16 entries reduce to 9 distinct unverified invariants after deduplicating Plan 08 restatements.

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `dev/rendro/catalog.ex` | Exact target selection, truthful candidate/canonical publication | ✗ PARTIAL | Substantive and wired, but actual scope is five, deterministic classification depends on review status, baseline provenance is false, and rollback is unsafe. |
| `lib/rendro/recipes/invoice.ex` | Target-only generic semantic treatment | ✓ VERIFIED | Generic profile, no catalog identity; focused tests pass. |
| `lib/rendro/recipes/statement.ex` | Target-only ledger semantic treatment | ✓ VERIFIED | Generic profile and anchor contracts pass; held-out profile behavior remains unverified. |
| `lib/rendro/recipes/payslip.ex` | Sequential measured ledgers | ✗ PARTIAL | Real happy/continuation paths exist, but valid omitted/nil YTD is broken. |
| `lib/rendro/recipes/ticket.ex` | Atomic equal-share locator | ✗ PARTIAL | Atomic association works, but Ticket light remains byte-stable, defeating the exact-six contract. |
| `dev/rendro/catalog_evidence_bundle.ex` | Trusted closed bundle validation | ✗ FAILED | Count/hash envelope validation does not semantically validate payload contents; real canonical catalog is rejected. |
| `.github/workflows/catalog-evidence.yml` | Exact-SHA review/canonical evidence | ✗ PARTIAL | Review workflow exists; canonical count command is wrong and trusted control lacks semantic payload binding. |
| `priv/quality/rubric_scores.json` | Six current exact reviewer records | ✗ FAILED | Historical records only; no Phase 136 exact review chain. |
| `priv/quality/SIGN-OFF.md` | Current review or truthful miss/deferral | ✓ VERIFIED (deferral only) | Accurately records no Phase 136 review authority; cannot satisfy the goal's review truth. |
| `assets/rendro/catalog.json` and six target PNGs | Eligible canonical publication | ✗ NOT MATERIALIZED | Canonical assets intentionally remain old because eligibility is absent. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Dev target map | four recipes | generic `presentation_profile` | ✓ WIRED | Exact IDs stay in dev tooling and recipes consume generic semantic/ledger/locator keys. |
| Real rendered PDFs | candidate diff | complete SHA-256 equality | ✗ FAILED | Actual partition is five changed / 27 byte-stable, not six / 26. |
| Candidate payloads | trusted control | bundle validator | ✗ HOLLOW | Trusted control binds outer provenance but does not validate internal IDs/paths/hashes/candidate/renderer relationships. |
| Reviewer records | canonical publication | eligibility predicate | ✗ DISCONNECTED | No six current records; canonical publication never occurred. |
| Sequential Payslip input | measured ledger | row formatting and width measurement | ✗ FAILED | Direct `line.ytd` dereference crashes valid optional input before render. |

## Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces truthful data | Status |
|---|---|---|---|---|
| Catalog candidate diff | source-PDF/PNG hashes | actual renders vs committed manifest | Only five real changes | ✗ CONTRACT MISMATCH |
| Review evidence | payload identities | candidate-controlled JSON wrapped by trusted control | Envelope is trusted; semantics are not | ✗ HOLLOW |
| Phase 136 scores | six target review records | named human over exact full-size evidence | No current source | ✗ DISCONNECTED |
| Canonical catalog | reviewed eligible candidate | generator/publication transaction | Not materialized; real canonical bundle shape rejected | ✗ DISCONNECTED |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Selected phase tests | `mix test` over catalog/evidence/rubric and four recipe suites | 282 tests, 0 failures in 3.1s | ✓ PASS, but incomplete |
| Real source-PDF target partition | Render all 32 with `Rendro.Catalog.render_source_pdf/1` and compare SHA-256 to `assets/rendro/catalog.json` | Five changed IDs; Ticket light absent | ✗ FAIL |
| Valid sequential Payslip with omitted YTD | `mix run` calling `Payslip.sections/2` with `sequential_measured` | `KeyError: key :ytd not found` | ✗ FAIL |
| Real canonical payload accepted by bundle builder | `CatalogEvidenceBundle.build(:canonical, assets/rendro/catalog.json, ...)` | `{:error, [:invalid_payload_counts]}` | ✗ FAIL |
| Local full candidate command | `mix rendro.catalog.candidate` | Missing Linux `pdfium-cli` locally | ? SKIP; source-PDF partition above proves the scope defect without raster inference |

## Probe Execution

SKIPPED — no Phase 136 probe script is declared and no `scripts/**/tests/probe-*.sh` exists.

## Requirements Coverage

| Requirement | Source plans | Status | Evidence |
|---|---|---|---|
| CATALOG-10 | 136-01, 136-06, 136-07, 136-08 | ✗ BLOCKED | Actual real-render partition is five targets, not the exact six. |
| CATALOG-11 | 136-02–136-08 | ✗ BLOCKED | No current exact six-target human reviews; historical scores include sub-threshold dimensions. |
| CATALOG-12 | 136-01–136-08 | ✗ BLOCKED | 32/20 and no-overclaim boundaries hold, but seven dark records omit required `print_safety:false`. |
| CATALOG-13 | 136-05–136-08 | ✗ BLOCKED | No complete changed-record provenance; evidence and canonical paths have independent blockers. |

All four requirement IDs declared in PLAN frontmatter are mapped to Phase 136 in `REQUIREMENTS.md`; no orphaned Phase 136 requirement exists.

## Test Quality Audit

| Test file/group | Linked requirement | Active / skipped | Strongest assertion | Verdict |
|---|---|---|---|---|
| `test/rendro/catalog_test.exs` | CATALOG-10, CATALOG-12 | Active / 0 | Value/behavioral over synthetic hashes | 🛑 INSUFFICIENT: synthetic six-change fixtures pass while the real catalog has five changes. |
| `test/rendro/catalog_evidence_bundle_test.exs` | CATALOG-11, CATALOG-13 | Active / 0 | Value over generated payloads | 🛑 INSUFFICIENT: positive fixtures use arbitrary `item-N` identities and canonical `images`, masking semantic forgery and real schema mismatch. |
| Recipe suites | CATALOG-11, CATALOG-12 | Active / 0 | Behavioral/render/value | ⚠️ PARTIAL: strong happy/error coverage, but omitted/nil YTD and several held-out profiled invariants are absent. |
| `rubric_manifest_contract_test.exs` | CATALOG-11–13 | Active / 0 | Value/contract | ✓ Correctly proves the current state is canonical-ineligible; it does not prove goal completion. |

**Disabled requirement tests:** 0. **Circular expected-value generators:** 0 observed. **Misleading/insufficient requirement tests:** 3 groups, including 2 blockers.

## Anti-Patterns and Review Blockers

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found. The refreshed `136-REVIEW.md` reports seven blockers; independent checks confirm all seven against the current checkout:

1. Count-only trusted-control validation accepts semantically arbitrary payloads.
2. Canonical workflow/validator reject the real catalog shape (`jq length`; `images` vs `cells`).
3. Real scope is five changed cells; Ticket light is byte-stable.
4. Candidate scope is improperly coupled to advisory scored/unscored state.
5. Sequential Payslip crashes on valid omitted YTD.
6. Canonical rollback can delete untouched canonical paths after early rename failures.
7. Candidate `baseline_commit_sha` is assigned the candidate SHA rather than the baseline identity.

The two warnings also remain: the gallery download docs hard-code `attempt-1`, and malformed renderer pin handling can raise outside `build/4`'s result contract.

## Prohibition Review

The six judgment-tier PLAN prohibitions were inspected. No public API/dependency, recipe catalog-ID leakage, raster overlay/second renderer, fixture rewrite, reviewer-score synthesis, or broad accessibility/print/viewer claim was found. These are **non-authoritative LLM judgments** only; per the prohibition contract they remain flagged `unverified-prohibition — human review recommended` and are not silently promoted to passes.

## Decision Coverage

All 26 trackable `136-CONTEXT.md` decisions were found in shipped artifacts (non-blocking decision-coverage gate: 26/26).

## Human Verification

Do not begin visual qualification yet. The deterministic scope, evidence semantics, canonical path, dark-record schema, and Payslip behavior blockers must be fixed first. After they pass, perform the two deferred Plan 08 checks: validate a fresh exact artifact before viewing, then transcribe six independent named reviews and confirm eligible publication or exact unpromoted misses.

## Deferred Items

None. Phase 137 requires fresh final evidence and truthful unavailable-state reporting; it does not implement Phase 136's missing exact review, semantic trust, or canonical publication contract.

## Gaps Summary and Next Action

The phase goal is not achieved. Existing passing tests prove several bounded recipe structures and truthful no-write behavior, but they do not overcome observable failures in every roadmap success criterion.

**Next command:** `$gsd-plan-phase 136 --gaps`

The gap plan should first close the deterministic/code-review blockers (real six-target scope, reviewer-independent classification, semantic bundle schemas, real canonical shape, truthful baseline identity, safe rollback, optional YTD, and dark `print_safety` representation). Only then should it dispatch a fresh exact review, collect six named records, and conditionally materialize canonical evidence.

---

_Verified: 2026-08-28T17:53:52Z_
_Verifier: the agent (gsd-verifier)_
