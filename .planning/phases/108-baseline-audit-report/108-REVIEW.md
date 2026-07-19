---
phase: 108-baseline-audit-report
reviewed: 2026-06-14T00:00:00Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - .github/workflows/ci.yml
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
status: issues_found
---

# Phase 108: Code Review Report

**Reviewed:** 2026-06-14
**Depth:** standard
**Files Reviewed:** 1 (diff surface: `f1e0bbf..HEAD`)
**Status:** issues_found

## Summary

The Phase 108 instrumentation is narrowly scoped: three additions to the `test` job in `.github/workflows/ci.yml`. The exit-code integrity analysis is sound — `pipefail` on bash ensures `mix ci`'s non-zero exit propagates through `tee`, and the `CI Baseline Summary` step is double-insulated from altering the gate outcome (`if: always()` + `continue-on-error: true`). No secrets are referenced in the summary step. The step handles missing log file and missing Elixir binary gracefully.

One warning-level issue exists: GitHub Actions template expressions for step outputs are expanded into the shell script text before the runner executes it. If `erlef/setup-beam` ever returns version strings containing shell metacharacters, those characters would be interpreted by bash. Two info items round out the review: silent truncation of slow-test data at 25 grep context lines, and the mutable `erlef/setup-beam@v1` tag which now has a runtime output dependency (pre-existing, elevated in relevance by the new `id:` reference).

---

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Template expressions for step outputs are interpolated into shell before bash sees them

**File:** `.github/workflows/ci.yml:50-51`

**Issue:** The `CI Baseline Summary` step embeds `${{ steps.setup-beam.outputs.otp-version }}` and `${{ steps.setup-beam.outputs.elixir-version }}` directly inside double-quoted `echo` strings. GitHub Actions substitutes these expressions at workflow-evaluation time, producing literal shell text like:

```bash
echo "| OTP | 28.0.0 |"
```

If `erlef/setup-beam@v1` ever returned a string containing shell metacharacters — e.g., a version tag with embedded `$(...)`, backticks, or `"` — bash would interpret them. The action is a trusted third-party action (not user input), and current outputs are semver-like strings, so exploitation requires either a compromised upstream action or an unexpected output format. The blast radius is limited (the step has `continue-on-error: true` and only writes to `$GITHUB_STEP_SUMMARY`), but the pattern is the canonical form of script injection documented in GitHub's own hardening guide.

**Fix:** Use environment variable indirection to pass action outputs to the shell, which prevents template-expansion injection:

```yaml
- name: CI Baseline Summary
  if: always()
  continue-on-error: true
  shell: bash
  env:
    OTP_VERSION: ${{ steps.setup-beam.outputs.otp-version }}
    ELIXIR_VERSION: ${{ steps.setup-beam.outputs.elixir-version }}
  run: |
    {
      echo "## CI Baseline"
      echo ""
      echo "| Property | Value |"
      echo "|----------|-------|"
      echo "| OTP | ${OTP_VERSION} |"
      echo "| Elixir | ${ELIXIR_VERSION} |"
      echo "| Schedulers | $(elixir -e 'IO.puts(System.schedulers_online())' 2>/dev/null || echo 'n/a') |"
      echo "| Cache (deps) | cold / none |"
      echo "| Cache (_build) | cold / none |"
      echo ""
      echo "### Slowest Tests"
      echo ""
      grep -A 25 'Top [0-9]* slowest' /tmp/mix-ci-output.log || echo "_(slowest data unavailable)_"
    } >> "$GITHUB_STEP_SUMMARY"
```

With this form, the template expressions are only expanded into the `env:` block (where GitHub Actions treats them as values, not code), and the shell sees only safe env-var references.

---

## Info

### IN-01: `grep -A 25` silently truncates slowest-test output if section exceeds 25 lines

**File:** `.github/workflows/ci.yml:59`

**Issue:** `grep -A 25 'Top [0-9]* slowest' /tmp/mix-ci-output.log` prints the matching header line plus the next 25 lines. ExUnit's `--slowest N` output can exceed 25 lines if a large N is passed to `mix ci` (e.g., `--slowest 30`). Any entries beyond line 25 are silently dropped from the step summary with no indication that truncation occurred.

**Fix:** Either increase the context count to a value safely above the expected slowest-test count (e.g., `-A 50`), or capture the entire section with `sed`:

```bash
sed -n '/Top [0-9]* slowest/,/^$/p' /tmp/mix-ci-output.log || echo "_(slowest data unavailable)_"
```

This is intentional per the phase's measurement scope, so deferring to phase 109 is acceptable — but the truncation should be documented.

---

### IN-02: `erlef/setup-beam@v1` is pinned by mutable tag; new output dependency makes this more load-bearing

**File:** `.github/workflows/ci.yml:24`

**Issue:** `erlef/setup-beam@v1` uses a mutable floating tag. All four jobs in the workflow used this pre-existing tag. Phase 108 adds `id: setup-beam` and references two of its named outputs (`otp-version`, `elixir-version`) in the `CI Baseline Summary` step. If the `v1` tag is moved to a version that renames or removes those outputs, the summary cells silently become empty strings (not a gate failure, due to `continue-on-error: true`), but the baseline measurement would report blank OTP/Elixir values without error — a silent data quality failure.

The other three jobs (`example-phoenix`, `raster-advisory`, etc.) also use the unpinned tag but have no output dependencies, so this is the only job where the mutable tag creates a silent-bad-data risk.

**Fix:** Pin to a digest SHA for reproducibility (deferred to a hardening phase is acceptable, but worth tracking):

```yaml
uses: erlef/setup-beam@DIGEST_SHA # v1.x.y
```

---

_Reviewed: 2026-06-14_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
