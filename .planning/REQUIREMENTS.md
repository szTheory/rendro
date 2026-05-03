# Requirements: Rendro v1.3

**Defined:** 2026-05-03
**Core Value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## v1.3 Requirements

### Licensing and Metadata

- [x] **REL-01**: `mix.exs` must define a valid open-source SPDX license string, paired with a matching top-level `LICENSE` file.
- [x] **REL-02**: `mix.exs` must contain accurate package metadata (`:description`, `:source_url`, `:links`) and maintainer-facing release copy.

### Documentation Structure and Boundaries

- [ ] **REL-03**: The ExDoc `groups_for_extras` configuration must rationally organize the growing list of guides and reference artifacts.
- [ ] **REL-04**: The README must have appropriate badge state for CI, Hex.pm, and HexDocs.
- [ ] **REL-05**: The project must explicitly define its public API stability policy and release support boundaries (e.g. `usage_rules.md`).

### Release Preflight Proof

- [ ] **REL-06**: The Hex release mechanics (`mix hex.publish --dry-run`) must remain a first-class, verifiable step in the release proof path.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Async artifact manifests or persistence workflows | Deferred to v1.4 |
| Validator-backed compliance/signature surfaces | Deferred to v1.5 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REL-01 | Phase 31 | Planned |
| REL-02 | Phase 31 | Planned |
| REL-03 | Phase 32 | Planned |
| REL-04 | Phase 32 | Planned |
| REL-05 | Phase 32 | Planned |
| REL-06 | Phase 33 | Planned |

**Coverage:**
- v1.3 requirements: 6 total
- Mapped to phases: 6
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-03*
*Last updated: 2026-05-03 after v1.3 Roadmap planning*
ng*
