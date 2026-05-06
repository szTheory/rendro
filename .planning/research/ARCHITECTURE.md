# Architecture: Rendro v1.10 Protected Delivery Hooks & Encryption Boundaries

**Domain:** Pure-Elixir deterministic PDF authoring; v1.10 adds a narrow protection story (external hooks first, native encryption gated).
**Researched:** 2026-05-06
**Overall confidence:** HIGH (grounded in actual file inspection of `lib/rendro/**`, `priv/support_matrix.json`, `PROJECT.md` Key Decisions, and `MILESTONE-ARC.md`).

This document recommends one coherent integration plan. Where the methodology lenses (Truthful Small Contracts, Boundary Validation First, Least Surprise DX) collapse multiple options into one, the recommendation is locked rather than presented as a menu, per `METHODOLOGY.md` "default synthesis style."

---

## 1. Recommended Pipeline Insertion Strategy

**Locked recommendation:** **Option B + Option C — external-hook-first as a post-pipeline transform on `%Rendro.Artifact{}`, exposed as a dedicated `Rendro.Protect` module plus an optional `Rendro.Adapters.Qpdf` boundary. Defer Option A (a `Rendro.Pipeline.Protect` stage) to a future, gated phase only if native AES encryption ships.**

### Why this shape and not the others

| Option | Why not now | Where it could fit later |
|--------|-------------|--------------------------|
| **A — new `Rendro.Pipeline.Protect` stage between `Render` and `Validate`** | Forces every render to traverse a protection seam even when no protection is requested. Conflicts with the locked Key Decision that the writer's allocation/build funnel "extends the existing seam" — encryption isn't another authored object kind, it transforms the entire byte stream and rewrites `/Encrypt`, the `/ID` array, and every string/stream object. Bolting that into core also breaks the "preserve the deterministic core pipeline as non-negotiable" Active Requirement, because once encryption is in-pipeline, the rendered binary's determinism contract has to become conditional. | Only if v1.10 actually ships native AES encryption (a Phase-53 gate). At that point a stage is cleaner than a writer hook because writer state stays focused on object emission, not crypto. Even then, the stage is only entered when `protect: [...]` is opted in at render time; default path stays unchanged. |
| **B — post-pipeline transform on `%Rendro.Artifact{}`** | This is the recommended primary path. | — |
| **C — optional adapter only (`Rendro.Adapters.Qpdf`)** | Recommended companion to B. The adapter does the actual external invocation; `Rendro.Protect` is the public seam that callers reach for. | — |

### How B + C compose

```
                       core pipeline (unchanged, deterministic)
                       +----------------------------------+
%Rendro.Document{}  -> | build->compose->measure->        | -> %Rendro.Artifact{}
                       | paginate->validate->render       |    (deterministic bytes,
                       +----------------------------------+     deterministic /ID)
                                                                       |
                                                                       v
                                              Rendro.Protect.password(artifact, opts)
                                                       (artifact-in, artifact-out)
                                                                       |
                                              +------------------------+------------------------+
                                              |                                                 |
                                              v                                                 v
                                  Rendro.Adapters.Qpdf                           [v1.10+, gated]
                                  (external binary, no                       Rendro.Protect.Native
                                   crypto in core)                          (in-process AES; opt-in)
```

### Justification against locked Key Decisions

- **"Preserve the core/adapter split even as operational features grow"** (PROJECT.md, Key Decisions). External hooks first respects this directly — `Qpdf` is a peer of `Poppler`, `Accrue`, `Mailglass`, all gated behind `Code.ensure_loaded?/1`-style boundaries (see `lib/rendro/adapters/accrue.ex:1` and `lib/rendro/adapters/mailglass.ex:1` for the established compile-time guard pattern).
- **"Extend the existing pipeline instead of creating an alternate rendering path"** (PROJECT.md, Constraints). B does not create an alternate rendering path: the rendered binary is unchanged. Protection is a *post-render transform*, not a new render. There is still one engine.
- **"Embedded files extend the existing writer allocation/build funnel; no inline serializer or separate PDF surface"** (Key Decisions, v1.9). This applied because embedded files are authored objects in the PDF body. Encryption is not — it rewrites the trailer and every string/stream after the body is built. Treating it as a transform on the artifact, not as an authored object, respects the same spirit (one authoring path) without forcing crypto into the writer.
- **MILESTONE-ARC.md v1.10 explicit guidance:** "External post-processing/enforcement hooks first" + "Native encryption only if demand is proven and non-deterministic output mode is accepted explicitly." B + C is the literal architectural shape of that arc rule.

### Determinism implication of this choice

The default `Rendro.render/2` path is byte-for-byte unchanged (`lib/rendro.ex:25`, `lib/rendro/pdf/writer.ex:1620-1629`). The deterministic `/ID` and trailer behavior shipped through v1.9 is preserved. Protection is something a caller *opts into* on the artifact, never something the engine adds invisibly.

---

## 2. Public API Shape

### 2.1 External-hook path (primary, v1.10 phases 51–52)

```elixir
# Module: Rendro.Protect (NEW)

@type permission :: :print | :modify | :copy | :annotate | :forms | :assemble | :print_high_res
@type permissions :: [permission()] | :none | :all

@type protect_opts :: [
  open_password: String.t(),       # password-to-open (user password)
  owner_password: String.t(),      # advisory permissions key (owner password)
  permissions: permissions(),       # advisory only; clearly documented as such
  algorithm: :aes_128 | :aes_256,  # via adapter capability check; default :aes_128 (v1.10)
  adapter: module()                 # default: Rendro.Adapters.Qpdf
]

@spec password(Rendro.Artifact.t(), protect_opts()) ::
        {:ok, Rendro.Artifact.t()} | {:error, Rendro.Error.t()}
def password(%Rendro.Artifact{} = artifact, opts)

# Convenience: render then protect (does NOT bake protection into the render call)
@spec render_protected(Rendro.Document.t(), [Rendro.render_option()], protect_opts()) ::
        {:ok, Rendro.Artifact.t()} | {:error, Rendro.Error.t()}
def render_protected(%Rendro.Document{} = doc, render_opts, protect_opts)
```

**Return contract (Least Surprise DX lens, METHODOLOGY.md):**

- Always returns `{:ok, %Rendro.Artifact{}} | {:error, %Rendro.Error{}}`. No raises, no naked binaries.
- The returned artifact is a *new* artifact: `binary` is the protected bytes, `hash` is `sha256(protected_bytes)`, `metadata` carries `:protection` (see §2.3).
- Validation errors for opts (e.g., missing both passwords, unsupported algorithm, adapter binary missing) return `{:error, %Rendro.Error{stage: :protect, reason: ...}}` with a NEW stage value `:protect` added to `Rendro.Error.from_stage/3` so the error envelope stays the existing one (`lib/rendro/error.ex:23`).

### 2.2 Native path (gated, deferred to Phase 53 — only if proof-backed)

```elixir
# Module: Rendro.Protect.Native (NEW, only ships if Phase 53 fires)
# Same opts surface as Rendro.Protect.password/2, but:
#   - `adapter:` is omitted (this IS the adapter)
#   - `:nondeterministic_output` MUST be explicitly true to opt in
#   - `:algorithm` constrained to :aes_128 in first ship; :aes_256 deferred
@spec password(Rendro.Artifact.t(), protect_opts()) ::
        {:ok, Rendro.Artifact.t()} | {:error, Rendro.Error.t()}
```

The native module is a peer adapter — it implements the same `Rendro.Protect` contract as `Rendro.Adapters.Qpdf`. Callers reach for `Rendro.Protect.password/2`; they don't dispatch directly to `Native`. This keeps the public seam stable across both paths.

### 2.3 Where do protection options live (render-call vs post-step)?

**Recommendation: post-step only on `%Rendro.Artifact{}`. Do NOT extend `Rendro.render/2` opts with `:protect`.**

Why:

- **Boundary Validation First lens.** The validate stage (`lib/rendro/pipeline/validate.ex:14`) walks authored document state. Protection options are not authored document state — they are a delivery-time concern attached to bytes after rendering. Putting them through `Rendro.render(doc, protect: [...])` would either (a) plumb protection through every stage that doesn't care about it, or (b) silently skip validation until very late. Both violate the lens.
- **Truthful Small Contracts lens.** Adding `:protect` to `render_options` widens the `Rendro.render/2` contract to imply that rendering and protection are one operation. They are not — protection is a separate trust contract that requires its own proof lane (Phase 52).
- **Two-step composition is symmetric with existing patterns.** `Rendro.render_to_artifact/2` already returns an `%Rendro.Artifact{}`. `Rendro.Adapters.Mailglass.attach_artifact/3` accepts an artifact. `Rendro.Storage.Local.put/2` accepts an artifact. `Rendro.Protect.password/2` taking an artifact slots into the same artifact-as-currency pattern.
- **Convenience is preserved** via `Rendro.Protect.render_protected/3` for callers who want one call site, but it is a thin composition of the two operations, not a third rendering path.

### 2.4 Where do passwords and permissions live so they don't leak?

This is the most security-sensitive boundary in v1.10. **Passwords MUST NOT enter:**

1. `%Rendro.Artifact{}.metadata` (returned to callers, possibly persisted via `Rendro.Storage`)
2. `%Rendro.Artifact{}.diagnostics` (developer-facing surface, often inspected)
3. `Rendro.Telemetry` events (forwarded to operators, often logged)
4. `Rendro.Audit.track_render/2` metadata (forwarded to external audit backends per `lib/rendro/audit.ex:22`)
5. `%Rendro.Error{}.details` (rendered into log lines via `String.Chars` impl at `lib/rendro/error.ex:138`)
6. Process state visible to `:sys.get_state/1` (Task ancestry from `lib/rendro/pipeline.ex:46`)

**Discipline (Least Surprise DX + Truthful Small Contracts):**

- **Never store password binaries on the artifact.** `metadata.protection` carries only:
  ```elixir
  %{
    protected: true,
    algorithm: :aes_128,           # public — what the file uses
    adapter: Rendro.Adapters.Qpdf, # public — who wrapped it
    has_open_password: true,       # boolean only
    has_owner_password: true,      # boolean only
    permissions_advised: [:print], # public — encoded in the PDF anyway
    deterministic: false           # see §3
  }
  ```
- **Telemetry envelope for the new `:protect` stage** (mirror of `lib/rendro/pipeline.ex:131` span shape): `%{render_id, stage: :protect, status, byte_size, algorithm, adapter, has_open_password: bool, has_owner_password: bool}`. No password fields, by construction.
- **Error redaction.** `Rendro.Error.from_stage(:protect, reason, ctx)` for protection failures must scrub opts before placing them in `details:`. Adopt a small `Rendro.Protect.Opts.redact/1` helper that returns a public-safe summary, used in every error and telemetry path.
- **External-adapter handoff.** The `Qpdf` adapter receives the password via `System.cmd/3` argv. Argv leaks to other processes on shared hosts. Mitigation: pass passwords through the qpdf `@argfile` mechanism (a temp file written 0600, deleted on exit) rather than direct argv. Document this constraint as part of the adapter's truthful contract; it is a known-narrow public claim, not a security guarantee.
- **GC reachability.** Erlang refc binaries can persist in process heaps. After protection, replace the password local with `:crypto.strong_rand_bytes(byte_size(pw))` style overwrite where feasible. This is a best-effort hardening, not a guarantee — call it out explicitly in `guides/api_stability.md` so the public claim stays truthful.

---

## 3. Determinism Strategy

### 3.1 Existing `/ID` behavior (v1.0–v1.9, verified in code)

The writer already emits a deterministic `/ID` array when `deterministic: true`:

```elixir
# lib/rendro/pdf/writer.ex:1620-1629
deterministic? = Keyword.get(opts, :deterministic, false)

id_entry =
  if deterministic? do
    content_hash = :crypto.hash(:md5, IO.iodata_to_binary(body_parts))
    id_hex = {:hex_string, content_hash}
    [{"ID", {:array, [id_hex, id_hex]}}]
  else
    []
  end
```

Both elements of `/ID` are the same MD5 of the concatenated body objects. **This is exactly what PDF encryption uses as crypto input** (per the PDF spec: the file ID is mixed into the password-to-key derivation; AES-CBC IVs are typically random per-string/per-stream).

So the v1.10 starting point is good: a deterministic, content-addressed file ID already exists. v1.10 does not need to introduce one. It needs to *propagate* it correctly into the protection step.

### 3.2 Crypto-determinism reality check

For external-hook adapters (qpdf and similar): the encrypted output is **non-deterministic by default** because:

1. AES-CBC IVs are randomly generated per object/stream by default.
2. qpdf does have `--static-aes-iv` for testing, but the maintainers explicitly mark it as test-only and security-weakening (see Sources). It MUST NOT be the Rendro default.
3. Even with a static IV, qpdf does not guarantee byte-for-byte stability across qpdf versions.

For native AES (gated): same constraint. The IV is per-object per-encryption; reusing it under the same key reveals plaintext relationships (catastrophic for streams that share prefixes — e.g., similar pages).

### 3.3 Locked decision

**Default: encrypted output is explicitly non-deterministic.** The unencrypted artifact remains deterministic. Encryption is a separate post-step whose output is documented as non-deterministic, and the artifact metadata says so.

**Opt-in deterministic-encryption mode is NOT offered in v1.10.** Reasons:

1. The cryptographic-weakening disclaimer would be hard to surface convincingly to callers who only read auto-completed opt names.
2. It would create a surface where two artifacts with the same `:deterministic` flag have wildly different security properties. That violates Least Surprise DX hard.
3. v1.10's locked Active Requirement is "preserve the existing deterministic core pipeline" — not "make encryption deterministic too."
4. Callers needing reproducible encrypted bytes for caching/dedup can hash the *unencrypted* artifact (still deterministic) and cache by that key, then re-encrypt on demand. The architecture supports this directly because the unencrypted artifact is preserved as a separate value.

The metadata flag makes the boundary explicit:

```elixir
%Rendro.Artifact{
  binary: <<encrypted_bytes>>,
  hash: "sha256-of-encrypted-bytes",  # changes every call
  metadata: %{
    protection: %{
      protected: true,
      deterministic: false,             # <-- the truth
      ...
    },
    deterministic: false                # top-level mirrors protection-disabled determinism
  }
}
```

`Rendro.render_to_artifact(doc, deterministic: true)` followed by `Rendro.Protect.password(...)` should:

1. Preserve the inner deterministic hash of the unencrypted artifact in `metadata.protection.source_hash` (only if explicitly opted in via `:retain_source_hash` to avoid plaintext-byte-equivalence side channels).
2. Mark `metadata.deterministic = false` on the outer protected artifact, since its bytes are not deterministic.
3. Document this explicitly in `guides/api_stability.md` under a new "Protected Artifact Determinism Posture" section.

### 3.4 `/ID` array under encryption

When the protection adapter rewrites the trailer, it MUST preserve the `/ID` array bit-for-bit if the input artifact was rendered with `deterministic: true`. qpdf does this when given a deterministic input ID, but not all external tools do — the adapter must validate post-encryption that `/ID[0]` from the input equals `/ID[0]` of the output, and fail with `{:error, ... :id_drift}` if it does not. This is a small but important boundary check that keeps the deterministic content-addressing story coherent across the protection seam.

---

## 4. Boundary Preservation

### 4.1 Optional-adapter boundary

`Rendro.Adapters.Qpdf` (NEW) follows the established `Code.ensure_loaded?/1` or `System.find_executable/1` guard pattern (see `lib/rendro/adapters/poppler.ex:14` for the executable form, or `lib/rendro/adapters/accrue.ex:1` for the compile-time form). qpdf is an external binary, so the Poppler-style runtime guard is the right shape:

```elixir
defmodule Rendro.Adapters.Qpdf do
  @moduledoc "External binary adapter for qpdf-based PDF protection."

  @behaviour Rendro.Protect.Adapter   # NEW behaviour, see §6

  @impl true
  def password_protect(%Rendro.Artifact{} = artifact, opts) do
    case System.find_executable("qpdf") do
      nil -> {:error, {:missing_executable, "qpdf"}}
      executable -> do_protect(executable, artifact, opts)
    end
  end
end
```

Critically: **qpdf MUST NOT become a hard dependency of `:rendro`.** It is a peer of Poppler — present-or-absent at runtime, with `{:missing_executable, "qpdf"}` returned when absent. `mix.exs` is not modified.

### 4.2 Validate-stage boundary

Per the Boundary Validation First lens and per the Key Decision "Embedded-file metadata is validated in `Rendro.Pipeline.Validate` with tuple errors, not registration-time exceptions" (PROJECT.md), protection-option validation must use the same tuple-error envelope. But there is a wrinkle: protection is post-pipeline, so it does not run inside `Rendro.Pipeline.Validate` (`lib/rendro/pipeline/validate.ex`).

**Resolution:**

- **Authored protection state on the document is NOT introduced** in v1.10. Protection is purely a post-render concern. The validate stage stays unchanged. This is a deliberate narrowing — adding `Rendro.Document.set_protection/2` would put us right back into Option A territory.
- **`Rendro.Protect.password/2` validates its opts at the public boundary** before invoking any adapter, returning typed tuples. New error tuples (Phase 51 contract):
  - `{:error, %Rendro.Error{stage: :protect, reason: :no_passwords_supplied}}`
  - `{:error, %Rendro.Error{stage: :protect, reason: {:unsupported_algorithm, term}}}`
  - `{:error, %Rendro.Error{stage: :protect, reason: {:invalid_permissions, term}}}`
  - `{:error, %Rendro.Error{stage: :protect, reason: {:missing_executable, "qpdf"}}}`
  - `{:error, %Rendro.Error{stage: :protect, reason: {:adapter_failure, exit_code, redacted_output}}}`
  - `{:error, %Rendro.Error{stage: :protect, reason: :id_drift}}`
- `Rendro.Error.from_stage/3` gains a `:protect` stage clause (`lib/rendro/error.ex:23`) with `what/where/why/next` text.

### 4.3 Support-matrix boundary

`priv/support_matrix.json` already encodes per-surface, per-viewer claims (`forms`, `embedded_files`, `links`). v1.10 adds a `protection` top-level key with the same shape:

```json
"protection": {
  "modes": {
    "external_password_to_open": "supported",
    "external_advisory_permissions": "supported",
    "native_password_to_open": "unsupported",
    "native_advisory_permissions": "unsupported",
    "compliance_pdf_a": "unsupported",
    "compliance_pdf_ua": "unsupported",
    "digital_signature": "unsupported"
  },
  "adapters": {
    "qpdf": {
      "status": "supported",
      "min_version": "11.0",
      "proof": ["password_to_open_blocks_open", "owner_password_unlocks_permissions"]
    }
  },
  "viewers": {
    "adobe_acrobat_reader": {
      "status": "unverified",
      "proof": ["prompt_for_password", "open_with_correct_password",
                "reject_wrong_password", "permissions_observed"]
    },
    "apple_preview": { "status": "unverified", "proof": [/* same shape */] }
  }
}
```

Phase 53 (gated) flips `native_password_to_open` from `unsupported` to `supported` only after structural proof and viewer evidence is recorded.

The `unsupported` array gains entries to make the narrowing truthful:

```json
"unsupported": [
  "full_pdf_compliance",
  "digital_signatures",
  "pdf_permissions_as_security_guarantee",   // NEW in v1.10
  "encryption_determinism"                    // NEW in v1.10
]
```

That last entry is the public truth for §3.3 — encryption output is non-deterministic.

### 4.4 Documentation honesty boundary

`guides/api_stability.md` gains a new section "Protection Support Boundary" mirroring the existing "Embedded Files Support Boundary" tone:

- Password-to-open is supported via the external-adapter path with recorded proof.
- Advisory permissions are encoded in the file but explicitly NOT a security guarantee — they signal viewer intent, nothing more.
- Encryption output is non-deterministic by design; the unencrypted artifact remains deterministic.
- Native encryption is `unsupported` until Phase 53 ships with proof.

Also, `mix docs.contract` (the existing docs contract task at `lib/mix/tasks/docs.contract.ex`) gains assertions over the new section so docs cannot drift from `priv/support_matrix.json`.

---

## 5. Phase Decomposition for v1.10

Five phases, ordered to maximize early-shippability. **Phase 51 + Phase 52 are sufficient to close v1.10 as "external-hooks-only" if Phase 53 demand-gating fails.** This makes v1.10 shippable on either of two endpoints, satisfying the MILESTONE-ARC rule "Native encryption only if demand is proven."

### Phase 51 — Public Protection API + Qpdf Adapter Contract

**Goal:** Land the `Rendro.Protect` public seam, the `Rendro.Protect.Adapter` behaviour, and the `Rendro.Adapters.Qpdf` implementation. No proof-backed claims yet — adapter present, error tuples typed, opts validated.

**Inputs:** v1.9 milestone close state. No new authored document fields. No changes to writer, validate, render, or pipeline modules.

**Outputs:**
- `lib/rendro/protect.ex` (NEW) — public API.
- `lib/rendro/protect/adapter.ex` (NEW) — `@callback password_protect/2`.
- `lib/rendro/protect/opts.ex` (NEW) — opts normalization, password redaction.
- `lib/rendro/adapters/qpdf.ex` (NEW) — implements the behaviour.
- `lib/rendro/error.ex` (MODIFIED) — add `:protect` stage clauses.
- `lib/rendro/artifact.ex` (MODIFIED) — `metadata.protection` map shape documented in `@moduledoc`; struct itself unchanged.
- Tests under `test/rendro/protect/` (NEW).

**Dependencies:** None upstream. This is the foundation phase.

**Shippability:** Yes — closes a meaningful slice (callers can password-protect artifacts via qpdf with typed errors) even if Phases 52–54 do not ship.

### Phase 52 — Poppler Validation Lane for Protected PDFs + Support-Matrix Wiring

**Goal:** Extend the existing `Rendro.Adapters.Poppler` proof lane to validate that password-protected PDFs reject access without the user password and accept with it. Publish the protection-support contract in `priv/support_matrix.json` and `guides/api_stability.md`. Record manual viewer evidence for at least one viewer (Apple Preview is the cheapest first proof; Adobe Acrobat Reader is the second).

**Inputs:** Phase 51 outputs.

**Outputs:**
- `lib/rendro/adapters/poppler.ex` (MODIFIED) — `validate/2` accepts an optional `password:` arg and a `:protected_negative` mode that asserts protection actually rejects bare access. (See `lib/rendro/adapters/poppler.ex:14` for the current shape.)
- `priv/support_matrix.json` (MODIFIED) — new `protection` block, see §4.3.
- `guides/api_stability.md` (MODIFIED) — new "Protection Support Boundary" section.
- `lib/mix/tasks/docs.contract.ex` (MODIFIED) — assertions for the new section.
- `lib/mix/tasks/verify.ex` (MODIFIED) — add a "Protected Artifact Proof" step inside the deterministic core lane that runs the negative-validation case (verifies that an unprotected pdf is openable, a protected one is not, and the protected one opens with `password:`).
- Recorded viewer-evidence checklist for at least one viewer.

**Dependencies:** Phase 51. Can begin in parallel with Phase 51 only on docs/matrix shape design; implementation must wait until 51's API stabilizes.

**Shippability:** Yes — this is the closure point for "external-hooks-only" v1.10. After this phase, the milestone has a truthful, proof-backed protection story.

### Phase 53 — Native AES-128 Encryption (GATED on demand + accepted non-determinism)

**Goal:** Add an in-process AES-128 encryption adapter (`Rendro.Protect.Native`) that implements `Rendro.Protect.Adapter`. Explicitly opt-in via `adapter: Rendro.Protect.Native, accept_nondeterministic_output: true`. The default `Rendro.Protect.password/2` call still uses qpdf.

**Inputs:** Phase 51 (the behaviour + public API). Phase 52 (the proof lane). External demand signal that the milestone-gate accepts.

**Outputs:**
- `lib/rendro/protect/native.ex` (NEW) — implements the adapter behaviour using `:crypto`.
- `lib/rendro/pdf/writer.ex` (MODIFIED, narrowly) — expose a small read-only API surface (`object_offsets/1`, `body_iodata/1`, `id_array/1`) so the native adapter can rewrite the trailer and inject `/Encrypt` without re-implementing object emission. NO encryption logic enters writer.ex.
- `priv/support_matrix.json` (MODIFIED) — `native_password_to_open` flips from `unsupported` to `supported` IF proof is recorded.
- Optional: `lib/rendro/pipeline.ex` (MODIFIED) — only if a future caller wants protection inside the same render call. Not required for Phase 53 itself; can be deferred to a later milestone.

**Dependencies:** Phase 51 + Phase 52. Strictly sequential after both.

**Shippability:** Independent. Can be skipped entirely if demand-gate fails — v1.10 closes at the end of Phase 52 with an explicit "native encryption deferred" note.

### Phase 54 — Support-Boundary Closure & Proof Documentation

**Goal:** Close the milestone with one truthful support contract spanning external + native (if 53 shipped). Add a second viewer's proof checklist. Capture the milestone audit.

**Inputs:** Phases 51, 52, and (optionally) 53.

**Outputs:**
- `priv/support_matrix.json` (MODIFIED) — final viewer rows, final adapter rows.
- `guides/api_stability.md` (MODIFIED) — viewer posture section finalized.
- `.planning/v1.10-MILESTONE-AUDIT.md` (NEW).
- Phoenix example or recipe added under `lib/rendro/recipes/` if it would clarify the call-site shape (optional).

**Dependencies:** Phase 52 minimum; Phase 53 if it shipped.

**Shippability:** Closes the milestone. Always required.

### Parallelism summary

| Pair | Parallel? | Why |
|------|-----------|-----|
| Phase 51 ↔ Phase 52 | Partially — 52 design (matrix shape, docs section) can begin in parallel with 51 implementation; 52 implementation cannot. | 52 implementation depends on 51's stable API. |
| Phase 51 ↔ Phase 53 | No | 53 depends on the behaviour Phase 51 introduces. |
| Phase 52 ↔ Phase 53 | Yes, after 51 closes | They edit largely disjoint files. The Poppler lane and the native adapter do not collide. |
| Phase 51/52/53 ↔ Phase 54 | No | 54 audits the others. |

### Strict sequence (minimum viable order)

```
51 -> 52 -> [53 optional, gated] -> 54
```

### Early-shippable endpoints

- **Endpoint A (external-hooks-only):** 51 -> 52 -> 54. Closes v1.10 with no native encryption. Matches MILESTONE-ARC.md guidance directly.
- **Endpoint B (native opt-in shipped):** 51 -> 52 -> 53 -> 54. Same shape, with the gated native option proven and documented.

---

## 6. Modified vs New File Inventory

### NEW files

| File | Purpose | First Phase |
|------|---------|-------------|
| `lib/rendro/protect.ex` | Public protection API (`password/2`, `render_protected/3`). | 51 |
| `lib/rendro/protect/adapter.ex` | `@behaviour` defining `password_protect/2` for adapters. | 51 |
| `lib/rendro/protect/opts.ex` | Opts normalization, validation, redaction. Used by every `:protect` stage error. | 51 |
| `lib/rendro/adapters/qpdf.ex` | Optional external-binary adapter; mirrors `Rendro.Adapters.Poppler` shape. | 51 |
| `lib/rendro/protect/native.ex` | Optional in-process AES adapter (gated). | 53 |
| `test/rendro/protect/protect_test.exs` | Public API tests, opts validation, error envelopes. | 51 |
| `test/rendro/adapters/qpdf_test.exs` | Adapter behaviour tests; skips when qpdf absent. | 51 |
| `test/rendro/protect/native_test.exs` | Native adapter tests (gated). | 53 |
| `.planning/v1.10-MILESTONE-AUDIT.md` | Milestone close artifact. | 54 |

### MODIFIED files

| File | Change | First Phase |
|------|--------|-------------|
| `lib/rendro/error.ex` | Add `:protect` stage in `from_stage/3`, plus `what/why/next` clauses for each new reason atom. | 51 |
| `lib/rendro/artifact.ex` | Document `metadata.protection` map shape in `@moduledoc`. Struct fields unchanged (preserves backward compatibility). | 51 |
| `lib/rendro/adapters/poppler.ex` | Accept `password:` opt and `:protected_negative` mode; assert encrypted PDFs reject bare access. | 52 |
| `priv/support_matrix.json` | Add `protection` block; extend `unsupported` array. | 52 |
| `guides/api_stability.md` | Add "Protection Support Boundary" + "Protected Artifact Determinism Posture" sections. | 52 |
| `lib/mix/tasks/docs.contract.ex` | New assertions for protection sections + matrix keys. | 52 |
| `lib/mix/tasks/verify.ex` | Add "Protected Artifact Proof" step in the deterministic core lane. | 52 |
| `lib/rendro/pdf/writer.ex` | NARROW change: expose read-only helpers for trailer/body offsets so the native adapter can rewrite the trailer without owning crypto. NO crypto logic in writer. Skipped entirely if Phase 53 does not ship. | 53 |

### NOT modified (verified)

- `lib/rendro/pipeline.ex` — pipeline orchestration unchanged in 51/52/54. Optional touch in 53 only if a later milestone wires protection into a render-call opt; v1.10 explicitly does not do this.
- `lib/rendro/pipeline/validate.ex` — no new authored document state, no new validate rule. The existing `@default_rules` list stays at 6 rules (`lib/rendro/pipeline/validate.ex:14-21`).
- `lib/rendro.ex` — public top-level API unchanged. `Rendro.Protect.password/2` is the new namespace; no `Rendro.protect/2` shim added (preserves Truthful Small Contracts — protection is a separate seam, not a top-level verb).
- `lib/rendro/document.ex` (and `Rendro.Document.t()` shape) — no protection field on the document. Confirms the §4.2 narrowing decision.
- `mix.exs` — no new hard deps. qpdf is a runtime executable, not a hex package.

---

## 7. Determinism Implications, Layer by Layer

| Layer | v1.9 behavior | v1.10 behavior | Implication |
|-------|---------------|----------------|-------------|
| `Rendro.render(doc, deterministic: true)` | Byte-deterministic. `/ID` is MD5 of body. | **Unchanged.** | Default path stays deterministic. |
| `Rendro.render_to_artifact/2` | Returns deterministic artifact when `deterministic: true`. | **Unchanged.** | Same. |
| `Rendro.Protect.password(artifact, opts)` | n/a | Returns NON-deterministic artifact (different bytes per call). `metadata.protection.deterministic = false`. | New seam, explicitly non-deterministic. Documented. |
| `/ID` array under encryption | n/a | Preserved bit-for-bit from input artifact. Adapter validates `/ID[0]` survives. Returns `:id_drift` error if not. | Content-addressing still works on the input artifact's hash; protected output is keyed by encryption per call. |
| `metadata.deterministic` on the artifact | True iff rendered with `deterministic: true`. | Top-level mirrors `protection.deterministic` (false) for protected artifacts. | One truthful flag, no ambiguity. |
| `Rendro.Audit` events | Carry `deterministic: bool`. | Add `protection: %{algorithm, adapter, has_open_password: bool, has_owner_password: bool}` (no passwords). | Operators see protection happened; auditors do not see secrets. |
| `Rendro.Telemetry` `:protect` stage | n/a | New stage span; same envelope shape as `:render`. | Operability stays consistent across the pipeline + protect seam. |

---

## 8. What Could Bite Later (and what to flag for the roadmap)

1. **PDF/A and PDF/UA pressure.** The moment encryption ships, downstream callers will ask "now make it PDF/A too." Compliance is already in `unsupported` (`priv/support_matrix.json:107`). Phase 52's docs section must reaffirm this so the support contract does not silently widen.
2. **Per-recipient encryption.** Some downstream patterns want the same document encrypted with different passwords per recipient. The artifact-in/artifact-out shape supports this naturally (call `Rendro.Protect.password/2` once per recipient on the same source artifact). No architectural change needed, but worth noting for the v1.10 example/recipe.
3. **Signature interaction (v2.0).** Signing wraps the *protected* bytes if both apply. The MILESTONE-ARC.md sequence has signatures after encryption, which is correct: signing-on-protected is well-defined; protecting-on-signed invalidates the signature. Phase 53's writer-API exposure (read-only offsets) anticipates the signing-prep path without committing to it. No coupling in v1.10.
4. **qpdf ABI/version drift.** The Poppler adapter does not pin a version; qpdf adapter needs the same posture but with one defensive check: `qpdf --version` parsed at first call, with `:unsupported_qpdf_version` returned for known-bad versions. Cheaper than chasing per-version output drift.
5. **Argv leakage.** The `@argfile` mitigation (§2.4) is the right call but it adds a temp-file dependency. Document this as a known-narrow boundary, not a security guarantee.

---

## Sources

- Inspected: `/Users/jon/projects/rendro/.planning/PROJECT.md` (Key Decisions, Constraints, Active requirements for v1.10).
- Inspected: `/Users/jon/projects/rendro/.planning/MILESTONE-ARC.md` (v1.10 candidate scope, non-goals, arc rules).
- Inspected: `/Users/jon/projects/rendro/.planning/METHODOLOGY.md` (Truthful Small Contracts, Boundary Validation First, Least Surprise DX, default synthesis style).
- Inspected: `/Users/jon/projects/rendro/lib/rendro.ex`, `/Users/jon/projects/rendro/lib/rendro/pipeline.ex`, `/Users/jon/projects/rendro/lib/rendro/pipeline/validate.ex`, `/Users/jon/projects/rendro/lib/rendro/pipeline/render.ex`, `/Users/jon/projects/rendro/lib/rendro/artifact.ex`, `/Users/jon/projects/rendro/lib/rendro/error.ex`, `/Users/jon/projects/rendro/lib/rendro/audit.ex`, `/Users/jon/projects/rendro/lib/rendro/storage.ex`, `/Users/jon/projects/rendro/lib/rendro/storage/local.ex`, `/Users/jon/projects/rendro/lib/rendro/adapters/poppler.ex`, `/Users/jon/projects/rendro/lib/rendro/adapters/accrue.ex`, `/Users/jon/projects/rendro/lib/rendro/adapters/mailglass.ex`, `/Users/jon/projects/rendro/lib/rendro/pdf/writer.ex` (lines 1463-1485, 1600-1678 — deterministic `/ID` behavior verified), `/Users/jon/projects/rendro/lib/rendro/rules/check_embedded_files.ex`, `/Users/jon/projects/rendro/priv/support_matrix.json`, `/Users/jon/projects/rendro/guides/api_stability.md`, `/Users/jon/projects/rendro/lib/mix/tasks/verify.ex`.
- [PDF Encryption — qpdf 12.3.2 documentation](https://qpdf.readthedocs.io/en/stable/encryption.html)
- [qpdf encryption manual on GitHub](https://github.com/qpdf/qpdf/blob/main/manual/encryption.rst)
- [qpdf issue #144: Encryption with 256-bit key](https://github.com/qpdf/qpdf/issues/144)
- [qpdf discussion #530: Question about security of encrypted pdf files](https://github.com/qpdf/qpdf/discussions/530)
