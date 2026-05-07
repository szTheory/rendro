# Phase 16: Phoenix Error Boundary Proof - Research

**Researched:** 2026-04-28
**Domain:** Phoenix HTTP adapter, error serialization, test boundaries
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Phase 16 should keep the Phoenix adapter responsible for an explicit operator-facing HTTP error response. Do not defer this contract to host-app-only fallback handling in this phase.
- **D-02:** For Phoenix requests resolved to `json` format, the adapter should return a structured JSON error response with HTTP status `500`, not `text/plain`.
- **D-03:** The JSON contract should expose the stable operator-facing envelope fields that Rendro already promises: `what`, `where`, `why`, `next`, `stage`, and `render_id`. Keep the wire contract small and truthful.
- **D-04:** Do not expose raw internal `reason` terms or the full `details` map as committed HTTP contract fields by default. They are useful internally, but too unstable and implementation-shaped for a durable library boundary.
- **D-05:** For non-JSON requests, retain an explicit plain-text fallback using the existing `%Rendro.Error{}` string rendering. This keeps browser/manual debugging ergonomic without forcing JSON onto every route.
- **D-06:** Request-format branching should follow Phoenix format semantics, not ad hoc raw `Accept` parsing. Use the resolved request format as the contract switch so API routes and browser-style routes behave predictably.
- **D-07:** Keep the implementation dependency-light. Do not add a new direct JSON dependency just to format this response; use the Phoenix-side facilities already present at the adapter boundary.
- **D-08:** The primary committed proof for `OBS-03` should live at the library-owned conn boundary in `test/rendro/adapters/phoenix_test.exs`, directly exercising `Rendro.Adapters.Phoenix`.
- **D-09:** Do not make the example Phoenix app the sole or primary proof surface for this requirement. The example app is useful supporting evidence, but the contract belongs to the library adapter.
- **D-10:** A route-level/example-app smoke proof is acceptable only as thin supporting evidence if it is cheap and non-duplicative. It is not required to close the phase.
- **D-11:** The canonical failure used to prove the boundary should be a deterministic paginate-stage overflow (`:content_overflow`), not timeout and not a flaky runtime path.
- **D-12:** Force the overflow with explicit geometry, such as an oversized block height, rather than text-measurement drift or long-content heuristics. The fixture should stay deterministic across environments.
- **D-13:** The boundary proof should assert the operator-facing contract, not internal implementation trivia. Assert sent state, status code, content type, and stable envelope fields/body content. Avoid brittle full-body golden assertions when shorter field-level assertions close the contract more truthfully.
- **D-14:** Downstream agents should treat this context as recommendation-first and locked unless a later decision would materially change public semantics beyond this phase boundary.
- **D-15:** Carry forward the user's explicit preference to shift routine implementation choices left within GSD. For similar future phases, default to one coherent recommendation set and escalate only when a decision is truly high-impact or policy-significant.

### the agent's Discretion
- Exact JSON body nesting, as long as the stable operator-facing fields remain explicit and documented.
- Whether the thin optional smoke proof lives in the example app or a tiny Phoenix harness, if planning concludes the extra witness is worth the maintenance cost.
- Exact assertion style in the tests, as long as the proof stays stable, deterministic, and boundary-focused.

### Deferred Ideas (OUT OF SCOPE)
- Full app-owned exception/fallback integration for Rendro Phoenix consumers — valid future design space, but broader than this boundary-proof phase.
- Standardizing on RFC 9457 `application/problem+json` — potentially valuable later if Rendro needs a broader cross-language HTTP API contract, but heavier than needed for this closure phase.
- Rich example-app route smoke coverage beyond a minimal witness — useful only if it stays clearly secondary to the library-owned contract proof.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OBS-03 | Operator receives structured errors that explain what happened, where it failed, why, and suggested next actions. | Implemented via the `Rendro.Error` envelope and correctly exposed over HTTP via the updated `Rendro.Adapters.Phoenix` error handling logic for JSON responses and text fallbacks. |
</phase_requirements>

## Summary

The Phoenix Error Boundary Proof phase establishes a guaranteed and structured API response for downstream consumers when PDF generation fails. By inspecting the negotiated format via Phoenix standard tools, the `Rendro.Adapters.Phoenix` adapter provides a 500 status with an explicit JSON structure for JSON-first pipelines, and retains the existing text fallback for browser endpoints. The test proof forces a deterministic geometric pagination error to exercise this boundary cleanly.

**Primary recommendation:** Update `Rendro.Adapters.Phoenix` to fetch format using `try do Phoenix.Controller.get_format(conn) rescue _ -> "text" end` and encode the `what/where/why/next/stage/render_id` map using `Phoenix.json_library()`. Add deterministic boundary test directly in `test/rendro/adapters/phoenix_test.exs` and skip the `phoenix_example` test footprint since it's an extraneous test matrix that adds low-value duplicated coverage.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| HTTP Error Serialization | API / Backend (Phoenix Adapter) | — | The adapter defines the library's integration surface. Transforming the `Rendro.Error` internal struct into correct 500 HTTP responses falls purely into its boundary contract. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Phoenix.Controller` | >= 1.7 | Format negotiation | Exposes `get_format/1` conforming to Phoenix HTTP rules. |
| `Phoenix.json_library()` | >= 1.7 | JSON Serialization | Native encoder alias that doesn't force a direct Jason dependency into Rendro's core package. |

## Architecture Patterns

### Recommended Project Structure
This is primarily a refactoring and tightening of an existing API boundary. Changes apply within:
```
lib/rendro/adapters/phoenix.ex          # Updates to `render_pdf` and `preview_pdf` error branches
test/rendro/adapters/phoenix_test.exs   # Addition of deterministic failure tests
```

### Pattern 1: Safe Format Negotiation
**What:** Retrieving Phoenix format without crashing Unfetched parameter connections.
**When to use:** When serving multi-format endpoints outside the router/Plug pipeline guarantees.
**Example:**
```elixir
format = 
  try do
    Phoenix.Controller.get_format(conn)
  rescue
    _ -> "text"
  end
```

### Pattern 2: Lightweight Envelope Mapping
**What:** Exposing a small and safe JSON subset of `Rendro.Error` using native Phoenix serialization.
**Example:**
```elixir
json = Phoenix.json_library().encode_to_iodata!(%{
  what: error.what,
  where: error.where,
  why: error.why,
  next: error.next,
  stage: error.stage,
  render_id: error.render_id
})
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Accept Header Parsing | Custom regex or header splitting logic | `Phoenix.Controller.get_format/1` | Phoenix already implements the `plug :accepts` standard logic for request formats; hand-rolling introduces edge cases. |
| JSON Serialization | Custom JSON string interpolation or forcing `Jason` dep | `Phoenix.json_library().encode_to_iodata!/1` | Phoenix encapsulates its chosen encoder; depending directly on `Jason` inside the adapter bloats dependency graphs. |

## Common Pitfalls

### Pitfall 1: Unfetched Parameters Exception
**What goes wrong:** `Phoenix.Controller.get_format(conn)` raises an `ArgumentError`.
**Why it happens:** In tests or custom endpoints without `plug :accepts` or `Plug.Parsers`, the `conn.params` key is an `%Unfetched{}` struct. `get_format/1` checks for `_format` in params and crashes.
**How to avoid:** Wrap the call in a `try...rescue` and fallback to `"text"` (or `"html"`), maintaining graceful degradation.

### Pitfall 2: Brittle Full-Body String Assertions
**What goes wrong:** Tests fail when error phrasing is improved slightly.
**Why it happens:** Exact string matches on long JSON strings break easily.
**How to avoid:** Decode the JSON response body using `Phoenix.json_library().decode!(conn.resp_body)` and assert on specific keys like `body["stage"] == "paginate"`.

## Code Examples

### Boundary Test Example
```elixir
defp overflow_document do
  Rendro.flow([Rendro.block(Rendro.text("Too big"), height: 2000)])
end

test "render_pdf/3 sends structured JSON 500 when format is json" do
  conn = conn(:get, "/download") |> put_private(:phoenix_format, "json")
  
  conn = Adapter.render_pdf(conn, overflow_document(), "proof.pdf")

  assert conn.status == 500
  assert ["application/json; charset=utf-8"] = Plug.Conn.get_resp_header(conn, "content-type")

  body = Phoenix.json_library().decode!(conn.resp_body)
  assert body["stage"] == "paginate"
  assert body["what"] =~ "Pagination failed"
  assert Map.has_key?(body, "render_id")
end
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/rendro/adapters/phoenix_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OBS-03 | Adapter returns JSON response with struct payload when format is json | unit | `mix test test/rendro/adapters/phoenix_test.exs` | ✅ Wave 0 |
| OBS-03 | Adapter returns plain-text response with `to_string(error)` payload when format is plain/html | unit | `mix test test/rendro/adapters/phoenix_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/adapters/phoenix_test.exs`
- **Per wave merge:** `mix ci`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements.

## Sources

### Primary (HIGH confidence)
- Context validation logic: `Phoenix.Controller` definition.
- Native capabilities: `Phoenix.json_library()`.
- Deterministic failure geometry: `Rendro.Pipeline.Paginate`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Relies completely on official Phoenix API bindings.
- Architecture: HIGH - Confirmed safe usage pattern for unfetched params within plugs.
- Pitfalls: HIGH - Tested locally to verify crash conditions in `test` framework and mitigated gracefully.

**Research date:** 2026-04-28
**Valid until:** 2026-05-28
