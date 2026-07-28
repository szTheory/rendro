# Phase 109: caching-setup-beam - Pattern Map

**Mapped:** 2026-06-15
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `mix.exs` | config | batch | `mix.exs` | exact |
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |
| `.github/workflows/hexdocs.yml` | config | batch | `.github/workflows/hexdocs.yml` | exact |
| `.github/workflows/release.yml` | config | batch | `.github/workflows/release.yml` | exact |

## Pattern Assignments

### `mix.exs` (config, batch)

**Analog:** `mix.exs`

**Core Pattern (dialyzer block)** (lines 17-20):
```elixir
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs(),
      dialyzer: [plt_add_apps: [:mix, :stream_data, :jsv, :yaml_elixir, :livebook]]
```

---

### `.github/workflows/ci.yml` (config, batch)

**Analog:** `.github/workflows/ci.yml`

**Core Pattern (unpinned setup-beam)** (lines 19-24):
```yaml
      - name: Setup Beam
        id: setup-beam
        uses: erlef/setup-beam@v1
        with:
          otp-version: '28'
          elixir-version: '1.19.5'
```

**Step Summary Pattern** (lines 40-62):
```yaml
      - name: CI Baseline Summary
        if: always()
        continue-on-error: true
        shell: bash
        # Pass setup-beam outputs via env (values, not inlined script text) to avoid
        # ${{ }} template-expression injection into the shell (WR-01 / GitHub hardening guide).
        env:
          OTP_VERSION: ${{ steps.setup-beam.outputs.otp-version }}
          ELIXIR_VERSION: ${{ steps.setup-beam.outputs.elixir-version }}
        run: |
          {
            echo "## CI Baseline"
            echo ""
            echo "| Property | Value |"
            echo "|----------|-------|"
            echo "| OTP | ${OTP_VERSION:-n/a} |"
            echo "| Elixir | ${ELIXIR_VERSION:-n/a} |"
            echo "| Schedulers | $(elixir -e 'IO.puts(System.schedulers_online())' 2>/dev/null || echo 'n/a') |"
            # TODO(109): replace 'cold / none' with cache-hit output once actions/cache + id: cache lands
            echo "| Cache (deps) | cold / none |"
            echo "| Cache (_build) | cold / none |"
            echo ""
```

---

### `.github/workflows/hexdocs.yml` (config, batch)

**Analog:** `.github/workflows/hexdocs.yml`

**Core Pattern (pinned setup-beam)** (lines 26-30):
```yaml
      - name: Setup Beam
        uses: erlef/setup-beam@8251c48667b97e88a0a24ec512f5b72a039fcea7 # v1
        with:
          otp-version: '28'
          elixir-version: '1.19.5'
```

---

### `.github/workflows/release.yml` (config, batch)

**Analog:** `.github/workflows/release.yml`

**Core Pattern (unpinned setup-beam)** (lines 16-20):
```yaml
      - name: Setup Beam
        uses: erlef/setup-beam@v1
        with:
          otp-version: '28'
          elixir-version: '1.19.5'
```

---

## Shared Patterns

### Dialyzer PLT Split Cache
**Source:** `.planning/phases/109-caching-setup-beam/109-RESEARCH.md`
**Apply to:** `.github/workflows/ci.yml`
```yaml
      - name: Restore PLT
        uses: actions/cache/restore@v4
        id: plt-cache
        with:
          path: priv/plts
          key: ${{ runner.os }}-plt-${{ env.CACHE_BUSTER }}-${{ steps.setup-beam.outputs.otp-version }}-${{ steps.setup-beam.outputs.elixir-version }}-${{ env.MIX_ENV || 'test' }}-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-plt-${{ env.CACHE_BUSTER }}-${{ steps.setup-beam.outputs.otp-version }}-${{ steps.setup-beam.outputs.elixir-version }}-${{ env.MIX_ENV || 'test' }}-

      - name: Run CI
        run: mix ci # Dialyzer might fail here

      - name: Save PLT
        uses: actions/cache/save@v4
        if: always() && steps.plt-cache.outputs.cache-hit != 'true'
        with:
          path: priv/plts
          key: ${{ steps.plt-cache.outputs.cache-primary-key }}
```

## No Analog Found

Files with no close match in the codebase:
*(None, all files are modifications to existing files.)*

## Metadata

**Analog search scope:** Root `mix.exs` and `.github/workflows/*.yml`
**Files scanned:** 4
**Pattern extraction date:** 2026-06-15