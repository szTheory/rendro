# Project Research — Pitfalls for v2.3 Viewer Proof & Interop Closure

**Milestone:** v2.3 Viewer Proof & Interop Closure
**Date:** 2026-05-08
**Confidence:** HIGH

## Scope of This Document

These pitfalls are specific to the act of **adding recorded per-viewer evidence and promotion-gated support-contract rows to a deterministic-rendering library that already ships engine-level proof for structural validity, signing integrity, and long-lived signature posture.** They are not generic OSS / docs / CI pitfalls — they are the failure modes that would specifically dilute Rendro's existing v2.0–v2.2 trust posture if v2.3 were executed carelessly.

Five existing guardrails frame everything below and must be preserved by every phase:

1. Pure-Elixir core, no browser runtime in core, no Python/external-binary hard deps.
2. Determinism for unsigned render output; signed/long-lived artifacts are intentionally non-deterministic and labeled as such.
3. One canonical machine-readable contract: `priv/support_matrix.json`.
4. Public claims must stay narrower than blanket "works everywhere".
5. The required `signing-live-proof` and `long-lived-live-proof` CI lanes must stay green and not be diluted by viewer work.

---

## Critical Pitfalls

### Pitfall 1: Promoting a (surface × viewer) row from a casual "looks fine" check (overclaim)

**What goes wrong:**
An operator opens the rendered fixture in Acrobat / Preview / a Chromium build / PDF.js, sees something on screen that resembles the authored surface, and promotes the corresponding `priv/support_matrix.json` viewer row from `unverified` to `supported`. The casual check missed at least one of:

- **Apple Preview × signed_artifacts:** Preview *renders the signature appearance dictionary* but does not implement full `/Sig` cryptographic validation. A signature appearing on screen is not the same as Preview having validated it. Promoting `signing.viewers.apple_preview` to `supported` because the appearance renders is overclaim.
- **PDF.js × forms:** PDF.js historically does not implement full AcroForm appearance streams the way Acrobat does — fields render because Rendro authors explicit appearance streams, not because PDF.js "supports" the form. Promoting `forms.viewers.pdfjs` to `supported` because the page shows the field is overclaim. Edit/toggle/save behavior is the actual surface.
- **Acrobat × signed_artifacts vs long_lived:** Acrobat's "Signed and all signatures are valid" banner means signature integrity. Acrobat's Long-Term Validation (LTV) indicator is a separate UX signal about embedded validation evidence. Conflating the two — promoting `signing.long_lived.viewers.adobe_acrobat_reader` based on the integrity banner alone — is overclaim.
- **PDFium × everything:** "PDFium" is not one viewer. Behavior differs across Chrome stable, Chrome canary, Edge, Brave, embedded WebView2, and embedded `pdfium.dll` consumers. Promoting `chrome_pdfium` as a single row without recording the *exact host application + version + platform* is overclaim by underspecification.
- **"It opens without an error dialog" ≠ "implements the surface correctly":** absence of an error is not presence of behavior. Every checked surface must pass *named per-behavior* checks (e.g., `edit_or_toggle`, `save_and_reopen_readability`, `advisory_print_behavior`), not "no errors observed".

**Why it happens:**
- Operator fatigue at the end of a viewer pass — the easy way to clear an `unverified` row is to declare it `supported`.
- Visual signals (banner, glyph rendering, field outline) are mistaken for behavioral implementation.
- The four target viewers behave very differently and an operator's mental model of "PDF viewer" tends to be Acrobat-shaped.

**How to avoid:**
- **Per-behavior promotion only.** A row's `proof:` array enumerates the exact behaviors that must each independently pass. Promotion requires PASS on every entry; any FAIL or N/A holds the row at `unverified` (or moves it to explicit deferral with a named reason — see Pitfall 6).
- **Distinguish "renders" from "implements" in checklist vocabulary.** Checklists must use behavioral verbs (`edit_or_toggle`, `save_and_reopen_readability`, `validation_indicator_matches_expected_state`) — never `looks_correct` or `displays_without_error`.
- **No conflated-signal rows.** `signing` and `signing.long_lived` viewer rows are separate; an integrity-only Acrobat banner promotes only the `signing` row, never the `signing.long_lived` row, without a recorded LTV-specific check.
- **Specific viewer identity.** Replace abstract `chrome_pdfium` with recorded `host_app` + `host_app_version` + `pdfium_version_if_available` + `platform` fields in the evidence file. The matrix row keeps its key (`chrome_pdfium`) but the supporting evidence file pins the exact substrate.

**Warning signs:**
- A PR promotes a row but the evidence file has fewer recorded behaviors than the row's `proof:` array.
- Evidence text contains the words "looks correct," "renders fine," "no errors," or "signature shown" without a behavioral verb.
- The Apple Preview signed_artifacts or long_lived row is being promoted at all (almost certainly overclaim — see deferral discipline).
- The evidence file does not name a specific host app for `chrome_pdfium`.

**Phase to address:**
Each per-viewer recording phase (forms, protection, signature widgets, signing preparation, signed artifacts, long-lived). Plus a docs-contract test in the schema-extension phase that asserts a row can only be promoted when the evidence file lists every behavior in its declared `proof:` array.

---

### Pitfall 2: Recorded checklists silently going stale under viewer auto-update (viewer-version drift)

**What goes wrong:**
An operator records evidence against Acrobat 2024.x, Preview 11.0 on macOS 26.4.1, Chrome 134's PDFium, and PDF.js 4.x, and the row is promoted to `supported`. Six months later all four viewers have auto-updated. The `priv/support_matrix.json` row still reads `supported`. Nothing in the public contract surfaces that the underlying evidence is now potentially stale. A regression in a future Acrobat point release (e.g., a change in how Acrobat treats `NeedAppearances=false` plus authored appearance streams) goes undetected and Rendro continues to claim recorded support that no longer reflects reality.

**Why it happens:**
- Viewer auto-update is silent and continuous.
- The matrix has no temporal axis — `supported` is a binary, not a "supported as of" claim.
- No CI lane re-runs viewer evidence (and, per scope, none should — see Pitfall 7).

**How to avoid:**

Three layered disciplines, all introduced in v2.3:

1. **Schema disciplines (additive fields on every promoted viewer row):**
   - `recorded_at:` — ISO date the evidence was last validated (string, e.g. `"2026-05-08"`).
   - `viewer_version:` — exact viewer version recorded (string).
   - `platform:` — OS + version + arch context (string).
   - `evidence:` — relative path to the per-viewer evidence file, e.g. `priv/viewer_evidence/forms/apple_preview.md`.

   These fields are *additive* — see Pitfall 4 for schema-coupling discipline.

2. **A `mix viewer_evidence.audit` task** that:
   - Reads `priv/support_matrix.json`, walks every `status: supported` viewer row.
   - Flags rows whose `recorded_at` is older than a configurable staleness threshold (default 6 months).
   - Flags rows missing `recorded_at`, `viewer_version`, `platform`, or `evidence`.
   - Flags rows whose `evidence` file does not exist on disk.
   - Exits with non-zero on flags so CI / a release-readiness gate can reject silent staleness.

   The task is *advisory* by default and *blocking* in a release-readiness lane only — it is not part of the core merge gate (avoid Pitfall 7).

3. **CHANGELOG / release-notes discipline:** every time a row is re-validated against a new viewer version, a CHANGELOG entry records `(surface × viewer) re-validated against viewer_version X on date Y`. This makes the temporal axis visible to operators consuming Rendro, not just to Rendro's maintainers.

**Warning signs:**
- A promoted row has no `recorded_at` field.
- `mix viewer_evidence.audit` flags rows older than 6 months and the operator response is to *bump the date* without re-running the checklist.
- An evidence file's `recorded_at` does not match the last commit date that touched the file (suggests a bumped date without a fresh check).

**Phase to address:**
The schema-extension phase (introduces `recorded_at`, `viewer_version`, `platform`, `evidence` fields with additive discipline) and the recipe phase (introduces `mix viewer_evidence.audit`, CHANGELOG discipline, and the operator-grade re-validation loop).

---

### Pitfall 3: Scope creep — widening v2.3 beyond the milestone (interop / adoption / compliance / signer-trust drift)

**What goes wrong:**
v2.3 is intentionally narrow: record honest per-viewer evidence for the existing surfaces, and promote `priv/support_matrix.json` rows where evidence completes. Once viewer evidence work begins, several adjacent temptations surface and any of them, accepted, would inflate the milestone past its proof-backed scope.

The specific creep candidates and why they must stay deferred:

| Creep candidate | Why it looks attractive | Why it must stay deferred |
|---|---|---|
| Automated headless-Chromium PDF.js rendering CI | "We could verify PDF.js without manual checks" | This is an adoption-grade automation effort, not viewer evidence. It introduces a browser runtime in CI, which is exactly the dependency posture core forbids. Belongs to a future automation milestone, possibly v2.4. |
| PDF/A, PDF/UA, ETSI compliance posture | "Operators ask about compliance whenever signatures come up" | Compliance is not viewer evidence. v2.2 already shipped narrow compliance posture under `signing.long_lived` only. Broader compliance is a separate row family with its own proof lanes and its own milestone. |
| Signer-identity-trust evidence | "Acrobat shows a green check or a yellow warning depending on signer trust — we should record that" | Trust is a separate axis from viewer behavior of the surface. Signer-identity trust is explicitly out of scope across v2.0–v2.2 and remains so. The viewer's *trust UX* output is a function of certificate stores and OS keychains, not of Rendro's authored bytes. |
| Multi-signature workflows | "Acrobat handles N signatures differently than 1" | Multi-signature is explicitly out of scope across the entire signing arc. v2.3 does not open it. |
| New surfaces (page-level annotations beyond curated links, JavaScript actions, named destinations, XFA, `NeedAppearances`-driven forms, etc.) | "While we're recording viewers, we could just add..." | Each of these is a new feature milestone, not a viewer-evidence task. v2.3 records evidence for surfaces that are *already shipped*. |
| Promoting `unverified` rows for surfaces that have *no* recorded evidence | "Surely Acrobat handles AES-256 password-to-open" | "Surely" is overclaim. Promotion requires recorded evidence — see Pitfall 1. |

**Why it happens:**
- Once an operator is hands-on with viewers, adjacent quality-of-life work is visible.
- The existing v2.2 long-lived narrative naturally invites compliance follow-up.
- "We're already in the matrix file" makes additive feature rows feel cheap.

**How to avoid:**
- **Milestone scope guardrail in the roadmap:** v2.3 phases name only the six surfaces in scope (forms, protection, signature widgets, signing preparation, signed artifacts, long-lived signed artifacts). Any phase proposing to add a new surface, a new viewer beyond the four-viewer set, or a new row family is rejected at roadmap review.
- **`MILESTONE-ARC.md` non-goals copied verbatim into every v2.3 phase context.** The non-goals list (no headless CI in v2.3, no compliance expansion, no signer-trust evidence, no multi-signature, no new surfaces) is the single authoritative scope filter.
- **Roadmap close-out gate:** the milestone-audit phase verifies that no row family was added, no new surface key was added to `priv/support_matrix.json`, and the only matrix changes are (a) viewer-status promotions on existing rows and (b) the additive evidence-pointer fields from Pitfall 4.
- **Defer-with-reason discipline** (see Pitfall 6) — every excluded item gets a named deferral, not silent omission.

**Warning signs:**
- A phase plan introduces the words "PDF/A," "PDF/UA," "compliance," "signer trust," "headless," "multi-signature," "named destination," or "annotation" outside the explicit non-goal list.
- A phase proposes adding a new top-level key to `priv/support_matrix.json`.
- A phase proposes a new CI lane that runs a viewer (rather than checking schema/files).

**Phase to address:**
Every phase context section (must reproduce the non-goals); the milestone-audit phase verifies no scope drift.

---

### Pitfall 4: Schema coupling — additive evidence fields breaking downstream readers

**What goes wrong:**
`priv/support_matrix.json` is now consumed by `guides/api_stability.md`, the docs-contract tests, and downstream readers (operators / tooling). v2.3 must add evidence-pointer fields (`recorded_at`, `viewer_version`, `platform`, `evidence`, possibly `proof[]` per behavior). Done wrong, the schema change either:

- breaks readers that did not expect the new fields (rare in JSON, but real for typed parsers),
- couples the matrix to a specific viewer version (so when the viewer auto-updates, the recorded matrix becomes literally wrong rather than potentially stale),
- folds compliance / trust / multi-signature language into viewer-evidence fields, polluting the row taxonomy.

**Why it happens:**
- The cheapest place to add metadata is wherever the operator is already typing.
- `recorded_at: "2026-05-08"` looks innocent until the row says `viewer_version: "2024.001.20643"` and Acrobat auto-updates the next morning. The literal field is now a lie.
- "While we're at it" temptation to record `compliance_posture` next to a viewer row.

**How to avoid:**

Three schema disciplines:

1. **Additive and optional only.** New fields are *added* to existing viewer-row objects. Existing readers that look up `status` still work. Readers that look up `proof[]` still work. The new fields (`recorded_at`, `viewer_version`, `platform`, `evidence`) are *optional* in the schema — their absence is permitted (and means "not yet recorded"), their presence is enforced for `status: supported`. No field is removed, no field is renamed, no field changes type. A docs-contract test enforces additive-only.

2. **Decouple `evidence:` from a frozen viewer version.** The `evidence:` field points at a checked-in evidence file. The evidence file *records* the viewer version, but the matrix row's *promotion* is justified by "an evidence file exists at this path that records a passing checklist," not "Acrobat version X is passing." This means a viewer auto-update does not invalidate the JSON — it only ages the evidence (Pitfall 2 handles aging). The matrix is a pointer; the truth lives in the evidence file.

3. **Do not let viewer evidence carry compliance / trust / multi-signature language.** Compliance posture lives under `signing.long_lived.validation` (already shipped). Signer-identity trust is explicitly `unsupported`. Multi-signature is explicitly `unsupported`. The viewer-evidence fields *only* describe what a human operator observed in a viewer for a specific authored surface. A docs-contract test asserts that no viewer row contains compliance / trust / multi-signature keys.

**Warning signs:**
- A schema change modifies an existing field's type or removes a field.
- A viewer row gains a `compliance_*`, `trust_*`, `cert_*`, or `multi_sig_*` key.
- A viewer row's promotion reasoning quotes an exact viewer version as the *justification* (rather than as recorded context).
- The docs-contract test goes green after a schema change without being updated to enforce the new invariants.

**Phase to address:**
The schema-extension phase. Specific guardrails:
- A docs-contract test (`test/rendro/support_matrix_contract_test.exs` or similar) that enumerates the allowed keys on a viewer-row object and rejects unknown keys at the viewer-row level.
- A docs-contract test that, for every `status: supported` row, asserts the four additive fields are present and the `evidence:` path resolves to an existing file.
- A docs-contract test that asserts no viewer row contains compliance / trust / multi-signature keys.

---

### Pitfall 5: Recorded checklists not reproducible by another operator (reproducibility)

**What goes wrong:**
Operator A records "Acrobat passes the protection checklist" and promotes the row. Operator B, six months later, cannot reproduce the result because Operator A did not check in:

- which exact authored Rendro example was rendered,
- which fixture (or which content hash) was opened in the viewer,
- which viewer version, OS, and platform context were used,
- the per-behavior pass/fail/N/A with a one-line reason,
- the date the check was recorded.

The `priv/support_matrix.json` row says `supported`, but no one can independently confirm it. The proof is non-portable, so the trust claim is non-portable.

**Why it happens:**
- Recording checklists is tedious; the operator's working notes feel sufficient at the time.
- The matrix row alone *appears* to capture the result.
- Screenshots feel like the artifact to keep, but screenshots cannot be machine-checked, can leak content, and bloat the repo (see Pitfall 8).

**How to avoid:**

Every promoted row's `evidence:` field MUST point at a file at `priv/viewer_evidence/<surface>/<viewer>.md` containing, at minimum:

| Field | Purpose | Example |
|---|---|---|
| Authored example or fixture pointer | Reproducibility — what was rendered? | `examples/forms/text_field_example.exs` or a content hash like `sha256:abc123...` of a checked-in fixture |
| Viewer version | Pin the substrate | `Adobe Acrobat Reader 2024.001.20643` |
| OS / platform context | Pin the environment | `macOS 26.4.1 (arm64)` / `Windows 11 23H2 (x64)` / `Ubuntu 24.04 (x64)` |
| Per-behavior result table | Granular pass/fail | `\| open \| PASS \| opens with no dialog \|` `\| edit_or_toggle \| PASS \| toggles persist after focus loss \|` |
| One-line reason on each entry | Disambiguates PASS / FAIL / N/A | "FAIL — Preview does not surface the embedded file in its UI under v11.0" |
| Date recorded | Temporal axis (ties to Pitfall 2) | `2026-05-08` |
| Operator (optional but recommended) | Trail | `recorded by: <handle>` |

**Plain-text and machine-checkable:** the evidence file is text-only Markdown. No screenshots, no embedded PDFs, no binary blobs (see Pitfall 8). The recipe phase establishes a template at `priv/viewer_evidence/_template.md` that every per-viewer evidence file must conform to.

**Warning signs:**
- A promoted row's `evidence:` points at a path that does not exist.
- An evidence file is missing any of the seven fields above.
- An evidence file references "the example I rendered" or "my local PDF" without a checked-in path or hash.
- An evidence file declares PASS without a one-line reason.

**Phase to address:**
- The recipe phase (defines the template, the directory layout, the operator-grade workflow).
- Every per-viewer recording phase (uses the template; produces files that pass the schema-extension phase's docs-contract checks).
- The schema-extension phase's docs-contract tests verify (a) the file referenced by `evidence:` exists, (b) it parses against the template, (c) every `proof:` behavior is recorded.

---

### Pitfall 6: Honest-failure pitfalls — vague "deferred" rows with no named reason

**What goes wrong:**
A viewer / surface pair that *fails* the checklist, or that *cannot* be checked, ends up in the matrix as `unverified` or `deferred` with no recorded reason. A future operator (or downstream reader) cannot tell whether:

- the row was never attempted,
- the row was attempted and failed for a viewer-implementation reason,
- the row is structurally impossible to verify (e.g., Apple Preview does not implement `/Sig` validation, period),
- the row is held off pending external work.

These are very different states and conflating them under "deferred" is dishonest documentation.

**Why it happens:**
- "Deferred" feels safe — it doesn't promise anything.
- Operators do not want to write a paragraph for every negative result.
- The matrix's coarse `unverified` status absorbs all of these without protest.

**How to avoid:**

Every non-`supported` row that the operator *attempted* must record either a `not_promoted_reason:` (the surface failed in a specific, named way) or a `deferred_reason:` (the surface is not being attempted in v2.3 for a specific, named reason). Vocabulary discipline:

- **Named viewer behavior:** "Apple Preview does not implement `/Sig` cryptographic validation as of Preview 11.0 on macOS 26.4.1 — appearance renders, validation indicator absent."
- **Named structural blocker:** "PDF.js 4.x renders the AcroForm field but does not persist edits across reload under viewer.html — `edit_or_toggle` and `save_and_reopen_readability` cannot pass."
- **Named scope deferral:** "Long-lived signature viewer evidence for PDF.js is deferred — PDF.js does not implement DSS / VRI surfaces; promotion is structurally not possible without a different viewer."

**Forbidden vocabulary** (rejected by docs-contract test):
- "deferred for later"
- "TBD"
- "not yet"
- empty string

**How to avoid (cont.):**
- The schema-extension phase adds an optional `not_promoted_reason:` / `deferred_reason:` string field. Either field, when present, must (a) be at least N characters long, (b) name a specific viewer or version, (c) not match the forbidden-vocabulary list.
- Rows with `status: unverified` *and no attempt yet* may have neither field — meaning "no operator has attempted this checklist in v2.3."
- Rows with `status: unverified` *and* a recorded attempt MUST have one of the two fields. The recipe phase makes this explicit in the operator workflow.

**Warning signs:**
- An evidence file contains "deferred" without naming a viewer behavior or version.
- Multiple rows share the exact same `deferred_reason:` text — suggests boilerplate, not analysis.
- A row was flipped from `supported` to `unverified` with no `not_promoted_reason:` recorded (regression with no audit trail).

**Phase to address:**
- The schema-extension phase (adds optional reason fields with minimum-length and forbidden-vocabulary docs-contract checks).
- Each per-viewer recording phase (operators record reasons for failures and deferrals).
- The milestone-audit phase verifies every attempted-but-not-promoted row carries a named reason.

---

### Pitfall 7: CI dilution — a new viewer-evidence lane degrading the existing trust gates

**What goes wrong:**
v2.3 adds a viewer-evidence-schema CI lane (validates that promoted rows have evidence files, that schemas are intact, that no forbidden vocabulary appears). Done wrong, the new lane:

- replaces or weakens the required `signing-live-proof` lane,
- replaces or weakens the required `long-lived-live-proof` lane,
- conflates structural schema checking with behavioral viewer checking (claiming to "verify viewers in CI" when no viewer is run),
- dilutes the meaning of "required check on `main`" by adding a check whose failure mode is misinterpreted by reviewers.

The existing required lanes are the trust spine of v2.1–v2.2. Any change that allows them to be skipped, made non-blocking, or quietly replaced is a regression, regardless of how reasonable the v2.3 work appears.

**Why it happens:**
- It is tempting to consolidate "all the trust checks" into one lane.
- Naming a viewer-schema lane `viewer-proof` (or similar) suggests it does behavioral checking when it does not.
- Branch-protection settings are out-of-band and easy to forget to verify after lane changes.

**How to avoid:**

- **The new lane is structural-only.** It validates: schema shape, additive-field presence on `supported` rows, evidence-file existence, evidence-file template conformance, forbidden-vocabulary absence, no scope-creep keys. It does NOT run any viewer, render any PDF in a viewer, or claim to verify behavior. Name it accordingly: `viewer-evidence-schema` or `support-matrix-contract`, not `viewer-proof`.

- **Required-check invariant.** The milestone-audit phase explicitly verifies that the GitHub branch protection on `main` still requires:
  - `signing-live-proof` (from v2.1)
  - `long-lived-live-proof` (from v2.2)
  - `viewer-evidence-schema` (added in v2.3, additive)
  - all existing `mix ci` / `mix verify` / docs-contract / structural-validation lanes from prior milestones.

  No required check is removed in v2.3. The audit phase's verification artifact records the exact list of required checks and that the v2.1/v2.2 lanes remain enforced.

- **Failure-mode disambiguation.** The new lane's failure messages must say "schema/file invariant failed" — never "viewer X is broken." A red `viewer-evidence-schema` lane means "the matrix and evidence files are inconsistent," not "Acrobat regressed."

- **Docs-contract test for the contract itself.** A test asserts that `guides/api_stability.md` and `priv/support_matrix.json` separately distinguish: structural proof (Poppler/pdfinfo), signing integrity proof (`signing-live-proof`), long-lived posture proof (`long-lived-live-proof`), and recorded viewer evidence. These four lanes are not interchangeable and the docs language must not allow them to be conflated.

**Warning signs:**
- A PR removes any required check from branch protection.
- A new CI job has "proof" or "live" in its name but does not run any external tool.
- A failing `viewer-evidence-schema` is treated as "the viewer broke" in PR review.
- The required-check list at milestone close has fewer entries than at milestone start.

**Phase to address:**
- The CI / live-proof phase (introduces `viewer-evidence-schema` as a structural lane with explicit naming and documented invariant).
- The milestone-audit phase (verifies required-check enforcement on `main` is unchanged from v2.2 plus the additive new lane).

---

### Pitfall 8: Storage pitfalls — bloating the repo or leaking PII through evidence checklists

**What goes wrong:**
"Evidence" naturally invites screenshots, recorded video, full PDFs of representative documents, or copies of customer artifacts as proof of a viewer behavior. Done wrong, evidence checklists carry:

- Customer PII (names, addresses, account numbers from a customer-shaped fixture).
- Screenshot blobs (PNGs / JPEGs / videos) that bloat the repo and are not text-diffable.
- Full PDFs of large fixtures committed alongside the checklist.
- Operational secrets accidentally captured in screenshots (file paths, passphrases visible in title bars, keychain prompts).

This violates the existing v1.10/v2.1/v2.2 operational-safety constraint (no key paths, passphrases, raw stderr in audit surfaces) and inflates the repository size in a way that is hard to reverse later.

**Why it happens:**
- Screenshots feel like the most convincing evidence.
- Operators reach for whatever PDF is on their disk, not necessarily a fixture.
- Customer-shaped fixtures get reused without sanitization.

**How to avoid:**

- **Text-only evidence files.** Per-viewer evidence files in `priv/viewer_evidence/<surface>/<viewer>.md` are Markdown text only. No inline binaries, no inline base64, no embedded screenshots. The recipe phase enforces this in the template and the schema-extension phase enforces it via a docs-contract test that rejects evidence files containing image syntax (`![...](...)`), HTML img tags, or base64 inlines.

- **Fixture-by-hash references.** When the evidence file needs to point at a rendered artifact, it points at either:
  - a checked-in fixture under `test/fixtures/` or `priv/viewer_evidence/fixtures/` with the *content hash* recorded in the evidence file, or
  - an authored Rendro example at `examples/<surface>/...` with the example path recorded.
  No raw customer PDFs. No screenshots of customer data.

- **Fixture sanitization discipline.** Any fixture committed under `priv/viewer_evidence/fixtures/` must use clearly-fictional names, addresses, and amounts. The recipe phase documents a fixture-authoring checklist; the schema-extension phase's docs-contract test optionally lints fixture filenames for obvious PII patterns (best-effort only — primary defense is the recipe).

- **Operational-secret discipline (inherited from v2.1/v2.2).** Evidence files must not contain key paths, passphrases, raw tool stderr, or anything that would fail the existing redaction tests. The recipe phase reminds operators of this; the docs-contract test scans evidence files for forbidden vocabulary (`-----BEGIN`, `passphrase`, `private_key`, absolute home-directory paths, etc.).

- **Repo-size guardrail.** A docs-contract test rejects any file under `priv/viewer_evidence/` larger than a configurable byte budget (default ~64KB per file) — checklists that exceed this are almost certainly carrying inline binaries or pasted dumps.

**Warning signs:**
- An evidence file contains image syntax or HTML img tags.
- A PR adds binary files under `priv/viewer_evidence/`.
- An evidence file references a path under `/Users/<name>/...` or `C:\Users\<name>\...`.
- An evidence file's representative fixture uses a real-looking customer name or account number.
- Repo size grows by more than a few KB in the v2.3 milestone outside of fixture additions.

**Phase to address:**
- The recipe phase (defines text-only template, fixture-by-hash discipline, sanitization checklist).
- The schema-extension phase (adds docs-contract tests: no image syntax, no inline binaries, no operational-secret vocabulary, byte-budget enforcement).
- Every per-viewer recording phase (uses the template, references fixtures by hash).

---

## Technical Debt Patterns

Shortcuts that look reasonable during v2.3 but create long-term cost.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|---|---|---|---|
| Promote a row without `evidence:` because the checklist passed locally | Faster v2.3 close | Future operator cannot reproduce; matrix becomes lore-driven; downstream readers cannot audit | Never — promotion is gated on evidence file existence |
| Inline screenshot "just this once" | Convincing one-off proof | Repo bloat, PII risk, sets precedent that the next 20 evidence files follow | Never |
| Single shared `recorded_at` at the top of the matrix | Less typing | Cannot tell which row is stale; defeats Pitfall 2's whole purpose | Never — date is per-row |
| `deferred_reason: "see issue #N"` | Defers the writing burden | Issue may be closed / archived / private; reason is no longer self-contained in repo | Never — reasons live in the evidence file |
| Hand-edit `priv/support_matrix.json` without re-running the docs-contract test | Skips local test cycle | Subtle schema breakage that fails CI on push; or worse, fails silently if test wasn't updated | Only if the local docs-contract test passes; never when bypassing it |
| Reuse the v1.9 / v1.10 evidence template style without adding the new fields | Cheaper template churn | New rows pass current docs-contract but fail when the additive fields become required | Only during the schema-extension phase if the template is updated atomically |
| Bump `recorded_at` without re-running the checklist | Clears `mix viewer_evidence.audit` warnings | Stale evidence claims fresh recording — actively dishonest | Never |
| Add a viewer-evidence CI lane that calls a real viewer "just once for v2.3" | Stronger-looking proof | Browser/viewer dependency in CI conflicts with the no-browser-runtime constraint and with v2.3 scope | Never in v2.3; possibly v2.4 with explicit milestone scope |

## Integration Gotchas

Common mistakes when wiring v2.3 into the existing trust surfaces.

| Integration | Common Mistake | Correct Approach |
|---|---|---|
| `priv/support_matrix.json` consumers | Adding non-additive fields that break existing readers | Additive-and-optional only; existing keys/types unchanged; new keys gated by docs-contract test |
| `guides/api_stability.md` | Updating prose to imply broader viewer support than the matrix records | Prose mirrors matrix one-to-one; docs-contract test asserts every viewer claim in prose has a matching `status: supported` row with evidence |
| `signing-live-proof` CI lane (v2.1) | Treating viewer-evidence-schema lane as a substitute | Both required; schema lane is structural, signing lane is behavioral; both gate `main` |
| `long-lived-live-proof` CI lane (v2.2) | Folding LTV viewer behavior into the existing long-lived live proof | Live proof remains tool-based (pyHanko/pdfsig + certomancer); viewer-side LTV evidence stays in viewer evidence files; the two are not merged |
| Branch protection on `main` | Adding the new structural lane as required while accidentally relaxing an existing required lane | Audit phase explicitly verifies the required-check list grew, never shrunk |
| Phase-validation records | Recording viewer evidence in phase summaries and not in `priv/viewer_evidence/` | Evidence files live in `priv/viewer_evidence/` (canonical); phase summaries reference them, never duplicate them |

## Domain-Specific Security Mistakes

Security issues specific to a deterministic-PDF library publishing operator-recorded evidence.

| Mistake | Risk | Prevention |
|---|---|---|
| Screenshot leaks operational secrets in title bars / sidebars | Key paths or passphrases visible in committed evidence | Text-only evidence files; image syntax rejected by docs-contract test |
| Customer-shaped fixture committed as the "representative" PDF | PII in repo, potentially in plaintext or weakly protected | Sanitization checklist in recipe; fixtures use clearly-fictional content; PII linter on fixture filenames |
| Evidence file references an absolute home-directory path | Leaks operator identity / machine layout | docs-contract test rejects `/Users/...` and `C:\Users\...` strings in evidence files |
| Evidence quotes raw `pdfsig` / pyHanko stderr | Could include passphrase or key path text | Inherits v2.1/v2.2 redaction discipline; docs-contract test scans for forbidden tokens (`-----BEGIN`, `passphrase`, etc.) |
| Promotion based on an Acrobat trust-store-dependent indicator | Recorded "supported" in one operator's environment, "warning" in another's | Viewer evidence checklists explicitly exclude trust-UX checks; trust UX is not the surface (Pitfall 3) |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces. Each item links to the verifying check.

- [ ] **Promoted row has `recorded_at`** — verify field is present and date is within staleness threshold.
- [ ] **Promoted row has `viewer_version`** — verify field is present and pins a specific build.
- [ ] **Promoted row has `platform`** — verify field is present and pins OS + version + arch.
- [ ] **Promoted row has `evidence`** — verify field is present, path resolves, file parses against template.
- [ ] **Evidence file lists every behavior in `proof:`** — verify per-behavior table covers each declared `proof:` entry.
- [ ] **Every `PASS` / `FAIL` / `N/A` has a one-line reason** — verify no bare verdicts.
- [ ] **Failed / deferred row has `not_promoted_reason:` or `deferred_reason:`** — verify presence and absence of forbidden vocabulary.
- [ ] **Evidence file contains no image syntax or inline binary** — verify text-only.
- [ ] **Evidence file contains no operational-secret vocabulary** — verify against forbidden-token list.
- [ ] **Evidence file references fixture by checked-in path or content hash** — verify reproducibility from another operator's machine.
- [ ] **`signing-live-proof` is still required on `main`** — verify branch protection unchanged from v2.2.
- [ ] **`long-lived-live-proof` is still required on `main`** — verify branch protection unchanged from v2.2.
- [ ] **`viewer-evidence-schema` is required on `main`** — verify branch protection updated additively.
- [ ] **No new top-level key in `priv/support_matrix.json`** — verify scope guardrail.
- [ ] **No row family contains compliance / trust / multi-signature keys** — verify scope guardrail.
- [ ] **`guides/api_stability.md` prose matches matrix** — verify docs-contract test passes.
- [ ] **CHANGELOG records every promotion / re-validation** — verify temporal axis is visible to operators.

## Recovery Strategies

When pitfalls occur despite prevention.

| Pitfall | Recovery Cost | Recovery Steps |
|---|---|---|
| Overclaim promotion shipped | MEDIUM | Demote row to `unverified` with `not_promoted_reason:`; CHANGELOG entry; release patch version with corrected matrix; update `guides/api_stability.md` |
| Stale evidence detected post-release | LOW | Re-run checklist with current viewer; update `recorded_at` + `viewer_version` + evidence file; CHANGELOG re-validation entry |
| Schema regression breaks downstream reader | HIGH | Revert schema change; add docs-contract test that would have caught it; re-issue patch with additive-only correction |
| PII / secret leaked in evidence file | HIGH | Rewrite repo history to remove the file (acknowledged repo-rewrite cost); rotate any leaked secret; add docs-contract scan that would have caught it |
| Required CI lane accidentally removed | HIGH | Re-add to branch protection immediately; audit `main` for any merges since removal that would have failed the lane; CHANGELOG advisory |
| Scope crept into a v2.3 phase mid-execution | MEDIUM | Carve the crept work into a follow-on phase or defer to v2.4; trim v2.3 phase back to milestone non-goals; re-verify roadmap close-out gate |

## Pitfall-to-Phase Mapping

How v2.3 phases address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---|---|---|
| 1: Overclaim promotion | Each per-viewer recording phase + schema-extension phase | docs-contract test asserts row promotion only when evidence file lists every `proof:` behavior with named verb |
| 2: Viewer-version drift | Schema-extension phase + recipe phase | `mix viewer_evidence.audit` flags rows older than threshold; CHANGELOG discipline for re-validations |
| 3: Scope creep | Roadmap definition + every phase context + milestone-audit phase | Audit phase verifies no new top-level keys, no new row families, no new surfaces |
| 4: Schema coupling | Schema-extension phase | docs-contract tests: additive-only, no removed/renamed/retyped fields, no compliance/trust/multi-sig keys on viewer rows, evidence path resolves |
| 5: Reproducibility | Recipe phase + each per-viewer recording phase | Template enforces seven required fields; docs-contract test verifies template conformance |
| 6: Honest failure | Schema-extension phase + each per-viewer recording phase | docs-contract test: minimum-length reasons; forbidden-vocabulary list; named viewer or version in reason |
| 7: CI dilution | CI / live-proof phase + milestone-audit phase | New lane named `viewer-evidence-schema`; audit verifies `signing-live-proof` and `long-lived-live-proof` remain required; required-check list grew, never shrunk |
| 8: Storage / PII | Recipe phase + schema-extension phase | docs-contract: rejects image syntax, inline binaries, operational-secret vocabulary, files over byte budget |

## Sources

- `.planning/PROJECT.md` (Rendro project constraints, v2.3 active milestone definition, key decisions across v1.5–v2.2 — HIGH confidence, primary)
- `.planning/MILESTONE-ARC.md` (v2.3 candidate scope, non-goals, ordering logic — HIGH confidence, primary)
- `priv/support_matrix.json` (current schema shape, existing viewer-row vocabulary, existing `proof:` arrays — HIGH confidence, primary)
- `guides/api_stability.md` (existing docs language for forms / signing preparation / signed artifacts / long-lived evidence / embedded files / curated links / protection viewer posture — HIGH confidence, primary)
- `.planning/milestones/v2.2-MILESTONE-AUDIT.md` (precedent for required-check enforcement, audit-phase pattern, separation of `signing-live-proof` and `long-lived-live-proof` — HIGH confidence, primary)
- Existing v1.9 viewer-promotion precedent (Apple Preview `embedded_files` held at `unverified` despite Preview being supported for `links` on the same milestone) — HIGH confidence, primary; demonstrates per-surface independence
- Existing v1.10 viewer-promotion precedent (Apple Preview promoted for `protection` only after Phase 54 recorded checklist for version 11.0 on macOS 26.4.1) — HIGH confidence, primary; demonstrates version+platform discipline
- Apple Preview `/Sig` validation behavior (rendering without cryptographic validation) — MEDIUM confidence, widely documented community knowledge; treated as a deferral premise rather than a promoted claim
- PDF.js AcroForm appearance-stream behavior (renders authored appearance streams, edit/save round-trip is implementation-specific) — MEDIUM confidence, community knowledge; treated as a deferral premise
- PDFium substrate fragmentation across Chrome / Edge / WebView2 — MEDIUM confidence, community knowledge; informs the underspecification pitfall

---
*Pitfalls research for: v2.3 Viewer Proof & Interop Closure*
*Researched: 2026-05-08*
