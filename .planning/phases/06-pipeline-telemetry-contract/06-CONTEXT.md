# Phase 6: Pipeline Telemetry Contract Fixes - Context

**Gathered:** 2026-04-26
**Status:** Ready for planning
**Decision style:** Research-backed, locked. User preference: synthesized recommendations over interrogation. Items below are decisions, not options.

<domain>
## Phase Boundary

Bring `Rendro.Pipeline` and `Rendro.Telemetry` into agreement with REQUIREMENTS.md OBS-01 by:

1. Emitting `[:rendro, :pipeline, :validate, :start|:stop|:exception]` events in addition to the existing five stages (closes BLOCKER-04).
2. Restoring spec-stated stage order `:build → :compose → :measure → :paginate → :render → :validate` (closes BLOCKER-05).
3. Preserving `page_count` and `byte_size` in stop metadata on the error path when the doc has them available (closes MINOR-15).

Out of scope (carried to deferred): deterministic-mode runtime invariant enforcement (no `/CreationDate` / `/ModDate` / non-deterministic `/ID`); structural PDF spec validation beyond header/trailer presence; new policy types beyond the existing `max_pages` / `max_bytes` / `timeout`.

</domain>

<decisions>
## Implementation Decisions

### Pipeline shape and stage ordering

- **D-01:** Final canonical execution order is `build → compose → measure → paginate → guard_max_pages → render → validate`. Six stages emit telemetry spans (`:build, :compose, :measure, :paginate, :render, :validate`); `guard_max_pages` is a non-spanned policy guard, not a stage.
- **D-02:** **`Compose` becomes logical/document-tree assembly only.** Responsibilities: walk pages/content, normalize cells (move `normalize_row/1` here from `Measure`), attach header/footer templates, resolve content-flow direction, leave `width`/`height`/`x`/`y` as `nil` unless user-supplied. **No font metrics, no pixel math, no y-stacking inside Compose.**
- **D-03:** **`Measure` becomes a pure metric pass.** For every block with `nil` width/height, fill from font metrics or table cell rules. Operates on the normalized tree from Compose. Idempotent.
- **D-04:** **`Paginate` absorbs y-stacking.** For fixed-position pages, validate fit. For flow content, stack blocks against the page cursor and split tables. This is where `current_y` lives — moved out of `Compose`. Latent flow bug (page-2 remainder rows inheriting page-1 y values) is fixed by construction.
- **D-05:** `Render` is unchanged.

Rationale: the unanimous pattern across CSS/WeasyPrint, TeX, Typst, ReportLab Flowables, and react-pdf/Yoga is **assemble tree → measure → place**. Rendro's two-API engine (fixed-position + flow, CORE-03/04) and its forthcoming flow features (LAY-02/03 multi-page tables, repeating headers) both want this shape.

### `:validate` stage scope (locked tight to audit)

- **D-06:** `:validate` is a **real trailing stage** that runs post-render checks on the rendered PDF binary. It is wrapped in `:telemetry.span([:rendro, :pipeline, :validate], ...)` and emits `start/stop/exception` like any other stage.
- **D-07:** `:validate` body for v1.0 includes exactly:
  1. PDF structural sanity: header `%PDF-` present, `%%EOF` trailer present.
  2. Page-count parity: PDF object-graph page count must equal `length(doc.pages)`.
  3. `max_bytes` policy check (absorbed from the previous post-render inline check).
- **D-08:** `:validate` does NOT enforce deterministic-mode invariants (no `/CreationDate`/`/ModDate`/`/ID` checks). High-leverage idea, but new scope — promoted to `<deferred>` for a dedicated "deterministic mode hardening" phase with its own test corpus.
- **D-09:** Failure cases return `{:error, %Rendro.Error{stage: :validate, what: ...}}` using the existing `Rendro.Error.from_stage/3` constructor. New error reasons added to `lib/rendro/error.ex` `what`/`next` clauses: `:structural_corruption` ("PDF header/trailer missing — internal renderer bug, please report"), `:page_count_mismatch` ("Rendered page count diverged from document page count — pipeline bug"), `:max_bytes_exceeded` (already exists, reused).

Rationale: a pure-passthrough `:validate` (Option A from research) would emit a hollow span and lie to operators reading dashboards. A real validate stage is idiomatic (Oban only spans real work; Typst exports run trailing PDF/A invariants). Keeping the scope tight to the audit's success criteria avoids scope creep; deterministic enforcement gets its own phase where it can have proper test coverage.

### `max_pages` policy guard placement

- **D-10:** `max_pages` is checked **after paginate, before render** as a non-spanned `with` step (`validate_policy(:pages, doc, policies, base_meta)`). It does NOT move into the trailing `:validate` stage.

Rationale: page count is only final after paginate. Moving the check post-render (into `:validate`) would force compose+measure+paginate+render work on a document the policy exists to refuse — a CPU/DoS regression. Fail-fast at the earliest point where the metric is meaningful.

### Stage stop_meta schema (success and error paths)

- **D-11:** Single stable stop-event schema. Every `:stop` event (success or error) emits the same fields:
  ```
  %{
    render_id:     String.t(),
    document_type: :pdf,
    deterministic: boolean(),
    stage:         atom(),
    status:        :ok | :error,
    page_count:    non_neg_integer(),
    byte_size:     non_neg_integer()
  }
  ```
- **D-12:** `page_count` is derived from the latest doc state available to the span: prefer `result.pages` if `result` is a `%Rendro.Document{}`, else fall back to the input `doc.pages`. Late-stage failures carry real page counts; early-stage failures carry whatever the input had (typically 0 for build, populated for measure/paginate/compose/render).
- **D-13:** `byte_size` is real only when `stage == :render` and `result` is a binary; `0` otherwise. Never report a partial buffer size that downstream alerts could misinterpret as a real artifact.
- **D-14:** Error path adds an optional `:error` key: `error: %{kind: error.kind, stage: error.stage}`. Typed `%Rendro.Error{}` remains the function return value; the metadata field is for telemetry handlers that don't want to re-parse the error tuple. This is the documented `:telemetry.span/3` pattern for tagged-tuple errors (Keathley conventions).
- **D-15:** Tagged-tuple errors emit `:stop` events with `status: :error`. Only true raises hit `:exception` (auto-emitted by `:telemetry.span/3` with `kind`/`reason`/`stacktrace`). This matches Oban's split and prevents APM tools from double-counting failures.
- **D-16:** Top-level `[:rendro, :render, :stop]` event uses the same schema (existing `build_stop_meta/3` updated to match).

### SemVer and breaking-change communication

- **D-17:** Ship as a single-shot release. **No bridge period, no dual emission, no `telemetry_contract_version` field, no `UPGRADING.md`.**
- **D-18:** Document the change in a new `CHANGELOG.md` (Keep-a-Changelog format, root of repo) under `[0.1.0] - Unreleased`:
  - **Added:** `[:rendro, :pipeline, :validate, :*]` events.
  - **Changed (BREAKING):** stage execution order now matches spec; `max_pages_exceeded` now fires after `:paginate` instead of mid-pipeline. Top-level `[:rendro, :render, :*]` events unchanged.
  - **Notes:** pre-1.0; previous order was a bug against the documented architecture.
- **D-19:** Test contract migration: update `test/rendro/telemetry_test.exs:319` from `[:build, :measure, :paginate, :compose, :render]` to `[:build, :compose, :measure, :paginate, :render, :validate]`. Add tests asserting `[:rendro, :pipeline, :validate, :stop]` fires after `:render :stop`, that `max_pages_exceeded` fires post-paginate / pre-render, and that error-path stop_meta carries `page_count: length(doc.pages)` (regression test for MINOR-15). Estimated diff: ~15 lines across 3 tests + 2 new tests.
- **D-20:** Threadline adapter impact assessment: `lib/rendro/adapters/threadline.ex` only subscribes to top-level `[:rendro, :render, :stop|:exception]` events — unaffected by stage reorder or new `:validate` event. No recipe edits expected. Verify by re-running `test/rendro/adapters/threadline_test.exs` after the change.

Rationale: pre-1.0, no published Hex releases, no external consumers, audit document explicitly frames this as bug-fix not API churn (`v1.0-MILESTONE-AUDIT.md`), `:telemetry` library does not promise event ordering as part of any public contract. Direct precedent: Oban v2.0 renamed every telemetry event with a single conversion table and no dual-emission bridge.

### Claude's Discretion
- Module naming for new helpers (e.g., `Rendro.Pipeline.Validate` module to host structural sanity + max_bytes logic).
- Internal organization of `Compose` after the y-stacking is removed (small enough to keep in one file or split, planner's call).
- Test file layout for new `:validate` stage tests (add to `test/rendro/telemetry_test.exs` vs new `test/rendro/pipeline/validate_test.exs` — planner's call).
- Exact wording of `Rendro.Error` `what`/`next` strings for new error reasons.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and audit
- `.planning/v1.0-MILESTONE-AUDIT.md` — BLOCKER-04 (missing `:validate` event), BLOCKER-05 (compose/measure inverted), MINOR-15 (error-path metric loss). The phase's success criteria are explicitly tied to closing these.
- `.planning/ROADMAP.md` § Phase 6 — Goal, requirements (OBS-01, OBS-02, CORE-01), success criteria.
- `.planning/REQUIREMENTS.md` — OBS-01 (telemetry stages), OBS-02 (metrics correlation), OBS-03 (structured errors), CORE-01 (core pipeline).
- `.planning/PROJECT.md` § Architecture — locked pipeline shape `build -> compose -> measure -> paginate -> render -> validate`.

### Carried-forward decisions
- `.planning/phases/01-core-deterministic-foundation/01-CONTEXT.md` — D-02 (canonical pipeline stages), D-05/D-06 (telemetry schema with `render_id`/`document_type`/`deterministic`/`status`/`duration`/`page_count`/`byte_size`).

### Implementation surfaces
- `lib/rendro/pipeline.ex` — current pipeline orchestration (lines 17-36 top-level Task wrapping; 39-44 telemetry span; 46-59 build_stop_meta; 61-71 run_stages with the wrong order; 73-91 validate_policy; 93-127 span helper + stage_stop_meta).
- `lib/rendro/telemetry.ex:26` — `@stage_names` constant (must add `:validate`).
- `lib/rendro/pipeline/compose.ex` — currently does y-stacking; must lose it to D-04.
- `lib/rendro/pipeline/measure.ex` — currently does row normalization; must hand that to Compose per D-02.
- `lib/rendro/pipeline/paginate.ex` — gains y-stacking responsibility per D-04.
- `lib/rendro/pipeline/build.ex` — unchanged.
- `lib/rendro/pipeline/render.ex` — unchanged.
- `lib/rendro/error.ex` — add `:structural_corruption`, `:page_count_mismatch` to `from_stage/2,3` `what`/`next` clauses.
- `test/rendro/telemetry_test.exs:319` — locks the wrong order; rewrite per D-19.
- `test/rendro/pipeline/compose_test.exs`, `test/rendro/pipeline/measure_test.exs` — verify they still pass after refactor (compose tests assert explicit x/y; measure tests assert width/height only — both should be stable).

### Adapter impact
- `lib/rendro/adapters/threadline.ex` — subscribes to top-level `[:rendro, :render, :*]` only; unaffected by stage reorder. Verify after change.
- `test/rendro/adapters/threadline_test.exs` — regression check.

### Telemetry conventions and ecosystem evidence
- [`hexdocs.pm/telemetry/telemetry.html`](https://hexdocs.pm/telemetry/telemetry.html) — `:telemetry.span/3` semantics; ordering is not a contract.
- [`hexdocs.pm/oban/Oban.Telemetry.html`](https://hexdocs.pm/oban/Oban.Telemetry.html) — only spans real work, distinguishes `:stop` from `:exception`.
- [`hexdocs.pm/finch/Finch.Telemetry.html`](https://hexdocs.pm/finch/Finch.Telemetry.html) — single stable stop schema for success and error.
- [`hexdocs.pm/broadway/Broadway.html`](https://hexdocs.pm/broadway/Broadway.html) — "StopMetadata should include the values from StartMetadata".
- [Telemetry Conventions — Keathley](https://keathley.io/blog/telemetry-conventions.html) — error metadata via optional `:error` key on `:stop`.
- [`hexdocs.pm/oban/v2-0.html`](https://hexdocs.pm/oban/v2-0.html) — precedent for shipping telemetry contract changes without a bridge.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `:telemetry.span/3` already wired through `Rendro.Pipeline.span/4` — extend, don't replace.
- `Rendro.Error.from_stage/2,3` already produces structured envelopes; new error reasons plug into existing scaffolding.
- `Rendro.Telemetry.@stage_names` is the single source of truth for stage event names — adding `:validate` cascades through `event_prefixes/0` and `all_event_names/0` automatically.
- Existing `validate_policy/4` private functions in `pipeline.ex` already implement `max_pages` and `max_bytes` checks; partition them: `:pages` stays inline, `:bytes` moves into the new `Validate` module body.

### Established Patterns
- Stages return `{:ok, doc} | {:error, reason}`; `with` short-circuits.
- Stage modules live at `lib/rendro/pipeline/<stage>.ex` with `run/1`. The new `:validate` stage follows: `lib/rendro/pipeline/validate.ex` with `run/2` (PDF binary + doc) returning `{:ok, pdf_binary} | {:error, %Rendro.Error{}}`.
- Tests for stages live at `test/rendro/pipeline/<stage>_test.exs`. Telemetry-shape tests live at `test/rendro/telemetry_test.exs`.

### Integration Points
- Threadline adapter (top-level events only) — no integration churn.
- Future Oban worker (Phase 8) — depends on this phase's contract; will hook into the same stable schema.
- Future Phoenix adapter (Phase 7) — surfaces `%Rendro.Error{}` envelopes; new validate-stage error reasons must be representable through the same envelope.

</code_context>

<specifics>
## Specific Ideas

- "Be the architect, not the interviewer" — user preference for research-backed locked recommendations rather than option menus. This CONTEXT.md is the result of 4 parallel research agents (Elixir/OTP idioms, layout engine analogues, telemetry conventions, SemVer/breaking-change norms) synthesized into a single coherent decision set.
- Treat the audit document (`v1.0-MILESTONE-AUDIT.md`) as the floor for Phase 6 success — implement exactly what it specifies as BLOCKER/MINOR remediation, defer additive ideas (deterministic invariant enforcement) to dedicated phases.
- Threadline integration validation is part of done-ness; verify `test/rendro/adapters/threadline_test.exs` passes unchanged after the pipeline shift.

</specifics>

<deferred>
## Deferred Ideas

- **Deterministic-mode runtime invariant enforcement.** Have `:validate` (or a new stage) assert no `/CreationDate`, no `/ModDate`, deterministic `/ID` when `deterministic: true`. High-leverage for catching reproducibility regressions, but new scope beyond the audit. Should be its own focused phase with a deterministic-fixture test corpus. — Add to roadmap backlog as candidate gap-closure phase post-Phase 11.
- **PDF/A and PDF/UA conformance checks** in `:validate`. Tracked as v2 requirements (COMP-01, COMP-02). Out of scope for v1.0; require validator-backed proof per PROJECT.md constraints.
- **`telemetry_contract_version` metadata field.** Considered and rejected for Phase 6 (overengineered pre-1.0). Reconsider only if a downstream consumer requests explicit contract pinning.
- **Splitting `max_bytes` into its own dedicated post-render policy stage** (separate from `:validate`). Would yield finer-grained telemetry but at the cost of stage proliferation. Defer until usage data shows it matters.

</deferred>

---

*Phase: 06-pipeline-telemetry-contract*
*Context gathered: 2026-04-26*
