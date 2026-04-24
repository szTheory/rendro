# Pitfalls Research

**Domain:** Elixir-native PDF/document generation library
**Researched:** 2026-04-24
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: HTML/CSS Scope Creep in Core

**What goes wrong:**
The project drifts from native deterministic layout toward browser-renderer parity goals.

**Why it happens:**
Teams optimize for familiarity and broad marketing claims instead of product thesis.

**How to avoid:**
Enforce explicit support matrix and keep HTML/Typst/browser integrations as optional adapters only.

**Warning signs:**
Roadmap items mention CSS fidelity, DOM semantics, or browser-comparison parity as core milestones.

**Phase to address:**
Phase 1 (core architecture contract) and Phase 4 (docs/release truthfulness).

---

### Pitfall 2: Pagination Treated as "Later"

**What goes wrong:**
Library can render simple pages but breaks on multi-page tables/reports, causing unusable v0.1 output.

**Why it happens:**
Pagination complexity is underestimated and deferred behind surface-level API work.

**How to avoid:**
Make pagination and table header repetition first-order success criteria early; block phase completion until deterministic cases pass.

**Warning signs:**
Large-table examples are missing, or pagination behavior is "best effort" with unclear guarantees.

**Phase to address:**
Phase 2 (layout and pagination engine).

---

### Pitfall 3: Optional Dependency Leakage

**What goes wrong:**
Core package accidentally depends on Phoenix/Oban/integration libraries and loses purity guarantees.

**Why it happens:**
Adapter work lands quickly without compile/runtime guards or package boundaries.

**How to avoid:**
Use optional dependencies, explicit guards, and adapter package isolation from day one.

**Warning signs:**
Core tests fail when optional adapters are absent, or core docs require Phoenix to run.

**Phase to address:**
Phase 3 (adapter boundaries and optional integrations).

---

### Pitfall 4: Unverified Claims in Documentation

**What goes wrong:**
README/docs promise compliance/signature/capabilities that implementation cannot verify.

**Why it happens:**
Marketing pressure outruns engineering verification and release discipline.

**How to avoid:**
Adopt docs-contract tests and release gates that fail on unsupported claims.

**Warning signs:**
No automated checks for docs claims; "supports X" statements lack fixture/tests/validator evidence.

**Phase to address:**
Phase 4 (quality, docs, and release hardening).

---

### Pitfall 5: Weak Operational Observability

**What goes wrong:**
Production failures are difficult to diagnose because telemetry and error context are sparse.

**Why it happens:**
Observability is deferred as "ops work" instead of being treated as product capability.

**How to avoid:**
Emit structured lifecycle events and actionable errors in early milestones.

**Warning signs:**
Failures return generic tuples; no render duration/page count/error class metrics.

**Phase to address:**
Phase 1 (event schema) and Phase 3 (production adapter flows).

---

### Pitfall 6: Non-Deterministic Test Artifacts

**What goes wrong:**
Golden fixtures and CI snapshots flap due to unstable object ordering/timestamps/IDs.

**Why it happens:**
Deterministic mode is bolted on after serializer behavior is established.

**How to avoid:**
Design deterministic lane at core renderer level and keep advisory lanes separate.

**Warning signs:**
Fixture updates required without code changes; CI intermittently fails visual/structural checks.

**Phase to address:**
Phase 1 (deterministic render contract) and Phase 4 (verification lanes).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcoding layout edge cases per template | Faster short-term demo output | Explodes maintenance and breaks generality | Acceptable only in throwaway spikes, never in core |
| Mixing adapter logic into core modules | Faster delivery of integrations | Hidden coupling and brittle releases | Never acceptable for OSS core |
| Skipping docs-contract CI checks | Fewer early checks | Trust erosion and support burden | Never acceptable after initial scaffolding |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Phoenix | Building core API around controller concerns | Keep Phoenix helpers in adapter layer over stable core API |
| Oban | Assuming background processing is mandatory | Keep synchronous core path; Oban is optional for scale needs |
| threadline/mailglass/accrue | Shipping hard dependency integrations | Publish recipe/adapter approach with opt-in dependencies |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Full-document in-memory buffering only | Memory spikes on large reports | Add bounded policies and streaming-friendly artifact path | Typically visible at large table/report workloads |
| Unbounded table pagination loops | Render hangs/long timeouts | Guard with max pages/time and explicit overflow failure modes | Medium to large documents |
| Excessive per-block measurement recomputation | Slow render times | Cache stable measurements where safe | Throughput-oriented workloads |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Unbounded asset loading and remote fetch defaults | SSRF/path traversal/resource exhaustion | Default-deny asset resolver with allowlists and size limits |
| Verbose raw error leakage in production | Sensitive data exposure | Structured errors with redaction mode and safe metadata |
| Missing execution bounds | Denial-of-service vectors through huge docs/assets | Policy limits for pages/bytes/image sizes/render duration |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Opaque overflow failures | Users cannot fix templates quickly | Include block path, available/required dimensions, and suggested remediations |
| Inconsistent page break behavior | Low trust in output correctness | Deterministic pagination semantics and fixture-driven regression tests |
| Undocumented constraints | Frustrating onboarding and rework | Explicit support matrix + executable examples in docs |

## "Looks Done But Isn't" Checklist

- [ ] **Pagination:** Multi-page table headers verified with deterministic fixtures and real sample data.
- [ ] **Errors:** Structured error payload includes what/where/why/next guidance.
- [ ] **Adapters:** Core compiles and tests cleanly with all optional adapters disabled.
- [ ] **Docs:** Every major claim is covered by docs-contract or integration test.
- [ ] **Release:** Version/tag parity and publish dry-run checks pass before release.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Scope creep into HTML/CSS core | HIGH | Re-baseline roadmap to native scope, move browser needs to adapters |
| Missing pagination quality | HIGH | Pause new features; add focused pagination test corpus and fix engine invariants |
| Docs claims drift | MEDIUM | Add/repair docs-contract checks, audit support matrix, issue corrective release notes |
| Adapter leakage | MEDIUM | Extract adapter concerns to optional packages and restore core boundaries |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| HTML/CSS scope creep | Phase 1 + Phase 4 | Roadmap scope audit and docs support-matrix checks |
| Pagination deferred | Phase 2 | Multi-page table fixture suite passes deterministically |
| Optional dependency leakage | Phase 3 | Core compiles/tests with optional deps disabled |
| Unverified documentation claims | Phase 4 | Docs-contract CI lane green and release checklist pass |
| Weak observability | Phase 1 + Phase 3 | Telemetry/error schema validated in example and adapter flows |
| Non-deterministic artifacts | Phase 1 + Phase 4 | Deterministic lane stable across repeated CI runs |

## Sources

- `prompts/rendro-gsd-seed.md`
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md`
- `prompts/rendro-oss-dna.md`
- `prompts/rendro-integration-opportunities.md`

---
*Pitfalls research for: Elixir-native PDF generation*
*Researched: 2026-04-24*
