# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

#### LNCH-02: Zero-UAT mobile viewer evidence posture

- Added terminal `explicit_deferral` rows for iOS Files/Preview and Google Drive PDF viewer on Android across `forms` and `signed_artifact`. These rows intentionally publish no mobile GUI support claim until automated device-level CI evidence exists.
- Mirrored the mobile deferral reasons in `guides/api_stability.md`; signed-artifact deferrals distinguish Markup/drawn signatures from `/Sig` cryptographic validation.

### Fixed

#### HYG-03: Cluster-boundary split_graphemes rewrite (D-11, D-12, D-13)

- Rewrote `split_graphemes/4` in `lib/rendro/pipeline/measure.ex` to shape runs at
  cluster boundaries instead of calling `Shaper.shape/3` once per grapheme. The old
  per-grapheme shaping call is removed entirely.
- Under `Shaper.Simple` (cluster=0 for all glyphs), the new run-shaping path is
  byte-identical to the old per-grapheme path by construction — each glyph still maps
  1:1 to a grapheme and x_advance values are unchanged. **No golden regressions.**
- Under `Rendro.Adapters.HarfBuzz` (cluster=byte offset), ligature clusters are now
  treated as atomic units for line-breaking, which was objectively wrong before.
- StreamData property test added (`test/rendro/text/shaper_test.exs`) formally proving
  per-grapheme width sum == per-run width under `Shaper.Simple` for random ASCII strings (D-12).
- **Re-bless event (D-13): No golden files changed.** The Latin/Shaper.Simple path is
  byte-identical by construction (proven by property test). No HarfBuzz-path golden
  fixtures exist in the test suite, so no re-blessing was required.

## [1.0.0] - 2026-06-05

This release marks the `1.0.0` milestone, establishing the first formal SemVer commitment. It consolidates the v2.3 Viewer Evidence work, the v2.4 Batteries-Included workflow features, and the v2.5 API stability cleanup.

The published `0.3.0` surface lifted v1.5–v2.2 work. This 1.0.0 release closes out the remaining core milestones. Operator-only evidence artifacts (`priv/viewer_evidence/` and `priv/support_matrix.json`) intentionally remain out of the Hex package; the public contract is mirrored in `guides/api_stability.md`.

### Stability

For details on the two-tier stability contract, the byte-output carve-out, and the soft-deprecation policy, see the [Upgrading to 1.0 guide](guides/upgrading_to_1.0.md).

### Added

#### API Stability & Surface (v2.5)

- Formal two-tier SemVer contract (`stable` and `adapter`).
- `priv/public_api.json` manifest as the canonical source of truth for the public API surface.
- ExDoc stability badges for all public modules.
- Introspection-based docs-contract tests to mechanically pin the documented surface to the manifest.

#### Batteries-Included Workflow (v2.4)

- `Rendro.Page` primitive for explicit page-level content control.
- Five canonical, tested recipes: `Rendro.Recipes.Invoice`, `BrandedInvoice`, `Statement`, `Receipt`, and `Certificate`.
- Reference Phoenix application (`examples/phoenix_example`) demonstrating integration, async delivery, and testing.

#### Viewer Evidence (v2.3)

- `Rendro.Adapters.Pdfium` optional PATH-discovered adapter for pdfium-cli form/info observation used by the viewer-evidence live-proof lane.
- `mix rendro.viewer_evidence record forms chrome_pdfium` to autogenerate evidence files from pdfium-cli observations.
- Promoted `forms.viewers.chrome_pdfium` to `supported` with evidence at `priv/viewer_evidence/forms/chrome_pdfium.md` (`viewer_kind: pdfium-cli`).
- Promoted `forms.viewers.adobe_acrobat_reader` to `supported` with evidence at `priv/viewer_evidence/forms/adobe_acrobat_reader.md` (`viewer_kind: pdfium-cli`).
- Promoted `forms.signature_widget_viewers.adobe_acrobat_reader`, `apple_preview`, and `chrome_pdfium` to `supported` with evidence under `priv/viewer_evidence/signature_widget/`.
- Promoted `signing_preparation.viewers.adobe_acrobat_reader` to `supported` with evidence at `priv/viewer_evidence/signing_preparation/adobe_acrobat_reader.md`; non-Acrobat rows inherit signature-widget evidence pointers (D-15).
- Promoted `signing.viewers.adobe_acrobat_reader` and `chrome_pdfium` to `supported` with evidence under `priv/viewer_evidence/signed_artifact/`.
- Promoted `signing.long_lived.viewers.adobe_acrobat_reader` to `supported` with evidence at `priv/viewer_evidence/long_lived_signed_artifact/adobe_acrobat_reader.md`.
- Promoted `protection.viewers.adobe_acrobat_reader` to `supported` with evidence at `priv/viewer_evidence/protection/adobe_acrobat_reader.md`.
- Phase 71 structural-proxy proof modules: `FormsAcrobatProof`, `ProtectionAcrobatProof`, `SignatureWidgetAcrobatProof`, `SignatureWidgetApplePreviewProof`, `SigningPreparationPdfiumProof`, `SignedArtifactAcrobatProof`, `LongLivedAcrobatProof`.
- `viewer-evidence-live-proof` CI lane extended with pdfsig/pyhanko and Phase 71 live tests (`trust_sensitive_viewer_evidence_live_test.exs` and related adapters).
- `mix rendro.viewer_evidence validate --strict` operator staleness gate (exit 1 on `recorded_at` older than 180 days); advisory and **not** merge-blocking in CI.
- Explicit deferrals for `forms.viewers.pdfjs`, `forms.signature_widget_viewers.pdfjs`, `signing_preparation.viewers.pdfjs`, `signing.viewers.apple_preview`, `signing.viewers.pdfjs`, `signing.long_lived.viewers.{apple_preview,chrome_pdfium,pdfjs}`, and `embedded_files.viewers.apple_preview` with named reasons in `priv/support_matrix.json`.

### Changed

#### API Cleanup & Normalization (v2.5)

- Accidentally-public internals (`Rendro.PDF.CidFont`, `Rendro.PDF.FontSubsetter`, `Rendro.Sign.redact_*`, `Rendro.Protect.redact_*`) are now hidden (`@moduledoc false` or `@doc false`).
- `Rendro.Metadata` is now fully documented with a public `@type t`.
- Recipe options (`sections/2`) for `Invoice` and `BrandedInvoice` correctly thread options instead of silently ignoring them.

#### Viewer Evidence (v2.3)

- Document viewer-evidence CHANGELOG discipline in `guides/api_stability.md` — promotions, explicit deferrals, and legacy re-homes require CHANGELOG entries; re-validations refresh `recorded_at` in the log.
- Re-home `forms.viewers.apple_preview` evidence to `priv/viewer_evidence/forms/apple_preview.md` (**support status unchanged** since v1.8 Phase 47).
- Re-home `embedded_files.viewers.adobe_acrobat_reader` evidence to `priv/viewer_evidence/embedded_files/adobe_acrobat_reader.md` (**support status unchanged** since v1.9 Phase 50).
- Re-home `links.viewers.adobe_acrobat_reader` evidence to `priv/viewer_evidence/links/adobe_acrobat_reader.md` (**support status unchanged** since v1.9 Phase 50).
- Re-home `links.viewers.apple_preview` evidence to `priv/viewer_evidence/links/apple_preview.md` (**support status unchanged** since v1.9 Phase 50).
- Re-home `protection.viewers.apple_preview` evidence to `priv/viewer_evidence/protection/apple_preview.md` (**support status unchanged** since v1.10 Phase 54).
- Signing-preparation equivalence note in `guides/api_stability.md`: non-Acrobat `signing_preparation` rows inherit `signature_widget` evidence; Acrobat requires independent byte-range evidence.
- `embedded_files.viewers.apple_preview` status changed from `unverified` to `explicit_deferral` after Phase 71 re-verify (Attachments UI gap named explicitly).

### Truthful Boundaries Held

- `priv/support_matrix.json` and `guides/api_stability.md` keep unsupported narratives (HTML/CSS parity, browser-style layout, signer-identity trust by default, broad compliance branding, viewer promotion without recorded evidence, multi-signature workflows, HSM/key custody in core, remote asset fetching, broad complex-script support) explicit. Every supported viewer row is backed by recorded checklist proof; trust-sensitive surfaces without recorded proof use `explicit_deferral` with named reasons rather than bare `unverified`.
- The canonical protected-delivery recipe documented in 0.2.0 stays unchanged: `render_to_artifact -> Protect.password -> store/deliver`. Signing seams (`prepare/2`, `sign/2`, `augment/2`) live alongside protection on the artifact boundary, never inside `Rendro.render/2`.

## [0.3.0] - 2026-05-08

This release lifts the v1.5–v2.2 milestone work onto Hex. The 0.2.0 published surface ended at password-to-open protection; 0.3.0 adds validation/trust surfaces, interactive forms, embedded artifacts, signature widgets and signing preparation, cryptographic signing, and long-lived signature evidence — every public claim backed by `priv/support_matrix.json` rows and either a structural or live-tool proof lane. Per-viewer evidence remains the next milestone (v2.3) and is intentionally still recorded as `unverified` outside the rows that have promoted proof.

### Added

#### Validation and Trust Surfaces (v1.5)

- `Rendro.Adapters.Poppler` for structural PDF validation through `pdfinfo`/Poppler with stable redacted error reasons. The lane proves PDF structure only; it does not prove interactive viewer behavior.
- `priv/support_matrix.json` as the canonical machine-readable support contract, mirrored by `guides/api_stability.md`. Every public surface added in this release ships a row in the matrix; rows without recorded per-viewer evidence stay `unverified` rather than being promoted optimistically.
- Widow/orphan layout controls and richer nested-layout structures.

#### Interactive Forms (v1.8)

- `Rendro.form_field/3` with `%Rendro.FormField{}` for deterministic authored AcroForm text fields, checkboxes, and radio groups in the core pipeline.
- Explicit appearance streams for every form widget rather than relying on viewer-generated `NeedAppearances` — keeps deterministic render output stable across viewers.
- Forms boundary in `priv/support_matrix.json` and a `forms_claims_test.exs` docs-contract lane.
- Recorded Apple Preview proof for the `forms` surface (Phase 47); other viewers held at `unverified` pending v2.3 viewer-evidence work.

#### Embedded Artifact Surfaces (v1.9)

- Document-level embedded files with explicit deterministic metadata, validate-stage rejection of ambiguous authored state, and writer emission of `/EmbeddedFile`, `/Filespec`, `/Names`, and `/AF` catalog wiring sorted by stable authored keys.
- Curated link annotations limited to `http`/`https` URIs and in-document page targets, serialized through the existing page `/Annots` seam — no named destinations, no `/GoToR`, no generic action dictionaries.
- Recorded Adobe Acrobat Reader proof for both `embedded_files` and `links`; recorded Apple Preview proof for `links`.

#### Signature Field Authoring and External Signing Preparation (v2.0)

- `Rendro.signature_field/2` for explicit unsigned signature-field authoring on the existing `%Rendro.FormField{}` seam — narrow surface, no second forms engine.
- Deterministic unsigned `/Sig` widget serialization and AcroForm structures without signer-owned placeholders or policy dictionaries leaking into ordinary render output.
- Validate-stage rejection for scope-breaking signature metadata (signer identity, trust anchors, compliance claims) so unsupported semantics fail before render with typed errors.
- `Rendro.Sign.prepare/2` artifact-first external-signing preparation that operates on final artifact bytes, publishes deterministic placeholder coordinates under `metadata.signing_preparation`, and isolates adapter-specific handoff data under `metadata.signing_preparation_adapter`.

#### Cryptographic Signing and Signed-Artifact Validation (v2.1)

- `Rendro.Sign.sign/2` as the artifact-first cryptographic-signing seam over the v2.0 unsigned/preparation boundary.
- `Rendro.Sign.Adapter` behaviour defining the narrow signing-adapter contract.
- First-party optional `Rendro.Adapters.PyHanko` (signing + signed-artifact validation) and `Rendro.Adapters.Pdfsig` (validation) adapters with explicit runtime-executable, redaction, and integrity-vs-trust boundaries — neither package becomes a hard dependency.
- `Rendro.Sign.validate/2` with distinct signals for cryptographic integrity, certificate trust, and viewer behavior (rather than collapsing them into one "signed and valid" claim).
- `signing-live-proof` GitHub Actions lane required on `main` that exercises the canonical `sign → validate` path against checked-in static signing fixtures.
- One signed-artifact support contract aligned across `priv/support_matrix.json`, `guides/api_stability.md`, `guides/integrations.md`, docs-contract tests, and verification artifacts. Signature-specific viewer rows remain `unverified` until recorded per-viewer evidence exists.

#### Long-Lived Signatures and Compliance Evidence (v2.2)

- `Rendro.Sign.augment/2` as a separate seam that adds timestamp and revocation evidence over already-signed artifacts — keeps signing, augmentation, and validation as three explicit boundaries instead of one widening API.
- First-party optional pyHanko long-lived adapter that adds timestamp and revocation evidence without claiming certificate-trust ownership.
- Validator-backed posture classification reporting cryptographic integrity, timestamp presence, revocation evidence presence, and narrow compliance posture as distinct signals — not a blanket PDF/A or PAdES claim.
- `metadata.long_lived` shared posture and `metadata.long_lived_adapter` for tool-shaped facts; explicit non-determinism flagged on every augmented artifact.
- `long-lived-live-proof` GitHub Actions lane required on `main`, backed by an offline `certomancer`-driven PKI/TSA/OCSP fixture so the supported `sign → augment → validate` path is operationally enforced without depending on any public PKI/TSA/CRL endpoint.
- Nested `signing.long_lived` taxonomy in `priv/support_matrix.json`, separate from blanket PDF/A claims, signer trust, viewer behavior, and multi-signature workflows.

### Truthful Boundaries Held

- `priv/support_matrix.json` and `guides/api_stability.md` keep unsupported narratives (HTML/CSS parity, browser-style layout, signer-identity trust by default, broad compliance branding, viewer promotion without recorded evidence, multi-signature workflows, HSM/key custody in core, remote asset fetching, broad complex-script support) explicit. Every supported viewer row is backed by recorded checklist proof; rows without recorded proof remain `unverified` rather than being promoted.
- The canonical protected-delivery recipe documented in 0.2.0 stays unchanged: signing seams (`prepare/2`, `sign/2`, `augment/2`) live alongside protection on the artifact boundary, never inside `Rendro.render/2`.

## [0.2.0] - 2026-05-06

### Added

- `Rendro.Protect.password/2` and `Rendro.render_protected/3` for artifact-first AES-256 password-to-open protection through optional external adapters.
- `Rendro.Adapters.Qpdf` as the first-party external protection adapter, keeping `qpdf` as an optional runtime executable instead of a hard dependency.
- Password-aware `Rendro.Adapters.Poppler.validate/2` support so protected PDFs can still participate in the structural validation lane.
- A new `protection` family in `priv/support_matrix.json` plus docs-contract coverage for advisory-permissions wording and unsupported compliance/signature claims.
- Proof-backed Apple Preview support for the `protection` surface, with release guidance that points downstream users back to the canonical `render_to_artifact -> Protect.password -> store/deliver` recipe instead of persisting passwords in Oban or pushing them into Mailglass.
- `Rendro.Artifact` struct and `Rendro.render_to_artifact/2` to encapsulate generation results (binary, hash, diagnostics, metadata).
- `Rendro.Storage` behavior for persisting generated artifacts to external systems.
- `Rendro.Audit` behavior defining the contract for logging render events and lifecycle telemetry.
- Optional adapter `Rendro.Adapters.Accrue` for building deterministic billing documents.
- Optional adapter `Rendro.Adapters.Mailglass` for seamless attachment of artifacts to transactional emails.
- Optional adapter `Rendro.Adapters.Oban.RenderWorker` for reliable asynchronous document generation and storage.
- `[:rendro, :pipeline, :validate, :start | :stop | :exception]` telemetry events for the new trailing post-render validation stage. The stage performs PDF structural sanity checks (`%PDF-` header, `%%EOF` trailer), page-count parity (PDF `/Type /Pages /Count N` vs `length(doc.pages)`), and the `:max_bytes` policy enforcement formerly inlined after `:render`. Closes BLOCKER-04 from `.planning/v1.0-MILESTONE-AUDIT.md`.
- `Rendro.Pipeline.Validate` module exposing `run/2 :: (binary(), Rendro.Document.t()) -> {:ok, binary()} | {:error, atom()}`.
- `Rendro.Error` `:validate`-stage `what`/`next_step` clauses for `:structural_corruption`, `:page_count_mismatch`, and `:max_bytes_exceeded` (D-09).

### Changed (BREAKING)

- Pipeline stage execution order now matches the documented architecture: `build → compose → measure → paginate → render → validate`. Previously stages ran in the order `build → measure → paginate → compose → render`, which inverted compose/measure relative to the spec. Closes BLOCKER-05 from `.planning/v1.0-MILESTONE-AUDIT.md`.
- `max_pages_exceeded` policy errors now fire from the `:paginate` stage stop event rather than mid-pipeline; the policy guard runs after `:paginate` and before `:render`, where page count is final.
- `max_bytes_exceeded` policy errors are now attributed to the `:validate` stage rather than `:render`; the trailing inline `validate_policy(:bytes, ...)` was absorbed into the `:validate` stage body.
- Stage `:stop` events now carry a unified schema across success and error paths: `%{render_id, document_type, deterministic, stage, status, page_count, byte_size}` with an optional `:error` map (`%{kind, stage}`) on `status: :error`. Error-path `page_count` is now derived from the latest known doc state rather than hardcoded to `0`. Closes MINOR-15 from `.planning/v1.0-MILESTONE-AUDIT.md`.
- Top-level `[:rendro, :render, :stop]` event payload mirrors the new stage stop schema (event name unchanged).

### Notes

- Pre-1.0 release; the previous stage order was a bug against the documented architecture (`v1.0-MILESTONE-AUDIT.md` BLOCKER-04, BLOCKER-05). Top-level `[:rendro, :render, :*]` event names are unchanged; only their stop-metadata schema is updated.
- The `Threadline` adapter (`lib/rendro/adapters/threadline.ex`) subscribes only to top-level events and is unaffected by these changes.
- No bridge period, dual emission, or `telemetry_contract_version` field is provided. See `.planning/phases/06-pipeline-telemetry-contract/06-CONTEXT.md` D-17.
