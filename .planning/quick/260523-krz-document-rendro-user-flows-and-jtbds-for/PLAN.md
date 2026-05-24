---
type: quick-task
id: 260523-krz-document-rendro-user-flows-and-jtbds-for
title: Document Rendro user flows and JTBDs
branch: main
repo: /Users/jon/projects/rendro
created: 2026-05-23
autonomous: true
scope:
  - Add one public guide that explains Rendro through user flows and jobs to be done
  - Add one internal research memo covering JTBD coverage, gaps, prioritization, and diminishing returns
  - Link the public guide from the README and record the doc-system decision in planning artifacts
verification:
  - mix docs.contract
files:
  - README.md
  - guides/user_flows_and_jtbd.md
  - .planning/research/JTBD-USER-FLOWS.md
  - .planning/DECISIONS.md
---

# Quick Task Plan

## Objective
Give Phoenix SaaS integrators and future maintainers a clear map of what Rendro is for, which user journeys it already supports, where the biggest workflow gaps still are, and how to keep that map updated over time.

## Constraints
- Stay within Rendro's truthful support boundaries and avoid implying unsupported capabilities.
- Optimize the public guide for a fresh reader who knows Elixir/Phoenix but not this codebase.
- Keep the internal memo useful for milestone prioritization rather than turning it into a generic market survey.

## Execution

### Task 1: Draft the public guide
Explain the current Rendro user journey from a SaaS integrator's perspective: request-time rendering, recipe-led authoring, custom layout escape hatches, background delivery, interactive/document-rich surfaces, and artifact-stage trust operations.

### Task 2: Draft the internal JTBD memo
Map current coverage, benchmark comparable libraries, rank the highest-value gaps, and define the point where further JTBD mapping becomes diminishing-return work.

### Task 3: Wire in and verify
Link the public guide from the README, record the documentation-system decision in planning notes, and run `mix docs.contract`.

## Done When
- A fresh reader can choose the right Rendro path without reading roadmap archaeology.
- The repo has a durable internal memo for future JTBD refreshes and milestone planning.
- The new guide is discoverable from the README.
- `mix docs.contract` passes.
