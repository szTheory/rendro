# Phase 80: Stability Contract & Migration Docs — Pattern Map

**Mapped:** 2026-05-30
**Files analyzed:** 6 new/modified files + 4 lockstep test edits
**Analogs found:** 6 / 6

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/docs_contract/api_stability_claims_test.exs` | test / docs-contract | request-response (file I/O + reflection) | `test/docs_contract/protection_claims_test.exs` + `test/docs_contract/public_api_contract_test.exs` | exact composite |
| `guides/upgrading_to_1.0.md` | documentation | — | `guides/viewer_evidence.md` (heading/style) | style-match |
| `guides/api_stability.md` (MODIFY — rewrite) | documentation | — | itself (current 155 lines) | self |
| `mix.exs` (MODIFY — ExDoc wiring) | config | — | itself (lines 108–132) | self |
| `scripts/verify_docs.exs` (MODIFY — lane 12) | test-orchestration | — | itself (lines 7–19, 11 lanes) | self |
| `test/docs_contract/protection_claims_test.exs` (MODIFY — lines 48, 56) | test / docs-contract | request-response | itself | self |

---

## Pattern Assignments

### `test/docs_contract/api_stability_claims_test.exs` (NEW — test, docs-contract)

This file is the primary deliverable for STAB-05. It is assembled from two analog sources:

**Analog A:** `test/docs_contract/protection_claims_test.exs` — the closest sibling for the `guide = File.read!` + `assert guide =~` + `refute guide =~` + lane-registration test structure.

**Analog B:** `test/docs_contract/public_api_contract_test.exs` — the source for the false-pass-guarded `Code.ensure_loaded?` + `function_exported?` symbol-existence pattern (D-10 item 1).

---

**Module declaration and `use` line** (from `protection_claims_test.exs` lines 1–2):
```elixir
defmodule Rendro.DocsContract.ProtectionClaimsTest do
  use ExUnit.Case, async: true
```
Mirror exactly:
```elixir
defmodule Rendro.DocsContract.ApiStabilityClaimsTest do
  use ExUnit.Case, async: true
```
`async: true` is correct — file reads are safe to parallelize.

---

**Guide file-read + substring pin pattern** (from `protection_claims_test.exs` lines 41–66):
```elixir
test "api stability guide uses narrow, truthful protection wording" do
  guide = File.read!("guides/api_stability.md")

  assert guide =~
           "Rendro supports password-to-open PDF protection through an external artifact-first boundary."

  assert guide =~ "`Rendro.Protect.password/2`"
  assert guide =~ "Rendro v1.10 supports only `:aes_256`"
  # ...

  refute guide =~ "secure PDF"
  refute guide =~ "tamper-proof"
  refute guide =~ "PDF/A compliant"
end
```
Apply this idiom verbatim for the STAB-05 guide-prose tests. All assertions are position-independent `guide =~ "substring"` — no line numbers, no regex ordering.

---

**Lane self-registration test** (from `protection_claims_test.exs` lines 90–95 — the exact idiom every sibling uses):
```elixir
test "docs verification script includes the protection claims lane" do
  script = File.read!("scripts/verify_docs.exs")

  assert script =~
           ~s|{"Protection semantic-claims lane", ["test", "test/docs_contract/protection_claims_test.exs"]}|
end
```
Mirror for STAB-05:
```elixir
test "docs verification script includes the api stability claims lane" do
  script = File.read!("scripts/verify_docs.exs")

  assert script =~
           ~s|{"API stability claims lane", ["test", "test/docs_contract/api_stability_claims_test.exs"]}|
end
```
The label string `"API stability claims lane"` must match byte-for-byte what is inserted into `scripts/verify_docs.exs`.

---

**False-pass-guarded symbol existence pattern** (from `public_api_contract_test.exs` lines 94–119):
```elixir
for module <- hidden_modules do
  assert Code.ensure_loaded?(module),
         "Expected internal module #{inspect(module)} to exist and be compiled, " <>
           "but it could not be loaded — was it renamed or deleted? " <>
           "The hidden-internals contract must track real modules."
  # ...
end
```
Apply this guard structure for every `Code.ensure_loaded?` and `function_exported?` call in STAB-05. A missing assert message means a renamed/deleted symbol would silently pass. Required form:

```elixir
assert Code.ensure_loaded?(Rendro.Document),
  "Expected Rendro.Document to be loaded — was it renamed or deleted?"

assert function_exported?(Rendro, :flow, 2),
  "Rendro.flow/2 not exported — was it renamed or deleted?"
```

---

**Struct existence pattern** (D-10 item 1 — no existing analog; use `struct/1` + `match?`):
```elixir
assert match?(%Rendro.Artifact{}, struct(Rendro.Artifact)),
  "%Rendro.Artifact{} struct not present — was it deleted?"
```
`struct(Rendro.Artifact)` raises `ArgumentError` if the struct does not exist, which is the desired false-pass-guard behavior.

---

**Upgrade-guide existence pattern** (D-10 item 4):
```elixir
test "upgrade guide exists" do
  assert File.exists?("guides/upgrading_to_1.0.md"),
    "guides/upgrading_to_1.0.md must exist (STAB-03)"
end
```
Do NOT assert the guide's contents from this test — that is the upgrade guide's own concern.

---

**Symbols to assert (D-10 + D-09 reconcile from RESEARCH.md):**

Modules via `Code.ensure_loaded?` — assert all of these (all `stable` tier per manifest):
- `Rendro.Document`
- `Rendro.PageTemplate`
- `Rendro.Section`
- `Rendro.Metadata`
- `Rendro.Artifact`
- `Rendro.Sign`
- `Rendro.Protect`

Adapter modules via `Code.ensure_loaded?` — assert these at their correct Tier-2 tier (D-10 explicitly includes adapters):
- `Rendro.Adapters.PyHanko`
- `Rendro.Adapters.Qpdf`

Do NOT assert `Code.ensure_loaded?(Rendro.Inspector)` — its manifest tier is `adapter`, not `stable`. The rewritten guide must describe diagnostics map keys (`:level`, `:type`) as the stable contract, not the Inspector module itself.

Functions via `function_exported?/3` on the `Rendro` top-level module (all `stable`):
- `Rendro.flow/2`
- `Rendro.signature_field/2`
- `Rendro.render_signed/3`
- `Rendro.render_protected/3`

Functions via `function_exported?/3` on `Rendro.Sign` (all `stable`):
- `Rendro.Sign.prepare/2`
- `Rendro.Sign.sign/2`
- `Rendro.Sign.augment/2`
- `Rendro.Sign.validate/2`

Functions via `function_exported?/3` on `Rendro.Protect` (all `stable`):
- `Rendro.Protect.password/2`

---

**Refute guards for banned overclaim phrases** (from `signing_claims_test.exs` lines 84–93 and `protection_claims_test.exs` lines 64–66):
```elixir
refute guide =~ "tamper-evident signing"
refute guide =~ "PAdES is supported"
refute guide =~ "LT/LTA is supported"
refute guide =~ "PDF/A is supported"
refute guide =~ "regulatory approval"
refute guide =~ "enterprise compliance"
refute guide =~ "all signature viewers are supported"
refute guide =~ "viewer portability is guaranteed"
refute guide =~ "Rendro owns signer identity trust"
refute guide =~ "secure PDF"
refute guide =~ "tamper-proof"
refute guide =~ "PDF/A compliant"
```
STAB-05 should include at minimum `refute guide =~ "secure PDF"` and `refute guide =~ "PAdES is supported"` per D-03. Add any other banned phrases from the full list above that are relevant to the new "NOT covered by SemVer" prose.

---

**Section headers to pin** (per D-10 item 2 + RESEARCH.md open question resolution):
```elixir
assert guide =~ "## Tier-1 Stable"
assert guide =~ "## Tier-2 Evolving"
assert guide =~ "## NOT covered by SemVer"
assert guide =~ "## Deprecation Policy"
assert guide =~ "## Deprecations"
```
These must match the exact heading strings the rewrite ships. Decide headings during guide drafting and backfill STAB-05 in the same commit.

---

**Deprecations table sentinel** (D-15 — assert table header columns + sentinel row):
```elixir
assert guide =~ "| Symbol |"
assert guide =~ "None as of 1.0.0"
```
The exact column header text and sentinel wording are Claude's discretion, but STAB-05 must pin them in the same commit they are written.

---

### `guides/upgrading_to_1.0.md` (NEW — documentation)

**Analog:** `guides/viewer_evidence.md` (heading/style conventions) and `guides/api_stability.md` (tone and cross-reference style).

**Top-level heading style** (from `guides/viewer_evidence.md` line 1):
```markdown
# Viewer Evidence Recording
```
Mirror:
```markdown
# Upgrading to 1.0
```

**Section heading style** (from `guides/api_stability.md` lines 3, 13, 19):
```markdown
## Semantic Versioning Expectations

## Core API vs Adapters

## Deprecation Policy
```
Use `##` for top-level sections, `###` for subsections. No decorative dividers or horizontal rules in the existing guides.

**Internal cross-reference style** (from `guides/api_stability.md` line 30):
```markdown
See `guides/viewer_evidence.md` for the operator recording recipe.
```
And from `guides/viewer_evidence.md` line 5:
```markdown
Rendro's support matrix (`priv/support_matrix.json`) is the public index...
```
Use backtick-quoted paths for file references. For the CHANGELOG generic link (D-12), use:
```markdown
For full change history, see [CHANGELOG.md](../CHANGELOG.md).
```
No anchor fragment (the `## [1.0.0]` section is not written until Phase 82).

**Content structure per D-11:**
1. Open with reassurance: "1.0 is a stability commitment, not a rewrite — if you're on 0.3.x no code changes are required."
2. Two-tier contract summary (reference `api_stability.md` for full details).
3. Short digest of what consolidation delivered (viewer evidence, batteries-included recipes, formal tiers + deprecation policy).
4. Support-matrix pointer to the per-surface boundary sections in `api_stability.md`.
5. Generic CHANGELOG link.

---

### `guides/api_stability.md` (MODIFY — full rewrite)

**Analog:** itself (current 155 lines, fully read above).

**Current top-level structure to preserve byte-identical** (per D-01/D-02):

The following 8 `##`-level section blocks must move verbatim below a new subordinate heading. Their existing content is the ground truth — the rewrite only changes their *position* in the document, not their text:

| Current section heading (line) | Content start |
|-------------------------------|--------------|
| `## Interactive Forms Support Boundary` (line 32) | line 32 |
| `## Signing Preparation Support Boundary` (line 60) | line 60 |
| `## Signed Artifact Support Boundary` (line 72) | line 72 |
| `## Long-Lived Evidence Support Boundary` (line 86) | line 86 |
| `## Embedded Files Support Boundary` (line 98) | line 98 |
| `## Curated Links Support Boundary` (line 106) | line 106 |
| `## Embedded Artifact Viewer Posture` (line 112) | line 112 |
| `## Protected PDF Support Boundary` (line 122) | line 122 |
| `## Explicit Deferral Reasons (matrix-mirrored)` (line 144) | line 144 |

**Label strings to scrub (free edits, no CI pin):**
- Line 54: `"during Phase 71 review"` → `"during operator review"`
- Line 118: `"after Phase 71 re-verify"` → delete or replace with `"on the version recorded"`
- Line 148: `"during Phase 71 operator review"` → `"during operator review"`
- Line 155: `"after Phase 71 re-verify; v1.9 deferral stands"` → `"on the version recorded; the deferral stands"`

**CRITICAL — 40-char prefix safety constraint (D-02 / RESEARCH Pitfall 1):**
Lines 148 and 155 contain deferral reasons mirrored from `priv/support_matrix.json`. The test `viewer_evidence_claims_test.exs:74-83` asserts the FIRST 40 characters of each `evidence_deferred` string appear in this guide. The edits above affect only the *endings* of those sentences — the beginnings (`"PDF.js failed the forms four-check save-"` and `"Apple Preview Attachments UI still does "`) must survive verbatim. Do not reword sentence openings for lines 148 and 155.

**Label strings requiring CI-pinned lockstep edit (D-05):**
- Line 128: `"Rendro v1.10 supports only \`:aes_256\`"` → `"Rendro supports only \`:aes_256\`"` (must update `protection_claims_test.exs:48` in the same commit)
- Line 136: `"Phase 53 does not introduce a first-party protected worker or orchestration API."` → `"Rendro does not introduce a first-party protected worker or orchestration API."` (must update `protection_claims_test.exs:56` in the same commit)

**New content to lead the document (D-01, D-13, D-15):**
1. Two-tier contract (Tier-1 Stable / Tier-2 Evolving) with exact tier vocabulary matching `priv/public_api.json` tags (`stable` / `adapter`).
2. Byte-output carve-out with headline: `"deterministic within a version, not frozen across versions"` (this exact string must be pinned by STAB-05).
3. "NOT covered by SemVer" section with the 6 bullets from D-13.
4. Deprecation policy (soft-deprecate-first per D-16) with illustrative fenced example.
5. Deprecations table with `_None as of 1.0.0_` sentinel row.

**Inspector reconcile (D-09 — LANDMINE):**
The current guide line 17 names `Rendro.Inspector` in a Tier-1-sounding context. The rewrite must either (a) drop the module name and describe only the `:diagnostics` map keys (`:level`, `:type`) as stable, or (b) explicitly label it as Tier-2. STAB-05 must NOT assert `Code.ensure_loaded?(Rendro.Inspector)` as a stable symbol. The recommended approach: describe the map keys as stable contract, not the Inspector module.

---

### `mix.exs` (MODIFY — ExDoc wiring)

**Analog:** itself (lines 108–132, read above).

**Current `extras` list** (lines 108–117):
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
Add `"guides/upgrading_to_1.0.md"` after `"guides/api_stability.md"`:
```elixir
extras: [
  "README.md",
  "guides/integrations.md",
  "guides/branding.md",
  "guides/api_stability.md",
  "guides/upgrading_to_1.0.md",
  "guides/viewer_evidence.md",
  "guides/page_primitive.md",
  "guides/recipes.md",
  "guides/user_flows_and_jtbd.md"
],
```

**Current `groups_for_extras` Policies group** (lines 124–127):
```elixir
Policies: [
  "guides/api_stability.md",
  "guides/viewer_evidence.md"
],
```
Add `"guides/upgrading_to_1.0.md"` between the two existing entries:
```elixir
Policies: [
  "guides/api_stability.md",
  "guides/upgrading_to_1.0.md",
  "guides/viewer_evidence.md"
],
```

---

### `scripts/verify_docs.exs` (MODIFY — lane 12)

**Analog:** itself (lines 7–19, 11 existing lanes, read above).

**Current last entry** (lines 18–19):
```elixir
  {"Public API contract lane", ["test", "test/docs_contract/public_api_contract_test.exs"]}
]
```
Add lane 12 after the current last entry:
```elixir
  {"Public API contract lane", ["test", "test/docs_contract/public_api_contract_test.exs"]},
  {"API stability claims lane", ["test", "test/docs_contract/api_stability_claims_test.exs"]}
]
```

**Note:** The label string `"API stability claims lane"` is the exact byte sequence STAB-05's lane self-assertion pins:
```elixir
assert script =~
  ~s|{"API stability claims lane", ["test", "test/docs_contract/api_stability_claims_test.exs"]}|
```
These two must be identical to the character.

**Naming convention observed in sibling lanes:**
```
"README doctest lane"
"Signing semantic-claims lane"
"Protection semantic-claims lane"
"Public API contract lane"
```
The new lane follows the `"X claims lane"` pattern, not the `"X semantic-claims lane"` pattern, because STAB-05 is a contract-level claims test (covers symbol existence, not just semantic wording). Either is defensible; `"API stability claims lane"` is the RESEARCH.md recommendation.

---

### `test/docs_contract/protection_claims_test.exs` (MODIFY — lines 48 and 56 only)

**Analog:** itself (read in full above).

**Line 48 — current:**
```elixir
assert guide =~ "Rendro v1.10 supports only `:aes_256`"
```
**Line 48 — after D-05 edit:**
```elixir
assert guide =~ "Rendro supports only `:aes_256`"
```

**Lines 55–57 — current:**
```elixir
assert guide =~
         "Phase 53 does not introduce a first-party protected worker or orchestration API."
```
**Lines 55–57 — after D-05 edit:**
```elixir
assert guide =~
         "Rendro does not introduce a first-party protected worker or orchestration API."
```

These are the only two changes in this file. All other assertions remain untouched.

---

## Shared Patterns

### Position-Independent Guide Assertion
**Source:** `test/docs_contract/signing_claims_test.exs` lines 54–93 and `test/docs_contract/protection_claims_test.exs` lines 41–67
**Apply to:** `api_stability_claims_test.exs` (all guide prose assertions)
```elixir
guide = File.read!("guides/api_stability.md")
assert guide =~ "exact substring"   # position-independent — safe across any restructure
refute guide =~ "banned phrase"     # enforces absence of overclaim language
```
Never use `guide =~ ~r/.../` with positional ordering for guide files. Ordering regex patterns in the codebase exclusively target `priv/support_matrix.json` JSON structure, not guides.

### Lane Self-Registration Test
**Source:** `test/docs_contract/signing_claims_test.exs` lines 95–100; `test/docs_contract/protection_claims_test.exs` lines 90–95
**Apply to:** `api_stability_claims_test.exs` (final test in the module)
```elixir
test "docs verification script includes the <name> lane" do
  script = File.read!("scripts/verify_docs.exs")
  assert script =~
    ~s|{"<Label string>", ["test", "test/docs_contract/<file>_test.exs"]}|
end
```
The label string in the `~s|...|` sigil must be byte-identical to the entry in `scripts/verify_docs.exs`. This self-referential test cannot pass if the lane is not registered.

### False-Pass Guard
**Source:** `test/docs_contract/public_api_contract_test.exs` lines 94–101
**Apply to:** All `Code.ensure_loaded?` and `function_exported?` calls in `api_stability_claims_test.exs`
```elixir
assert Code.ensure_loaded?(SomeModule),
  "Expected #{inspect(SomeModule)} to exist and be compiled — was it renamed or deleted?"
```
A bare `if Code.ensure_loaded?(mod)` or unasserted `Code.ensure_loaded?` call silently passes when the module is missing. Every existence check MUST be wrapped in `assert`.

### Lockstep Commit Rule
**Apply to:** Every wave that edits a guide AND a test that pins guide content.
- Wave 1: `guides/api_stability.md` rewrite + `test/docs_contract/protection_claims_test.exs` lines 48 & 56 in the same commit.
- Wave 4: `test/docs_contract/api_stability_claims_test.exs` (NEW) + `scripts/verify_docs.exs` lane 12 in the same commit.
- Run `mix test test/docs_contract/` before each commit; run `mix ci` before the final phase commit.

---

## No Analog Found

None. All 6 files have close analogs in the codebase.

---

## Metadata

**Analog search scope:** `test/docs_contract/`, `guides/`, `scripts/`, `mix.exs`
**Files read:** 8 source files
**Pattern extraction date:** 2026-05-30
