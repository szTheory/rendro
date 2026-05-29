# Phase 74: Statement Recipe - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 74-statement-recipe
**Areas discussed:** Per-page balance strategy, Statement data-map contract, Footer/header composition, Formatting policy
**Mode:** Advisor (minimal_decisive → escalated to deep two-round parallel research at user request)

---

## Per-page balance strategy (STMT-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Recipe pre-chunks rows | `sections/2` computes capacity, folds running balance, splits rows into per-page groups with `break_before: true`; engine unchanged | ✓ |
| Engine table-continuation + post-pagination seam | Inject carried/brought via a `{page,total}` per-page hook | |

**User's choice:** Recipe pre-chunks (D-01).
**Notes:** 3 of 4 research agents independently found the post-pagination seam architecturally blocked — it only sees `{page_number, total_pages}`, never which body rows landed on a page, so a per-page balance is uncomputable there without a feedback hook that risks the PAGE-04 convergence loop.

---

## Statement data-map contract (STMT-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Money: integer minor units (cents) | Stripe idiom, zero dep, exact; caller converts; off-by-100/exponent footguns | |
| Money: `Decimal` | Elixir money idiom (Ecto/ex_money/accrue), exact, least-surprise for caller; adds featherweight `:decimal` dep | ✓ |
| Money: plain number/float | Matches current Invoice; float-money is a correctness bug | |
| Line: signed `amount` | Unambiguous `opening + Σ amount` fold; no debit/credit convention baked | ✓ |
| Line: `debit:`/`credit:` columns | Mirrors printed columns; invalid-state risk (both/neither set) | |
| Line: `type: :debit\|:credit` + positive amount | Explicit, loud errors; but requires recipe to bake a contested balance-direction convention | |
| Container: bare atom-keyed map | Consistent with Invoice (STMT-03) | ✓ |
| Container: typed struct | Compile-time safety; breaks Invoice consistency | |
| Validation: `validate_data!/1` raise w/ guidance | Mirrors BrandedInvoice; errors-as-product | ✓ |

**User's choice:** Decimal + signed amount + bare map + `validate_data!/1` (D-04..D-08).
**Notes:** User asked for a deep, correct, one-shot coherent set. Two cross-agent conflicts resolved by orchestrator: (1) **Decimal over integer-cents** — weighted least-surprise-for-target-caller + Elixir/Phoenix/Ecto idiom over zero-dep, since `:decimal` is featherweight and ubiquitous and the "dependency-light" DNA targets heavy/leaky deps; (2) **signed amount over `type:`** — signed sidesteps the bank-vs-AR debit/credit balance-direction convention trap and keeps the fold exact and unambiguous. Recipe computes balances (no caller per-line balance).

---

## Footer/header composition (STMT-02 + STMT-04)

| Option | Description | Selected |
|--------|-------------|----------|
| Balances in BODY rows; footer = "Page X of Y" only | Carried = last body row, brought = first body row; footer carries only the PAGE primitive | ✓ |
| Balances in footer/header running regions | Blocked: running-content `fn {page,total}` can't see per-page body content | |

**User's choice:** Balances in body, footer page-number only (D-02/D-03).
**Notes:** Same root constraint as the balance strategy — running regions are page-number-aware, not page-content-aware. Coherence review surfaced a load-bearing caveat (D-09): the recipe can't call the engine's private measurement, risking off-by-one `:content_overflow`; mitigation = expose a read-only public measure helper + reserve conservative capacity.

---

## Formatting policy

| Option | Description | Selected |
|--------|-------------|----------|
| Hardcoded `Rendro.Format` default + `:formatters`/`:labels` escape hatch | Pure, deterministic, no CLDR in core; i18n via caller closure | ✓ |
| Per-column declarative `format: :currency` directives | Drags locale vocabulary into the engine's pure table primitive (scope creep) | |
| Pre-formatted strings only | Impossible — recipe must format the balances it computes | |

**User's choice:** Pure default + escape hatch (D-11).
**Notes:** CLDR/ex_money are runtime-locale-dependent → non-deterministic; kept out of core, reachable via the caller's `:formatters` closure. Default must accept `Decimal`.

## Claude's Discretion

- Statement module/private-builder layout; `Rendro.Format` internals; `validate_data!/1` message wording.
- Exact signature/name/placement of the D-09 public measurement helper (pending researcher confirmation it stays behavior-neutral).
- `period` shape (`Date.range/2` vs `%{from:, to:}`); `summary` totals superset.

## Deferred Ideas

- Conventional Debit/Credit display columns via a `:columns` option (signed input already supports the derivation).
- Currency/locale-aware formatting in core (use the `:formatters` closure instead).
- Migrating existing Invoice/BrandedInvoice recipes onto `Rendro.Format`.
</content>
