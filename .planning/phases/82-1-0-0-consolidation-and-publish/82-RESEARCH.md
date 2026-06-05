# Phase 82: 1.0.0 Consolidation & Publish - Research

**Researched:** 2026-06-05
**Domain:** Release Engineering & CI/CD
**Confidence:** HIGH

## Summary

This phase finalizes the 1.0.0 release of Rendro by closing preflight audit gaps and consolidating the changelog. The `lib/mix/tasks/release/preflight.ex` script needs to be hardened to prevent the accidental inclusion of internal/operator files in the published Hex tarball, enforce dependency/registry audits (`mix hex.audit`, `mix deps.audit`), and ensure `source_ref` parity in the package documentation. The `CHANGELOG.md` will be consolidated into a single `1.0.0` entry encompassing v2.3, v2.4, and the Phase 78-80 stability work. Finally, `mix.exs` will be bumped to `1.0.0` and the manual release sequence will be documented for the operator.

**Primary recommendation:** Harden `preflight.ex` to check against a strict list of forbidden files and add regex support for dated changelog headers, then update metadata and document the manual Git tag/push steps for Hex publication via CI.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Fix REL-02 and REL-03 in `preflight.ex` before consolidating `CHANGELOG.md`.**
- **REL-02**: Ensure `preflight.ex` checks for the absence of operator/evidence artifacts (`priv/support_matrix.json`, `priv/viewer_evidence/`, `priv/guardrails/`, `scripts/`, `test/`) in the unpacked Hex tarball.
- **REL-02**: Ensure `preflight.ex` adds `mix hex.audit`, `mix deps.audit`, and a `source_ref` parity check.
- **REL-03**: Update `check_changelog_release_tail/1` to accept dated headers (e.g. `## [1.0.0] - YYYY-MM-DD`) instead of strictly `"Unreleased"`.
- **REL-04**: Consolidate `CHANGELOG.md` to a single `1.0.0` entry, including uncatalogued v2.4 features and Phase 78-80 work, and add a "Stability" subsection.
- **REL-06**: The agent must NOT run `git tag` or `git push` autonomously; document these for manual operator execution.

### the agent's Discretion
- Implementation details of regex matching in `preflight.ex`.
- Structure of the consolidated `CHANGELOG.md` entry for 1.0.0.

### Deferred Ideas (OUT OF SCOPE)
- None.
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Hex Package Preflight | CLI (`mix release.preflight`) | Hex CLI | Runs locally or in CI to gate releases before pushing. Validates artifact integrity and metadata. |
| Hex Package Publish | CI/CD (GitHub Actions) | Hex Registry | The actual publish is triggered by a tag (`v*.*.*`) in `.github/workflows/release.yml`. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `mix` | native | Build & Release Automation | Built-in task runner; provides `mix hex.build`, `mix hex.audit`, `mix hex.publish`. |
| `mix_audit` | ~> 2.1 (if needed) | Vulnerability Auditing | Provides `mix deps.audit` to scan for vulnerable dependencies. (Hex itself provides `mix hex.audit` for retired packages). |
| `ex_doc` | ~> 0.40 | Documentation | Consumes `source_ref` in `mix.exs` to link docs back to exact GitHub source tags. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Regex` | native | Pattern Matching | Used for extracting dated headers from `CHANGELOG.md`. |

**Version verification:** 
Verified native Hex and Mix capabilities. No new dependencies strictly required unless `mix_audit` is missing for `deps.audit`.

## Common Pitfalls

### Pitfall 1: Preflight Failing After Tag Cut
**What goes wrong:** The tag is pushed, triggering CI, but `preflight.ex` fails in CI, preventing `mix hex.publish`. The tag is now burned.
**Why it happens:** The changelog wasn't updated correctly, or `source_ref` was missing.
**How to avoid:** Run `mix release.preflight` locally before cutting the tag, or ensure the CI workflow strictly gates on `preflight.ex`. The workflow already runs `mix release.preflight` before `mix hex.publish`.

### Pitfall 2: Including Operator Files in Tarball
**What goes wrong:** Internal test fixtures, scripts, or evidence artifacts leak into the Hex package, bloating it and violating the package contract.
**Why it happens:** `package/0` files list in `mix.exs` might accidentally glob a directory (like `priv`), or files aren't explicitly ignored.
**How to avoid:** Ensure `preflight.ex` unpacks the dry-run tarball and asserts `File.exists?` returns false for `priv/support_matrix.json`, `priv/viewer_evidence/`, `priv/guardrails/`, `scripts/`, and `test/`.

### Pitfall 3: Missing `source_ref` Parity
**What goes wrong:** ExDoc points to `main` branch code instead of the specific `v1.0.0` tag in the published HexDocs.
**Why it happens:** The `docs` function in `mix.exs` omits `source_ref: "v" <> @version`.
**How to avoid:** Enforce its presence via `preflight.ex` before publish.

## Code Examples

Verified patterns from official sources:

### [Tarball File Absence Check]
```elixir
forbidden_files = [
  "priv/support_matrix.json",
  "priv/viewer_evidence",
  "priv/guardrails",
  "scripts",
  "test"
]

found_forbidden = Enum.filter(forbidden_files, fn file ->
  File.exists?(Path.join(dir, file))
end)

if found_forbidden == [] do
  pass("Hex Build Artifacts (Absence Check)")
else
  fail("Hex Build Artifacts", "forbidden files found in unpacked artifact: #{Enum.join(found_forbidden, ", ")}")
end
```

### [Changelog Date Regex]
```elixir
# In lib/mix/tasks/release/preflight.ex
true <- Regex.match?(~r/## \[#{version}\] - (\d{4}-\d{2}-\d{2}|Unreleased)/, changelog)
```

### [source_ref Parity Check]
```elixir
defp check_source_ref_parity(context, version) do
  docs = context.project_config[:docs] || []
  expected_ref = "v#{version}"
  case Keyword.fetch(docs, :source_ref) do
    {:ok, ^expected_ref} -> pass("Source ref parity")
    {:ok, actual} -> fail("Source ref parity", "expected #{expected_ref}, got #{actual}")
    :error -> fail("Source ref parity", "missing source_ref in docs config")
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `## [VERSION] - Unreleased` | `## [VERSION] - YYYY-MM-DD` | 1.0.0 | Enables preflight to pass on the final release commit without reverting to "Unreleased". |
| Broad `priv/` inclusion | Explicit `priv/branded` only | 1.0.0 | Keeps Hex package lightweight and avoids shipping internal proof matrices. |

## Open Questions

1. **`mix deps.audit` Availability**
   - What we know: `mix hex.audit` is built into Elixir/Hex. `mix deps.audit` requires the `mix_audit` package.
   - What's unclear: Does the project already use `mix_audit`? (It's not in `mix.exs` `deps` currently).
   - Recommendation: If `mix deps.audit` fails because the task is not found, the planner should add `{:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}` to `mix.exs` `deps()`.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified beyond native Hex/Mix and standard Elixir tools)
