# Rendro

## What This Is

Rendro is a pure-Elixir, Phoenix-first PDF and document generation library for teams that need deterministic, production-grade output without depending on a browser runtime in core. It focuses on predictable layout and pagination for real business artifacts like invoices, statements, certificates, and reporting documents. The primary users are Phoenix SaaS engineers, back-office/reporting engineers, and operators who need trustworthy behavior under production load.

## Core Value

Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## Current State

**Shipped milestone:** v2.5 1.0 Release Capstone — **SHIPPED 2026-06-05** (Phases 78–82, 16/16 requirements; milestone audit `passed`; **`rendro 1.0.0` live on hex.pm**). The formal two-tier SemVer commitment, enforced public API boundary, migration docs, hardened release gates, and the irreversible proof-gated publish are all done. The full phase-delivery narrative is archived in `milestones/v2.5-ROADMAP.md`. **Active milestone: v2.6 Public Launch & Adoption Bootstrap — convert Rendro's proof-backed depth into its first real adopters: fix claim accuracy (optional shaping NIF), ship the drawn-path primitive + table borders, build the deterministic raster lane, publish self-proving launch artifacts (visual gallery, self-rendered manual, benchmark page, Livebook), execute a coordinated ecosystem launch, and define a concrete demand gate for conditional v2.7 global text shaping.**

<details>
<summary>v2.5 phase delivery detail</summary>

**Phase 79 (Public API Contract Enforcement Lane) complete 2026-05-30** — the public API surface defined in Phase 78 is now mechanically gated: a new `test/docs_contract/public_api_contract_test.exs` (the 14th docs-contract lane, `async: false`) regenerates the manifest in-memory via the shared `Rendro.PublicApi`/`mix rendro.api.gen` codepath and byte-compares it to `priv/public_api.json` — a stray or hidden public function fails with an errors-as-product two-list drift diff that instructs `mix rendro.api.gen`. The same lane asserts the six known engine internals + five `redact_*` helpers stay `:hidden` (with a `Code.ensure_loaded?` guard so a *renamed/deleted* internal also fails, not just a re-exposed one), every manifested module carries exactly one tier tag (`:stable` xor `:adapter`), and every stable-tier function has an `@spec` via `Code.Typespec.fetch_specs/1`. The Strict-100% `@spec` backfill (D-04) turned out to be exactly two specs on `Rendro.Component` (`render_component/2`, `image/2`) — the other 26 stable modules were already fully specced or are pure-struct. The lane folds into the existing `test` required GitHub context (no new `required_contexts[]` entry, per D-07) via the guardrails lockstep triple (`scripts/verify_docs.exs` lane 11 + `test/guardrails/required_checks_contract_test.exs` `== 11` + `priv/guardrails/required_status_checks.json` notes). Verified 4/4 success criteria with live test runs; `mix ci` green (dialyzer 0 errors). Code review caught a false-pass blocker (CR-01: missing internal silently passed the hidden check) + 3 warnings — all fixed in `707bea2` and re-verified. Tracked in `79-REVIEW.md`. Next: Phase 80 (Stability Contract & Migration Docs / STAB-04).

**Phase 78 (Public API Surface Definition & Cleanup) complete 2026-05-30** — the public API surface is now intentional and machine-checkable: six accidentally-public engine internals (`PDF.CidFont`, `PDF.FontSubsetter`, `Text.Bidi`, `Text.Shaper`, `Audit`, `Format`) are `@moduledoc false`, the five `Sign`/`Protect` `redact_*` helpers are `@doc false`, and `Rendro.Metadata` is documented with a real `@moduledoc` + `@type t` (closing the invisible-type gap on `Rendro.metadata/1`). Every public module carries exactly one `@moduledoc tags: [:stable|:adapter]` annotation (27 stable, 18 adapter) rendered as a green/blue HexDocs badge, and a new `Rendro.PublicApi` introspection layer + `mix rendro.api.gen` task generate the canonical, byte-stable `priv/public_api.json` manifest (45 modules) validated against `priv/schemas/public_api.schema.json`. The five recipes now thread `sections/2` opts uniformly (Invoice/BrandedInvoice no longer silently drop `_opts`), additively and byte-identically. Verified 5/5 success criteria, 957 tests green (API-01, API-02, API-03, API-05). Code review surfaced 4 non-blocking warnings on the dev-only generator (gen task doesn't call `Validator.validate/1`; `jason` used transitively) — tracked in `78-REVIEW.md`. Next: Phase 79 (Public API Contract Enforcement Lane).

</details>

<details>
<summary>v2.4 phase delivery detail</summary> **Phase 76 (Reference Phoenix app, CI, and documentation closure) complete 2026-05-29** — a Phoenix engineer can now run `examples/phoenix_example` locally (modernized to Phoenix ~>1.8 / plug ~>1.18 / jason ~>1.4 / elixir ~>1.19, the previously-missing `PhoenixExampleWeb.ErrorJSON` module added, README documenting setup + all five recipes), all five recipes (Invoice, BrandedInvoice, Statement, Receipt/Report, Certificate) are demonstrated through `Rendro.Adapters.Phoenix` (`render_pdf/3` attachment + `preview_pdf/2` inline) with 12 ConnCase/structural tests green, an isolated graph-disconnected (`needs: []`, no `continue-on-error`) advisory `example-phoenix` CI job runs `mix test` against the example without gating the four engine lanes (recorded in `priv/guardrails/required_status_checks.json` `advisory_contexts`; guardrail contract test refactored off its single-element advisory destructure and bumped to 10 docs-contract lanes), and two HexDocs guides (`guides/page_primitive.md`, `guides/recipes.md`) are wired into ExDoc under a "Recipes & Primitives" group with three new docs-contract tests bounding every claim to `priv/support_matrix.json` + on-disk proof evidence (REF-01..03, CONTRACT-02). Verified 18/18 must-haves. Code review caught and fixed a doc-correctness blocker (the page-primitive guide had shown non-functional `{page}`/`{total}` tokens in an unevaluated schematic fence; corrected to the engine's real `{{page_number}}`/`{{total_pages}}`). Previously: **Phase 75 (Receipt/Report and Certificate recipes + support contract) complete 2026-05-29** — two new data-driven recipes ship on the three-rung escape hatch: `Rendro.Recipes.Receipt` (one module scaling 1→N pages — a long multi-page tabular "report" is just a receipt that overflows, with repeating table headers and "Page X of Y" footers; RCPT-01..03) and `Rendro.Recipes.Certificate` (landscape-default, ALL element coordinates derived from template geometry with zero hardcoded A4 numerics, renders at A4 and US Letter via a multi-size test, optional branding mirroring `BrandedInvoice`; CERT-01..03). Statement's pagination/formatting machinery was extracted into a private shared `Rendro.Recipes.Pagination` helper (generalizing the per-row `balance` to opaque `meta`) plus a pure `Rendro.PageSize` resolver, with Statement refactored onto it and its 51-test determinism gate preserved verbatim (D-04). The support contract closed via four terminal non-viewer-sensitive `priv/support_matrix.json` rows (`page_numbering`, `statement` backfill, `receipt_report`, `certificate`) — flat objects with `supported` status + resolvable test-evidence pointers and no `viewers` sub-key, passing the existing schema validator + 21 docs-contract tests unchanged (CONTRACT-01). Verified 5/5 success criteria, 882 tests green. Code review flagged 6 non-blocking errors-as-product robustness gaps (WR-01..06: the new recipes validate key presence but not type/shape for some optional fields, leaking `BadMapError`/`FunctionClauseError` instead of instructive `ArgumentError`) — tracked in `75-REVIEW.md`, fixable via `/gsd-code-review 75 --fix`. Previously: **Phase 74 (Statement recipe) complete 2026-05-29** — `Rendro.Recipes.Statement` is the first end-to-end consumer of the PAGE primitive: a caller with account-transaction data generates a multi-page billing statement with correct "Page X of Y" footers and carried-forward / brought-forward balances, all through the three-rung escape hatch (`document/2` → `page_template/1` → `sections/2`) consistent with `Invoice`. Engine enablers landed first (`Rendro.measure_rows/4` for recipe-owned chunking by the engine's own row heights; the pure locale-free `Rendro.Format` module), the running-balance fold is exact signed Decimal, and `validate_data!/1` is errors-as-product including a `Decimal.equal?/2` assertion on caller-supplied closing balances (STMT-01..04). Verified passed after closing two code-review gaps (CR-01 descending-range guard in `measure_rows`; WR-01 top-level closing-balance validation). Previously: **Phase 73 (Page-Numbering / Running-Region Primitive) complete 2026-05-29** — the `fn {page, total}` running header/footer primitive + `page_number/1` helper + `suppress_on` selector with single-pass deterministic substitution. Next: Phase 76 (Reference Phoenix app, CI, and documentation closure).

</details>

**Shipped Version:** v2.5 1.0 Release Capstone (2026-06-05)

Rendro `1.0.0` is published on hex.pm — a permanent, proof-backed first 1.x release consolidating all unreleased v2.3 + v2.4 work since `0.3.0`. The public API surface is intentional and machine-checkable (tiered `priv/public_api.json` manifest, 27 stable + 18 adapter modules, accidentally-public internals hidden, docs-contract enforcement lane failing CI on drift), the two-tier SemVer stability contract is formal (`guides/api_stability.md` rewritten, `guides/upgrading_to_1.0.md`, Tier-1-symbols-exist claims test), and release machinery is hardened (exact-allowlist tarball content audit, `hex.audit`/`deps.audit`, SHA-pinned release workflow). All 16 requirements satisfied; milestone audit `passed`. Archived in `milestones/v2.5-ROADMAP.md` / `milestones/v2.5-REQUIREMENTS.md` / `milestones/v2.5-MILESTONE-AUDIT.md`.

**Previous Shipped Version:** v2.4 Batteries-Included Workflow & Adoption Closure (2026-05-30)

Rendro now ships batteries-included Phoenix document workflows: a deterministic page-numbering / running-region primitive (single-pass "Page X of Y", region content as a named helper or raw `fn {page, total}`, `body_capacity` overlap fix), three data-driven recipes — Statement, Receipt/Report, and Certificate — on the three-rung escape hatch alongside Invoice/BrandedInvoice, an executable reference Phoenix app (`examples/phoenix_example`) exercised in an isolated non-required CI lane, and HexDocs guides with docs-contract enforcement. All five new surfaces carry terminal `priv/support_matrix.json` rows. All 19 v1 requirements satisfied; milestone audit `passed` (5/5 phases, 6/6 E2E flows, integration PASS, all phases `nyquist_compliant: true`). Archived in `milestones/v2.4-ROADMAP.md` / `milestones/v2.4-REQUIREMENTS.md` / `milestones/v2.4-MILESTONE-AUDIT.md`.

**Previous Shipped Version:** v2.3 Viewer Proof & Interop Closure (2026-05-29, tag v0.3.1)

All 26 (surface × viewer) cells across forms, protection, signature widgets, signing preparation, signed artifacts, and long-lived signed artifacts are now terminal — 17 `supported` (each with a resolvable `evidence:` pointer into `priv/viewer_evidence/`), 9 `explicit_deferral` (each with a named viewer-behavior reason), 0 silently `unverified`. v2.3 added the `explicit_deferral` matrix vocabulary, additive `evidence:`/`recorded_at:`/`viewer_kind:` fields enforced by an in-tree JSON-Schema validator, the `mix rendro.viewer_evidence` operator task, the 8th docs-contract lane wired into the required `test` job, and the durable `guides/viewer_evidence.md` operator recipe. The engine-level trust spine (`signing-live-proof`, `long-lived-live-proof`, `release-proof`, `test`) was verified unchanged via a live branch-protection audit. Archived in `milestones/v2.3-ROADMAP.md` / `milestones/v2.3-REQUIREMENTS.md` / `milestones/v2.3-MILESTONE-AUDIT.md`.

**Previous Shipped Version:** v2.2 Long-Lived Signatures & Compliance Evidence (2026-05-08)

Rendro now supports one proof-backed long-lived-signature path over the shipped cryptographic-signing seam: `Rendro.Sign.augment/2` adds timestamp and revocation evidence over signed artifacts on a separate seam from `sign/2`, the first-party optional pyHanko long-lived adapter provides timestamp and revocation facts without claiming certificate-trust ownership, and `validate/2` reports cryptographic integrity, timestamp presence, revocation evidence presence, and narrow compliance posture as distinct signals. The `long-lived-live-proof` CI lane runs the full `sign → augment → validate` workflow against an offline certomancer-backed PKI/TSA/OCSP fixture and is required on `main`. `priv/support_matrix.json` and `guides/api_stability.md` publish `signing.long_lived` evidence separately from blanket PDF/A claims, signer trust, viewer behavior, and multi-signature workflows, with the `67-VERIFICATION.md` ledger backing the exact supported path.

**Previous Shipped Version:** v2.1 Cryptographic Signing & Signed-Artifact Proof (2026-05-07)

Rendro now supports one proof-backed cryptographic-signing path over the shipped unsigned/preparation seam: `Rendro.Sign.sign/2` signs rendered artifacts, first-party optional pyHanko and pdfsig adapters keep runtime-executable and integrity-vs-trust boundaries explicit, and the live proof lane is both executable and enforced on `main` through the required `signing-live-proof` status check. The public support contract now distinguishes signed-artifact integrity from certificate trust, viewer posture, and deferred compliance narratives, and the closeout trail includes Phase 60-63 verification artifacts for full audit-grade requirement closure.

**Previous Shipped Version:** v2.0 Signature Fields & External Signing Preparation (2026-05-07)

Rendro now supports explicit unsigned signature-field authoring through `Rendro.signature_field/2`, deterministic unsigned `/Sig` widget serialization on the existing AcroForm seam, and artifact-first external-signing preparation through `Rendro.Sign.prepare/2`. The public support contract now names unsigned widgets and signing preparation separately from unsupported digital-signature, viewer-validity, tamper-evidence, and compliance claims, and the closeout trail now includes backfilled Phase 55 and 56 verification artifacts so requirement closure is audit-grade rather than summary-only.

**Previous Shipped Version:** v1.10 Protected Delivery Hooks & Encryption Boundaries (2026-05-06)

Rendro now supports artifact-first password-to-open protection through `Rendro.Protect` and the first-party optional `qpdf` adapter, with AES-256-only public semantics, password-safe error/audit boundaries, password-aware Poppler structural validation, proof-backed Apple Preview support for the `protection` surface, and release-readiness gates that keep the canonical protected-delivery recipe truthful.

**Previous Shipped Version:** v1.9 Embedded Artifact Surfaces (2026-05-06)

Rendro supports document-level embedded files with explicit, deterministic metadata and curated link annotations limited to `http`/`https` URIs and in-document page targets. The writer emits deterministic `/EmbeddedFile`, `/Filespec`, `/Names`, and `/AF` catalog wiring and serializes `/Link` annotations through the existing page `/Annots` seam without named destinations or generic action dictionaries. Public claims are backed by structural proof through Poppler and recorded manual viewer evidence in Adobe Acrobat Reader and Apple Preview.

**Previous Shipped Version:** v1.8 Interactive PDF Forms (2026-05-05)

Rendro supports deterministic authored AcroForm text fields, checkboxes, and radio groups in the core pipeline with explicit appearance streams and proof-backed forms support boundaries.

**Previous Shipped Version:** v1.5 Validation and Trust Surfaces (2026-05-05)

Rendro provides validator-backed trust surfaces including the `Poppler` adapter for structural validation and a machine-readable support matrix for clear operational boundaries.

**Previous Shipped Version:** v1.4 Async Delivery and Artifact Operations (2026-05-05)

Rendro ships a queued render lifecycle, artifact metadata, persistence/sink contracts, and optional integrations (`Accrue`, `Mailglass`, `Oban.RenderWorker`) for production async/delivery workflows.

**Foundation Already Shipped:** v1.3 release readiness, v1.2 typography/assets truth, v1.1 layout-authoring maturity, and v1.0 deterministic core rendering.

## Current Milestone: v2.6 Public Launch & Adoption Bootstrap

**Goal:** Convert Rendro's proof-backed depth into its first real adopters — fix claim accuracy, polish visible output, build the deterministic raster toolchain, ship self-proving launch artifacts, and execute a coordinated ecosystem launch that makes the conditional text-shaping demand gate actually reachable.

**Target features:**
- **Claim-accuracy & shaping hygiene** — make `harfbuzz_ex` an optional dependency behind a `Rendro.Text.Shaper` behaviour (core ships a pure-Elixir `Shaper.Simple`; HarfBuzz adapter activates when present, with an instructive error for unsupported scripts — never silent broken output), fix the per-grapheme shaping bug in the line-breaking path, migrate off the dead `unicode_data 0.8.0` to the maintained `ex_unicode` stack, and record `explicit_deferral` support-matrix rows for complex scripts. The "pure Elixir core" claim becomes true again before any launch content ships.
- **Drawn-path primitive + visible polish** — declarative `%Rendro.Path{}` block element (move/line/curve/rect/rounded-rect, stroke/fill) on the existing writer seam; table rules/borders/header-band options; Certificate `border:` frame. Byte-determinism golden tests + support-matrix rows.
- **Deterministic raster lane** — extend `Rendro.Adapters.Pdfium` with `render/2` (pinned pdfium-cli), a golden-PNG snapshot harness in `mix test` (hash-equality fast path, containerized bless), an advisory CI lane, and an honest `viewer_kind: "pdfium-render"` evidence vocabulary distinct from GUI observation.
- **Self-proving launch artifacts** — visual recipe gallery (all five recipes rasterized into README + HexDocs, hash-checked in CI), a Prawn-style `manual.pdf` generated by Rendro itself with its SHA-256 published, a reproducible "PDFs in Elixir without Chrome" benchmark/comparison page vs ChromicPDF/pdf_generator/Typst-CLI, and a CI-executed Livebook tutorial with "Run in Livebook" badges.
- **Launch execution + demand instrumentation** — ElixirForum #announcing thread, ElixirStatus post, awesome-elixir PR, genuine replies in the two existing demand threads, a mobile-viewer-evidence content beat (2–4 honest rows), and a concrete v2.7 text-shaping demand gate (signal thresholds + ADOPTION.md ledger + GitHub Discussions/issue templates).

**Why now:** Rendro has 1.0-grade depth but is invisible — ~856 lifetime hex downloads (essentially all self/CI), 0 GitHub stars, never announced anywhere — while two live ElixirForum threads ask for exactly this library and conclude it doesn't exist. The roadmap's own rule ("v2.7 text shaping only if adopter demand justifies it") cannot trigger at zero visibility; the in-niche cautionary tale is `mudbrick` (12 releases, no launch work, stalled at 2.8k downloads). Every successful comparable (Oban, ChromicPDF, Typst, pdf-lib, Prawn) started with a visibility act, and Rendro's proof culture (byte-reproducible manual, checked-in benchmarks, honest viewer matrix) is launch marketing no competitor can copy. One blocking truth issue: `harfbuzz_ex` is currently a *hard* NIF dependency, so the "pure Elixir / no external dependencies" positioning must be fixed before announcing. Research detail in `.planning/research/`.

## Strategic Arc

**Active strategic arc:** public 1.0 commitment → public launch & adoption bootstrap → demand-gated capability growth

**Planned sequence after v2.5:**
- v2.6 Public Launch & Adoption Bootstrap — claim-accuracy hygiene, path primitive + borders, deterministic raster lane, self-proving launch artifacts, coordinated ecosystem launch, concrete demand instrumentation
- v2.7 Global Text Shaping & Script Support (conditional — pursue only when the v2.6-defined demand gate triggers; the gate is now measurable instead of an open circuit)

## Requirements

### Validated

- ✓ Rendro v2.5 shipped the public 1.0 commitment: a formal two-tier SemVer/API-stability contract (Tier-1 Stable strict SemVer, Tier-2 Evolving adapters/diagnostics), a mechanically enforced public API boundary (`priv/public_api.json` manifest + `public_api_contract_test.exs` docs-contract lane, API-01..05), rewritten stability/migration docs (`api_stability.md`, `upgrading_to_1.0.md`, Tier-1 claims test, STAB-01..05), hardened release gates (exact-allowlist tarball audit, `hex.audit`/`deps.audit`, SHA-pinned workflow), and the irreversible consolidated `1.0.0` publish to hex.pm (REL-01..06). All 16 requirements satisfied; milestone audit `passed`. Shipped 2026-06-05 and archived in `milestones/v2.5-ROADMAP.md` / `milestones/v2.5-REQUIREMENTS.md` / `milestones/v2.5-MILESTONE-AUDIT.md`. — v2.5
- ✓ Rendro v2.4 closed the adoption gap with batteries-included Phoenix document workflows — a deterministic page-numbering / running-region primitive (PAGE-01..04), three data-driven recipes on the three-rung escape hatch (Statement STMT-01..04, Receipt/Report RCPT-01..03, Certificate CERT-01..03), terminal support-matrix rows for every new surface (CONTRACT-01), an executable reference Phoenix app in an isolated non-required CI lane (REF-01..03), and HexDocs guides bounded by docs-contract tests (CONTRACT-02). All 19 v1 requirements satisfied; milestone audit `passed`. Shipped 2026-05-30 and archived in `milestones/v2.4-ROADMAP.md` / `milestones/v2.4-REQUIREMENTS.md` / `milestones/v2.4-MILESTONE-AUDIT.md`. — v2.4
- [x] Rendro v2.3 closed the trust-sensitive viewer evidence gap surface-by-surface: all 26 (surface × viewer) cells are terminal — 17 `supported` with resolvable `evidence:` pointers into `priv/viewer_evidence/`, 9 `explicit_deferral` with named viewer-behavior reasons, 0 silently `unverified`. Added the `explicit_deferral` matrix vocabulary plus additive `evidence:`/`recorded_at:`/`viewer_kind:` fields enforced by an in-tree JSON-Schema validator, the `mix rendro.viewer_evidence` operator task, the 8th docs-contract lane (wired into the required `test` job), and the durable `guides/viewer_evidence.md` operator recipe. The engine-level required CI lanes were verified unchanged via a live branch-protection audit. Shipped 2026-05-29 at tag `v0.3.1` and archived in `milestones/v2.3-ROADMAP.md` / `milestones/v2.3-REQUIREMENTS.md` / `milestones/v2.3-MILESTONE-AUDIT.md`.
- [x] Rendro v2.2 delivered one proof-backed long-lived-signature path over the shipped cryptographic-signing seam: `Rendro.Sign.augment/2` for timestamp and revocation evidence, the first-party optional pyHanko long-lived adapter, validator-backed posture classification with distinct integrity/timestamp/revocation/compliance signals, the offline certomancer-backed `long-lived-live-proof` CI lane (now required on `main`), and a truthful `signing.long_lived` support contract that stays separate from blanket PDF/A claims, signer trust, viewer behavior, and multi-signature workflows. Shipped on 2026-05-08 and archived in `milestones/v2.2-ROADMAP.md` / `milestones/v2.2-REQUIREMENTS.md`.
- [x] Rendro v2.0 delivered unsigned signature-field authoring, deterministic unsigned signature-widget serialization, artifact-first external-signing preparation, truthful signature support language, and backfilled verification artifacts for full audit-grade requirement closure. Shipped on 2026-05-07 and archived in `milestones/v2.0-ROADMAP.md` / `milestones/v2.0-REQUIREMENTS.md`.
- [x] Rendro v1.10 delivered artifact-first password protection, a first-party optional `qpdf` adapter, password-aware structural validation, protected-artifact-safe delivery seams, proof-backed protection support language, and release-ready protection proof. Shipped at exact tag `v0.2.0`.
- [x] Rendro v1.9 delivered deterministic authored document-level embedded files and curated link annotations (`http`/`https` URIs and in-document page targets only), with one proof-backed support contract published across `priv/support_matrix.json` and `guides/api_stability.md`, structural proof through the Poppler lane, and recorded manual viewer evidence in Adobe Acrobat Reader (both surfaces) and Apple Preview (links). Validated at milestone close in `v1.9-MILESTONE-AUDIT.md`.
- [x] Rendro v1.8 delivered deterministic authored interactive PDF forms for text fields, checkboxes, and radio groups, along with truthful forms support boundaries. Validated at milestone close in `v1.8-MILESTONE-AUDIT.md`.
- [x] Rendro v1.5 delivered validator-backed trust surfaces, structural validation, and a machine-readable support matrix. Validated at milestone close in `v1.5-MILESTONE-AUDIT.md`.
- [x] Rendro v1.4 delivered Async Delivery and Artifact Operations, including a queued render lifecycle, artifact metadata, and persistence/sink contracts. Validated at milestone close in `v1.4-MILESTONE-AUDIT.md`.
- [x] Rendro v1.2 delivered deterministic typography, assets, and honest Unicode boundaries. Validated at milestone close in `v1.2-REQUIREMENTS.md`.
- [x] Rendro v1.3 delivered first public hex release readiness. Validated at milestone close in `v1.3-REQUIREMENTS.md`.
- [x] Merge-blocking verification is now truthful and executable: `mix ci` covers format, compile, tests, docs, and package build, and `mix verify` separates deterministic vs advisory lanes without early exit. Validated in Phase 12: Verification Chain Closure (`QUAL-01`, `QUAL-03`, `QUAL-05`).
- [x] Deterministic CI gate regression is fixed and traceability state perfectly mirrors the true gate status. Validated in Phase 17: Deterministic CI Gate Recovery Traceability Resync (`QUAL-01`).
- [x] Rendro v1.0 proved pure-core rendering, baseline layout primitives, optional adapters, and truthful operational verification as a shippable MVP. Validated at milestone close in `v1.0-REQUIREMENTS.md`.
- [x] Rendro v1.1 proved layout-authoring maturity with explicit templates/regions, deterministic wrapped text, keep/break pagination semantics, truthful fit validation, stronger table continuation, diagnostics proof, and canonical recipes. Validated at milestone close in `v1.1-REQUIREMENTS.md`.
- [x] Rendro v2.1 delivered one proof-backed cryptographic-signing path, first-party optional pyHanko/pdfsig adapters, enforced live proof, and a truthful signed-artifact support contract. Shipped on 2026-05-07 and archived in `milestones/v2.1-ROADMAP.md` / `milestones/v2.1-REQUIREMENTS.md`.

### Active

_Milestone **v2.6 Public Launch & Adoption Bootstrap** is active (concrete REQ-IDs in `REQUIREMENTS.md`, phases 83–88 in `ROADMAP.md`). Headline requirements:_

- [ ] **Claim-accuracy & shaping hygiene** — `harfbuzz_ex` optional behind a `Rendro.Text.Shaper` behaviour with pure-Elixir `Shaper.Simple` in core, per-grapheme shaping bug fixed, `unicode_data` → `ex_unicode` migration, `explicit_deferral` matrix rows for complex scripts (HYG-xx).
- [ ] **Drawn-path primitive + visible polish** — declarative `%Rendro.Path{}`, table rules/borders, Certificate border frame, determinism golden tests (PATH-xx).
- [ ] **Deterministic raster lane** — `Pdfium.render/2`, golden-PNG snapshot harness, advisory CI lane, honest `pdfium-render` evidence vocabulary (RAST-xx).
- [ ] **Self-proving launch artifacts** — CI-hash-checked visual recipe gallery, self-rendered `manual.pdf` with published SHA-256, reproducible benchmark/comparison page, CI-executed Livebook tutorial (GAL-xx, CMP-xx).
- [ ] **Launch execution + demand instrumentation** — coordinated ecosystem launch, mobile-viewer-evidence content beat, concrete v2.7 shaping demand gate + ADOPTION.md ledger (LNCH-xx).
- [ ] Hold **v2.7 Global Text Shaping & Script Support** as conditional — pursue only when the v2.6-defined demand gate triggers.
- [ ] Keep viewer claims narrower than blanket "works in every viewer" marketing, blanket compliance narratives, and signer identity trust unless a separate milestone proves them; every new surface inherits the v2.3 viewer-evidence recording discipline. Raster-renderer evidence must never be presented as GUI-viewer proof.

### Out of Scope

- HTML/CSS parity or browser-style layout behavior — Rendro remains a deterministic document engine, not a browser renderer.
- WYSIWYG builders, hosted template editing, or app-specific layout hacks in core — they widen surface area before the authoring contract is stable.
- In-core key custody, certificate-store management, HSM orchestration, or signer identity workflows — these belong to optional adapters or external infrastructure.
- Blanket compliance branding, generic “signed PDF works everywhere” positioning, or viewer promotion without recorded evidence — public claims must stay proof-backed and narrow.
- Remote asset fetching, broad complex-script support, and “supports every language” positioning — defer until the engine has proof surfaces and a dedicated milestone for those capabilities.

## Context

Rendro has now shipped four authored PDF surfaces inside one deterministic pipeline (static content v1.0-v1.2, interactive forms v1.8, document-level embedded files v1.9, curated link annotations v1.9) and one full trust-sensitive stack as artifact-first or optional-adapter seams: protection through `Rendro.Protect` (v1.10), unsigned signature preparation through `Rendro.Sign.prepare/2` (v2.0), cryptographic signing through `Rendro.Sign.sign/2` plus first-party optional runtime adapters (v2.1), and long-lived signature augmentation through `Rendro.Sign.augment/2` plus a dedicated long-lived-live-proof CI lane (v2.2). All of this lands without widening the core rendering contract or the deterministic `build → compose → measure → paginate → render → validate` pipeline.

As of v2.3 (2026-05-29), per-viewer behavior is no longer carried as blanket `unverified`: every (surface × viewer) cell across forms, protection, signature widgets, signing preparation, signed artifacts, and long-lived artifacts is terminal — recorded `supported` with checked-in evidence or `explicit_deferral` with a named viewer-behavior reason. Recorded engine truth and recorded operator-facing truth are now aligned end-to-end, enforced by the schema validator and the 8th docs-contract lane. The next trust-and-adoption gap is adoption itself: reducing time-to-production for common Phoenix workflows (v2.4), with global text shaping held as a conditional v2.5.

## Constraints

- **Tech stack**: Keep the core pure Elixir with no hard dependency on Phoenix, Oban, browser runtimes, Python packages, or external signing binaries — preserves deterministic deployment and product boundaries.
- **Architecture**: Extend the existing `build -> compose -> measure -> paginate -> render -> validate` pipeline instead of creating an alternate rendering path — one engine must continue to power both APIs.
- **Product scope**: Viewer claims must stay narrower than blanket "works everywhere" positioning, signer identity trust, or broad compliance narratives unless recorded per-viewer evidence and matching `priv/support_matrix.json` rows back the claim.
- **Determinism**: Unsigned render output remains deterministic; signed and long-lived artifacts are intentionally non-deterministic and must be labeled as such rather than hidden behind deterministic claims.
- **Operational safety**: Key paths, passphrases, raw tool stderr, revocation blobs, and signer-specific secrets must stay redacted in errors, metadata, and audit surfaces.
- **Documentation honesty**: Public APIs, guides, and examples must not imply viewer support, trust anchoring, or compliance coverage beyond what `priv/support_matrix.json` and proof lanes cover.
- **Verification**: Merge-blocking, docs-contract, structural-validation, and live-tool proof lanes must stay truthful as the signing surface expands.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Embedded files live on the document in a dedicated registry, not on `metadata.custom` or in writer-owned state | Preserves the registry-backed authored-input pattern and keeps serialization separate from authoring state | ✓ Shipped in v1.9 |
| Embedded-file metadata is validated in `Rendro.Pipeline.Validate` with tuple errors, not registration-time exceptions | Keeps malformed authored state in the standard validate-stage error envelope before writer work begins | ✓ Shipped in v1.9 |
| Embedded files extend the existing writer allocation/build funnel; no inline serializer or separate PDF surface | Preserves one deterministic object-planning seam in the core writer | ✓ Shipped in v1.9 |
| Attachment catalog wiring stays document-level only (`/Names`, `/EmbeddedFiles`, `/AF`); no page-level file-attachment annotations | Matches the phase threat model and prevents generic-annotation scope creep | ✓ Shipped in v1.9 |
| Curated links accept only explicit `uri:` (`http`/`https`) or `page:` targets; no named destinations, no `/GoToR`, no generic actions | Narrowest useful annotation surface that reuses the existing `/Annots` seam without opening a generic review/comment API | ✓ Shipped in v1.9 |
| Hold viewer claims at `unverified` until manual evidence is recorded; promote only proof-backed pairs at milestone close | Keeps the public support contract truthful and auditable; prevents portability overclaims | ✓ Shipped in v1.9 |
| Reuse one `Rendro.form_field/3` / `%Rendro.FormField{}` authored boundary for all currently supported interactive widgets | Keeps DSL surface area narrow and preserves one normalization path into the core engine | ✓ Shipped in v1.8 |
| Generate explicit form appearance streams instead of relying on `NeedAppearances` | Viewer-generated appearances would weaken determinism and create false portability claims | ✓ Shipped in v1.8 |
| Publish support boundaries as machine-readable product contract | Viewer and feature claims need one canonical truth source that docs and tests can enforce | ✓ Shipped in v1.5 and extended in v1.8/v1.9/v2.0/v2.1 |
| Preserve the core/adapter split even as operational features grow | Keeps Rendro deployable and testable without forcing downstream ecosystem choices | ✓ Reinforced across v1.4 through v2.1 |
| Treat verification artifacts as product behavior | Operators need clear proof of what the engine supports and what remains unverified | ✓ Reinforced across shipped milestones |
| `v2.1` proved one narrow cryptographic-signing path before any compliance or long-lived-signature stories | Protected the product contract from widening faster than the evidence lanes could support it | ✓ Shipped in v2.1 |
| `v2.2` added long-lived evidence before broader viewer or adoption expansion | Durable signature evidence was the highest-leverage prerequisite between “we can sign” and “users can trust the signed workflow long term” | ✓ Shipped in v2.2 |
| Long-lived augmentation lives on a separate `Rendro.Sign.augment/2` seam over signed artifacts, not as new options on `Rendro.Sign.sign/2` or new render-time semantics | Keeps signing, augmentation, and validation as three explicit boundaries instead of one widening API | ✓ Shipped in v2.2 |
| Persist long-lived posture under `metadata.long_lived` and adapter-shaped facts under `metadata.long_lived_adapter`, with explicit non-determinism on every augmented artifact | Keeps shared metadata posture-only, isolates tool-shaped data, and forces truthful determinism labeling | ✓ Shipped in v2.2 |
| Use an offline certomancer-backed PKI/TSA/OCSP fixture for the required `long-lived-live-proof` lane | Keeps the operationally enforced proof reproducible without depending on any public PKI/TSA/CRL endpoint | ✓ Shipped in v2.2 |
| Publish long-lived evidence as nested `signing.long_lived` rather than a new top-level family in `priv/support_matrix.json` | Reuses one signing taxonomy and prevents accidental coupling to broad compliance, viewer, or signer-identity rows | ✓ Shipped in v2.2 |
| `v2.3` should close per-viewer evidence before any batteries-included adoption push | Engine-level truth (structure, signing, long-lived) is now proof-backed; per-viewer truth is the next blocker before stronger adoption claims | ✓ Shipped in v2.3 |
| Add `explicit_deferral` as a third matrix row state (alongside `supported`/`unverified`) with a required named reason, rather than leaving non-promotable cells as silent `unverified` | Distinguishes a viewer that fundamentally does not implement a surface from an un-attempted cell; makes coverage honest and auditable | ✓ Shipped in v2.3 |
| Extend `priv/support_matrix.json` strictly additively (new `evidence:`/`recorded_at:`/`viewer_kind:` fields, new row state) and enforce shape with an in-tree JSON-Schema validator wired to the required `test` job | Lets v1.5–v2.2 readers keep passing while making recording-discipline failures fail CI before merge, not in review | ✓ Shipped in v2.3 |
| Record viewer evidence as text-only Markdown files under `priv/viewer_evidence/<surface>/<viewer>.md`, fixtures by repo-path or content hash, with a durable operator recipe in `guides/viewer_evidence.md` | Keeps evidence reproducible and PII/secret-free, and makes the discipline inheritable by future surfaces without re-deriving the recipe | ✓ Shipped in v2.3 |
| Record viewer gaps as `explicit_deferral` rather than widening engine code to please specific viewers | Per-viewer polyfills in the writer would corrupt determinism and manufacture false portability; the gap belongs in the matrix, not the engine | ✓ Shipped in v2.3 |
| `v2.4` batteries-included adoption closure is the next milestone; conditional `v2.5` global text shaping only if demand justifies the core investment | With engine-level and per-viewer truth both proof-backed, reducing time-to-production is the highest-leverage next step | ✓ Shipped in v2.4 |
| Ship page numbering as a foundational engine primitive (Phase 73) before any recipe depends on it, rather than letting each recipe hand-roll it | "Page X of Y" / running regions are table-stakes; building them once, deterministically and tested, keeps recipes thin and consistent | ✓ Shipped in v2.4 |
| Page-number substitution is single-pass and post-layout (curated running-region tokens only); the engine stays stateless — carried/brought-forward totals are computed in recipe `sections/2`, never via an engine-level running-total accumulator | Preserves byte-identical determinism; statefulness or arbitrary text substitution would widen surface and break the determinism guarantee | ✓ Shipped in v2.4 |
| New recipes (Statement, Receipt/Report, Certificate) reuse the proven three-rung escape hatch (`document/2` → `page_template/1` → `sections/2`) and a shared private `Rendro.Recipes.Pagination` / `Rendro.PageSize`, not bespoke per-recipe pipelines | Keeps the recipe surface narrow and consistent with Invoice/BrandedInvoice; callers override at any rung without touching the rungs above | ✓ Shipped in v2.4 |
| `Rendro.Format` is pure and locale-free by construction (no CLDR/gettext/ex_money); i18n is a caller-supplied `:formatters`/`:labels` override, never core | Keeps the core deterministic and dependency-free; globalization stays a conditional v2.5 concern behind real demand | ✓ Shipped in v2.4 |
| Certificate coordinates are derived from template geometry (page size is a parameter, default with a multi-size A4+Letter exit test), not hardcoded A4 numerics | Recipes must render correctly across page sizes; hardcoded geometry is a latent portability bug | ✓ Shipped in v2.4 |
| The reference Phoenix app's CI job is isolated and graph-disconnected (`needs: []`, advisory, recorded in `advisory_contexts`), never a required branch-protection check | A Phoenix-dependency failure must never block the four engine-critical lanes (`signing-live-proof`, `long-lived-live-proof`, `release-proof`, `test`) | ✓ Shipped in v2.4 |
| New recipe surfaces raise structured `ArgumentError` on malformed input rather than leaking `BadMapError`/`FunctionClauseError` (Phase 77 closure) | Errors-as-product: instructive failures at the recipe boundary are part of the adoption contract | ✓ Shipped in v2.4 |
| `v2.6` is a public-launch/adoption milestone, not a feature milestone | Rendro has 1.0-grade depth and zero visibility (0 stars, no announcement ever); the conditional-shaping demand gate cannot trigger without adopters; every successful comparable started with a visibility act | Locked 2026-06-10 |
| Fix the "pure Elixir core" claim before launch: `harfbuzz_ex` becomes optional behind a `Rendro.Text.Shaper` behaviour; unsupported scripts raise an instructive error, never silent broken output | A hard Rust-NIF dependency contradicts the flagship positioning; launching with an inaccurate claim would violate the proof-backed-claims culture at the worst moment (iText pdfCalligraph seam precedent) | v2.6 |
| Path primitive is declarative (`%Rendro.Path{}` authored element, ReportLab-shapes-style), never an imperative Prawn-style canvas | Matches Rendro's declarative authored-element architecture; ~20 deterministic PDF operators on an existing internal writer pattern | v2.6 |
| Raster evidence gets its own `viewer_kind` (`pdfium-render`) distinct from GUI observation; renderer version bumps are deliberate evidence re-recording events | A rasterizer is not Acrobat; automation must not silently upgrade structural-proxy claims into GUI-viewer proof | v2.6 |
| Defer full text shaping to conditional v2.7, release-please, multi-signature, charts, TOC, and duplex headers — each with a named reason | Shaping is multi-quarter (fpdf2 ~6 expert-months; iText sells it as a paid add-on); release-please adds a PAT credential to an irreversible pipeline for minutes/year saved; multi-sig is DocuSign-shaped; charts are a DX scope sink; TOC demand is book-shaped not invoice-shaped | v2.6 scoping |

## Archived Milestone Context

<details>
<summary>v2.2 milestone focus before ship</summary>

- Add one truthful long-lived-signature path over the shipped cryptographic-signing seam through `Rendro.Sign.augment/2`.
- Ship a first-party optional long-lived adapter and validator-backed posture classification without coupling certificate trust into the integrity story.
- Prove the supported `sign → augment → validate` path with an offline `long-lived-live-proof` CI lane and require it on `main`.
- Publish long-lived and narrow compliance posture as their own taxonomy, separate from blanket PDF/A claims, signer trust, viewer behavior, and multi-signature workflows.
- Defer broader viewer portability claims, multi-signature workflows, signer-identity orchestration, HSM/key custody in core, and generic regulatory packaging.

</details>

<details>
<summary>v2.1 milestone focus before ship</summary>

- Add one truthful cryptographic-signing path over the shipped unsigned/preparation seam.
- Ship first-party optional signing and signed-artifact validation adapters without widening render-core semantics.
- Prove the supported signed-artifact path in CI and align every public claim to that exact proof.
- Defer long-lived signatures, timestamps, revocation evidence, PAdES/LTV/TSA/OCSP/CRL, and blanket compliance narratives.

</details>

<details>
<summary>v2.0 milestone focus before ship</summary>

- Add unsigned signature-field authoring that fits the existing authored form model truthfully.
- Add deterministic unsigned signature-widget serialization and artifact-first external-signing preparation without changing `Rendro.render/2`.
- Publish support boundaries that distinguish field authoring and preparation from actual digital signatures, viewer validity, and compliance claims.
- Defer cryptographic signing, key custody, PAdES/LTV/TSA/OCSP/CRL, and broad compliance narratives.

</details>

## Evolution Path

- `v2.0` shipped signature preparation through narrow authored fields and external-signing seams, not broad cryptographic or compliance claims.
- `v2.1` added actual cryptographic signing and signed-artifact proof without collapsing integrity, trust, viewer posture, and compliance into one claim.
- `v2.2` shipped timestamp/revocation evidence and a narrow long-lived-signature posture over the proof-backed signing seam, with `long-lived-live-proof` enforced on `main` and `signing.long_lived` published as its own support taxonomy.
- `v2.3` shipped per-viewer evidence closure across all shipped surfaces — every cell terminal (`supported` with recorded proof or `explicit_deferral` with a named reason), enforced by a schema validator and docs-contract lane, with a durable operator recipe for future surfaces.
- `v2.4` shipped batteries-included adoption closure — the page-numbering primitive, three new data-driven recipes, the reference Phoenix app, and docs-contract-bounded guides.
- `v2.5` shipped the public 1.0 commitment — the enforced public API boundary, the two-tier SemVer stability contract, hardened release gates, and the irreversible `1.0.0` publish to hex.pm.
- `v2.6` is the active milestone: public launch & adoption bootstrap — truth-accurate claims, visible polish, deterministic raster proof tooling, self-proving launch artifacts, and a measurable demand gate for conditional v2.7 text shaping.
- The core deterministic pipeline and the optional-adapter boundary remain non-negotiable.

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check -> still the right priority?
3. Audit Out of Scope -> reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-10 — Started milestone v2.6 Public Launch & Adoption Bootstrap (deep-research-backed scoping; five parallel research agents). Next: define REQUIREMENTS.md, create roadmap (phases 83–88).*
