# Phase 80: Stability Contract & Migration Docs - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Rendro's **public guides** state the formal `1.0` stability promise so an external adopter understands exactly what 1.0 covers. Concretely (STAB-01..05):

- Rewrite `guides/api_stability.md` to lead with the **two-tier SemVer contract** (Tier-1 Stable strict SemVer core / Tier-2 Evolving adapters + diagnostics/metadata, additive-only), the **byte-output carve-out** ("deterministic within a version, not frozen across versions"), an explicit **"NOT covered by SemVer"** list, and a **soft-deprecate-first** deprecation policy + Deprecations table.
- Create `guides/upgrading_to_1.0.md`, wire it into `mix.exs` ExDoc `extras` under the **Policies** group.
- **Scrub internal milestone/phase labels** ("Rendro v1.10", "Phase 53", "Phase 71", "v2.x") from public guides, updating string-pinned docs-contract tests in lockstep so `release-proof` stays green.
- Add `test/docs_contract/api_stability_claims_test.exs` proving every named Tier-1 symbol exists + tier headers + key promise sentences + upgrade-guide presence.

**This phase is documentation + one new docs-contract test. No new public API, no engine changes, no version bump (that's Phase 81), no CHANGELOG `## [1.0.0]` entry (that's Phase 82).**

</domain>

<decisions>
## Implementation Decisions

All four gray areas were researched in parallel (grounded in the actual pinned tests + Elixir/Oban ecosystem precedent) and locked by the user. Calibration: `minimal_decisive` — one researched recommendation per area, accepted as written.

### Guide Rewrite Structure (STAB-01/02)
- **D-01: Contract-first restructure (Option A).** Rewrite `api_stability.md` so the two-tier stability contract + deprecation policy/table **lead** the document; relocate the six existing per-surface `## … Support Boundary` blocks (forms, signing prep, signed artifact, long-lived, embedded files, curated links, protection, embedded-artifact viewer posture) **verbatim** below a clearly subordinate heading.
- **D-02: Zero forced test churn is achievable — and is the bar.** Every assertion against `api_stability.md` across `test/docs_contract/*.exs` is a **position-independent `guide =~ "substring"`** match; there are NO line-number/ordering regexes against the guide (the only `.*?` ordering regexes target `priv/support_matrix.json`, which this phase does not touch). Therefore moving sections does NOT break CI — only rewording/deleting a pinned substring does. **Move the per-surface blocks byte-identical.** Verify with `mix test test/docs_contract/` + the `release-proof` lane before commit.
- **D-03: New carve-out / "NOT covered" prose must not trip the `refute` guards.** Do not introduce banned overclaim phrases (e.g. "secure PDF", "PAdES is supported", "all signature viewers are supported", "PDF/A compliant"). Any NEW Tier-1 symbol string the rewrite adds must be pinned by `api_stability_claims_test.exs` in the SAME commit (lockstep rule).

### Internal-Label Scrub Scope (STAB-04)
- **D-04: Scrub ALL leaking public guides (Option A), not just the requirement-enumerated ones.** Empirically only `guides/api_stability.md` and `guides/viewer_evidence.md` contain internal labels; the other 6 ExDoc extras (README, integrations, branding, page_primitive, recipes, user_flows_and_jtbd) are already clean — verified, no action. Half-scrubbing reopens the gray area next phase and violates success criterion 4.
- **D-05: Only TWO leaks are CI-pinned — update both in lockstep, preserving the substantive claim, dropping only the label:**
  - `protection_claims_test.exs:48` — `"Rendro v1.10 supports only \`:aes_256\`"` → `"Rendro supports only \`:aes_256\`"` (guide line ~128).
  - `protection_claims_test.exs:56` — `"Phase 53 does not introduce a first-party protected worker or orchestration API."` → `"Rendro does not introduce a first-party protected worker or orchestration API."` (guide line ~136).
- **D-06: All other occurrences are free edits (no guide-test coupling):**
  - `api_stability.md` free-prose label edits: lines ~54 ("during Phase 71 review" → "during operator review"), ~118 ("after Phase 71 re-verify" → drop / "on the version recorded"), ~148 ("during Phase 71 operator review" → "during operator review"), ~155 ("after Phase 71 re-verify; v1.9 deferral stands" → "on the version recorded; the deferral stands").
  - `viewer_evidence.md` free-prose label edits at lines ~31, ~59, ~97, ~109 (v2.3), ~157 (v2.3), ~190, ~327 (Phase 69 plan pointer), ~329 — reword to timeless language (drop "Phase 70/71", "v2.3").
  - **Test title/comment renames (no guide coupling, hygiene only):** `signing_claims_test.exs:33` title "…terminal after Phase 71" → drop label; `viewer_evidence_claims_test.exs:94` title "…documents Phase 71 deferral templates" → drop label; `embedded_artifact_claims_test.exs:38` comment "…per Phase 71 re-verify" → "…on the version checked".
- **D-07: Do NOT touch the negative guards.** `viewer_evidence_claims_test.exs:106-107` are `refute` assertions that internal-checklist wording is ABSENT — they ENFORCE the scrub; keep them. `required_checks_contract_test.exs` / `release_preflight_test.exs` label refs assert internal CLI/metadata output, not public guides — out of scope.

### Tier-1 Claims Test Scope (STAB-05)
- **D-08: Guide-named symbols only (Option A) — single-responsibility CLAIMS test.** STAB-05 verifies the guide PROSE is true; it is DISJOINT from Phase 79's `public_api_contract_test.exs` (which already owns manifest==code surface equality, exactly-one-tier-tag, and Tier-1 `@spec` coverage). Do NOT reconcile against the full 27-stable/18-adapter manifest — that duplicates Phase 79 and forces the guide to enumerate all 45 modules instead of its intentional curated core.
- **D-09 (LANDMINE): the current guide names `Rendro.Inspector`, which is NOT in the stable manifest.** This is exactly the prose-vs-reality drift STAB-05 exists to catch. The rewrite MUST reconcile: either stop naming `Rendro.Inspector` as Tier-1, or only name symbols that actually exist in the stable tier. STAB-05 then asserts existence of whatever survives.
- **D-10: STAB-05 assertion set** (mirror the `signing_claims_test.exs`/`protection_claims_test.exs` idiom — `guide = File.read!("guides/api_stability.md")`, false-pass-guarded existence checks like Phase 79's lane):
  1. **Symbol existence — only what the rewritten prose names.** Modules via `Code.ensure_loaded?/1` (e.g. `Rendro.Document`, `Rendro.PageTemplate`, `Rendro.Section`, `Rendro.Metadata`, `Rendro.Artifact`, `Rendro.Sign`, `Rendro.Protect`, `Rendro.Adapters.PyHanko`, `Rendro.Adapters.Qpdf`); functions via `function_exported?/3` after ensure_loaded (e.g. `Rendro.flow/2`, `Rendro.signature_field/2`, `Rendro.render_signed/3`, `Rendro.render_protected/3`, `Rendro.Sign.{prepare,sign,augment,validate}/2`, `Rendro.Protect.password/2`); struct presence for `%Rendro.Artifact{}`. A missing symbol must FAIL (guard against false pass).
  2. **Tier/section headers** via `guide =~` — the exact header strings the rewrite ships (two-tier contract headers, deprecation policy header, "NOT covered by SemVer" header).
  3. **Key promise sentences** via verbatim `guide =~` full-sentence assertions.
  4. **Upgrade-guide presence** — assert `File.exists?("guides/upgrading_to_1.0.md")` (do NOT assert its contents — that's its own concern).
  5. **`verify_docs.exs` lane registration** — assert the new lane label/path is registered (matches sibling claims tests; this is the docs-contract guardrail-lockstep pattern from Phases 76/79).

### Upgrade Guide + Carve-out Content (STAB-01/03)
- **D-11: `upgrading_to_1.0.md` = reassurance-first + "new since 0.3.0" digest (Option B).** Open with "1.0 is a stability commitment, not a rewrite — if you're on 0.3.x no code changes are required." Then: two-tier contract summary; a short DIGEST of what consolidation delivered (v2.3 viewer evidence, v2.4 batteries-included recipes, formal tiers + deprecation policy); support-matrix pointer.
- **D-12: Forward-pointing rule (dependency-safe).** The consolidated `## [1.0.0]` CHANGELOG entry is written LATER in Phase 82 (REL-04). This Phase-80 guide must NOT deep-link an anchor inside that unwritten section — link the CHANGELOG **generically** ("see the CHANGELOG") and point substantive support claims at `api_stability.md` (which exists and is what STAB-05 asserts). Phase 82 closes the loop with the reciprocal CHANGELOG→guide link.
- **D-13: "NOT covered by SemVer" list (exact bullets for `api_stability.md`):**
  1. **Byte-for-byte rendered PDF output across versions** (headline; deterministic WITHIN a version — layout/shaping/rendering fixes may change bytes in any minor).
  2. **Internal modules/functions** marked `@moduledoc false` / `@doc false` (e.g. `Rendro.PDF.CidFont`, `Rendro.PDF.FontSubsetter`, the `redact_*` helpers). Public ≡ what ExDoc renders.
  3. **Exact shape of `:diagnostics` / metadata maps beyond documented common keys** (Tier-2 additive-only — documented common keys are stable, additive keys may appear any release).
  4. **Adapter APIs that track upstream library majors** (`Rendro.Adapters.*` — Tier-2, may break to follow underlying tools' majors).
  5. **Error-message *wording*** (presence/category of an error is contract; the human-readable string is not).
  6. **Log/telemetry message *text*** (documented event names/measurements are covered; free-text descriptions are not).
- **D-14: EXCLUDE the support-matrix contents from the "NOT covered" list.** The matrix is an evidence-backed *covered* contract (the existing "Viewer Evidence and CHANGELOG Discipline" section already requires CHANGELOG entries for promotions/deferrals). Listing it as "not covered" would contradict that discipline. (The operator artifact FILES `priv/support_matrix.json` / `priv/viewer_evidence/` ship outside the Hex tarball — that's a Phase-81 packaging concern, not a SemVer carve-out.)
- **D-15: Deprecations table ships TRUTHFUL (Option A+).** Table contains a single `_None as of 1.0.0_` sentinel row (columns: Symbol | Soft-deprecated `@doc deprecated:` | Hard-deprecated `@deprecated` | Removed | Replacement). The soft-deprecate-first lifecycle is shown via an **illustrative fenced example in the policy PROSE** (clearly marked "example, not a live deprecation"), never as a fake table row. STAB-05/docs-contract test asserts the table **header columns** + the `None as of 1.0.0` sentinel row.
- **D-16: Soft-deprecate-first is mandatory because `mix ci` compiles `--warnings-as-errors`.** A hard `@deprecated` on a symbol with in-tree callers would break the build. Policy: `@doc deprecated:` + CHANGELOG by default → `@deprecated` hard-warning only once no in-tree caller remains → removal only in `2.0`.

### Claude's Discretion
- Exact prose wording, heading text, and ordering within the rewritten guide and the new upgrade guide (subject to D-02's byte-identical-move constraint for the relocated per-surface blocks, and D-03's banned-phrase constraint).
- The precise final list of symbols named in the rewritten guide prose (D-09 reconcile) and therefore asserted by STAB-05 — planner/executor resolve `Rendro.Inspector` during the rewrite.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Locked requirements & scope
- `.planning/REQUIREMENTS.md` — STAB-01..05 (locked: two-tier contract, byte-output carve-out, soft-deprecate-first, `upgrading_to_1.0.md`, label scrub, Tier-1 claims test) + the v2.5 scope note. **Read before planning.**
- `.planning/ROADMAP.md` §"Phase 80" — goal + 5 success criteria (what must be TRUE).

### Files this phase edits/creates
- `guides/api_stability.md` — the rewrite target (155 lines; currently SemVer section + per-surface boundaries). **Lead with two-tier contract; relocate boundary blocks verbatim (D-01/D-02).**
- `guides/upgrading_to_1.0.md` — NEW (D-11/D-12).
- `guides/viewer_evidence.md` — internal-label scrub target (D-04/D-06).
- `mix.exs` §ExDoc `extras` + `groups_for_extras` Policies group (~lines 108-130) — add `guides/upgrading_to_1.0.md` to both.
- `test/docs_contract/api_stability_claims_test.exs` — NEW (D-08/D-10).
- `scripts/verify_docs.exs` — register the new claims lane (D-10 item 5; mirrors the Phases 76/79 guardrails-lockstep pattern).

### Lockstep test edits (preserve claims, drop labels)
- `test/docs_contract/protection_claims_test.exs` lines 48, 56 — the ONLY two CI-pinned label leaks (D-05).
- `test/docs_contract/signing_claims_test.exs:33`, `viewer_evidence_claims_test.exs:94`, `embedded_artifact_claims_test.exs:38` — test title/comment renames only (D-06).
- **Keep:** `viewer_evidence_claims_test.exs:106-107` (`refute` guards enforcing the scrub — D-07).

### Cross-phase context (do not duplicate)
- `test/docs_contract/public_api_contract_test.exs` — Phase 79's lane. Owns manifest==code surface equality, one-tier-tag, Tier-1 `@spec` coverage. **STAB-05 must stay disjoint from this (D-08).**
- `priv/public_api.json` — 27 stable / 18 adapter tier manifest (Phase 78). Source of truth for tiers; confirms the guide names a curated subset, not all 45 (D-08/D-09).
- `priv/support_matrix.json` — evidence-backed covered contract; the support-matrix pointer in the upgrade guide targets the boundary sections of `api_stability.md` (D-14).

### Ecosystem precedent (for guide framing)
- Elixir "Compatibility and deprecations" (hexdocs.pm/elixir/compatibility-and-deprecations.html) — scopes guarantees to documented APIs; soft (`@doc deprecated:`) vs hard (`@deprecated`) split.
- Elixir "Library guidelines" + `Module` docs — `@deprecated` / `@doc deprecated:` conventions.
- Oban "Upgrading to v2.0" (hexdocs.pm/oban/v2-0.html) — reassurance-first upgrade-guide framing, "extracted and expanded from the CHANGELOG."

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`*_claims_test.exs` idiom** — `guide = File.read!("guides/X.md")` then position-independent `assert guide =~ "..."` substring pins. STAB-05 copies this exactly; `signing_claims_test.exs` / `protection_claims_test.exs` are the closest templates.
- **Phase 79 false-pass-guard pattern** — `public_api_contract_test.exs` uses `Code.ensure_loaded?` guards so a renamed/deleted symbol FAILS (not silently passes). STAB-05's symbol-existence checks must adopt the same guard (D-10 item 1).
- **Guardrails-lockstep triple** (Phases 76/79) — adding a docs-contract lane registers it in `scripts/verify_docs.exs` and is asserted by a contract test. STAB-05 follows the same registration discipline (D-10 item 5).

### Established Patterns
- **Position-independent pins** — no docs-contract test asserts line numbers/ordering against any guide; ordering regexes target only `support_matrix.json`. This is what makes the D-01 restructure zero-churn (D-02).
- **`refute` guards** enforce absence of internal/overclaim wording (e.g. `viewer_evidence_claims_test.exs:106-107`) — the scrub must not violate these and must not add banned overclaim phrases (D-03/D-07).
- **Claims tests verify PROSE; contract tests verify manifests/schemas** — the hard line that keeps STAB-05 (claims) disjoint from Phase 79 (contract) (D-08).

### Integration Points
- ExDoc `extras` + `groups_for_extras` Policies group in `mix.exs` — where `upgrading_to_1.0.md` plugs in alongside `api_stability.md` + `viewer_evidence.md`.
- `release-proof` required CI lane runs the docs-contract suite — the gate the lockstep edits (D-05) must keep green.

</code_context>

<specifics>
## Specific Ideas

- "Public ≡ what ExDoc renders" — the project's locked definition of the public surface; the carve-out list (D-13) leans on it for the internals bullet.
- Tier vocabulary is fixed: **Tier-1 Stable** (strict SemVer core) / **Tier-2 Evolving** (adapters + diagnostics/metadata, additive-only) — must match `priv/public_api.json` tag vocabulary (`stable` / `adapter`).
- Byte-output carve-out headline phrasing: "deterministic within a version, not frozen across versions."

</specifics>

<deferred>
## Deferred Ideas

- **`@doc since:` retrofitting across the 0.x surface** — out of scope (REQUIREMENTS.md: would misstate history; adopt going-forward only).
- **CHANGELOG `## [1.0.0]` consolidation entry** — Phase 82 (REL-04). Phase 80 only points forward generically (D-12).
- **Version bump / `source_ref` / package links / `:mix_audit`** — Phase 81 (REL-01). Not Phase 80.
- **Tarball allowlist audit (operator/evidence artifacts absent from Hex package)** — Phase 81 (REL-02). The "operator files ship outside the tarball" note in D-14 is descriptive only; enforcement is Phase 81.
- **release-please / conventional-commits** — deferred post-1.0 (AUTO-01).

None of the above is in scope for Phase 80 — discussion stayed within the stability-docs boundary.

</deferred>

---

*Phase: 80-stability-contract-migration-docs*
*Context gathered: 2026-05-30*
