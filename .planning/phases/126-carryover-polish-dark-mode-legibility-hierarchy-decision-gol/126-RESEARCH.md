# Phase 126: Carryover polish — dark-mode legibility, hierarchy decision & golden/typography depth - Research

**Researched:** 2026-08-16
**Domain:** Pure-Elixir recipe theming, deterministic PDF rendering, and bounded visual-regression evidence
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Dark table color semantics

- **D-01:** A themed table body must receive semantic theme ink rather than inheriting the fixed black default used by bare String cells. Repair the shared themed table-cell construction/style boundary so the same rule can be reused by every recipe; do not make the dark surface artificially light and do not hide the problem with an Invoice-only background or palette patch.
- **D-02:** Preserve the legacy unthemed String-cell path and all frozen no-theme bytes. The shared repair may add or reuse a private helper or table styling seam, but must not globally change unrelated unthemed caller tables.
- **D-03:** The fix covers table headers and body cells wherever a themed recipe uses the shared path, with explicit role choices (`ink` for primary values and `muted` only where the existing semantic hierarchy calls for it). Color contrast remains a bounded legibility improvement, not a WCAG/PDF-UA claim.

### Ticket hierarchy disposition

- **D-04:** Fix WINDOWS id 2; do not ship an exemption as the preferred outcome. Under every supplied theme, including all six Phase 125 presets, placement-grid values remain the dominant ticket fact, the event title stays secondary, and the human-readable reference code remains compact, legible, and visually subordinate.
- **D-05:** Preserve the no-theme Ticket bytes and the public `theme:`/`:typography` override order. Resolve the conflict through theme-aware semantic role mapping or an equally narrow recipe seam, not per-preset branches or a flattened one-size hierarchy. — **Reversibility: costly** — the resulting semantic role mapping becomes the baseline for Phase 127 rubric scoring and generated catalog rows.
- **D-06:** Keep the required reference visible and copyable; do not truncate it, hide it behind an image, or permit ordinary fixture references to split into the known three-line mid-token failure.

### Payslip numeric integrity

- **D-07:** Formatted money cells are visually atomic. Current/YTD values such as `$4,200.00` and `$25,200.00` must not break mid-number under the default theme or any curated preset, including Minimal-Mono.
- **D-08:** Prefer a bounded numeric-cell solution—measured column retuning, amount-specific fitting, or an existing non-breaking layout primitive—before shrinking the entire Payslip type scale. Preserve right alignment, Decimal formatting, description readability, reconciliation, and pagination.
- **D-09:** Preserve the no-theme bytes and the existing `:payslip_sans` fallback behavior. Do not introduce a public no-wrap API or a new font dependency unless research proves the existing private/layout seams cannot satisfy the requirement.

### Golden and typography depth

- **D-10:** Add a dedicated, table-driven byte golden over one stable realistic recipe/input that proves more than the historical single `from_brand/2` call: include `from_brand` and representative `Theme.preset/2` paths across at least two distinct accents, assert two-run equality, and bind the expected hashes. Keep the matrix deliberately bounded rather than multiplying every genre × accent × mode combination already covered elsewhere.
- **D-11:** Bring all seven recipes to dedicated typography-contract coverage. Four test modules currently exist (Invoice, Statement, Certificate, Ticket); planning must inspect their actual assertions and add or deepen the missing BrandedInvoice, Payslip, and Receipt coverage so every recipe proves its materialized scale, font roles, leading, and winning explicit override behavior.
- **D-12:** Existing smoke, byte-identity, deterministic preset-matrix, and raster tests remain useful but do not substitute for recipe-specific semantic typography assertions. Avoid duplicating the full twelve-row Phase 125 matrix in the new golden lane.

### Evidence closure and review ergonomics

- **D-13:** Close `.planning/WINDOWS.md` ids 1–3 only after focused regression tests, the relevant full deterministic suites, and fresh pinned-PDFium output for affected rows all pass. Update `priv/quality/SIGN-OFF.md` and `priv/quality/rubric_scores.json` from the new evidence; do not merely flip `passed` fields.
- **D-14:** Re-render only the affected launch/preset evidence unless a shared-byte change mechanically requires broader regeneration. Keep deterministic and advisory verification lanes separate and keep `priv/goldens` changes explicit.
- **D-15:** If human visual judgment is requested, present affected images at readable size in a sequential slideshow/lightbox-style review rather than only as a dense contact sheet. This is review ergonomics, not a new shipped UI feature.
- **D-16:** Phase completion means the three known defects are fixed and evidenced, all seven recipes have explicit typography coverage, the bounded accent golden is stable, and `mix test` plus `mix ci.fast` pass. Previously accepted Phase 125 preset imagery must not regress.

### the agent's Discretion

The planner may choose private helper names, exact affected raster rows, the stable golden fixture and two-or-more accent values, and whether amount integrity is achieved by measured widths or an existing private fitting seam. Research should determine the narrowest shared table-cell mechanism and the exact Ticket themed-role remapping. No public API, new dependency, per-preset recipe branch, blanket contrast claim, or premature catalog artifact may be introduced.

### Deferred Ideas (OUT OF SCOPE)

- Phase 127 owns public catalog generation, row-budget policy, and catalog-wide quality scoring.
- Phase 128 owns the shipped static configurator; a reusable browser-based slideshow/lightbox may be considered there if it naturally supports catalog browsing.
- Phase 129 owns final public guide/support-matrix/claim-language closure.
- A general public table-cell styling or no-wrap API is deferred unless Phase 126 research proves a private/shared existing seam cannot solve the bounded defects.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| POLISH-01 | Fix `invoice_dark` table-body legibility at shared color-role level. | The concrete Invoice table currently emits bare strings; a private themed-cell helper preserves the nil-theme string path while emitting `colors.ink` blocks only for themed tables. [VERIFIED: local codebase] |
| POLISH-02 | Resolve Ticket display/title hierarchy inversion or explicit carve-out. | Locked decisions require a real fix: preserve native mapping but give themed Ticket a semantic mapping where placement is dominant, title secondary, and reference compact. [VERIFIED: local codebase] |
| POLISH-03 | Prevent Payslip themed money wrapping, including Minimal-Mono. | Existing measured rows, fixed columns, and explicit right alignment make narrow amount-column retuning the first private solution to validate. [VERIFIED: local codebase] |
| POLISH-04 | Add bounded `from_brand`/preset × accent byte golden. | Existing deterministic rendering and SHA-256 in recipe byte-identity tests establish the exact test pattern; use one registered realistic recipe fixture and 3–4 variants. [VERIFIED: local codebase] |
| POLISH-05 | Give all seven recipes explicit type-scale coverage. | Four modules exist today; add BrandedInvoice, Payslip, and Receipt contract tests and deepen existing assertions from raise-path-only to structure/override checks. [VERIFIED: local codebase] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep `rendro` core pure; do not add a hard dependency on Phoenix, Oban, or admin tooling.
- Preserve deterministic and advisory verification lane separation in CI and documentation.
- Treat documentation claims as contracts; do not claim unsupported capabilities.
- Prefer optional-dependency guards for integrations.
- Preserve the data-first `build -> compose -> measure -> paginate -> render -> validate` pipeline, one render core, and product-level errors/telemetry. [VERIFIED: AGENTS.md]

## Summary

Phase 126 should be planned as a narrow repair-and-evidence phase, not a new theming feature. The target recipes already isolate a nil-theme compatibility branch from a resolved-theme branch. The correct implementation strategy is therefore to add themed-only semantic construction at each existing seam while retaining literal unthemed cells, fonts, geometry, and frozen hashes. [VERIFIED: local codebase]

The three visual defects have distinct owners: Invoice table-cell construction (semantic ink), Ticket’s themed role map (relative hierarchy plus stub fitting), and Payslip’s measured fixed amount columns (atomic money tokens). Their shared evidence pipeline already exists: focused ExUnit contracts and deterministic bytes are required proof, while pinned-PDFium rasters and human reading judgment remain advisory and must be recorded separately. [VERIFIED: local codebase]

**Primary recommendation:** Add no dependency or public API; repair themed-only private recipe seams, prove them with focused structural/byte tests, then regenerate only the affected pinned evidence and quality records. [VERIFIED: local codebase]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Semantic table ink | API / Backend | — | Recipe builders construct `Rendro.Table` cells before the render pipeline; color roles are recipe data, not a viewer concern. [VERIFIED: local codebase] |
| Ticket hierarchy and reference fit | API / Backend | Database / Storage — | `Ticket` maps roles and block widths; quality records later persist evidence but do not determine layout. [VERIFIED: local codebase] |
| Payslip money-cell integrity | API / Backend | — | Fixed column widths, measured rows, cell blocks, and alignment are all recipe/layout responsibilities. [VERIFIED: local codebase] |
| Byte golden and typography contracts | API / Backend | — | ExUnit exercises deterministic documents and extracted `%Text{}`/table data directly. [VERIFIED: local codebase] |
| Pinned raster review | CDN / Static | API / Backend | PDFs are rendered by core code, then optional PDFium produces committed/review PNG evidence. [VERIFIED: local codebase] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---|---|---|
| Elixir / OTP | 1.19.5 / 28 | Recipe changes and tests. | Installed project runtime; no new package is required. [VERIFIED: local environment] |
| ExUnit | bundled with Elixir 1.19.5 | Structural, determinism, and hash assertions. | Existing project test framework; `assert` supports equality and pattern contracts. [CITED: https://hexdocs.pm/ex_unit/ExUnit.Assertions.html] |
| Rendro.Theme + Presets | local | Fully materialized theme values and explicit curated-font registration. | Existing production seam for `from_brand/2` and `preset/2`. [VERIFIED: local codebase] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---|---|---|
| Project-pinned PDFium adapter | pinned v0.11.0 | Advisory page-one raster evidence. | Only after deterministic proof; use the checked provenance/container route. [VERIFIED: local codebase] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Private themed table-cell helper | Global `Rendro.Table` default color change | Global behavior would threaten unrelated unthemed callers and frozen bytes. [VERIFIED: local codebase] |
| Private amount-column retune | Public no-wrap API | A public API expands scope and is deferred; the existing fixed-column seam can address this bounded regression. [VERIFIED: local codebase] |
| Focused accent golden | Full genre × accent × mode cross-product | The 12-row preset matrix already covers genre/mode determinism; the new requirement is specifically bounded accent variation. [VERIFIED: local codebase] |

**Installation:** None — this phase introduces no external package. [VERIFIED: local codebase]

## Architecture Patterns

### System Architecture Diagram

```text
Theme.preset/2 or Theme.from_brand/2
              |
              v
Recipe palette/typography seam
              |
              +--> Invoice themed table cells -> semantic ink blocks
              +--> Ticket themed role map -> placement > title > reference
              +--> Payslip measured columns -> atomic right-aligned money cells
              |
              v
build -> compose -> measure -> paginate -> render (deterministic PDF)
              |                                  |
              v                                  +--> SHA-256 golden / ExUnit contracts
      optional pinned PDFium raster
              |
              v
SIGN-OFF.md + rubric_scores.json + WINDOWS ids 1–3
```

The flow keeps recipe behavior, deterministic proof, and advisory visual evidence separate. [VERIFIED: local codebase]

### Recommended Project Structure

```text
lib/rendro/recipes/
├── invoice.ex                 # themed table cell construction
├── ticket.ex                  # themed hierarchy/reference-width seam
└── payslip.ex                 # amount-cell width/fitting seam

test/rendro/recipes/
├── *_typography_test.exs      # all seven explicit typography contracts
└── *_byte_identity_test.exs   # frozen nil-theme bytes

test/rendro/theme/
├── preset_render_matrix_test.exs
├── preset_raster_snapshot_test.exs
└── preset_accent_golden_test.exs # new bounded golden
```

### Pattern 1: Preserve nil-theme literals; specialize only resolved-theme cells

**What:** Branch at the existing recipe-level seam: keep the exact string/list cells for `theme: nil`, but create `Rendro.block(Rendro.text(..., color: colors.ink))` cells for themed header/body values. [VERIFIED: local codebase]

**When to use:** Invoice table construction, and only other recipes that opt into the same private helper. [VERIFIED: local codebase]

**Example:**

```elixir
# Source: verified local Invoice/Payslip table patterns
defp themed_cell(text, colors, type) do
  Rendro.block(
    Rendro.text(text,
      size: type.scale.body,
      font: type.fonts.body,
      line_height: type.leading,
      widows: type.widows,
      orphans: type.orphans,
      color: colors.ink
    )
  )
end
```

### Pattern 2: Semantic role adaptation must be themed-only and monotonic for Ticket

**What:** Keep Ticket’s legacy nil-theme sizes byte-identical; when a theme is supplied, map placement to the largest semantic role, event title to the next role, and reference to a compact subordinate role. Widen or fit the reference’s existing block only enough to avoid ordinary mid-token splitting. [VERIFIED: local codebase]

**When to use:** `Ticket.typography/1`, `main_section/2`, and `reference_blocks/6`; do not branch by preset. [VERIFIED: local codebase]

### Pattern 3: Measure the real amount token, then retune a bounded column

**What:** Use `Rendro.measure_rows/4` with the same block cells and document font registration used for rendering. Select width(s) that fit the largest stable money fixture for default and presets, retain existing `cell_align`, and keep descriptions as the wrapping fields. [VERIFIED: local codebase]

**When to use:** Payslip ledger only; do not shrink the whole type scale or alter Decimal formatting. [VERIFIED: local codebase]

### Anti-Patterns to Avoid

- **Global table default recolor:** Would change bare-string callers outside the themed path and break the frozen no-theme constraint. [VERIFIED: local codebase]
- **Preset-specific recipe branches:** Contradict the locked no-genre-branch rule; roles, not preset identities, must drive recipes. [VERIFIED: CONTEXT.md]
- **Reference truncation or image-only code:** Violates the required visible/copyable reference contract. [VERIFIED: CONTEXT.md]
- **Hash-only “fix”:** A blessed byte hash proves repeatability, not legibility or hierarchy; retain structural and raster evidence. [VERIFIED: local codebase]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Table layout/measurement | Manual column geometry or width estimates | `Rendro.measure_rows/4` + existing `Rendro.table/2` column model | The core already measures rows using document fonts and paginates them. [VERIFIED: local codebase] |
| Font registration | Recipe-local font loading | `Rendro.Theme.Presets.register_fonts/2` | Curated roles must be registered explicitly and existing matrix tests prove its omission failure. [VERIFIED: local codebase] |
| Determinism framework | New snapshot/golden dependency | Existing two-run PDF equality plus SHA-256 ExUnit pattern | It matches established byte-identity tests and adds no dependency. [VERIFIED: local codebase] |
| Raster engine | Native/unpinned image conversion | Existing pinned PDFium adapter/raster test | The adapter checks executable provenance and version before accepting hashes. [VERIFIED: local codebase] |

**Key insight:** The phase is a composition/role-mapping correction; the existing renderer, measurement API, font bridge, and verification layers already solve the hard infrastructure problems. [VERIFIED: local codebase]

## Common Pitfalls

### Pitfall 1: Protecting frozen bytes by skipping the actual themed repair

**What goes wrong:** The defect remains because bare table strings never get semantic ink. [VERIFIED: local codebase]

**How to avoid:** Make the nil-theme row construction exactly literal/unchanged, and switch only the supplied-theme path to private blocks/text with explicit roles. Re-run every relevant byte-identity golden. [VERIFIED: local codebase]

### Pitfall 2: Fixing Ticket size but retaining reference overflow

**What goes wrong:** A smaller role alone can still leave a narrow stub that splits an ordinary reference token. [VERIFIED: local codebase]

**How to avoid:** Test role ordering and the normal fixture reference as a complete text run under every curated preset/mode row affected; tune the existing width/fitting seam if necessary. [VERIFIED: local codebase]

### Pitfall 3: Measuring Payslip with the wrong font context

**What goes wrong:** The measured width does not match the rendered fallback/curated font and money wraps in production. [VERIFIED: local codebase]

**How to avoid:** Preserve `:payslip_sans`, use the existing document prepared for measurement, and test the largest Current/YTD values under Minimal-Mono. [VERIFIED: local codebase]

### Pitfall 4: Treating the raster lane as deterministic CI

**What goes wrong:** Platform-dependent visual evidence blocks the deterministic lane or gets blessed outside the pinned environment. [VERIFIED: local codebase]

**How to avoid:** Keep regular `mix test`/`mix ci.fast` separate from `:raster_snapshot`; only bless from the pinned CI route and state its advisory scope honestly. [VERIFIED: local codebase]

### Pitfall 5: Updating quality prose without changed evidence

**What goes wrong:** `WINDOWS`, sign-off, and rubric records say the issue is closed while the underlying PDF remains defective. [VERIFIED: CONTEXT.md]

**How to avoid:** Sequence code + focused tests, deterministic suite, fresh raster artifacts, then record the actual visual findings and close ids 1–3. [VERIFIED: CONTEXT.md]

## Code Examples

### Bounded deterministic preset/accent golden

```elixir
# Source: verified local *_byte_identity_test.exs and PresetRenderMatrix patterns
for {name, theme, genre} <- [
      {:from_brand_blue, Theme.from_brand(accent: "#2C6BED"), nil},
      {:swiss_blue, Theme.preset(:swiss, accent: "#2C6BED"), :swiss},
      {:minimal_mono_orange, Theme.preset(:minimal_mono, accent: "#D97706"), :minimal_mono}
    ] do
  document = Invoice.document(realistic_data(), theme: theme)
  document = if genre, do: Presets.register_fonts(document, genre), else: document

  assert {:ok, first} = Rendro.render(document, deterministic: true)
  assert {:ok, second} = Rendro.render(document, deterministic: true)
  assert first == second
  assert sha256(first) == @expected_hashes[name]
end
```

This is intentionally a separate, bounded test module; it does not replicate the twelve-row preset matrix. [VERIFIED: local codebase]

### Typography contract shape

```elixir
# Source: verified local recipe typography and options-threading patterns
theme = Theme.preset(:humanist, accent: "#2C6BED")
document = Receipt.document(sample_data(), theme: theme,
  typography: %{scale: %{body: 11.25}}
)

assert [%Rendro.Section{} | _] = Receipt.sections(sample_data(), theme: theme)
assert {:ok, _pdf} = Rendro.render(Presets.register_fonts(document, :humanist), deterministic: true)
# Assert extracted text cells/blocks use materialized scale, role font, leading,
# and explicit `:typography` override as the winning layer.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Single `from_brand/2` call validation | `Theme.preset/2` with six curated genre tokens and explicit font registration | Phase 125 | Phase 126 can now prove accent variation across both construction paths. [VERIFIED: local codebase] |
| Smoke + frozen byte checks for four recipes | Recipe-specific typography-contract coverage for all seven | This phase | Closing the semantic coverage gap requires inspecting emitted roles and overrides, not only successful rendering. [VERIFIED: CONTEXT.md] |
| One generic themed Ticket scale | Themed-only semantic hierarchy mapping | This phase | Required to restore placement dominance while retaining legacy bytes. [VERIFIED: CONTEXT.md] |

**Deprecated/outdated:** Treating an existing passed raster or a deterministic matrix row as sufficient semantic typography coverage is out of scope for Phase 126’s completion criteria. [VERIFIED: CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | The existing private `Rendro.Table`/block cell path can fit all inspected realistic Payslip money values after column retuning without a new no-wrap primitive. | Architecture Patterns | If false, implementation must evaluate the existing private fitting seam before proposing any API. |
| A2 | The pinned container-wrapper workflow remains usable from this Docker-equipped host even though `pdfium-cli` is absent from PATH. | Environment Availability | Advisory raster regeneration needs an operator/CI environment adjustment. |

## Open Questions

1. **What exact themed Ticket mapping preserves all six presets while keeping reference compact?**
   - What we know: current themed `display=21`, `title=16.5`, and existing stub width cause the documented inversion and three-line reference. [VERIFIED: local codebase]
   - What's unclear: whether reassignment alone fits the fixture reference or whether the existing `avail_w` needs a narrow geometric adjustment.
   - Recommendation: make implementation test the full six-preset matrix with focused Ticket role/order assertions before choosing helper/width constants. [VERIFIED: CONTEXT.md]

2. **Which 3–4 golden variants give the best accent coverage?**
   - What we know: the requirement requires `from_brand` plus preset paths and at least two distinct accents.
   - What's unclear: the exact hashes until the stable realistic fixture is rendered.
   - Recommendation: choose one default-font `from_brand` Invoice fixture and two registered preset variants with visibly distinct blue/orange (or similarly distinct) accents; bind values only from an actual deterministic render. [VERIFIED: local codebase]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir / OTP | recipe builds and ExUnit | ✓ | Elixir 1.19.5 / OTP 28 | — [VERIFIED: local environment] |
| Mix | focused and CI suites | ✓ | bundled with Elixir | — [VERIFIED: local environment] |
| Docker | pinned PDFium advisory evidence | ✓ | 29.5.2 | — [VERIFIED: local environment] |
| `pdfium-cli` on PATH | direct advisory raster run | ✗ | — | Existing provenance-aware container wrapper/CI route. [VERIFIED: local environment] |

**Missing dependencies with no fallback:** None. [VERIFIED: local codebase]

**Missing dependencies with fallback:** Global `pdfium-cli`; use the existing pinned wrapper/container route, never a host-unpinned raster substitute. [VERIFIED: local codebase]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit (bundled with Elixir 1.19.5). [VERIFIED: local environment] |
| Config file | `test/test_helper.exs`; it excludes raster snapshots from the default suite. [VERIFIED: local codebase] |
| Quick run command | `mix test test/rendro/theme/preset_render_matrix_test.exs test/rendro/recipes/*typography_test.exs` |
| Full suite command | `mix test` then `mix ci.fast` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| POLISH-01 | Themed Invoice table header/body cells source semantic colors; no-theme hash remains frozen. | unit + byte golden | `mix test test/rendro/recipes/invoice*_test.exs` | ✅ existing baseline; focused color assertions are a phase addition. |
| POLISH-02 | Ticket placement > title > reference and normal reference does not split under presets. | unit + deterministic matrix | `mix test test/rendro/recipes/ticket*_test.exs test/rendro/theme/preset_render_matrix_test.exs` | ✅ baseline; semantic order assertions are a phase addition. |
| POLISH-03 | Default/preset Payslip Current/YTD tokens stay on one visual cell line and right-aligned. | unit + deterministic matrix | `mix test test/rendro/recipes/payslip*_test.exs test/rendro/theme/preset_render_matrix_test.exs` | ✅ baseline; atomic-money regression case is a phase addition. |
| POLISH-04 | Bounded from-brand/preset × accent PDFs are equal across two runs and match named hashes. | byte golden | `mix test test/rendro/theme/preset_accent_golden_test.exs` | ❌ Wave 0 |
| POLISH-05 | All recipes prove type scale, roles, leading, and explicit override precedence. | unit | `mix test test/rendro/recipes/*typography_test.exs` | ❌ add BrandedInvoice/Payslip/Receipt and deepen four existing modules. |

### Sampling Rate

- **Per task commit:** relevant focused files plus `mix format --check-formatted`. [VERIFIED: local codebase]
- **Per wave merge:** `mix test`. [VERIFIED: local codebase]
- **Phase gate:** `mix ci.fast` green; run pinned-PDFium affected rows separately as advisory evidence. [VERIFIED: local codebase]

### Wave 0 Gaps

- [ ] `test/rendro/theme/preset_accent_golden_test.exs` — POLISH-04 bounded table-driven hashes.
- [ ] `test/rendro/recipes/branded_invoice_typography_test.exs` — POLISH-05.
- [ ] `test/rendro/recipes/payslip_typography_test.exs` — POLISH-05 plus fallback preservation.
- [ ] `test/rendro/recipes/receipt_typography_test.exs` — POLISH-05.
- [ ] Deepen Invoice, Statement, Certificate, and Ticket typography tests from their current targeted assertions to explicit scale/role/leading/override contracts. [VERIFIED: local codebase]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No request/auth surface is added. [VERIFIED: local codebase] |
| V3 Session Management | no | No session surface is added. [VERIFIED: local codebase] |
| V4 Access Control | no | No access-control surface is added. [VERIFIED: local codebase] |
| V5 Input Validation | yes | Preserve existing recipe data validation and fixed theme option validation; do not introduce raw/unvalidated public options. [VERIFIED: local codebase] |
| V6 Cryptography | yes | Use existing `:crypto.hash(:sha256, pdf)` for golden integrity; do not implement hashing. [VERIFIED: local codebase] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Untrusted theme/data produces invalid layout or font references | Tampering / DoS | Retain recipe validators and existing typed render failures; add only private seams. [VERIFIED: local codebase] |
| Visual evidence is blessed from an unpinned rasterizer | Tampering | Pinned PDFium version + executable hash, with blessing restricted to CI. [VERIFIED: local codebase] |
| Misleading legibility/accessibility claim | Repudiation | Record only bounded visual evidence; do not claim WCAG/PDF-UA conformance. [VERIFIED: CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- Local `lib/rendro/recipes/{invoice,ticket,payslip}.ex` — concrete themed/nil branches, table cells, role mapping, measured columns, and `:payslip_sans` fallback. [VERIFIED: local codebase]
- Local `test/rendro/theme/{preset_render_matrix_test,preset_raster_snapshot_test}.exs` and `test/rendro/recipes/*byte_identity_test.exs` — deterministic and advisory evidence patterns. [VERIFIED: local codebase]
- Local `.planning/WINDOWS.md`, `priv/quality/SIGN-OFF.md`, and `priv/quality/rubric_scores.json` — exact defect provenance and honesty requirements. [VERIFIED: local codebase]

### Secondary (MEDIUM confidence)

- [ExUnit Assertions documentation](https://hexdocs.pm/ex_unit/ExUnit.Assertions.html) — equality, match, and exception assertion semantics. [CITED: https://hexdocs.pm/ex_unit/ExUnit.Assertions.html]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — entirely existing project runtime and no installations. [VERIFIED: local codebase]
- Architecture: HIGH — exact recipe/test seams inspected. [VERIFIED: local codebase]
- Pitfalls: HIGH — root causes are recorded in the broken-windows ledger and quality evidence. [VERIFIED: local codebase]

**Research date:** 2026-08-16
**Valid until:** 2026-09-15 (stable internal codebase findings; refresh after any upstream phase edit).
