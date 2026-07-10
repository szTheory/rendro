# Contributing

## Purpose

This guide keeps local verification aligned with Rendro's CI merge gate. Rendro is a pure-Elixir PDF layout library, so contributor checks should be reproducible with Mix commands before a pull request depends on GitHub Actions.

## CI Execution Model

The root command for the required merge gate is:

```sh
mix ci
```

`mix ci` runs the same required gate families used by CI: the fast deterministic lane followed by integration proofs. Advisory checks are intentionally separate so local contributors can reproduce the required gate without pulling in every optional observer or network-sensitive audit.

The GitHub Actions `test` job splits the fast lane into named steps for readable logs and step timings, but the commands are still represented locally by `mix ci.fast`.

## Local Commands

Use these commands depending on the failure you are reproducing:

| Command | Use |
|---------|-----|
| `mix ci.fast` | Required fast lane: formatting, Hex package build, compile warnings, default tests, docs, Credo, and Dialyzer. |
| `mix ci.proofs` | Required integration proof lane for live PDF tooling, signing, and release preflight proof checks. |
| `mix ci` | Full required merge gate: `ci.fast` followed by `ci.proofs`. |
| `mix ci.advisory` | Optional advisory lane for raster snapshots, launch artifacts, comparison, Livebook, PDF.js observer, and dependency audits. |
| `mix verify.flake` | Quarantined flaky-test lane for tests tagged `:quarantine`. |

When a CI step fails, start with the matching scoped command rather than running everything. For example, a Credo failure maps to `mix credo --strict` and a default test failure maps to:

```sh
mix test --exclude quarantine --slowest 10
```

## Reproducing Seed-Dependent Failures

ExUnit prints the seed at the end of every run. Re-run the same seed locally before changing a test:

```sh
mix test --seed 123456
```

For quarantined flakes, use the quarantine lane first:

```sh
mix verify.flake
```

If a quarantined test only fails under a specific seed, combine the tag and seed explicitly:

```sh
mix test --include quarantine --only quarantine --seed 123456
```

## Optional Tooling

Some proof and advisory commands require external tools or network access, such as PDF viewers, signing utilities, Node dependencies for the PDF.js observer, or Hex audit services. If those tools are not installed locally, reproduce the failing scoped Mix command first, then use the corresponding GitHub Actions job logs for environment-specific failures.

## Before Opening a Pull Request

Run the smallest relevant command while iterating. Before asking for review on pipeline or release-sensitive changes, run:

```sh
mix ci.fast
```

Run `mix ci` when the change touches CI, release proofing, signing, embedded files, viewer evidence, or other integration-sensitive surfaces.
