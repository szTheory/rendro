# Pitfalls Research — v2.6 Public Launch & Adoption Bootstrap

**Researched:** 2026-06-10
**Confidence:** HIGH (each pitfall traced to documented failures in comparable projects or direct codebase inspection)

## Phase 83 (claim accuracy / shaper seam)

1. **Behavior drift during the refactor.** Making harfbuzz_ex optional must keep existing Latin output byte-identical. Exit criterion: all existing deterministic golden tests pass unchanged with `Shaper.Simple` selected, and with `Shaper.HarfBuzz` selected where harfbuzz_ex was previously used. Don't "improve" measurement in the same phase.
2. **Silent degradation instead of instructive error.** If complex-script codepoints reach `Shaper.Simple`, the Prawn failure mode is silent disconnected Arabic. Must raise/return `{:error, {:shaping_required, script}}` — errors-as-product. (Prawn's decade of "why is my Arabic broken" issues; jsPDF #2613/#3377.)
3. **unicode_data migration changing script classification.** ex_unicode's newer tables may classify codepoints differently than 2019-era unicode_data — run itemization diffs on existing fixtures before/after; any change must be deliberate and documented.
4. **Per-grapheme fix changing line breaks.** Fixing `split_graphemes` to shape runs can change measured widths (correct kerning where none was applied) → wrapped-text goldens may legitimately shift. Decide explicitly: byte-freeze (apply cluster breaking only when shaping adapter active) vs. accept regenerated goldens with changelog note.

## Phase 84 (path primitive)

5. **Scope creep into a graphics package.** Transforms (`cm`), clipping (`W`), gradients, blend modes — each is a viewer-compat surface. Defer all three with explicit matrix entries; v1 path surface = move/line/curve/rect/rounded-rect + stroke/fill only.
6. **Float formatting nondeterminism.** All coordinates must route through the existing `format_num` discipline; no raw `Float.to_string`.
7. **Table-border option breaking existing fixtures.** Borders must be opt-in (`borders: ...` option defaulting to current borderless rendering) so every existing golden/recipe stays byte-identical.

## Phase 85 (raster lane)

8. **Cross-OS raster nondeterminism — the universally documented footgun.** pdf-visual-diff README warns identical PDFs raster differently across OSes (AA, font rendering, PNG encoders). Mitigations: refs generated ONLY on pinned CI (containerized bless command); pdfium-cli pinned by version + sha256; hash-equality as the gate; perceptual diff only during deliberate renderer bumps. **Never bless refs on dev laptops.**
9. **Renderer bump invalidating all refs at once.** Treat as a scheduled re-bless event (like a font change); record renderer version in evidence frontmatter; changelog the re-bless.
10. **Snapshot bloat.** Typst enforces ≤20 KiB per ref; use 72–96 dpi and page crops. Repo-size review in the phase exit.
11. **Overclaiming GUI-viewer support from raster evidence.** A rasterizer is not Acrobat. New `viewer_kind: "pdfium-render"` must stay distinct from GUI observation; Adobe/Preview rows remain structural proxies. Guard with the existing docs-contract lint pattern. (Appendix F of the evidence guide already names this boundary.)
12. **Required-lane contamination.** The raster lane must stay advisory (`needs: []`-isolated like `example-phoenix`) — a pdfium-cli download failure must never block the four engine-critical lanes.

## Phase 86 (gallery/manual)

13. **Gallery drift.** Images that aren't CI-hash-checked rot into lies. The docs-contract lane (committed hash == regenerated hash) is non-negotiable, same lockstep discipline as existing lanes.
14. **manual.pdf hash churn.** Every engine change that touches any recipe invalidates the published SHA-256. Make the hash machine-published (CI writes it into the guide via the existing docs-contract lockstep), never hand-maintained.
15. **Brand inconsistency.** Gallery/docs visuals must follow prompts/Rendro Brand Book.txt — one pass of design review before launch, not after.

## Phase 87 (benchmarks/Livebook)

16. **Benchmark fairness attacks.** A "vs ChromicPDF" page will be scrutinized by its maintainers/users. Pin versions, publish the harness, measure honestly (include ChromicPDF's strengths: arbitrary HTML/CSS, complex scripts), state hardware. Unfair or irreproducible benchmarks poison the launch.
17. **Livebook rot.** The .livemd must be executed in CI (advisory lane); an unexecuted notebook with stale API calls is worse than none.

## Phase 88 (launch)

18. **Launching before truth fixes land.** Phase ordering is load-bearing: announcing "pure Elixir, no external deps" while harfbuzz_ex is a hard NIF dep hands critics a refutation of the flagship claim. 83 must merge before 88 executes.
19. **Astroturf perception in demand threads.** Replies in the two ElixirForum threads must be genuinely helpful (answer the asker's constraints, acknowledge ChromicPDF's fit where true) — not drive-by self-promotion. The honest-claims culture is the differentiator; keep it in marketing voice too.
20. **Demand gate defined too vaguely (or too high).** "Adopter demand justifies it" failed as a gate once already. Thresholds must be concrete and recorded (N non-self issues/asks, download floor, first external contributor) — and reviewable at a set date, not open-ended.
21. **Single-maintainer responsiveness debt.** fpdf2's retrospective: PRs unanswered for a year killed contributor momentum. Launch creates inbound; budget for issue triage in the weeks after Phase 88 or the first contributors bounce.

## Carried-over engine constraints (from prior milestones, still binding)

- Single-pass pipeline: no fixpoint/multi-pass machinery may sneak in via any feature (TOC deferred design exists precisely to avoid this).
- D-10: substituted running-region tokens are never re-measured; any new token (future `{{toc_page:*}}`, `{{section_page_number}}`) must use fixed-width reservation.
- Optional adapters never become hard deps; external tools never enter core; the four required CI lanes never gain graph-coupled dependencies.
