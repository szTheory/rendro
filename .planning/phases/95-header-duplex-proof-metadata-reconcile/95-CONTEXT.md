# Phase 95: Header Duplex Proof & Metadata Reconcile - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Two independent, narrow deliverables — both proof/metadata hygiene, **no PDF behavior or public API change**:

1. **PROOF-01 — Header duplex proof depth.** Add direct end-to-end tests proving header-specific `only_on: :odd | :even` running content renders on the correct *physical* page parity, at parity with the footer coverage already shipped in v2.7. The `only_on` engine already exists and works (shipped in Phase 90); this phase adds the missing **header-specific** test coverage, it does **not** add or change a capability.
2. **META-01 — Stale validation metadata reconcile.** Flip the false-pending / false-incomplete status markers inside the archived v2.6/v2.7 `*-VALIDATION.md` files so each file's recorded status is internally consistent with its own `nyquist_compliant: true` / approval line and the already-`passed` milestone audits.

**This is a test-authoring + docs-reconcile phase.** It changes no `lib/` source, no public API surface (`priv/public_api.json` unchanged), no engine behavior, and no validation thresholds or machinery. Out of scope (held v2.8 non-goals): global text shaping, mobile GUI viewer promotion, TOC/outlines/anchors/cross-refs, charts, existing-PDF editing, release-please automation.

</domain>

<decisions>
## Implementation Decisions

This phase, like Phases 93 and 94, is **fully specified by its ROADMAP.md success criteria** (SC #1–#4) — they fix the HOW, not just the WHAT (exact test files, exact assertions, exact edge cases). Advisor mode (`minimal_decisive`, calibration tier from `vendor_philosophy: opinionated`) surfaced exactly one genuine fork (META-01 edit method); the rest are locked from the criteria + STATE.md prior research + the codebase scout below. No scope was added.

### PROOF-01 — Proof architecture (locked from STATE.md prior research)
- **D-01:** **Mirror the existing footer proof at both the render layer and the paginate layer.** **Reject** Poppler-per-page rendering and golden-byte fixtures as the proof mechanism — assert on the byte-stable content stream directly, exactly as the shipped footer test does. (Locked in STATE.md: "PROOF-01: mirror footer proofs at render + paginate layers; reject Poppler-per-page and golden-bytes.")
- **D-02:** **Render-layer test** (SC #1) lives in `test/rendro/flow_test.exs`. Mirror the existing footer test `"only_on odd and even footer sections render on physical page parity"` (flow_test.exs:268), changing `role: :footer` → `role: :header` and forcing a **≥4-physical-page** document (the footer test only reaches 2 pages — increase body content / shrink page height so 4 pages are produced). Assert the content stream contains `(Odd 1) Tj`, `(Even 2) Tj`, `(Odd 3) Tj`, `(Even 4) Tj` and `refute pdf =~ "{{page_number}}"` (token must not leak).
- **D-03:** **Paginate-layer test** (SC #2) lives in `test/rendro/pipeline/paginate_test.exs`. Prove header physical odd/even parity **coexists** with section-local header tokens under `page_numbering: [restart: true]`. Extend the pattern already established by the `"page_numbering restart … substitutes section tokens"` test (paginate_test.exs:685) — add a header section with `only_on:` parity alongside the restart/section-token assertions.
- **D-04:** **Edge cases** (SC #3), all three required:
  - First-page parity: page 1 is **odd** (an `:odd` header appears on page 1; an `:even` header does not).
  - Single-page doc: only the `:odd` header appears (no `:even`).
  - Header + footer `only_on` **coexisting** on the same document, proven to be driven by **independent `region_entries`** (the per-region entry map at `lib/rendro/pipeline/compose.ex:117`/`:134`) — i.e. header parity and footer parity do not interfere.

### META-01 — Reconcile method (user-decided + scoped)
- **D-05:** **Edit the stale status markers in place** in the archived files (user decision, 2026-06-13). Git-reversible; makes each record truthful at the point a reader looks. Rejected the "leave verbatim + append dated erratum" alternative because it leaves the false markers visibly present, which the criterion calls the defect.
- **D-06:** **Primary, unambiguous targets — the Per-Task Verification Map "Status" column cells reading `pending`, plus Phase 91's `Status: Planned`.** These directly contradict the same file's own `status: approved` / `nyquist_compliant: true` / Approval line. Flip `pending` → **`passed`** (the terminal token already used in `87-VALIDATION.md`'s trailing cells — reconcile to existing convention, do not invent a new token). Concrete cell counts found in scout: `88-VALIDATION.md` (5), `90-VALIDATION.md` (3), `92-VALIDATION.md` (4); `91-VALIDATION.md` uses an older `**Status:** Planned` header → set to its real terminal status.
- **D-07:** **Frontmatter `status: draft` is a research-gated secondary target, NOT a blind flip.** `status: draft` appears on `83/84/88`-VALIDATION.md **and on the current, genuinely-complete Phases 93/94** — it is an un-advanced GSD default, not a phase-specific false marker. Default behavior: **do not flip frontmatter `status` if doing so would create new cross-archive inconsistency** (e.g. making v2.6/v2.7 say `approved` while v1.x/v2.5 archives and current 93/94 stay `draft`). The researcher should confirm whether a milestone-wide terminal convention exists before touching frontmatter `status`; if none exists, leave frontmatter `status` alone and reconcile only the in-file table/heading markers (D-06), which is sufficient to remove the *false-pending* contradiction.
- **D-08:** **Scope is strictly the v2.6/v2.7 archived phase folders** (`.planning/milestones/v2.6-phases/`, `.planning/milestones/v2.7-phases/`), per the criterion. Do **not** touch v1.x/v2.5 archives, the current-milestone files (93/94/95/96), or any non-`VALIDATION` metadata.

### Claude's Discretion (planner/researcher)
- PROOF-01: exact page geometry (page height / body line count) needed to force a ≥4-physical-page document; whether to factor a shared header-template helper out of the footer test or duplicate inline; exact test names.
- META-01: exact terminal token if scout shows `passed` is not the dominant convention across the trailing cells; the precise frontmatter resolution per D-07 after the milestone-wide-convention check.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase definition (authoritative HOW)
- `.planning/ROADMAP.md` (Phase 95 block, lines ~99–111) — the four success criteria; they fix exact files, assertions, and edge cases.
- `.planning/REQUIREMENTS.md` — PROOF-01 (header `only_on` E2E proof at footer parity), META-01 (reconcile stale v2.6/v2.7 validation metadata).

### PROOF-01 — the footer proof to mirror + the `only_on` engine
- `test/rendro/flow_test.exs:268` — the shipped footer `only_on` render-layer proof. **The exact template to clone for the header render-layer test (D-02).** Note its content-stream assertions (`(Odd 1) Tj`) and `refute "{{page_number}}"`.
- `test/rendro/pipeline/paginate_test.exs:685` — the shipped `page_numbering restart` + section-token test. **Extend for the header parity + section-token coexistence test (D-03).**
- `lib/rendro/pipeline/paginate.ex:729–739` — `apply_only_on/3`: the physical-parity filter (`:odd`/`:even` keyed off `page_idx`). The behavior under proof.
- `lib/rendro/pipeline/compose.ex:117`, `:134`, `:150`, `:174–185` — `region_entries` per-region map and `validate_only_on!/1`. Independent `region_entries` is what makes header+footer coexistence (D-04) work.
- `lib/rendro/section.ex` — `only_on` section field surface.
- `test/rendro/pipeline/compose_test.exs`, `test/rendro_builders_test.exs` — existing `only_on` unit/validation coverage (do not duplicate; PROOF-01 adds the header-specific render/paginate proofs).

### META-01 — files to reconcile (v2.6/v2.7 only)
- `.planning/milestones/v2.6-phases/88-launch-execution-demand-instrumentation/88-VALIDATION.md` — `status: draft` + 5 `pending` rows.
- `.planning/milestones/v2.7-phases/90-duplex-running-content/90-VALIDATION.md` — `status: approved` but 3 `pending` rows (representative of the contradiction; see lines 4–5, 35–37, 54, 56).
- `.planning/milestones/v2.7-phases/91-pdf-js-advisory-proof-lane/91-VALIDATION.md` — `**Status:** Planned` (older format, no frontmatter).
- `.planning/milestones/v2.7-phases/92-docs-claims-release-hygiene/92-VALIDATION.md` — `status: approved` but 4 `pending` rows.
- `.planning/milestones/v2.6-phases/83-*/83-VALIDATION.md`, `84-*/84-VALIDATION.md` — `status: draft` (frontmatter; research-gated per D-07).
- Authoritative truth to reconcile against: `.planning/milestones/v2.6-MILESTONE-AUDIT.md` and `.planning/milestones/v2.7-MILESTONE-AUDIT.md` (both `passed`).
- Convention reference: `.planning/milestones/v2.6-phases/87-comparison-page-livebook/87-VALIDATION.md` — uses `passed` in trailing cells (the terminal token to reconcile to, D-06).

### Contracts that must stay green
- `priv/public_api.json` + `test/docs_contract/public_api_contract_test.exs` — must be untouched/green (PROOF-01 adds tests only; no public surface change).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Footer `only_on` test (flow_test.exs:268)** — near-complete template for the header render-layer test: `page_template` with a `role:` region, two `Rendro.section(only_on: :odd|:even, …)`, `Rendro.flow(…, sections: […])`, then `Rendro.render/1` and content-stream regex assertions. Clone it for `role: :header` and scale the doc to ≥4 pages.
- **`page_numbering restart` test (paginate_test.exs:685)** — base for the paginate-layer coexistence test; already exercises restart + section-token substitution.
- **`apply_only_on/3` (paginate.ex:729–739)** — the parity engine is shipped and proven for footers; PROOF-01 is purely additional header-direction coverage of the same code path.

### Established Patterns
- **Content-stream byte assertions over rendering** — the codebase proves running-region behavior by asserting on the PDF content stream (`(Text) Tj`, `/Type /Page` counts, `refute "{{token}}"`), not by rasterizing. D-01 follows this verbatim (and is why Poppler-per-page / golden-bytes were rejected).
- **`region_entries` is per-region** — header and footer parity are independent map entries, which is exactly what SC #3's "coexisting via independent `region_entries`" asserts.
- **VALIDATION.md status convention** — terminal trailing-cell token is `passed`; frontmatter terminal status varies (`approved`/`verified`/`complete`) and `draft` is the un-advanced default (present even on done current phases 93/94) — informs the D-07 research gate.

### Integration Points
- New tests slot into existing files (`flow_test.exs`, `paginate_test.exs`) — no new test infra, helpers, or files strictly required.
- META-01 edits are confined to `.planning/milestones/v2.6-phases/` and `v2.7-phases/` markdown — no code, no CI, no contract impact.

</code_context>

<specifics>
## Specific Ideas

- The header render-layer assertions should read `(Odd 1) Tj` / `(Even 2) Tj` / `(Odd 3) Tj` / `(Even 4) Tj` (page 1 = odd is the first-page-parity anchor) and must `refute` the raw `{{page_number}}` token to prove substitution happened.
- META-01's core insight: the defect is an *intra-file contradiction* (a file declaring `approved`/`nyquist_compliant: true` while its own task table says `pending`). Fixing the table cells removes the false-pending marker without needing to touch frontmatter that is consistent with the rest of the archive.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. One out-of-scope observation worth recording (do not act on it in Phase 95): the current-milestone Phases 93/94 `VALIDATION.md` files also carry `status: draft`; that is the systemic GSD default and will resolve when v2.8 closes — it is explicitly **not** META-01's concern (which is bounded to v2.6/v2.7 archives).

</deferred>

---

*Phase: 95-Header Duplex Proof & Metadata Reconcile*
*Context gathered: 2026-06-13*
