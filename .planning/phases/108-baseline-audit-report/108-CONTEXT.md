# Phase 108: Baseline & Audit Report - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish the **measured source-of-truth** for milestone C1 that drives phases 109–113.
Deliverables: a current-state baseline table (BASE-01), a critical-path + duplicated-work
map (BASE-02), an A–E classification of every test/check with cited evidence (BASE-03), a
prioritized P0–P3 recommendation report mapped to phases 109–113 (BASE-04), and CI
job-summary observability instrumentation (BASE-05).

**MEASURE-ONLY.** The ONLY file edit in this phase is the BASE-05 job-summary
instrumentation. No cache keys, no `async` flips, no removed/quarantined tests, no
gate-logic edits, no `docs/`/`guides/`/`CONTRIBUTING.md` — those land in 109–113.
</domain>

<decisions>
## Implementation Decisions

Four gray areas were researched in depth (advisor mode, two passes — minimal-decisive then
a full ecosystem/lessons/footguns/DX pass grounded in `prompts/rendro-oss-dna.md` and the
live szTheory sibling repos). All four are LOCKED and mutually coherent.

### D-01 — Baseline metric sourcing & rigor (BASE-01, BASE-02)
**Decision:** Hybrid, two honestly-scoped sources — never manufacture a statistic.
- **Real-runner wall-clock** for per-job/per-step durations + the critical-path /
  duplicated-work map (BASE-02): extract from existing history via
  `gh api repos/{owner}/{repo}/actions/runs/{id}/jobs` → `.jobs[].steps[]`.
- **Inner `mix ci` split** (format / compile / test / docs / credo / dialyzer) for BASE-01:
  derive from LOCAL `mix test --slowest 20`, `MIX_ENV=test mix compile --profile time`,
  `mix xref graph --label compile-connected`. The API physically CANNOT see this split
  because all of `mix ci` runs inside ONE opaque "Run CI" step.
- **Label everything honestly.** Report the local split as an **ordinal/proportional local
  proxy, NOT absolute seconds** (local dev box = 18 schedulers vs `ubuntu-latest` = 4, so
  it over-parallelizes). Report p95 as **"insufficient green-run data (n=3)"** — of 37
  ci.yml runs only 3 are green, and each collapses `mix ci` into one 372s/386s/222s step.
- **Do NOT trigger fresh paid runs** to manufacture a p95 sample: it burns discouraged
  minutes to baseline the uncached pipeline that 109–112 will deliberately invalidate.
  Real after-metrics are Phase 113's job (VAL-01), harvested from green-by-construction
  BASE-05 summaries.
**Why this is the headline finding, not a weakness:** a pipeline this red cannot yield a
defensible p95 — which is itself the argument for the BASE-05 instrumentation landing now.

### D-02 — Job-summary instrumentation pattern & scope (BASE-05)
**Decision:** Inline `$GITHUB_STEP_SUMMARY` shell step in the **`test` job ONLY**.
- **Pattern:** a single brace-group redirect — `{ echo "## CI Baseline"; echo "- …"; } >>
  "$GITHUB_STEP_SUMMARY"` — matching the prevailing szTheory house style (mailglass 14×,
  scrypath, rulestead, accrue). **NO composite action. NO `mix` task.**
- **Add `id:` to the setup-beam step** to read its `otp-version`/`elixir-version` outputs.
- **Content:** resolved OTP + Elixir versions, `System.schedulers_online()`, cache state
  (literal placeholder `cold / none` in 108), slowest tests.
- **Slowest-tests capture:** `tee` the `mix ci` stdout to a file, then grep the `--slowest`
  block in a follow-on step — do NOT re-run the suite.
- **Observability-only guarantee (HARD):** every summary step is `if: always()` AND
  `continue-on-error: true`, with a body that cannot error the job (`|| true` /
  `|| echo "n/a"`). It MUST NOT change any job's exit code or gate outcome.
- **109 handoff:** the cache row becomes live with a ONE-LINE edit —
  `${{ steps.cache.outputs.cache-hit == 'true' && 'hit' || 'miss' }}` plus `id: cache` on
  the new cache step.
**Rejected — composite action `.github/actions/ci-summary`:** multi-write collapse bug
(community #32566; `actions/runner#2020` — multiple `>> $GITHUB_STEP_SUMMARY` writes inside
one composite show only the LAST line); 0/9 szTheory siblings have a CI-summary composite;
introduces a new surprising convention the audit brief explicitly warns against.
**Rejected — `mix` task:** couples CI presentation into the library Mix namespace; reinvents
shell redirection in Elixir; no org or ecosystem precedent.
**Scope rejected — all 10 jobs / `test`+advisory:** the 4 advisory + 4 proof jobs don't run
`mix ci` and hold no version/scheduler/slowest-test signal — pure noise + 9 extra edit
surfaces against a no-behavior-change constraint.

### D-03 — Audit report location & shape (BASE-01..04 deliverable)
**Decision:** ONE consolidated planning-internal doc at
**`.planning/milestones/C1-AUDIT.md`**, sitting beside its source `C1-AUDIT-BRIEF.md`.
- **One file, NOT split.** Brief §10 is one tightly cross-referential chain (P0–P3 recs →
  A–E classes → baseline metrics → critical path); one anchored file keeps every citation
  resolving locally and edit-stable. A 4-file split fragments the most-cited relationships
  and invents a naming sub-convention no sibling uses.
- **Naming:** `C1-AUDIT.md`, deliberately NOT `-MILESTONE-AUDIT.md`. The
  `-MILESTONE-AUDIT.md` slot is the milestone-CLOSE retrospective/verdict; this is the
  milestone-START forward audit (113 closes it out). Distinct lifecycle → distinct name.
- **Audience:** GSD-internal (phases 109–113) + human maintainers. NOT published — ExDoc
  `extras` pull only from `guides/`, and `.planning/` is excluded from the Hex package and
  hexdocs. This is pre-implementation scaffolding, not a user doc.
- **Stable H2 anchors, one per deliverable** (heading prefixes `BASE-0N —`, `P0/P1/...` are
  STABLE; do not rename mid-milestone):
  - `## BASE-01 — Baseline Table` → `#base-01-baseline-table`
  - `## BASE-02 — Critical Path` → `#base-02-critical-path`
  - `## BASE-03 — A–E Classification` → `#base-03-a-e-classification`
  - `## BASE-04 — P0–P3 Recommendation Report` → `#base-04-recommendation-report`
    (exec summary, pipeline map, findings by category, prioritized recs with
    issue/change/impact/risk/rollback, target pipeline, test cleanup plan, validation plan)
  - YAML frontmatter (`milestone: C1`, status, generated date) mirroring sibling
    MILESTONE-AUDIT frontmatter style.
- **Downstream citation contract (109–113):** cite as
  `.planning/milestones/C1-AUDIT.md#<stable-anchor>`.
**Guardrail:** Phase 113 OWNS the contributor-facing output (VAL-02 target-pipeline writeup
+ DX-02 CONTRIBUTING.md). Phase 108 stays entirely inside `.planning/`.

### D-04 — A–E classification evidence depth (BASE-03)
**Decision:** Measured-but-bounded. Every A–E call is backed by a cited artifact; the pass
stops short of Phase 110's flips/proofs/deletions. This is both the floor AND the ceiling.
- **Evidence floor (MUST do in 108):**
  1. `mix test --slowest 20` (warm) once → cite for all **B** (optimize) / **C**
     (move-to-scheduled) slow-tail calls.
  2. Read ALL 34 `async: false` modules; cite each module's concrete non-async reason on
     Rendro's real axes — global app env, named ETS, registered process,
     port/`System.cmd`, tmpfs path, time, randomness, **process-global telemetry/Logger**.
     (NO Ecto sandbox exists — pure lib.) Heuristic grep auto-resolves ~30/34; human-read
     the ~4 residue (e.g. `branding_contract`, `public_api`, `telemetry`, `manifest`).
  3. ONE bounded flake sweep: `mix test --repeat-until-failure 25` × seeds {0,1,2}
     (suite or targeted at sleep/port/time modules) → cite as flaky **candidacy** for
     **D**, NOT as proof of absence.
  4. Classify the `test` gate, the 4 advisory soft-fail jobs, and the 4 live-proof gates
     (`:live_pdf_tools` / `:live_signing` / `:raster_snapshot`) as categories; cite
     evidence PER CATEGORY, not per individual test. Existing tag-exclusion IS the evidence
     for the excluded lanes — do not re-run them.
  5. **E** (delete/rewrite) requires a named artifact: assertion-free filler, duplicated
     path, or implementation-trivia — **never "slow" alone** (brief mandate).
- **Evidence ceiling (explicitly DEFERRED to Phase 110):** proving flake ABSENCE (deep
  `verify.flake`-style 50–200× multi-seed); full slow-tail beyond `--slowest 20`;
  `mix test --partitions N` experiments; every actual `async: true` flip, quarantine, and
  deletion (TEST-01/03/04).
**Convention oracle:** threadline's CONTRIBUTING documents per-reason `async: false`
("telemetry handlers are process-global" — directly relevant to Rendro's
`telemetry_test.exs`), forbids blind retries, and runs deep flake proof in a separate
nightly `mix verify.flake` lane. Phase 108 mirrors this: bounded candidacy now, exhaustive
proof out-of-band (110).

### Cohesive thread across all four
The **single monolithic `test` job / `mix ci` / one "Run CI" step is the root anomaly**
(every sibling decomposes the monolith into separate jobs/named steps for free per-stage
timing — mailglass: Format/Compile/Support-Contract; threadline: format→credo→compile→test;
lockspire: qa→sast→docs→audit→test). That single step is why (a) the API can't see the
inner split (forcing local-proxy profiling, D-01), (b) BASE-05 instrumentation is needed
now (D-02), and (c) there's zero parallelism to exploit. The A–E/P0–P3 report (D-03/D-04)
should therefore name **"decompose the `mix ci` monolith into parallel named jobs/steps"**
as a flagship P0/P1 recommendation that foreshadows phases 109 (caching) and 111 (topology).

### Claude's Discretion
- Exact ordering and table column set within `C1-AUDIT.md` (follow brief §10 layout).
- Precise flake-sweep seed count/targeting within the bounded floor (≥3 seeds, ~25 repeats).
- Exact echo lines / formatting of the `test`-job summary panel.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope & source of truth
- `.planning/milestones/C1-AUDIT-BRIEF.md` — the canonical milestone brief. Phase 108 maps
  to **§3** (baseline-first / measure before optimizing), **§4** (test value A–E
  classification), **§5.1–§5.2** (ExUnit async/partitioning), **§10** (recommendation
  report format), **§11** (prioritization rubric), **§12** (dark corners checklist).
- `.planning/ROADMAP.md` → "### Phase 108: Baseline & Audit Report" — goal, 5 success
  criteria, artifacts, the measure-only constraint, and the 108→110 hand-off boundary.
- `.planning/REQUIREMENTS.md` → BASE-01..05 (and the downstream CACHE/TEST/FLOW/SEC/DX/VAL
  reqs these recommendations must map to).

### Engineering DNA & sibling convention (the deep-research grounding)
- `prompts/rendro-oss-dna.md` — szTheory CI/release/test DNA; §2.1 CI patterns, §2.2 test
  strategy, §4 default quality contract. Names the sibling repos used as comparables.
- Live sibling repos (inspect via `gh api repos/szTheory/<name>/contents/...`):
  **mailglass** (inline `$GITHUB_STEP_SUMMARY` brace-group house style; decomposed
  Format/Compile/Support-Contract jobs), **threadline** (decomposed named steps;
  CONTRIBUTING async-reason + no-blind-retry + `mix verify.flake` nightly convention),
  **scrypath** (`if: always()` + `cat … >> $GITHUB_STEP_SUMMARY`), **lockspire**
  (decomposed qa/sast/docs/audit/test; only `.github/actions/` is release-please, not
  summaries), **rulestead**, **accrue**.

### Pipeline under audit
- `.github/workflows/ci.yml` — 10 jobs (the `test` gate, `example-phoenix`, 4 advisory
  `continue-on-error`, 4 `needs: test` proof gates); zero caching; setup-beam at ~line 23.
- `.github/workflows/hexdocs.yml`, `.github/workflows/release.yml` — must be covered by the
  BASE-01 baseline table.
- `mix.exs` → `defp aliases` (`ci:` = format → hex.build → compile --warnings-as-errors →
  test → docs → credo → dialyzer); `defp docs` (proves ExDoc extras = `guides/` only).
- `test/test_helper.exs` — tag exclusions (`:live_pdf_tools`/`:live_signing`/
  `:raster_snapshot`), ETS/Mocks setup; the 34 `async: false` of 127 test files.

### External references (BASE-05 correctness)
- GitHub Actions — Workflow commands (`$GITHUB_STEP_SUMMARY`): per-step summary isolation,
  append via `>>`, ≤1 MiB/step.
- `actions/runner#2020` + community discussion #32566 — composite multi-write collapse bug
  (the reason a composite action is rejected for BASE-05).
- Mix/ExUnit docs — `mix test --slowest`, `--repeat-until-failure` (≥1.17), `--seed`;
  `ExUnit.Case` async-only-if-no-global-state.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`mix ci` alias** (`mix.exs`): the exact serial command chain to profile locally for the
  BASE-01 inner split.
- **setup-beam step** (`.github/workflows/ci.yml` ~line 23): already present in every job;
  add `id:` to expose resolved `otp-version`/`elixir-version` for the summary.
- **Existing SHA-pinned actions** (e.g. `actions/checkout` pinned) — the repo already
  practices SHA pinning, consistent with the inline-summary "boring/idiomatic" direction.

### Established Patterns
- **Single opaque `test` job / `mix ci` / "Run CI" step** — the anomaly the audit must name;
  contrast against sibling job/step decomposition.
- **Graph-disconnected advisory jobs** (`continue-on-error: true`, no `needs:`) and
  **`needs: test` proof gates** — the existing lane tiering the A–E classification must
  honor (advisory vs merge-blocking vs live-proof).
- **szTheory inline `$GITHUB_STEP_SUMMARY` brace-group house style** — the BASE-05 pattern
  to mirror.

### Integration Points
- BASE-05 edits ONLY the `test` job in `.github/workflows/ci.yml`; the placeholder cache row
  is the single seam Phase 109 flips live.
- `C1-AUDIT.md` anchors are the citation seam for phases 109–113.

</code_context>

<specifics>
## Specific Ideas

- p95 must be written as the literal phrase **"insufficient green-run data (n=3)"** — an
  audit finding, not a gap to hide.
- Local profiling numbers must carry an explicit **"local proxy (18 schedulers; not
  runner-absolute)"** tag wherever shown.
- BASE-04 flagship recommendation candidate: **decompose the `mix ci` monolith into parallel
  named jobs/steps** (foreshadows 109 caching + 111 topology).
- BASE-05 summary panel header: `## CI Baseline` (single brace-group redirect).

</specifics>

<deferred>
## Deferred Ideas

- **Decomposing the `mix ci` monolith into parallel jobs/steps** — recommend in BASE-04 here,
  but IMPLEMENT in phases 109 (caching) / 111 (topology). 108 is measure-only.
- **Real green-run p95 / before-after metrics** — Phase 113 (VAL-01), from BASE-05 summaries.
- **`mix verify.flake` nightly deep flake-proof lane** (threadline pattern) — candidate for
  Phase 110 (TEST-03) / 111 trigger model; 108 only flags flaky candidacy.
- **Actual `async: true` flips, quarantine, deletions, `--partitions N`** — Phase 110
  (TEST-01/02/03/04). 108 records candidacy + evidence only.
- **Contributor-facing target-pipeline writeup + CONTRIBUTING.md** — Phase 113 (VAL-02 /
  DX-02). 108 stays inside `.planning/`.

</deferred>

---

*Phase: 108-baseline-audit-report*
*Context gathered: 2026-06-14*
