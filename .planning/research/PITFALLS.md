# Pitfalls Research — v1.10 Protected Delivery Hooks & Encryption Boundaries

**Domain:** Adding PDF protection (external hooks first, native encryption gated) on top of Rendro's existing deterministic, pure-Elixir, optional-adapter PDF pipeline.
**Researched:** 2026-05-06
**Confidence:** HIGH for cryptographic-correctness and Rendro-architecture pitfalls (verified against PDF 2.0 spec discussions, qpdf documentation, published PDF-encryption attacks, and Rendro's own writer source). MEDIUM for some viewer-specific advisory-permission behavior (varies across viewer versions and is the explicit reason for the proof-backed support-matrix lane).

> Replaces the v1.4-era content of this file. The earlier "Async Document Generation & SaaS Integration" pitfalls (Core Contamination, Opaque Async Failures, Leaking Artifact State) remain valid as project-wide architectural lenses and are referenced inline below where v1.10 reuses them, but the body of this catalog is v1.10-specific. The milestone audit at close should preserve them in the audit record before this file is archived.

## How to Read This File

Each critical pitfall captures: **Symptom**, **Root cause**, **Prevention** (concrete API / test / docs change — not "be careful"), **Phase to address** (mapped to v1.10's expected phase decomposition: API/contract → external-hook adapter → docs-contract & support-matrix → proof closure → optional native-encryption gate), and the **Methodology lens** it ties to.

Methodology lens shorthand: **TSC** = Truthful Small Contracts; **BVF** = Boundary Validation First; **DSF** = Deterministic Standard Formatting; **LSDX** = Least Surprise DX.

---

## Critical Pitfalls

### Pitfall 1: Standard Security Handler key derivation implemented incorrectly across R values

**What goes wrong:**
A native-encryption attempt rolls a single "key derivation" routine that conflates the legacy R=2/R=3 (RC4) path with R=4 (AES-128) and R=6 (AES-256). The resulting file opens in one viewer and fails to decrypt in another, or — worse — appears encrypted but uses derived material that does not match the spec, leaving a file that some tools accept and others silently truncate.

**Root cause:**
PDF Standard Security Handler key derivation differs significantly across revisions. R≤4 uses an MD5-based ladder over the padded user password, the `/O` entry, the `/P` entry, and the first element of the trailer `/ID` array, with conditional `0xFFFFFFFF` feeding when `/EncryptMetadata` is `false`. R=6 (PDF 2.0) is a completely different construction using SHA-256/SHA-384/SHA-512 with hardened iteration over `/U`, `/UE`, `/O`, `/OE`, and `/Perms`, where the file encryption key is *stored* (encrypted under a key derived from the password) rather than recomputed from the password directly. The two constructions have different invariants and different password-normalization rules.

**Prevention:**
- v1.10 native-encryption work, if it lands, MUST be R=6 (AES-256, PDF 2.0) only. Treat R≤4 as algorithm support that does not exist in Rendro core, period.
- Implement R=6 via a single, thoroughly-fixture-tested module with golden-vector tests against a third-party reference (qpdf-encrypted fixtures with known passwords, opened on round-trip) before any public function exists.
- Keep `/U`, `/UE`, `/O`, `/OE`, and `/Perms` derivation in one named function each, with documentation citing the PDF 2.0 (ISO 32000-2) algorithm number it implements; do not generalize across R values.
- Phase gate: do not merge a draft of native encryption that derives material in any way other than via these named functions.

**Phase to address:** Native-encryption gate phase (only if demand is proven). External-hook phases never touch key derivation — they shell out to qpdf or equivalent.

**Lens:** TSC (the smallest truthful encryption contract is "AES-256 R=6 only, or nothing"), BVF (validate algorithm/option choices at the public API before any crypto state is allocated).

---

### Pitfall 2: SASLprep / PRECIS password normalization missing or wrong for R=6

**What goes wrong:**
A user creates a PDF with a password containing non-ASCII characters (umlauts, accents, ligatures, ideographs) and the file fails to open in a compliant viewer, or opens in one viewer and not another, because the normalization the writer applied to the password before key derivation does not match what the viewer applies before key derivation.

**Root cause:**
PDF 2.0 R=6 mandates SASLprep (RFC 4013, the StringPrep profile that uses NFKC + RFC 3454 prohibited-character checks + bidirectional rule). RFC 8266 (PRECIS OpaqueString) is the modern replacement; some implementations now apply OpaqueString instead of legacy SASLprep. The user-visible bug is "I can't open my own PDF in Adobe Reader" with a password the user typed identically. Apache PDFBox tracked this for years (PDFBOX-4155). ASCII-only test fixtures completely hide this defect.

**Prevention:**
- If R=6 lands, password input must pass through a documented normalization function. Pick one (SASLprep per RFC 4013 is the spec-aligned choice for PDF 2.0; RFC 8266 OpaqueString is the more modern choice if behavior is verified against fixture viewers) and document it explicitly in the public API.
- Test fixtures MUST include at least: an ASCII password, a Latin-1-supplement password (e.g. `"café"`), a combining-mark password (precomposed vs decomposed `é`), a CJK password, and a password containing characters that would be prohibited by SASLprep (ensure it returns a typed error, not a silent normalization).
- The public API MUST return a typed error on a password that fails normalization, not silently coerce.
- Document explicitly: "Passwords are normalized using `<chosen profile>` before key derivation. Inputs that cannot be normalized return `{:error, {:invalid_password, reason}}`."

**Phase to address:** Native-encryption gate phase (R=6 is the only revision Rendro should ever support; R≤4 used a different and broken normalization step that Rendro must never inherit).

**Lens:** TSC (publish exactly which normalization is applied), BVF (validate at the API, not during key derivation).

---

### Pitfall 3: Reusing IVs (or zero IVs) across encrypted objects

**What goes wrong:**
The native-encryption writer derives one AES-CBC IV at file-open time and reuses it for every encrypted string and stream in the document. Two strings with the same plaintext prefix produce identical ciphertext prefixes, leaking structure to a passive observer. Worse, a "zero IV" implementation is catastrophic: known-plaintext cribs (PDF object headers and `<<` markers) produce trivial first-block recovery against the file encryption key.

**Root cause:**
Per the Standard Security Handler, every encrypted object MUST receive a fresh, random 16-byte IV in AES-CBC mode (the IV is prepended to the ciphertext of that object). This is per-object, not per-document. Implementers who think "the document already has a unique key, so the IV doesn't matter" are wrong; AES-CBC is provably insecure under fixed-IV encryption of distinct plaintexts under the same key.

**Prevention:**
- Native-encryption code MUST call `:crypto.strong_rand_bytes/1` (NEVER the deprecated `:crypto.rand_bytes/1`, removed in OTP 21+) for every encrypted object.
- Add a writer-internal invariant test that asserts no two encrypted objects in a generated file share an IV (read back the leading 16 bytes of each encrypted stream/string and assert distinctness).
- Document explicitly that native-encryption mode is not byte-deterministic across runs even with identical inputs (see Pitfall 7).
- Forbid any "deterministic IV" mode in v1.10. If users want byte-deterministic encrypted output for testing, they accept that this is a non-production knob and it lives behind a separately-named opt-in flag, not on the public protect API.

**Phase to address:** Native-encryption gate phase. External-hook phases (qpdf-style) are not Rendro's responsibility for IV correctness; the support-matrix row pins the external tool's version that has been tested.

**Lens:** TSC, DSF (do not let "deterministic" leak into encrypted output as a default).

---

### Pitfall 4: Encrypting `/ID`, `/Encrypt`, or the file trailer

**What goes wrong:**
The native-encryption writer indiscriminately encrypts every PDF string and dictionary it serializes. The resulting file is unopenable: viewers cannot find the `/Encrypt` dictionary because the trailer can't be parsed, or they cannot derive the encryption key because the `/ID` they're meant to feed into key derivation is itself ciphertext.

**Root cause:**
PDF spec rules: only string and stream objects are encrypted. Dictionaries, names, arrays-of-direct-objects, the `/Encrypt` dictionary itself, and the file trailer's `/ID` entry are NOT encrypted. The `/ID[0]` is *input* to key derivation and must remain plaintext. The `/Encrypt` dictionary contains the parameters needed to derive the key and must remain plaintext. Strings *inside* the `/Encrypt` dictionary (`/U`, `/UE`, `/O`, `/OE`, `/Perms`) are likewise not encrypted; they are the encryption primitives.

**Prevention:**
- The encryption layer must be a writer post-pass that walks the object graph and only re-serializes target string/stream payloads with ciphertext, leaving dictionary structure, names, the `/Encrypt` dictionary, and the trailer untouched.
- Add a fixture round-trip test: write an encrypted file, parse it back with `qpdf --check` and `pdfinfo --upw <password>`, and assert the file is structurally valid.
- Add a unit test that explicitly asserts the trailer `/ID[0]` byte string is identical between the unencrypted and encrypted variants of the same render.
- Phase gate: native-encryption module must not import or call any function that walks the trailer or `/Encrypt` dictionary as encryption targets.

**Phase to address:** Native-encryption gate phase.

**Lens:** TSC, BVF.

---

### Pitfall 5: `/EncryptMetadata` flag/behavior mismatch

**What goes wrong:**
The writer sets `/EncryptMetadata false` in the `/Encrypt` dictionary but still encrypts the metadata stream (or vice versa). Some viewers refuse to open the file; some open it but show garbage in the document properties pane; PDFBox in particular has historically failed decryption when `EncryptMetadata` defaulted to `true` but the metadata stream was actually unencrypted (see PDFBOX-3229).

**Root cause:**
The `/EncryptMetadata` boolean changes both *what is encrypted* and *what feeds into key derivation*: per the spec, the user password key derivation feeds an additional `0xFFFFFFFF` to the MD5 input when `EncryptMetadata` is `false` (R≤4) and analogous changes apply at R=6. So the flag is not just a "skip encryption of one stream" toggle — it changes derived material.

**Prevention:**
- v1.10 native-encryption (if it lands) must NOT expose `/EncryptMetadata` as a user-tunable knob in v1.10. Pick one default (encrypt metadata = true) and document it. Defer the toggle to a later milestone with its own proof.
- Pin the chosen behavior with an explicit fixture: encrypted PDF round-trips through `pdfinfo --upw <password>` AND through Adobe Reader / Apple Preview manual checklist with metadata visible after decryption.

**Phase to address:** Native-encryption gate phase (decision recorded in DECISIONS.md).

**Lens:** TSC (do not expose a knob whose semantics we have not proved).

---

### Pitfall 6: Allowing legacy / weak algorithms (RC4, R<4, V<4) to be selectable

**What goes wrong:**
The public API accepts `algorithm: :rc4_128` (or `:rc4_40`, or any R<4 / V<4 mode) "for compatibility with old viewers." Rendro now ships an algorithm that is broken in the modern threat model. CISOs cannot use Rendro because it offers a knob that violates compliance. Bug reports demand we keep the option for "enterprise customers."

**Root cause:**
qpdf, PDFlib, and most other PDF tooling still expose RC4 modes for legacy compatibility. Implementers default toward "more options is better." But qpdf itself, since v11, refuses by default to *write* RC4-encrypted files unless `--allow-weak-crypto` is passed. Rendro should be at least as opinionated.

**Prevention:**
- Public API for protection MUST NOT expose any algorithm selector beyond AES-256 (R=6). No `:rc4_*`, no `:aes_128`, no `R3`, no `R4`. If the option does not exist in the API, it cannot be misused.
- If the external-hook adapter shells out to qpdf, the adapter MUST pass the qpdf flags that constrain output to AES-256 and MUST NOT accept user-supplied qpdf flags as a passthrough. Document this explicitly.
- Add a docs-contract test that asserts the strings `RC4`, `40-bit`, `128-bit RC4`, `R=2`, `R=3`, and `R=4` do not appear as supported configurations in `priv/support_matrix.json` or `guides/api_stability.md` (they may appear as explicitly *unsupported* entries; the test discriminates).

**Phase to address:** API/contract phase (ban the surface entirely).

**Lens:** TSC (the smallest truthful contract is "AES-256 only"), LSDX (callers cannot accidentally select a broken algorithm because it does not exist in the API).

---

### Pitfall 7: Determinism drift — file `/ID` and IVs change byte-identical output guarantee

**What goes wrong:**
Rendro v1.0–v1.9's foundational promise is byte-deterministic output for identical inputs. The current writer (`lib/rendro/pdf/writer.ex` line ~1620) produces a deterministic `/ID[0]` derived from `MD5(body_parts)` when `deterministic: true`. As soon as protection is layered on, the file ID changes (because the body changes) and any per-object IVs are random. Existing test suites that assert `assert hash_a == hash_b` will start flaking.

**Root cause:**
- For external-hook protection (qpdf): qpdf's `--deterministic-id` flag is documented as "not compatible with creation of encrypted files." Encrypted output cannot be byte-deterministic across runs through qpdf at all.
- For native R=6 encryption: per-object IVs MUST be random (Pitfall 3), so encrypted bytes are non-deterministic by spec. `/U` and `/UE` also incorporate random salts.
- Rendro's existing determinism contract was implicit ("if `deterministic: true`, output bytes are identical"). Protection breaks that contract for protected outputs and only protected outputs.

**Prevention:**
- Add a `protected: true | false` field to `%Rendro.Artifact{}` set by the protection adapter (external or native). Document it as part of the artifact contract.
- Update test helpers / property-based generators to skip byte-identity assertions when `artifact.protected == true`. Provide a `Rendro.TestHelpers.assert_artifact_determinism/2` that takes a deterministic-or-not stance based on the artifact's `protected` flag.
- The `Rendro.Artifact.hash` field should continue to hash the actual binary (even if protected), so the hash naturally changes per run; documentation must explain that for protected artifacts the hash is *not* a determinism oracle.
- Update `guides/api_stability.md` with a "Determinism boundary under protection" subsection that says, in plain language: "Protected output (password-to-open or AES-256 R=6) is not byte-deterministic across runs. The unprotected upstream artifact remains byte-deterministic. Determinism tests must read `artifact.protected` before asserting byte equality."
- Add a CI test that renders the same input twice with protection enabled and asserts the unprotected upstream `/ID` and the page object stream bodies are identical, but the *protected* file binaries differ.

**Phase to address:** API/contract phase (artifact field + documented determinism boundary). Test/proof phase (determinism oracle helpers).

**Lens:** TSC, DSF (the deterministic promise must be truthfully scoped, not silently dropped).

---

### Pitfall 8: Marketing advisory permissions as security

**What goes wrong:**
Docs, README, support matrix, or hex package description state "Rendro supports PDF security with permission flags for printing, copying, and editing." A user adopts Rendro to enforce a "no-print" policy, ships protected reports, and is later breached when an off-brand viewer prints the file anyway (or when any user with the user password runs `qpdf --decrypt`).

**Root cause:**
PDF permission flags (`/P` bits in the encryption dictionary: print, modify, copy, annotate, fill-forms, extract, assemble, print-high-quality) are *not* cryptographically enforced. They are metadata that the viewer chooses to honor. Once the user has the user password (i.e., once the file opens), the full content is in memory, and any non-compliant viewer (including command-line tools, in-browser viewers like Edge in some configurations, and free PDF utilities) can ignore the flags entirely. PDFex (CCS 2019) further demonstrated that even the encryption envelope itself can be bypassed without the password.

**Prevention:**
- Public API: name the call `Rendro.protect/2` (or `Rendro.set_password_to_open/2`), NEVER `Rendro.secure/2` or `Rendro.lock/2`.
- The permissions field, if exposed at all, must be named `:advisory_permissions` (not `:permissions`) and the type-spec docstring must say verbatim: "Advisory only. Not cryptographically enforced. Compliant viewers honor these flags; non-compliant viewers and command-line tools may ignore them. Do not use as a security control."
- Docs-contract test: assert that the strings "advisory" and "not cryptographically enforced" both appear within the same paragraph as the first mention of `:advisory_permissions` in `guides/api_stability.md`. Assert that the words "secure", "secures", "secured" do not appear in association with permission flags in any guide file.
- Support-matrix entries for protection MUST distinguish two viewer behaviors per viewer × protection-feature pair: (a) "opens with password" — verifiable, and (b) "honors P-flag X" — call this out explicitly as advisory and record the viewer + version observed.

**Phase to address:** Docs-contract & support-matrix phase. API/contract phase (naming).

**Lens:** TSC (the truthful contract is "honor-system permissions"), LSDX.

---

### Pitfall 9: Conflating password-to-open with compliance, archival, or signature-grade integrity

**What goes wrong:**
A user reads Rendro's protection docs and assumes a protected PDF satisfies a regulatory "encryption at rest" or "tamper-evident document" requirement. They use it to ship HIPAA / PCI-DSS / GDPR data. The auditor rejects it because PDF Standard Security Handler is not signature-grade, not PDF/A-conformant, and provides no integrity guarantee — only a confidentiality envelope keyed on a password.

**Root cause:**
Authors of PDF tooling routinely conflate three orthogonal properties: (1) confidentiality (the password-to-open envelope), (2) integrity / authenticity (digital signatures, PAdES), (3) archival fidelity (PDF/A). PDF Standard Security Handler provides only (1), and only against an attacker who does not have the password. It provides no integrity guarantee — encrypted PDFs are malleable (this is part of why PDFex worked). PDF/A-1/2/3 forbid encryption entirely; PDF/A-4 still treats it as outside the archival contract.

**Prevention:**
- Public docs MUST contain a "What protection does NOT do" subsection that explicitly states: "Password-to-open encryption is not a digital signature. It does not prove authorship, does not detect modification, and does not satisfy PDF/A archival requirements. It does not satisfy regulatory 'encryption at rest' on its own — it provides a confidentiality envelope keyed on a password, with the security properties of that password choice."
- `priv/support_matrix.json` MUST add an `unsupported` row entry (already shaped) for `digital_signatures`, `pdf_a_compliance`, `tamper_evidence`. (Note: `digital_signatures` and `full_pdf_compliance` already exist in v1.9's matrix; v1.10 must keep them and add a `protection` block alongside, not extend `protection` claims into them.)
- Docs-contract test: assert that any guide page that mentions `Rendro.protect/2` either includes the "What protection does NOT do" block or links to it within the same page.

**Phase to address:** Docs-contract & support-matrix phase.

**Lens:** TSC.

---

### Pitfall 10: Implying signature-grade integrity from the encryption envelope

**What goes wrong:**
A user observes that a protected PDF "won't open without the password" and concludes it must therefore be tamper-evident. They base a chain-of-custody workflow on this assumption. An attacker with the password decrypts the file, modifies a single object, re-encrypts, and ships it; nothing detects the change.

**Root cause:**
Standard Security Handler is a confidentiality-only construction. There is no MAC over the document. The /Perms entry in R=6 is a 12-byte authenticated value over the permission flags only — not over the document content. Any decryption-and-re-encryption cycle preserves "the file is encrypted" without preserving "this is the same content." Some viewers do not even verify /Perms.

**Prevention:**
- The "What protection does NOT do" section (Pitfall 9) must explicitly include: "Encryption is not integrity. A protected PDF can be modified and re-protected; nothing in the protection layer detects this. Tamper evidence requires a digital signature, which is out of scope for this milestone."
- v1.10 milestone scope language must consistently use "password to open" and "advisory permissions" as the only protection nouns. Forbid "secure", "tamper-proof", "tamper-evident", "verified", "trusted" in any v1.10 protection prose. Add this to the docs-contract lane.

**Phase to address:** Docs-contract & support-matrix phase.

**Lens:** TSC.

---

### Pitfall 11: Support-matrix overclaim — viewer "supports password protection" but breaks rendering or silently drops permissions

**What goes wrong:**
The v1.10 support matrix marks Adobe Acrobat Reader as `supported` for `protection.password_to_open` because the viewer prompts for the password and opens the file. But the same viewer ignores the print-disabled P-flag, or the embedded font fails to render once decrypted (because the protection round-trip changed the cross-reference table), or links inside the PDF stop working. Users see "supported" and assume parity with the unprotected case.

**Root cause:**
Support-matrix promotion in v1.5–v1.9 was per-(surface, viewer, behavior). Protection introduces a *combinatorial explosion*: protection × every other authored surface × every viewer × every protection behavior (open, print-flag-honored, copy-flag-honored, fonts-still-render, links-still-work, embedded-files-still-discoverable, forms-still-fillable). Marking just "opens with password" hides behavior degradation.

**Prevention:**
- Extend `priv/support_matrix.json` with a `protection` block that has TWO behavior dimensions per viewer: (a) password-to-open behavior (`opens_with_user_password`, `opens_with_owner_password_only`), and (b) cross-feature regressions — explicitly track that protection × forms, protection × embedded_files, and protection × links each have their own viewer-evidence record before promotion.
- Docs-contract test: any `protection.viewers.<viewer>.status == "supported"` MUST require the per-viewer record to also carry a `cross_feature_proof` array enumerating the other surfaces verified to still work under protection. If the array is missing or empty, the row may be `unverified` but not `supported`.
- Manual viewer evidence checklist for v1.10 MUST record, per (viewer, viewer-version): does the password prompt; does the document render (fonts, links, embedded files, forms each tested); is the print P-flag observed (if author set it); is the copy P-flag observed.
- Default new protection rows to `unverified` until the recorded checklist promotes them, mirroring the v1.9 promotion rule.

**Phase to address:** Docs-contract & support-matrix phase. Proof closure phase (manual viewer checklist execution).

**Lens:** TSC, applied to support-matrix granularity.

---

### Pitfall 12: Password material in `%Rendro.Artifact{}.metadata` or `Rendro.Audit` events

**What goes wrong:**
A developer wires the protect call so that the user password is stored in `artifact.metadata[:user_password]` "for later audit" or so that `Rendro.Audit.track_render/2` receives `%{user_password: "hunter2"}` in its metadata map. The password ends up in `Threadline` audit logs, in Oban job arguments persisted to Postgres, in error reports sent to Sentry, and in `IO.inspect` output during debugging.

**Root cause:**
Rendro's existing async/audit pipeline (v1.4) is designed to be helpful and metadata-rich. The `Rendro.Audit` callback receives a `metadata :: %{optional(atom()) => term()}` map. There is no current type-level discrimination between "safe to log" and "secret material." The artifact struct's `metadata :: map()` is similarly untyped. Once a password leaks into either, it appears in every downstream sink.

**Prevention:**
- The protect API MUST NOT accept the password directly into a struct that is passed through the pipeline. Use a `Rendro.ProtectionParams.t/0` struct that wraps the password in a tagged tuple or a function (`fn -> password end`) so it cannot be `inspect`-ed casually, OR accept the password only as an argument to the protect call and immediately consume it.
- `%Rendro.Artifact{}` MUST gain `protected :: boolean()` (Pitfall 7) but MUST NOT carry the password anywhere. Add a compile-time check (Credo rule or equivalent) that forbids `:user_password`, `:owner_password`, `:password` as keys on Artifact metadata.
- `Rendro.Audit` callback contract: document explicitly that callers MUST NOT include passwords in the metadata map. Provide a `Rendro.Audit.scrub_metadata/1` helper that filters reserved keys; the audit adapter wrappers (`Threadline`) MUST call it.
- Add a fixture test: render with a recognizable password (`"REDACTED-CANARY-PASSWORD"`), invoke audit, and grep the captured audit metadata + artifact.metadata for the canary string. Assert it is absent.

**Phase to address:** API/contract phase (ProtectionParams shape, Artifact field). External-hook adapter phase (verify the adapter never round-trips the password into artifact metadata). Audit-contract docs update.

**Lens:** TSC, BVF (passwords are validated and consumed at the API boundary, not propagated through pipeline state), LSDX (the API does not give callers a way to accidentally leak the password).

---

### Pitfall 13: Coupling external tool (`qpdf`) into core as a hard dependency

**What goes wrong:**
The external-hook protection feature is implemented by adding a `System.cmd("qpdf", [...])` call inside `Rendro.Pipeline.Render` (or worse, inside `Rendro.protect/2` directly in core), so that *every* Rendro install requires `qpdf` to be present on the host even for unprotected renders. Hex CI starts failing on environments without `qpdf`. Users on minimal Docker images get cryptic runtime errors.

**Root cause:**
The temptation: "qpdf is small, ubiquitous, and always available — just shell out." But Rendro's core/adapter split (v1.0 onward) is non-negotiable per `.planning/PROJECT.md` constraints, and the v1.4 pitfall #1 ("Core Contamination") already defined this boundary. Protection is exactly the kind of feature that wants to slip into core.

**Prevention:**
- Implement external-hook protection as `Rendro.Adapters.QpdfProtect` (or similar) under `lib/rendro/adapters/`, mirroring the v1.5 `Rendro.Adapters.Poppler` pattern. The core contains only an injection point (e.g., `protect_adapter:` config) and a `Rendro.Protection` behavior.
- Add a probe call (`Rendro.Adapters.QpdfProtect.available?/0`) that returns `{:ok, version}` or `{:error, :not_installed | :version_too_old | reason}`. Public docs lead with: "External protection requires qpdf >= 11.0 on the host. If unavailable, `Rendro.protect/2` returns `{:error, {:adapter_unavailable, ...}}` and the unprotected artifact is still produced."
- CI matrix: at least one CI lane runs without qpdf installed and asserts that all unprotected-rendering tests pass and that protection tests skip with the expected adapter-unavailable error.
- Mix file: qpdf availability MUST NOT be a `mix.exs` dependency. The CI lane that runs protection tests installs qpdf as an apt/brew step before tests.

**Phase to address:** External-hook adapter phase. CI/proof phase.

**Lens:** TSC (the smallest truthful contract is "core renders; protection is an optional adapter"). Reuses v1.4's "Core Contamination" pitfall.

---

### Pitfall 14: Doing protection inside `Render` instead of as a post-render transform

**What goes wrong:**
The v1.10 implementer adds an `if doc.protected? do ... end` branch inside `Rendro.Pipeline.Render`, allocating different writer object IDs depending on whether the file will be protected, or computing the `/Encrypt` dictionary's `/O` and `/U` entries while the writer still holds object-allocation state. The pipeline's deterministic object-graph property no longer holds (object numbers depend on protection params), and unprotected vs protected renders of the same document produce different *unprotected* upstream bytes. Future signature work (v2.0) inherits the contamination.

**Root cause:**
PDF Standard Security Handler integrates "naturally" with the writer because the encryption dictionary is itself a PDF object that needs an ID. A naive implementer thinks: "encryption is a writer concern." But if the encryption envelope is computed *after* the deterministic writer has produced unprotected bytes, then (a) the unprotected pipeline is unchanged, (b) the protected output is provably a function of the unprotected output, and (c) the v2.0 signature path can sit at the same seam without further pipeline surgery.

**Prevention:**
- Architect protection as a post-render transform: `Rendro.Pipeline.Render` produces an unprotected `%Rendro.Artifact{protected: false}`. A separate `Rendro.Protection.apply/2` (calling either the external-hook adapter or the native R=6 module) consumes that artifact and returns `%Rendro.Artifact{protected: true, binary: <encrypted>, ...}`.
- The unprotected path's behavior, object IDs, and bytes MUST NOT change because protection support exists. Add a CI test: render a fixture without protection in v1.9 and v1.10 and assert byte-identity (subject to other v1.10 changes — gate via golden fixture).
- For native R=6 (if it lands), the encryption pass receives the already-serialized PDF bytes, parses just enough to identify encryptable strings/streams, and emits a new file with the `/Encrypt` dictionary appended and bodies replaced. The core writer (`lib/rendro/pdf/writer.ex`) is not modified.
- Validate-stage rejections of protection params happen in `Rendro.Pipeline.Validate` BEFORE `Render` runs (Pitfall 15), so Render never sees protection state at all.

**Phase to address:** Architecture / API-contract phase (lock the post-render transform shape on day one).

**Lens:** TSC, BVF (protection params validated at the boundary, not inside the writer).

---

### Pitfall 15: Validating protection options too late (in writer or post-write)

**What goes wrong:**
A user calls `Rendro.protect(artifact, password: "", advisory_permissions: [:print, :unknown_permission_atom])`. The empty password silently produces an unprotected file (or, worse, a file with a known empty key). The unknown permission atom is silently dropped. The error surfaces hours later when the file fails to open, or never surfaces at all.

**Root cause:**
v1.9 already established the precedent (`.planning/PROJECT.md` Key Decisions): "metadata is validated in `Rendro.Pipeline.Validate` with tuple errors, not registration-time exceptions." Protection inherits that contract. Implementers under time pressure often validate inside the writer or shell adapter ("we'll catch it when qpdf rejects it"), which gives terrible error UX and lets bad inputs reach unsafe layers.

**Prevention:**
- All protection params are validated in a single typed call at the public API boundary (e.g., `Rendro.Protection.Validate.params/1`) returning `{:ok, %ProtectionParams{}} | {:error, {:invalid_protection_params, reason}}`.
- Validation rules to lock in:
  - `password` must be non-empty after trimming and after normalization (R=6 path); empty / whitespace-only passwords return `{:error, {:invalid_password, :empty}}`.
  - `advisory_permissions` is a list of atoms drawn from a closed enum; unknown atoms return a typed error.
  - Setting any "compliance / archival / signature" key (even by typo) returns `{:error, {:unsupported_protection_option, key}}` rather than silently ignoring.
- Validation runs before the unprotected render even starts when the user calls a "render-then-protect" combined helper, so a bad password does not silently waste a render.
- Test suite includes property-based tests for the validate function over unicode, whitespace, and prohibited-character passwords.

**Phase to address:** API/contract phase.

**Lens:** BVF, TSC, LSDX.

---

### Pitfall 16: Terminology drift — "protected attachment" vs "embedded file" vs "delivery attachment"

**What goes wrong:**
v1.9 already had to fight a terminology trap: "embedded files" inside the PDF binary vs "delivery attachments" handled by adapters (email, download). v1.10 introduces a third axis: a "protected" file, a "password-protected attachment", and "encrypted embedded file" (an embedded file inside an already-protected PDF). Docs, error messages, and module names start using these interchangeably. Users open issues asking why "protecting an attachment" doesn't work the way they expect, and we discover three different mental models.

**Root cause:**
The English overlap is real. "Attach a protected PDF" can mean: (a) embed a PDF inside another PDF that itself happens to have a password, (b) email-attach a password-protected PDF via Mailglass, (c) put a password on a document-level embedded file inside a host PDF (which the Standard Security Handler does not natively do — embedded files inherit the host's encryption context).

**Prevention:**
- Lock terminology in `guides/api_stability.md` v1.10 update:
  - `protect` / `protection` / `protected` — the password-to-open envelope around an entire PDF binary.
  - `embedded file` — document-level file inside the PDF (v1.9 surface, unchanged).
  - `delivery attachment` — adapter-level attachment shipped via Mailglass / Accrue / Oban.
- Forbid the bare word "attachment" in protection prose. If the docs say "attachment", a docs-contract test fails.
- Module names mirror this: `Rendro.Protection.*` is exclusively about password-to-open. Embedded-file modules stay in their existing namespaces. Adapter delivery code stays in adapter namespaces.
- The protect API does not accept a list of "attachments" — only a target artifact and protection params.

**Phase to address:** Docs-contract phase.

**Lens:** TSC (terminology boundary), DSF (consistent naming).

---

### Pitfall 17: Asserting byte-identical output for encrypted PDFs in tests

**What goes wrong:**
A property-based or regression test asserts `assert artifact_a.binary == artifact_b.binary` for two protected renders of the same input. The test is flaky (random IVs differ, qpdf may differ across versions), so it gets `@tag :skip`-ped or the deterministic-id flag gets force-enabled in a way that produces a non-spec-conformant encrypted file (Pitfall 3).

**Root cause:**
Rendro's test culture is built on byte-identity assertions because the v1.0+ pipeline is deterministic. Tests don't currently distinguish "byte-deterministic" from "structurally equivalent" outputs.

**Prevention:**
- Test-helper API: `Rendro.TestHelpers.assert_artifact_determinism(a, b)` inspects `artifact.protected` and dispatches:
  - `protected: false` → byte-identity assertion (existing v1.x behavior).
  - `protected: true` → structural-equivalence assertion (decrypt with the test password and assert byte-identity of the *decrypted* content streams), or skip with a clear `:non_deterministic_protected_output` tag if decrypt is not possible in the test environment.
- Forbid raw `assert a.binary == b.binary` on protected artifacts via a Credo or compile-time hint (or at minimum a documented test-style rule reviewed in code review).
- Add property tests that specifically render the SAME input twice with protection, decrypt both with the test password via the qpdf adapter, and assert decrypted content streams are byte-identical (proving the unprotected upstream is still deterministic; only the encryption envelope differs).

**Phase to address:** Test/proof phase.

**Lens:** DSF (separate "byte-deterministic" from "structurally equivalent" with explicit helper names), TSC.

---

### Pitfall 18: Poppler adapter / `pdfinfo` fails silently on protected fixtures

**What goes wrong:**
The structural-validation lane (`Rendro.Adapters.Poppler` from v1.5) runs `pdfinfo` against generated fixtures. When v1.10 adds protected fixtures, `pdfinfo` returns a non-zero exit and the adapter either reports "validation failed" (false negative — the file is fine, the validator just needs a password) or, depending on Poppler version, prints partial info that the adapter parses incorrectly.

**Root cause:**
`pdfinfo` requires `--upw <user-password>` or `--opw <owner-password>` to read protected files. Without it, the tool exits with "Incorrect password" or with limited output. The Poppler adapter does not currently know how to feed credentials.

**Prevention:**
- Extend `Rendro.Adapters.Poppler` with optional credential support: `validate(binary, opts)` accepts `user_password: binary()` / `owner_password: binary()` and forwards them to `pdfinfo --upw` / `--opw`.
- Test fixtures for protected variants ship with their test passwords as constants in the test file (e.g., `@test_user_password "rendro-test-user"`). Document that test passwords are non-secret.
- Validate that `pdfinfo` version installed on CI supports the flags. Pin the minimum Poppler version in `priv/support_matrix.json` `validators.pdfinfo.version`.
- Add a structural-proof lane test: render a protected fixture, validate with the correct password (expect success), validate without password (expect typed `{:error, :requires_password}`), validate with wrong password (expect typed `{:error, :incorrect_password}`).

**Phase to address:** Proof closure phase (Poppler adapter extension), test/proof phase (fixtures).

**Lens:** TSC (Poppler adapter contract extends with named option, not magic), BVF.

---

### Pitfall 19: Promoting support-matrix rows without recorded manual viewer evidence

**What goes wrong:**
Time pressure at milestone close pushes a `protection.viewers.adobe_acrobat_reader.status` row from `unverified` to `supported` based on "I tried it once on my laptop and it opened." No recorded checklist, no version captured, no fixture path, no per-behavior pass/fail. Six months later the support row is challenged by a user issue and we cannot reproduce the evidence.

**Root cause:**
v1.5–v1.9 already established the recorded-checklist promotion rule (per `.planning/PROJECT.md`'s "Hold viewer claims at unverified until manual evidence is recorded" decision). Each new milestone risks regressing on it because manual viewer testing is tedious. Protection has more behaviors per viewer than any prior surface, so the temptation to skip rows is higher.

**Prevention:**
- Promotion rule for v1.10: a `protection.viewers.<viewer>.status == "supported"` MUST be paired with a phase validation record entry containing: viewer name, viewer version observed, OS, fixture path, date checked, and per-behavior pass/fail for AT LEAST these behaviors: `opens_with_user_password`, `displays_authored_content_correctly`, `honors_advisory_print_flag` (if author requested), `honors_advisory_copy_flag` (if author requested), and `cross_feature_proof` for any other v1.x surface present in the fixture (forms, embedded_files, links).
- Docs-contract test: lint `priv/support_matrix.json` so that any `protection.viewers.<viewer>` with `status == "supported"` requires a non-empty `proof: []` array; reject the file otherwise.
- Phase-close checklist explicitly lists each row that may be promoted and which checklist record backs it. Otherwise default to `unverified`.

**Phase to address:** Proof closure phase.

**Lens:** TSC, reused from v1.5/v1.8/v1.9 promotion rule.

---

### Pitfall 20: Returning `{:ok, _}` when the external tool failed silently

**What goes wrong:**
The qpdf adapter shells out via `System.cmd("qpdf", args)`, captures stdout, and returns `{:ok, output_path}` based on file existence. But qpdf wrote a warning to stderr ("file looks broken; trying to recover"), exited 3 (warning), and produced a file that opens but is missing some authored content. Rendro tells the caller "ok" and the broken file ships.

**Root cause:**
qpdf and similar tools have multi-tier exit codes (0 = ok, 2 = error, 3 = warning + recovered). Many shell-out adapters check only "exit == 0" and treat warnings as success, or check only "file exists at path" and treat any non-empty output as success.

**Prevention:**
- `Rendro.Adapters.QpdfProtect` MUST capture both stdout and stderr, parse exit code explicitly, and return:
  - exit 0 → `{:ok, %Artifact{...}}` only if stderr is empty.
  - exit 0, stderr non-empty → `{:warning, %Artifact{...}, warnings: [...]}` OR conservatively `{:error, {:adapter_warning, ...}}` for v1.10's truthful-claims posture (warnings are errors until proven otherwise).
  - exit 2 → `{:error, {:adapter_error, parsed_reason}}`.
  - exit 3 → `{:error, {:adapter_recovery, parsed_warnings}}` — DO NOT silently treat as success.
- The adapter MUST NOT depend on file existence to determine success.
- Add fixture-driven tests that intentionally feed corrupt input to qpdf and assert the adapter returns the typed warning/error, not `{:ok, _}`.

**Phase to address:** External-hook adapter phase.

**Lens:** BVF, LSDX (the "happy path" matches the real contract), TSC.

---

### Pitfall 21: Permissive default P-flags

**What goes wrong:**
`Rendro.protect/2` is called with only a password and no permissions argument. The implementation defaults the `/P` value to `0xFFFFFFFC` (everything allowed) "to avoid surprising users." A user reads docs that say "protected PDF" and assumes printing/copying is restricted by default; they ship reports without realizing every advisory permission is enabled.

**Root cause:**
Implementer defaults skew toward "least surprise == most permissive." But for an advisory-permissions API, the most truthful default is actually to require the caller to *explicitly* state what is allowed (or what is denied), so the docs and the call site agree.

**Prevention:**
- The advisory-permissions argument is REQUIRED in the API surface. Two reasonable shapes:
  - `Rendro.protect(artifact, password: pw, advisory_permissions: :all_allowed | :default_deny | [:print, :copy, ...])` — make the choice explicit.
  - Or omit the argument entirely from v1.10 and document "v1.10 ships password-to-open without advisory permission flags. Advisory permissions land in v1.11 with their own proof lane." This is the safer TSC choice if advisory permissions cannot be properly verified across the supported viewer set in v1.10.
- If the argument is present, validation rejects the empty list AND rejects the "no flag, no atom" case. The caller MUST pass `:all_allowed` explicitly to get the permissive behavior.

**Phase to address:** API/contract phase. Decide between "advisory permissions in v1.10" vs "deferred to v1.11" at architecture lock — the truthful-claims posture pushes toward deferral if proof cannot be recorded for at least Adobe Reader and Apple Preview.

**Lens:** LSDX, TSC.

---

### Pitfall 22: Public API name implies a guarantee that is actually advisory

**What goes wrong:**
The public function is named `Rendro.secure/2` or `Rendro.lock/2` or `Rendro.set_security/2`. A reader of the API docs sees the function name and assumes it provides security in the colloquial sense. They miss the docstring caveats. A code reviewer approving a PR that calls `Rendro.secure(artifact, password: pw)` does not flag it because the name reads as a security primitive.

**Root cause:**
Naming is the cheapest, loudest documentation surface. A name like `secure` overrides 200 lines of careful docstring caveats.

**Prevention:**
- Function name is `Rendro.protect/2` or `Rendro.set_password_to_open/2`. Both are accurate and narrower than `secure`.
- Module name is `Rendro.Protection`, NOT `Rendro.Security`, NOT `Rendro.Crypto`.
- Adapter behavior name is `Rendro.Protection.Adapter`, NOT `Rendro.Security.Adapter`.
- Add a docs-contract test (or prose review checklist) that the words `Rendro.secure`, `Rendro.lock`, `Rendro.security`, `Rendro.crypto` do not appear as exported public names anywhere in `lib/`.

**Phase to address:** API/contract phase.

**Lens:** TSC, LSDX.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Ship native R=6 encryption in v1.10 alongside external hooks | "We support real encryption out of the box" marketing line | Doubles the v1.10 cryptographic surface; key derivation and IV correctness must be proved twice (vs once via qpdf); locks the project into ongoing crypto maintenance | NEVER in v1.10. Native R=6 is gated on proven demand and explicit non-deterministic-output acceptance per `MILESTONE-ARC.md`. Defer to v1.11 or later. |
| Expose `algorithm:` selector with multiple values "in case users need legacy compat" | Backward compatibility with old viewers | Carries broken algorithms (RC4, R<4) into the public contract forever; CISO blockers; grants users a foot-gun (Pitfall 6) | NEVER. AES-256 R=6 only, or external-hook delegation. |
| Default advisory permissions to permissive | Fewer required arguments | Users ship overly permissive files thinking they are protected (Pitfall 21) | NEVER as a silent default. Explicit `:all_allowed` opt-in is acceptable. |
| Store password in artifact metadata "for round-trip operations" | Easy to re-protect during async re-renders | Password leaks to every audit and storage sink (Pitfall 12); GDPR/HIPAA exposure | NEVER. Re-protection requires the caller to re-supply the password. |
| Skip Apple Preview proof for protection because "Adobe Reader is good enough" | One less recorded checklist | Repeats v1.5/v1.8/v1.9 mistake; support matrix becomes single-viewer (Pitfall 19) | NEVER without recording the row as `unverified` rather than `supported`. |
| Use `assert binary == binary` test on protected output with deterministic-IV opt-in | Familiar test style | Non-spec-conformant encryption (Pitfall 3); test passes but file is cryptographically weak (Pitfall 17) | NEVER with deterministic IVs. Property-based decrypt-and-compare is the alternative (Pitfall 17 prevention). |
| Add `qpdf` to `mix.exs` deps | One-line install; tests run everywhere | Breaks the core/adapter boundary (Pitfall 13); breaks the "pure-Elixir core" project promise | NEVER. Probe at runtime, document the host requirement. |
| Pass arbitrary qpdf flags through the adapter | "Power users can do whatever" | Users select RC4 anyway via `--rc4`; CISO blocker; defeats the whole API design | NEVER. Adapter must restrict the qpdf flag set to AES-256 only. |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| qpdf (external hook) | Calling without `--allow-insecure` check, accepting `--rc4`, ignoring exit code 3 | Pin to qpdf >= 11.0; restrict flag set to AES-256 only; treat exit 3 (warning) as failure (Pitfall 20) |
| Poppler `pdfinfo` validator | Running against protected fixtures without `--upw`/`--opw`; treating exit code as boolean | Extend Poppler adapter with credential opts; pin minimum Poppler version in support matrix (Pitfall 18) |
| Mailglass delivery | Attaching a protected PDF and including the password in the email body or subject | Adapter docs explicitly forbid coupling password to delivery surface; recipe must show out-of-band password sharing (Pitfall 12 corollary) |
| Accrue billing | Embedding billing PII in a protected PDF and assuming the password protects it from compliance auditors | Docs explain confidentiality vs compliance distinction (Pitfall 9) |
| Oban worker | Persisting Oban job args (which would carry the protection params) to Postgres | Job args carry `artifact_id` only; password is supplied at job-execution time from a separate credentials channel (Pitfall 12) |
| Threadline audit | Logging `track_render` metadata that includes the protection params | `Rendro.Audit.scrub_metadata/1` filters reserved keys before any audit adapter sees the metadata (Pitfall 12) |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Spawning qpdf via `System.cmd/3` per render in a hot path | High p99 latency under burst load; many short-lived processes | Pre-flight check that qpdf is on PATH at boot; consider a long-running qpdf-as-coprocess pattern only if profiling shows process spawn dominates | At >100 protected renders/sec on small boxes |
| Re-rendering then re-protecting a large document on every Oban retry | Job timeouts; storage churn | Cache the unprotected `%Rendro.Artifact{}` (which IS deterministic) and re-protect from there; the protect step is the cheap part of the pipeline | At document sizes >5MB or page counts >100 |
| Native R=6 implemented in pure Elixir per byte without batching to OTP `:crypto` block ops | Throughput collapse on large streams | Use `:crypto.crypto_one_time/5` with full-stream input; do not roll a per-byte loop | At document sizes >5MB |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Treating PDF Standard Security Handler as a confidentiality control against an attacker WITH the password | Insider data exfiltration is mistakenly believed prevented | Docs explicitly state the threat model: protection is against an attacker WITHOUT the password (Pitfall 9) |
| Treating advisory P-flags as DRM | Users believe "no-print" is enforced; non-compliant viewers print anyway (Pitfall 8) | Name as `:advisory_permissions`; docs say "honor system" verbatim |
| Allowing weak passwords (empty, short, ASCII-only) without warning | Offline brute-force recovers content trivially via tools like `pdfrip` | Validate-stage rejects empty passwords; docs include a "choose a strong password" section with explicit recommendations (>=20 chars, generated, not reused); link to Pitfall 9's confidentiality framing |
| Reusing IVs / using zero IVs (Pitfall 3) | Catastrophic confidentiality break against passive observer | Per-object random IVs via `:crypto.strong_rand_bytes/1`; writer-internal invariant test |
| Using deprecated `:crypto.rand_bytes/1` | Compile fails on OTP 21+ OR worse, falls back to weak PRNG on older OTPs | Project-wide ban via Credo / compile check; native R=6 path uses only `:crypto.strong_rand_bytes/1` |
| Logging passwords to telemetry, audit, error reports, or Oban args (Pitfall 12) | Direct credential leak to every downstream sink | `Rendro.ProtectionParams` does not implement `Inspect`; `Rendro.Audit.scrub_metadata/1` strips reserved keys; canary fixture test |
| PDFex-style malleability — assuming encryption envelope provides integrity (Pitfall 10) | Modified document re-encrypted and shipped; nothing detects change | Docs explicitly: "encryption is not integrity, signatures are out of scope" |

## DX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| `{:ok, _}` returned when qpdf emitted warnings (Pitfall 20) | User ships subtly broken protected files | Adapter treats exit 3 / non-empty stderr as `{:error, ...}` |
| Function named `Rendro.secure/2` (Pitfall 22) | Reviewer / reader assumes security guarantee that is not delivered | Name is `Rendro.protect/2`; module is `Rendro.Protection` |
| Password accepted as plain string with no trace-warning in docs (Pitfall 12) | User logs the protect-call args via `Logger.debug/1` and leaks the password | Wrap in `%Rendro.ProtectionParams{}` with `Inspect` impl that prints `<redacted>`; docs caution against logging |
| Permission flags default to permissive when caller omits them (Pitfall 21) | User assumes restrictive defaults; ships permissive files | Require explicit `advisory_permissions` argument |
| Empty password silently produces unprotected file | Caller thinks they protected the file | Validate-stage rejects empty/whitespace-only passwords with typed error |
| `Rendro.protect/2` returns the artifact even when adapter is unavailable | Production failures show up only when the protect step is needed | Return typed `{:error, {:adapter_unavailable, ...}}` immediately |

## Rendro-Specific Overclaim Risks (Support Matrix & Docs-Contract)

These are claims that the v1.10 docs/marketing language and `priv/support_matrix.json` MUST NOT make. The docs-contract lane should treat each as a forbidden phrase or shape.

**DO NOT claim:**

- "Rendro generates secure PDFs." Use "Rendro generates protected PDFs (password-to-open envelope; advisory permissions; not signature-grade)."
- "Rendro encrypts your data." Use "Rendro applies the PDF Standard Security Handler password-to-open envelope. The envelope is a confidentiality control against an attacker without the password and does not provide integrity, authenticity, or compliance guarantees."
- "Permissions: print disabled / copy disabled" (without the word "advisory"). Use "Advisory permissions: print disabled / copy disabled (honored by compliant viewers; not cryptographically enforced)."
- "Compatible with all PDF viewers" for protected output. Use the per-viewer support-matrix row, with explicit `unverified` defaults.
- "PDF/A compliant" or "Suitable for archival" — already an `unsupported` row in v1.9; protection is orthogonal to compliance and v1.10 must not blur this.
- "Tamper-evident" / "Tamper-proof" / "Verified" — these imply integrity guarantees that the Standard Security Handler does not provide.
- "Digital signature" / "Signed PDF" — `digital_signatures` is `unsupported` in the v1.9 matrix and remains so in v1.10; protection is not signing.
- "Encryption provides regulatory compliance" — protection alone does not demonstrate HIPAA / PCI-DSS / GDPR posture.
- "Supports password protection" as a viewer-level claim (Pitfall 11) without the underlying per-behavior recorded checklist (`opens_with_user_password`, `displays_authored_content_correctly`, advisory-flag observations, cross-feature proof).
- "RC4-128 supported" / "AES-128 supported" / "supports legacy encryption" — Rendro v1.10 supports AES-256 (R=6) only via native or external-hook delegation. Legacy algorithms are explicit `unsupported` rows.

**DO claim, with truthful narrowness:**

- "Rendro supports password-to-open via external protection adapter (qpdf, AES-256 R=6 only). Native AES-256 R=6 is gated on demand."
- "Advisory permissions are honor-system metadata; compliant viewers honor them, others may ignore them."
- "Protected output is not byte-deterministic across runs. The unprotected upstream artifact remains deterministic."
- "Viewer support is recorded per-viewer in `priv/support_matrix.json`; default is `unverified` until a recorded manual checklist promotes the row."

## "Looks Done But Isn't" Checklist

- [ ] **Native R=6 password derivation:** Often missing SASLprep / RFC 8266 normalization — verify with non-ASCII fixture passwords (Pitfall 2)
- [ ] **External-hook adapter:** Often missing exit-code 3 (warning) handling — verify with intentionally corrupt input fixture (Pitfall 20)
- [ ] **Protected artifact:** Often missing `protected: true` flag on `%Rendro.Artifact{}` — verify the test helper dispatches on it (Pitfall 7, 17)
- [ ] **Support matrix row:** Often missing `cross_feature_proof` array (forms, embedded_files, links each tested under protection) — verify per-viewer record is complete before promotion (Pitfall 11, 19)
- [ ] **Public API name:** Often `secure` slipped in somewhere — verify no `Rendro.secure*`, no `Rendro.Security.*`, no `Rendro.lock*` (Pitfall 22)
- [ ] **Audit/metadata scrubbing:** Often missing canary-password absence test — verify a known canary string is not present in any captured audit metadata or artifact metadata (Pitfall 12)
- [ ] **Docs language:** Often missing the "What protection does NOT do" subsection — verify it links from every page that mentions `Rendro.protect` (Pitfall 9, 10)
- [ ] **Determinism boundary:** Often the "Protected output is not byte-deterministic" sentence is missing — verify in `guides/api_stability.md` (Pitfall 7)
- [ ] **Poppler adapter:** Often missing credential opts — verify `validate(binary, user_password: ...)` passes through to `pdfinfo --upw` (Pitfall 18)
- [ ] **Algorithm surface:** Often `algorithm:` option still present accepting multiple values — verify the public API exposes AES-256 R=6 only (Pitfall 6)
- [ ] **`/EncryptMetadata`:** Often exposed as a knob without proof — verify it is fixed at one default for v1.10 (Pitfall 5)
- [ ] **Hard dependency:** Often `qpdf` quietly added to `mix.exs` — verify `mix.exs` deps unchanged; runtime probe documents the host requirement (Pitfall 13)
- [ ] **CI without qpdf:** Often missing the no-qpdf CI lane — verify at least one CI lane runs unprotected tests on a host without qpdf installed (Pitfall 13)
- [ ] **Permission default:** Often the permissive default sneaks back in — verify `advisory_permissions` is required-explicit, not optional with a default (Pitfall 21)

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Native R=6 derivation bug shipped | HIGH | Hex-publish a security-advisory point release; revert the public function to `{:error, :unsupported_in_this_version}`; coordinate with users via threadline-style advisory; re-introduce only after fresh fixture proof. |
| Password leaked to audit / metadata | HIGH (credential rotation required by all callers) | Hex-publish point release that scrubs reserved keys at the audit boundary; advise all callers to rotate any password used; document the affected version range in CHANGELOG. |
| Support matrix overclaim discovered | MEDIUM | Demote affected row(s) to `unverified` in a point release; record the regression in milestone audit; require new manual viewer checklist before re-promotion. |
| Determinism break in unprotected upstream caused by protection refactor | HIGH | Revert protection refactor; reintroduce as a strict post-render transform that does not touch the writer (Pitfall 14); add CI golden-fixture regression test pinning unprotected bytes. |
| qpdf adapter swallowed exit code 3 | MEDIUM | Point release that escalates exit 3 to `{:error, ...}`; add corrupt-input fixture test; communicate breaking-error-shape change in CHANGELOG. |
| `{algorithm: :rc4_*}` accepted by validation | MEDIUM | Point release that returns `{:error, :unsupported_algorithm}`; document as a security-advisory item; re-export only AES-256 R=6. |

## Pitfall-to-Phase Mapping

Maps each pitfall to the v1.10 phase that should prevent it. Phase names are placeholders aligned to the architecture research's expected decomposition; the planning agent will reconcile names.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1. R-value key derivation correctness | Native-encryption gate phase | Golden-fixture round-trip with qpdf-encrypted reference files |
| 2. SASLprep / PRECIS normalization | Native-encryption gate phase | Unicode password fixture suite (Latin-supplement, CJK, combining marks, prohibited chars) |
| 3. IV reuse | Native-encryption gate phase | Writer-internal invariant test that reads back per-object IVs and asserts distinctness |
| 4. Encrypting `/ID` / `/Encrypt` / trailer | Native-encryption gate phase | Unprotected-vs-protected `/ID[0]` byte-identity test; `qpdf --check` round-trip |
| 5. `/EncryptMetadata` mismatch | Native-encryption gate phase | Single locked default + manual viewer checklist with metadata-visible assertion |
| 6. Weak/legacy algorithms in API | API/contract phase | Docs-contract lint forbidding `RC4`/`R3`/`R4`/`40-bit`/`128-bit RC4` as supported configs |
| 7. Determinism drift | API/contract phase + test/proof phase | `Rendro.Artifact.protected` field; `assert_artifact_determinism/2` helper; CI test of protected non-determinism + unprotected determinism |
| 8. Advisory permissions marketed as security | Docs-contract & support-matrix phase | Docs-contract lint forbidding `secure`/`secured`/`tamper-proof` near permission prose |
| 9. Compliance/archival/signature confusion | Docs-contract & support-matrix phase | "What protection does NOT do" subsection lint; explicit `unsupported` rows |
| 10. Encryption-as-integrity claim | Docs-contract & support-matrix phase | Docs-contract lint forbidding `tamper-evident`/`integrity`/`verified` near protection prose |
| 11. Support-matrix viewer overclaim | Docs-contract & support-matrix phase + proof closure phase | Per-viewer `cross_feature_proof` array required for `supported` |
| 12. Password material in artifact / audit | API/contract phase + adapter phase | Canary-password absence test across artifact metadata and audit metadata |
| 13. qpdf hard dep | External-hook adapter phase | CI lane without qpdf installed; runtime probe; `mix.exs` deps lint |
| 14. Protection inside `Render` | Architecture / API-contract phase | Post-render transform shape locked; unprotected golden-fixture byte-identity preserved across v1.9 → v1.10 |
| 15. Late validation | API/contract phase | `Rendro.Pipeline.Validate` rejection tests for empty/unicode/unknown-permission inputs |
| 16. Terminology drift | Docs-contract phase | Forbidden-bare-`attachment` lint in protection prose |
| 17. Byte-identity assertions on encrypted output | Test/proof phase | `assert_artifact_determinism/2` helper; structural-equivalence helper for protected outputs |
| 18. Poppler / pdfinfo silent failure on protected fixtures | Proof closure phase | Poppler adapter credential opts; minimum version pin in matrix |
| 19. Promoting matrix rows without recorded evidence | Proof closure phase | Promotion checklist; matrix lint requiring non-empty `proof` arrays for `supported` |
| 20. `{:ok, _}` on adapter failure | External-hook adapter phase | Corrupt-input fixture test asserting typed error |
| 21. Permissive default permissions | API/contract phase | Required-explicit `advisory_permissions` argument; validate-stage rejection of omission |
| 22. Function naming implies guarantee | API/contract phase | Public-name lint forbidding `secure`/`lock`/`crypto`/`security` in `Rendro.*` exports |

## Sources

- PDF Standard Security Handler R=6 — RFC 4013 SASLprep, RFC 8266 PRECIS OpaqueString, ISO 32000-2 (PDF 2.0). [PDFBOX-4155 Password Security with Unicode needs SASLprep](https://issues.apache.org/jira/browse/PDFBOX-4155); [RFC 4013 SASLprep](https://www.rfc-editor.org/rfc/rfc4013); [Encryption Algorithms and Key Lengths — PDFlib](https://www.pdflib.com/pdf-knowledge-base/pdf-password-security/encryption/).
- Algorithm correctness and modern recommendations. [How to solve "Unknown encryption type R = 6" errors — iText](https://itextpdf.com/blog/technical-notes/how-solve-unknown-encryption-type-r-6-errors); [PDF Encryption — qpdf 12.3.2](https://qpdf.readthedocs.io/en/stable/encryption.html); [Weak Cryptography — qpdf](https://qpdf.readthedocs.io/en/stable/weak-crypto.html).
- IV reuse and AES-CBC pitfalls. [CWE-329 Generation of Predictable IV with CBC Mode](https://cwe.mitre.org/data/definitions/329.html); [Reused IV-Key Pair Vulnerability — SecureFlag](https://knowledge-base.secureflag.com/vulnerabilities/broken_cryptography/reused_iv_key_pair_vulnerability.html).
- `/EncryptMetadata` semantics. [PDFBOX-3229 Decryption fails when Metadata not encrypted but EncryptMetadata is true](https://issues.apache.org/jira/browse/PDFBOX-3229); [PDF metadata not encrypted — fpdf2 #865](https://github.com/py-pdf/fpdf2/issues/865).
- PDF encryption known weaknesses. [PDFex — Practical Decryption exFiltration](https://www.pdf-insecurity.org/download/paper-pdf_encryption-ccs2019.pdf); [Hack Breaks PDF Encryption — Threatpost](https://threatpost.com/hack-breaks-pdf-encryption/148834/); [PDF Insecurity Website](https://pdf-insecurity.org/).
- Advisory permissions / honor system. [PDF permissions vs. encryption: What every developer needs to know — Nutrient](https://www.nutrient.io/blog/pdf-permissions-vs-encryption/); [PDF Security: Managing Access and Permissions — Apryse](https://apryse.com/blog/pdf-access-control-with-passwords); [MS Edge PDF Viewer not respecting PDF document security settings](https://learn.microsoft.com/en-us/answers/questions/2402486/ms-edge-pdf-viewer-not-respecting-pdf-document-sec).
- qpdf determinism + encryption incompatibility. [Running qpdf — `--deterministic-id` documentation](https://qpdf.readthedocs.io/en/stable/cli.html); [Object and Cross-Reference Streams — qpdf](https://qpdf.readthedocs.io/en/stable/object-streams.html).
- Erlang/OTP `:crypto` deprecation. [Crypto Release Notes — Erlang OTP](https://www.erlang.org/doc/apps/crypto/notes.html); [Use crypto:strong_rand_bytes/1 instead of crypto:rand_bytes/1 — erlang-bcrypt PR #19](https://github.com/smarkets/erlang-bcrypt/pull/19); [crypto:rand_bytes/1 is deprecated — erlang-jose #20](https://github.com/potatosalad/erlang-jose/issues/20).
- Rendro-internal: `/Users/jon/projects/rendro/lib/rendro/pdf/writer.ex` (file `/ID` derivation, lines ~1620–1637); `/Users/jon/projects/rendro/lib/rendro/artifact.ex` (artifact contract); `/Users/jon/projects/rendro/lib/rendro/audit.ex` (audit metadata contract); `/Users/jon/projects/rendro/.planning/PROJECT.md` (constraints + key decisions); `/Users/jon/projects/rendro/.planning/METHODOLOGY.md` (TSC, BVF, DSF, LSDX lenses); `/Users/jon/projects/rendro/.planning/MILESTONE-ARC.md` (v1.10 non-goals); `/Users/jon/projects/rendro/priv/support_matrix.json` (v1.9 claim shape and `unsupported` rows for `digital_signatures`, `full_pdf_compliance`); `/Users/jon/projects/rendro/guides/api_stability.md` (existing public-contract framing).

---
*Pitfalls research for: v1.10 Protected Delivery Hooks & Encryption Boundaries*
*Researched: 2026-05-06*
