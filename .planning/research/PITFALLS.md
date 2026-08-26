# Pitfalls Research

**Domain:** Quality cleanup in a deterministic, evidence-heavy Elixir library
**Researched:** 2026-08-26
**Confidence:** HIGH

## Critical Pitfalls

### 1. Cleanup churn masquerading as quality

**Failure:** Large diffs rename, split, or reformat working code without reducing risk or change cost.

**Prevention:** Phase 132 records evidence and a verification method before remediation. Size, coverage, xref counts, and style opinions are signals only. Low/style findings never justify standalone churn.

**Warning signs:** “Consistency” is the only rationale; no characterization test; public/golden changes are mixed into the refactor; the ledger has no before/after claim.

**Phase:** 132 defines the gate; 134 enforces it.

### 2. Metric gaming

**Failure:** Coverage, module length, function count, or dependency counts improve while readability or correctness worsens.

**Prevention:** Use metrics to locate questions, then require behavioral evidence and human cohesion review. Do not set a global coverage or file-size threshold.

**Warning signs:** Tests execute lines without asserting outcomes; one large cohesive function becomes several pass-through helpers; runtime cycles are removed through service-locator indirection.

**Phase:** 132 and 134.

### 3. Planning history remains executable

**Failure:** A normal milestone archive breaks tests or release automation because current behavior reads `.planning/phases` or `.planning/milestones`.

**Prevention:** Extract machine facts into versioned durable evidence, schema-check them, and prohibit product/release paths from consuming archived planning. Keep an explicit exception only for GSD-owned planning tools.

**Warning signs:** `File.read!` of an archived phase in tests; workflow arguments point into `.planning/milestones`; an archive-path edit is needed after every closeout.

**Phase:** 133.

### 4. Generic CI becomes less secure than phase-specific CI

**Failure:** Removing literal phase routes also removes exact-SHA validation, renderer pinning, permission limits, or artifact scope fences.

**Prevention:** Preserve every existing authority check in the generic workflow, validate typed inputs, use `contents: read`, never expose secrets, and emit artifacts rather than repository writes. Treat caches as untrusted.

**Warning signs:** checkout accepts a branch; input appears in shell without validation; artifact name omits SHA/run attempt; generation and publication share credentials.

**Phase:** 135.

### 5. Tests become cleaner but weaker

**Failure:** Duplicate or brittle tests are deleted without retaining the distinct behavior or failure mode they protected.

**Prevention:** Build a behavior/failure inventory before consolidation. The replacement must demonstrate teeth by failing when the protected contract is broken.

**Warning signs:** assertions disappear because they look repetitive; a schema/string contract is replaced with a broad smoke test; only snapshot equality remains.

**Phase:** 135.

### 6. Spec and comment zealotry

**Failure:** A blanket campaign either removes crucial invariants or adds redundant prose/specs that drift.

**Prevention:** Keep public/boundary specs and “why” comments. Remove stale phase narration, mechanical restatement, and private specs that are misleading or add no analysis value. Verify with docs warnings and Dialyzer.

**Warning signs:** comment count is used as a target; public behavior loses documented error boundaries; specs broaden to `term()` merely to silence analysis.

**Phase:** 134.

### 7. Visual repair broadens the product claim

**Failure:** Better dark screenshots are recorded as print safety, accessibility, PDF/UA, WCAG, or universal viewer support.

**Prevention:** Score visual dimensions independently from the false dark print-safety gate. Keep all existing boundary copy and require docs-contract overclaim checks.

**Warning signs:** `passed` is forced true by editing a derived status; false print safety changes without print evidence; twenty unscored cells are silently labeled reviewed.

**Phase:** 136.

### 8. Research/ledger becomes another stale documentation surface

**Failure:** v2.14 writes a comprehensive report that is never updated and obscures current truth.

**Prevention:** Keep detailed analysis in archived phase artifacts and make `QUALITY.md` a concise current ledger. Phase 137 must populate before/after and next triggers; future milestones update or explicitly supersede it.

**Warning signs:** duplicate finding lists disagree; resolved items remain active; no dates, commands, or resolution references.

**Phase:** 132 and 137.

## Technical Debt Patterns

| Shortcut | Immediate benefit | Long-term cost | When acceptable |
|----------|-------------------|----------------|-----------------|
| Delete code based only on no textual callers | Fast cleanup | Dynamic/protocol/Mix task entry points may be missed | Only after compile/runtime/package/task ownership checks |
| Add an ignore/suppression | Green gate | Hidden stale debt | Only with narrow evidence, owner, and re-review trigger |
| Combine refactor with behavior repair | Fewer commits | Impossible attribution and risky rollback | Only when separation is technically impossible and explicitly justified |
| Keep phase-number workflow routes “just in case” | Avoid migration | CI grows indefinitely and authorities become unclear | Never after generic parity is proven |
| Copy archived evidence to a new path without schema | Quick decoupling | Same ambiguity in a different directory | Never; extract/validate stable facts |
| Re-score catalog from thumbnails or prior files | Faster review | Judgment describes stale or incomplete bytes | Never |

## Integration Gotchas

| Integration | Common mistake | Correct approach |
|-------------|----------------|------------------|
| Mix xref and internal APIs | Treat runtime cycles as compile-cycle failures | Inspect edge labels and actual change cost before acting |
| Dialyzer and private specs | Add broad specs to suppress a warning | Fix the deepest real mismatch or remove a misleading spec with proof |
| Coverage and test quality | Enforce one global percentage | Use uncovered regions to ask which behavior/failure is missing |
| GitHub workflow inputs | Interpolate unvalidated input into shell | Validate exact enum/SHA, quote variables, compare checked-out HEAD |
| Caches and trusted workflows | Restore arbitrary executable cache contents in privileged jobs | Scope keys, save on trusted triggers, never cache secrets/evidence authority |
| Catalog generator and human rubric | Update scores as part of generation | Generate identity evidence first; human review owns judgments separately |

## Performance Traps

| Trap | Symptom | Prevention |
|------|---------|------------|
| Run the 32-cell renderer for every local edit | Slow iteration and accidental artifact churn | Use focused deterministic tests locally and controlled exact-SHA renderer checkpoints |
| Split tests without measuring startup/compile cost | More jobs but longer CI and duplicate compilation | Baseline wall time and critical path before changing job topology |
| Expand Dialyzer flags across all code at once | High-noise remediation milestone | Trial against representative modules and record signal/noise |
| Optimize large modules without profiles | Complicated code and unchanged runtime | Performance findings require reproducible inputs and measured before/after |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Catalog workflow can check out an unchecked ref | Reviewer/canonical evidence does not identify source | Exact forty-hex SHA input and literal HEAD equality |
| Cache writes from low-trust context | Poisoned code/dependency cache reaches trusted run | Restore-only low-trust use; save from trusted triggers |
| Evidence workflow receives publish credentials | Generation compromise can mutate external state | Read-only permissions, no publish secrets, artifact-only output |
| Cleanup logs or manifests expose release secrets | Credential/privacy leak | Retain existing redaction and bounded evidence fields |

## Looks Done But Is Not

- [ ] `mix ci.fast` is green but product/release tests still read archived planning.
- [ ] Large modules are smaller but dependency direction or cognitive load did not improve.
- [ ] Coverage increased but no new behavior/failure assertion exists.
- [ ] Historical workflow routes were deleted before generic artifact parity was proven.
- [ ] Six catalog images look better but current hashes, source PDFs, reviewer identity, or boundaries are stale.
- [ ] Every high finding is “resolved” but some were silently downgraded without evidence.
- [ ] The milestone closes without current deferred triggers and next-milestone options.

## Pitfall-to-Phase Mapping

| Pitfall | Phase | Verification |
|---------|-------|--------------|
| Cleanup churn / metric gaming | 132 | Ledger disposition contract and baseline evidence |
| Planning history executable | 133 | Planning-reference prohibition plus release/newcomer regression tests |
| Spec/comment zealotry | 134 | Docs, Dialyzer, public manifest, and focused review |
| Weaker tests / insecure generic CI | 135 | Teeth tests, YAML/permission/input/artifact contracts, remote artifact parity |
| Visual overclaim | 136 | Current human records, derived manifest, catalog/docs-contract checks |
| Stale ledger | 137 | Before/after, closed high findings, deferred triggers, next-milestone handoff |

## Sources

- Official sources in `STACK.md`
- Current Rendro source/test/xref/workflow/catalog evidence inspected 2026-08-26
- Archived v2.11-v2.13 verification and closeout regressions

---
*Pitfalls research for: v2.14 Quality & Maintainability*
*Researched: 2026-08-26*
