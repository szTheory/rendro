# Phase 16: phoenix-error-boundary-proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `16-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-28T20:41:00Z
**Phase:** 16-phoenix-error-boundary-proof
**Areas discussed:** Phoenix HTTP error contract, boundary proof surface, canonical proving failure

---

## Phoenix HTTP error contract

| Option | Description | Selected |
|--------|-------------|----------|
| Plain text only | Keep `500 text/plain` with `to_string(error)` for all requests | |
| JSON only | Return machine-readable JSON envelope for every error response | |
| Format-aware dual mode | JSON for `json` format requests, explicit plain-text fallback for non-JSON routes | ✓ |
| Host-app owned formatting | Push formatting to app-level fallback/exception handling instead of adapter-owned response | |

**User's choice:** Recommendation-first synthesis requested; agent selected the coherent default.
**Notes:** Chosen because the example app already uses an API pipeline accepting JSON, while Rendro still benefits from a human-readable fallback on non-JSON routes. Raw internal `reason` and `details` should not become committed wire fields.

---

## Boundary proof surface

| Option | Description | Selected |
|--------|-------------|----------|
| Adapter conn boundary | Primary proof in `test/rendro/adapters/phoenix_test.exs` directly against `Rendro.Adapters.Phoenix` | ✓ |
| Internal Phoenix harness | Main proof through a dedicated test endpoint/controller harness inside the repo | |
| Example-app primary proof | Close the phase mainly through `examples/phoenix_example` route/controller tests | |
| Layered proof | Primary adapter proof plus one thin supporting Phoenix smoke witness | |

**User's choice:** Recommendation-first synthesis requested; agent selected the coherent default.
**Notes:** The library owns the adapter seam, so that seam should carry the committed proof. A thin supporting smoke witness is acceptable later if cheap, but is not required to close `OBS-03`.

---

## Canonical proving failure

| Option | Description | Selected |
|--------|-------------|----------|
| Invalid input / no pages | Boundary proof driven by caller misuse or shallow invalid-document failure | |
| Deterministic overflow | Use an explicit oversized block to trigger paginate-stage `:content_overflow` | ✓ |
| Deterministic policy violation | Use `:max_pages_exceeded` or similar policy failure | |
| Timeout / runtime failure | Use timeout or deeper runtime failure as the canonical proof | |

**User's choice:** Recommendation-first synthesis requested; agent selected the coherent default.
**Notes:** Chosen because it exercises a real Rendro pipeline failure while staying deterministic and geometry-driven. Timeout was explicitly rejected as too flaky and environment-sensitive for the canonical proof.

---

## the agent's Discretion

- Exact JSON body nesting for the structured error response.
- Whether a thin optional supporting smoke proof is worth adding beyond the primary adapter conn test.
- Exact assertion granularity, provided the tests stay boundary-focused and deterministic.

## Deferred Ideas

- Broader host-app fallback integration model for Phoenix consumers.
- Future adoption of RFC 9457 problem details if Rendro later needs a heavier cross-language HTTP API contract.
- Richer example-app smoke coverage beyond a thin witness.
