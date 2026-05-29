# Milestones

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
