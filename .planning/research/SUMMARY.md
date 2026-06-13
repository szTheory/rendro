# v2.8 Stewardship Research Summary

**Researched:** 2026-06-13 (5 parallel agents, code- and hex.pm-verified)
**Purpose:** Lock the *how* for each v2.8 requirement before roadmapping. Recommendations are cohesive with Rendro's identity: deterministic core, narrow proof-backed public surface, errors-as-product, quiet pull-based posture, demand-gated growth.

These are locked recommendations, not options. Each is grounded in the live codebase.

---

## DX-01 / DX-02 — `Rendro.Recipes` facade

**Locked design:** Expose all five recipes through `Rendro.Recipes` as hand-written, `@spec`'d **arity-1 + arity-2** wrapper pairs that thread `opts` to each recipe's `document/2`. Keep the individual `Rendro.Recipes.*` modules as the canonical documented entry; the facade is a thin convenience index (the **Ecto** model — `Ecto.Query` is primary, `Ecto` is thin — not the flat **Req** model).

- **Functions (10):** `invoice/1,2`, `branded_invoice/1,2`, `statement/1,2`, `receipt/1,2`, `certificate/1,2`. Each `name/1` funnels to `name/2` with `[]`; each `name/2` calls `Module.document(data, opts)`.
- **Fix the live opts-drop:** today `invoice/1` → `Invoice.document/1`, silently dropping `:formatters`/`:labels`/`:border`/`:page_number_opts`. README line ~135 documents this drop and must be updated. This is the headline footgun (same class as wkhtmltopdf wrappers ignoring page-size opts).
- **Naming:** use `receipt`, NOT `report`/`receipt_report`/an alias. "Report" is a usage framing of the same recipe; document it in `receipt/2`'s `@doc`, don't mint a second function (avoids "naming implies more than delivered").
- **Hand-written wrappers, not `defdelegate`:** facade names (`invoice`) differ from the recipe entry (`document`), so `defdelegate` needs `as: :document` everywhere and still requires a hand-written stable-tier `@spec`. Wrappers co-locate `@doc`/`@spec`/body and stay greppable.
- **Arity pair, not default arg:** `def invoice(data, opts \\ [])` would *replace* `invoice/1` with `invoice/2` in `priv/public_api.json` → the API-contract lane reads it as a stable-surface change. Arity-1 + arity-2 is purely **additive** — preserves the existing Tier-1 `invoice/1` symbol.
- **DX-02 drift test** (`test/rendro/recipes/facade_drift_test.exs`): a `@recipes` roster table drives three assertions — (1) each recipe reachable as `name/1` and `name/2`; (2) MapSet equality so the facade exposes **no extra** functions (catches stray alias/orphan); (3) `Rendro.Recipes.name(data, opts) == Module.document(data, opts)` byte-identical delegation (catches mis-wiring/opts-drop). One row added when a 6th recipe ships.
- **Mandatory companion:** run `mix rendro.api.gen` to regenerate `priv/public_api.json` (currently `["branded_invoice/1","invoice/1"]` → 10-fn set) or `public_api_contract_test.exs` (14th docs-contract lane) fails the byte-compare; it also asserts every stable-tier fn has an `@spec` (why every wrapper carries one).
- **Do NOT add validation to the facade** — each module already owns errors-as-product `validate_data!/1` (single validation path, per v2.4 decision).

---

## HYG-01 — ExDoc hidden-reference warnings (real: ~16 warnings today)

Two distinct causes, two fixes:

1. **Prose `@doc` refs to hidden internals** (`Rendro.Format`, `Rendro.PDF.CidFont`, `Rendro.PDF.FontSubsetter` named in `statement.ex`/`receipt.ex`/`rendro.ex` prose). **Fix:** add a `skip_code_autolink_to:` list in `mix.exs docs/0` (target-matched; keeps prose, drops the broken link). This is **Req's** documented pattern.
   - **Verified pitfall:** `skip_undefined_reference_warnings_on` does NOT suppress these — it matches the *referencing* file, not the hidden *target* (ExDoc issue #1306). Rendro already lists files there and the warnings still fire. Wrong tool.
2. **Type `Rendro.PDF.Font.t()` in public `@spec`s** of `Rendro.FontRegistry` / `Rendro.Text.Shaper` / `Rendro.Text.Shaper.Simple`. `skip_code_autolink_to` does NOT gate typespec autolinks (verified empirically). **Fix:** give `Rendro.PDF.Font` a real `@moduledoc` marking it internal/unstable-fields. **Verified safe:** `Rendro.PDF.Font` is NOT in `priv/public_api.json` and NOT in the asserted-hidden list of `public_api_contract_test.exs` (which covers exactly `CidFont, FontSubsetter, Text.Bidi, Format, Audit`) — documenting it breaks no contract.
   - Optional sidebar polish: add `"Internal Types": [Rendro.PDF.Font]` to `groups_for_modules` to keep it out of the Core Builder API TOC.

**Policy:** adopt "zero unexplained doc warnings" and enforce it by adding `docs --warnings-as-errors` to the `ci` alias (ExDoc flag since v0.36.0; matches the existing guardrail-lockstep discipline). Result verified: `mix docs` emits zero warnings after both fixes.

---

## HYG-02 — viewer-evidence staleness noise (currently LATENT)

**Finding:** nothing is stale today — all evidence recorded 2026-05-29/06-13, 180-day threshold isn't hit until **~late Nov 2026**, and the staleness check runs only in `mix rendro.viewer_evidence validate` (operator task), **not in `mix ci`**. So it is a *future* operator-only signal, not active routine noise.

**Locked (do NOT silence, raise threshold, or pre-emptively re-record — all violate proof-backed truthfulness):**
1. Keep 180-day threshold, advisory-by-default / fatal-under-`--strict` (already implemented and correct — can't hide rot, isn't in CI).
2. Make the staleness line **self-explaining**: append remediation (`re-record via 'mix rendro.viewer_evidence record <surface> <viewer>'; advisory outside --strict; see guides/viewer_evidence.md`) in `validator.ex` (~line 105).
3. Document the staleness lifecycle in `guides/viewer_evidence.md` so a maintainer seeing it post-Nov-2026 knows it's a designed cadence signal, not a defect.

This is a docs + wording change now; real re-recording is a deliberate operator evidence event when the warning actually fires.

---

## PROOF-01 — header `only_on: :odd|:even` E2E proof depth

Headers and footers share the same code path (`apply_page_template/5` → `running_region_entries/2` → `apply_only_on/3` at `paginate.ex:729-739`, region-agnostic, keyed on `rem(page_idx,2)`). Footers have BOTH render-layer (`flow_test.exs:268`) and paginate-layer (`paginate_test.exs:754/789`) proofs; headers have only a compose-layer assertion (`compose_test.exs:210`). Close that gap by mirroring the footer proofs.

**Locked:**
1. **Render-layer E2E** in `test/rendro/flow_test.exs`: mirror `flow_test.exs:268` swapping `region: :footer`→`:header`; assert on byte-stable content stream (`pdf =~ "(Odd 1) Tj"`, `"(Even 2) Tj"`, `refute pdf =~ "{{page_number}}"`). Output is deterministic (pinned `@deterministic_date`), so no flakiness. Size the body so the doc spans ≥4 physical pages (assert `Odd 1/Even 2/Odd 3/Even 4`).
2. **Paginate-layer** in `test/rendro/pipeline/paginate_test.exs`: mirror `:789` with a `page_numbering: [restart: true]` body + header `only_on:` carrying `{{section_page_number}}`, using `paginate_flow/1` + `page_texts/1`, to prove **physical** parity while header tokens stay **section-local** (the locked PROJECT.md decision).

**Reject** Poppler-per-page (adds binary dependency, asymmetric) and golden-bytes (over-couples; a parity bug and a kerning tweak look identical).

**Edge cases:** first-page parity (page-1 = odd, off-by-one guard); ≥2 odd AND ≥2 even pages; restart-section physical-vs-section parity (highest value); single-page doc (only `:odd` appears); header+footer `only_on` coexisting (independent `region_entries`); token non-substitution leak.

---

## SIGNAL-01 — adoption-signal review

**Locked:** append a single dated review to the existing `## Review Log` in `ADOPTION.md` (one table row + a short dated prose block). **No `mix` task** — a snapshot task would add a public surface + test + docs-contract obligation to a near-done lib (the machinery-deepening MILESTONE-ARC warns against). The existing `curl … | jq '.downloads'` one-liner IS the helper.

- **Cadence:** pull-based, never scheduled. Triggers: a new `area:text-shaping`/`adoption:signal` issue, OR milestone-planning, OR a standing re-review floor that always records the next earliest re-check date (can't be silently forgotten or nagged).
- **Decision rule (four verdicts):** TRIGGER (all 3 threshold families met → *propose* gated milestone; necessary-not-sufficient, maintainer still chooses) · ACCUMULATING · HOLD · HOLD(noise). Resists hype (stars/+1/generic i18n don't count) and neglect (HOLD always writes a concrete next trigger).
- **Write now (demand ≈ zero, verified live):** hex `downloads.all` 867→877, `week` 115→117 over the day — noise, far below the `+1,500 all` / `≥150 week` gate. First dated **HOLD** review; next trigger = first qualifying issue OR 2026-12-13 OR next milestone planning.
- **OSS lessons:** curl ("not a democracy"; demand must be *demonstrated*, not voted), SQLite (deferrals on the record), Node ("feature requests aren't valuable input"; the PR is the signal), Rust RFC (don't import RFC ceremony → burnout). Pattern: demonstrated-not-expressed demand, deferrals recorded openly, near-zero per-cycle cost.

---

## STEW-01 — done-enough stewardship posture

**Locked: two locations, no new files** (a `guides/project_status.md` would be another doc to keep truthful — against Rendro's DNA):

1. **Internal** — new `## Stewardship Posture (Done-Enough)` section in `.planning/MILESTONE-ARC.md` under `## Active Strategic Arc`, with a **Posture last reviewed** date: Rendro is ~90-93% done-enough; standing rule = prefer stewardship/hygiene/adoption work, do NOT deepen proof/viewer machinery by default, new feature family must prove *why necessary*; named non-goals carried as deliberate demand-gated deferrals (NOT abandonment), each tied to `ADOPTION.md`.
2. **Public** — new `## Project Status & Stewardship` section at the top of `guides/api_stability.md` (already the canonical support-language surface, already on HexDocs, already README-linked): "Stable and actively stewarded · feature-complete for its stated scope," with explicit commitments (bug/security fixes prioritized; issues read, best-effort pull-based responses; deterministic core + SemVer honored) and "new capabilities are demand-gated, not abandoned" pointing to `ADOPTION.md` with an invitation to file qualifying signal.
3. **Optional** — one-line README Guides-bullet tweak so status is discoverable from the front page. No new README section.

**Messaging:** signal "stable & cared-for," never "abandoned." Use a *Last reviewed* date (converts quiet→deliberately quiet); commit to bugfix/security; frame non-goals as "deliberately deferred pending demand" with a path to change it. Avoid the terminal-word trap (libxml2's one-word "unmaintained" triggered downstream panic; MinIO/IBM "no longer maintained"). Borrow crates.io `passively-maintained`/`as-is` *phrasing* (skip the badge), SQLite LTS commitment framing, Rust "stability without stagnation / you never dread upgrading."

---

## Cohesion

All six recommendations reinforce one identity: a narrow, deterministic, proof-backed public surface kept honest by mechanical contracts (drift test, docs-contract lane, `--warnings-as-errors`), with truthfulness never traded for quiet (staleness stays visible, evidence never fake-refreshed), and growth strictly demand-gated and recorded openly. Nothing here widens the core pipeline or the optional-adapter boundary.

---

## Roadmapping note

These map cleanly to logical phases (suggested grouping for the roadmapper, continuing numbering from Phase 92 → Phase 93+):
- **DX-01/DX-02** — facade + drift test + api.gen regen + README update (one phase; touches `priv/public_api.json` contract).
- **HYG-01** + **HYG-02** — docs/warning hygiene (one phase; `mix.exs` + `Rendro.PDF.Font` moduledoc + validator wording + guide).
- **PROOF-01** — header duplex proof (one phase; pure test additions).
- **META-01** — validation/Nyquist metadata reconcile (small; can fold with PROOF-01 or stand alone).
- **SIGNAL-01** + **STEW-01** — adoption review + stewardship posture docs (one phase; pure docs, cohesive pair).

The roadmapper owns final phase boundaries; this is advisory.
