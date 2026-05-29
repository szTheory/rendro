# Phase 74: Statement Recipe - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers **`Rendro.Recipes.Statement`** — a multi-page billing/account statement recipe runnable from a data map alone (no template authoring), built on the three-rung escape hatch (`document/2` / `page_template/1` / `sections/2`) consistent with `Rendro.Recipes.Invoice`, and the **first end-to-end consumer of the Phase 73 PAGE primitive**. Concretely (STMT-01..04):

- `document/2` accepts a statement data map (period, account, opening/closing balance, transaction lines, summary) and returns a renderable `%Rendro.Document{}`.
- The recipe computes carried-forward / brought-forward running balances **in data-assembly (`sections/2`)** — deterministic and correct across page breaks (NOT in the engine).
- "Page X of Y" appears in the running footer via the Phase 73 PAGE primitive, correct on every page including the last.
- Three-rung escape hatch consistent with `Invoice` — callers override at any rung without touching the rungs above.

**In scope:** the Statement recipe (recipe layer only), plus one small **read-only public measurement helper on the engine** (see D-09) needed for deterministic recipe-owned pagination. **Out of scope:** the Receipt/Report and Certificate recipes (Phase 75), the reference Phoenix app (Phase 76), and any change to the engine's pagination *behavior* (the single forward pass / no-convergence-loop guarantee from PAGE-04 is preserved).

</domain>

<decisions>
## Implementation Decisions

> **Process note:** All four discussed areas were researched in parallel by advisor subagents, then a second, deeper round (cross-ecosystem idiom, DX, footguns, coherence) was run at the user's request to one-shot a coherent, "correct" set. Two cross-agent conflicts were resolved by the orchestrator and are flagged below (**[RECONCILED]**). User preference: deep parallel research → locked recommendations, decide rather than re-ask.

### Per-page balance strategy (STMT-02)
- **D-01:** **The recipe OWNS pagination of the transaction table.** `sections/2` computes `body_capacity` from declared layout geometry (the same pure formula the engine uses: `body_h − header_h − footer_h`), folds the running balance, splits transaction lines into per-page groups, and emits them as body blocks with `break_before: true` (a public `Rendro.Block` attribute already honored by the paginator) starting each new page. **The engine stays behaviorally unchanged and single-pass** — the recipe decides the breaks, the engine obeys directives it already supports.
- **Rejected:** post-pagination injection seam (like `replace_page_numbers/2`). The seam (`paginate.ex` ~426/464) only receives `{page_number, total_pages}` and operates on header/footer region blocks — it has **zero visibility** into which transaction rows landed on which body page, so a per-page running balance is literally uncomputable there. Adding a per-page-body feedback hook would edge toward the multi-pass convergence loop PAGE-04 forbids. (This was the unanimous finding across 3 of 4 research agents.)

### Carried/brought-forward placement & footer composition (STMT-02 + STMT-04)
- **D-02:** **Carried-forward / brought-forward balances are REAL BODY ROWS, not running-region content.** Carried-forward is the last body row of each non-final page; brought-forward is the first body row of each subsequent page (suppress carried-forward on the last page, brought-forward on the first). This follows directly from D-01: the running-content `fn {page, total} -> ... end` cannot see per-page body content, so balances cannot live in the footer/header running regions.
- **D-03:** **The footer running region carries ONLY "Page X of Y"** via the Phase 73 PAGE primitive — use the public `Rendro.page_number/1` (`rendro.ex:210`) / `fn {page, total}` content, mirroring `Invoice.footer_section/1`. This keeps the footer's reserved height a pure function of geometry (Phase 73 D-04/D-09).

### Statement data-map contract (STMT-01)
- **D-04 [RECONCILED — money type]:** **Monetary amounts and balances are `Decimal`.** Chosen over integer-minor-units (cents) and plain numbers. Rationale: `Decimal` is *the* Elixir money idiom — Ecto `:decimal` columns, `ex_money`, and Rendro's own `lib/rendro/adapters/accrue.ex` already speak it, so the target Phoenix/Ecto billing caller passes what they already hold (least surprise); it is exact and deterministic (`Decimal.add/2` fold — no float drift, satisfies STMT-02); and `:decimal` is a featherweight, zero-transitive-dep package, so it does not violate the "dependency-light pure core" DNA (which targets heavy/leaky deps like Chrome/CLDR, not this). Reject integer-cents (off-by-100 and currency-exponent footguns, caller-side conversion friction) and float (money-in-float is a hard correctness bug). **Action for planner:** add `:decimal` to `mix.exs` core deps; validate amounts are `Decimal` at the boundary (reject `Float` with an instructive error).
- **D-05 [RECONCILED — line shape]:** **Each transaction line carries a SIGNED `Decimal` `amount`** (positive increases the balance, negative decreases it). Chosen over `debit:`/`credit:` columns and `type: :debit|:credit` + positive amount. Rationale: signed amounts make the running balance an unambiguous, exact `opening_balance + Σ amount` fold and **sidestep the contested debit-vs-credit balance-direction convention** (bank statements and AR/customer statements move the balance in *opposite* directions for the same "debit") — the recipe bakes in no perspective. The recipe renders a signed "Amount" column plus a running "Balance" column (the classic simple statement layout). *Mitigation for the silent-sign-flip footgun:* the running Balance column makes a wrong sign visually obvious, and validation rejects non-`Decimal`/`Float` amounts. (Splitting into conventional Debit/Credit display columns is a deferred `:columns` ergonomic — see Deferred.)
- **D-06:** **Caller does NOT supply per-line or running balances — the recipe computes them.** Single source of truth: `Enum.map_reduce`/`Decimal`-fold over `opening_balance + Σ amount`. `closing_balance` and `summary` (totals) are **optional caller assertions the recipe derives when absent**; a caller-supplied per-line `:balance` is rejected (so callers don't think it's honored).
- **D-07:** **Bare atom-keyed map, consistent with `Invoice` (STMT-03).** Not a typed struct, not keyword options. Required top-level keys: `period`, `account`, `opening_balance`, `lines`. Per-line: `%{date: Date.t(), description: String.t(), amount: Decimal.t()}`. `document(data, opts \\ [])` keeps Invoice's arity; `opts` (keyword) forwards to `page_template/1` and carries `:formatters`/`:labels` (D-10).
- **D-08:** **Validation is "errors-as-product" via a `validate_data!/1` that raises with what/where/why/next** — mirror the existing `Rendro.Recipes.BrandedInvoice.validate_data!/1` (`branded_invoice.ex:195`) pattern (raise `ArgumentError`/`Rendro.Error`-formatted message for missing required keys, invalid/non-`Decimal` amounts, malformed `period`). **No NimbleOptions** (wrong tool for nested line records; keeps deps light). Do NOT mix paradigms — raise for malformed call; the `{:ok|:error}` `Rendro.Error` contract stays at `Rendro.render/1`.

### Row-height drift mitigation (load-bearing — affects D-01 correctness)
- **D-09:** **Expose a thin, read-only PUBLIC measurement helper AND have the recipe reserve conservative capacity — do both.** The recipe must pre-chunk rows by `body_capacity`, but `body_capacity/1` (`measure.ex:442`, `paginate.ex:565`) and `measure_block/3` (`measure.ex:32`) are all `defp` — there is no public way for the recipe to ask the engine how tall its rows are. A recipe-local height *estimate* that diverges from the engine's actual `measure_block` produces **off-by-one page breaks → hard `:content_overflow`** (`paginate.ex:357`). Decision:
  1. **Promote a pure measurement projection to public API** (e.g. `Rendro.measure_rows/3` or `Rendro.Recipes.row_capacity/2`) so the recipe chunks using the engine's *own* numbers. This is a read-only projection of existing private logic — no pagination-behavior change, PAGE-04 single-pass preserved. (Researcher/planner to confirm the exact signature/placement and that it stays within "engine behavior unchanged.")
  2. **Recipe reserves a conservative margin** (pack to `body_capacity − one_row` epsilon) as defense-in-depth, so sub-pixel rounding never tips a page into overflow. A blank trailing row is a far better failure mode than a render error.
- **D-10 [page-grouping invariant]:** Structure each page's rows as one explicit ordered group `[brought_forward?, ...txns, carried_forward?]` with `break_before: true` on the **first** block of every page after page 1 (`maybe_break_before` only breaks when `hd(group).break_before` and the current page is non-empty). Do **not** also rely on the engine's keep-rules for these rows (that double-paginates); never set `keep_together` on a group larger than `body_capacity` (converts a soft re-break into a hard overflow). Add a recipe-level invariant test: page count matches `ceil`, and first/last rows of each page carry the right labels.

### Formatting & label policy
- **D-11:** **Pure `Rendro.Format` default + `:formatters` / `:labels` escape hatch.** Ship a sensible deterministic default formatter (`$1,234.50`, parentheses for negatives, ISO `YYYY-MM-DD` dates; labels "Balance" / "Brought forward" / "Carried forward" / "Opening balance" / "Closing balance"), implemented as a small pure module with **no CLDR/gettext in core** (locale-aware formatting is runtime-locale-dependent → non-deterministic). The default formatter MUST accept `Decimal` (and render it deterministically). Callers override via `formatters: [amount: fn, date: fn]` and `labels: %{...}` — full i18n/`ex_money` reachable from the *caller's* app without Rendro's core taking the dep. The formatter is applied to **both** caller-supplied amounts **and** recipe-computed running/carried balances.
- **Rejected:** per-column declarative `format: :currency` directives (drags a locale vocabulary into the engine's pure `table/2` primitive — core scope creep) and pre-formatted-strings-only (impossible: the recipe must format the balances it computes itself).

### Claude's Discretion
- Exact module layout of `Rendro.Recipes.Statement` (private builders mirroring `invoice.ex`), the `Rendro.Format` module's internal helpers (thousands grouping, negative handling), and the precise `validate_data!/1` message wording.
- The exact public signature/name/placement of the D-09 measurement helper (subject to researcher confirmation that it stays read-only and behavior-neutral).
- `period` shape (`Date.range/2` vs `%{from:, to:}`) — pick one, guard it, keep consistent.
- Whether `summary` totals are `%{total_debits:, total_credits:, line_count:}` or a superset.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` §STMT-01..STMT-04 — the locked WHAT for this phase.
- `.planning/ROADMAP.md` §"Phase 74: Statement Recipe" — goal + 4 success criteria.

### Phase 73 PAGE primitive (the dependency this phase consumes)
- `.planning/phases/73-page-numbering-running-region-primitive/73-CONTEXT.md` — D-01..D-11 (running-region `fn {page,total}` contract, fixed-reserved-height determinism D-04/D-09, no-engine-auto-measure D-05, single-pass/no-convergence PAGE-04). **Read before designing the footer and the recipe-owned pagination.**

### Engine & recipe code (verified during scout)
- `lib/rendro/recipes/invoice.ex` — three-rung reference (`document/2` / `page_template/1` / `sections/2`); the pattern Statement must stay consistent with (STMT-03).
- `lib/rendro/recipes/branded_invoice.ex:195` — `validate_data!/1` raise-with-guidance pattern to mirror (D-08).
- `lib/rendro/adapters/accrue.ex` — `format_amount/1` precedent (already handles integer and Decimal-like values); the in-ecosystem billing-amount convention.
- `lib/rendro/pipeline/paginate.ex` — single-pass body loop (~69), `maybe_break_before` (~321), `check_overflow!`/`validate_body_region_fit!` (~357), `body_capacity` (~565), `replace_page_numbers/2` + running-content seam (~426/464).
- `lib/rendro/pipeline/measure.ex` — `body_capacity/1` (~442), `measure_block/3` (~32), `measure_region_blocks` (~420). Source of the D-09 public-helper projection.
- `lib/rendro/block.ex:15` — `break_before` field (D-01/D-10).
- `lib/rendro.ex:210` — public `page_number/1` (footer, D-03); likely home for the D-09 measurement helper.
- `lib/rendro/error.ex` — `Rendro.Error` for D-08 instructive errors.
- `mix.exs` — core deps (add `:decimal` per D-04; `:decimal`/NimbleOptions currently absent).

### Vision / DNA (informed the reconciliations)
- `prompts/rendro-oss-dna.md` — pure dependency-light core, errors-as-product, optional-dep gating.
- `prompts/rendro-gsd-seed.md` — two-APIs-one-engine (Flow API for statements), architecture defaults.
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` §"Errors are part of the product" (~405-418), Flow/component API sketch (~371-401), footguns (~420-462).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rendro.Recipes.Invoice` (`invoice.ex`) — copy the three-rung skeleton (`document/2` → `page_template/1` → `sections/2`) and private `*_section/1` builder structure verbatim in spirit.
- `Rendro.Recipes.BrandedInvoice.validate_data!/1` (`branded_invoice.ex:195`) — exact raise-with-guidance validation idiom to reuse for D-08.
- `Rendro.page_number/1` (`rendro.ex:210`) — public PAGE-primitive footer helper for D-03; do not re-implement.
- `Rendro.Block` `break_before:` (`block.ex:15`) — public, paginator-honored (`paginate.ex:321`); the mechanism the recipe uses to force per-page breaks (D-01/D-10).
- `Rendro.Adapters.Accrue.format_amount/1` (`accrue.ex:125`) — existing amount-formatting precedent to align `Rendro.Format` with.

### Established Patterns
- Three-rung escape hatch — recipes author footers via `Rendro.section(region: :footer, content: [...])`; the PAGE footer plugs in there.
- Engine single forward pass over body blocks against `max_h = layout.body_capacity`, no convergence loop (Phase 73 PAGE-04). D-01 preserves this: the recipe pre-decides breaks; the engine never iterates.
- `deterministic: true` byte-identical contract from prior milestones — the Decimal fold + `Rendro.Format` must produce byte-identical output (no locale/runtime ambient state).

### Integration Points
- `body_capacity` math lives in two private sites (`measure.ex:442`, `paginate.ex:565`) — D-09 promotes a read-only projection of this to public API for the recipe.
- The recipe's pre-chunked groups feed the engine's existing `paginate_blocks` pass — D-09/D-10 keep the recipe's chunks ≤ engine capacity so the engine never re-breaks mid-chunk (no double-pagination, no stranded carried-forward row).

</code_context>

<specifics>
## Specific Ideas

- User (library author, technical, opinionated/decisive) explicitly requested a deeply-researched, one-shot, *correct* and *coherent* recommendation set — idiomatic for the Elixir/Phoenix/Ecto library ecosystem, with cross-ecosystem lessons (Stripe integer-minor-units, `ex_money`/`Decimal`, Ruby Money gem), great DX / principle of least surprise, and alignment to the project's pure-deterministic-core vision and `prompts/` research.
- Two orchestrator reconciliations beyond raw agent output, both documented: **D-04 (Decimal over integer-cents)** for caller least-surprise + ecosystem idiom, and **D-05 (signed amount over `type:`)** to avoid the debit/credit balance-direction convention trap. Both preserve exact-arithmetic determinism.
- The design deliberately pushes batteries-included ergonomics (pagination, balance math, formatting) to the **recipe layer**, keeping the engine pure/deterministic — continuing the Phase 73 philosophy. The one engine touch (D-09 read-only measurement helper) is justified specifically to keep recipe-owned pagination from silently drifting into `:content_overflow`.

</specifics>

<deferred>
## Deferred Ideas

- **Conventional Debit/Credit display columns** — rendering the signed amount as two side-by-side Debit and Credit columns (the literal printed bank-statement layout) via a `:columns` option. The signed-`amount` input model (D-05) already supports deriving this; ship the simple signed Amount + Balance layout first, add the column split as an ergonomic later if demanded.
- **Currency/locale-aware formatting in core** — explicitly out; the `:formatters` closure (D-11) is the supported i18n path (caller's `ex_money`/CLDR). Revisit only if Rendro adopts a formal i18n story.
- **Aligning the existing `Invoice`/`BrandedInvoice` recipes onto `Rendro.Format`** — those use crude `"$#{price}"`; a future cleanup, not this phase.

None other — discussion stayed within phase scope.

</deferred>

---

*Phase: 74-statement-recipe*
*Context gathered: 2026-05-29*
</content>
</invoke>
