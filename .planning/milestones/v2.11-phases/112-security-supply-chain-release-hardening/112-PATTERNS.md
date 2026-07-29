# Phase 112: Security, Supply-chain & Release Hardening - Pattern Map

**Mapped:** 2026-06-16
**Files analyzed:** 4
**Analogs found:** 3 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.github/dependabot.yml` | config | event-driven | None | N/A |
| `.github/workflows/ci.yml` | config | event-driven | `.github/workflows/ci.yml` | exact |
| `.github/workflows/audit.yml` | config | event-driven | `.github/workflows/ci.yml` | role-match |
| `.github/workflows/release.yml` | config | event-driven | `.github/workflows/release.yml` | exact |

## Pattern Assignments

### `.github/workflows/ci.yml` (config, event-driven)

**Analog:** `.github/workflows/ci.yml`

**Discrete Advisory Job Pattern** (lines 104-110):
```yaml
  advisory-checks:
    runs-on: ubuntu-latest
    continue-on-error: true
    # no 'needs:' -> graph-disconnected; failures cannot block engine merges
    steps:
      - name: Checkout
        uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
```
*(Planner should use this exact structure for the new `advisory-audits` job)*

---

### `.github/workflows/audit.yml` (config, event-driven)

**Analog:** `.github/workflows/ci.yml`

**Schedule Trigger Pattern** (lines 8-9):
```yaml
  schedule:
    - cron: '0 2 * * *'
```

**Standard Elixir Setup Pattern** (lines 109-116):
```yaml
      - name: Checkout
        uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3

      - name: Setup Beam
        uses: erlef/setup-beam@8251c48667b97e88a0a24ec512f5b72a039fcea7 # v1
        with:
          otp-version: '28'
          elixir-version: '1.19.5'
```

---

### `.github/workflows/release.yml` (config, event-driven)

**Analog:** `.github/workflows/release.yml`

**Tag Push Trigger Pattern** (lines 3-6):
```yaml
on:
  push:
    tags:
      - 'v*.*.*'
```

**Environment Secret Usage Pattern** (lines 33-35):
```yaml
      - name: Publish to Hex
        env:
          HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
```

---

## Shared Patterns

### Action Pinning
**Source:** `.github/workflows/ci.yml`
**Apply to:** All workflows
```yaml
      - name: Checkout
        uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3

      - name: Setup Beam
        uses: erlef/setup-beam@8251c48667b97e88a0a24ec512f5b72a039fcea7 # v1
```
*(All external actions MUST be pinned to an exact SHA)*

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.github/dependabot.yml` | config | event-driven | No Dependabot configuration exists yet |

## Metadata

**Analog search scope:** `.github/workflows/`
**Files scanned:** 3
**Pattern extraction date:** 2026-06-16