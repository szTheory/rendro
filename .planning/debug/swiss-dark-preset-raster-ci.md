---
status: resolved
trigger: "authorize-scoped-swiss-dark-investigation"
created: 2026-08-20
updated: 2026-08-20
---

# Debug Session: Swiss/Dark Preset Raster CI

## Symptoms

### Expected behavior

The authorized exact-SHA launch CI run installs the SHA-verified pinned PDFium v0.11.0 binary, passes the preset raster snapshot lane, executes the Phase 130 launch generation/check steps, and uploads the exact provenance-bound launch artifact.

### Actual behavior

CI run `32373206387`, advisory job `96438328454`, installed the required pinned PDFium binary successfully but failed at `Run Preset Raster Snapshot Tests` on the `swiss/dark` reference mismatch. Phase 130 candidate generation, launch checks, and artifact upload were skipped.

### Error messages

Preset raster snapshot mismatch for `swiss/dark`; no launch artifact was produced. Exact failure output and old/new artifact identities must be recovered from the immutable run/job evidence.

### Timeline

Observed on 2026-08-20 while continuing Phase 130 Plan 130-08 from an explicitly authorized exact-SHA CI checkpoint. The failure was described by the executor as pre-existing and occurred before Phase 130-specific generation steps.

### Reproduction

Use ref `gsd/phase-130-catalog-review-f8ee18d3d6504b3f4db58289efe1c6a5d178c419`, commit `f8ee18d3d6504b3f4db58289efe1c6a5d178c419`, CI run `32373206387`, and advisory job `96438328454`. Required PDFium v0.11.0 binary SHA-256 is `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a`.

## Scope Constraints

- Diagnose only unless a fix is provably safe and entirely within the already authorized investigation boundary.
- Do not bless or modify any raster reference, golden, launch artifact, catalog score, rubric evidence, or SIGN-OFF record.
- Do not bypass, reorder, weaken, or skip the preset-raster CI gate.
- Preserve the Phase 130 detached staging worktree and its exact two authorized golden changes.
- If a reference change may be legitimate, report exact old/new hashes, cause, affected paths, and required human-review evidence before any mutation.
- Any code or reference change creates a new commit identity and therefore requires fresh exact-SHA launch-CI authorization.

## Current Focus

hypothesis: confirmed — `704a58b` changed the theme-enabled Certificate body used by the `swiss/dark` snapshot, while its reference stayed at the pre-change `95e8…` value; the mismatch requires both the behavioral source change and the missing reviewed reference lifecycle
test: compare the exact CI failure, pin verification, commit-path history, and exact exercised branch; attempt an isolated matching-platform replay solely to recover the withheld actual hash
expecting: source/reference divergence explains the deterministic assertion, while the isolated replay is only needed to derive a candidate reference value for later human review
next_action: complete — authorized canonical Swiss/dark reference transitioned and focused host-available contracts passed; obtain fresh exact-SHA launch-CI authorization before any launch run
bug_class: bohrbug
reasoning_checkpoint:
  hypothesis: "The themed-certificate reorder in 704a58b invalidated the swiss/dark preset-raster reference because no later commit updated priv/raster_refs/presets/swiss/dark.sha256."
  confirming_evidence:
    - "CI job 96438328454 verified the exact PDFium SHA/version, then failed solely on the swiss/dark hash assertion."
    - "The failure's matrix row renders Certificate with a supplied swiss/dark theme, and 704a58b changes that exact theme-enabled branch after f0b8b0b's last reference update."
    - "From f0b8b0b through f8ee18d, certificate.ex changed once (704a58b) and swiss/dark.sha256 did not change."
  falsification_test: "Run the exact f8ee18d source on Linux with the SHA-verified PDFium binary and observe a PNG hash equal to the committed 95e8… reference."
  fix_rationale: "A separately authorized raster-review lifecycle must regenerate and human-review the reference after any intentional behavioral change to the tested renderer input; changing CI or the assertion would only hide the divergence."
  blind_spots: "The immutable CI log does not print the actual PNG hash, and this host's amd64 Linux Erlang container cannot execute Mix under Rosetta emulation; no exact replacement hash is proven."
  candidate_causes:
    - "code: 704a58b reorders the themed Certificate body used by swiss/dark."
    - "data: the committed swiss/dark reference was not refreshed after that behavior change."
    - "environment: PDFium binary/version drift was ruled out by the job's pin assertions before rendering."
  and_gate: "yes — the mismatch appears only when the changed themed-certificate code is evaluated against the unchanged pre-change reference."
tdd_checkpoint:

## Evidence

- timestamp: 2026-08-20
  checked: persisted debug-session state and required debugger guidance
  found: the failure is constrained to an exact-SHA advisory CI job, after successful pinned PDFium installation and before Phase 130 launch steps; no raster or launch mutation is authorized
  implication: investigate as a deterministic CI/preset-raster mismatch using immutable evidence and local comparisons only

- timestamp: 2026-08-20
  checked: local debug knowledge base and immutable run metadata for 32373206387 / 96438328454
  found: no knowledge base exists; the job checked out the stated SHA, successfully installed the pinned renderer, passed the non-preset raster lane, and failed only `Run Preset Raster Snapshot Tests`; all subsequent Phase 127/130/launch/artifact steps were skipped
  implication: no known-pattern candidate applies; the failure is isolated to the preset snapshot lane rather than CI setup, PDFium installation, or Phase 130 generation

- timestamp: 2026-08-20
  checked: failed-step log and exact-SHA snapshot test/matrix/reference/pin
  found: the sole failure is the `swiss_certificate_dark` matrix row (certificate recipe, `:swiss`, `:dark`) at the hash assertion; the committed expected hash is `95e8bf26c2dea691f400d0115c53d6047402205e1c8e78953c282ae724702b1d`, while the test proves the PDFium binary SHA and version before rendering but does not print the actual image hash
  implication: this is a deterministic Bohrbug in the reference-versus-rendered-byte contract; next evidence must recover the actual hash and trace reference freshness, not investigate CI orchestration or renderer provenance

- timestamp: 2026-08-20
  checked: local bounded review PNG, complete `swiss/dark` reference history, and the last reference-refresh commit
  found: `tmp/rendro_preset_raster_review/swiss_certificate_dark_page_1.png` hashes to `00794cc7346687f91dab250fc5a49937fedeab6134fdaffb5e6495bc85f44bdf`, exactly the immediately preceding committed reference value; `f0b8b0b` changed it to `95e8bf26c2dea691f400d0115c53d6047402205e1c8e78953c282ae724702b1d` while its diff contained launch assets and reference updates, no rendering implementation
  implication: stale/incorrect-reference is strongly supported, but an isolated exact-SHA replay is still needed because the local review PNG's provenance is not independently bound to run 32373206387

- timestamp: 2026-08-20
  checked: relevant-path diff from the reference refresh through f8ee18d
  found: f0b8b0b itself changed no renderer/test input paths, but f8ee18d includes `lib/rendro/recipes/certificate.ex` from `704a58b` after the reference refresh; no CI run is recorded for f0b8b0b, so its updated reference was never independently validated by this CI lane
  implication: the leading root-cause branch is a code/reference synchronization gap (post-refresh certificate rendering change without a corresponding reviewed reference update); the exact diff and replay can confirm or refute it

- timestamp: 2026-08-20
  checked: complete `704a58b` certificate diff and local runtime compatibility
  found: the commit moves the recipient ahead of title/certification whenever a theme is supplied; `swiss/dark` exercises that branch. The local host runs the same Elixir/OTP as CI but cannot execute CI's Linux-amd64 PDFium binary natively
  implication: host replay would be confounded by platform incompatibility; a disposable Linux-container replay is the falsification test for both the stale-reference and renderer-environment hypotheses

- timestamp: 2026-08-20
  checked: first disposable Linux-container replay setup and historical CI availability
  found: the container downloaded and SHA-verified the required PDFium binary, but its non-TTY Erlang process failed in `prim_tty` before `mix deps.get` or the test could run; no CI runs exist for either the reference-refresh commit or the later certificate-change commit
  implication: the attempted replay neither supports nor refutes the root-cause hypothesis; retry with a TTY is a single environment correction, while missing historical CI validation reinforces the reference-synchronization gap

- timestamp: 2026-08-20
  checked: TTY replay retry and local-review provenance
  found: the retry again SHA-verified PDFium but Erlang failed in `prim_tty` under this host's amd64/Rosetta emulation before Mix; the only local Swiss-dark review PNG hashes to `00794…` but its timestamps are 2026-08-16, before both f0b8b0b's reference refresh and 704a58b's certificate change
  implication: no exact replacement value is safe to report or apply. The confirmed diagnosis is the code-plus-reference lifecycle gap; the exact candidate hash must be recovered by a fresh authorized Linux CI render with human review

## Eliminated

## Resolution

root_cause: "AND-gate: commit 704a58b changed the theme-enabled Certificate body used by the swiss/dark preset snapshot, while priv/raster_refs/presets/swiss/dark.sha256 remained at f0b8b0b's pre-change expected hash (95e8bf26c2dea691f400d0115c53d6047402205e1c8e78953c282ae724702b1d). The exact pinned CI renderer therefore deterministically produces bytes that do not match the stale reference."
fix: "Applied the explicitly authorized one-file canonical transition in priv/raster_refs/presets/swiss/dark.sha256 from 95e8bf26c2dea691f400d0115c53d6047402205e1c8e78953c282ae724702b1d to the human-reviewed 4f1071715386b463bd4d76bc5a18d81fe2d31b99ab83216ccff24c1306058338."
verification: "Before mutation, the primary main checkout held the authorized old value and the approved diagnostic PNG SHA-256 reverified as 4f1071715386b463bd4d76bc5a18d81fe2d31b99ab83216ccff24c1306058338. After mutation, the focused deterministic CI contract test passed (mix test test/guardrails/required_checks_contract_test.exs: 19 tests, 0 failures), the reference exactly matched the approved PNG SHA-256, and git diff --check passed. Host PDFium was unavailable, so no native raster execution was claimed; the authoritative pinned Linux raster gate remains required under fresh exact-SHA launch-CI authorization."
files_changed:
  - "priv/raster_refs/presets/swiss/dark.sha256"
  - ".planning/debug/swiss-dark-preset-raster-ci.md"

## Specialist Review

Not invoked: the authorized repair is a single reviewed reference-value transition; no source-code fix direction was proposed.

## Blameless Postmortem

why_not_caught: "The themed Certificate behavior changed after the prior reference refresh, but the affected Swiss/dark raster reference was not regenerated and reviewed in the same lifecycle."
guard: "Require a reviewed preset-raster reference refresh whenever a committed renderer-input change affects a covered matrix row; retain the pinned Linux preset-raster CI assertion as the enforcement artifact."

## Resolution Evidence

- timestamp: 2026-08-20
  checked: authorized primary-main reference transition and approved diagnostic PNG
  found: committed old reference was 95e8bf26c2dea691f400d0115c53d6047402205e1c8e78953c282ae724702b1d; the reviewed PNG rehashed to 4f1071715386b463bd4d76bc5a18d81fe2d31b99ab83216ccff24c1306058338; only the canonical Swiss/dark SHA file was changed
  implication: the authorized reference repair is exact and provenance-bound to the reviewed artifact

- timestamp: 2026-08-20
  checked: focused host-available deterministic and CI-contract verification
  found: mix test test/guardrails/required_checks_contract_test.exs passed with 19 tests and 0 failures; post-update reference comparison matched the PNG SHA; git diff --check passed; pdfium-cli is unavailable on this host
  implication: reference and CI contract integrity are verified locally without weakening any gate; the pinned Linux raster gate must be rerun only after fresh exact-SHA authorization
