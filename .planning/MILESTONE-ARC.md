# Rendro Milestone Arc

**Last updated:** 2026-06-13
**Purpose:** Preserve the recommended multi-milestone sequence so milestone-definition work does not reopen settled architectural tradeoffs unless the project direction materially changes.

## Stewardship Posture (Done-Enough)

*Date recorded: 2026-06-13*

Rendro is ~90-93% feature-complete for its stated product identity. The standing rule is to prefer short stewardship, claim hygiene, and adoption-feedback work over new feature families. Do not deepen proof/viewer machinery by default.

**Demand-Gated Deferrals** (see [ADOPTION.md](../ADOPTION.md) for gate status; these are not abandoned, just waiting for qualifying demand):
- Global text shaping
- Mobile GUI viewer promotion
- TOC/outlines/anchors/cross-references
- Charts
- Existing-PDF editing
- Release-please automation
- Proactive outreach

## Active Strategic Arc

### Done-Enough Stewardship and Demand-Gated Growth

- **Intent:** Keep Rendro credible for Phoenix SaaS adopters now that the 1.0 release, quiet public launch, recipe workflow, proof surfaces, and page-context ergonomics are shipped.
- **Ordering logic:** Treat Rendro as near done for its stated scope. Prefer short stewardship, claim hygiene, and adoption-feedback work over new feature families unless public demand makes the tradeoff obvious.
- **Done-enough estimate:** 90-93% for the stated product identity. The remaining delta is important-but-narrow, not foundational.

## Last Shipped Milestone

### v2.7 Page Context & Browser Proof Hardening

- **Status:** shipped 2026-06-13
- **Why it mattered:** It extended the already-shipped PAGE primitive into section-local numbering and physical odd/even running content while keeping PDF.js evidence advisory and global text shaping demand-gated.
- **Scope shipped:**
  - `page_numbering: [restart: true]` on body sections.
  - `{{section_page_number}}` and `{{section_total_pages}}` in running header/footer text.
  - `only_on: :odd | :even` for physical page parity on running content.
  - Pinned PDF.js advisory observations that do not promote GUI-viewer support.
  - Public docs/package/workflow guardrails for the new claims.
- **Non-goals held:**
  - Public `Rendro.PageContext` struct or callback API.
  - TOC, outlines, anchors, cross-references, charts, and blank recto/verso insertion.
  - PDF.js GUI support claims.
  - Global text shaping without the `ADOPTION.md` demand gate.

## Active Milestone

### None

- **Status:** awaiting next `$gsd-new-milestone`
- **Current recommendation:** Start a short v2.8 stewardship milestone rather than a new capability family.

## Next Recommendation

### v2.8 Done-Enough Stewardship & Adoption Signal Loop

- **Status:** recommended next milestone
- **Why next:** Repo inspection shows the main adopter jobs are already served: data-to-PDF rendering, canonical business recipes, Phoenix response integration, async delivery hooks, telemetry/diagnostics, support boundaries, trust-sensitive artifact operations, proof-backed viewer posture, Livebook/comparison try paths, and page-context report ergonomics. The highest leverage is now to reduce maintainer/adopter friction and keep the public posture truthful while demand accumulates.
- **Target user/job:** A Phoenix SaaS engineer or maintainer evaluating whether Rendro is stable, understandable, and low-risk enough to adopt today.
- **Done-enough outputs:**
  - Clean or deliberately documented docs/CI warning posture, including the known hidden-internal ExDoc warnings and stale viewer-evidence warning noise.
  - Direct header-specific `only_on` rendering E2E coverage to match footer proof depth.
  - Optional Nyquist/validation-history cleanup for recent v2.6/v2.7 phase debt where the audit already passed but metadata is stale.
  - Small adopter-DX polish where source reality shows friction, such as the `Rendro.Recipes` facade only delegating invoice/branded invoice while statement/receipt/certificate exist as full recipe modules.
  - A lightweight adoption-signal review that confirms whether `ADOPTION.md` has qualifying text-shaping demand, download movement, or contributor signal before any large capability is proposed.
  - Updated maintainer docs/state that say Rendro is near done for its current scope and should not deepen proof/viewer work by default.
- **Non-goals:**
  - No global text shaping implementation unless the gate has triggered.
  - No mobile GUI viewer support promotion without automated device-level evidence.
  - No TOC/outlines/anchors/cross-reference feature unless there is concrete long-report adopter pressure.
  - No charts, existing-PDF editing, HTML/CSS rendering, multi-signature orchestration, HSM/key custody, or release-please automation.
  - No proactive launch/outreach obligations unless the maintainer explicitly opts in.

## Next Candidates

### Larger Report Navigation

- **Status:** demand-gated candidate
- **Why later:** Page context is now a prerequisite for long-report navigation, but the repo has no concrete demand signal requiring TOC, outlines, anchors, or cross-references as the next product wedge.
- **Potential scope:** Anchor registry, deterministic outline serialization, internal link helpers, and docs-contract/support-matrix rows that keep navigation support narrow.
- **Non-goals:** Browser-like layout, arbitrary named destinations, existing-PDF editing, and a broad report-platform promise.

### Global Text Shaping & Script Support

- **Status:** conditional candidate
- **Why later:** `ADOPTION.md` currently records zero qualifying shaping signals and all threshold families are blocked. This is a large core investment and should not consume the next milestone without evidence.
- **Potential scope if triggered:** HarfBuzz-backed shaping path, RTL/bidi handling, script-specific support rows, fixture coverage, and explicit fallback errors.
- **Non-goals:** "Supports every language" marketing, silent fallback shaping, browser runtime dependency, or unbounded Unicode promises.

### Mobile GUI Viewer Proof

- **Status:** demand-gated candidate
- **Why later:** Mobile rows are terminal `explicit_deferral`, and v2.6/v2.7 already show proof investment is near diminishing returns. Promote only if a real adopter needs mobile GUI behavior and an automated device-level evidence lane is feasible.
- **Potential scope:** Device-lab automation, exact fixture checklist, and support-matrix promotion only for rows that pass.
- **Non-goals:** Manual-only mobile claims or structural proxy evidence presented as mobile GUI proof.

### Charts and Visual Reporting

- **Status:** later candidate
- **Why later:** Charts could matter for reporting, but they add a new authoring and proof surface. Current recipes and paths cover basic business documents without needing `%Rendro.Chart{}`.
- **Potential scope:** Narrow chart primitives lowered to Path/Text, deterministic snapshots, and explicit support rows.
- **Non-goals:** Full charting library breadth, interactivity, or browser/SVG compatibility.

### Release Automation and Outreach

- **Status:** low-priority candidate
- **Why later:** Current manual/semi-manual BEAM release posture is acceptable, and quiet public discoverability was a deliberate v2.6 decision. Automation adds credential and workflow complexity before release friction is proven.
- **Potential scope:** Only revisit if repeated release pain appears in maintainer logs.
- **Non-goals:** Creating recurring community response obligations by default.

## Durable Lessons

- Rendro is now closer to a finished library than an unfinished platform. New milestones should prove why they are necessary before adding surface area.
- The proof axis is at diminishing returns. Keep support rows, docs-contract tests, and advisory lanes honest, but do not deepen viewer/proof machinery just because it is available.
- The adoption axis is now pull-based. `ADOPTION.md`, issue-only intake, public docs, HexDocs, Livebook, and comparison evidence are enough to collect signal without proactive outreach.
- Planning artifacts can lag shipped truth. `MILESTONE-ARC.md` was stale after v2.7 while `PROJECT.md`, `ROADMAP.md`, `STATE.md`, and milestone audits had moved on. Future milestone-boundary work should refresh the arc before starting `$gsd-new-milestone`.

## Open Research Flags

- Review `ADOPTION.md` before any text-shaping milestone. The gate currently has no qualifying shaping signals, no post-baseline download snapshots, and no qualifying external contributor signal.
- Re-check public HexDocs/package state before making release or docs availability claims.
- If report-navigation pressure appears, design anchors/outlines/cross-references before exposing a public `Rendro.PageContext` API.
- If a viewer claim is tempting, require exact support-matrix evidence first and keep structural/advisory evidence separate from GUI support.

## Closeout Checklist Expectations

Before a future milestone is marked complete:

- Public docs must have docs-contract coverage for every new claim.
- Support-matrix rows must be terminal: `supported` with evidence or `explicit_deferral` with a named reason.
- Deterministic and advisory CI lanes must remain separated.
- Any optional adapter work must compile out cleanly and keep core free of hard Phoenix, Oban, Node, Python, browser, signing-tool, or viewer dependencies.
- The final audit should update this arc if the recommended next wedge changes.
