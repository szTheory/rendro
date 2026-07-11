# Phase 108: Baseline & Audit Report — Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 2
**Analogs found:** 2 / 2

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.github/workflows/ci.yml` (test job only) | CI config / observability step | event-driven (push/PR trigger → shell pipeline) | `.github/workflows/ci.yml` existing steps + `.github/workflows/hexdocs.yml` Setup Beam step | exact (in-repo) |
| `.planning/milestones/C1-AUDIT.md` | planning doc (milestone-start forward audit) | transform (local measurement → structured report) | `.planning/v2.8-MILESTONE-AUDIT.md` (YAML frontmatter + H2 heading convention) | role-adjacent (retrospective vs. forward audit — same heading/frontmatter idiom, distinct lifecycle name) |

---

## Pattern Assignments

### `.github/workflows/ci.yml` — BASE-05 instrumentation (test job only)

**Analog:** `.github/workflows/ci.yml` existing `test` job steps (lines 15–33) + `.github/workflows/hexdocs.yml` SHA-pinned `Setup Beam` step (lines 28–32)

**Existing `test` job structure to preserve** (ci.yml lines 15–33):

```yaml
  test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3

      - name: Setup Beam
        uses: erlef/setup-beam@v1
        with:
          otp-version: '28'
          elixir-version: '1.19.5'

      - name: Install Dependencies
        run: mix deps.get

      - name: Run CI
        run: mix ci
```

**Step 1 — Add `id:` to Setup Beam** (mutation of ci.yml line 23; `test` job only):

```yaml
      - name: Setup Beam
        id: setup-beam          # ADD THIS LINE — exposes otp-version / elixir-version outputs
        uses: erlef/setup-beam@v1
        with:
          otp-version: '28'
          elixir-version: '1.19.5'
```

Note: hexdocs.yml line 28 shows the SHA-pinned variant (`erlef/setup-beam@8251c48667b97e88a0a24ec512f5b72a039fcea7 # v1`). ci.yml uses floating `@v1` — do NOT change the ref in Phase 108 (SEC-01 is Phase 112 scope). Add `id:` only.

**Step 2 — Capture `mix ci` stdout via tee** (replace ci.yml line 32 `run: mix ci`):

```yaml
      - name: Run CI
        shell: bash
        run: |
          set -o pipefail
          mix ci 2>&1 | tee /tmp/mix-ci-output.log
```

`set -o pipefail` is required: without it, `tee`'s always-zero exit code swallows a `mix ci` failure. Alternative: `mix ci 2>&1 | tee /tmp/mix-ci-output.log; exit ${PIPESTATUS[0]}` — both are equivalent; prefer `set -o pipefail` for readability.

**Step 3 — Job summary step** (new step appended after Run CI, still inside `test` job):

```yaml
      - name: CI Baseline Summary
        if: always()
        continue-on-error: true
        shell: bash
        run: |
          {
            echo "## CI Baseline"
            echo ""
            echo "| Property | Value |"
            echo "|----------|-------|"
            echo "| OTP | ${{ steps.setup-beam.outputs.otp-version }} |"
            echo "| Elixir | ${{ steps.setup-beam.outputs.elixir-version }} |"
            echo "| Schedulers | $(elixir -e 'IO.puts(System.schedulers_online())' 2>/dev/null || echo 'n/a') |"
            # TODO(109): replace 'cold / none' with cache-hit output once actions/cache + id: cache lands
            echo "| Cache (deps) | cold / none |"
            echo "| Cache (_build) | cold / none |"
            echo ""
            echo "### Slowest Tests"
            echo ""
            grep -A 25 'Top [0-9]* slowest' /tmp/mix-ci-output.log || echo "_(slowest data unavailable)_"
          } >> "$GITHUB_STEP_SUMMARY"
```

**Key pattern guarantees (all mandatory):**

| Guard | Why |
|-------|-----|
| `if: always()` | Step runs even when `Run CI` fails — summary must survive test failures |
| `continue-on-error: true` | A shell error in the summary step cannot fail the job or change the gate outcome |
| Single brace-group `{ … } >> "$GITHUB_STEP_SUMMARY"` | One write per step — house style; avoids rendering inconsistency |
| `\|\| echo 'n/a'` / `\|\| echo "_(unavailable)_"` | Every subcommand has a fallback; body must never error the job |
| `set -o pipefail` on Run CI step | Preserves `mix ci` exit code through the `tee` pipeline |

**House style source (szTheory sibling analogs verified via GitHub API):**
- **mailglass** `.github/workflows/ci.yml`: brace-group `{ echo "## heading"; echo "- items"; } >> "$GITHUB_STEP_SUMMARY"` — exact pattern, 14 uses across jobs
- **scrypath** `.github/workflows/ci.yml`: `if: always()` + `cat generated-file.md >> "$GITHUB_STEP_SUMMARY"` — confirms `if: always()` convention

**Phase 109 cache row seam** (ONE-LINE edit in 109, not 108):

```yaml
# In 109, after actions/cache step gains id: cache, replace the two cold/none rows with:
echo "| Cache (deps) | ${{ steps.cache.outputs.cache-hit == 'true' && 'hit' || 'miss' }} |"
```

The `# TODO(109)` comment in the summary step is the explicit handoff marker.

---

### `.planning/milestones/C1-AUDIT.md` — BASE-01 through BASE-04 deliverable

**Analog:** `.planning/v2.8-MILESTONE-AUDIT.md` (frontmatter style) + RESEARCH.md §C1-AUDIT.md Report Shape

**YAML frontmatter pattern** (from `.planning/v2.8-MILESTONE-AUDIT.md` lines 1–24, adapted for forward-audit lifecycle):

```yaml
---
milestone: C1
milestone_name: CI/CD Performance & Reliability
status: in-progress
generated: "2026-06-14"
phases: [109, 110, 111, 112, 113]
---
```

Differences from retrospective `-MILESTONE-AUDIT.md` style:
- `generated:` (not `audited:`) — forward audit, not post-close retrospective
- `status: in-progress` (not `passed`/`failed`) — milestone not yet closed
- No `scores:` / `gaps:` / `nyquist:` blocks — those belong to the Phase 113 close-out retrospective
- `phases:` list forward (109–113) — the phases this audit drives

**H2 anchor headings pattern** (stable; must NOT be renamed during milestone):

```markdown
## BASE-01 — Baseline Table

## BASE-02 — Critical Path

## BASE-03 — A–E Classification

## BASE-04 — P0–P3 Recommendation Report
```

URL fragments (GitHub Markdown): `#base-01--baseline-table`, `#base-02--critical-path`, `#base-03--ae-classification`, `#base-04--p0p3-recommendation-report`

Downstream citation contract (phases 109–113 use these literally):
```
.planning/milestones/C1-AUDIT.md#base-01--baseline-table
.planning/milestones/C1-AUDIT.md#base-02--critical-path
.planning/milestones/C1-AUDIT.md#base-03--ae-classification
.planning/milestones/C1-AUDIT.md#base-04--p0p3-recommendation-report
```

**Top-level H1 pattern** (from v2.8-MILESTONE-AUDIT.md line 26):

```markdown
# C1 Baseline Audit
```

(NOT `# C1 Milestone Audit Report` — forward audit, not close-out; "Baseline Audit" distinguishes it from the Phase 113 retrospective)

**BASE-04 per-recommendation structure** (each item must include all fields):

```markdown
### P0 — [Short title]

**Category:** Performance / Reliability / Security / DX / Test Quality
**Issue:** [What is wrong today]
**Proposed change:** [Concrete action]
**Expected impact:** [Runtime/reliability/DX benefit]
**Risk:** [What could go wrong]
**Rollback:** [How to revert]
**Target phase:** 109 / 110 / 111 / 112 / 113
```

**Mandatory literal phrases** (from CONTEXT.md `<specifics>`):
- p95 column value: `"insufficient green-run data (n=3)"` — exact phrase, no substitutions
- Local proxy label: `"local proxy (18 schedulers; not runner-absolute)"` — must appear on every locally-derived number
- BASE-05 summary panel header: `## CI Baseline` — the H2 inside the job summary brace-group

---

## Shared Patterns

### Shell pipeline exit-code preservation
**Source:** RESEARCH.md §BASE-05 Exact YAML Pattern (guardrail: "HARD: Exit code in tee pattern")
**Apply to:** The modified `Run CI` step in `test` job

```yaml
shell: bash
run: |
  set -o pipefail
  mix ci 2>&1 | tee /tmp/mix-ci-output.log
```

### `if: always()` + `continue-on-error: true` observability-step guard
**Source:** RESEARCH.md §BASE-05 Exact YAML Pattern + scrypath sibling analog
**Apply to:** Every summary step added in BASE-05 (currently only `test` job)

```yaml
if: always()
continue-on-error: true
```

Both fields are required together. `if: always()` alone still allows the step to propagate a non-zero exit; `continue-on-error: true` is the hard barrier that prevents the summary step from failing the job.

### `|| echo 'n/a'` fallback guard
**Source:** RESEARCH.md §BASE-05 Exact YAML Pattern
**Apply to:** Every subcommand inside the brace-group that could fail when BEAM is not set up

```yaml
$(elixir -e 'IO.puts(System.schedulers_online())' 2>/dev/null || echo 'n/a')
grep -A 25 'Top [0-9]* slowest' /tmp/mix-ci-output.log || echo "_(slowest data unavailable)_"
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | Both artifacts have solid in-repo analogs. |

No analog gaps. The `$GITHUB_STEP_SUMMARY` brace-group pattern is well-evidenced by mailglass/scrypath siblings (verified via GitHub API in RESEARCH.md). The frontmatter + H2 anchor doc pattern is directly established by the existing `-MILESTONE-AUDIT.md` files in `.planning/`.

---

## Metadata

**Analog search scope:** `.github/workflows/` (ci.yml, hexdocs.yml, release.yml), `.planning/` (all `*-MILESTONE-AUDIT.md` files), `.planning/milestones/C1-AUDIT-BRIEF.md`, sibling repos mailglass + scrypath (via RESEARCH.md verified API extracts)
**Files scanned:** 4 in-repo workflow/doc files; 2 sibling-repo patterns via RESEARCH.md
**Pattern extraction date:** 2026-06-14
