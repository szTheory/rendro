# Stack Research — v1.10 Protected Delivery Hooks & Encryption Boundaries

**Domain:** PDF protection (password-to-open + advisory permissions) for an existing pure-Elixir, deterministic PDF library
**Researched:** 2026-05-06
**Confidence:** HIGH for OTP `:crypto` primitives; HIGH for `qpdf`/`pdfcpu` external tools; HIGH for Hex package survey (the survey itself is conclusive — there is no existing Elixir lib that writes encryption); MEDIUM for the deterministic-IV strategy claim, which depends on milestone-time prototype validation against Adobe Reader.

## Scope Anchor

This file covers ONLY the v1.10 surface (external protection hooks first; native encryption gated). It is additive on top of the v1.0–v1.9 stack already shipped in `mix.exs`. Existing dependencies (`telemetry`, `harfbuzz_ex`, `unicode_data`, `phoenix`, `plug`, `oban`, `stream_data`, `credo`, `dialyxir`, `ex_doc`, `req`) are unchanged and out of scope.

The two viable v1.10 stack postures are:

1. **External hooks only** (recommended primary surface) — zero new core deps, two new optional adapters wrapping `qpdf` and `pdfcpu` binaries on the same boundary as `Rendro.Adapters.Poppler`.
2. **Native encryption gated** (only if external hooks land cleanly AND demand is proven) — zero new Hex deps; built entirely on the OTP `:crypto` primitives Rendro already calls.

## Recommended Stack

### Core Technologies (no new deps)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| OTP `:crypto` | 5.8.x (OTP 26+) | AES-256-CBC, AES-128-CBC, MD5, SHA-256, PBKDF2-HMAC, `strong_rand_bytes/1` | Already in routine use (`lib/rendro/artifact.ex`, `lib/rendro/pdf/writer.ex:295,1624`, `lib/rendro/storage/local.ex`, `lib/rendro/text/shaper.ex`, `lib/rendro/telemetry.ex`); ships with the runtime; no licence drag; covers every primitive ISO 32000-2 §7.6 standard security handler revisions 4–6 require — `crypto_one_time/5` for AES-CBC, `pbkdf2_hmac/5` for R6 password-to-key derivation, `hash/2` for MD5/SHA-256, `strong_rand_bytes/1` for `/U`, `/O`, validation salts, perms, and CBC IVs. Pure BEAM-side; preserves the pure-core deployment story. |
| `Rendro.Adapters.*` boundary | n/a | Optional adapter shape with `System.find_executable/1` → `System.cmd/3` → typed `{:ok, _} \| {:error, {:missing_executable, _}}` returns | Already proven by `Rendro.Adapters.Poppler` (43 LOC, `lib/rendro/adapters/poppler.ex`). Reuse this exact shape for the new protection adapters. No new deps; pattern is already truthful, optional, and proof-friendly. |
| `Rendro.Pipeline.Validate` | n/a | Validate-stage rejection of ambiguous protection authoring state with typed error tuples | Same lens used to validate embedded-file metadata in v1.9. New protection inputs (passwords, permission flags, post-process selectors) get tuple-error treatment at the boundary, never raised mid-render. |

**Rationale for staying on `:crypto`:** every Rendro hashing/random call already uses `:crypto`. The PDF 1.7 / ISO 32000-2 standard security handler — at every revision Rendro would consider (R4 RC4-128 declined; R5 deprecated; R6 AES-256) — needs only `aes_*_cbc` ciphers, MD5, SHA-256/384/512, `pbkdf2_hmac` (R6 only), and CSPRNG bytes. All present in OTP since 5.x. Adding any third-party crypto Hex package would dilute the trust posture without adding capability.

### Optional Adapter Targets (external binaries)

| Tool | Latest | Licence | Last release | Fit | Boundary impact |
|------|--------|---------|--------------|-----|-----------------|
| **qpdf** | 12.3.2 | Apache-2.0 (or Artistic 2.0 pre-v7) | 2026-01-24 | **Yes — primary recommendation for `Rendro.Adapters.Qpdf`** | Optional; `System.find_executable("qpdf")`. Zero impact on pure core. |
| **pdfcpu** | 0.12.0 | Apache-2.0 | 2026-04-22 | **Yes — secondary recommendation for `Rendro.Adapters.Pdfcpu`** | Optional; static Go binary, single executable. Zero impact on pure core. |
| **mutool** (MuPDF) | 1.27.x | AGPL-3.0 | 2026 | **Maybe** — adapter possible but AGPL of the binary is a deployment surprise for users; do not document as a primary path. | Optional; same shape but flagged in docs. |
| **cpdf** (Coherent PDF) | 2.9 | AGPL-3.0 (community) / commercial paid licence | 2026-02 | **No** | Same AGPL surprise as mutool plus a separate paid-licence track for commercial users; misaligned with Rendro's MIT posture. |
| **pdftk** | 2.02 (server) | GPL-2.0 / proprietary fork | unmaintained since ~2013 | **No** | Discontinued; only RC4-40/RC4-128. Recommending pdftk would push users toward weak-by-default crypto, violating the v1.10 non-goal "weak/legacy algorithms (RC4-40 etc.)". |

**Why qpdf is primary:**
- AES-256 (PDF 1.7 ext-level 8 / PDF 2.0 R6) is the only secure standard-security-handler form qpdf will produce for `--encrypt … 256`; matches the only protection level Rendro should claim.
- Apache-2.0 binary; users can install it without surprise on macOS (`brew install qpdf`), Debian/Ubuntu (`apt install qpdf`), Fedora (`dnf install qpdf`), and Windows.
- Recent active maintenance (12.3.2 in 2026-01); 4,733 commits, 61 releases.
- Stable, well-documented CLI surface (`qpdf --encrypt user owner 256 [perms] -- in.pdf out.pdf`) that is trivial to wrap with the existing `Rendro.Adapters.Poppler` shape.
- Has known security caveats (empty owner password → `--allow-insecure`, behavior of identical user/owner passwords is viewer-dependent) that Rendro can encode as a typed boundary in the adapter — exactly the lens Rendro already applies elsewhere.

**Why pdfcpu is secondary:**
- Pure Go static binary, no shared-library footprint, easy to ship in a Docker image without OS-level dependencies.
- Apache-2.0; clean licence story.
- AES-256 by default (`pdfcpu encrypt -opw OWNER in.pdf`); permissions modeled as flags (`-perm none|all`).
- Useful as a fallback when qpdf is unavailable in a target environment, and as a cross-validator for the manual evidence lane.
- Slightly less PDF-spec-edge-case battle tested than qpdf for unusual structural inputs; that's why it's secondary.

### Existing Hex.pm PDF Encryption Survey (honest, including unmaintained)

This is the conclusive part of the survey: **no Hex package today writes PDF encryption in a way that fits Rendro's pure-core + deterministic + truthful-claims posture.** The closest packages are either inspection-only, deprecated, or browser-runtime wrappers.

| Package | Latest | Licence | Last release | Fit | Notes |
|---------|--------|---------|--------------|-----|-------|
| `ex_qpdf` | 0.1.3 | Apache-2.0 | 2026-01-05 | **No (read-only)** | Wraps qpdf via `System.cmd` for `password_required?/1`, `info/1,2`, `open/1,2`. Does not write encryption. Roadmap mentions merge/split/metadata but not encrypt-write. Useful as a reference for adapter shape but Rendro should write a thinner, encrypt-focused `Rendro.Adapters.Qpdf` rather than depend on `ex_qpdf` (its scope and ours barely overlap, and adding a single-purpose dep with 13 weekly downloads is not worth the supply-chain risk). |
| `pdf_generator` | 0.6.2 | MIT | 2020-03-05 | **No (deprecated stack)** | Browser-runtime PDF generation (wkhtmltopdf / chrome-headless) plus optional encryption via pdftk. Both wrapped tools are abandonware (wkhtmltopdf archived 2023, pdftk unmaintained since ~2013); pdftk only supports RC4-40/128. Including it would re-introduce exactly the weak-algorithm and browser-runtime postures Rendro deliberately rejects. |
| `chromic_pdf` | 1.17.x | Apache-2.0 | active | **No (browser runtime)** | HTML-to-PDF via Chrome + Ghostscript. Not in the same product family; would force a browser runtime back into the deployment story. No PDF encryption surface. |
| `cipher`, `cloak`, `aes256`, `aes256_crypter`, `ex_crypto` | various | various | various | **No (wrong layer)** | Generic AES helpers over `:crypto` with their own format/serialization conventions (envelopes, base64, salt headers). Rendro's encryption layer needs PDF-format-specific bit-exact byte layouts (algorithms 2.A–2.B in ISO 32000-2 §7.6.4) that no general-purpose Elixir crypto wrapper produces. Calling `:crypto` directly is correct and avoids a dependency that would not save code. |
| `prawn_ex`, `imprintor`, `pdf` (v0.7.2), `pdf_extractor`, `pdf_info`, `merge_pdf`, `puppeteer_pdf`, `api2pdf` | various | various | various | **No (out of scope for v1.10)** | None expose encryption write surfaces. |

**Take-away:** v1.10 must build its protection adapters in-tree. There is no acceptable shortcut.

### Validation / Proof Lane

| Tool | Purpose | Addition needed? |
|------|---------|------------------|
| `pdfinfo` (Poppler) | Report `Encrypted: yes`, encryption variant (e.g. `AES 256-bit`), and advisory permissions on a protected PDF without supplying a password | **Reuse** `Rendro.Adapters.Poppler` — it already shells `pdfinfo`; we only need to widen its `parse_output/1` map matchers to expose the `Encrypted` and `Permissions` lines. New code is one parse branch, not a new adapter. |
| `pdfinfo -upw / -opw` | Decrypt-with-known-password proof for password-roundtrip tests | Add a thin `Rendro.Adapters.Poppler.validate/2` arity that accepts `{:upw, pw} \| {:opw, pw}` opts; keep zero-arg behavior unchanged. |
| `qpdf --check` (when `qpdf` is the chosen adapter) | Cross-validate structural integrity post-encryption | Optional second proof lane on top of `pdfinfo`; nice-to-have, not required. |
| Manual viewer evidence | Adobe Acrobat Reader, Apple Preview, Chrome PDFium open-with-password, "permissions honored" advisory check | Same recorded-evidence approach used in v1.8/v1.9 for forms and embedded files; just extend `priv/support_matrix.json` with a `protection` family. |

The existing `pdfinfo` lane already covers the core "is it encrypted?" structural assertion without holding the password — confirmed via the manpage. **No new validator binary is needed for v1.10**; the encrypted-PDF visibility comes for free from the Poppler adapter Rendro already ships.

### Determinism Strategy

Rendro already produces a deterministic file `/ID` array when `opts[:deterministic]` is true: `lib/rendro/pdf/writer.ex:1620-1629` MD5-hashes the body bytes and uses the digest for both halves of the trailer `/ID` array. This is the right primitive to extend. The split below preserves that:

| Output mode | Determinism | What changes vs. today |
|-------------|-------------|------------------------|
| Unprotected (existing `:deterministic` mode) | Byte-for-byte deterministic | Unchanged; v1.10 must not regress. |
| External post-process (qpdf/pdfcpu) — owner & user passwords supplied by caller | **Non-deterministic** by default (qpdf and pdfcpu both inject random salts and CBC IVs); becomes deterministic only if the post-process tool itself is deterministic and the caller pins versions/seeds, which neither tool guarantees. | Document the protection step as crossing the determinism boundary. The pre-encryption Rendro PDF stays deterministic; the post-encryption artifact does not. |
| Native AES-256 encryption (gated R6) | **Deterministic-with-fixed-salt** mode possible: derive `/O`, `/U`, `/OE`, `/UE`, `/Perms`, validation/key salts, and per-stream CBC IVs from the existing content-hash file `/ID` via HKDF-SHA256, NOT from `strong_rand_bytes/1`. The encryption key itself is then a deterministic function of (content hash, owner password, user password, perms). | This explicitly trades cryptographic forward-secrecy properties for byte-reproducibility and must be opt-in only (`encryption: [..., deterministic: true]`). The default native mode must use `strong_rand_bytes/1` and be honestly labelled non-deterministic. |

**Key authoring decision the milestone has to make at design-lock time:** does v1.10 promise a deterministic encryption mode, or only honest "encryption necessarily breaks byte-determinism"? The `MILESTONE-ARC.md` entry says "non-deterministic output mode is explicitly accepted opt-in", which favors not promising the deterministic-with-fixed-salt mode initially. Recommended posture: **ship native encryption (if it ships at all) as honestly non-deterministic, and defer the deterministic-with-fixed-salt experiment to a later phase under the same gate process v1.5/v1.8/v1.9 used.** That keeps the v1.10 trust contract truthful and avoids surfacing a subtle "your CBC IVs are content-derived" caveat in the first protection release.

The existing MD5-based `/ID` array already serves the file-identity role even in encrypted mode (algorithms 2.A and 3.4 in ISO 32000-2 mix the file identifier into the password-to-key derivation). No change to the `/ID` generator is needed — only an audit to confirm it still runs **before** encryption is applied (it already does, since it sits in the writer's trailer phase).

## Installation

```elixir
# mix.exs deps/0 — additions for v1.10 (NONE)
# All v1.10 work is built on existing :crypto and the existing optional-adapter pattern.
defp deps do
  [
    # ... unchanged from v1.9 ...
    {:telemetry, "~> 1.4"},
    {:harfbuzz_ex, "~> 1.2"},
    {:unicode_data, "~> 0.8.0"},
    {:phoenix, "~> 1.7", optional: true},
    {:plug, "~> 1.14", optional: true},
    {:oban, "~> 2.17", optional: true},
    {:stream_data, "~> 1.3", only: [:dev, :test], runtime: false},
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
    {:ex_doc, "~> 0.40", only: [:dev, :test], runtime: false},
    {:req, "~> 0.5", only: [:dev, :test]}
  ]
end
```

External binaries used as optional adapters (no Hex involvement; users install them themselves, mirroring the existing `pdfinfo` requirement):

```bash
# qpdf (recommended primary protection adapter)
brew install qpdf            # macOS
apt install qpdf             # Debian/Ubuntu
dnf install qpdf             # Fedora/RHEL+EPEL

# pdfcpu (recommended secondary protection adapter)
brew install pdfcpu          # macOS
go install github.com/pdfcpu/pdfcpu/cmd/pdfcpu@latest  # any platform with Go
# or download static binary from releases

# pdfinfo — already required for the existing Poppler validator lane
brew install poppler         # macOS
apt install poppler-utils    # Debian/Ubuntu
```

Test/CI matrix: protection-adapter tests gate on `System.find_executable/1` exactly the way `Rendro.Adapters.Poppler` tests already do, so missing-binary CI runs return `{:error, {:missing_executable, _}}` as a typed result, not a test failure. The `mix verify` deterministic vs advisory split absorbs this without change.

## Alternatives Considered

| Recommended | Alternative | When the alternative would make sense |
|-------------|-------------|---------------------------------------|
| `Rendro.Adapters.Qpdf` (in-tree, written for v1.10) | Depend on `ex_qpdf` v0.1.3 | Never for v1.10 — `ex_qpdf` doesn't write encryption. Reconsider only if it grows an `encrypt/3` surface and has materially better adoption than today's ~13 weekly downloads. |
| `:crypto` directly for any future native encryption | `cloak`, `cipher`, `ex_crypto`, `aes256`, `aes256_crypter` | Never for PDF encryption — these libraries impose envelope formats, base64 outputs, and salt prefixes that conflict with byte-exact PDF encryption-dictionary bit layouts. They solve a different problem (encrypting opaque blobs at rest), and their solutions are wrong at the PDF layer. |
| `qpdf` as primary external tool | `mutool` / `cpdf` | Only when a downstream user has an explicit business reason to use AGPL tooling (e.g. they already accept it). Rendro itself should not direct users there by default. |
| Honest non-deterministic encryption mode (gated) | "Deterministic-encryption" mode using HKDF over content hash | Only after a follow-up phase produces (a) recorded Adobe Reader + Apple Preview + Chrome PDFium proof, (b) a security note that explicitly states content-derived IVs are not forward-secret, and (c) explicit opt-in API with no default activation. Not appropriate for v1.10 first-light. |
| `pdfinfo` (existing Poppler adapter, lightly extended) | A new structural validator binary | Never for v1.10 — adding a second binary requirement would weaken the proof story rather than strengthen it, and `pdfinfo` already reports the `Encrypted` line and advisory permissions for unknown-password files. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **RC4-40 and RC4-128** (Standard security handler R2/R3/R4) | Listed as a v1.10 hard non-goal; cryptographically broken in published attacks; only legacy reason to support is interop with viewers Rendro doesn't even claim portability for. | AES-256 (R6) or no native encryption at all. |
| **Standard security handler R5** (AES-256, pre-PDF-2.0, "Adobe ExtensionLevel 3") | Cryptographic weaknesses published in 2008; superseded by R6 (ExtensionLevel 8 / PDF 2.0). | R6 only, if any native encryption ships. |
| **`pdftk` as a recommended path** | Discontinued; supports only RC4-40/RC4-128; encouraging it would push users toward weak crypto and a dead toolchain. | qpdf (primary) or pdfcpu (secondary). |
| **`pdf_generator` (Hex package)** | Wraps abandonware (wkhtmltopdf, pdftk) and a browser runtime (Chrome). Re-introduces every constraint Rendro's pure-core posture rejects. | The in-tree `Rendro.Adapters.Qpdf` and `Rendro.Adapters.Pdfcpu` adapters Rendro will ship in v1.10. |
| **Generic Elixir crypto wrappers** (`cloak`, `cipher`, `ex_crypto`, `aes256`, `aes256_crypter`) | They do AES-CBC over `:crypto` but emit their own byte envelope, salt prefix, and base64 framing. PDF encryption requires bit-exact /Encrypt-dictionary layout that is incompatible with any of these envelopes. Adding one would be all overhead, no benefit. | `:crypto` directly. |
| **`cpdf` (Coherent PDF) as a default** | AGPL community license + paid commercial license; misaligned with Rendro's MIT posture and with users who want a default that doesn't introduce a viral copyleft. | qpdf (Apache-2.0) by default; document `cpdf` only as a third-party choice users wire themselves. |
| **Marketing PDF permissions as enforcement** | PDF advisory permissions are an honor-system signal; third-party viewers and any decrypt-extract tool ignore them. The v1.10 non-goals already prohibit this; Rendro must encode it in the support-matrix wording. | `priv/support_matrix.json` row `protection.permissions: "advisory_only"`; docs guide labelling permissions as advisory and pointing readers toward DRM-class tools when enforcement is the actual requirement. |
| **Hard-deps on any OS binary in the core mix.exs** | Breaks the pure-core deployment story; users on minimal containers (Distroless, Alpine without poppler-utils) would silently fail to load Rendro. | All protection tools remain optional and gated by `System.find_executable/1`, exactly like the existing Poppler adapter. |

## Stack Patterns by Variant

**If the milestone ships external hooks only (recommended starting point):**
- Add `Rendro.Adapters.Qpdf` (primary) and optionally `Rendro.Adapters.Pdfcpu` (secondary).
- Both use the existing adapter shape: `find_executable/1` → `System.cmd/3` → typed return.
- Extend `Rendro.Adapters.Poppler.parse_output/1` to surface `Encrypted` and `Permissions` lines.
- Add a `protection` family to `priv/support_matrix.json` with rows for `password_to_open`, `permissions: "advisory_only"`, and explicit `unsupported`-flagged compliance/archival/signature claims.
- No `:crypto` work in core; no new mix deps; no determinism-mode change to the writer.

**If the milestone also ships native encryption (only after external hooks proof-pass):**
- Build a new `Rendro.Pdf.Encrypt` module under `lib/rendro/pdf/` (alongside `writer.ex`) implementing ISO 32000-2 §7.6 R6 algorithms 2.A, 8, 9, 11, 13 directly on `:crypto`.
- Wire it as a **post-trailer pass** in the writer so the deterministic content-hash `/ID` is already computed before encryption rewrites the streams; this preserves the existing deterministic file-identity contract.
- Default mode is non-deterministic (`strong_rand_bytes/1` for `/U`, `/O`, `/OE`, `/UE`, `/Perms`, validation/key salts, per-stream CBC IVs), and is documented as such.
- No new Hex deps; entirely on existing `:crypto`.

**If the milestone defers native encryption (acceptable per `MILESTONE-ARC.md`):**
- Same as the external-only branch.
- Document the decision in `MILESTONE-ARC.md` and `PROJECT.md > Evolution Path`, and keep the `priv/support_matrix.json` `protection.native_encryption: "unsupported"` row as a truthful boundary until a future milestone reopens it.

## Version Compatibility

| Component | Compatible with | Notes |
|-----------|-----------------|-------|
| Elixir 1.19 | OTP 26 / 27 / 28 | All `:crypto` primitives (`pbkdf2_hmac/5`, `crypto_one_time/5`, `aes_*_cbc`, `hash/2`, `strong_rand_bytes/1`) are stable across all three OTP versions Rendro supports. No version-floor changes for v1.10. |
| `qpdf` ≥ 11 | All Linux/macOS/Windows | AES-256 encryption fully supported; 256-bit `--encrypt` form requires `--allow-insecure` only when owner password is empty (the adapter must enforce non-empty owner). 12.x preferred but not required. |
| `pdfcpu` ≥ 0.5 | All platforms (single Go binary) | AES-256 default since 0.4. 0.12.0 is the current latest. |
| `pdfinfo` (Poppler) | ≥ 22 | Already declared in `priv/support_matrix.json > validators.pdfinfo`; existing version floor stays. Encrypted-line and Permissions-line output have been stable for many years. |

## Sources

- Erlang/OTP `:crypto` — Context7 (`/websites/erlang_doc`) — `pbkdf2_hmac/5`, `strong_rand_bytes/1`, AES cipher streaming/one-time API, MD5 listed under compatibility hashes — confirmed available in OTP 26+.
- [Erlang/OTP crypto v5.8.3 module reference](https://www.erlang.org/doc/apps/crypto/crypto.html) — primitives, cipher list, RC4 still supported as `cipher_no_iv` (deliberately not used).
- [Elixir 1.19 release notes](https://elixir-lang.org/blog/2025/10/16/elixir-v1-19-0-released/) — OTP 26+ baseline confirmed.
- [qpdf 12.3.2 encryption documentation](https://qpdf.readthedocs.io/en/stable/encryption.html) — AES-256 only at 256-bit, --allow-insecure caveat, permission flag matrix.
- [qpdf GitHub](https://github.com/qpdf/qpdf) — Apache-2.0 / Artistic-2.0 alt; 12.3.2 released 2026-01-24; actively maintained.
- [qpdf issue #351 — empty owner password viewer behavior](https://github.com/qpdf/qpdf/issues/351) — security caveat the adapter must encode.
- [qpdf Homebrew formula](https://formulae.brew.sh/formula/qpdf) — install pathway parity with the existing Poppler/pdfinfo install model.
- [pdfcpu GitHub](https://github.com/pdfcpu/pdfcpu) — Apache-2.0, v0.12.0 (2026-04-22), single Go binary, 1,013 commits, actively maintained.
- [Coherent PDF cpdf manual ch. 4 — encryption](https://www.coherentpdf.com/cpdfmanual/cpdfmanualch4.html) — AES + AGPL/commercial dual-license model — recorded as not-recommended-by-default.
- [MuPDF mutool clean docs](https://mupdf.readthedocs.io/en/latest/tools/mutool-clean.html) — encryption capabilities + AGPL — recorded as fallback only.
- [pdftk discontinuation discussion](https://harihareswara.net/posts/2022/pdftk-qpdf-and-dealing-with-password-protected-pdfs/) — confirms unmaintained status and RC4-only encryption.
- [Hex.pm `ex_qpdf` 0.1.3](https://hex.pm/packages/ex_qpdf) and [hexdocs README](https://hexdocs.pm/ex_qpdf/readme.html) — Apache-2.0, 2026-01-05; **read-only**, does not write encryption — disqualifies it as a v1.10 dep.
- [Hex.pm `pdf_generator` 0.6.2](https://hex.pm/packages/pdf_generator) — MIT, last release 2020-03-05, wraps wkhtmltopdf/Chrome + pdftk encryption — disqualified (browser runtime + RC4).
- [Hex.pm PDF package listing](https://hex.pm/packages?search=pdf&sort=recent_downloads) — full survey: no Hex package writes PDF encryption today.
- [pdfinfo manpage](https://manpages.ubuntu.com/manpages/bionic/en/man1/pdfinfo.1.html) — confirms `Encrypted: yes` and permissions surface without password; `-upw`/`-opw` flags exist for known-password roundtrip proofs.
- [PDF Association — quirks of PDF encryption](https://pdfa.org/quirks-of-pdf-public-key-encryption/) — confirmation that R5 is deprecated in favor of R6.
- [LockLizard write-up on PDF permission honor system](https://www.locklizard.com/pdf-security/) — third-party confirmation that permissions are advisory; supports Rendro's `permissions: "advisory_only"` claim.
- ISO 32000-2 §7.6 standard security handler — algorithms 2.A, 8, 9, 11, 13 — referenced via the qpdf encryption documentation as the canonical bit-exact specification.

---
*Stack research for: Rendro v1.10 Protected Delivery Hooks & Encryption Boundaries*
*Researched: 2026-05-06*
