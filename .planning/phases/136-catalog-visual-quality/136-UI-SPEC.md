---
phase: 136
slug: catalog-visual-quality
status: draft
shadcn_initialized: false
preset: none
created: 2026-08-27
---

# Phase 136 — UI Design Contract

> Visual and interaction contract for the six scored PDF catalog cells and their evidence-review flow. This phase produces document surfaces, not a browser control surface.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none — pure Elixir PDF recipes; no web UI or shadcn gate applies |
| Preset | existing Corporate Classic, Minimal Mono, Swiss, and Brutalist presets; target-scoped private profiles only |
| Component library | existing Rendro document primitives: text, table, section, palette, measurement, pagination |
| Icon library | none |
| Font | Preserve each preset's registered font roles; use semantic text roles, not a new typeface or public type API |

**Scope rule:** the literal allowlist is exactly `invoice--cedar-mutual--corporate-classic--dark`, `statement--signal-ledger--minimal-mono--dark`, `payslip--northline-logistics--swiss--light`, `payslip--northline-logistics--swiss--dark`, `ticket--aurora-live--brutalist--light`, and `ticket--aurora-live--brutalist--dark`. The remaining 26 cells must be byte-identical in source-PDF and PNG hashes. Catalog identity stays in dev-only tooling; recipes consume generic private presentation profiles and never IDs, brands, presets, or phase names.

---

## Spacing Scale

Declared values are PDF points for recipe-local spacing; use the nearest existing preset/layout seam and preserve locked geometry where this table does not explicitly change it.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4pt | Label-to-value and rule-adjacent clearance |
| sm | 8pt | Compact document fact grouping |
| md | 16pt | Table, ledger, and summary separation |
| lg | 24pt | Major document-region separation |
| xl | 32pt | Dominant-band and primary-group breathing room |
| 2xl | 48pt | Major page-area separation where an existing recipe supports it |
| 3xl | 64pt | Not introduced by this phase; reserved existing page-level whitespace |

Exceptions: Ticket locator remains a single equal-share row; Payslip description and money widths are measurement-derived rather than forced to this scale. Do not globally retune page margins, preset spacing, or target-pair geometry.

---

## Typography

Use the existing preset typography scale and registered font roles. Phase 136 introduces **no point sizes and no font-weight changes**: profile tuning may change only semantic palette treatment and the locked Payslip/Ticket geometry. Each target profile below declares the four exact existing sizes allowed for its Phase 136 presentation; do not substitute, interpolate, or add a fifth size during raster iteration.

| Target profile | Exact existing sizes / assigned roles | Weight | Leading |
|----------------|---------------------------------------|--------|---------|
| Corporate Classic Invoice dark | 8pt caption/utility; 10pt body/facts; 12pt table heading/support; 18pt `Total Due` display | Existing registered regular face (400); no added weight | 1.3 |
| Minimal Mono Statement dark | 8pt caption/utility; 9.5pt body/context; 11pt ledger heading/facts; 16pt `Closing Balance` display | Existing registered regular face (400); no added weight | 1.25 |
| Swiss Payslip light and dark | 8pt caption/utility; 10.5pt body/facts; 13pt ledger heading/support; 21pt `Net Pay` display | Existing registered regular face (400); no added weight | 1.3 |
| Brutalist Ticket light and dark | 8pt locator label/utility; 10pt subtitle/terms; 20pt title; 34pt placement display | Existing registered regular face (400); no added weight | 1.2 |

The four-size profile tables constrain Phase 136 additions only; unchanged non-target recipe content retains its existing source behavior under the byte-stability contract. Monetary strings are unbroken atomic text; numeric columns are right aligned.

---

## Color

Apply existing palette roles, never raw black/default ink call sites, raster overlays, or global `Theme.dark/1` retuning. Percentages describe perceived page composition, not a new token system.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | existing light `surface` / dark warm-neutral `surface` (`night-700` family) | Page field and main document surface |
| Secondary (30%) | existing `paper`/raised light surface or dark warm-neutral supporting surface and rules | Summary bands, table-header surface, stub/reference boundary, boxed balance |
| Accent (10%) | existing preset accent (Corporate blue where already present) | Corporate `Total Due` only; do not introduce accent to Statement, Payslip, Ticket, or generic labels |
| Destructive | none | No destructive rendered-document action exists in this phase |

Accent reserved for: the existing Corporate Classic Invoice `Total Due` focal amount and its existing accent semantics only. Primary ink is required for functional labels, table headings, values, and active accounting facts. Secondary ink is required for dates, addresses, terms, opening/context balances, subtotal/tax support facts, footers, ticket labels, stub/reference text, perforation/rules, and terms. No information-bearing text may depend on hue alone or sit near its background.

Dark output remains screen-oriented with `print_safety: false`; stronger semantic contrast is a readability repair, not a WCAG, PDF/UA, viewer-support, accessibility, or print-safety claim.

---

## Surface Contracts

### 1. Corporate Classic Invoice — dark

- Preserve page geometry, caller data, fonts, pagination, and existing blue-accent meaning.
- Render functional labels and the `Item`, `Qty`, and `Price` headings in primary semantic ink. Render issuer/customer addresses, invoice/date/due/terms, subtotal, tax, and footer in a deliberate secondary semantic ink.
- `Total Due` remains the sole display-size focal element. Do not promote the header, table headings, or support facts to competing display emphasis.
- Check at readable full size that every label is distinguishable from the warm dark surface and that the anchor remains visually first in the invoice's scan path.

### 2. Minimal Mono Statement — dark

- Preserve the operational ledger geometry, source data, font roles, and pagination.
- Render `Date`, `Description`, `Amount`, and `Balance` headers plus row values in primary semantic ink; render date range, opening balance, page footer, and other context in secondary semantic ink.
- Keep boxed `Closing Balance` as the sole display-size focal element. The high-contrast ledger must support reconciliation without competing with that boxed total.
- Maintain mono/ledger restraint: no decorative color, new cards, or global palette changes.

### 3. Swiss Payslip — light and dark

- Both modes use identical structure and geometry: a full-width `Earnings | Current | YTD` table followed by a full-width `Deductions | Current | YTD` table. This replaces the paired seven-column ledger only for the generic target-selected sequential-ledger profile.
- Keep every fixture description verbatim, including long labels. Description is the one flexible/shared column; `Current` and `YTD` each have explicit font-measured widths with headroom for the widest monetary token. Amounts are right aligned and indivisible; never wrap, clip, abbreviate, or shrink text merely to fit.
- Each table owns its semantic header. Use measured row heights and native pagination; on continuation, repeat that table's own header and do not leave a section heading orphaned at the page bottom.
- Keep `NET PAY` uniquely dominant. Keep the final `Gross Pay - Total Deductions = Net Pay` reconciliation contiguous with the final ledger rows; reserve its measured space during pagination.
- Light and dark differ only in semantic palette treatment. In dark, header text, body text, rules, and summary use their palette roles; no raw-black header/body fallback is permitted. Dark retains `print_safety: false`.

### 4. Brutalist Ticket — light and dark

- Preserve the A6 ticket archetype, left-to-right single locator row, source order, and equal-share placement-group geometry: `Section | Row | Seat | Gate` above atomic values `GA | H | 24 | B`.
- Labels sit directly above their own values. `GA`, `H`, `24`, and `B` must each fit on one line and stay in distinct cells: `GA` must never split and `24`/`B` must never visually read as `24B`.
- The placement group is the page's sole dominant hierarchy. Title, subtitle, reference/stub, perforation/rules, and terms stay subordinate while remaining readable.
- Use identical light/dark geometry. In dark, raise muted label, reference/stub, perforation/rule, and terms contrast enough for rapid screen scanning without softening the rectilinear Brutalist motif. Retain `print_safety: false`.

### 5. Evidence-review experience — sealed, document-first flow

This is an operator procedure and review record, not a new browser UI.

1. Dispatch one `review` operation for one full immutable candidate SHA using the existing Catalog Evidence workflow.
2. Before inspecting any image, validate the root manifest and checksums plus candidate/HEAD/control identity, pinned PDFium version and executable SHA, run ID, attempt, closed payload roles, counts, and artifact hashes. A failure stops visual interpretation and routes to the runbook's corrective action.
3. Review only full-size reconciled images in this order: Corporate Classic Invoice light control → dark target; Minimal Mono Statement light control → dark target; Swiss Payslip light → dark; Brutalist Ticket light → dark. Thumbnails and stale references are navigation aids only.
4. Record one independent reviewer-owned result per target: all six dimension scores, reading order, `print_safety`, concise rationale, reviewer identity/date, candidate SHA, PDFium identity, run/attempt, source-PDF hash, PNG hash, artifact URL/digest, and prior/superseded evidence reference.
5. Record actual misses. Phase success requires content hierarchy `5`, every other scored visual dimension `>=4`, and preserved reading order for every target. This is separate from complete manifest `passed` arithmetic: dark records may meet the visual threshold while correctly remaining unpromoted because `print_safety: false`.
6. Generate/check canonical 32-cell output only after deterministic six-changed/26-byte-stable proof and all six phase visual thresholds. Candidate creation must never write review/quality approval fields.

---

## Copywriting Contract

Document labels are source/caller data except where the existing recipe owns a semantic label; do not alter fixture wording to repair layout. The publication confirmation below is operator-facing procedural/runbook text outside the rendered-document color system; it does not imply a destructive document color, web control, or new UI surface.

| Element | Copy |
|---------|------|
| Primary CTA | `Validate review bundle` — the operator action that must precede image review |
| Empty state heading | `No review bundle is available for this candidate.` |
| Empty state body | `Dispatch the Catalog Evidence workflow with one full immutable commit SHA and operation review, then validate the downloaded bundle before scoring.` |
| Error state | `Catalog evidence bundle could not be validated. Do not score its images. Inspect the reported manifest, checksum, identity, renderer-pin, role, or count failure; correct the bounded source/control mismatch and rerun review for the same immutable SHA.` |
| Destructive confirmation | `Publish canonical catalog`: `Confirm that all six target records meet the Phase 136 visual threshold and the candidate proves exactly six changed IDs with 26 byte-stable controls. Canonical publication does not change dark print-safety or make a compliance claim.` |

Microcopy principles: use concrete nouns and precise verbs; state what failed, where the evidence differs, why that invalidates review, and the next command/action. Never say “approved,” “accessible,” “print-safe,” or “passed” when only generation, a partial score, or screen-readable dark contrast is evidenced.

---

## UI Considerations

The compiled UI-consideration probe was run over six authored surface kinds: Invoice and Statement static/list content, Payslip static/list content, Ticket static content, the review bundle's media/list/form/static content, and the canonical runbook procedure's static content. Kind confirmation found no missing element kind. Coverage is 36 applicable, 36 resolved, 0 unresolved: 28 explicit and 8 backstop. No item was silently dismissed.

### Covered

- Invoice empty: catalog fixture validation rejects a missing invoice payload; Phase 136 never renders an empty-document substitute.
- Invoice loading: PDF generation is atomic and exposes no document loading state; only a completed PDF or an existing structured error reaches catalog tooling.
- Invoice error: existing recipe validation/render errors remain structured failures; Phase 136 does not emit a partial fallback PDF.
- Invoice populated: the existing Cedar Mutual fixture and exact item rows remain unchanged while only the private dark presentation profile changes semantic ink.
- Invoice partial: missing required invoice data remains an upstream recipe validation failure; optional facts retain their existing source behavior.
- Invoice zero/one/many: existing row-count behavior remains unchanged; the target profile introduces no collection padding or new empty copy.
- Statement empty: catalog fixture validation rejects a missing statement payload; Phase 136 never renders an empty-document substitute.
- Statement loading: PDF generation is atomic and exposes no document loading state; only a completed PDF or an existing structured error reaches catalog tooling.
- Statement error: existing recipe validation/render errors remain structured failures; Phase 136 does not emit a partial fallback PDF.
- Statement populated: the existing Signal Ledger fixture rows remain unchanged while only the private dark presentation profile changes semantic ink.
- Statement partial: missing required statement data remains an upstream recipe validation failure; optional facts retain their existing source behavior.
- Statement zero/one/many: existing row-count behavior remains unchanged; the target profile introduces no padding or new empty copy.
- Payslip empty: each sequential ledger owns its header and existing zero-row behavior; no paired-table blank-padding grid is generated.
- Payslip loading: PDF generation is atomic and exposes no document loading state; only a completed PDF or an existing structured error reaches catalog tooling.
- Payslip error: invalid data or impossible measured layout remains a structured render/validation error, never a clipped or partially approved PDF.
- Payslip populated: the Northline fixture renders full-width Earnings then Deductions tables, followed by contiguous reconciliation and uniquely dominant Net Pay.
- Payslip partial: Earnings and Deductions are independent sequential sections; one may have fewer rows without fake blank rows, while required reconciliation stays present.
- Payslip zero/one/many: focused tests cover zero, one, and many rows per sequential table without paired-grid padding and with deterministic section order.
- Review bundle empty: show the Copywriting Contract empty state and require a new exact-SHA review dispatch; missing evidence is never approval.
- Review bundle loading: until download and deterministic validation complete, images are ineligible for review; there is no invented browser or in-document loading surface.
- Review bundle error: show the Copywriting Contract validation error with the failing manifest/checksum/identity/pin/role/count condition and prohibit scoring.
- Review bundle populated: the valid happy path is one closed manifest-rooted bundle with reconciled full-size images reviewed in the locked family-paired order.
- Review bundle partial: any missing target image, score, reading order, provenance field, role, count, or hash leaves the record unpromoted and blocks canonical materialization.
- Review bundle overflow: review uses full-size images rather than cropped thumbnails; provenance values remain complete machine-checked strings rather than truncated identifiers.
- Review bundle zero/one/many: bundle contracts require exactly six target review records and classify exactly six changed IDs plus 26 byte-identical controls.
- Review bundle long text: error details and reviewer rationale remain complete and concise; machine identity and digest fields are preserved verbatim and validated rather than shortened.
- Canonical-procedure overflow: ordinary runbook/terminal text stays outside the document color system and may wrap without hiding required predicates.
- Canonical-procedure long text: confirmation names the exact six/26 proof, all-six visual threshold, and dark print-safety boundary without abbreviation or compliance overclaim.

### Backstops

- statement: Held-out existing long Invoice facts and item content retain deterministic wrapping, geometry, and pagination under semantic-ink-only changes.
  verification: backstop
- statement: Existing long Invoice labels and facts retain deterministic measured wrapping without clipping or changing caller text.
  verification: backstop
- statement: Held-out existing long Statement ledger facts retain deterministic wrapping, geometry, and pagination under semantic-ink-only changes.
  verification: backstop
- statement: Existing long Statement descriptions and contextual facts retain deterministic measured wrapping without clipping or caller-text changes.
  verification: backstop
- statement: Held-out Payslip longest labels, widest money tokens, and continuation pages prove flexible descriptions, atomic right-aligned money, native pagination, repeated own-table headers, and reserved reconciliation space.
  verification: backstop
- statement: Held-out verbatim Payslip descriptions wrap only in the flexible description column; headers and monetary tokens never wrap, clip, abbreviate, or shrink.
  verification: backstop
- statement: Ticket render assertions prove the one-row equal-share locator keeps `GA`, `H`, `24`, and `B` atomic and distinct in light and dark with no `24B` association.
  verification: backstop
- statement: Held-out Ticket subtitle, terms, and reference strings wrap only in existing flexible prose regions; the four locator labels and values never wrap or truncate.
  verification: backstop

---

## Verification Contract

| Concern | Deterministic proof | Advisory human evidence |
|---------|---------------------|------------------------|
| Scope isolation | Literal six-ID allowlist; candidate classification reports exactly six changed IDs and exactly 26 PDF/PNG byte-stable controls | None required |
| Semantic dark repair | Target profile tests assert semantic primary/secondary text/header roles and unchanged no-profile/default paths | Full-size dark pair review confirms readable scan order and anchors |
| Payslip geometry | Tests cover verbatim long labels, widest money, right alignment/atomicity, measured rows, repeated headers, reconciliation, light/dark geometry, Unicode fallback, and two-render determinism | Full-size pair review scores each visual dimension |
| Ticket clarity | Tests cover ordered four fields, one row, labels above values, atomic `GA`/`H`/`24`/`B`, no `24B` association, and identical light/dark geometry | Full-size pair review verifies gate-scan clarity and restraint |
| Review provenance | Existing bundle/reconciliation contracts validate SHA, pin, hashes, roles, counts, run/attempt, reviewer-owned fields, and canonical sequencing | Named per-cell scores/rationale/provenance; actual misses retained |
| Truthful claims | Contract tests preserve 32 cells, 20 explicit unscored records, dark `print_safety: false`, and distinction between phase threshold and manifest `passed` | Reviewer does not certify WCAG, PDF/UA, print safety, or universal quality |

Performance contract: use the existing single render pipeline and `measure_rows/4`; do not introduce browser rendering, raster overlays, PDF post-processing, a second renderer, dependencies, or new public API. Render twice for determinism; only the remote pinned PDFium lane establishes review raster identity.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | not applicable — no shadcn, third-party registry, browser component, or new dependency is in phase scope |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-08-27

## Sources Applied

- Locked phase decisions: `136-CONTEXT.md` (D-01 through D-26).
- Technical seams and evidence architecture: `136-RESEARCH.md`, `dev/rendro/catalog.ex`, recipe modules, and Catalog Evidence runbook.
- Current visual evidence: six current target PNGs, reviewed at full native image size on 2026-08-27.
- Current system guidance: `brand/README.md`, `brand/tokens/tokens.json`, `brand/copy/VOICE.md`, and `brand/audit/AUDIT.md`; current `brand/` guidance takes precedence over older prompt-era references.
