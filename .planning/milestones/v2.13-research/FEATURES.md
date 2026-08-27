# Feature Research

**Domain:** OSS quality stewardship and adoption readiness for a deterministic, Phoenix-first PDF library
**Researched:** 2026-08-19
**Confidence:** HIGH for shipped-surface and catalog findings; MEDIUM for live adoption evidence because public search snapshots are cached and a fresh gate review must use the live APIs.

## Scope and Evidence Boundary

This is a ratchet on existing product surfaces, not a new feature family. Rendro already has a 32-cell public catalog, deterministic catalog generation/checking, a human rubric, six presets, static configurator/codegen/Livebook routes, a Phoenix example, and an adoption ledger. The outcome is trustworthy evidence that those surfaces work better for a newcomer today.

The 12 flagship catalog cells are exactly the scored brand/preset light-dark pairs for Invoice/Corporate Classic, Statement/Minimal Mono, Receipt/Humanist, Certificate/Editorial, Payslip/Swiss, and Ticket/Brutalist. All 12 currently fail because `content_hierarchy` is 4 where the rubric requires 5. The Humanist dark Receipt additionally scores 2 for reader affordances and typographic craft and 3 for cohesion. Dark cells intentionally retain `print_safety: false`; that is a documented screen-oriented boundary, not a defect to conceal or a reason to claim print/accessibility compliance.

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature / outcome | Why expected | Complexity | Testable acceptance boundary and shipped dependencies |
|---|---|---:|---|
| Improve and re-score all 12 named `Scored — needs work` cells | A public quality disposition invites a clear follow-through; leaving the identified flagship set unresolved makes the catalog feel provisional. | HIGH | For each exact `catalog_id`, update the underlying recipe/theme data only as needed; regenerate its catalog PNG/PDF hashes; preserve catalog schema; record a human re-review whose scores meet `content_hierarchy == 5`, other core dimensions `>= 4`, and applicable gates. Depends on the catalog generator/checker, `rubric_scores.json`, and current recipe/preset behavior. |
| Fix the Humanist dark Receipt before declaring catalog closure | It is the only target with observed sub-4 reader affordance, typography, and cohesion—not just a conservative hierarchy score. | MEDIUM | Deterministic artifact and bounded full-size review show readable description text and scores of at least 4 in those three dimensions, plus hierarchy 5. Keep its dark screen-only disclosure and false print-safety gate. Depends on the Humanist preset, receipt recipe, and pinned advisory raster workflow. |
| Evidence-backed review protocol, not score edits | A quality label is credible only when revised bytes, hashes, rubric entries, and reviewer sign-off identify the same cell. | MEDIUM | A contract test rejects missing/mismatched catalog disposition, hash, score, or review provenance; re-review is bounded to specified artifacts and never auto-generated. Depends on existing hash-checked catalog and rubric manifest contracts. |
| Refresh every adoption gate and record an explicit decision | Quiet OSS projects still need a current, inspectable answer to “what changed?”; stale baseline evidence is not adoption evidence. | LOW-MEDIUM | In one review window, query the live Hex package API, the public issue labels, and merged-PR history; append dated sources/counts and a `HOLD`, `ACCUMULATING`, or `TRIGGER` decision for demand, downloads, and contributor gates. A zero-result is recorded as zero, not inferred. Depends on `ADOPTION.md` counting rules and public APIs/CLI access. |
| Complete newcomer journey evaluation | A Phoenix-first library must prove that discovery leads to a working customized PDF, rather than merely linking to surfaces. | MEDIUM | Execute a clean-environment script/checklist: discover README/HexDocs → add dependency → compile → follow the canonical Swiss invoice route → choose/copy a configurator snippet → apply it in a runnable Phoenix controller/example → request a PDF and verify bytes/content headers. Record exact commands, versions, output, and any documentation repair. Depends on README, presets guide, configurator formatter, Phoenix adapter, and `examples/phoenix_example`. |
| Honest result and scope messaging throughout | Users must not mistake a page-one preview or newcomer smoke test for a guarantee of design quality, WCAG, PDF/UA, all-viewer behavior, or print safety. | LOW | Journey and catalog copy preserve existing bounded disclosures. The test rejects newly broadened claims. Depends on docs-contract lanes and the published support-boundary guide. |

### Differentiators (Competitive Advantage)

| Feature / outcome | Value proposition | Complexity | Notes |
|---|---|---:|---|
| A quality ratchet that closes named public evidence debt | The catalog does not merely display examples: it publishes a shortfall, repairs it, and retains artifact-level proof. This is unusually credible for an OSS PDF library. | HIGH | The differentiator is the linkage of deterministic byte evidence and human judgment, not an aesthetic certification. Do not broaden the review budget into universal quality scoring. |
| One continuous Phoenix newcomer proof | Connects package discovery, a practical preset choice, copied canonical Elixir, and an actual controller response. It proves integration coherence across documentation rather than another isolated unit test. | MEDIUM | Use the canonical Invoice/Swiss/light path as the fixed happy path; test the configurator selection as a customization step. A schematic README snippet alone is explicitly insufficient. |
| Pull-based adoption ledger with a decision even when nothing qualifies | Makes “we are not building global text shaping yet” a reasoned product decision backed by transparent criteria rather than a vague deferral. | LOW | A current HOLD is valuable. The gate stays conjunctive: none of demand, downloads, or contribution alone authorizes a new text-engine capability. |
| Review tooling only where it reduces ambiguity | Full-size sequential review packaging can make the 12-cell decision auditable and repeatable without becoming an end-user visual Studio. | MEDIUM | Keep it an operator/reviewer aid, bounded to target artifacts and source hashes. |

### Anti-Features (Explicitly Unnecessary)

| Anti-feature | Why it may be requested | Why unnecessary/problematic now | Better alternative |
|---|---|---|---|
| New recipes, presets, catalog expansion, or a new rendering capability | Quality work can tempt “more examples” as a visible milestone output. | The project has 32 cells and the task is to improve the 12 known weak flagship cells; adding cells expands evidence debt and obscures whether the ratchet closed. | Repair/review only the named cells and retain the existing catalog shape. |
| Auto-scoring or AI-generated rubric verdicts | It reduces manual review effort. | The rubric is intentionally human judgment; automated scores would create an unsupported quality claim and erase accountable sign-off. | Automate coverage/hash/provenance checks; keep scoring and approval human. |
| Treating dark mode as print-safe or as accessibility/PDF/UA/WCAG certified | Raising visual scores can be misread as a broader guarantee. | The catalog explicitly designates dark cells screen-oriented and currently records false print safety. Changing that requires a distinct compliance/print-evidence program. | Improve on-screen readability while preserving the dark boundary disclosure and gate value. |
| Scheduled growth campaign, analytics, or social-counter adoption metrics | More numbers look like more adoption evidence. | The adopted policy is quiet and pull-based; private analytics and social metrics do not satisfy the text-shaping gate. | Refresh only qualifying public/anonymized evidence using the ledger’s specified sources and rules. |
| Triggering global text shaping from download growth, a dependent package, or one issue | Recent public package evidence may look encouraging. | The gate requires all three threshold families in one review window, including six qualifying shaping signals and a qualifying non-maintainer PR. | Record the factual snapshot and an explicit HOLD/ACCUMULATING/TRIGGER outcome; start a later capability milestone only if the gate actually passes. |
| Replacing the static configurator with hosted live rendering/account features | A newcomer may ask for arbitrary live previews or saved themes. | It widens a library stewardship milestone into deferred Studio/server/DB work and conflicts with the zero-server adoption path. | Validate browse → pick → copy against the existing static configurator and then run the copied code locally. |

## Feature Dependencies

```
Catalog repair (12 exact cells)
    └──requires──> deterministic regeneration + hash update
    └──requires──> bounded human re-review + rubric provenance
    └──requires──> honest dark-cell boundary retained

Humanist dark Receipt repair
    └──blocks──> successful 12-cell quality closure

Newcomer journey evaluation
    └──requires──> canonical README/presets/configurator surfaces
    └──requires──> runnable Phoenix adapter/example path
    └──benefits from──> repaired catalog evidence (choice confidence)

Adoption evidence refresh
    └──requires──> live Hex/GitHub queries in the same review window
    └──produces──> explicit gate decision
    └──does not authorize──> text-shaping work unless all three gates pass
```

### Dependency Notes

- **Repair precedes sign-off:** a changed visual cell must be deterministically regenerated before a person scores it; otherwise the score describes stale bytes.
- **The Humanist dark Receipt is the critical path:** every other target has only the strict hierarchy shortfall. Its low contrast/typographic observation needs an actual repair before its hierarchy review can credibly close the complete 12-cell set.
- **Journey evaluation should follow catalog repair but must be independently executable:** the newcomer needs a working document even if they never use the catalog. The catalog validates discovery and choice; the Phoenix response validates integration.
- **Adoption refresh is independent of catalog repair:** do not manufacture adoption demand from maintenance work. It can run in parallel and records the state found.

## Milestone Outcome Definition

### Launch With (v2.13)

- [ ] All 12 named flagship cells move from `Scored — needs work` to a re-reviewed passing disposition, with regenerated deterministic artifacts/hashes and bounded human sign-off tied to each exact ID.
- [ ] The Humanist dark Receipt clears its documented affordance, typography, and cohesion deficits without claiming print safety or compliance.
- [ ] A machine-checkable provenance/coverage guard ensures the catalog, rubric disposition, and reviewer evidence cannot drift apart.
- [ ] `ADOPTION.md` contains one dated, source-backed refresh and an explicit decision for demand, downloads, and contributor gates—even if the result is `HOLD` for all.
- [ ] A clean Phoenix newcomer journey produces a customized, verified PDF and leaves a durable reproducible record or test; all discovered blockers are fixed in the existing docs/integration surfaces.

### Defer (after evidence, not during v2.13)

- [ ] Global text shaping, RTL/bidi/cluster support—only if the existing conjunctive adoption gate is actually met.
- [ ] Rendro Studio, server-rendered previews, accounts, and arbitrary visual token editing.
- [ ] Catalog growth, additional presets, charts, or new document families.
- [ ] Compliance, accessibility, PDF/UA, WCAG, universal-viewer, or print-certification initiatives.

## Feature Prioritization Matrix

| Feature / outcome | User value | Implementation cost | Priority |
|---|---:|---:|---|
| Humanist dark Receipt repair + evidence | HIGH | MEDIUM | P1 |
| Remaining 11 target-cell hierarchy ratchets + evidence | HIGH | HIGH | P1 |
| Catalog/rubric/provenance fail-loud guard | HIGH | MEDIUM | P1 |
| Complete clean Phoenix newcomer journey | HIGH | MEDIUM | P1 |
| Adoption ledger refresh + explicit decisions | MEDIUM | LOW-MEDIUM | P1 |
| Bounded reviewer ergonomics | MEDIUM | MEDIUM | P2, only if it directly enables the 12-cell review |
| New capability/product surfaces | LOW for this milestone | HIGH | Out of scope |

## Sources

- `.planning/PROJECT.md` — v2.13 goal and no-new-capability constraint.
- `.planning/ROADMAP.md` — current deferred Studio and review-tooling context.
- `assets/rendro/catalog.json` — 32-cell catalog, exact target artifacts, hashes, and dark boundary disclosures.
- `priv/quality/rubric_scores.json` and `priv/quality/SIGN-OFF.md` — rubric thresholds, 12 scored target cells, individual shortfalls, and bounded-human-review precedent.
- `ADOPTION.md` — authoritative text-shaping gate thresholds, baseline, counting rules, and pull-based review policy.
- `README.md`, `guides/presets.md`, and `examples/phoenix_example/` — existing discovery, configurator, canonical preset, and runnable Phoenix paths.
- [Hex package/dependents listing](https://hex.pm/packages/rendro/dependents) — public adoption context only; search-result snapshots are not a substitute for the live API refresh. Confidence: MEDIUM.

---
*Feature research for: Rendro v2.13 Quality Ratchet & Adoption Readiness*
*Researched: 2026-08-19*
