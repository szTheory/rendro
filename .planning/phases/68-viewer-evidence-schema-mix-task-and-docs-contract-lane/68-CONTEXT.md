# Phase 68: Viewer Evidence Schema, Mix Task, and Docs-Contract Lane - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Land the additive matrix vocabulary (`explicit_deferral`), JSON Schema validation (Draft 2020-12 via JSV, dev/test only), `Mix.Tasks.Rendro.ViewerEvidence` (`list` / `validate` / `missing`), the eighth docs-contract lane, and `priv/viewer_evidence/` + `priv/schemas/` scaffolding. Validator must pass against the **unchanged** matrix at phase end (no promotions yet — those are Phase 69–71).

Out of scope: `guides/viewer_evidence.md`, first recorded cell, matrix promotions, family-specific claims test edits for deferred rows, `mix.exs` extras for the guide, staleness **blocking** on `main`, optional Pdfium/PdfJs adapters.

</domain>

<decisions>
## Implementation Decisions

### Deferral row shape (matrix vocabulary)
- **D-01:** Use a third matrix status: `status: "explicit_deferral"` with required `evidence_deferred` (non-empty prose naming viewer behavior, version, or tracked issue). Do **not** overload `status: "unverified"` for named non-promotions.
- **D-02:** `unverified` means only “recording obligation not satisfied” — no `evidence:`, no `evidence_deferred`, not yet promoted or deferred.
- **D-03:** `explicit_deferral` rows MUST NOT carry `evidence:`; deferral is matrix-only (no evidence file).
- **D-04:** JSON Schema for viewer rows: enum `["supported", "unverified", "explicit_deferral"]` with conditional rules (`supported` → require `evidence` + `recorded_at` + `viewer_kind`; `explicit_deferral` → require `evidence_deferred`; forbid conflicting keys).
- **D-05:** Update `ARCHITECTURE.md` Pattern 1 / deferral-flow examples during implementation — they are superseded by D-01–D-04 (ROADMAP/MATRIX-01 win over older `unverified` + `evidence_deferred`-only shape).

### Evidence file frontmatter contract
- **D-06:** Canonical path: `priv/viewer_evidence/<surface>/<viewer>.md`. Frontmatter `surface` and `viewer` MUST match path segments (validator error if not).
- **D-07:** Frontmatter schema version **1** with required keys: `schema_version`, `surface`, `viewer`, `viewer_version`, `platform` (single “OS + platform” string), `recorded_at` (ISO date `YYYY-MM-DD`), `behaviors` (array).
- **D-08:** Fixture reference: exactly one of `fixture` (repo-relative path) OR `fixture_sha256` (`sha256:<64 hex>`).
- **D-09:** `behaviors[]` items: `{behavior, result, note}` where `behavior` matches matrix `proof[]` IDs for that cell, `result` ∈ `pass | fail | skip | na`, `note` non-empty on every row (including `pass`).
- **D-10:** Promotion state lives on the **matrix only**: `status`, `evidence`, `recorded_at`, `viewer_kind` (`manual | pdfium-cli | pdfjs-dist`). **Forbidden in frontmatter:** `status`, `viewer_kind`, `checks`, `date_checked`, flat pass/fail maps.
- **D-11:** `viewer_version` ONLY in evidence file — never on matrix row (viewer auto-update must not silently invalidate matrix).
- **D-12:** Validate with **JSV** (`{:jsv, "~> 0.18", only: [:dev, :test], runtime: false}`) against `priv/schemas/viewer_evidence.schema.json` + `priv/schemas/support_matrix.schema.json`, plus **Elixir** cross-artifact rules (path alignment, `proof[]` completeness, orphan files, canonical path `priv/viewer_evidence/<surface>/<viewer>.md`, body lint). Add `{:ymlr, ...}` dev/test only for YAML frontmatter parse.
- **D-13:** Ship `priv/viewer_evidence/_template.md` and `priv/viewer_evidence/.gitkeep` in Phase 68. Defer `mix rendro.viewer_evidence init` scaffold to Phase 69 unless trivial.

### Enforcement thresholds
- **D-14:** Per evidence file byte budget: **65_536** bytes (`byte_size/1` on disk). Document in schema description and mix task moduledoc.
- **D-15:** Evidence body lint (scoped to `priv/viewer_evidence/**/*.md` only): reject `-----BEGIN`, `![`, `<img`, `data:image/`, home paths (`/Users/`, `/home/`, `C:\Users\`), `private_key` with assignment unless negated (`no private_key`), operational `passphrase:` assignments; allow prose like “does not yet implement”, “open password”, “password prompt”.
- **D-16:** Deferral reason lint (matrix `evidence_deferred` only): reject empty/whitespace; whole-reason `TBD` / `not yet` / `deferred for later` (case-insensitive); `\bTBD\b`; leading `deferred for later`; vague viewer phrases without a named viewer/issue token; minimum trimmed length **40** characters. Allowlist phrases: `does not yet implement`, `not yet implemented`, `not yet available in`.
- **D-17:** Staleness: **180 days** from matrix `recorded_at` on `supported` rows. Phase 68: `validate` emits **warning**, **exit 0**. Phase 72: blocking via `validate --strict` or closure audit — **not** in docs-contract PR test.
- **D-18:** No new GitHub required check — fold enforcement into existing `test` job via `scripts/verify_docs.exs` eighth lane + `mix test test/docs_contract/viewer_evidence_claims_test.exs`.

### Operator tooling (`mix rendro.viewer_evidence`)
- **D-19:** Single task `Mix.Tasks.Rendro.ViewerEvidence` at `lib/mix/tasks/rendro/viewer_evidence.ex` with subcommands: `list`, `validate`, `missing` (argv-based, not separate Mix modules).
- **D-20:** Human-readable default: summary counts + fixed-width table (sort: `surface` → `viewer`) + footer hints (`missing` → record/defer; `--json` available). No TTY auto-detect in Phase 68.
- **D-21:** `--json` on `list` and `missing`: JSON-only stdout (`summary` + `cells`); errors on stderr; stable field names for scripting.
- **D-22:** Exit codes: `list` → 0 on successful parse; `validate` → `exit({:shutdown, 1})` on any violation; `missing` → 1 iff any `status == "unverified"` cell exists, 0 when empty. `supported` without `evidence:` shown in `list` with note; fails in `validate` + docs-contract (not counted in `missing`).
- **D-23:** `missing` walks **all** viewer rows in `priv/support_matrix.json` (no “trust-sensitive only” filter). Include nested viewer maps (e.g. `forms.signature_widget_viewers`).
- **D-24:** Rich `@moduledoc` (VisualUat-style): three states, subcommands, exit codes, CI truth (docs-contract lane), forward link to `guides/viewer_evidence.md` (Phase 69). Do **not** add this task to `mix ci` in Phase 68.
- **D-25:** No `Rendro.Support.ViewerEvidence` runtime module — build-time/audit-time only per pure-core convention.

### Claude's Discretion
- Shared lint module location (`lib/rendro/viewer_evidence/lint.ex` vs `test/support/`) as long as docs-contract test and Mix task share one implementation.
- Exact table formatting and optional `list` “drift” marker column for `supported` without `evidence:` before Phase 70.
- Whether matrix `recorded_at` must equal frontmatter `recorded_at` on promotion (recommend equality when both present).
- JSV schema file layout details (`$defs`, `if/then`) and error message wording.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements and roadmap
- `.planning/ROADMAP.md` — Phase 68 goal, success criteria, pitfall guardrails
- `.planning/REQUIREMENTS.md` — MATRIX-01–03, RECIPE-02/04, GUARDRAIL-01/03/04
- `.planning/PROJECT.md` — Pure core, truthful support matrix, v2.3 milestone intent

### Research (v2.3 design)
- `.planning/research/SUMMARY.md` — Build order, JSV choice, additive matrix fields, pitfalls map
- `.planning/research/ARCHITECTURE.md` — Patterns 1 & 4, file layout, data flow (reconcile deferral examples with D-01)
- `.planning/research/STACK.md` — JSV ~> 0.18, dev/test-only validation, schema paths
- `.planning/research/PITFALLS.md` — Overclaim, version drift, schema coupling, honest-failure vocabulary

### Project DNA and prompts
- `prompts/rendro-oss-dna.md` — Docs-contract tests, single `mix ci` verify entrypoint, optional-deps discipline
- `AGENTS.md` — Pure core, deterministic vs advisory lanes, documentation-as-contract

### Existing implementation patterns
- `scripts/verify_docs.exs` — Lane aggregator pattern (add eighth lane)
- `test/docs_contract/protection_claims_test.exs` — Family claims test style (do not merge cross-family invariants into family tests)
- `priv/support_matrix.json` — Current viewer row shapes to remain valid until promotions/deferrals land in later phases
- `lib/mix/tasks/rendro.visual_uat.ex` — Mix task moduledoc/exit-code precedent

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/verify_docs.exs`: copy lane tuple pattern for viewer evidence test path.
- `test/docs_contract/*_claims_test.exs`: `File.read!` + Jason or regex assertions; new file is cross-family only.
- `Mix.Tasks.Rendro.VisualUat`: `@moduledoc`, `exit({:shutdown, 1})`, `Mix.shell()` messaging patterns.

### Established Patterns
- Machine-readable contract in `priv/` + human mirror in `guides/` + docs-contract enforcement — do not invent a fourth pattern.
- Merge-blocking structural checks inside `mix test`; live/signing proof lanes unchanged.
- Optional deps and Mix tasks stay out of runtime `Rendro.*` API.

### Integration Points
- `mix.exs` deps: add `jsv`, `ymlr` (dev/test only).
- `scripts/verify_docs.exs`: one new lane entry.
- `priv/support_matrix.json`: additive fields only in later phases; Phase 68 schema must accept current file unchanged.

</code_context>

<specifics>
## Specific Ideas

- Treat viewer interop like **Can I Use / compatibility matrices**: “no with reason” is a first-class state, not “unknown + footnote.”
- Operator loop: `missing` → record or defer → `validate` → docs-contract green (kubectl/terraform/npm-audit style separation: `list` informs, `missing` gates backlog).
- Example deferral cell to implement against in Phase 71: `forms.signature_widget_viewers.pdfjs` → `explicit_deferral` citing mozilla/pdf.js#4202.
- Consolidation migration (Phase 70): map legacy `date_checked` / `checks` maps → `recorded_at` / `behaviors[]` per D-07–D-09.

</specifics>

<deferred>
## Deferred Ideas

- `guides/viewer_evidence.md` + `mix.exs` extras entry — Phase 69
- First matrix promotion (forms × Apple Preview) — Phase 69
- `mix rendro.viewer_evidence init` scaffold — Phase 69 (preferred)
- Family claims test updates when deferral rows land — Phase 71
- Staleness blocking on `main` — Phase 72 (GUARDRAIL-02)
- Optional `Rendro.Adapters.Pdfium` / `PdfJs` automatable observers — v2.4+ per research

</deferred>

---

*Phase: 68-viewer-evidence-schema-mix-task-and-docs-contract-lane*
*Context gathered: 2026-05-28*
