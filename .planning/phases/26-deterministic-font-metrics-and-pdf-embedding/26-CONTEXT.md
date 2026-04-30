# Phase 26: Deterministic Font Metrics and PDF Embedding - Context

**Gathered:** 2026-04-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Make resolved font selection drive both deterministic measurement/pagination and final PDF embedding for supported custom fonts. This phase closes `FONT-02` and `FONT-03` without widening into fallback chains, broad Unicode claims, ambient system-font discovery, or shaping behavior.

</domain>

<decisions>
## Implementation Decisions

### Public font source contract
- **D-01:** Keep built-in fonts and embedded custom fonts as distinct public concepts. Built-in registration stays separate from embedded-font registration; do not collapse them into one magical API.
- **D-02:** The embedded-font contract must accept both tagged path and tagged binary sources: `{:path, path}` and `{:binary, bytes}`.
- **D-03:** Any path-based input must be eagerly read and normalized into Rendro-owned pure data before later pipeline stages run. Temp-file lifetime, release layout, or host filesystem state must not affect pagination or rendering after registration/preflight.
- **D-04:** Do not support system-font lookup, ambient OS font discovery, remote fetching, or implicit environment-dependent resolution in this phase.

### Registration and family modeling
- **D-05:** Preserve the existing logical-font authoring contract: `%Rendro.Text{font: ...}` continues to reference explicit logical font names, not PDF internals or CSS-like family strings.
- **D-06:** Add an explicit embedded-font registration path for custom fonts rather than overloading `register_font/3` with mixed semantics.
- **D-07:** Support a narrow four-variant family model for DX: `regular`, `bold`, `italic`, and `bold_italic`, but only through explicit caller-provided variant files/bytes.
- **D-08:** Missing variants must fail explicitly. No faux bold/italic synthesis, no implicit family discovery, and no silent remapping to another face.
- **D-09:** Do not broaden into arbitrary weight axes, variable-font semantics, or generalized style resolution in this phase.

### Failure and validation policy
- **D-10:** Preflight custom fonts before `measure`, `paginate`, and `render`. Unreadable data, unsupported format, missing required metrics, or non-embeddable fonts must fail through typed errors at the earliest deterministic boundary.
- **D-11:** Rendro must never silently fall back from an explicitly registered/selected embedded font to a different face. Invalid explicit font usage is a hard failure, not best effort.
- **D-12:** The existing “fail early at Build” posture from Phase 25 should extend to embedded-font readiness: later stages should consume already-validated descriptors rather than re-deciding validity ad hoc.

### Determinism and verification contract
- **D-13:** Measurement and writer must consume the same resolved font descriptor/metrics payload so line breaks, widths, heights, and final PDF font objects all derive from one shared source of truth.
- **D-14:** The public determinism contract for this phase is stable layout behavior: measured widths/heights, wrapped lines, page breaks, page counts, and resolved font selection parity.
- **D-15:** Verification should assert embedded-font structure and presence, but should not elevate full-PDF byte identity to the main public contract for this phase.
- **D-16:** If whole-file byte-stability tests exist, they should remain a narrow internal regression tool rather than the user-facing promise that defines success.

### Developer and operator experience
- **D-17:** Optimize for Phoenix, Plug, Ecto, and Oban usage without coupling core to any of them: path input should feel natural for uploads/files, binary input should feel natural for DB/blob/cached assets, and both normalize into one pure-core descriptor.
- **D-18:** Errors and diagnostics should name the logical font, source kind, and concrete failure reason so operators can fix invalid font setup without reading PDF internals.
- **D-19:** Downstream agents should default to one coherent recommendation set rather than surfacing menus of equivalent options. Escalate only choices that materially change product semantics or milestone scope. This is already consistent with `.planning/METHODOLOGY.md` and should be applied strongly in planning/execution for this phase.

### the agent's Discretion
- Exact internal module split for parsing, metrics extraction, embedding, and descriptor caching.
- Whether the four-variant family helper stores an internal variant map or expands into explicit logical names, as long as caller intent stays explicit and deterministic.
- Exact typed error atoms/details and telemetry field names, as long as they stay consistent with existing public error surfaces.
- Whether narrow whole-file deterministic fixtures exist internally, as long as the public contract stays centered on layout determinism and embedding structure rather than byte identity.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement truth
- `.planning/ROADMAP.md` — Phase 26 goal, planned work, and milestone sequencing.
- `.planning/REQUIREMENTS.md` — `FONT-02` and `FONT-03` definitions plus out-of-scope constraints.
- `.planning/PROJECT.md` — v1.2 milestone intent, truthful support-boundary rules, and core purity constraints.
- `.planning/STATE.md` — current milestone execution state and recent typography decisions.
- `.planning/METHODOLOGY.md` — coherent recommendation-set bias, truthful small contracts, and escalation rule.

### Prior phase contract
- `.planning/phases/25-font-registry-and-public-typography-contract/25-RESEARCH.md` — rationale for document-owned logical font registry and shared resolution path.
- `.planning/phases/25-font-registry-and-public-typography-contract/25-PATTERNS.md` — existing registry, resolver, and builder analogs to preserve.
- `.planning/phases/25-font-registry-and-public-typography-contract/25-01-SUMMARY.md` — public typography contract decisions and Helvetica-compatibility boundary.
- `.planning/phases/25-font-registry-and-public-typography-contract/25-02-SUMMARY.md` — early font validation, shared resolver, and measure/writer parity decisions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/rendro/font_registry.ex`: Existing logical-font registry and shared resolution seam; extend descriptor modeling here instead of inventing a parallel font store.
- `lib/rendro/document.ex` and `lib/rendro.ex`: Existing document-owned font registration/default APIs; these are the natural public integration points for embedded-font registration helpers.
- `lib/rendro/pipeline/build.ex`: Current earliest deterministic failure boundary for invalid font references; likely home for embedded-font readiness validation.
- `lib/rendro/pipeline/measured_text.ex`: Already carries the resolved font through the pipeline; preserve this measure-to-render parity mechanism.
- `lib/rendro/pipeline/measure.ex`: Current consumer of resolved metrics for wrapping/measurement; extend to consume embedded metrics without splitting logic paths.
- `lib/rendro/pdf/writer.ex`: Current font collection/resource allocation seam; extend it to emit embedded font objects and structural embedding proof.
- `lib/rendro/pdf/font.ex`: Current metrics container for built-in Helvetica; likely starting point for a generalized resolved-font metrics representation.

### Established Patterns
- One shared resolver across Build, Measure, and Writer is already the chosen Rendro pattern and must remain true for embedded fonts.
- Public APIs talk in logical font names while PDF resource names and object allocation stay private implementation details.
- Invalid explicit font references fail early instead of silently degrading to Helvetica or another implicit default.
- Core preserves pure-data document ownership and avoids optional-adapter leakage into deterministic pipeline behavior.

### Integration Points
- Extend document font registration so embedded fonts become first-class authored state alongside built-ins.
- Add embedded-font preflight/validation before layout work begins.
- Feed preflighted metrics into measurement and the exact same resolved descriptor into writer embedding/output.
- Add deterministic regression helpers around wrapped-line parity, page-break parity, and embedded-font object inspection.

</code_context>

<specifics>
## Specific Ideas

- Use the same product posture successful PDF libraries converged on: keep built-ins and custom embedded fonts distinct, accept either file or bytes for embedded sources, and eagerly capture external state so later rendering is deterministic.
- Learn from common footguns in other libraries: avoid temp-file lifetime leaks, system-font/environment discovery, silent fallback, faux style synthesis, and broad “supports fonts” claims that outpace test coverage.
- Prefer a four-variant family helper for common business-document ergonomics, but keep it explicit and narrow rather than inventing a CSS-style font system.
- Keep the recommendation style for this phase one-shot and cohesive: planner/researcher should synthesize a single default path unless a choice would materially alter product semantics.

</specifics>

<deferred>
## Deferred Ideas

- Fallback chains and missing-glyph resolution policy — Phase 27.
- Unsupported glyph/script/shaping diagnostics and the Unicode support matrix — Phase 27.
- Variable fonts, arbitrary weight axes, and generalized style-resolution semantics — future work only if the roadmap explicitly asks for them.
- System-font discovery, remote font fetching, and environment-dependent font lookup — out of scope for the current milestone posture.
- Whole-file reproducible PDF bytes as a public product guarantee — future trust/release concern if explicitly required.

</deferred>

---

*Phase: 26-deterministic-font-metrics-and-pdf-embedding*
*Context gathered: 2026-04-30*
