# Phase 131: Adoption Snapshot & Phoenix Newcomer Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-21
**Phase:** 131-adoption-snapshot-phoenix-newcomer-proof
**Areas discussed:** Adoption review structure, Canonical discovery route, Clean-room standard, Journey proof record, Public release prerequisite

---

## Adoption Review Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Existing distributed tables only | Append to the existing snapshot, signal, contributor, and review tables with no separate evidence record. Lowest file count, but weaker replayability and unavailable-source clarity. | |
| One large inline review | Put raw API and CLI results into a dated ADOPTION.md section. Self-contained, but noisy, privacy-sensitive, and brittle to validate. | |
| Summary plus immutable sidecar | Keep ADOPTION.md readable while linking compact source/query/results evidence that contracts validate offline. | ✓ |

**User's choice:** Accepted the researched recommendation set.
**Notes:** Retrieval availability is separate from decision state. Unavailable is not zero. The composite is the weakest family status and triggers only when all three families trigger.

---

## Canonical Discovery Route

| Option | Description | Selected |
|--------|-------------|----------|
| README-first | Install first, then select the canonical preset, build an app-owned document, serve through the adapter, and verify. | ✓ |
| HexDocs-first | Route newcomers through versioned reference guides before installation. Good depth, but adds a first-success navigation decision. | |
| Configurator-first | Begin with visual selection. Strong for installed users, but it does not own dependencies, data, routes, or HTTP verification. | |

**User's choice:** Accepted the README-first recommendation.
**Notes:** HexDocs supplies depth; the configurator remains the exact selection/snippet surface, not an installation wizard. No new UI is added. Living brand guidance supersedes the older brand prompt.

---

## Clean-room Standard

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse committed Phoenix example | Fast and reviewable, but its path dependency, lockfile, and workspace context cannot prove public-package installation. | |
| Ephemeral generated Phoenix app | Fresh API-only `mix phx.new` app, isolated Mix/Hex/build/dependency caches, exact public package, and fail-closed leakage checks. | ✓ |
| Container-only proof | Strong OS isolation, but adds image/toolchain maintenance and obscures the ordinary Phoenix path without a demonstrated need. | |

**User's choice:** Accepted the ephemeral generated-app recommendation.
**Notes:** Omit Ecto, HTML, and assets because the job is the Phoenix PDF response boundary. Do not repurpose `HOME`; isolate the relevant tool caches explicitly.

---

## Journey Proof Record

| Option | Description | Selected |
|--------|-------------|----------|
| ConnTest only | Idiomatic router/pipeline/controller proof with good failure localization; no real socket/process request. | |
| Live server request only | Proves actual HTTP delivery, but gives poorer deterministic regression ergonomics. | |
| Both plus structured record | Run ConnCase/ConnTest and a real local request; retain the harness, result manifest, and concise human transcript. | ✓ |

**User's choice:** Accepted both proof layers and all three retained evidence layers.
**Notes:** Both require `200`, `application/pdf`, and `%PDF-`. External installation/server evidence remains advisory; offline contracts validate the retained record without network polling.

---

## Public Release Prerequisite

| Option | Description | Selected |
|--------|-------------|----------|
| Publish additive minor `1.3.0` | Use existing release machinery to make the already-shipped preset/configurator surface public before the clean-room proof. | ✓ |
| Weaken the journey to `1.0.0` | Install the current public release but abandon the required Swiss/light path. | |
| Use Git/tag dependency | Exercise newer source without a checkout, but fail the requirement to install the public Hex package. | |

**User's choice:** Accepted `1.3.0` as a hard prerequisite.
**Notes:** Context approval permits planning this one-way action. The implementation plan must stop at an explicit human checkpoint immediately before tag/publish; it must not infer publication authorization from this discussion.

---

## the agent's Discretion

- Exact private harness/helper names, JSON schema key names, temporary directory layout, safe port/readiness mechanics, and focused test locations.
- Exact filenames beneath the locked `priv/adoption_evidence/` boundary.

## Deferred Ideas

None. No UI product, analytics, outreach, scheduled polling, database integration, new capability family, or global text-shaping implementation was added.
