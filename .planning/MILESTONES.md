# Milestones

## v2.10 Realistic Business-Document Examples & Anatomy (Shipped: 2026-07-19)

**Phases completed:** 5 phases, 31 plans, 56 tasks

**Key accomplishments:**

- The realistic invoice fixture was moved verbatim from `bench/comparison/fixtures/invoice_data.json` into the shared `priv/examples/invoice/acme-phoenix-saas/invoice.json` library, with every consumer repointed and behavior-preservation proven two ways: a byte-identical sha256 blob diff and a fresh Rendro render matching the already-recorded benchmark PDF hash.
- Invoice fixture money normalized to Decimal-safe 2-decimal strings with an S4 brand/logo slot (byte-identical Rendro render), plus the first automated JSV schema-validation lane over priv/examples/.
- Authored `priv/examples/invoice/DOMAIN.md` (domain language, personas + JTBD, reading context, layout conventions) and a structural docs-contract test enforcing the four-heading shape for every domain family.
- 1. [Out of scope] Comparison claims lane fails on stale generated guide block
- Froze two sha256 goldens — pre-upgrade toy Invoice render and pre-`cell_align` table render — on pristine code, resolving RESEARCH OQ1 before any `lib/` edit lands in this phase.
- Flipped `Rendro.Format` from `@moduledoc false` to the public adapter/Evolving tier in one atomic commit — the milestone's single irreversible act (INV-04) — regenerating `priv/public_api.json` and fixing two independent hidden-module contract checks so the lane stays green.
- Added the only net-new engine primitive in Phase 115 — opt-in `cell_align: :right` on `Rendro.table/2` (column-level) or a direct `%Rendro.Cell{}` (per-cell) — resolving RESEARCH Open Question 2 in favor of applying the x-offset entirely in `paginate.ex`'s `stack_cells`, so `writer.ex` needed zero changes and every existing table stays byte-identical.
- Upgraded `Rendro.Recipes.Invoice` from a toy 3-field recipe to full optional anatomy (issuer/customer/due_date/terms/totals) with a Decimal money split routed through `Rendro.Format.money/1`, an errors-as-product `validate_data!/1` boundary, a `Decimal.equal?/2`-validated totals block kept with the last table rows via per-page capacity reservation, and a `palette(opts)` color seam — while the pre-upgrade toy call keeps rendering byte-identically to the frozen sha256 golden.
- Additive `label_resolver/2` merge-order generalization plus `validate_labels!/2`/`validate_formatters!/2` opts-shape guards in `Rendro.Recipes.Pagination`, landed via strict RED/GREEN TDD with zero edits to Statement's existing call sites or tests.
- `Rendro.Recipes.Payslip` shipped end-to-end on the 3-rung pattern: a geometry-derived 4-region template with a zero-height-backdrop net-pay anchor band, a D-12 combined 6-column earnings/deductions ledger that paginates natively, and a `Decimal.equal?/2`-asserted D-13 gross-to-net reconciliation kept with the last page — plus a reusable vendored-font unicode-fallback pattern so D-17's "never reject caller content" promise actually renders accented text instead of crashing.
- `Rendro.Recipes.Ticket.document/2` on the 3-rung pattern -- a geometry-derived fixed landscape band with a D-02 placement-grid anchor (single Rendro.table/2 row, 22pt values), a D-05/D-06/D-07/D-08/D-09 stub (bordered code box, always-on human-readable reference, optional caller-supplied PNG, dashed perforation), and D-10's genuinely-new caller-image pre-validation plumbing that guarantees `Rendro.AssetRegistry.InvalidAssetError` never leaks.
- Closed FAM-03's registration loop: added `Rendro.Recipes.Payslip`/`Rendro.Recipes.Ticket` to the hardcoded `@public_modules` allowlist, regenerated `priv/public_api.json` via `mix rendro.api.gen`, and added proof-backed `payslip`/`ticket` rows to `priv/support_matrix.json` with individually-asserted capability claims in `recipes_claims_test.exs` — Phase 116's two new recipes are now visible to every downstream consumer of the public manifest and support contract.
- `Rendro.Test.Golden` — the un-gated byte-SHA-256 assert/bless helper with a two-run determinism pre-check, missing-ref hard-flunk, and a MIX_GOLDEN_DUMP eyeball escape hatch, self-tested in isolation.
- Built `Rendro.Test.EdgeFixtures`, the single {family, dimension} -> recipe-shaped document dispatch table covering all 62 `:applies` cells across the six families plus the four EDGE-02 error fixtures — pure test-support composition of shipped recipes and public primitives, zero `lib/` edits.
- Automated fail-loud guard proving the Hex tarball excludes test-only priv/goldens/ and priv/raster_refs/ while still shipping lib/rendro — turning an implicit allowlist omission into an enforced tripwire.
- Authored `Rendro.EdgeMatrixTest` — the phase's central, machine-checked-honest @matrix mapping all 102 {family, dimension} pairs to `:applies` or an N/A reason string, with a D-02 coverage-honesty meta-test, two transcription tripwires, a public `stress_fixture_ids/0`, and 62 data-driven golden byte-identity tests blessed against committed hash-only refs — zero `lib/` edits.
- Extended the existing `test/rendro/adapters/pdfium_raster_snapshot_test.exs` in place with the six D-10 curated raster fixtures — three combined pagination+60plus+odd-even renders (Invoice/Statement/Payslip), a Certificate A4/Letter geometry pair, and an Invoice extreme-wrap — each building its PDF via `EdgeFixtures`, proving two-run determinism, and reusing the file's private `assert_or_bless/2` verbatim, with zero `lib/` and zero `ci.yml` edits.
- Recorded EDGE-03's rubric beauty-gate exemption as a single explicit, schema-enforced `stress_exemption` block (D-13/D-14) and added 4 D-15 fail-loud-in-both-directions contract guards proving the exemption is present, that no real demo entry can hijack the per-entry `stress_exempt` loophole, and that the 62-entry stress-fixture ID set (imported from 117-04 as the single source of truth) is provably disjoint from — and non-vacuous relative to — Phase 118's future `scores` entries. Zero `lib/` changes.
- Task 1 — Schema generalization (`priv/schemas/examples.schema.json`)
- Five co-located four-heading DOMAIN.md anatomy files (statement, receipt, certificate, payslip, ticket) plus a DomainMdContractTest strengthened from "at least one" to "one per demonstrated domain" derived from fixture dirs.
- Rendro.ExamplesData — a faithful, `@moduledoc false` per-family transform (`transform_{invoice,statement,receipt,certificate,payslip,ticket}/1` + a `transform/2` dispatcher) that turns string-keyed fixture JSON into the atom-keyed, Decimal/Date-typed maps each recipe's `document/2` consumes, preserving cents and unit-tested end-to-end through all six recipes.
- `Rendro.LaunchArtifacts` now sources all seven gallery tiles (invoice, branded_invoice, statement, receipt_report, certificate, payslip, ticket) from `priv/examples/
- D-14 accessibility-overclaim tripwire authored test-first, then the guides/Livebook/phoenix_example and support_matrix/README reconciled to demonstrate the realistic example library + new Payslip/Ticket families — every claim proof-backed, no accessibility overclaim, and no quality/rubric-pass claim (all six demos are honestly below the rubric gate per 118-06).
- Task 1 — Invoice overhaul.
- 1. [Rule 1 - Bug] Stale `@expected_gallery_dimensions["ticket"]` blocked `launch_artifacts.check`

---

## C1 CI/CD Performance & Reliability (Shipped: 2026-07-11)

**Delivered:** Non-version CI/CD infrastructure milestone that turned the pipeline into a split, cached, observable required gate with local reproduction commands and remote validation evidence. No Hex release or library version tag was cut.

**Phases completed:** 108-113 (18 plans, 13 tracked tasks)

**Key accomplishments:**

- Captured a measure-first baseline across `ci.yml`, `hexdocs.yml`, and `release.yml`, including critical path, cache absence, A-E check classification, and P0-P3 recommendations.
- Added precise deps, `_build`, and PLT caching with unified SHA-pinned `erlef/setup-beam` and cache-hit observability.
- Improved test trust by documenting non-async reasons, increasing safe concurrency, quarantining nondeterministic paths, and preserving slow/live proof layering.
- Reshaped CI around named fast-lane steps, advisory/proof lane boundaries, PR cancellation, and one stable `ci-success` required check.
- Hardened supply-chain and release posture with pinned actions, Dependabot, advisory security-audit lanes, and deterministic release proof behavior.
- Closed DX and validation with scoped `mix ci.fast` / `mix ci.proofs` / `mix ci.advisory` commands, README/CONTRIBUTING updates, three green remote `ci.yml` runs, and a passed C1 milestone audit.

**Stats:**

- 6 phases, 18 plans, 13 tracked tasks
- Local `mix ci.fast`: 1219 tests, 12 doctests, 4 properties, 0 failures
- Remote required gate sample: p50 783s, nearest-rank p95 1013s across runs `29133061301`, `29133777702`, and `29134266708`
- Cache evidence: deps exact hit 3/3, `_build` restored 3/3, PLT exact hit 3/3

**Audit status:** `passed` — 30/30 requirements satisfied; 6/6 phases verified; 18/18 plans complete; 6/6 integration flows passed.

**Archived:** `milestones/C1-ROADMAP.md`, `milestones/C1-REQUIREMENTS.md`, and `milestones/C1-MILESTONE-AUDIT.md`.

**Known advisory signal:** `security-audit` reports dependency advisories in the non-required advisory lane; the deterministic required gate remains `ci-success`.

**What's next:** Start the next milestone with `$gsd-new-milestone`.

---

## v2.9 TOC & Document Navigation (Shipped: 2026-06-14)

**Phases completed:** 4 phases, 9 plans, 7 tasks

**Key accomplishments:**

- Introduce the `{{anchor_page:id}}` substitution token and ensure the Measure pipeline reserves a fixed-width bounding box for it to prevent infinite layout oscillations when real page numbers are later injected.
- Implement pre-layout duplicate ID validation and block location primitives.
- Declarative Document Outlines added to blocks and harvested into a hierarchical tree in Document Metadata during pagination
- Serialize the extracted metadata outline tree into a doubly-linked PDF dictionary structure with UTF-16BE support
- Automate the visual/human verification of PDF outlines by introducing an end-to-end integration test that programmatically asserts the correctness of the generated PDF binary.

---

## v2.8 Done-Enough Stewardship & Adoption Signal Loop (Shipped: 2026-06-13)

**Delivered:** Reduced maintainer/adopter friction and kept Rendro's public posture truthful while demand accumulates — without widening product scope.

**Phases completed:** 93-96 (8 plans)

**Key accomplishments:**

- Closed the `Rendro.Recipes` facade DX gap with a 10-function facade and drift test preventing facade/recipe drift.
- Cleaned up docs/warning hygiene, resolving zero unexplained ExDoc warnings and augmenting the viewer-evidence staleness signal to be self-explaining.
- Brought header `only_on: :odd | :even` proof depth to footer parity with direct render-layer and paginate-layer E2E tests.
- Reconciled stale v2.7 validation history metadata, clearing false-pending markers to match the passed milestone audit.
- Established an explicit "done-enough" stewardship posture tied to a dated adoption-signal review in `ADOPTION.md` (HOLD verdict).

**Audit status:** `passed` — all 8 requirements satisfied.

**Archived:** `milestones/v2.8-ROADMAP.md`, `milestones/v2.8-REQUIREMENTS.md`, and `milestones/v2.8-MILESTONE-AUDIT.md`.

---
## v2.7 Page Context & Browser Proof Hardening (Shipped: 2026-06-13)

**Phases completed:** 4 phases, 6 plans, 15 tasks

**Key accomplishments:**

- Section-local page numbering for flow documents using internal page context and PAGE token substitution
- Physical odd/even running content with section-local PAGE tokens and compose-time option validation
- Pinned PDF.js advisory observations for representative Rendro PDFs, isolated from core runtime and required CI.
- v2.7 public claims now match shipped page-context, duplex, and PDF.js advisory behavior, with HexDocs/package and workflow guardrails backing the release posture.
- Public linked docs are now included in package/docs contexts, and CI/release workflows use read-only repository token permissions.
- Phase 92 final verification passed across focused docs-contracts, all docs-contract lanes, package/docs checks, and full `mix ci`.

**Audit status:** `passed` — all 12 requirements satisfied. Integration audit passed with one non-blocking tech-debt item for a future header-specific `only_on` E2E test.

**Archived:** `milestones/v2.7-ROADMAP.md`, `milestones/v2.7-REQUIREMENTS.md`, `milestones/v2.7-MILESTONE-AUDIT.md`, and `milestones/v2.7-phases/`.

---

## v2.6 Public Launch & Adoption Bootstrap (Shipped: 2026-06-13)

**Delivered:** Quiet public discoverability backed by truth-correct claims, deterministic visual proof, comparison/Livebook try paths, issue-only intake, and a measurable demand gate for conditional text shaping.

**Phases completed:** 83-88 (32 plans, 68 tasks)

**Key accomplishments:**

- Restored the "pure Elixir core" claim: HarfBuzz is optional behind `Rendro.Text.Shaper`, `Shaper.Simple` is the default, complex scripts fail instructively, `unicode_data` is gone, and Latin output remains deterministic.
- Added deterministic visible polish: declarative `%Rendro.Path{}`, table borders/rules/header bands, Certificate frame support, public API manifest rows, and explicit support-matrix deferrals for path transforms/clipping/gradients.
- Shipped the advisory raster lane: `Rendro.Adapters.Pdfium.render/2`, pinned pdfium-cli metadata, render-backed PNG snapshot hashes, and CI/guardrail checks that keep `pdfium-render` separate from GUI-viewer proof.
- Published self-proving launch artifacts: five rendered recipe gallery PNGs, `manual.pdf` generated by Rendro, manifest and README/HexDocs hash checks, package inclusion, and brand-consistent presentation.
- Added adoption proof paths: a benchmark-backed comparison guide vs ChromicPDF/pdf_generator/Typst-CLI and a CI-executed first-invoice Livebook tutorial, both kept advisory/non-required.
- Closed launch instrumentation truthfully: quiet public posture, issue-only GitHub intake, `ADOPTION.md` signal ledger with numeric v2.7 gate thresholds, and terminal mobile GUI `explicit_deferral` rows instead of unsupported support claims.

**Stats:**

- 228 files changed in the milestone range
- ~31,335 inserted / 388 deleted lines in the milestone range, plus binary gallery/manual/benchmark artifacts
- 6 phases, 32 plans, 68 tasks
- 2026-06-10 -> 2026-06-13

**Git range:** `51b9218 docs(83): create phase plan` -> `091cea1 docs(88): record quiet public posture`

**Audit status:** `passed` — all 21 requirements satisfied. Nyquist validation cleanup remains non-blocking historical debt for phases 83, 84, 86, and 88.

**Archived:** `milestones/v2.6-ROADMAP.md`, `milestones/v2.6-REQUIREMENTS.md`, `milestones/v2.6-MILESTONE-AUDIT.md`, and `milestones/v2.6-phases/`.

**What's next:** Start a fresh milestone with `$gsd-new-milestone`; v2.7 global text shaping remains conditional on the `ADOPTION.md` gate.

---

## v2.5 1.0 Release Capstone (Shipped: 2026-06-05)

**Phases completed:** 5 phases (78, 79, 80, 81, 82)

**Key accomplishments:**

- Formal SemVer/API-stability commitment established.
- First 1.x public hex release (`1.0.0`) shipped.
- Public API contract enforcement lanes implemented.
- Release machinery hardened with preflight checks and dependency audits.
- Irreversible proof-gated publish completed.

**Audit status:** `passed` — all 16 requirements satisfied.

---

## v2.4 Batteries-Included Workflow & Adoption Closure (Shipped: 2026-05-30)

**Phases completed:** 5 phases (73, 74, 75, 76, 77), 21 plans

**Delivered:** Closed the adoption gap — the common Phoenix document workflows are now batteries-included. A foundational page-numbering / running-region primitive plus three data-driven recipes (Statement, Receipt/Report, Certificate) on the proven three-rung escape hatch, an executable reference Phoenix app exercised in CI, and HexDocs guides — so teams reach production with documented recipes instead of hand-assembling primitives.

**Key accomplishments:**

- Shipped a first-class page-numbering / running-region primitive: single-pass deterministic "Page X of Y" (`{{page_number}}`/`{{total_pages}}`), region content as a named `page_number/1` helper or raw `fn {page, total} -> ... end` with `suppress_on`, plus the prerequisite `body_capacity` overlap fix so footers never collide with body content (PAGE-01..04).
- Shipped `Rendro.Recipes.Statement` — multi-page billing statements generated from data alone, with exact signed-`Decimal` carried-forward / brought-forward balances computed in `sections/2` and "Page X of Y" footers; landed engine enablers `Rendro.measure_rows/4` and the pure, locale-free `Rendro.Format` (STMT-01..04).
- Shipped `Rendro.Recipes.Receipt` (one module scaling 1→N pages with repeating table headers — a long report is just a receipt that overflows) and `Rendro.Recipes.Certificate` (landscape-default, all coordinates geometry-derived with zero hardcoded A4, renders at A4 + US Letter via a multi-size test, optional branding mirroring `BrandedInvoice`), on a shared `Rendro.Recipes.Pagination` + `Rendro.PageSize` extracted from Statement (RCPT-01..03, CERT-01..03).
- Closed the support contract: four terminal `priv/support_matrix.json` rows for every new surface (`page_numbering`, `statement`, `receipt_report`, `certificate`), passing the schema validator + docs-contract lanes — inheriting the v2.3 evidence discipline, never a silent `unverified` (CONTRACT-01).
- Upgraded `examples/phoenix_example` to executable adoption proof: mix-runnable on modern floors (Phoenix ~>1.8 / plug ~>1.18 / jason ~>1.4 / elixir ~>1.19), README'd, demonstrating all five recipes via `Rendro.Adapters.Phoenix`, with an isolated graph-disconnected advisory `example-phoenix` CI job that never gates the four engine-critical lanes; plus `guides/page_primitive.md` + `guides/recipes.md` wired into HexDocs with docs-contract tests bounding every claim to proof (REF-01..03, CONTRACT-02).
- Ran a closure phase (77) off the milestone audit: greened the clean-tree `mix ci` format gate, filled the Nyquist VALIDATION records for Phases 73/74/75, and hardened recipe input-validation to raise structured `ArgumentError` (not raw `BadMapError`/`FunctionClauseError`) on malformed input — ending at a clean committed tree with the 925-test suite green.

**Audit status:** `passed` — all 19 requirements satisfied, all 5 phases closed, integration PASS, 6/6 E2E flows complete (Statement/Receipt/Certificate/Invoice/BrandedInvoice render data → PDF end-to-end). All 5 phases `nyquist_compliant: true`. See `milestones/v2.4-MILESTONE-AUDIT.md`.

**Tech debt (non-critical, all severity `info`):** `Rendro.Recipes` facade is asymmetric (only `invoice/1`/`branded_invoice/1` delegates exist; statement/receipt/certificate are called fully-qualified — no flow broken); SUMMARY `requirements-completed:` frontmatter lists 10/19 REQ-IDs while VERIFICATION.md confirms all 19 (metadata drift only); minor recipe input-validation polish items (WR/IN series) recorded in `77-REVIEW.md`.

---

## v2.3 Viewer Proof & Interop Closure (Shipped: 2026-05-29)

**Phases completed:** 5 phases (68, 69, 70, 71, 72), 15 plans, 32 tasks

**Delivered:** Closed the trust-sensitive viewer evidence gap surface-by-surface — every (surface × viewer) cell now carries recorded per-viewer proof or a named explicit deferral, backed by a durable operator-grade recording recipe future surfaces inherit.

**Key accomplishments:**

- Added `explicit_deferral` as a third matrix row state plus additive `evidence:`/`recorded_at:`/`viewer_kind:` fields on `priv/support_matrix.json`, enforced by an in-tree JSON-Schema (Draft 2020-12) two-tier validator wired to the required `test` job — strictly additive, no existing field renamed or retyped.
- Shipped the `mix rendro.viewer_evidence` operator task (list/validate/missing subcommands, `--json` contract, D-22 exit codes) and the 8th docs-contract lane (`viewer_evidence_claims_test.exs`) rejecting unevidenced `supported` rows, unnamed deferrals, forbidden vocabulary, and orphan evidence files.
- Published the `guides/viewer_evidence.md` operator-grade recipe under the HexDocs Policies extras group and the canonical `priv/viewer_evidence/<surface>/<viewer>.md` template, smoke-tested end-to-end on forms × Apple Preview as the worked example.
- Drove all 26 (surface × viewer) cells to terminal state — **17 supported** (each with a resolvable `evidence:` pointer), **9 explicit_deferral** (each with a named reason), **0 silently unverified** — across forms, protection, signature widgets, signing preparation, signed artifacts, and long-lived signed artifacts.
- Verified the engine-level trust spine unchanged via a live branch-protection audit: all four required engine lanes (`signing-live-proof`, `long-lived-live-proof`, `release-proof`, `test`) remain required on `main`; the required-check list grew or stayed flat, never shrank, and no behavioral lane was diluted by viewer-evidence work (GUARDRAIL-02).
- Closed the ship gate at v0.3.1 — split the CHANGELOG into a frozen 0.3.0 and a new 0.3.1 section, bumped `@version`, locked Hex packaging honesty with a negative tarball test, and hardened `release.yml` with a preflight step (isolated-worktree preflight proof green at a synthetic exact tag).

**Audit status:** `passed` — all 19 requirements satisfied, all 5 phases closed, 24/24 cross-phase integration checks passed, 4/4 E2E flows complete, live branch-protection audit passed. See `milestones/v2.3-MILESTONE-AUDIT.md`.

**Tech debt (non-critical, largely intentional):** SURFACE_EQUIVALENCE-inherited secondary cells rely on operator discipline rather than independent proof-ID re-validation (optional hardening); Nyquist VALIDATION.md for phases 69–72 remain draft (lightweight backfill phases per D-21, no engine code changed); staleness gate advisory by default (D-17); Hex `files:` whitelist intentionally omits operator tooling assets (D-29, refuted by a negative hex.build test D-30).

---

## v2.2 Long-Lived Signatures & Compliance Evidence (Shipped: 2026-05-08)

**Phases completed:** 4 phases (64, 65, 66, 67)

**Key accomplishments:**

- Added `Rendro.Sign.augment/2` as the public seam for applying timestamp and revocation evidence over signed artifacts, enforcing explicit non-deterministic posture.
- Shipped a first-party optional long-lived adapter backed by pyHanko that provides timestamp and revocation facts while remaining separate from bare signing and certificate trust ownership.
- Shipped a validator-backed inspection path that reports cryptographic integrity, timestamp presence, revocation evidence presence, and narrow compliance posture as distinct signals.
- Established a dedicated `long-lived-live-proof` job on CI to verify the full `sign -> augment -> validate` workflow against known fixtures.
- Updated repository branch protection rules to explicitly require `long-lived-live-proof` as an operational support-contract gate.
- Published an updated `priv/support_matrix.json` and docs-contract testing lane that rigorously separates long-lived and narrow compliance capabilities from blanket PDF/A claims, generic enterprise narratives, and multi-signature workflows.

**Audit status:** `passed` — all 7 requirements satisfied, all 4 phases closed, cross-phase long-lived workflows verified, branch protection rule enforced. See `milestones/v2.2-MILESTONE-AUDIT.md`.

---

## v2.1 Cryptographic Signing & Signed-Artifact Proof (Shipped: 2026-05-07)

**Phases completed:** 4 phases (60, 61, 62, 63)

**Key accomplishments:**

- Added `Rendro.Sign.sign/2` as the explicit artifact-first cryptographic-signing seam over the shipped unsigned/preparation boundary.
- Added first-party optional `Rendro.Adapters.PyHanko` and `Rendro.Adapters.Pdfsig` adapters that keep runtime-executable, redaction, and integrity-vs-trust boundaries narrow.
- Added a dedicated live proof lane with checked-in non-secret signing fixtures and a `signing-live-proof` GitHub Actions job.
- Enforced `signing-live-proof` as a required status check on `main`, turning the supported signing path into an operational gate rather than advisory proof only.
- Published one exact signed-artifact support contract across `priv/support_matrix.json`, `guides/api_stability.md`, `guides/integrations.md`, docs-contract tests, and verification artifacts.
- Closed the milestone audit trail by adding Phase 60-62 verification artifacts and synchronizing all 9 milestone requirements to explicit proof-backed closure.

**Audit status:** `passed` — all 9 requirements satisfied, all 4 phases closed, cross-phase signing/validation/docs flows verified. See `milestones/v2.1-MILESTONE-AUDIT.md`.

---

## v2.0 Signature Fields & External Signing Preparation (Shipped: 2026-05-07)

**Phases completed:** 5 phases (55, 56, 57, 58, 59)

**Key accomplishments:**

- Added `Rendro.signature_field/2` as the explicit unsigned signature-field authoring seam while keeping authored state on the shared `%Rendro.FormField{}` path.
- Added validate-stage rejection for scope-breaking signature metadata so unsupported signing semantics fail before render with typed errors.
- Extended the writer to emit deterministic unsigned `/Sig` widgets and AcroForm structures without introducing signer-owned placeholders or policy dictionaries into ordinary render output.
- Added an artifact-first `Rendro.Sign.prepare/2` seam that operates on final artifact bytes, publishes only deterministic placeholder coordinates in shared metadata, and keeps adapter-specific handoff data isolated.
- Published a narrow signature support contract across `priv/support_matrix.json`, `guides/api_stability.md`, and docs-contract tests that separates unsigned widgets and signing preparation from digital-signature, viewer, and compliance claims.
- Backfilled Phase 55 and Phase 56 verification artifacts so all nine milestone requirements close with explicit proof instead of summary-only traceability.

**Audit status:** `passed` — all 9 requirements satisfied, all 5 milestone phases closed, cross-phase authoring/render/prepare/docs flows verified. See `milestones/v2.0-MILESTONE-AUDIT.md`.

---

## v1.10 Protected Delivery Hooks & Encryption Boundaries (Shipped: 2026-05-06)

**Phases completed:** 4 phases (51, 52, 53, 54)

**Key accomplishments:**

- Added an artifact-first `Rendro.Protect` boundary for password-to-open protection without widening the deterministic render pipeline.
- Shipped a first-party optional `qpdf` adapter with AES-256-only public semantics, curated advisory-permission mapping, and typed redacted failures.
- Extended the Poppler structural lane to validate protected PDFs with caller-supplied passwords and locked the real-tool path behind explicit proof.
- Preserved protected-artifact delivery/storage seams without persisting password material and published one canonical recipe: `render_to_artifact -> Protect.password -> store/deliver`.
- Published a dedicated `protection` support contract and promoted only the first proof-backed viewer pair: Apple Preview for the `protection` surface.
- Closed the release tail with changelog/readiness guidance, a preflight gate for the canonical recipe, and a passing isolated tagged proof lane.

**Close note:** release verification passed at exact tag `v0.2.0` via `mix ci`, `mix release.preflight`, and `scripts/release_preflight_proof.exs`.

---

## v1.9 Embedded Artifact Surfaces (Shipped: 2026-05-06)

**Phases completed:** 3 phases (48, 49, 50)

**Key accomplishments:**

- Added a deterministic authored boundary for document-level embedded files with explicit metadata and validate-stage rejection of ambiguous state.
- Extended the writer to emit deterministic `/EmbeddedFile`, `/Filespec`, `/Names`, and `/AF` catalog wiring sorted by stable authored keys.
- Added curated link annotations limited to `http`/`https` URIs and in-document page targets through the existing page `/Annots` seam — no named destinations, no `/GoToR`, no generic action dictionaries.
- Published the proof-backed support contract: family-first matrix entries for `embedded_files` and `links`, canonical guide wording that distinguishes PDF-internal embedded files from delivery attachments, and a new `Embedded artifact semantic-claims` docs-contract lane.
- Recorded manual viewer evidence in Adobe Acrobat Reader and Apple Preview; promoted only proof-backed pairs (Adobe: both surfaces; Preview: links supported, embedded files unverified per D-09).

**Audit status:** `tech_debt` — all 7 requirements satisfied; debt is documentation/tracking-artifact only (missing `49-VERIFICATION.md`, stale `wave_0_complete: false` flags, inconsistent SUMMARY frontmatter shape). See `milestones/v1.9-MILESTONE-AUDIT.md`.

---

## v1.8 Interactive PDF Forms (Shipped: 2026-05-05)

**Phases completed:** 3 phases (45, 46, 47)

**Key accomplishments:**

- Added deterministic AcroForm text-field authoring and serialization to the core pipeline.
- Extended the same authored boundary to checkbox and radio widgets with explicit validation and deterministic button appearances.
- Added form-specific support boundaries in `priv/support_matrix.json` and docs-contract coverage to keep public claims truthful.
- Proved representative forms output structurally through the Poppler lane and recorded Apple Preview viewer proof.

---

## v1.5 Validation and Trust Surfaces (Shipped: 2026-05-05)

**Phases completed:** 4 phases (41, 42, 43, 44)

**Key accomplishments:**

- Implemented `Rendro.Adapters.Poppler` to provide structural validation for generated PDFs via `pdfinfo`.
- Added a machine-readable `support_matrix.json` for clear operational boundaries.
- Introduced advanced layout controls for widow/orphan management.
- Extended layout capabilities with robust nested layout structures.

---

## v1.4 Async Delivery and Artifact Operations (Shipped: 2026-05-05)

**Phases completed:** 5 phases

**Key accomplishments:**

- Implemented table fragmentation DSL, grid projection, and cell fragmentation in the measure and paginate phases.
- Introduced `Rendro.Artifact` to encapsulate generated PDF binaries, deterministic hashes, and metadata.
- Added `Rendro.Storage` and `Rendro.Audit` behaviors for external persistence and logging.
- Implemented optional integrations (`Accrue`, `Mailglass`, `Oban.RenderWorker`) to power production async/delivery workflows.

---

## v1.3 First Public Hex Release Readiness (Shipped: 2026-05-03)

**Phases completed:** 3 phases

**Key accomplishments:**

- Added licensing, package metadata, API stability guidance, and release preflight proof lanes for the first public package boundary.

---
