# Phase 131: Adoption Snapshot & Phoenix Newcomer Proof - Context

**Gathered:** 2026-08-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 131 records one dated, source-backed adoption review and proves that a newcomer can install the public Rendro Hex package in a clean Phoenix application, select the canonical Invoice / Swiss / `#2C6BED` / light path through existing public discovery surfaces, and serve a verified PDF through `Rendro.Adapters.Phoenix`.

The phase may publish the already-shipped additive-minor preset/configurator surface only because the public-package journey is otherwise impossible, and may repair existing documentation, package, release, example, and adapter handoffs needed by the proof. It does not add a core capability family, recipe, preset, catalog cell, runtime dependency, analytics, scheduled polling, outreach program, database feature, UI product, or broader visual/accessibility/viewer claim.

</domain>

<decisions>
## Implementation Decisions

### Public package prerequisite and release boundary

- **D-01 — Fail closed on the public package:** the newcomer journey must resolve Rendro from Hex. A path dependency, Git dependency, repository checkout, or milestone tag is not an acceptable substitute for JOURNEY-01.
- **D-02 — Publish the intended additive minor before the journey:** public Hex currently exposes `1.0.0`, whose release tag predates `Rendro.Theme`, presets, and the configurator. Phase 131 therefore requires the already-intended `1.3.0` release before it can attempt the Swiss/light proof. — **Reversibility: one-way** — publishing a Hex version and pushing its release tag are externally visible and cannot be undone as if they never occurred; the plan must place an explicit human decision checkpoint immediately before the tag/publish action. Approval of this context authorizes planning the checkpoint, not executing publication without that checkpoint.
- **D-03 — Separate consumer range from evidence pin:** public installation docs use idiomatic `{:rendro, "~> 1.3"}` while the retained clean-room proof resolves exact `1.3.0` and records the resulting lock identity.
- **D-04 — Verify publication before proof:** after the release, verify the Hex API version, Hex package contents, HexDocs source/version, and the presence of the preset/font/adapter surfaces before generating the clean Phoenix app. Missing or stale public surfaces stop the journey.
- **D-05 — Preserve existing release discipline:** reuse the current version/tag parity, package allowlist, dry-run, release preflight, CI, and post-publish verification machinery. Do not invent a second publishing path inside the newcomer harness.

### Adoption review structure and decision semantics

- **D-06 — Human index plus immutable evidence:** `ADOPTION.md` remains the public, readable decision index. One compact dated JSON sidecar under `priv/adoption_evidence/` retains the exact source inputs and classifications; because `ADOPTION.md` ships in the package, its linked sidecar must ship with it.
- **D-07 — Retrieval and decision are separate facts:** every source family records `AVAILABLE` or `UNAVAILABLE` independently from `HOLD`, `ACCUMULATING`, or `TRIGGER`. Unavailable evidence is recorded as not evaluable, never as numeric zero, and cannot yield `TRIGGER`.
- **D-08 — Family status meanings:** `HOLD` means no qualifying progress is demonstrated (or the family cannot be evaluated); `ACCUMULATING` means qualifying progress exists but the exact threshold is incomplete; `TRIGGER` means the existing family threshold is met without weakening its requester, organization, use-case, blocking, timing, or contributor exclusions.
- **D-09 — Composite uses weakest-link conjunction:** treat family states as `HOLD < ACCUMULATING < TRIGGER`; the composite is their minimum and becomes `TRIGGER` only when demand, downloads, and contributor activity all trigger in the same review. This prevents progress in one family from overstating the conjunctive gate.
- **D-10 — Retain bounded public metadata, not bodies:** the sidecar records UTC retrieval time, source URL, HTTP/retrieval outcome, exact scoped query and pagination limit, raw Hex `downloads` totals, returned GitHub candidate metadata/URLs, result digest, qualification/rejection reason, and final statuses. Do not copy issue bodies, private reports, tokens, credentials, or unnecessary reporter content.
- **D-11 — One authoritative snapshot, no polling:** take one deliberate Phase-131 snapshot. No scheduled workflow, analytics, telemetry, recurring bot, GitHub mutation, labeling, or outreach is added. A source failure remains an explicit unavailable result.
- **D-12 — Offline enforcement:** docs/contracts validate the committed evidence shape, allowed states, thresholds, source/query completeness, unavailable-not-zero rule, contributor exclusions, and conjunctive invariant without fetching the network. Network observations remain advisory evidence, separate from deterministic merge authority.

### Canonical newcomer discovery and API-facing journey

- **D-13 — README-first route:** the public path is `install -> select -> customize -> serve -> verify`. README owns the short start and links to HexDocs for depth, the preset guide/configurator for selection, and the runnable Phoenix example for broader reference.
- **D-14 — One locked first success:** use Invoice / Swiss / `#2C6BED` / light. Light remains the canonical print-oriented first path; the journey does not promote dark output beyond its existing screen-oriented, non-print/accessibility/PDF-UA/WCAG boundary.
- **D-15 — One formatter-owned snippet seam:** the existing generated/configurator snippet remains the source of truth for theme construction and explicit font registration. README and Phoenix documentation link or embed from that seam rather than maintaining divergent hand-written variants.
- **D-16 — Consumer-owned document boundary:** place invoice-data mapping, theme construction, recipe construction, and font registration in an application-owned document module. The Phoenix controller stays thin: obtain the app's invoice data, call the document module, then call `Rendro.Adapters.Phoenix.render_pdf/3`.
- **D-17 — Adapter owns HTTP mechanics:** newcomer code must not manually duplicate `Content-Type`, `Content-Disposition`, response sending, or Rendro error handling. The adapter is the public response boundary.
- **D-18 — Ecto stays outside the proof:** the proof uses in-memory fictional invoice data and does not add a database. Real Phoenix apps may obtain data from an Ecto context, but mapping a domain schema into recipe data is application-owned and does not belong in the Rendro adapter contract.
- **D-19 — No new UI:** preserve the current configurator as the accessible browse/pick/copy surface, including semantic labels, keyboard/focus behavior, live status/error feedback, responsive layout, and reduced-motion handling. Do not turn it into an installer, server wizard, or backend-implementation explainer.
- **D-20 — Brand-aligned microcopy:** lead with concrete verbs and verified outcomes: “Copy the theme source, build the invoice document, then serve it through the Phoenix adapter.” Keep code beside claims and limits beside capabilities; avoid “magic,” “seamless,” “just works,” design-quality language, or backend internals irrelevant to the user's job.

### Clean-room environment standard

- **D-21 — Ephemeral generated Phoenix app:** commit a small rerunnable harness that creates a uniquely named temporary API-only Phoenix application with an explicitly recorded `phx_new` version. Do not convert the checked-in `examples/phoenix_example` app into the clean-room authority.
- **D-22 — Isolate consumer state:** use fresh run-scoped Mix, Hex, dependency, build, and Rebar cache locations without repurposing `HOME`; unset `PHX_NEW_CACHE_DIR` and inherited Mix path overrides. Start with no generated app, `deps`, `_build`, or lockfile.
- **D-23 — Generate only what the job needs:** use `mix phx.new` with no installation, Ecto, HTML, or asset pipeline. The journey proves a Phoenix HTTP adapter and PDF response, not a database, LiveView, frontend, mailer, or asset toolchain.
- **D-24 — Reject workspace leakage:** before dependency resolution and again before proof, fail on `path:` or `git:` dependencies, references to the Rendro checkout, reused caches outside the isolated root, or copied application/build state. Fetch the exact Rendro release and all transitive dependencies through public package infrastructure.
- **D-25 — Record both declared and resolved versions:** retain Elixir, OTP, Hex, `phx_new`, Phoenix, Plug/Bandit, Rendro, command lines, and the resolved `mix.lock` hash. Public docs remain range-based; the evidence run is exact and reproducible.

### Journey proof and retained evidence

- **D-26 — Two complementary HTTP proofs:** first run the generated app's idiomatic `ConnCase`/`Phoenix.ConnTest` route test, then start the actual endpoint and make a real local HTTP request. ConnTest is deterministic regression authority; the live request closes the process/socket handoff.
- **D-27 — Assert the user-visible contract:** both proofs require HTTP `200`, a response `Content-Type` beginning `application/pdf`, the expected attachment disposition/filename where applicable, a non-empty body, and bytes beginning `%PDF-`.
- **D-28 — Three-layer retained record:** keep (1) the automated harness as the rerunnable procedure, (2) a machine-readable manifest containing exact versions, commands, exit results, lock/source identities, response facts, and repairs, and (3) a concise human transcript that states what happened and what to try if a source was unavailable.
- **D-29 — Do not commit ephemeral payloads:** do not commit the generated Phoenix app, downloaded dependency cache, `_build`, server PID/state, or PDF binary. Retain hashes and bounded result facts instead.
- **D-30 — Evidence lanes stay truthful:** the live Hex/GitHub/network/server run is advisory external evidence. Deterministic tests may prove the harness, templates, docs, manifest schema, and retained assertions, but must not present a cached or mocked network run as proof that public installation succeeded.
- **D-31 — Existing example retains its narrower role:** `examples/phoenix_example` remains the fast, reviewable repository regression fixture for adapter/controller behavior. Its path dependency and warm lock/build context disqualify it from JOURNEY-01 but do not reduce its ongoing test value.

### Execution-time superseding decision — failed v1.3.0 release recovery

- **D-32 — Preserve v1.3.0 history and recover with exact v1.3.1:** annotated public tag `v1.3.0` is immutable failed-release evidence and continues to peel to approved commit `3d014b8194782fc29bc685c0d5e84e4adc64b2c3`; protected release workflow run `32513353551` failed before Hex publication because its version extraction matched both the `@version "1.3.0"` declaration and `source_ref: "v#{@version}"`, producing a multiline `MIX_VERSION`. Hex package `1.3.0` is absent and HexDocs `1.3.0` was not dispatched or published. Exact `1.3.1` supersedes exact `1.3.0` as the public-package evidence pin and clean-room target, while public documentation remains `{:rendro, "~> 1.3"}`. Recovery must fix the existing release workflow parser with zero/multiple-match failure, reproduce the multiline regression deterministically, prepare and freshly approve one exact `1.3.1` candidate, and use only the existing protected tag-driven Hex path plus candidate-bound HexDocs path. The executor must never delete, move, overwrite, recreate, or retry `v1.3.0`, and must not publish `1.3.0` through any alternate path. This decision supersedes only the exact-release target portions of D-02, D-03, and D-04; D-01 through D-31 otherwise remain binding. — **Reversibility: one-way for the eventual v1.3.1 publication; reversible for the parser repair and private candidate preparation.**

### the agent's Discretion

The planner may choose exact private helper/module names, the bounded JSON schema keys, temporary-directory layout, safe local port-selection mechanics, retry/readiness probing for the local server, and focused test-module placement. It may choose the exact filenames beneath `priv/adoption_evidence/` as long as ADOPTION and journey evidence remain clearly separated or typed. It may not weaken the public-Hex boundary, remove the pre-publish human checkpoint, use a Git/path dependency, conflate unavailable with zero, change the gate thresholds, duplicate the canonical snippet, expose backend mechanics as user-facing API, commit generated/cache/PDF payloads, or merge advisory network evidence into deterministic authority.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.** The living `brand/` system supersedes `prompts/Rendro Brand Book.txt` wherever they conflict.

### Phase scope, sequencing, and accumulated decisions

- `.planning/ROADMAP.md` — Phase 131 goal, dependency, success criteria, and fixed milestone boundary.
- `.planning/REQUIREMENTS.md` — SIGNAL-02..05 and JOURNEY-01..04, plus explicit exclusions.
- `.planning/PROJECT.md` — core value, current stewardship posture, pure-core boundary, and historical release intent.
- `.planning/STATE.md` — current phase, sequencing, accumulated decisions, and deferred demand-gated capabilities.
- `.planning/phases/130-catalog-quality-evidence-ratchet/130-CONTEXT.md` — stable catalog state consumed by this journey and deterministic/advisory evidence separation.
- `.planning/milestones/v2.12-REQUIREMENTS.md` — additive-minor `1.3.0` intent and shipped preset/configurator requirements.
- `.planning/milestones/v2.12-MILESTONE-AUDIT.md` — verified preset, configurator, package/docs, Livebook, and E2E handoffs that must be present in the public release.

### Adoption gate and evidence contracts

- `ADOPTION.md` — existing thresholds, baseline, ledgers, review cadence, source commands, and prior HOLD decision.
- `test/docs_contract/adoption_claims_test.exs` — existing fail-loud public claims, threshold, command, cadence, and no-telemetry contract.
- `guides/comparison.md` — public conditional text-shaping gate handoff and truthful category boundary.
- `priv/support_matrix.json` — current support taxonomy and unsupported global-shaping boundary.

### Public discovery, presets, and user jobs

- `README.md` — public discovery root, current missing installation handoff, preset/configurator links, Phoenix example, and claims language.
- `guides/presets.md` — canonical Invoice / Swiss / `#2C6BED` / light first success and bounded preview/quality language.
- `assets/rendro/configurator/index.html` — existing accessible browse/pick/copy surface.
- `assets/rendro/configurator/index.json` — committed generated canonical snippet records.
- `lib/rendro/theme/snippet.ex` — formatter-owned snippet vocabulary and source seam.
- `guides/livebook/first_invoice.livemd` — executable canonical invoice path and current dependency patterns.
- `guides/user_flows_and_jtbd.md` — Phoenix engineer journey, recipe ladder, artifact boundary, and practical first-week progression.

### Phoenix integration and existing proof seams

- `lib/rendro/adapters/phoenix.ex` — optional adapter compile guard, response headers, success path, and Rendro error boundary.
- `test/rendro/adapters/phoenix_test.exs` — direct adapter response and error contracts.
- `examples/phoenix_example/mix.exs` — existing repository path dependency that cannot satisfy the clean-room requirement.
- `examples/phoenix_example/README.md` — current runnable reference-app setup and adapter usage.
- `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` — current thin-controller pattern and unthemed invoice gap.
- `examples/phoenix_example/lib/phoenix_example_web/router.ex` — existing route/pipeline integration point.
- `examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` — existing ConnCase, content-type, and PDF-magic assertions.
- `mix.exs` — current `1.0.0` version, optional Phoenix/Plug deps, package allowlist, docs extras, public source ref, and release aliases.

### Release and public-package gates

- `.github/workflows/release.yml` — tag-driven version parity, dry-run, and Hex publication path.
- `.github/workflows/hexdocs.yml` — public HexDocs publication path.
- `scripts/release_preflight_proof.exs` — isolated tag/version release proof and cleanup behavior.
- `guides/api_stability.md` — Stable/Evolving contract and release-facing support language.
- `CHANGELOG.md` — public additive-release narrative.

### Product, architecture, DX, and brand guidance

- `prompts/rendro-gsd-seed.md` — core value, personas, happy path, reference-app proof, optional adapter, and verification-lane defaults.
- `prompts/rendro-oss-dna.md` — executable adoption proof, docs-contract, release, package, optional-dependency, and truthful-evidence lessons.
- `prompts/rendro-integration-opportunities.md` — guide-first, thin-adapter, contract-test integration policy.
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — Phoenix-native DX, mature library lessons, day-zero/day-two jobs, and explicit footguns.
- `prompts/Rendro Brand Book.txt` — older persona, JTBD, and positioning context only; living `brand/` sources win on conflict.
- `brand/README.md` — living brand authority and source order.
- `brand/copy/VOICE.md` — concrete, example-led, honest-limit, what/where/why/next voice and microcopy rules.
- `brand/copy/marketing-copy.md` — current verified project description, CTA, quickstart, and no-overclaim language.
- `brand/audit/AUDIT.md` — current design/accessibility/maintainability pressure test.
- `brand/audit/SCORECARD.md` — developer credibility, Elixir ecosystem fit, docs usefulness, and accessibility lenses.

### External implementation references

- `https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html` — current generated-app flags, installation behavior, and cache mechanism.
- `https://phoenix.hexdocs.pm/testing_controllers.html` — idiomatic Phoenix ConnCase/ConnTest endpoint testing.
- `https://hexdocs.pm/mix/Mix.Tasks.Deps.html` — Mix dependency source and resolution behavior.
- `https://hex.hexdocs.pm/Mix.Tasks.Hex.Config.html` — Hex home/cache configuration used for isolation.
- `https://cli.github.com/manual/gh_issue_list` — scoped issue query and structured output contract.
- `https://cli.github.com/manual/gh_pr_list` — scoped merged-PR query and structured output contract.
- `https://hex.pm/api/packages/rendro` — authoritative public Rendro version and download snapshot source.
- `https://github.com/prawnpdf/prawn` — successful install/first-output/manual progression and explicit non-HTML scope precedent.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `ADOPTION.md` and `Rendro.DocsContract.AdoptionClaimsTest`: already define the three gate families, exact thresholds, source commands, exclusions, cadence, and public claims lane.
- `Rendro.Theme.Snippet` plus the committed configurator index: already own the exact requested-code seam for all bounded selections; Phase 131 should consume rather than fork it.
- `Rendro.Adapters.Phoenix`: already owns PDF response headers, disposition, sending, and structured error translation behind optional Phoenix/Plug guards.
- `examples/phoenix_example` tests: already demonstrate idiomatic `ConnCase` assertions for `200`, `application/pdf`, and `%PDF-`; they are templates for the ephemeral app, not clean-room evidence themselves.
- Existing release workflow and preflight proof: remain the required protected path for exact `1.3.1` recovery after repairing the version parser; failed `v1.3.0` is evidence, not a retry target (D-32).

### Established Patterns

- Required deterministic checks, external/network observations, and human/advisory evidence remain separate and honestly labeled.
- Public claims are contracts guarded offline; execution captures external evidence once and commits bounded facts rather than making CI poll public services.
- Core remains pure; Phoenix and Plug are optional consumer-owned dependencies, with compile/runtime guards at the adapter boundary.
- Public code examples flow from one canonical formatter seam to prevent README, configurator, generator, and Livebook drift.
- Errors and unavailable evidence explain what happened, where, why, and what to do next.

### Integration Points

- Release closure updates `mix.exs`, `CHANGELOG.md`, tag/version proof, Hex publication, and HexDocs before the journey may begin.
- README and preset documentation form the public install/select handoff; the configurator supplies exact theme/document code.
- The clean-room harness generates an app, installs the public package, inserts bounded app-owned document/controller/router/test templates, and emits a structured result record.
- Adoption evidence joins the Hex API snapshot with read-only GitHub issue and merged-PR review, then projects the four decisions into `ADOPTION.md`.
- Docs contracts validate package inclusion, source bindings, decision arithmetic, journey record shape, and no path/Git/workspace leakage without requiring live network access.

</code_context>

<specifics>
## Specific Ideas

- The user wants a one-shot, expert-owned recommendation set emphasizing great Elixir/Phoenix DX, consumer-first API design, least surprise, truthful evidence, coherent architecture, accessibility where applicable, and the project's living brand.
- Newcomer nouns are `invoice`, `theme`, `document`, `controller`, `route`, and `response`; verbs are `add`, `select`, `copy`, `build`, `serve`, and `verify`. Cache isolation, source provenance, and evidence schemas remain maintainer-facing.
- Current research rehearsal on 2026-08-21 observed Hex `downloads.all = 3149` and `downloads.week = 182`, no qualifying shaping issues, and no qualifying post-baseline non-maintainer merged PR. Under D-08/D-09, if the authoritative execution snapshot remains equivalent, the expected family decisions are Downloads `ACCUMULATING`, Demand `HOLD`, Contributor `HOLD`, Composite `HOLD`.
- Treat the checked-in Phoenix example as a regression fixture and the generated clean-room app as adoption proof; neither should impersonate the other.

</specifics>

<deferred>
## Deferred Ideas

None — global text shaping remains governed by the existing demand gate, and discussion stayed within Phase 131's adoption-evidence and newcomer-proof boundary.

</deferred>

---

*Phase: 131-adoption-snapshot-phoenix-newcomer-proof*
*Context gathered: 2026-08-21*
