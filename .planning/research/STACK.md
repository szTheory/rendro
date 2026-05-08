# Project Research — Stack for v2.3 Viewer Proof & Interop Closure

**Domain:** Rendro v2.3 — operator-grade per-viewer evidence (manual + selectively automatable) for forms / protection / signature widgets / signing preparation / signed artifacts / long-lived signed artifacts across Acrobat (Reader/Pro), Apple Preview, PDFium (Chromium-family), and PDF.js (Mozilla)
**Date:** 2026-05-08
**Confidence:** HIGH for the tooling recommendations (official repos / live release pages verified). MEDIUM for the version pins (PDFium / pdfium-cli / pdf.js move weekly to monthly — pin to ranges, not exact builds, to avoid silently invalidating recorded proof). HIGH for the schema-shape recommendation (it derives from Rendro's own existing pattern, not an external best practice).

## Headline Recommendation

**Add nothing to the runtime hard-dependency surface. Add nothing to `mix.exs` runtime deps. Extend `priv/support_matrix.json` in-place with a small additive sub-schema, and ship one new in-tree directory `priv/viewer_evidence/<surface>/<viewer>.md` for the recorded checklists.**

For automatable viewers, add **two strictly optional** first-party adapters that follow the existing pyHanko / qpdf / Poppler pattern (PATH-discovered external binary, exit-status-only redaction, no Hex hard dep, separate optional CI lane):

1. `Rendro.Adapters.Pdfium` — wraps `pdfium-cli` (klippa-app) v0.10.x for headless PDFium rendering and form/info extraction
2. `Rendro.Adapters.PdfJs` — wraps `pdfjs-dist` 5.x via a pinned Node script for headless PDF.js rendering

Both adapters are **observers, not viewers** — they record what PDFium and PDF.js see in the artifact, not what a human end-user sees. Treat their output as **additional automatable evidence** that complements but does not replace the manual Acrobat / Preview checklists. Do not promote a viewer row from `unverified` to `supported` purely on automatable-adapter output for surfaces where the question is "does the human-facing UI behave correctly" (forms editing, password prompt, signature panel display) — those still require recorded manual evidence per the v1.8 / v1.9 / v1.10 promotion discipline.

Use **JSV ~> 0.18** as a build-time-only dev/test JSON Schema validator for `priv/support_matrix.json` and the new viewer-evidence schema. Do **not** add any JSON Schema validator as a runtime hard dep.

This keeps the v2.3 surface narrow, preserves the pure-core/optional-adapter discipline already shipped through v2.2, and avoids the trap of making per-viewer-version drift silently invalidate recorded proof.

## Recommended Stack Additions

### Core Technologies (no change)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir core (no new runtime deps) | (existing) | Authoring + emitting + recording | Preserves the pure-core/no-Phoenix/no-Python/no-browser-runtime promise that has held from v1.0 through v2.2. Adding any runtime dep for evidence recording would be product-shape regression. |
| `priv/support_matrix.json` (existing canonical contract) | (existing) | Single source of truth for support claims | Already extended cleanly across v1.5/v1.8/v1.9/v1.10/v2.0/v2.1/v2.2. v2.3 should grow it additively, not replace it. |
| `priv/viewer_evidence/<surface>/<viewer>.md` (new in-tree directory) | (new) | Recorded operator-grade checklists | Plain-Markdown checklists are the lightest-weight format that the existing v1.8 Phase 47 / v1.9 / v1.10 Phase 54 evidence flow already implicitly used; promoting that pattern into a stable on-disk layout is the cheapest possible scale-out. |

### Supporting Libraries (additive, optional, dev/test-scoped)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `jsv` (Hex) | `~> 0.18` (latest 0.18.3, 2026-04-21) | Build-time validation of `priv/support_matrix.json` and `priv/viewer_evidence/**/*.md` frontmatter against an authored JSON Schema | Dev/test-only (`only: [:dev, :test], runtime: false`). Powers a new `mix rendro.support_matrix.verify` task and a docs-contract guard so a malformed evidence row breaks CI rather than silently shipping. JSV is the only Elixir validator with full Draft 2020-12 support and compile-time pre-compilation, both of which matter for keeping CI cycle-time honest. |

**Why JSV over ex_json_schema:** ex_json_schema (latest 0.11.3, 2026-05-06) is mature and zero-dep, but only supports drafts 4/6/7 — no 2020-12. JSV (latest 0.18.3, 2026-04-21) is the only widely-used Elixir validator that covers Draft 2020-12 with `$dynamicRef`/`$dynamicAnchor` and offline file/directory schema resolution, which is what `priv/support_matrix.json` should target so its schema aligns with what every other modern operational manifest uses. If the project preferred to write the schema as Draft 7, ex_json_schema would also work and is acceptable; pick one and stick with it.

### Optional First-Party Adapters (new, additive, off by default)

| Adapter | External binary | Pinned version range | Purpose | When to Use |
|---------|-----------------|---------------------|---------|-------------|
| `Rendro.Adapters.Pdfium` | `pdfium-cli` (klippa-app) | `~> 0.10.0` (latest 0.10.3, 2026-04-14) — pin to **minor**, not patch | Headless PDFium rendering + `info` + `form` + `attachments` extraction; produces automatable per-render evidence (page dimensions, form-field detection, attachment presence) | Optional CI lane only. Discoverable by PATH lookup at runtime. Provides automatable evidence for `forms`, `embedded_files`, `links`, `protection` surfaces. Does **not** replace human-UI viewer checklists. |
| `Rendro.Adapters.PdfJs` | `pdfjs-dist` (Mozilla) | `~> 5.7` (latest 5.7.284, 2026-04-27) — pin to **minor**, not patch, via a checked-in `package-lock.json` next to a small `priv/viewer_proof/pdfjs/` Node script | Headless PDF.js render + form/annotation detection through the official `pdfjs-dist` API in Node | Optional CI lane only. PDF.js's known limitations (signature widgets unsupported, AcroForm support partial) are themselves the evidence — recording "PDF.js does/does not surface this widget" is exactly the per-viewer truth Rendro is trying to publish. |

**Why pdfium-cli (klippa-app) over the official `pdfium_test`:** the upstream `pdfium_test` is a research tool that requires building PDFium from source (Ninja + depot_tools) and produces only `.ppm`/`.png` rasters; it has no `info`, `form`, or `attachments` subcommand. `klippa-app/pdfium-cli` (Apache-2.0, last release 2026-04-14, MacOS/Linux/Windows native + WebAssembly binaries) wraps PDFium 1.19.x via a single self-contained Go binary and exposes the exact subcommands Rendro needs (`render`, `info`, `form`, `attachments`). It is the same shape as the existing qpdf and pdfsig adapter surfaces.

**Why `pdfjs-dist` over headless Chromium:** headless Chromium would smuggle a browser runtime into the test fixture, which is exactly what Rendro's "no browser hard dep in core" constraint forbids. `pdfjs-dist` is the official Mozilla pre-built tarball that runs in plain Node (no Chromium), already used by 2,991+ npm-registry projects, and produces the right kind of "what does PDF.js's annotation/form layer actually surface for this artifact" signal from a self-contained dev-only Node script.

**Why ranges, not exact pins:** PDFium ships weekly (`bblanchon/pdfium-binaries` had 5 releases in April 2026 alone), and `pdfjs-dist` shipped 5.7.284 on 2026-04-27. Hard-pinning either to a specific patch version means recorded viewer proof goes stale within weeks of being recorded. Pin to minor and treat patch drift as acceptable noise; record the exact resolved version inside each evidence-file frontmatter so the recorded artifact answers "what did we see, on which build" without coupling matrix promotion to viewer version drift.

### Development Tools (additive)

| Tool | Purpose | Notes |
|------|---------|-------|
| `mix rendro.support_matrix.verify` (new) | Validates `priv/support_matrix.json` against an authored JSON Schema and validates each `priv/viewer_evidence/<surface>/<viewer>.md` frontmatter | Wires JSV into an existing-style `mix verify` lane. Fails CI if a `status: supported` row has no `evidence:` pointer or if the pointer is missing/broken. |
| `mix rendro.viewer_proof.pdfium` (new, optional) | Drives the optional `Rendro.Adapters.Pdfium` adapter against a representative fixture set | Runs only when `pdfium-cli` is on PATH. Mirrors the existing `mix.test --include live_pdf_tools` opt-in shape. |
| `mix rendro.viewer_proof.pdfjs` (new, optional) | Drives the optional `Rendro.Adapters.PdfJs` adapter against the same fixture set via a pinned Node script | Same opt-in semantics. The Node script is checked into `priv/viewer_proof/pdfjs/` with its own `package-lock.json`. |

## Installation

No new runtime hex deps. Dev/test additions only:

```elixir
# mix.exs — defp deps()
defp deps do
  [
    # ... existing deps unchanged ...
    {:jsv, "~> 0.18", only: [:dev, :test], runtime: false}  # NEW: dev/test schema validator
  ]
end
```

Optional automatable-adapter binaries (operator-installed, never bundled, never required):

```bash
# Optional: PDFium CLI for the optional pdfium-evidence lane
# https://github.com/klippa-app/pdfium-cli/releases (v0.10.3 as of 2026-04-14)
brew install klippa-app/tap/pdfium-cli  # or download binary directly

# Optional: PDF.js evidence script
# (kept as a self-contained checked-in package-lock.json under priv/viewer_proof/pdfjs/)
cd priv/viewer_proof/pdfjs && npm ci
# pdfjs-dist 5.7.284 as of 2026-04-27
```

Manual viewers (Adobe Acrobat Reader/Pro, Apple Preview) are operator-installed and operator-driven. Rendro records the version+OS in the evidence-file frontmatter and **does not** attempt to script them.

## Answers to the Specific Stack Questions

### 1. Existing Elixir libraries vs in-tree schema validator

Use **JSV (~> 0.18) as a build-time-only validator**. The viewer-evidence checklist is a small, stable set of fields (5-15 evidence keys per surface, always boolean or single-string status). That is small enough that an in-tree handwritten Elixir validator would also work — but writing it in-tree gains nothing over JSV and forfeits the ability to publish the schema as a separately-readable JSON Schema document. JSV gives you:

- 100% Draft 2020-12 compliance (compile-time pre-compiled for ~zero runtime overhead)
- Offline file-resolution (no network at validation time, which matters for CI honesty)
- Dev/test-only scope (`runtime: false`), preserving the pure-core promise
- A schema document that is itself published and reviewable

Do **not** add it as a runtime dep. Do **not** add it to the runtime `application/0` deps. The validator runs only inside `mix rendro.support_matrix.verify`, which itself runs inside an existing `mix verify` lane.

### 2. PDFium and PDF.js automatability state

**PDFium: partially automatable.** Use it for additive automatable evidence, not as a substitute for human viewer evidence.

- The official `pdfium_test` is a build-from-source rasterizer only (no `info`, no `form`, no `attachments` subcommand). Not suitable.
- `klippa-app/pdfium-cli` (v0.10.3, 2026-04-14, Apache-2.0, prebuilt binaries for Linux/macOS/Windows) provides `render`, `info`, `form`, `attachments`, and 9 other subcommands as a single self-contained Go binary built on go-pdfium 1.19.1 and PDFium 1.19.x. This is the right adapter target.
- PDFium has a low-level signature C API (`fpdf_signature.h`) but **no CLI** for signature verification — `pdfium-cli` does not expose signature subcommands. For signed/long-lived artifacts, PDFium evidence is "did PDFium open and render the page without error" only; integrity validation continues to belong to `pdfsig` / pyHanko.
- Form and annotation rendering through PDFium has known initialization gotchas (`PdfDocument.init_forms()` must be called before render, and signature widgets are partly skipped under default flags). Treat any "PDFium did not surface field X" as **observed evidence**, not as a failure of the artifact.

**PDF.js: partially automatable, with documented limitations that are themselves the evidence.**

- `pdfjs-dist` 5.7.284 (2026-04-27) runs in plain Node and exposes the full annotation/form layer through the same API the Firefox viewer uses. Suitable for an optional adapter that records "what does PDF.js's annotation extractor return for this artifact."
- PDF.js explicitly **does not** support signature widget rendering for empty signature fields (`mozilla/pdf.js#4202`), and AcroForm support is partial (text/checkbox/radio yes; complex behaviors no). For Rendro's signature_widget surface, PDF.js evidence will read "signature widget not surfaced by PDF.js as of v5.7.x" and that is the correct, recorded truth.
- Headless Chromium would also give automatable PDF.js evidence but introduces a browser runtime into the test fixture — off the table per the project constraint.

**Acrobat (Reader/Pro) and Apple Preview: must remain manual.** No upstream-supported automation exists for either, and the per-viewer behavior under test is human-UI behavior (does the password dialog appear, does the form field accept typing, does the signature panel display "signature is valid" UI). These continue to use the recorded-checklist pattern that v1.8 / v1.9 / v1.10 already proved.

### 3. Lightest-weight evidence-capture format for the manual viewers

**Markdown file with YAML frontmatter, one file per (surface, viewer), checked into `priv/viewer_evidence/<surface>/<viewer>.md`.**

Markdown checklists are the lightest format operators reliably use; the v1.8 Phase 47 Apple-Preview-forms record, the v1.9 Adobe-Acrobat-embedded-files record, and the v1.10 Phase 54 Apple-Preview-protection record have all already de-facto used this shape. Promote it from "implicit phase practice" to "explicit on-disk layout." Concrete shape:

```markdown
---
surface: forms                          # one of: forms, signature_widget, signing_preparation,
                                        #          signing, signing.long_lived, protection,
                                        #          embedded_files, links
viewer: adobe_acrobat_reader            # one of: adobe_acrobat_reader, adobe_acrobat_pro,
                                        #          apple_preview, chrome_pdfium, pdfjs
viewer_version: "2025.001.20438"        # human-readable, what the operator literally saw
viewer_kind: manual                     # manual | pdfium-cli | pdfjs-dist
os: "macOS 26.4.1"                      # what was running underneath
fixture: "test/fixtures/forms_v18.pdf"  # repo-relative
recorded_at: 2026-05-08
recorded_by: "operator-handle"
result: supported                       # supported | unverified | unsupported
---

## Evidence

- [x] open
- [x] default_state_visible
- [x] edit_or_toggle
- [x] save

## Notes

(Free-form notes, screenshots optional under priv/viewer_evidence/_assets/...)
```

JSON Schema for the frontmatter lives in `priv/schemas/viewer_evidence.schema.json` and is enforced at build-time by JSV. Markdown body checklist items are not schema-validated (free-form by design — operators add detail). The schema is a **frontmatter contract**, not a body contract.

**Rejected alternatives:**
- Pure JSON: harder for operators to skim; loses the "drop a screenshot or a paragraph of notes" affordance that real viewer-proof needs.
- Pure YAML: same skim problem; no good story for inline screenshots or human notes.
- One big YAML index of all viewers: every promotion forces a single-file edit and conflicts proliferate. One file per (surface, viewer) is the right granularity — same as `priv/support_matrix.json` rows.
- A custom Markdown-only DSL: forfeits machine validation and reintroduces the "implicit shape" problem v2.3 is trying to fix.

### 4. Versions / install paths for the optional automatable adapters

| Adapter | External binary | Pin | Source / install path | Resolved release referenced |
|---------|-----------------|-----|----------------------|------------------------------|
| `Rendro.Adapters.Pdfium` | `pdfium-cli` | `~> 0.10` (track minor) | Prebuilt binary download from `https://github.com/klippa-app/pdfium-cli/releases` (Linux/macOS/Windows). PATH-discovered at runtime by name `pdfium-cli`. | v0.10.3, 2026-04-14 (PDFium 1.19.1 / chromium/7825 family) |
| `Rendro.Adapters.PdfJs` | `pdfjs-dist` (Node) | `~> 5.7` in a checked-in `priv/viewer_proof/pdfjs/package.json` + `package-lock.json` | `npm ci` inside `priv/viewer_proof/pdfjs/`. Node-only; no Chromium. The script itself is invoked as `node priv/viewer_proof/pdfjs/extract.js <path>` and is PATH-discovered as `node`. | pdfjs-dist 5.7.284, 2026-04-27 |

Discipline (mirror of pyHanko / qpdf / Poppler):

- Strictly optional. No `mix.exs` runtime entry. No `application/0` registration.
- PATH-discovered at runtime; missing-binary errors are typed and redacted.
- Stderr never bubbled into return values or audit metadata; only exit-status and adapter-shaped facts.
- Each adapter has its own optional CI lane that is **not** required on `main` (mirrors how the existing structural-validation / signing-live-proof / long-lived-live-proof lanes were introduced before promotion to required).
- After Rendro v2.3 ships and the lanes are stable, only **then** consider promoting them to required — and even then, only the lanes themselves, not the version pins.

### 5. How `priv/support_matrix.json` should evolve

Extend the existing per-viewer row shape **additively**, in place. Do not introduce a sibling file. Do not nest evidence inside the row body in a way that couples it to viewer-version drift.

Current shape (already shipped):

```json
"viewers": {
  "apple_preview": {
    "status": "supported",
    "proof": ["opens_with_open_password", "displays_authored_content_correctly", "..."]
  },
  "adobe_acrobat_reader": { "status": "unverified" }
}
```

Proposed v2.3 additive extension:

```json
"viewers": {
  "apple_preview": {
    "status": "supported",
    "proof": ["opens_with_open_password", "displays_authored_content_correctly", "..."],
    "evidence": "priv/viewer_evidence/protection/apple_preview.md",
    "recorded_at": "2026-05-06",
    "viewer_kind": "manual"
  },
  "adobe_acrobat_reader": { "status": "unverified" }
}
```

Rules baked into the schema and enforced by `mix rendro.support_matrix.verify`:

1. **`status: supported` requires `evidence`, `recorded_at`, and `viewer_kind`.** No promotion without recorded proof.
2. **`status: unverified` forbids `evidence`, `recorded_at`, and `viewer_kind`.** Prevents stale or speculative evidence pointers.
3. **`evidence` is a repo-relative pointer to `priv/viewer_evidence/<surface>/<viewer>.md`.** The verifier asserts the file exists and that its frontmatter `surface` and `viewer` match the matrix row.
4. **`recorded_at` is the date the operator ran the checklist.** Plain ISO-8601 date. Not auto-updated. Not coupled to viewer-version drift.
5. **`viewer_version` is recorded in the evidence-file frontmatter, not in the matrix row.** The matrix names what behaves, the file records what was running underneath. A new viewer release does not silently invalidate the matrix; it just means the evidence file becomes a historical snapshot until a fresh checklist is run.
6. **`viewer_kind` enum:** `manual | pdfium-cli | pdfjs-dist`. Lets the docs-contract honestly distinguish a recorded-by-operator pass from an automatable-evidence pass when promotion happens.
7. **`unsupported` is reserved.** Use it only when a recorded checklist proves the viewer cannot handle the surface (e.g., "PDF.js does not surface signature widgets per `mozilla/pdf.js#4202`"). Do not collapse `unverified` into `unsupported`.

This shape preserves every existing matrix invariant, adds zero coupling to viewer version churn, and gives `guides/api_stability.md` a single sentence per row to mirror: "Adobe Acrobat Reader is `supported` for `forms` based on the recorded Phase X viewer checklist for version Y on OS Z (`priv/viewer_evidence/forms/adobe_acrobat_reader.md`)."

### 6. Prior-art viewer-conformance test harnesses to reuse

**Reusable, with caveats:**

| Source | Reuse for | Caveat |
|--------|-----------|--------|
| `pdf-association/pdf-corpora` (index of PDF-centric corpora) | Discovering additional fixtures for representative input PDFs that exercise rare-but-real features | This is an *index*, not a single corpus. Pull individual fixtures as Rendro needs; do not vendor the whole index. |
| `mozilla/pdf.js` test corpus (`/test/pdfs/`) | Cross-referencing what behavior PDF.js itself considers "expected" for a given input | Useful for sanity-checking the optional `Rendro.Adapters.PdfJs` adapter, not for generating Rendro's own evidence. |
| Upstream PDFium test PDFs (`testing/resources/` in the chromium/pdfium tree) | Same role as PDF.js corpus, for `Rendro.Adapters.Pdfium` | Same caveat: cross-reference, not redistribute. |

**Not reusable / explicitly do not adopt:**

| Source | Why not |
|--------|---------|
| veraPDF + veraPDF-corpus | veraPDF validates **PDF/A and PDF/UA conformance**. v2.3 is about **per-viewer behavior**, not archival/accessibility conformance. Pulling veraPDF in would conflate viewer evidence with compliance posture, which is exactly the conflation `signing.long_lived` and the entire support-matrix taxonomy was carefully designed to avoid. The Out of Scope row "blanket compliance branding" applies. Defer veraPDF to a separate future milestone if PDF/A is ever taken on. |
| Isartor Test Suite | Same reason — PDF/A-1 conformance, not viewer behavior. |
| Cal Poly PDF/VT Test Suite | PDF/VT is a print-production sub-spec; not in v2.3 scope. |
| Acrobat reference test suites | Adobe-internal, not openly redistributable. |

**Recommendation:** for v2.3, keep using Rendro's own representative fixtures (the existing `test/fixtures/` set already exercises forms, embedded files, links, protection, signing, long-lived). Borrow individual files from the `pdf-association/pdf-corpora` index *if* a specific viewer surface needs an edge-case input not already in-tree. Do not adopt veraPDF/Isartor — those are PDF/A conformance tools, and pulling them in would re-conflate compliance with viewer behavior in exactly the way `signing.long_lived` was carefully kept separate in v2.2.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Markdown + YAML-frontmatter evidence files | Pure-JSON evidence files | Never — operators do not reliably author by-hand JSON, and inline notes/screenshots become awkward. |
| JSV (Draft 2020-12) | ex_json_schema (Draft 7) | If the project actively prefers Draft 7 because the rest of its schemas already target Draft 7. ex_json_schema is mature, zero-dep, and well-supported (latest 0.11.3, 2026-05-06). Rendro currently has no other schemas, so the new-greenfield JSV recommendation stands. |
| `klippa-app/pdfium-cli` | Upstream `pdfium_test` | Only if Rendro ever needs raw PDFium internals not exposed by the CLI. For evidence recording, klippa is strictly better. |
| `pdfjs-dist` (Node-only) | Headless Chromium (Puppeteer/Playwright) | Never for the optional adapter — would import a full browser runtime. Only acceptable as a one-off operator local debugging tool, not a checked-in adapter. |
| Optional automatable adapter | Skip automatable evidence entirely; manual-only | If operator install of `pdfium-cli` and Node turns out to be a recurring blocker, fall back to manual-only for v2.3 and revisit automation in v2.4. The manual-only path is fully sufficient to ship v2.3 — automation is a force multiplier, not a prerequisite. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Adding `jsv` (or any JSON Schema validator) as a runtime hard dep | Breaks the pure-core promise. Validation runs at build/CI time, not at user runtime. | `{:jsv, "~> 0.18", only: [:dev, :test], runtime: false}` |
| Using headless Chromium / Puppeteer / Playwright as the PDF.js evidence harness | Smuggles a full browser runtime into the test fixture; explicitly excluded by the "no browser hard deps in core" constraint | `pdfjs-dist` 5.7.x in plain Node, kept under `priv/viewer_proof/pdfjs/` with its own pinned `package-lock.json` |
| Hard-pinning PDFium / pdf.js / pdfium-cli to exact patch versions | PDFium ships weekly, pdf.js ships every few weeks. Hard pins force constant matrix-row churn and silently invalidate recorded proof. | Pin to **minor** (`~> 0.10`, `~> 5.7`) and record exact resolved version inside each evidence-file frontmatter |
| Encoding `viewer_version` directly into `priv/support_matrix.json` rows | Couples the canonical contract to viewer release cadence. Every viewer minor release would force a matrix edit even though Rendro's behavior didn't change. | Record `viewer_version` only inside `priv/viewer_evidence/<surface>/<viewer>.md` frontmatter; matrix rows carry only `evidence` pointer + `recorded_at` date + `viewer_kind`. |
| Adopting veraPDF / Isartor / Cal Poly test suites for v2.3 | Conflates PDF/A and PDF/UA conformance with viewer behavior — exactly the conflation the existing `signing.long_lived` taxonomy and "blanket compliance branding" Out of Scope explicitly forbid | Pull individual representative PDFs from `pdf-association/pdf-corpora` only if a specific edge case is needed. Stay surface-and-viewer scoped. |
| Auto-updating `recorded_at` on every CI run | "Recently checked" is meaningless if the check is automated; the date should reflect when a human or named automated lane actually ran the checklist | `recorded_at` is set when the operator commits the evidence file, never automatically. |
| Treating an automatable-adapter pass as sufficient for surfaces where the question is human-UI behavior (signature panel display, password dialog UX) | An "automatable evidence pass" answers a different question than "a human operator can drive this in the GUI" | Manual evidence required for human-UI surfaces; automatable evidence is **additive**, not substitutive. |
| Putting the optional adapter CI lanes on `main` as required from day one | The existing pattern (`structural-validation`, `signing-live-proof`, `long-lived-live-proof`) introduced the lane first, then promoted to required only after stability was proven | New `pdfium-evidence` and `pdfjs-evidence` lanes start as optional advisory checks; promote to required only after they pass cleanly for at least one milestone cycle. |

## Stack Patterns by Variant

**If only manual evidence ships in v2.3 (minimum viable scope):**
- Add `jsv ~> 0.18` to dev/test deps
- Add `priv/schemas/viewer_evidence.schema.json` and `priv/schemas/support_matrix.schema.json`
- Add `priv/viewer_evidence/<surface>/<viewer>.md` files for each manually proven (surface, viewer) cell
- Add `mix rendro.support_matrix.verify` to the existing `mix verify` lane
- Extend `priv/support_matrix.json` rows additively with `evidence`, `recorded_at`, `viewer_kind`
- This is sufficient to close v2.3 honestly. The two optional adapters can land in v2.4 or later.

**If automatable evidence also ships in v2.3 (recommended scope):**
- All of the above, plus
- `Rendro.Adapters.Pdfium` wrapping `pdfium-cli ~> 0.10`
- `Rendro.Adapters.PdfJs` wrapping `pdfjs-dist ~> 5.7` via a pinned Node script under `priv/viewer_proof/pdfjs/`
- Two new optional CI lanes: `pdfium-evidence` and `pdfjs-evidence`. Neither required on `main` for v2.3 ship.
- Each automatable run produces a `priv/viewer_evidence/<surface>/{chrome_pdfium,pdfjs}.md` file with `viewer_kind: pdfium-cli` or `viewer_kind: pdfjs-dist`, recording the resolved binary version.

**If the project decides to defer all of viewer evidence beyond a manual-recipe-only milestone:**
- Add only `jsv ~> 0.18`, the schemas, the new docs section in `guides/api_stability.md` defining the recipe, and one canonical worked example (e.g., Adobe-Acrobat × forms).
- This is the smallest possible v2.3 ship, and it is still a meaningful product win because it converts the implicit Phase 47 / Phase 54 / v1.9 evidence pattern into an explicit, repeatable recipe.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| `jsv ~> 0.18` | Elixir 1.15+ | Compile-time pre-compilation needs OTP 26+. Already comfortably inside Rendro's existing CI matrix. |
| `pdfium-cli ~> 0.10` | PDFium 1.18.x — 1.19.x (Chromium 7776 — 7825 family) | Pin to minor only; record exact resolved version per evidence run. |
| `pdfjs-dist ~> 5.7` | Node 18+ | Mozilla's published support matrix lists the legacy/ subdirectory as the fallback for older environments; do not target it — the test fixture should run on current Node LTS. |
| Existing `pyhanko`, `qpdf`, `pdfsig`, `pdfinfo` adapters | (unchanged) | v2.3 does not modify any existing adapter signature, behavior, or version pin. The new adapters live alongside, not in place of. |

## Integration Points

- **`mix.exs` deps:** Add `{:jsv, "~> 0.18", only: [:dev, :test], runtime: false}`. Nothing else.
- **`lib/rendro/adapters/`:** Add `pdfium.ex` and `pdf_js.ex` alongside the existing `poppler.ex`, `pdfsig.ex`, `py_hanko.ex`, `qpdf.ex`. Same shape: PATH lookup, exit-status redaction, typed error envelopes, no in-core dep on the binary.
- **`priv/`:** Add `schemas/support_matrix.schema.json`, `schemas/viewer_evidence.schema.json`, `viewer_evidence/<surface>/<viewer>.md` files, and (optional) `viewer_proof/pdfjs/{package.json,package-lock.json,extract.js}`.
- **`mix verify` aliases:** Add `mix rendro.support_matrix.verify` to the existing deterministic-lane `mix verify` flow. This is a fast, offline check; it stays on the always-required path. The two new optional automatable lanes (`pdfium-evidence`, `pdfjs-evidence`) start as advisory in `.github/workflows/ci.yml` mirroring how `signing-live-proof` and `long-lived-live-proof` were introduced.
- **`guides/api_stability.md`:** Mirror each promoted matrix row with one sentence in plain English, exactly as the v1.10 protection section already does for Apple Preview. Add a new top-level "Operator-Grade Viewer-Evidence Recipe" section describing the `priv/viewer_evidence/` layout, the schema, the promotion gate, and the `mix rendro.support_matrix.verify` enforcement.

## What Explicitly Does Not Need to Be Added

Calling these out so the v2.3 roadmap cannot accidentally widen:

- No new compliance validator (no veraPDF, no Isartor, no PDF/UA tooling) — viewer evidence is not compliance evidence.
- No new signer-trust tooling — certificate trust remains separate from viewer evidence.
- No multi-signature workflow tooling — explicitly out of scope per the v2.2 boundary.
- No Phoenix LiveDashboard / web UI for viewing evidence — Markdown files in-tree are the UI.
- No Hex package for the viewer-evidence schema — it ships in-tree at `priv/schemas/`.
- No automatable adapter for Acrobat or Apple Preview — they remain manual by upstream tooling reality.
- No auto-update path that bumps `viewer_version` on a fresh viewer release without re-running the checklist — that would silently invalidate recorded proof, which is exactly the failure mode v2.3 is trying to fix.

## Sources

- [klippa-app/pdfium-cli releases](https://github.com/klippa-app/pdfium-cli/releases) — verified v0.10.3, 2026-04-14, PDFium 1.19.1 (HIGH)
- [klippa-app/pdfium-cli README](https://github.com/klippa-app/pdfium-cli/blob/main/README.md) — confirmed `render`, `info`, `form`, `attachments` subcommands; no signature subcommand (HIGH)
- [bblanchon/pdfium-binaries releases](https://github.com/bblanchon/pdfium-binaries/releases) — verified PDFium 149.0.7825.0 / chromium/7825, 2026-05-04 (HIGH)
- [mozilla/pdf.js releases](https://github.com/mozilla/pdf.js/releases) — verified pdfjs-dist 5.7.284, 2026-04-27 (HIGH)
- [mozilla/pdf.js#4202 — Unimplemented annotation type (Widget signature)](https://github.com/mozilla/pdf.js/issues/4202) — HIGH; documents that PDF.js does not display empty signature widgets, which is itself the recorded evidence for the `signature_widget × pdfjs` cell
- [mozilla/pdf.js#7613 — Interactive form (AcroForm) support](https://github.com/mozilla/pdf.js/issues/7613) — HIGH; documents partial AcroForm support
- [PDFium fpdf_signature.h](https://pdfium.googlesource.com/pdfium/+/refs/heads/master/public/fpdf_signature.h) — HIGH; confirms PDFium signature API is C-only with no upstream CLI
- [JSV on hex.pm](https://hex.pm/packages/jsv) — verified 0.18.3, 2026-04-21 (HIGH)
- [JSV GitHub](https://github.com/lud/jsv) — verified Draft 2020-12 + Draft 7, compile-time pre-compilation, offline file resolver (HIGH)
- [ex_json_schema on hex.pm](https://hex.pm/packages/ex_json_schema) — verified 0.11.3, 2026-05-06; Draft 4/6/7 only, no 2020-12 (HIGH; reason for not recommending)
- [pdfjs-dist on npm](https://www.npmjs.com/package/pdfjs-dist) — verified 5.7.284, 2026-04-27 (HIGH)
- [pdf-association/pdf-corpora](https://github.com/pdf-association/pdf-corpora) — confirmed as index, not corpus (HIGH)
- [veraPDF Test Suite](https://pdfa.org/resource/verapdf-test-suite/) and [veraPDF/veraPDF-corpus](https://github.com/veraPDF/veraPDF-corpus) — HIGH; confirmed scope is PDF/A and PDF/UA conformance, which is the reason for *not* adopting in v2.3
- Rendro repo internal: `priv/support_matrix.json`, `guides/api_stability.md`, `lib/rendro/adapters/`, `mix.exs`, `.github/workflows/ci.yml` — HIGH; observed existing optional-adapter shape (Poppler, pyHanko, pdfsig, qpdf), CI lane shape (`structural-validation`, `signing-live-proof`, `long-lived-live-proof`), and existing matrix row shape

---
*Stack research for: Rendro v2.3 Viewer Proof & Interop Closure*
*Researched: 2026-05-08*
