---
candidate_commit_sha: 52d0410fe16d9fa8085c3fb5a4d802db70f18ea9
version: 1.3.0
release_ref: v1.3.0
package_checksum: d10c9a7b0ec04519a1248e298c3d858dd4f7f64eaf951734893dd3384ff853bd
tag_pushed: false
hexdocs_dispatched: false
registry_mutated: false
---

# Rendro v1.3.0 Release Candidate

The exact code-bearing release candidate is
`52d0410fe16d9fa8085c3fb5a4d802db70f18ea9`. This record is committed after
that candidate so it can state its identity without a self-referential Git hash.

## Candidate facts

- Version and source reference: exact `1.3.0` / `v1.3.0`.
- Package archive checksum: `d10c9a7b0ec04519a1248e298c3d858dd4f7f64eaf951734893dd3384ff853bd`.
- Archive inventory includes `README.md`, `guides/presets.md`,
  `assets/rendro/configurator/index.html`, the curated fonts, `NOTICE`, and
  `priv/adoption_evidence/2026-08-21.json`.
- `mix ci.fast`, `mix release.preflight`, and `mix hex.publish --dry-run`
  completed successfully against the candidate surface.
- Local tag absence check passed: `git tag -l v1.3.0` produced no output.
- HexDocs dispatch inputs are fixed to
  `candidate_commit_sha=52d0410fe16d9fa8085c3fb5a4d802db70f18ea9` and
  `release_ref=v1.3.0`; the workflow requires both exact values and runs in the
  protected `Hex Publish` environment.

## No-mutation proof

- `tag_pushed: false` — no annotated tag was created or pushed.
- `hexdocs_dispatched: false` — no GitHub workflow dispatch occurred.
- `registry_mutated: false` — no Hex or HexDocs publication occurred.

This candidate preparation is not release authorization. Only the next
blocking-human decision may authorize all three mutations together: tag push,
protected Hex publication, and protected candidate-bound HexDocs publication.

## Superseded approval

The prior candidate `68c3a630aa071e34faf464f96d7f767641b2e8aa` lacked an
executable verifier boundary: its planned verifier command could exit zero
without producing a record. Its candidate facts and any approval tied to it are
superseded and non-transferable. Only an explicit approval naming
`52d0410fe16d9fa8085c3fb5a4d802db70f18ea9` may authorize the complete tag,
Hex, and HexDocs mutation set.
