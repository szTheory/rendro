# Phase 95: Header Duplex Proof & Metadata Reconcile - Research

**Researched:** 2026-06-13
**Domain:** Elixir test authoring (PDF content-stream proofs) + GSD validation-metadata reconcile
**Confidence:** HIGH (all PROOF-01 mechanics empirically verified by running probe scripts against the live engine; all META-01 cell counts and frontmatter states verified by direct file inspection)

## Summary

PROOF-01 adds header-specific `only_on: :odd | :even` proof at parity with the shipped footer coverage. The `only_on` engine (`apply_only_on/3`, paginate.ex:729-739) is region-agnostic — it filters any running entry by physical `page_idx` parity, and `apply_page_template/5` (paginate.ex:558-573) iterates **all non-body regions independently**, pulling each region's entries from the per-region `region_entries` map (compose.ex:117-124). Header parity therefore works through the exact same code path footers already exercise; this phase is purely additive test coverage, no engine change. I verified all four render-layer assertions, all three D-04 edge cases, and the D-03 paginate coexistence by executing throwaway probes against the real pipeline — every one passed.

META-01 has one genuine research gate (D-07) and one **correction to a CONTEXT.md premise** the planner must absorb: of the four D-06 targets, only **90 and 92** contain the claimed intra-file contradiction (`status: approved` + `nyquist_compliant: true` vs. `pending` task cells). **88 is materially different** — its entire frontmatter is `status: draft` / `nyquist_compliant: false` / `wave_0_complete: false` with `**Approval:** pending` and all checkboxes unchecked. 88's `pending` cells are internally *consistent* with a draft Nyquist planning artifact, not contradictory. The v2.6 audit explicitly records this state (line 39). **91 has no `pending` task cells at all** — it is a plan-time "Validation Map" whose only status marker is the `**Status:** Planned` header.

**Primary recommendation:** PROOF-01 — clone flow_test.exs:268 with `role: :header` + a header region (y:24, h:16), bump body to `1..16` lines → exactly 4 pages (verified). Extend paginate_test.exs:685 pattern with a header region + odd/even header sections (verified). META-01 — flip `pending`→`passed` in the **90 (3 cells)** and **92 (4 cells)** task tables only; set **91**'s `**Status:** Planned`→`passed`; **do NOT touch 88's task cells** without also reconciling its draft frontmatter (flag to planner — see D-06 Correction). **Leave all frontmatter `status:` untouched** (D-07 resolved: no milestone-wide terminal convention exists).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Header `only_on` physical parity | Paginate (`apply_only_on/3`) | Compose (`region_entries`) | Already shipped + region-agnostic; phase only adds tests over it |
| Header/footer independence | Compose (`region_entries` per-region map) | Paginate (`apply_page_template` per-region loop) | Each region's entries filtered independently keyed on physical `page_idx` |
| Render-layer byte proof | Test (`flow_test.exs`) | — | Asserts on content stream `(Text) Tj`, `/Type /Page` count, token refute |
| Paginate-layer structural proof | Test (`paginate_test.exs`) | — | Asserts `page_texts/1` per page |
| Validation-metadata truth | Docs (`.planning/milestones/v2.6,v2.7-phases`) | — | Markdown-only reconcile; no code/CI/contract impact |

## Standard Stack

No new packages. This phase uses only the existing project test stack.

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit | bundled w/ Elixir | Test framework | Already the project's sole test framework |
| Regex (stdlib) | bundled | Content-stream byte assertions | Established pattern (`Regex.scan(~r"/Type\s*/Page\b", pdf)`) [VERIFIED: flow_test.exs:324] |

**No Package Legitimacy Audit required** — phase installs nothing.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-01 | Direct E2E test renders header `only_on: :odd|:even` and asserts correct physical pages, at footer parity | D-02 render-layer geometry + assertions VERIFIED (4-page probe passed); D-03 paginate coexistence VERIFIED (3-page probe passed); D-04 all 3 edge cases VERIFIED |
| META-01 | Reconcile stale v2.6/v2.7 validation metadata; no false-pending/false-incomplete markers | Exact cell counts + frontmatter states VERIFIED per-file; D-07 gate resolved (see Open Questions / D-07) |

## Architecture Patterns

### How header+footer `only_on` independence actually works (VERIFIED)

```
Compose.run (compose.ex:117-124)
  region_entries = group_by(:region) over [header entries, footer entries, body...]
  → %{header: [odd_h, even_h], footer: [odd_f, even_f], ...}   # per-region, independent

Paginate.apply_page_template/5 (paginate.ex:558-573)
  template.regions |> reject(body) |> flat_map(fn region ->
    running_region_entries(layout, region.name)         # pulls THIS region's entries only
    |> flat_map(running_entry_blocks(&1, idx, total, ctx))
  end)

running_entry_blocks/4 (paginate.ex:625-632)
  |> apply_only_on(entry.only_on, page_idx)   # paginate.ex:729-739, keyed on PHYSICAL page_idx
```

`apply_only_on/3` is region-blind — it only sees `blocks`, the `:odd|:even` atom, and the physical `page_idx`. Header and footer are separate `region_entries` keys processed in separate loop iterations, so their parities cannot interfere. This is exactly SC #3's "independent `region_entries`" claim. [VERIFIED: code read + coexistence probe — `HOdd 1/FOdd 1` on p1, `HEven 2/FEven 2` on p2 both present]

### Page-geometry / pagination math (VERIFIED)

- Default text: `size: 12`, `line_height: 1.2` → **14.4 pt/line** [VERIFIED: lib/rendro/text.ex:18,20; measure.ex:69]
- `body_capacity = body_h − header_h − footer_h` (measure.ex:483-510). **header_h/footer_h are subtracted ONLY if the region geometrically overlaps the body band.** A header at y:24 h:16 (ends y:40) above body at y:52 does NOT overlap → header_h=0 → body_capacity = body_h unchanged. [VERIFIED: code + 4-page probe gave identical capacity to footer test]
- Footer test (flow_test.exs:268): body_capacity 60 / 14.4 = **4 lines/page**; 8 lines → 2 pages. [VERIFIED by running the test]

### Anti-Patterns to Avoid
- **Do NOT rasterize / Poppler-per-page / golden-byte fixtures** — rejected by D-01. Assert on the byte-stable content stream directly. [CITED: 95-CONTEXT.md D-01]
- **Do NOT add a header region that overlaps the body band** unless you intend to shrink body_capacity — it changes the page count and breaks the parity arithmetic.
- **Do NOT duplicate the existing `only_on` unit/validation coverage** (compose_test.exs, rendro_builders_test.exs already cover validation). [CITED: 95-CONTEXT.md canonical_refs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Proving running-content parity | Per-page raster diff harness | Content-stream `=~`/`Regex.scan` assertions | Byte-stable, fast, matches shipped footer proof |
| New test template helper | A shared header-template module | Inline template in the test (or copy footer's inline `page_template`) | Footer test uses inline templates; consistency + zero new infra (D-04 discretion allows either) |

## Code Examples

### PROOF-01 render-layer (D-02) — VERIFIED to produce exactly 4 pages

Clone `flow_test.exs:268`, change `role: :footer`→`:header`, add a header region, bump `1..8`→`1..16`:

```elixir
# Source: VERIFIED probe against live engine (4 pages, all 4 assertions pass, no token leak)
test "only_on odd and even header sections render on physical page parity" do
  template =
    Rendro.page_template(
      name: :duplex_header_test,
      width: 420, height: 220,
      margin_top: 20, margin_right: 24, margin_bottom: 20, margin_left: 24,
      regions: [
        Rendro.region(name: :header, role: :header, anchor: :top,
          x: 24, y: 24, width: 372, height: 16),          # y:24 h:16 ends y:40, above body → no capacity hit
        Rendro.region(name: :body, role: :body, anchor: :flow,
          x: 24, y: 52, width: 372, height: 60)            # body_capacity = 60 → 4 lines/page
      ]
    )

  odd_header =
    Rendro.section(region: :header, only_on: :odd,
      content: [Rendro.block(Rendro.text("Odd {{page_number}}"))])

  even_header =
    Rendro.section(region: :header, only_on: :even,
      content: [Rendro.block(Rendro.text("Even {{page_number}}"))])

  doc =
    Rendro.flow(
      for(i <- 1..16, do: Rendro.block(Rendro.text("Line #{i}"))),  # 16 lines / 4 per page = 4 pages
      page_template: :duplex_header_test,
      page_templates: [template],
      sections: [odd_header, even_header]
    )

  {:ok, pdf} = Rendro.render(doc)

  assert length(Regex.scan(~r"/Type\s*/Page\b", pdf)) == 4
  assert pdf =~ "(Odd 1) Tj"     # page 1 = odd (first-page parity anchor)
  assert pdf =~ "(Even 2) Tj"
  assert pdf =~ "(Odd 3) Tj"
  assert pdf =~ "(Even 4) Tj"
  refute pdf =~ "{{page_number}}"   # substitution happened, no token leak
end
```

`Rendro.render/1` returns `{:ok, pdf_binary}`. [VERIFIED: flow_test.exs:322 + probe]

### PROOF-01 paginate-layer (D-03) — VERIFIED to produce header parity + section-local footer tokens

The existing `section_context_template` (paginate_test.exs:1215-1245) has only `body` + `footer` regions — **you must add a `:header` region to it** (or define a local template). Extend the restart pattern from paginate_test.exs:685:

```elixir
# Source: VERIFIED probe — 3 pages: header physical parity coexists with footer section-local tokens
test "header only_on physical parity coexists with restart section tokens" do
  # template = section_context_template() PLUS a header region:
  template = %PageTemplate{
    name: :section_context_header,
    width: 420, height: 240,
    margin_top: 20, margin_right: 24, margin_bottom: 28, margin_left: 24,
    regions: [
      %Region{name: :header, role: :header, anchor: :top, x: 24, y: 24, width: 372, height: 20},
      %Region{name: :body, role: :body, anchor: :flow, x: 24, y: 52, width: 372, height: 30},
      %Region{name: :footer, role: :footer, anchor: :bottom, x: 24, y: 200, width: 600, height: 20}
    ]
  }

  odd_header  = Rendro.section(region: :header, only_on: :odd,
                  content: [Rendro.page_number(format: "HOdd P{{page_number}}")])
  even_header = Rendro.section(region: :header, only_on: :even,
                  content: [Rendro.page_number(format: "HEven P{{page_number}}")])
  footer      = Rendro.section(region: :footer,
                  content: [Rendro.page_number(format: "S{{section_page_number}}/{{section_total_pages}}")])
  appendix    = Rendro.section(name: :appendix, region: :body, page_numbering: [restart: true],
                  content: for(i <- 1..3, do: Rendro.block(Rendro.text("Appendix #{i}"))))

  doc =
    Rendro.flow([Rendro.block(Rendro.text("Intro"))],
      page_template: :section_context_header,
      page_templates: [template],
      sections: [appendix, odd_header, even_header, footer])

  assert {:ok, paginated} = paginate_flow(doc)
  assert length(paginated.pages) == 3
  [page1, page2, page3] = paginated.pages

  # page_texts/1 returns HEADER first, then FOOTER, then BODY blocks (verified ordering).
  # Header shows PHYSICAL parity; footer S-token shows SECTION-LOCAL numbering (restart).
  assert page_texts(page1) == ["HOdd P1",  "S1/1", "Intro"]
  assert page_texts(page2) == ["HEven P2", "S1/2", "Appendix 1", "Appendix 2"]
  assert page_texts(page3) == ["HOdd P3",  "S2/2", "Appendix 3"]
end
```

**Block ordering caveat (VERIFIED):** within a page, `page_texts/1` lists header region blocks first, footer next, body last (running regions are prepended in template-region order via `anchored_blocks ++ page.blocks`, paginate.ex:572). Assert the full list as above, or filter to the header block if you want order-independence. `paginate_flow/1` and `page_texts/1` helpers already exist (paginate_test.exs:1145, 1152). [VERIFIED]

### PROOF-01 edge cases (D-04) — all three VERIFIED

```elixir
# Single-page doc: only :odd appears  (VERIFIED: pages=1, "(Odd 1) Tj" present, no "(Even")
#   → one body block ("Solo"), same template as render test.
#   assert length(Regex.scan(~r"/Type\s*/Page\b", pdf)) == 1
#   assert pdf =~ "(Odd 1) Tj"
#   refute pdf =~ "(Even"

# First-page parity: covered by the main render test — page 1 = "(Odd 1)", page 1 has no Even.
#   To assert "even header absent on page 1" cleanly at render layer, the page-count + the
#   ordered presence of "(Odd 1)" before "(Even 2)" already proves it; for an explicit refute,
#   use a single-page doc (above) where Even never appears.

# Header + footer coexistence via independent region_entries  (VERIFIED: pages=2)
#   header region y:24 h:16 + footer region y:190 h:16 (both outside body band y:52..112)
#   sections: [odd_header, even_header, odd_footer, even_footer]
#   assert pdf =~ "(HOdd 1)" and pdf =~ "(FOdd 1)"     # page 1: both odd variants
#   assert pdf =~ "(HEven 2)" and pdf =~ "(FEven 2)"   # page 2: both even variants
#   This proves header parity and footer parity do not interfere (separate region_entries keys).
```

## Runtime State Inventory

> Greenfield-equivalent for runtime state: this phase writes only test files and edits markdown. No databases, services, OS registrations, secrets, or build artifacts are touched. The one "stored state" concern is the **validation-metadata markdown itself** (META-01), which is the deliverable, not incidental state.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — verified: no DB, no datastore. | None |
| Live service config | None — verified: no external service config. | None |
| OS-registered state | None. | None |
| Secrets/env vars | None. | None |
| Build artifacts | None — new tests compile into the existing suite; no package/version change. | None |

## Common Pitfalls

### Pitfall 1: Header region geometry silently changes page count
**What goes wrong:** Placing the header region so it overlaps the body band (e.g., header y:40 h:20 ending at y:60 > body start y:52) subtracts `header_h` from `body_capacity`, changing lines/page and breaking the `(Odd 1)..(Even 4)` arithmetic.
**Why it happens:** `body_capacity` overlap test in measure.ex:489-497.
**How to avoid:** Keep header strictly above body start (y+h ≤ body.y). The verified geometry (header y:24 h:16, body y:52 h:60) leaves body_capacity = 60. [VERIFIED]
**Warning signs:** Page count ≠ 4; `(Even 4) Tj` missing.

### Pitfall 2: Asserting paginate header tokens in the wrong list position
**What goes wrong:** `page_texts/1` returns header blocks first, then footer, then body. Asserting `["Intro", "HOdd P1"]` fails.
**How to avoid:** Use the verified ordering `["HOdd P1", "S1/1", "Intro"]`, or filter to the header block.

### Pitfall 3 (META-01): Treating 88 like 90/92 creates a NEW contradiction
**What goes wrong:** D-06 lists 88 (5 cells) alongside 90/92 as a "false-pending contradicting `status: approved`". But 88's frontmatter is `status: draft` / `nyquist_compliant: false` / `**Approval:** pending`. Flipping 88's task cells to `passed` while leaving the draft frontmatter makes the file say "all tasks passed" inside a doc that declares itself an un-approved draft — a brand-new intra-file contradiction, which D-05's own rationale forbids.
**How to avoid:** See "D-06 Correction" below — recommend the planner either (a) leave 88 entirely untouched (its pending cells are consistent with its draft state), or (b) escalate 88 as out-of-band, because making 88 truthful requires reconciling frontmatter too, which D-07 says to avoid.

## State of the Art

Not applicable — no external library landscape. Conventions are project-internal (verified in-repo below).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | (none) | — | All claims verified by tool (engine probes, file inspection) or cited to CONTEXT.md/in-repo files. |

**This table is empty by design** — every factual claim was verified against the live engine or by direct file read. No training-data assumptions remain.

## Open Questions

### D-07 RESEARCH GATE — RESOLVED: do NOT touch frontmatter `status:`

**Question:** Is there a milestone-wide terminal `status:` convention, or is `draft` the un-advanced GSD default present even on genuinely-complete phases?

**Evidence (VERIFIED — full frontmatter `status:` census):**

| File | Frontmatter `status:` | In milestone audit? |
|------|----------------------|---------------------|
| v2.6 83-VALIDATION.md | `draft` | yes, passed |
| v2.6 84-VALIDATION.md | `draft` | yes, passed |
| v2.6 85-VALIDATION.md | `verified` | yes, passed |
| v2.6 87-VALIDATION.md | `complete` | yes, passed |
| v2.6 88-VALIDATION.md | `draft` | yes, complete |
| v2.7 90-VALIDATION.md | `approved` | yes, passed |
| v2.7 91-VALIDATION.md | (no frontmatter; `**Status:** Planned`) | yes, passed |
| v2.7 92-VALIDATION.md | `approved` | yes, passed |
| current 93-VALIDATION.md | `draft` | (open milestone) |
| current 94-VALIDATION.md | `draft` | (open milestone) |

**Finding:** There is **NO milestone-wide terminal convention.** Terminal `status:` values are inconsistent across done phases (`verified`, `complete`, `approved`, and `draft` all coexist among audited-passed phases). `draft` is demonstrably the un-advanced GSD default — it sits on genuinely-complete phases 85-era 83/84/88 AND on the current done phases 93/94. [VERIFIED: full census above]

**Recommendation (definitive):** **Leave all frontmatter `status:` fields untouched.** Per D-07, flipping v2.6/v2.7 frontmatter to a terminal token would create *new* cross-archive inconsistency (e.g., making 88 `approved` while 83/84 and current 93/94 stay `draft`). Reconciling only the in-file table/heading markers (D-06) is sufficient to remove the *false-pending* contradiction. The frontmatter `draft` default is systemic and resolves when the milestone closes — explicitly out of META-01 scope (CONTEXT.md deferred note).

### D-06 CORRECTION — the planner must absorb this before writing tasks

The D-06 premise that all four files have "false-pending contradicting `status: approved`" holds for **only 90 and 92**. Verified per-file:

| File | Frontmatter | Approval line | Checkboxes | `pending` task cells | Genuine intra-file contradiction? | Recommended action |
|------|-------------|---------------|-----------|----------------------|-----------------------------------|--------------------|
| **90** | `status: approved`, `nyquist_compliant: true`, `wave_0_complete: true` | `approved 2026-06-13` | all `[x]` | **3** (lines 35-37) | YES | flip 3 cells `pending`→`passed` |
| **92** | `status: approved`, `nyquist_compliant: true`, `wave_0_complete: true` | `approved 2026-06-13` | all `[x]` | **4** (lines 36-39) | YES | flip 4 cells `pending`→`passed` |
| **91** | no frontmatter | header `**Status:** Planned` (line 4) | n/a | **0** (it's a plan-time Validation Map, no per-task status column) | header is stale (audit says passed) | set `**Status:** Planned`→`passed` (line 4) |
| **88** | `status: draft`, `nyquist_compliant: false`, `wave_0_complete: false` | `**Approval:** pending` (line 91) | all `[ ]` | **5** (lines 43-46) | **NO — cells are CONSISTENT with the draft state** | **flag/hold** — see below |

**88 specifics (VERIFIED):** frontmatter lines 3-5 = `status: draft` / `nyquist_compliant: false` / `wave_0_complete: false`; line 91 = `**Approval:** pending`; checkboxes all unchecked. The v2.6 milestone audit (line 39) **explicitly documents** this: *"88-VALIDATION.md remains a draft Nyquist planning artifact even though 88-VERIFICATION.md records automated completion."* So 88's 5 `pending` cells are NOT a false-pending contradiction — they are honest for a draft artifact. Flipping only the cells (per D-06) would make 88 self-contradictory in the way D-05 prohibits.

**Recommendation for 88:** Default to **leave 88 untouched** — its in-file markers are already internally consistent, so there is no "false-pending contradiction" to remove (the criterion's defect target). If the user/planner wants 88 to read as terminally complete, that requires reconciling frontmatter (`draft`→terminal, `nyquist_compliant`/`wave_0_complete`→true, `Approval`→a date) — which D-07 says to avoid because it creates cross-archive frontmatter inconsistency. Surface this as a planning decision rather than executing a partial flip.

**Terminal token confirmation (VERIFIED):** `passed` is the dominant trailing-cell token — 87-VALIDATION.md uses `passed` in all 6 task rows (lines 57-62) and all 16 coverage rows (lines 70-83). Use `passed` for 90/92 cell flips and 91's header. [VERIFIED: 87-VALIDATION.md]

**False-incomplete markers outside D-06 scope (FYI, do not act):** 83/84-VALIDATION.md use a different table style with `⬜ pending` / `❌ W0` cells (e.g., 84 lines 41-49) and `status: draft` frontmatter. These are in v2.6 but are NOT in D-06's target list and fall under the D-07 frontmatter-gate / D-08 scope discussion. Flag to planner only if the "no false-incomplete markers remaining" clause of META-01 is read to include them; the CONTEXT.md D-06 target list does not.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix | running ExUnit tests | ✓ | project toolchain (tests run cleanly) | — |
| ExUnit | PROOF-01 tests | ✓ | bundled | — |

No external tools, services, or runtimes. Probes ran successfully via `mix test` / `mix run`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled) |
| Config file | none beyond `mix.exs` / `test/test_helper.exs` |
| Quick run command | `mix test test/rendro/flow_test.exs test/rendro/pipeline/paginate_test.exs` |
| Full suite command | `mix test` (project also has `mix ci`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROOF-01 | Header `only_on` physical parity at render layer (4-page proof) | integration/E2E | `mix test test/rendro/flow_test.exs` | ✅ (new test added to existing file) |
| PROOF-01 | Header parity coexists with restart section tokens at paginate layer | integration | `mix test test/rendro/pipeline/paginate_test.exs` | ✅ (new test added to existing file) |
| PROOF-01 | Edge cases: single-page (odd only), first-page parity, header+footer coexistence | integration | `mix test test/rendro/flow_test.exs` | ✅ |
| META-01 | Reconciled VALIDATION.md files are intra-file consistent | manual re-read | grep `pending` returns no task-status cells in 90/92; `**Status:**` line in 91 reads `passed` | n/a (docs) |

**The new PROOF-01 tests ARE the validation for PROOF-01.** META-01 is verified by re-reading each reconciled file for intra-file consistency (no `pending` Status cells remaining in 90/92; 91 header terminal) and confirming no contract test regressed (`test/docs_contract/public_api_contract_test.exs` stays green — PROOF-01 adds no public surface).

### Sampling Rate
- **Per task commit:** `mix test test/rendro/flow_test.exs test/rendro/pipeline/paginate_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** `mix test` (or `mix ci`) green; `mix format --check-formatted`; public-API contract test green before `/gsd:verify-work`.

### Wave 0 Gaps
- None — both target test files exist (`flow_test.exs`, `paginate_test.exs`) with the helper functions (`paginate_flow/1`, `page_texts/1`) and template patterns already in place. No new test infrastructure required.

## Security Domain

> `security_enforcement` is not present in config.json. This phase changes NO `lib/` source, NO public API, NO input-handling, NO crypto, NO data persistence. It adds test code and edits internal planning markdown. No ASVS category applies (no auth, session, access control, input validation surface, or cryptography is introduced or modified). Confirmed: `priv/public_api.json` and the public-API contract test must remain untouched and green. No threat surface.

## Project Constraints (from CLAUDE.md)

No `./CLAUDE.md` exists in the working directory (verified). Binding constraints come from 95-CONTEXT.md locked decisions D-01..D-08:
- No `lib/` source changes, no public API change (`priv/public_api.json` untouched), no engine/threshold changes. [D-01, domain]
- Proof mechanism = content-stream byte assertions only; Poppler-per-page and golden-bytes rejected. [D-01]
- META-01 scope is strictly `.planning/milestones/v2.6-phases/` and `v2.7-phases/`; do NOT touch v1.x/v2.5, current 93/94/95/96, or non-VALIDATION metadata. [D-08]
- Edit stale markers in place (git-reversible). [D-05]
- Reconcile to existing `passed` token; do not invent a new token. [D-06]

## Sources

### Primary (HIGH confidence)
- Live engine probes (executed against the real pipeline this session): render-layer 4-page proof, single-page edge, header+footer coexistence, paginate-layer restart coexistence — all passed.
- `lib/rendro/pipeline/paginate.ex:558-573, 575-632, 729-739` — region-independent running-content + `apply_only_on/3`.
- `lib/rendro/pipeline/compose.ex:117-124, 144-154, 179-186` — per-region `region_entries`, `validate_only_on!`.
- `lib/rendro/pipeline/measure.ex:69, 483-512` — line height + `body_capacity`.
- `lib/rendro/text.ex:18,20` — default size 12, line_height 1.2.
- `test/rendro/flow_test.exs:268-328` — footer render proof to clone.
- `test/rendro/pipeline/paginate_test.exs:684-838, 1145-1245` — paginate patterns + helpers + `section_context_template`.
- META-01 file inspection: 88/90/91/92-VALIDATION.md frontmatter + cells; 87-VALIDATION.md `passed` convention; v2.6/v2.7-MILESTONE-AUDIT.md verdicts (both `passed`).

### Secondary (MEDIUM confidence)
- `.planning/phases/95-.../95-CONTEXT.md` — locked decisions D-01..D-08.
- `.planning/REQUIREMENTS.md` — PROOF-01, META-01.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- PROOF-01 mechanics: HIGH — every assertion empirically verified by executing probes against the live engine.
- META-01 cell counts / frontmatter / convention: HIGH — direct file inspection of all targets + the full frontmatter census.
- D-07 resolution: HIGH — full `status:` census across all archives + current phases.
- D-06 correction (88 is not a contradiction): HIGH — 88 frontmatter, approval line, checkboxes, and the v2.6 audit's own note all confirm.

**Research date:** 2026-06-13
**Valid until:** 2026-07-13 (stable — internal code + planning docs; only invalidated if the engine's running-content/body_capacity logic changes)
