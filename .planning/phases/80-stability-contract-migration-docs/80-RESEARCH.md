# Phase 80: Stability Contract & Migration Docs — Research

**Researched:** 2026-05-30
**Domain:** Elixir documentation + docs-contract test authoring (no new public API)
**Confidence:** HIGH — all findings grounded in live repo files; no training-data assumptions used

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Contract-first restructure. Rewrite `api_stability.md` so the two-tier stability contract + deprecation policy/table **lead** the document; relocate the six existing per-surface `## … Support Boundary` blocks (forms, signing prep, signed artifact, long-lived, embedded files, curated links, protection, embedded-artifact viewer posture) **verbatim** below a clearly subordinate heading.

**D-02:** Zero forced test churn is achievable — and is the bar. Every assertion against `api_stability.md` across `test/docs_contract/*.exs` is a **position-independent `guide =~ "substring"`** match; there are NO line-number/ordering regexes against the guide. Move per-surface blocks byte-identical. Verify with `mix test test/docs_contract/` + the `release-proof` lane before commit.

**D-03:** New carve-out / "NOT covered" prose must not trip the `refute` guards. Do not introduce banned overclaim phrases. Any NEW Tier-1 symbol string the rewrite adds must be pinned by `api_stability_claims_test.exs` in the same commit (lockstep rule).

**D-04:** Scrub ALL leaking public guides (Option A). Empirically only `guides/api_stability.md` and `guides/viewer_evidence.md` contain internal labels; the other 6 ExDoc extras are already clean.

**D-05:** Only TWO leaks are CI-pinned — update both in lockstep, preserving the substantive claim, dropping only the label:
- `protection_claims_test.exs:48` — `"Rendro v1.10 supports only \`:aes_256\`"` → `"Rendro supports only \`:aes_256\`"` (guide line 128).
- `protection_claims_test.exs:56` — `"Phase 53 does not introduce a first-party protected worker or orchestration API."` → `"Rendro does not introduce a first-party protected worker or orchestration API."` (guide line 136).

**D-06:** All other occurrences are free edits (no guide-test coupling):
- `api_stability.md` free-prose label edits: lines 54, 118, 148, 155.
- `viewer_evidence.md` free-prose label edits: lines 31, 59, 97, 109, 157, 190, 327, 329.
- Test title/comment renames: `signing_claims_test.exs:33`, `viewer_evidence_claims_test.exs:94`, `embedded_artifact_claims_test.exs:38`.

**D-07:** Do NOT touch the negative guards. `viewer_evidence_claims_test.exs:106-107` are `refute` assertions that internal-checklist wording is ABSENT — they ENFORCE the scrub; keep them.

**D-08:** Guide-named symbols only (Option A) — single-responsibility CLAIMS test. STAB-05 is DISJOINT from Phase 79's `public_api_contract_test.exs`.

**D-09 (LANDMINE):** The current guide names `Rendro.Inspector`, which is NOT in the stable manifest. The rewrite MUST reconcile: either stop naming `Rendro.Inspector` as Tier-1, or only name symbols that actually exist in the stable tier.

**D-10:** STAB-05 assertion set (mirror `signing_claims_test.exs`/`protection_claims_test.exs` idiom). Five assertion categories: symbol existence, tier/section headers, key promise sentences, upgrade-guide presence, verify_docs.exs lane registration.

**D-11:** `upgrading_to_1.0.md` = reassurance-first + "new since 0.3.0" digest. Open with "1.0 is a stability commitment, not a rewrite."

**D-12:** Forward-pointing rule. Do NOT deep-link the CHANGELOG anchor for `## [1.0.0]` (unwritten until Phase 82). Link generically.

**D-13:** "NOT covered by SemVer" list (exact 6 bullets).

**D-14:** EXCLUDE the support-matrix contents from the "NOT covered" list.

**D-15:** Deprecations table ships with a single `_None as of 1.0.0_` sentinel row. Illustrative deprecation example in prose (clearly marked), never as a fake table row.

**D-16:** Soft-deprecate-first is mandatory because `mix ci` compiles `--warnings-as-errors`. A hard `@deprecated` on a symbol with in-tree callers would break the build.

### Claude's Discretion

- Exact prose wording, heading text, and ordering within the rewritten guide and the new upgrade guide (subject to D-02's byte-identical-move constraint and D-03's banned-phrase constraint).
- The precise final list of symbols named in the rewritten guide prose (D-09 reconcile) — planner/executor resolve `Rendro.Inspector` during the rewrite.

### Deferred Ideas (OUT OF SCOPE)

- `@doc since:` retrofitting across the 0.x surface.
- CHANGELOG `## [1.0.0]` consolidation entry (Phase 82, REL-04).
- Version bump / `source_ref` / package links / `:mix_audit` (Phase 81, REL-01).
- Tarball allowlist audit (Phase 81, REL-02).
- release-please / conventional-commits (AUTO-01).

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STAB-01 | `guides/api_stability.md` rewritten with two-tier SemVer contract, byte-output carve-out, "NOT covered" list | D-01/D-13 fully specify content; D-02 confirms zero test churn from relocation |
| STAB-02 | Deprecation policy (soft-deprecate-first) + Deprecations table added to guide | D-15/D-16 specify content; D-16 verified: `mix ci` compiles `--warnings-as-errors` |
| STAB-03 | `guides/upgrading_to_1.0.md` created; wired into `mix.exs` ExDoc extras + Policies group | D-11/D-12 specify content; mix.exs wiring anchor verified at lines 108-130 |
| STAB-04 | Internal labels scrubbed from public guides; docs-contract tests updated in lockstep | D-04/D-05/D-06/D-07 fully specify scope; all label occurrences enumerated below |
| STAB-05 | `test/docs_contract/api_stability_claims_test.exs` proves named Tier-1 symbols exist + headers + sentences + upgrade-guide presence | D-08/D-09/D-10 specify scope; D-09 landmine confirmed and quantified below |

</phase_requirements>

---

## Summary

Phase 80 is a documentation-only phase with one new docs-contract test file. The 16 locked decisions in CONTEXT.md fully specify what to build; this research answers "are those decisions grounded in the real repo?" The answer is YES — with three important refinements the planner must carry forward.

**Refinement 1 (D-02 verification — CONFIRMED SAFE):** Every assertion against `api_stability.md` in `test/docs_contract/*.exs` is a position-independent `guide =~ "substring"` match. No ordering or line-number regexes target the guide. The only `~r/.*?/` ordering regexes target `priv/support_matrix.json`. The "Explicit Deferral Reasons (matrix-mirrored)" section at guide lines 144–155 has one subtlety: `viewer_evidence_claims_test.exs:74-83` takes the first 40 characters of each `evidence_deferred` string from `priv/support_matrix.json` and asserts those 40 chars appear in the guide. Both Phase-71-containing deferral reasons produce 40-char prefixes that appear BEFORE the "Phase 71" text; D-06 rewording of lines 148 and 155 is confirmed safe for these assertions.

**Refinement 2 (D-09 landmine — CONFIRMED AND QUANTIFIED):** `Rendro.Inspector` is named in the current guide (line 17) but its manifest tier is `adapter`, not `stable`. STAB-05 must assert only symbols that the REWRITTEN prose names — so the rewrite must either (a) drop `Rendro.Inspector` from named Tier-1 symbols or (b) clearly present it as a Tier-2 diagnostics helper. All other D-10 symbols (`Rendro.Document`, `Rendro.Section`, `Rendro.Metadata`, `Rendro.Artifact`, `Rendro.Sign`, `Rendro.Protect`) are `stable`; adapters `Rendro.Adapters.PyHanko` and `Rendro.Adapters.Qpdf` are `adapter` tier as expected.

**Refinement 3 (D-05 exact line numbers — CONFIRMED):** Guide lines 128 and 136 contain exactly the strings CONTEXT.md claims; `protection_claims_test.exs` lines 48 and 56 pin exactly those strings. No other docs-contract test pins "Rendro v1.10", "Phase 53", or "Phase 71" against `api_stability.md` or `viewer_evidence.md` as guide-content assertions (only as test descriptions/comments).

**Primary recommendation:** Plan in this order — (1) rewrite + label-scrub `api_stability.md` with byte-identical block relocation, updating protection_claims_test.exs in the same commit; (2) label-scrub `viewer_evidence.md` + rename test titles/comments; (3) create `upgrading_to_1.0.md` and wire into mix.exs; (4) create `api_stability_claims_test.exs` + register lane in `scripts/verify_docs.exs`. Gate each wave on `mix test test/docs_contract/`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Guide prose authoring (api_stability.md rewrite) | Documentation | — | Pure markdown edit; no runtime component |
| Internal-label scrub (api_stability + viewer_evidence) | Documentation | docs-contract tests | Tests pin some label strings; scrub must update both atomically |
| upgrading_to_1.0.md creation | Documentation | mix.exs ExDoc | New file + ExDoc wiring = two-file change |
| mix.exs ExDoc wiring | Build config | — | extras list + groups_for_extras Policies group |
| api_stability_claims_test.exs | Test / docs-contract | scripts/verify_docs.exs | New test + lane registration = two-file lockstep |
| scripts/verify_docs.exs lane registration | Test orchestration | api_stability_claims_test.exs | Both must change in the same commit per lockstep rule |

---

## Verification: D-02 Zero-Churn Claim

[VERIFIED: live repo grep]

**Finding:** CONFIRMED. ALL assertions against `guides/api_stability.md` in the docs-contract suite are position-independent `guide =~ "substring"` string matches. No test asserts line numbers, line ordering, or positional regex against the guide itself.

**Evidence:** Grep for `~r/.*?/` patterns across `test/docs_contract/*.exs` — all ordering regexes target `priv/support_matrix.json` (JSON key ordering within that file), NOT guide files. Specifically:

```
embedded_artifact_claims_test.exs: ~r/"embedded_files".*?"viewers"...  → support_matrix.json
forms_claims_test.exs:             ~r/"forms".*?"viewers"...           → support_matrix.json
signing_claims_test.exs:           ~r/"signing".*?"long_lived"...      → support_matrix.json
protection_claims_test.exs:        ~r/"protection".*?"viewers"...      → support_matrix.json
viewer_evidence_claims_test.exs:   ~r/"signature_widget_viewers"...    → support_matrix.json
```

The one indirect guide assertion that touches matrix-sourced text is `viewer_evidence_claims_test.exs:74-83`, which extracts all `evidence_deferred` strings from the live matrix and asserts the first 40 characters of each appears in `api_stability.md`. Two of those deferral reasons contain "Phase 71" text, but their 40-char prefixes (`"PDF.js failed the forms four-check save-"` and `"Apple Preview Attachments UI still does "`) appear BEFORE any "Phase 71" wording. D-06 edits to guide lines 148 and 155 are confirmed safe against these assertions.

**Conclusion:** Moving the per-surface boundary blocks byte-identical produces ZERO test churn. Only rewording or deleting a pinned substring breaks CI.

---

## Verification: D-09 Landmine

[VERIFIED: live repo]

**Finding:** CONFIRMED. `Rendro.Inspector` appears in `guides/api_stability.md` at **line 17** as a named Tier-1-sounding diagnostics module, but `priv/public_api.json` assigns it `"tier": "adapter"`.

**Exact guide text at line 17:**
```
- **Diagnostics (`Rendro.Inspector`, `:diagnostics` map):** The structure of diagnostics maps is
  intended for developer-facing debugging and is considered stable for common keys (`:level`, `:type`),
  but additive keys may be introduced in any release.
```

**Manifest tier for all D-10 candidate symbols:**

| Symbol | Manifest Tier | In STAB-05 assertion? |
|--------|-------------|----------------------|
| `Rendro` (module) | `stable` | YES — `flow/2`, `signature_field/2`, `render_signed/3`, `render_protected/3` |
| `Rendro.Document` | `stable` | YES — module existence |
| `Rendro.PageTemplate` | `stable` | YES — module existence |
| `Rendro.Section` | `stable` | YES — module existence |
| `Rendro.Metadata` | `stable` | YES — module existence |
| `Rendro.Artifact` | `stable` | YES — struct presence `%Rendro.Artifact{}` |
| `Rendro.Sign` | `stable` | YES — `prepare/2`, `sign/2`, `augment/2`, `validate/2` |
| `Rendro.Protect` | `stable` | YES — `password/2` |
| `Rendro.Adapters.PyHanko` | `adapter` | YES — D-10 includes adapter modules |
| `Rendro.Adapters.Qpdf` | `adapter` | YES — D-10 includes adapter modules |
| `Rendro.Inspector` | **adapter** | **MUST NOT** be asserted as Tier-1; reconcile required |

**Required reconciliation:** The rewritten guide prose must either (a) stop naming `Rendro.Inspector` as a stability-covered module (recommended — it is Tier-2/adapter, and the diagnostics *map keys* `:level`/`:type` are what's stable, not the Inspector module itself) or (b) explicitly present it as a Tier-2 adapter. STAB-05 then asserts only symbols the rewritten prose actually names at the appropriate tier.

**Note on `Rendro.Protect.render_protected/3`:** The D-10 list mentions `Rendro.render_protected/3` (on the top-level `Rendro` module, which IS `stable`). There is also `Rendro.Protect.render_protected/3` in the manifest under `Elixir.Rendro.Protect` (`stable`). The guide rewrite should make clear which module surface is meant; STAB-05 should assert `function_exported?(Rendro, :render_protected, 3)` per D-10.

---

## Verification: D-05 Exact Pinned Substrings

[VERIFIED: live repo]

**Finding:** CONFIRMED. Both pinned leaks match CONTEXT.md claims exactly.

**`protection_claims_test.exs:48`** asserts:
```elixir
assert guide =~ "Rendro v1.10 supports only `:aes_256`"
```
**Guide line 128** (exact text):
```
Rendro v1.10 supports only `:aes_256` on this public protection surface. AES-128, RC4, and native in-core encryption are not part of the supported contract for this release.
```
After D-05 edit, guide line 128 becomes: `"Rendro supports only \`:aes_256\`..."`, and the test assertion changes to `assert guide =~ "Rendro supports only \`:aes_256\`"`.

**`protection_claims_test.exs:56`** asserts:
```elixir
assert guide =~
         "Phase 53 does not introduce a first-party protected worker or orchestration API."
```
**Guide line 136** (exact text):
```
Phase 53 does not introduce a first-party protected worker or orchestration API.
```
After D-05 edit, guide line 136 becomes: `"Rendro does not introduce a first-party protected worker or orchestration API."`, and the test assertion changes accordingly.

**No other docs-contract test pins "Rendro v1.10", "Phase 53", or "Phase 71" as guide-content assertions.** The other occurrences are test *descriptions* (e.g., `signing_claims_test.exs:33` test name "...terminal after Phase 71") and test *comments* (`embedded_artifact_claims_test.exs:38` comment "...per Phase 71 re-verify"), which are D-06 free edits.

**Complete label inventory across all public guides:**

`guides/api_stability.md`:
- Line 54: "during Phase 71 review" — FREE EDIT (D-06), no test pin
- Line 118: "after Phase 71 re-verify" — FREE EDIT (D-06), no test pin
- Line 128: "Rendro v1.10" — CI-PINNED (D-05), must update test in lockstep
- Line 136: "Phase 53" — CI-PINNED (D-05), must update test in lockstep
- Line 148: "during Phase 71 operator review" — FREE EDIT (D-06; 40-char prefix safe)
- Line 155: "after Phase 71 re-verify; v1.9 deferral stands" — FREE EDIT (D-06; 40-char prefix safe)

`guides/viewer_evidence.md`:
- Line 31: "record Phase 70 consolidated legacy rows" — FREE EDIT (D-06)
- Line 59: "Phase 71 trust-sensitive surfaces" — FREE EDIT (D-06)
- Line 97: "records all Phase 71 structural-proxy evidence files" — FREE EDIT (D-06)
- Line 109: "no unverified cells remain (v2.3 close)" — FREE EDIT (D-06)
- Line 157: "Tier-B promotion-complete validation passes for all `supported` rows at v2.3 close" — FREE EDIT (D-06)
- Line 190: "same pdfium-cli structural proxy lane as Phase 70 automation" — FREE EDIT (D-06)
- Line 327: "see Phase 69 plan 03" — FREE EDIT (D-06)
- Line 329: "no GUI viewer sessions required for Phase 71 trust-sensitive closures" — FREE EDIT (D-06)

---

## Verification: D-16 / mix ci --warnings-as-errors

[VERIFIED: mix.exs line 66]

**Finding:** CONFIRMED. `mix ci` alias in `mix.exs` at line 66:
```elixir
"compile --warnings-as-errors",
```
The full alias (lines 62-73): `format --check-formatted`, `hex.build`, `compile --warnings-as-errors`, `test`, `docs`, `credo --strict`, `dialyzer`.

A hard `@deprecated` on any symbol with in-tree callers would emit a compiler warning during `compile --warnings-as-errors`, causing `mix ci` to fail. No `@deprecated` or `@doc deprecated:` attributes currently exist in `lib/` — the codebase starts clean. The soft-deprecate-first policy is mandatory AND testable via D-15's deprecation-table sentinel row assertion.

---

## Verification: release-proof Lane and verify_docs Registration

[VERIFIED: live repo]

**CI chain:** `release-proof` GitHub Actions job (`.github/workflows/ci.yml:173-192`) runs:
```
mix run scripts/release_preflight_proof.exs --current-version-tag --worktree <isolated>
```
This invokes `mix release.preflight` in an isolated worktree. `mix release.preflight` (Phase 2) runs `mix docs.contract` (among other checks). `mix docs.contract` (`lib/mix/tasks/docs.contract.ex`) runs:
```
mix run scripts/verify_docs.exs
```
`scripts/verify_docs.exs` currently has **11 lanes**. The new Phase 80 lane will be the **12th**.

**Exact registration idiom** (from `scripts/verify_docs.exs`):
```elixir
lanes = [
  {"README doctest lane", ["test", "test/docs_contract/readme_doctest_test.exs"]},
  # ... (10 more)
  {"Public API contract lane", ["test", "test/docs_contract/public_api_contract_test.exs"]}
  # ADD HERE:
  # {"API stability claims lane", ["test", "test/docs_contract/api_stability_claims_test.exs"]},
]
```

**Suggested lane label** (following naming convention): `"API stability claims lane"` → `"test/docs_contract/api_stability_claims_test.exs"`.

The new `api_stability_claims_test.exs` must assert this lane string exists in `scripts/verify_docs.exs`, following the pattern from every sibling claims test (e.g., `protection_claims_test.exs:90-94`):
```elixir
test "docs verification script includes the api stability claims lane" do
  script = File.read!("scripts/verify_docs.exs")
  assert script =~
    ~s|{"API stability claims lane", ["test", "test/docs_contract/api_stability_claims_test.exs"]}|
end
```

**Lane count safety:** `viewer_evidence_claims_test.exs:285-308` asserts the "prior seven" lanes by exact label string, not by count. Adding lane 12 does not remove any of those seven strings; the test continues to pass.

---

## Claims Test Idiom (for STAB-05)

[VERIFIED: live repo]

The STAB-05 test template is assembled from two sources:

**Source 1 — File read + substring pin** (from `protection_claims_test.exs`):
```elixir
defmodule Rendro.DocsContract.ApiStabilityClaimsTest do
  use ExUnit.Case, async: true

  test "api stability guide states the two-tier contract and deprecation policy" do
    guide = File.read!("guides/api_stability.md")

    # Tier/section header assertions (exact strings the rewrite ships)
    assert guide =~ "## Tier-1 Stable"   # or whatever the rewrite uses
    assert guide =~ "## NOT covered by SemVer"
    assert guide =~ "## Deprecation Policy"

    # Key promise sentence assertions
    assert guide =~ "deterministic within a version, not frozen across versions"
    # ... (other key sentences)

    # Banned overclaim guard (D-03)
    refute guide =~ "secure PDF"
    refute guide =~ "PAdES is supported"
  end
end
```

**Source 2 — False-pass-guarded symbol existence** (from `public_api_contract_test.exs`):
```elixir
test "guide-named tier-1 symbols exist and are exported" do
  # Module existence — guard against false pass
  for mod <- [Rendro.Document, Rendro.PageTemplate, Rendro.Section,
              Rendro.Metadata, Rendro.Artifact, Rendro.Sign, Rendro.Protect,
              Rendro.Adapters.PyHanko, Rendro.Adapters.Qpdf] do
    assert Code.ensure_loaded?(mod),
      "Expected #{inspect(mod)} to be loaded — was it renamed or deleted?"
  end

  # Function existence
  assert function_exported?(Rendro, :flow, 2),
    "Rendro.flow/2 not exported — was it renamed or deleted?"
  assert function_exported?(Rendro, :signature_field, 2), ...
  assert function_exported?(Rendro, :render_signed, 3), ...
  assert function_exported?(Rendro, :render_protected, 3), ...

  assert function_exported?(Rendro.Sign, :prepare, 2), ...
  assert function_exported?(Rendro.Sign, :sign, 2), ...
  assert function_exported?(Rendro.Sign, :augment, 2), ...
  assert function_exported?(Rendro.Sign, :validate, 2), ...

  assert function_exported?(Rendro.Protect, :password, 2), ...

  # Struct presence
  assert match?(%Rendro.Artifact{}, struct(Rendro.Artifact)),
    "%Rendro.Artifact{} struct not present — was it deleted?"
end

test "upgrade guide exists" do
  assert File.exists?("guides/upgrading_to_1.0.md"),
    "guides/upgrading_to_1.0.md must exist (STAB-03)"
end
```

**Critical false-pass-guard rule (D-10 item 1):** Every `Code.ensure_loaded?` and `function_exported?` call MUST be wrapped in an `assert` with a message explaining it is a false-pass guard — not a silent pass-through. A renamed or deleted symbol must cause the test to FAIL, not silently succeed.

---

## ExDoc Wiring — Exact Anchors

[VERIFIED: mix.exs lines 108-130]

**Current `extras` list (mix.exs lines 108-117):**
```elixir
extras: [
  "README.md",
  "guides/integrations.md",
  "guides/branding.md",
  "guides/api_stability.md",
  "guides/viewer_evidence.md",
  "guides/page_primitive.md",
  "guides/recipes.md",
  "guides/user_flows_and_jtbd.md"
],
```

**Current `groups_for_extras` Policies group (mix.exs lines 124-127):**
```elixir
Policies: [
  "guides/api_stability.md",
  "guides/viewer_evidence.md"
],
```

**Required change:** Add `"guides/upgrading_to_1.0.md"` to BOTH `extras` (new entry) and `groups_for_extras` Policies group (new entry alongside the existing two). The ordering convention is `api_stability.md` → `upgrading_to_1.0.md` → `viewer_evidence.md` (or other logical ordering; Claude's discretion per CONTEXT.md).

---

## Common Pitfalls

### Pitfall 1: Breaking the deferral-substring assertion via guide rewrite
**What goes wrong:** The guide's "Explicit Deferral Reasons (matrix-mirrored)" section (lines 144–155) mirrors `support_matrix.json` deferral reasons. `viewer_evidence_claims_test.exs:74-83` asserts the first 40 chars of each matrix deferral reason appear in the guide. If the rewrite eliminates or substantially rewrites those sentences' openings, the test fails.
**Why it happens:** The section is easy to conflate with "free edit" territory since D-06 flags lines 148 and 155.
**How to avoid:** D-06 edits are specifically about dropping the "Phase 71 re-verify" and "v1.9 deferral stands" ENDINGS; the sentence BEGINNINGS ("PDF.js failed the forms four-check save-..." and "Apple Preview Attachments UI still does not discover...") must survive. Keep both sentences; edit only the suffix.
**Warning signs:** `viewer_evidence_claims_test.exs` test "api stability guide contains deferral reason substrings from matrix" fails after rewrite.

### Pitfall 2: Adding banned overclaim phrases in new contract prose
**What goes wrong:** The rewrite's new "NOT covered by SemVer" section mentions PDF output, compliance, etc. A single slip of "PAdES is supported" or "secure PDF" trips a `refute` guard and fails CI.
**Why it happens:** D-13's six bullets include compliance-adjacent language; authors may inadvertently flip the framing.
**How to avoid:** Run `mix test test/docs_contract/` after drafting every new prose section. Consult the refute guards in `signing_claims_test.exs:84-93` and `protection_claims_test.exs:64-66` before writing.
**Warning signs:** `signing_claims_test.exs` or `protection_claims_test.exs` fails after rewrite with a `refute` assertion.

### Pitfall 3: The D-09 landmine — asserting Inspector as Tier-1
**What goes wrong:** If STAB-05 asserts `Code.ensure_loaded?(Rendro.Inspector)` and the guide prose still implies it's Tier-1 stable, the test passes (the module exists), but the prose-vs-reality drift that STAB-05 was designed to catch is perpetuated.
**Why it happens:** Inspector is in `groups_for_modules["Inspection & Observability"]` in mix.exs, making it look stable; it appears in the current guide at line 17.
**How to avoid:** Rewrite the guide to describe the diagnostics *map keys* (`:level`, `:type`) as the stable contract, not the `Rendro.Inspector` module itself. Do NOT include `Rendro.Inspector` in the symbol-existence assertions. The module's actual tier is `adapter`.
**Warning signs:** The guide's Tier-1 symbol list and STAB-05's assertion list diverge.

### Pitfall 4: Commit atomicity violations (lockstep rule)
**What goes wrong:** Guide edits and test updates committed separately — CI is red between commits.
**Why it happens:** Two-phase workflow where guide is drafted first, tests updated second.
**How to avoid:** Stage ALL changes (guide edits + test updates + lane registration) in a single commit per wave. Run `mix test test/docs_contract/` before each commit.
**Warning signs:** CI fails on any intermediate commit with a test assertion against a modified guide string.

### Pitfall 5: New heading strings in the rewrite not pinned by STAB-05
**What goes wrong:** The guide ships with new Tier-1/Tier-2 section headers, but STAB-05 doesn't pin them. A future refactor silently breaks the contract without CI catching it.
**Why it happens:** Authors focus on content, forget to pin structural headers in the test.
**How to avoid:** For every new major section heading the rewrite introduces (e.g., `## Tier-1 Stable`, `## Tier-2 Evolving`, `## NOT covered by SemVer`, `## Deprecation Policy`, `## Deprecations`), add a corresponding `assert guide =~ "## ..."` in STAB-05.
**Warning signs:** STAB-05 has zero header assertions — that's an incomplete test.

---

## Architecture Patterns

### Docs-Contract Test Structure

The standard idiom (all sibling tests follow this pattern):

```elixir
defmodule Rendro.DocsContract.ApiStabilityClaimsTest do
  use ExUnit.Case, async: true

  describe "api stability guide" do
    test "states the two-tier SemVer contract" do
      guide = File.read!("guides/api_stability.md")
      assert guide =~ "..."   # exact substring match
    end

    test "named tier-1 symbols exist and are exported" do
      # false-pass-guarded Code.ensure_loaded? + function_exported? checks
    end

    test "upgrade guide exists" do
      assert File.exists?("guides/upgrading_to_1.0.md")
    end
  end

  test "docs verification script includes the api stability claims lane" do
    script = File.read!("scripts/verify_docs.exs")
    assert script =~ ~s|{"API stability claims lane", ...}|
  end
end
```

### Lockstep Triple Pattern (from Phases 76/79)

Three files always change together when adding a docs-contract lane:
1. The new test file itself (`api_stability_claims_test.exs`)
2. `scripts/verify_docs.exs` — new lane entry
3. The test itself asserts item 2 (the lane registration self-assertion)

This self-referential assertion is the "guardrail-lockstep" pattern: the test cannot pass if the lane is not registered.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Symbol existence checking | Custom reflection code | `Code.ensure_loaded?/1` + `function_exported?/3` | Standard Elixir introspection; same pattern as Phase 79 |
| Struct existence checking | Struct field enumeration | `struct(Rendro.Artifact)` + `match?` | Simplest proof a struct is defined |
| Guide substring matching | Line-number parsing | `guide =~ "substring"` | Position-independent; safe across restructure |
| Lane registration | Manual tracking | Self-referential `assert script =~ lane_label` | Enforcement via test; breaks if lane missing |

---

## Standard Stack

No new dependencies. This phase is pure documentation + one test file.

| Component | Tool | Version |
|-----------|------|---------|
| Test framework | ExUnit | Included with Elixir 1.19 |
| Docs authoring | Markdown (ExDoc-rendered) | ex_doc ~> 0.40 (already in mix.exs) |
| Symbol introspection | `Code.ensure_loaded?/1`, `function_exported?/3` | Elixir stdlib |
| Guide assertions | `File.read!` + `String.contains?` via `=~` | Elixir stdlib |

---

## Environment Availability

Step 2.6: SKIPPED for new files (no external dependencies). The docs-contract test suite runs via `mix test test/docs_contract/` — no external tools needed beyond the Elixir/Mix toolchain already present.

One check relevant to release-proof: `mix release.preflight` runs `mix docs.contract` which runs `scripts/verify_docs.exs`. This requires the full test suite to pass including any new lane. No additional environment setup needed.

---

## Runtime State Inventory

Step 2.5: NOT APPLICABLE. This is not a rename/refactor/migration phase. No stored data, live service config, OS-registered state, secrets, or build artifacts reference guide file names or test module names that would require runtime migration.

---

## Validation Architecture

Nyquist validation: ENABLED (config.json `workflow.nyquist_validation: true`).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) |
| Config file | None separate — runs via `mix test` |
| Quick run command | `mix test test/docs_contract/` |
| Full suite command | `mix ci` (includes compile --warnings-as-errors, test, credo, dialyzer) |
| Docs-contract gate | `mix docs.contract` (= `mix run scripts/verify_docs.exs`) |
| Release-proof gate | `mix run scripts/release_preflight_proof.exs --current-version-tag --worktree <isolated>` |

### Success Criteria → Test Map

| SC# | Success Criterion | Test Type | Automated Command | Notes |
|-----|-------------------|-----------|-------------------|-------|
| SC-1 | `api_stability.md` states two-tier contract, byte-output carve-out, "NOT covered" list | Docs-contract claims | `mix test test/docs_contract/api_stability_claims_test.exs` | File DOES NOT EXIST yet — Wave 0 gap |
| SC-2 | Deprecation policy + Deprecations table in guide | Docs-contract claims | Same as SC-1 | Assertions: table header columns + `None as of 1.0.0` sentinel |
| SC-3 | `upgrading_to_1.0.md` exists, wired into ExDoc Policies group | Docs-contract claims + manual | `mix test test/docs_contract/api_stability_claims_test.exs` + `mix docs` to verify ExDoc renders it | File DOES NOT EXIST yet |
| SC-4 | No internal labels in public guides; CI-pinned tests updated in lockstep | Docs-contract claims | `mix test test/docs_contract/protection_claims_test.exs test/docs_contract/signing_claims_test.exs test/docs_contract/viewer_evidence_claims_test.exs test/docs_contract/embedded_artifact_claims_test.exs` | Current tests must PASS after label scrub |
| SC-5 | `api_stability_claims_test.exs` proves symbols exist + headers + sentences + upgrade-guide | Docs-contract claims | `mix test test/docs_contract/api_stability_claims_test.exs` | File DOES NOT EXIST yet — core Wave 0 gap |

### Phase-Level Regression Gate

The phase is complete when ALL of the following are green:

1. `mix test test/docs_contract/` — all 12 lanes (11 existing + new api_stability_claims lane)
2. `mix docs.contract` — runs `scripts/verify_docs.exs`, which runs all 12 lanes
3. `mix ci` — compile + test + credo + dialyzer + docs (confirms no `--warnings-as-errors` regression)
4. The `release-proof` CI lane — runs `mix release.preflight` which includes `mix docs.contract`

### Lockstep Invariant

Any new pinned substring added to a guide must be pinned by a test assertion in the SAME commit. This is enforced by the three-file lockstep pattern:

```
guide edit → test assertion → verify_docs.exs lane entry
```

Violating this leaves a window where `mix docs.contract` passes but the substantive claim is not verified.

### Wave 0 Gaps (files that must be created before STAB-05 can be verified)

- [ ] `test/docs_contract/api_stability_claims_test.exs` — the new STAB-05 test (covers SC-1, SC-2, SC-3, SC-5)
- [ ] `guides/upgrading_to_1.0.md` — required by STAB-03 and asserted by STAB-05 (SC-3)

No test infrastructure gaps: ExUnit, the `test/docs_contract/` directory, and `scripts/verify_docs.exs` all exist and are working.

### Sampling Rate

- Per-task commit: `mix test test/docs_contract/` (fast; no live proofs needed)
- Per-wave merge: `mix ci` (full suite including dialyzer)
- Phase gate: `mix docs.contract` green before marking phase complete

---

## Open Questions

1. **Exact heading strings for STAB-05 to pin**
   - What we know: D-10 says assert "the exact header strings the rewrite ships (two-tier contract headers, deprecation policy header, 'NOT covered by SemVer' header)"
   - What's unclear: The planner/executor choose the exact heading text (Claude's discretion)
   - Recommendation: Decide headings during guide drafting; add corresponding `assert guide =~ "## <heading>"` entries to STAB-05 in the same commit. Suggested: `"## Tier-1 Stable"`, `"## Tier-2 Evolving"`, `"## NOT covered by SemVer"`, `"## Deprecation Policy"`, `"## Deprecations"`.

2. **Final symbol list in rewritten guide prose**
   - What we know: D-09 says the planner/executor resolves the Inspector reconcile during the rewrite
   - What's unclear: Will the rewritten guide name only the 8 stable modules (dropping Inspector) or will it describe Inspector as explicitly Tier-2?
   - Recommendation: Drop `Rendro.Inspector` from any Tier-1 framing; describe the `:diagnostics` map common keys as stable, not the Inspector module. This avoids any STAB-05 assertion against an adapter-tier symbol as if it were stable.

3. **`upgrading_to_1.0.md` exact link to CHANGELOG**
   - What we know: D-12 says link generically ("see the CHANGELOG"), not to an anchor
   - What's unclear: The exact anchor will not exist until Phase 82 writes `## [1.0.0]`
   - Recommendation: Write `"For full change history, see [CHANGELOG.md](../CHANGELOG.md)."` — no anchor, no `#100` fragment.

---

## Sources

### Primary (HIGH confidence)
- `guides/api_stability.md` — live file; all line refs verified
- `guides/viewer_evidence.md` — live file; all label occurrences verified
- `test/docs_contract/protection_claims_test.exs` — live file; D-05 pins at lines 48, 56 confirmed
- `test/docs_contract/signing_claims_test.exs` — live file; D-06 title at line 33 confirmed
- `test/docs_contract/viewer_evidence_claims_test.exs` — live file; D-07 refute guards at lines 106-107 confirmed; D-02 deferral-substring mechanism confirmed
- `test/docs_contract/embedded_artifact_claims_test.exs` — live file; D-06 comment at line 38 confirmed
- `test/docs_contract/public_api_contract_test.exs` — live file; Phase 79 false-pass-guard pattern confirmed
- `scripts/verify_docs.exs` — live file; 11 lanes confirmed, exact registration idiom documented
- `priv/public_api.json` — live file; all tier assignments verified; `Rendro.Inspector` tier=adapter confirmed
- `mix.exs` — live file; `compile --warnings-as-errors` at line 66 confirmed; ExDoc wiring at lines 108-130 confirmed
- `.github/workflows/ci.yml` — live file; `release-proof` job at lines 173-192 confirmed
- `lib/mix/tasks/release/preflight.ex` — live file; `mix docs.contract` in Phase 2 checks confirmed
- `lib/mix/tasks/docs.contract.ex` — live file; runs `scripts/verify_docs.exs` confirmed
- `priv/support_matrix.json` — live file; two "Phase 71" deferral reasons confirmed; 40-char prefix analysis verified

### Secondary (MEDIUM confidence)
None needed — all findings are from direct codebase inspection.

---

## Assumptions Log

No claims tagged `[ASSUMED]` in this research. All claims verified against the live repository.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| (empty) | | | |

**All claims in this research were verified against the live codebase.**

---

## Metadata

**Confidence breakdown:**
- D-02 zero-churn claim: HIGH — verified by grep across all docs_contract tests
- D-05 exact pinned substrings: HIGH — verified by reading exact test lines and exact guide lines
- D-09 Inspector landmine: HIGH — verified by reading priv/public_api.json tier assignments
- D-16 --warnings-as-errors: HIGH — verified at mix.exs line 66
- release-proof chain: HIGH — verified full chain from CI job to verify_docs.exs
- Claims test idiom: HIGH — extracted from live sibling tests
- ExDoc wiring: HIGH — verified at mix.exs lines 108-130

**Research date:** 2026-05-30
**Valid until:** 2026-06-30 (stable codebase; validity only affected by concurrent changes to docs_contract tests or mix.exs ExDoc config)
