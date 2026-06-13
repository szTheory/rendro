# Phase 94: Docs & Warning Hygiene - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a clean, deliberate ExDoc warning posture and a self-explaining viewer-evidence staleness signal:

1. `mix docs` emits **zero** unexplained ExDoc warnings, and that zero-warning policy is mechanically enforced in CI.
2. The latent viewer-evidence staleness warning (180-day) is made **self-explaining** — wording/docs only, nothing silenced, raised, or pre-emptively re-recorded.

This is a docs/hygiene/wording phase. It does **not** change PDF behavior, the public API surface, the staleness threshold, or the viewer-evidence promotion machinery.

</domain>

<decisions>
## Implementation Decisions

The ROADMAP success criteria for Phase 94 are fully prescriptive — they fix the HOW, not just the WHAT. Discussion confirmed there are no gray areas worth surfacing (calibration: `minimal_decisive`; user opted to skip discussion and capture the locked spec). The decisions below restate the locked mechanisms so the planner does not re-derive or re-litigate them.

### ExDoc warning resolution (HYG-01)
- **D-01:** Resolve prose `@doc` references to hidden internals via a **`skip_code_autolink_to:`** list in `mix.exs` `docs/0`. This is a *new* ExDoc option here — `docs/0` currently only has `skip_undefined_reference_warnings_on:` (a different option for undefined-reference warnings in extras). Do not conflate the two.
- **D-02:** Give `Rendro.PDF.Font` a **real internal-marking `@moduledoc`** (it is currently `@moduledoc false`) so its `@type t` typespec autolinks resolve and stop warning. Verified safe to make visible: `Rendro.PDF.Font` is **not** in `priv/public_api.json` and **not** in the asserted-hidden contract list — so this neither widens the public API nor breaks the public-API contract test. The `@moduledoc` text must mark it as an internal implementation detail (not a public, stable surface).
- **D-03:** Net result: `mix docs` emits zero warnings.

### CI enforcement (HYG-01)
- **D-04:** Add `--warnings-as-errors` to the docs step of the `ci` alias in `mix.exs` (currently `"docs"` → becomes `"docs --warnings-as-errors"`). This mechanically enforces the zero-unexplained-warnings policy; any future stray ExDoc warning fails CI.

### Viewer-evidence staleness signal (HYG-02)
- **D-05:** Make the staleness warning line **self-explaining** at its source (`lib/rendro/viewer_evidence/validator.ex:105`, the `staleness_warnings/1` message). Append: (a) the remediation command, (b) a note that the warning is **advisory outside `--strict`** (fatal only with `--strict`), and (c) a pointer to `guides/viewer_evidence.md`.
- **D-06:** **Preserve the 180-day threshold** (`@staleness_days 180` at `validator.ex:11`). HYG-02 is a wording/docs change only — **do not** silence the warning, raise/lower the threshold, or pre-emptively re-record evidence to dodge it. The signal must still fire on the same cadence; it just explains itself.
- **D-07:** Document the staleness lifecycle in `guides/viewer_evidence.md` (the guide already exists and is already wired into ExDoc `extras`/package `files`). Add a section explaining that the signal is a **designed cadence signal, not a defect** — so a maintainer who first sees it fire (~late Nov 2026, 180 days after the latest recordings) understands it is intentional.

### Claude's Discretion
- Exact entries in the `skip_code_autolink_to:` list — driven by which references actually warn during `mix docs`; the planner/researcher should run `mix docs` to enumerate them empirically rather than guessing.
- Exact wording of the `@moduledoc` on `Rendro.PDF.Font`, the augmented staleness message string, and the new lifecycle section's heading/placement within `guides/viewer_evidence.md`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase definition
- `.planning/ROADMAP.md` (Phase 94 block) — the four success criteria; they are the authoritative HOW.
- `.planning/REQUIREMENTS.md` — HYG-01 (clean ExDoc warning posture), HYG-02 (self-explaining staleness signal).

### Files to change
- `mix.exs` `docs/0` (currently ~lines 98–130) — add `skip_code_autolink_to:`; note existing `skip_undefined_reference_warnings_on:`.
- `mix.exs` `aliases/0` `ci:` list (currently ~lines 65–73) — change `"docs"` → `"docs --warnings-as-errors"`.
- `lib/rendro/pdf/font.ex` — replace `@moduledoc false` with a real internal-marking `@moduledoc`.
- `lib/rendro/viewer_evidence/validator.ex` — `@staleness_days` (line 11, **preserve**); `staleness_warnings/1` message (line ~105, **augment**).
- `guides/viewer_evidence.md` — existing guide; add the staleness-lifecycle section.

### Contracts that must stay green (do not break)
- `priv/public_api.json` + the public-API contract test (`test/docs_contract/public_api_contract_test.exs`) — confirms `Rendro.PDF.Font` stays out of the public surface and the asserted-hidden internals stay hidden after the `@moduledoc` change.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix.exs` `docs/0` already has `skip_undefined_reference_warnings_on:` — the new `skip_code_autolink_to:` follows the same list-of-strings shape and lives in the same keyword list.
- `guides/viewer_evidence.md` already exists, is in ExDoc `extras`, and is in the package `files` list — only a new section is needed, no wiring.
- `lib/rendro/viewer_evidence/validator.ex` centralizes staleness logic (`@staleness_days`, `staleness_warnings/1`, aggregated in `warnings/…` at ~line 132) — single edit site for the message.

### Established Patterns
- Errors-as-product: existing warning/error strings in the codebase embed the remediation `mix` command (see `lib/rendro/launch_artifacts.ex` "run mix rendro.launch_artifacts.gen"). The augmented staleness message should match this convention.
- CI alias is the single enforcement lane (`ci:` runs `compile --warnings-as-errors`, `test`, `docs`, `credo --strict`, `dialyzer`) — adding `--warnings-as-errors` to `docs` fits the established "fail on drift" posture.

### Integration Points
- The public-API contract lane is the guardrail that makes the `Rendro.PDF.Font` `@moduledoc` change safe to verify — run it after the change.
- `mix docs` is the empirical oracle for which autolink references warn; enumerate before populating `skip_code_autolink_to:`.

</code_context>

<specifics>
## Specific Ideas

- The staleness signal is expected to first fire ~late Nov 2026 (180 days after the most recent viewer-evidence recordings). The lifecycle guide section should make that "first firing" legible as a designed cadence event, not a regression.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. The phase is deliberately narrow (docs + wording + CI enforcement). No silencing, no threshold changes, no public-API changes.

</deferred>

---

*Phase: 94-Docs & Warning Hygiene*
*Context gathered: 2026-06-13*
