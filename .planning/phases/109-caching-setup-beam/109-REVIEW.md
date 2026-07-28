---
phase: 109
reviewed: 2026-06-15T21:18:54Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - .github/workflows/ci.yml
  - .github/workflows/release.yml
  - mix.exs
findings:
  critical: 2
  warning: 2
  info: 0
  total: 4
status: issues_found
---

# Phase 109: Code Review Report

**Reviewed:** 2026-06-15T21:18:54Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Reviewed `mix.exs` and `.github/workflows/*.yml` changes introduced for phase 109 CI caching setup. Found two critical blockers preventing CI from running and correctly caching Dialyzer PLTs, as well as two warnings regarding unchecked-in PLT paths and directory creation.

## Narrative Findings (AI reviewer)

### CR-01: Malformed YAML syntax preventing GitHub Actions parse

**File:** `.github/workflows/ci.yml:353-354`
**Issue:** A duplicated, malformed step (`: Verify Release Proof`) at the end of the `ci.yml` file violates YAML syntax. This will cause the entire GitHub Actions workflow file to fail parsing, blocking all CI jobs from running.
**Fix:** Remove the duplicate and malformed lines 353-354:
```yaml
      - name: Verify Release Proof
        run: mix run scripts/release_preflight_proof.exs --current-version-tag --worktree "$RUNNER_TEMP/rendro-release-proof"
```

### CR-02: Missing PLT Cache restore and save steps

**File:** `.github/workflows/ci.yml:71`
**Issue:** The environment block in `CI Baseline Summary` attempts to evaluate `steps.plt-cache.outputs.cache-hit`, but there is no step with `id: plt-cache` defined anywhere in the `test` job. The planned `actions/cache/restore@v4` and `actions/cache/save@v4` steps for the Dialyzer PLT cache were completely omitted. This breaks Dialyzer CI caching entirely.
**Fix:** Add the required caching steps around the `Run CI` step:
```yaml
      - name: Cache PLT
        id: plt-cache
        uses: actions/cache/restore@v4
        with:
          path: priv/plts
          key: ${{ runner.os }}-plt-${{ env.CACHE_BUSTER }}-${{ steps.setup-beam.outputs.otp-version }}-${{ steps.setup-beam.outputs.elixir-version }}-${{ env.MIX_ENV }}-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-plt-${{ env.CACHE_BUSTER }}-${{ steps.setup-beam.outputs.otp-version }}-${{ steps.setup-beam.outputs.elixir-version }}-${{ env.MIX_ENV }}-

      - name: Run CI
        shell: bash
        run: mix ci 2>&1 | tee /tmp/mix-ci-output.log

      - name: Save PLT Cache
        uses: actions/cache/save@v4
        if: always() && steps.plt-cache.outputs.cache-hit != 'true'
        with:
          path: priv/plts
          key: ${{ steps.plt-cache.outputs.cache-primary-key }}
```

## Warnings

### WR-01: Untracked `priv/plts` directory missing from `.gitignore`

**File:** `.gitignore:1`
**Issue:** `mix.exs` changes moved Dialyzer's local PLT directory to `priv/plts`. However, this path is not ignored in `.gitignore`. Since PLTs are large generated binary files, developers running `mix dialyzer` locally risk accidentally committing them to the repository.
**Fix:** Add the directory to `.gitignore`:
```gitignore
 # ── Elixir/Mix ──
 /_build/
 /deps/
+/priv/plts/
```

### WR-02: Missing directory creation for custom PLT path

**File:** `.github/workflows/ci.yml`
**Issue:** Dialyxir generally expects the target PLT directory to exist. While `actions/cache` may recreate it during a cache hit, a cache miss will start with no `priv/plts` directory. `mix dialyzer` might fail with an `ENOENT` error if it tries to write to a non-existent custom path that isn't pre-created.
**Fix:** Add a shell step to ensure the directory exists before the PLT cache restoration step:
```yaml
      - name: Ensure PLT directory exists
        run: mkdir -p priv/plts
```

---

_Reviewed: 2026-06-15T21:18:54Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
