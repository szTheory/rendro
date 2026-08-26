# Feature Research

**Domain:** Maintainability and existing-catalog quality for a mature Elixir library
**Researched:** 2026-08-26
**Confidence:** HIGH

## Scope Boundary

This is a stewardship milestone, not a new capability milestone. “Features” below are maintainer and contributor outcomes: trustworthy findings, simpler change paths, durable evidence, reliable automation, and closure of known visual debt. Studio, charts, global shaping, new recipes, new presets, and catalog expansion remain outside v2.14.

## Feature Landscape

### Table Stakes

| Outcome | Why expected | Complexity | Acceptance boundary |
|---------|--------------|------------|---------------------|
| Durable quality ledger | A broad quality effort otherwise becomes an unrepeatable review or a list of opinions | MEDIUM | Every finding has evidence, impact, confidence, disposition, owner phase, verification, status, and next trigger |
| Evidence-led triage | Large files, cycles, coverage, or style preferences are not defects by themselves | MEDIUM | High findings are fixed or evidence-rejected; bounded medium findings are fixed; low/style findings do not cause standalone churn |
| Stable public contracts | Mature library cleanup must not surprise users | HIGH | Public API manifest remains compatible and unrelated render goldens stay byte-identical |
| Durable release evidence | Tests and release automation must not break when planning history is archived | MEDIUM | Product/release paths consume versioned repository evidence, not `.planning/milestones/` |
| Repository hygiene | A fresh clone should not contain loose historical phase files or one-off tracked helpers without ownership | LOW-MEDIUM | Historical artifacts live in milestone archives; tracked helpers are referenced, documented, or removed |
| Readable architecture | Contributors need cohesive change points and truthful comments/specs | HIGH | Accepted boundary/readability findings close with focused regression evidence; no line-count quota |
| Trustworthy tests | Test volume must protect behavior rather than implementation trivia or frozen planning prose | HIGH | Duplicated/brittle tests are consolidated without losing failure modes; archival operations cannot break product tests |
| Purpose-named catalog evidence CI | Existing catalog work still needs pinned rendering, but historical phase routes should not accumulate | HIGH | One exact-SHA workflow replaces Phase 126/127/130 generation branches after artifact parity is proven |
| Existing catalog visual closure | Public scored gaps should not remain indefinitely | HIGH | Six named cells reach hierarchy 5 and all other visual dimensions at least 4, with dark print safety still false |
| Decision-ready handoff | The next milestone should not rediscover current debt | LOW | Before/after summary and ranked triggers remain in the current quality ledger and project state |

### Differentiators

| Outcome | Value | Complexity | Notes |
|---------|-------|------------|-------|
| Quality changes carry proof of non-churn | Makes stewardship auditable rather than aesthetic | HIGH | Pair architecture/readability judgment with public API, golden, test, and package checks |
| Deterministic and human quality stay separate | Preserves Rendro’s truthful evidence model even during visual polish | MEDIUM | Automation proves identity/scope; a named reviewer owns visual judgment |
| One ledger spans code, CI, evidence, and catalog debt | Gives maintainers a coherent view without a hosted dashboard | MEDIUM | Keep it concise; archived phase artifacts retain detail |
| Historical planning becomes non-executable | Milestone archival can no longer break current release/test behavior | MEDIUM | Planning may document history but cannot be a runtime authority |

### Anti-Features

| Anti-feature | Why tempting | Why harmful | Better alternative |
|--------------|--------------|-------------|--------------------|
| Refactor every large file | Produces visible activity and smaller files | Can increase indirection and change risk without reducing cognitive load | Extract only a cohesive responsibility with evidence of coupling/churn |
| Achieve a global coverage percentage | Creates an easy numeric target | Line coverage misses branch/assertion quality and can reward low-value tests | Use coverage to locate blind spots, then add behavior-focused tests |
| Maximize `@spec` count | Looks rigorous | Redundant or over-broad private specs can obscure inferred success types | Keep public/boundary specs and private specs that improve analysis |
| Rewrite all comments | Makes the diff look polished | Risks deleting non-obvious invariants or adding narration that rots | Keep “why” and boundary comments; remove stale history/restatement |
| Add new quality dependencies by default | Suggests a comprehensive audit | Expands tool maintenance and may duplicate current checks | Trial only against a demonstrated gap before adoption |
| Score all 32 catalog cells | Appears to finish the catalog | Multiplies human-review cost beyond the agreed problem | Repair the six actual visual gaps; keep twenty explicitly unscored |
| Make dark PDFs print-safe | Could make all dark dispositions pass | Changes the product/evidence boundary into a print-design program | Improve screen readability while retaining `print_safety: false` |
| Add Studio/charts/shaping | Converts stewardship into visible features | Breaks scope, adoption gates, and compatibility focus | Keep them demand-gated for a later milestone |

## Dependencies

```text
Current research
    -> Phase 132 baseline + ledger
        -> accepted finding set
            -> repository/evidence hygiene (133)
            -> architecture/readability (134)
            -> test + CI simplification (135)
                -> generic catalog evidence authority
                    -> catalog repairs/review (136)
                        -> closure + next triggers (137)
```

- **The audit precedes remediation:** prevents a moving target and gives every later change an owner and verification method.
- **Evidence durability precedes test/CI cleanup:** tests and workflows need stable inputs before historical planning routes are removed.
- **Generic catalog workflow precedes visual closure:** the six repaired cells require a non-phase-specific pinned renderer authority.
- **Catalog follows core/CI cleanup:** visual changes should land after byte-identity and evidence gates are stable.
- **Closure follows all work:** before/after reporting must measure the final committed state.

## v2.14 Definition

### Commit to

- [ ] Research current quality practices without adding speculative tools.
- [ ] Create and use a durable quality ledger.
- [ ] Fix or evidence-reject every accepted high-impact finding.
- [ ] Fix bounded medium findings; defer the rest with explicit triggers.
- [ ] Decouple current product/release verification from archived planning files.
- [ ] Replace historical catalog evidence routes with a generic exact-SHA workflow.
- [ ] Repair and re-review six exact catalog cells.
- [ ] Publish verified before/after and next-milestone guidance.

### Defer

- Studio, charts, and global text shaping until their existing triggers are met.
- Review of the twenty unscored catalog cells until a later explicitly funded review window.
- Dependency upgrades not required to close a demonstrated v2.14 finding.
- Broad performance optimization without a measured bottleneck.

## Prioritization

| Outcome | Maintainer/user value | Cost | Priority |
|---------|-----------------------|------|----------|
| Quality ledger and baseline | HIGH | MEDIUM | P1 |
| Planning/evidence decoupling | HIGH | MEDIUM | P1 |
| High-impact architecture/readability closure | HIGH | HIGH | P1 |
| Generic catalog evidence workflow | HIGH | HIGH | P1 |
| Six-cell visual closure | HIGH | HIGH | P1 |
| Bounded medium cleanup | MEDIUM | MEDIUM | P2 |
| Low/style cleanup | LOW | variable | P3/defer |

## Sources

- User-approved v2.14 milestone summary and decisions (2026-08-26)
- `.planning/PROJECT.md`, `.planning/STATE.md`, and archived v2.10-v2.13 roadmaps
- `mix xref` repository baseline, module-size inventory, workflow topology, and planning-reference scan
- `priv/quality/rubric_scores.json` and `assets/rendro/catalog.json`
- Official tool sources listed in `STACK.md`

---
*Feature research for: v2.14 Quality & Maintainability*
*Researched: 2026-08-26*
