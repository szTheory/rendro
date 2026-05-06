# Feature Landscape — v1.10 Protected Delivery Hooks & Encryption Boundaries

**Domain:** PDF protection (password-to-open, advisory permissions, native encryption boundaries) layered onto an existing pure-Elixir, deterministic, Phoenix-first PDF engine.
**Researched:** 2026-05-06
**Confidence:** MEDIUM-HIGH

Stack-level mechanics (V/R combos, /Encrypt dictionary fields, qpdf surface, viewer realities) are anchored in `STACK.md`. This file answers "what should v1.10 ship and not ship?" and is sized to feed the v1.10 roadmap and `priv/support_matrix.json` extension.

## Framing: Two Thin Public Contracts, Not One Encryption Surface

v1.10 should expose **two clearly separated public contracts**, with a hard wall between them:

1. **`Rendro.Protect` (external-hook adapter, default)** — Take a `%Rendro.Artifact{}`, shell out to a configured external tool (e.g., `qpdf`), produce a new `%Rendro.Artifact{}` with explicit protection metadata. **Never claims determinism.** Default-on for any v1.10 protection narrative.
2. **`Rendro.Crypt` (native encryption surface, gated, off by default)** — In-process /Encrypt dictionary emission. **Only lands if proof shows real demand AND non-determinism is explicitly opted into.** Behind a feature flag and an explicit `:non_deterministic_output` opt-in argument until proof closes.

This split is the load-bearing methodology decision. Everything else flows from it.

Why two contracts:

- The deterministic core pipeline (`build → compose → measure → paginate → render → validate`) and `Rendro.Artifact{}` byte-stable hash are non-negotiable per `PROJECT.md` constraints. Native encryption introduces randomness (file encryption key, IVs, salts in O/U/OE/UE) that **breaks byte-stable output by design** — qpdf itself enforces this incompatibility ([qpdf disallows `--deterministic-id` with `--encrypt`](https://qpdf.readthedocs.io/en/stable/cli.html)).
- External hooks let v1.10 ship a truthful narrow protection story today against a battle-tested external tool (qpdf) without rewriting the writer.
- Truthful Small Contracts lens (`METHODOLOGY.md`): the smallest public contract that satisfies the locked phase is two narrow surfaces, each with explicit accepted shapes and explicit error tuples.

## Truthful Framing (Required Across Docs and Support Matrix)

Three claims must stay verbally distinct everywhere — guides, README, `priv/support_matrix.json`, error messages, hexdocs:

| Claim | Truthful framing | Marketing framing to **AVOID** |
|---|---|---|
| **Password-to-open** | "Encrypts file contents; viewer cannot render pages without the user password." | "Secure PDF" |
| **Advisory permissions** (P-flags: print/copy/modify/etc.) | "A flag the PDF asks compliant viewers to honor. Not a security guarantee. Many viewers and tools ignore it." | "Restricts printing/copying" |
| **NOT compliance / NOT signing** | "Rendro v1.10 does not claim PDF/A, PDF/UA, PAdES, LTV, or digital signature support." | (silence — silence reads as implied support) |

Source for the advisory framing: ISO 32000 P-bit semantics ([ISO 32000 spec via PDF Association](https://pdfa.org/resource/iso-32000-2/)) plus widely-acknowledged ecosystem reality that "many open-source viewers and PDF Password Remover websites simply ignore these metadata flags" ([Apryse: PDF Access Control with Passwords](https://apryse.com/blog/pdf-access-control-with-passwords), [PDF Ink: Owner Password & Permissions](https://pdfink.com/blog/2026/02/understanding-pdf-owner-password-and-security-permissions/)). qpdf itself only enforces permissions if you ask it to, and includes a documented "honor system" caveat.

## Table Stakes (Users Expect These of Any "Password-Protected PDF" Library)

These are the features anyone evaluating "I need to send a password-protected PDF" will check for. Missing = the v1.10 narrative is incomplete. Default complexity assessments assume the external-hook-first architecture; native equivalents are noted separately under Differentiators.

| Feature | Why Expected | Complexity | Depends On (existing v1.0–v1.9) | Notes |
|---|---|---|---|---|
| **F-1. Password-to-open via external hook** | Single most common ask: "encrypt this PDF with a password before I email/upload it." | **Medium** | `Rendro.Artifact{}` (v1.4); async delivery seam (v1.4); optional-adapter boundary (v1.0+). | Shell out to `qpdf` with `--encrypt USER OWNER 256 --` ([qpdf encryption manual](https://qpdf.readthedocs.io/en/stable/encryption.html)). New artifact carries `protection: %{...}` metadata. Shape mirrors how `wkhtmltopdf` ecosystems use qpdf/pdftk for encryption ([wkhtmltopdf issue #2808](https://github.com/wkhtmltopdf/wkhtmltopdf/issues/2808)). |
| **F-2. AES-128 baseline** | "At-least-AES-128" is the floor anyone takes seriously after RC4 deprecation ([PDFlib encryption KB](https://www.pdflib.com/pdf-knowledge-base/pdf-password-security/encryption/)). | **Low** (delegated) | F-1. | qpdf maps `--encrypt USER OWNER 128 --use-aes=y --` to V=4 R=4 AES-128. Should be the **lowest** strength v1.10 will accept. |
| **F-3. AES-256 (V=5 R=6, ISO 32000-2)** | The defensible default in 2026. PDF 2.0 explicitly deprecates shorter bit lengths ([PDF 2.0 cryptographic support](https://pdfa.org/pdf-2-0-modernizes-cryptographic-support/)). | **Low** (delegated) | F-1. | qpdf 256-bit key automatically uses V=5 R=6 ([qpdf encryption manual](https://qpdf.readthedocs.io/en/stable/encryption.html)). Should be the **default** strength. |
| **F-4. User password + owner password as distinct inputs** | Long-standing PDF mental model; tooling and operators expect both as separate fields. | **Low** | F-1. | Public API accepts `:user_password` and `:owner_password` separately. Both optional, with explicit error tuples for invalid combinations. **Explicit warning on empty owner password with AES-256** — qpdf flags this insecure and requires `--allow-insecure` ([qpdf encryption](https://qpdf.readthedocs.io/en/stable/encryption.html)). Rendro should refuse it unless caller passes `:allow_insecure_owner_password` opt-in. |
| **F-5. Advisory P-flags as a typed list, NOT booleans named "Restrict X"** | Operators want to express "compliant viewers should not allow print/copy/modify/annotate/form-fill/assemble." | **Low** | F-1. | Public API: `permissions: [:print, :copy, :modify, :annotate, :fill_forms, :assemble, :extract_for_accessibility]` — explicit allowlist, not "deny X" booleans. Maps to ISO 32000 P-bits 3, 4, 5, 6, 9, 11, 10, 12 (high-quality print). Docs **must** label this surface "advisory" inline at every mention. |
| **F-6. Validate-stage rejection of invalid protection state** | Boundary Validation First lens: caller mistakes (no passwords + permission list, malformed `:permissions`, conflicting key length and revision) must fail with typed tuples. | **Low** | `Rendro.Pipeline.Validate` (existing); structured-error pattern (v1.0+). | E.g., `{:error, {:rendro, :protect_missing_password, _}}`, `{:error, {:rendro, :protect_unsupported_algorithm, _}}`. Same envelope shape as v1.9 embedded-files validation. |
| **F-7. Protection metadata on `%Rendro.Artifact{}`** | Async delivery, audit, and storage adapters need to know "this artifact is encrypted, with these claims." | **Low** | `Rendro.Artifact{}` (v1.4); `Rendro.Audit` and `Rendro.Storage` behaviors (v1.4). | New struct field: `protection: nil \| %{algorithm: :aes_256, revision: 6, has_user_password: true, has_owner_password: true, advisory_permissions: [...]}`. Audit emissions and `Mailglass`/`Accrue` adapters consume this read-only. |
| **F-8. Support matrix rows for new surface** | v1.5/v1.8/v1.9 already published `priv/support_matrix.json` as the canonical truth source. Protection cannot be exempt. | **Low** | `priv/support_matrix.json` (v1.5+); `guides/api_stability.md` framing pattern (v1.3+). | New family: `protection`, with capability rows (`password_to_open`, `aes_128`, `aes_256_iso32k`, `advisory_permissions`) and viewer rows (initially `unverified` for everything until manual proof closes). |
| **F-9. Poppler structural validation of encrypted output** | v1.5 lane is the structural-truth gate; promotion requires it. | **Medium** | `Rendro.Adapters.Poppler` (v1.5). | `pdfinfo` accepts a password (`-upw`/`-opw`); the adapter must learn the protection contract so encrypted artifacts can be structurally validated. Without this, encrypted artifacts cannot pass the existing trust gate. |
| **F-10. Honest viewer-support boundary docs (recorded checklist or `unverified`)** | v1.9 set the rule: viewers stay `unverified` until manual proof is recorded. v1.10 must follow the same rule. | **Medium** | v1.9 viewer-proof methodology; recorded-checklist pattern. | Per-viewer rows for Adobe Acrobat Reader, Apple Preview, Chrome PDFium, PDF.js, Foxit, Edge × `password_to_open` × revision (R=4, R=6). All start `unverified`. Manual checklist promotes proof-backed pairs at milestone close. |

## Differentiators (Truthful Edge Rendro Can Defend)

Things Rendro can do that meaningfully distinguish it from "just call qpdf yourself" or from competing PDF libraries — without overclaiming.

| Feature | Value Proposition | Complexity | Depends On | Notes |
|---|---|---|---|---|
| **D-1. External-hook-first architecture as a public contract, not an afterthought** | "Protection is a separate adapter, not core. The core stays pure Elixir and deterministic." | **Medium** | Optional-adapter boundary (v1.0+). | This is **the** Rendro-coherent positioning. ReportLab, HexaPDF, and pdf-lib bake encryption into core; wkhtmltopdf has no answer at all (community uses qpdf/pdftk externally with no contract — [wkhtmltopdf issue #2808](https://github.com/wkhtmltopdf/wkhtmltopdf/issues/2808)). Rendro publishes a `Rendro.Protect.Adapter` behaviour with one shipping implementation (`Rendro.Protect.Adapters.QPDF`) plus a documented contract for users to write their own (e.g., HSM-backed, KMS-fronted). |
| **D-2. `Rendro.Protect.Adapters.QPDF` shipping with `ex_qpdf` reuse** | One install, one config, predictable defaults. Builds on the existing `ex_qpdf` Hex package ([ex_qpdf](https://hex.pm/packages/ex_qpdf)) instead of inventing a port wrapper. | **Medium** | Optional dep approach used in `Accrue`/`Mailglass`/`Oban` adapters (v1.4). | Optional dep declared `optional: true` like `oban`/`accrue`. Defaults: AES-256, no advisory permissions, owner password required. Shells out via `System.cmd/3` with explicit args (no shell interpolation), captures stderr into the structured error tuple. |
| **D-3. Truthful "advisory permissions" surface that names viewers known to ignore the flags** | Honest support-matrix entry that says "advisory; not enforced by [list]." Competitors usually leave this implicit, then users feel deceived when print/copy works anyway. | **Low** | `priv/support_matrix.json` shape (v1.5+). | New matrix subkey under `protection.advisory_permissions`: `enforcement: "honor_system"`, plus `viewers_known_to_ignore: [list-or-empty]`. Sets the right operator expectation up front. |
| **D-4. Determinism contract preserved by **not** doing native encryption in core (v1.10)** | "Rendro guarantees byte-stable artifact hashes for unprotected output. Protected output is the responsibility of an external adapter and is documented as not byte-stable." | **Low** (already true; just document it) | `Rendro.Artifact{}` byte-stable hashing (v1.4). | Single most truthful claim Rendro can make against ReportLab/HexaPDF/pdf-lib. Becomes a featured differentiator in `guides/api_stability.md`. **No new code** — pure framing. |
| **D-5. Optional gated native encryption (v1.10 stretch only, off by default)** | "If you accept non-deterministic output, Rendro can emit /Encrypt natively without external dependencies." | **Large** | F-7, F-8, F-9; the writer's existing object-allocation seam. | Behind feature flag and explicit `:non_deterministic_output` opt-in. Authoring side stays deterministic; encryption layer adds a randomness boundary. **Recommendation: do not ship in v1.10**; keep external-hook-only and reassess after v1.10 close based on demand. |
| **D-6. Identity crypt filter for already-encrypted streams** (only relevant if D-5 ships) | Critical for embedded files (v1.9): authored-bytes embedded files must not be re-encrypted at write time if they're already encrypted. ISO 32000 § 7.6 (Crypt Filters) anticipates this. | **Medium** | F-7; v1.9 embedded-files writer. | Only relevant if native encryption ships. Worth scoping as a known requirement so authoring intent does not get lost; **defer with D-5**. |
| **D-7. Phoenix/Oban integration that flows protection through the existing async lane** | "Add `protect:` opts to your existing `Oban.RenderWorker` job and Mailglass attachment delivery, get a protected artifact and an audited event for free." | **Medium** | `Oban.RenderWorker` (v1.4); `Mailglass`/`Accrue` adapters (v1.4); `Rendro.Audit` behavior (v1.4). | Reuse the existing async delivery job shape; do not invent a parallel "protect job". One audit event per protect step, with redacted password material per existing audit conventions. |

## Anti-Features (Out of Scope for v1.10 — Some Permanently)

Features that look attractive but break the truthful-narrow-contract methodology, or that introduce trust-model claims v1.10 cannot back.

| Anti-Feature | Why Avoid | What to Do Instead |
|---|---|---|
| **A-1. RC4 / V=2 / V=3 / R=2 / R=3 support (40-bit or 128-bit RC4)** | RC4 is cryptographically broken; PDF 2.0 deprecates it ([PDF 2.0 cryptographic support](https://pdfa.org/pdf-2-0-modernizes-cryptographic-support/)). Shipping it would force Rendro to claim "we let you make insecure PDFs," which contradicts the truthful-claims posture. | Refuse outright at validate stage with typed error: `{:error, {:rendro, :protect_legacy_algorithm_unsupported, %{algorithm: :rc4}}}`. Document it as permanently unsupported in `support_matrix.json`. |
| **A-2. Marketing P-flags as "security" or "DRM"** | The P-flag bits are not a security boundary; they are a polite request to compliant viewers. Many viewers and tools ignore them ([Apryse blog](https://apryse.com/blog/pdf-access-control-with-passwords)). Calling them security would be the kind of overclaim `PROJECT.md` constraints explicitly forbid. | Use the word "advisory" inline at every mention, in API docs, in error messages, and in `support_matrix.json`. Add `enforcement: "honor_system"` to the matrix entry. |
| **A-3. Compliance claims (PDF/A-3, PDF/UA, PDF/X for protection, archival)** | Compliance requires validator-backed proof and a separately-bounded trust contract per `PROJECT.md`. Out of scope per `MILESTONE-ARC.md` arc rule. | Explicit `unsupported: ["full_pdf_compliance"]` already in `support_matrix.json`. Keep it; do not add protection-flavored compliance claims. |
| **A-4. Digital signatures, PAdES, LTV, OCSP/CRL/TSA** | Higher-trust surface area with separate cryptographic-trust contract; deferred to v2.0 candidate per `MILESTONE-ARC.md`. v1.10 must not even hint at it. | Explicit "v1.10 does not include digital signatures" line in `guides/api_stability.md` Protection Support Boundary section. |
| **A-5. In-core key custody, key escrow, password vault** | Rendro is a rendering library, not a secrets manager. Caller-owned passwords in opts only. | Public API accepts plain string passwords from caller; never persists, never logs, never echoes in `inspect/1`. Audit emissions redact them. |
| **A-6. Native encryption shipped on by default (D-5 forced into core)** | Breaks the deterministic-artifact contract on which v1.4 hashing and downstream caching depend. Major user-visible regression. | If D-5 ships, gate it behind explicit `:non_deterministic_output` opt-in argument **and** a config flag, with the config flag defaulting to `false`. Any path that flips the determinism contract must require the caller to acknowledge it. |
| **A-7. Public-key encryption (`/Filter /PublicKey`, X.509 recipients)** | Materially larger trust surface; needs cert handling, recipient lists, key infrastructure. Out of scope. | Document as not supported. Standard Security Handler only for v1.10. |
| **A-8. Removing protection / decryption helpers** | Tempts library into being a general-purpose PDF tool. Outside the locked Rendro arc (deterministic authored output, not arbitrary PDF manipulation). | Out of scope. If a user has an encrypted PDF and needs to decrypt, they can call `qpdf` directly. |
| **A-9. Boolean per-permission flags named "deny X"** | Semantically backwards from how P-flags actually work (a 1-bit grants the permission). Confusing and error-prone. | Allowlist semantics: caller passes `permissions: [:print, :copy]` to **grant** those advisory permissions; everything not in the list is `0`. Explicit and matches ISO 32000 bit semantics directly. |
| **A-10. "Encrypted-deterministic" claim without explicit fixed-IV opt-in** | Standard AES-CBC requires a non-zero IV; reusing a fixed IV across runs is a deterministic cheat that has cryptographic warts (see SIV mode discussion — [Connect2id: Deterministic encryption with AES SIV](https://connect2id.com/blog/deterministic-encryption-with-aes-siv)) and is not how the PDF spec mode works. | If D-5 ever ships, do **not** offer a "deterministic encryption" mode in v1.10. The honest claim is "external hook is non-deterministic; native is also non-deterministic; deterministic protected output is a research question, not a feature." |

## Feature Dependencies

```
v1.4 Rendro.Artifact (byte-stable hash)
    └──read-by──> F-7 (protection: %{...} metadata field)
                     └──read-by──> D-7 (Oban/Mailglass/Accrue async protect lane)

v1.4 Rendro.Audit + Rendro.Storage behaviors
    └──read-by──> D-7

v1.5 Poppler adapter
    └──extended-by──> F-9 (encrypted-PDF structural validation; needs password handoff)

v1.5/v1.8/v1.9 priv/support_matrix.json
    └──extended-by──> F-8, D-3 (new "protection" family with advisory framing)

v1.0+ optional-adapter boundary + Validate stage
    └──pattern-reused-by──> F-6, D-1, D-2

F-1 (password-to-open hook) ──requires──> F-2 OR F-3 (a key length)
F-1 ──requires──> F-4 (passwords) ──requires──> F-6 (validate-stage rejections)
F-1 ──produces──> F-7 (protection metadata) ──read-by──> F-8 (matrix), F-9 (validator), D-7 (delivery)

F-5 (advisory P-flags) ──requires──> D-3 (honest "advisory" framing in matrix)
                       ──requires──> A-2 wording discipline in docs

D-5 (native encryption stretch) ──conflicts-with──> v1.4 byte-stable hash unless gated
                                ──requires──> A-10 wording discipline (no "deterministic" claim)
                                ──requires──> D-6 (identity crypt filter for v1.9 embedded files)

A-1 (RC4) ──conflicts-with──> truthful-claims posture (must reject at validate stage)
A-2 (marketing P-flags) ──conflicts-with──> truthful-claims posture (linguistic discipline only)
```

### Dependency Notes

- **F-9 (Poppler must accept passwords) is the critical-path gate** for any v1.10 ship that names a viewer `supported`. Without it, encrypted artifacts cannot pass the structural-validation lane that v1.5/v1.8/v1.9 promotion gates depend on. Treat as same-phase-as-F-1 work.
- **F-7 + F-8 must land together.** A protection field on `Rendro.Artifact{}` without a matrix shape is meaningless to operators; a matrix shape without artifact metadata cannot be programmatically asserted.
- **D-5 (native encryption) is structurally incompatible with v1.4 byte-stable hashing** unless the artifact carries a `non_deterministic: true` flag. This is the single biggest reason to ship v1.10 as external-hook-first only.
- **A-9 (boolean "deny" flags) and F-5 (allowlist `:permissions`) are mutually exclusive API choices.** F-5 wins — the allowlist is more honest and matches ISO 32000 bit semantics directly.

## v1.10 Recommended Scope

### Ship (Locked)

The smallest v1.10 surface that is truthful, useful, and reuses existing v1.0–v1.9 seams.

- [x] **F-1** External-hook adapter `Rendro.Protect.Adapters.QPDF` via `ex_qpdf` — primary v1.10 deliverable.
- [x] **F-2 + F-3** AES-128 minimum, AES-256 default; refuse anything weaker.
- [x] **F-4** User and owner password as distinct opts; refuse empty owner password with AES-256 unless `:allow_insecure_owner_password` is explicit.
- [x] **F-5** Allowlist-shaped `:permissions` opt with `[:print, :copy, :modify, :annotate, :fill_forms, :assemble, :extract_for_accessibility]`.
- [x] **F-6** Validate-stage rejection with typed `{:error, {:rendro, :protect_*, _}}` tuples for all malformed inputs.
- [x] **F-7** `protection: %{...}` field on `%Rendro.Artifact{}`; nil for unprotected artifacts (preserves v1.4 hash semantics).
- [x] **F-8** New `protection` family in `priv/support_matrix.json` with capability rows and `unverified` viewer rows.
- [x] **F-9** Poppler adapter learns password handoff so encrypted artifacts can pass structural validation.
- [x] **F-10** Manual viewer checklist for at least Adobe Acrobat Reader and Apple Preview × `password_to_open` × R=6 (and R=4 if practical) before milestone close.
- [x] **D-1** External-hook-first architecture published as a contract in `guides/api_stability.md`.
- [x] **D-2** `Rendro.Protect.Adapters.QPDF` ships as the reference implementation.
- [x] **D-3** Honest "advisory" framing on the P-flags surface in matrix and docs.
- [x] **D-4** Documented determinism boundary: byte-stable for unprotected; explicitly not byte-stable for protected.
- [x] **D-7** Async/delivery integration: `Oban.RenderWorker` accepts `protect:` opts; `Mailglass` and `Accrue` adapters thread protection through unchanged.

### Defer (Stretch, Only If Demand Proves It Inside v1.10 Window)

- [ ] **D-5** Native `Rendro.Crypt` AES-256 V=5 R=6 emission. **Trigger:** explicit user requests during v1.10, AND `:non_deterministic_output` opt-in shipped, AND F-9 already extended for native output. **Default recommendation: do not ship in v1.10.**
- [ ] **D-6** Identity crypt filter for already-encrypted v1.9 embedded files. **Trigger: only if D-5 ships.**

### Permanently Out of Scope (v1.10)

The anti-feature list (A-1 through A-10) above. Specifically: RC4/V<4/R<4, marketing P-flags as security, compliance claims, signatures, key custody, deny-style boolean flags, public-key encryption, decryption helpers, "deterministic encryption" claims.

## Recommended Public-API Shape

(Detailed surface spec lives in `ARCHITECTURE.md`. Sketches here so the feature table is concrete.)

### External-hook adapter (default v1.10 surface)

```elixir
# Pure functional surface; no GenServer state.
{:ok, %Rendro.Artifact{} = protected} =
  Rendro.Protect.apply(
    artifact,
    adapter: Rendro.Protect.Adapters.QPDF,
    user_password: "open-me",
    owner_password: "manage-me",
    algorithm: :aes_256,                # default; :aes_128 also accepted
    permissions: [:print, :copy]        # advisory allowlist; default [] (deny-all-advisory)
  )

# Explicit error tuples, matching v1.0+ pattern.
{:error, {:rendro, :protect_missing_owner_password, %{algorithm: :aes_256}}} = ...
{:error, {:rendro, :protect_legacy_algorithm_unsupported, %{algorithm: :rc4}}} = ...
{:error, {:rendro, :protect_adapter_failure, %{adapter: ..., stderr: ..., exit: ...}}} = ...
```

### Artifact protection metadata (read-only)

```elixir
%Rendro.Artifact{
  binary: <<...>>,
  hash: "...",            # NOT byte-stable across runs when protected; documented
  protection: %{
    algorithm: :aes_256,
    revision: 6,
    has_user_password: true,
    has_owner_password: true,
    advisory_permissions: [:print, :copy],
    via: :external_hook,  # or :native (only if D-5 ships)
    adapter: Rendro.Protect.Adapters.QPDF
  }
}
```

### Native encryption (only if D-5 ships; gated)

```elixir
# Requires explicit non-determinism opt-in.
{:ok, artifact} =
  Rendro.render(doc,
    protect: [
      user_password: "open-me",
      owner_password: "manage-me",
      algorithm: :aes_256,
      permissions: [:print],
      non_deterministic_output: true   # MANDATORY; no default; refuse without it
    ]
  )

# Without :non_deterministic_output, refuse:
{:error, {:rendro, :protect_native_requires_non_deterministic_opt_in, %{}}} = ...
```

## Competitor Feature Posture

| Feature | ReportLab (Python) | HexaPDF (Ruby) | pdf-lib (JS) | wkhtmltopdf (HTML→PDF) | qpdf (CLI) | **Rendro v1.10** |
|---|---|---|---|---|---|---|
| Password-to-open AES-128 | yes | yes | yes | no (community uses qpdf) | yes | yes (via QPDF adapter) |
| Password-to-open AES-256 R=6 | partial | yes | partial | no | yes | yes (default; via QPDF adapter) |
| Allow RC4/V<4 | yes (legacy) | yes (legacy) | yes | n/a | yes | **no — refused** |
| Advisory P-flag framing in docs | mixed (uses "canPrint" booleans) | mixed | mixed | n/a | clearer | **explicit "advisory" everywhere** |
| Determinism preserved for unprotected | n/a | n/a | n/a | n/a | with `--deterministic-id` only | **yes — guaranteed** |
| External-hook-first as a public contract | no | no | no | de facto | n/a | **yes — primary v1.10 surface** |
| Native encryption in core | yes | yes | yes | no | yes | **no in v1.10 (D-5 deferred)** |
| Public-key (X.509) encryption | no | yes | partial | no | yes | **no — out of scope** |
| Compliance claims attached | no | no | no | no | no | **explicitly disclaimed** |

The honest competitive read: ReportLab, HexaPDF, and pdf-lib all bake encryption into core, which forces them into trust-model claims they can't always defend. Rendro's authentic edge is keeping the core deterministic and putting protection in an explicit, narrow adapter — and saying so plainly.

## Confidence and Open Questions

**Confidence: MEDIUM-HIGH.** PDF spec mechanics (V/R combos, /Encrypt fields, P-bit semantics) are well-anchored in ISO 32000 ([PDF Association: ISO 32000-2](https://pdfa.org/resource/iso-32000-2/)) and qpdf's reference implementation ([qpdf encryption manual](https://qpdf.readthedocs.io/en/stable/encryption.html)). Ecosystem patterns (qpdf as the post-processing tool of record, advisory P-flag reality, AES-256 as the 2026 default) reflect multiple sources.

**Open questions to resolve in v1.10 phase research:**

1. **Viewer-support reality must be measured, not assumed.** Adobe Acrobat Reader, Apple Preview, Chrome PDFium, PDF.js, Foxit, Edge × `password_to_open` × R=4 vs R=6 — every one of these starts `unverified`. Apple Preview is reported as AES-128-only on output ([Apple Community: PDF encryption upon export](https://discussions.apple.com/thread/250705030)), but its **opening** behavior for AES-256 R=6 inputs needs a recorded checklist. PDF.js has documented quirks around AES-256 R=6 with multibyte passwords ([mozilla/pdf.js#6010](https://github.com/mozilla/pdf.js/issues/6010), [#20049](https://github.com/mozilla/pdf.js/issues/20049)) — needs measurement before any `supported` claim.
2. **SASLprep / RFC 8266 PRECIS exact requirement for AES-256 R=6.** PDF 2.0 normalizes user-password Unicode via SASLprep (RFC 4013) ([PDFBOX-4155](https://issues.apache.org/jira/browse/PDFBOX-4155)). For external-hook v1.10, `qpdf` handles this internally; for any future native D-5 path, Rendro must implement or vendor the normalization. Phase that scopes D-5 must research this before commitment.
3. **`ex_qpdf` API surface for encryption specifically.** [`ex_qpdf` Hex package](https://hex.pm/packages/ex_qpdf) currently advertises detection and metadata extraction, not encryption emission. v1.10 may need to either contribute encryption helpers upstream or wrap `qpdf` directly via `System.cmd/3` — phase planning should confirm.
4. **D-7 audit redaction requirement.** Audit emissions must never log password material. Existing `Rendro.Audit` redaction conventions need a recorded check that the new `protection: %{...}` artifact field is safe to emit (it should be — passwords are inputs, not outputs).
5. **Determinism narrative when chaining v1.9 embedded files into v1.10 protection.** v1.9 ships authored embedded files with deterministic byte output. When the artifact then passes through `Rendro.Protect.apply`, the embedded streams will be encrypted by the external tool. Confirm this does not produce unexpected behavior in viewers (Apple Preview already does not reliably surface embedded files per v1.9 audit; encryption may compound that). Worth a dedicated v1.10 phase fixture.

## Sources

PDF specification and cryptography:
- [ISO 32000-2 — PDF 2.0 spec entry (PDF Association)](https://pdfa.org/resource/iso-32000-2/)
- [ISO 32000-1 — PDF 1.7 spec entry (PDF Association)](https://pdfa.org/resource/iso-32000-1/)
- [PDF 2.0 modernizes cryptographic support (PDF Association)](https://pdfa.org/pdf-2-0-modernizes-cryptographic-support/)
- [ISO 32000-2:2020 Clause 7: Syntax (PDF Association)](https://pdfa.org/iso-32000-22020-clause-7-syntax/)
- [Encryption Algorithms and Key Lengths (PDFlib)](https://www.pdflib.com/pdf-knowledge-base/pdf-password-security/encryption/)
- [Practical Decryption exFiltration: Breaking PDF Encryption (Müller et al., NDS Bochum)](https://www.nds.rub.de/media/nds/veroeffentlichungen/2021/05/05/PDF_Encryption.pdf)

qpdf (reference implementation, recommended external hook):
- [qpdf encryption manual](https://qpdf.readthedocs.io/en/stable/encryption.html)
- [qpdf CLI reference](https://qpdf.readthedocs.io/en/stable/cli.html)
- [qpdf encryption.rst source](https://github.com/qpdf/qpdf/blob/main/manual/encryption.rst)

Advisory permissions / honor system reality:
- [Apryse: PDF Access Control with Passwords](https://apryse.com/blog/pdf-access-control-with-passwords)
- [PDF Ink: Owner Password and Security Permissions](https://pdfink.com/blog/2026/02/understanding-pdf-owner-password-and-security-permissions/)
- [CMU Adobe Gallery: PDF 1.3 Encryption Explained (historic, P-bit semantics)](https://www.cs.cmu.edu/~dst/Adobe/Gallery/anon21jul01-pdf-encryption.txt)

Viewer support reality:
- [mozilla/pdf.js #6010 — Cannot open AES-256 R=6 with multibyte passwords](https://github.com/mozilla/pdf.js/issues/6010)
- [mozilla/pdf.js #20049 — Wrongly prompts for password on attachment-only encrypted PDFs](https://github.com/mozilla/pdf.js/issues/20049)
- [mozilla/pdf.js #7699 — Copy from encrypted file without password](https://github.com/mozilla/pdf.js/issues/7699)
- [pdfium #727 — Chrome PDF Viewer and 256-bit AES (level 8)](https://groups.google.com/g/pdfium-bugs/c/oHQ_-Vfp_Rw)
- [Apple Community: PDF encryption upon export from Preview](https://discussions.apple.com/thread/250705030)
- [Apple Community: What PDF encryption does Preview use](https://discussions.apple.com/thread/251273705)

Unicode password normalization (SASLprep / PRECIS):
- [PDFBOX-4155 — Password Security with Unicode needs SASLprep](https://issues.apache.org/jira/browse/PDFBOX-4155)
- [RFC 4013 — SASLprep](https://www.rfc-editor.org/rfc/rfc4013.txt)
- [draft-ietf-precis-7613bis — PRECIS update for usernames and passwords](https://datatracker.ietf.org/doc/draft-ietf-precis-7613bis/07/)

Ecosystem patterns (post-processing-first vs in-core encryption):
- [wkhtmltopdf #2808 — Can wkhtmltopdf password protect the PDF? (community uses qpdf/pdftk)](https://github.com/wkhtmltopdf/wkhtmltopdf/issues/2808)
- [HexaPDF SecurityHandler API](https://hexapdf.gettalong.org/documentation/api/HexaPDF/Encryption/SecurityHandler/index.html)
- [HexaPDF homepage](https://hexapdf.gettalong.org/)
- [ReportLab pdfencrypt source](https://github.com/eduardocereto/reportlab/blob/master/src/reportlab/lib/pdfencrypt.py)
- [pdf-lib encryption implementation (AIA Singapore Tech Blog)](https://medium.com/aia-sg-techblog/implementing-encryption-feature-in-pdf-lib-112091bce9af)
- [ex_qpdf Hex package (Elixir wrapper)](https://hex.pm/packages/ex_qpdf)
- [elixir-pdf-generator README (uses pdftk for encryption)](https://github.com/gutschilla/elixir-pdf-generator)

Determinism / fixed-IV background:
- [Connect2id: Deterministic encryption with AES SIV](https://connect2id.com/blog/deterministic-encryption-with-aes-siv)

Rendro internal anchors:
- `/Users/jon/projects/rendro/.planning/PROJECT.md` — v1.10 milestone goals and constraints
- `/Users/jon/projects/rendro/.planning/MILESTONE-ARC.md` — protected-delivery arc rules
- `/Users/jon/projects/rendro/.planning/METHODOLOGY.md` — Truthful Small Contracts, Boundary Validation First lenses
- `/Users/jon/projects/rendro/priv/support_matrix.json` — current support contract shape (extends with `protection` family)
- `/Users/jon/projects/rendro/guides/api_stability.md` — existing support-boundary doc pattern (extends with Protection Support Boundary)
