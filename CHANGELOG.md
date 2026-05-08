# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - Unreleased

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
- The canonical protected-delivery recipe documented in 0.2.0 stays unchanged: `render_to_artifact -> Protect.password -> store/deliver`. Signing seams (`prepare/2`, `sign/2`, `augment/2`) live alongside protection on the artifact boundary, never inside `Rendro.render/2`.

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
