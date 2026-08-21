# Phase 131: Adoption Snapshot & Phoenix Newcomer Proof - Research

**Researched:** 2026-08-21  
**Domain:** public Hex release stewardship, auditable adoption evidence, and a clean Phoenix consumer proof  
**Confidence:** HIGH for repository/release facts; MEDIUM for upstream Phoenix/Hex/GitHub CLI mechanics

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

The public package journey must fail closed on Hex, publish the intended `1.3.0` additive minor before proving the journey, use `{:rendro, "~> 1.3"}` in docs but retain an exact `1.3.0` evidence pin, and verify the Hex API/package/HexDocs surfaces before creating the clean app. Reuse the existing version/tag parity, allowlist, dry-run, preflight, CI, and post-publish release path. An explicit human decision checkpoint is required immediately before pushing the release tag or publishing; this context authorizes planning that checkpoint, not publication.

`ADOPTION.md` is the human index and a compact dated JSON sidecar under `priv/adoption_evidence/` is immutable retained evidence that must ship in the package. Retrieval availability is independent of the `HOLD`/`ACCUMULATING`/`TRIGGER` decision. `UNAVAILABLE` is never numeric zero and never yields `TRIGGER`; the composite is the weakest-link conjunction of demand, downloads, and contributor activity. Retain bounded public metadata only, take one deliberate snapshot with no polling/analytics/mutation, and enforce the evidence contract offline without fetching.

The public route is README-first: `install -> select -> customize -> serve -> verify`. The only first success is Invoice / Swiss / `#2C6BED` / light. Consume the formatter-owned configurator snippet seam; do not fork it. Put invoice mapping, theme construction, recipe construction, and font registration in an application-owned document module; keep the controller thin and call `Rendro.Adapters.Phoenix.render_pdf/3` for HTTP mechanics. Ecto is outside this proof and no new UI is permitted. Copy must be concrete, outcome-led, limit-aware, and avoid backend internals as user-facing API.

The clean-room proof is a rerunnable harness which generates a uniquely named API-only Phoenix app. It must use run-scoped Mix, Hex, dependency, build, and Rebar state without repurposing `HOME`; unset `PHX_NEW_CACHE_DIR` and inherited Mix path overrides. Begin without an app, lockfile, `deps`, or `_build`, reject path/git/workspace/cache leakage before resolution and proof, and record declared plus resolved Elixir, OTP, Hex, `phx_new`, Phoenix, Plug/Bandit, Rendro, command, and lock identities. The proof is ConnCase/ConnTest plus a real local HTTP request, both asserting `200`, PDF content type, attachment filename where applicable, non-empty body, and `%PDF-` magic. Retain harness + machine manifest + concise transcript; never commit the generated app, caches, process state, or PDF bytes. Live external/network/server evidence is advisory; offline checks cannot claim it succeeded. The existing Phoenix example remains a path-dependency regression fixture, not clean-room authority.

### the agent's Discretion

Exact private helper/module names, bounded JSON schema keys, temporary-directory layout, safe local port selection, readiness probing, focused test-module placement, and filenames beneath `priv/adoption_evidence/` remain discretionary. These choices must not weaken the public-Hex boundary, pre-publish human checkpoint, no-path/no-Git rule, gate thresholds, canonical snippet seam, adapter ownership, no-payload retention rule, or deterministic/advisory separation.

### Deferred Ideas (OUT OF SCOPE)

None — global text shaping remains demand-gated; no new UI, analytics, scheduled polling, outreach, database feature, capability family, recipe, preset, or catalog cell is in scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| SIGNAL-02 | Dated public Hex snapshot with source and raw totals | Sidecar retrieval schema, primary API verification, offline validator |
| SIGNAL-03 | Qualifying text-shaping issue review | Bounded `gh issue list` query/candidate ledger and qualification rules |
| SIGNAL-04 | Qualifying non-maintainer merged-contribution review | Bounded `gh pr list` query, exclusions, and candidate disposition |
| SIGNAL-05 | Four explicit family/composite decisions; unavailable is not zero | Separate availability and decision fields; minimum-state reducer contract |
| JOURNEY-01 | Public-package clean Phoenix install, no checkout/warm cache | Fresh generated app and env/cache/leakage checks |
| JOURNEY-02 | Public discovery to canonical Swiss/light Invoice customization | README-first links and formatter-owned snippet/template consumption |
| JOURNEY-03 | Adapter sends a valid PDF HTTP response | ConnCase plus live socket proof of headers, disposition, body, magic bytes |
| JOURNEY-04 | Exact reproducible retained journey record | Bounded manifest/transcript schema, repair log, deterministic contract tests |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep core pure: no hard Phoenix, Oban, or admin dependency.
- Preserve deterministic and advisory verification lanes in CI and docs.
- Treat documentation claims as contracts; do not claim unsupported capabilities.
- Use optional-dependency guards for integrations.
- Preserve the data-first `build -> compose -> measure -> paginate -> render -> validate` engine and its two APIs / one render core.
- Treat errors and telemetry as product behavior.
- This artifact is written within the active GSD planning workflow; later implementation must use the designated GSD execution workflow.

## Summary

Phase 131 is chiefly an evidence-and-release boundary, not a Phoenix feature. Public Hex currently reports Rendro `1.0.0` as latest, while the repository already contains the Theme/preset/configurator and optional Phoenix seams required by the locked journey. The journey must therefore be sequenced behind a deliberately authorized `1.3.0` release, verified from public infrastructure, and then exercised in a disposable consumer application. [VERIFIED: Hex package API] [VERIFIED: codebase]

The implementation should split into deterministic contract work and one explicitly advisory execution run. Offline tests validate the adoption-sidecar grammar, status arithmetic, package/docs bindings, clean-room harness templates, manifest shape, and leakage detectors. The run itself observes Hex/GitHub/public documentation and a real local server; it writes only bounded source facts, commands, hashes, and outcomes. It must never be represented as a deterministic CI proof of the then-live public registry. [VERIFIED: 131-CONTEXT.md] [VERIFIED: codebase]

**Primary recommendation:** plan release closure, evidence contracts, README/document-module/harness templates, then gate tag/publish with a human checkpoint before executing the public-Hex clean-room run and committing its bounded advisory record.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Adoption snapshot and decision | Repository docs/evidence | Hex API + GitHub API | Source observations are external; the committed index/sidecar are audited project records. |
| Package release | CI/release platform | Hex/HexDocs | Existing tag/version parity and workflow own one-way distribution. |
| Theme/document construction | Consumer application domain module | Rendro core | Customer data mapping and recipe/theme choices belong to the app, keeping core pure. |
| PDF response | Phoenix adapter | Phoenix controller | Adapter already owns headers, sending, and structured Rendro error translation. |
| HTTP integration test | Generated app test tier | Endpoint/router | ConnCase is the deterministic router/controller regression boundary. |
| Live response observation | Local endpoint process | OS socket | A real loopback request proves endpoint startup and socket handoff but remains advisory evidence. |

## Standard Stack

### Core

| Library/tool | Version | Purpose | Why standard |
|---|---:|---|---|
| Rendro public Hex package | exact `1.3.0` evidence pin; docs `~> 1.3` | Consumer PDF/theme/recipe API | Locked public-package boundary; currently published `1.0.0` proves release prerequisite. [VERIFIED: Hex package API] |
| Phoenix + Plug + Bandit generated app | generator-resolved; retain exact lock versions | HTTP route, controller, endpoint, test | Phoenix's idiomatic generated app provides the controller/ConnCase boundary. [CITED: https://phoenix.hexdocs.pm/testing_controllers.html] |
| `mix phx.new` | local `1.8.9`; record actual execution value | Fresh API-only consumer app | Official generator supports no-Ecto/no-HTML/no-assets/no-install use. [CITED: https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html] |
| Hex API + GitHub CLI | record actual versions/results | Read-only adoption observations | Existing `ADOPTION.md` already defines their public source commands. [VERIFIED: codebase] |

### Supporting

| Tool | Purpose | When to use |
|---|---|---|
| `curl` | Hex API retrieval and loopback HTTP proof | Strict noninteractive commands with bounded output/hash capture. [VERIFIED: codebase] |
| `jq` | Bounded JSON extraction/normalization | Avoid recording bodies or whole unbounded API responses. [VERIFIED: codebase] |
| `gh` | Scoped issue/PR metadata | Record query/limit and candidate metadata, never mutate labels/issues. [CITED: https://cli.github.com/manual/gh_issue_list] |
| `sha256sum`/`shasum` | Lock/PDF/result identity | Retain hashes rather than payloads. [ASSUMED] |

**Installation:** No new root runtime dependency is warranted. The generated Phoenix application's `mix.exs` must declare only public `{:rendro, "1.3.0"}` for evidence, allowing its Phoenix-generated dependencies to resolve normally. [VERIFIED: 131-CONTEXT.md]

## Package Legitimacy Audit

No new third-party package is recommended for this phase. The only added consumer dependency is Rendro itself, which is the project’s owned public Hex package; public API verification is a release gate rather than a third-party install decision. [VERIFIED: Hex package API]

## Architecture Patterns

### System Architecture Diagram

```text
Maintainer inputs                         Public sources (advisory)
  |                                       Hex API / Hex package / HexDocs / GitHub
  v                                                     |
release preflight -> HUMAN CHECKPOINT -> tag + existing CI publish -> public-surface verify
                                                                       |
                                                                       v
ADOPTION.md <--- bounded sidecar <--- one read-only snapshot ---- clean-room harness
  |                    |                                           |
  |                    v                                           v
  +--> offline docs-contract tests                         generated API-only Phoenix app
                                                            |        |
README -> preset/configurator snippet -> App.InvoiceDocument -> controller -> Rendro.Adapters.Phoenix
                                                                              |
                                         ConnCase assertion <----- endpoint/local HTTP request
                                                                              |
                                                                              v
                                                    advisory manifest + transcript (no PDF/cache/app)
```

### Recommended Project Structure

```text
priv/adoption_evidence/
  2026-08-21.json                    # immutable, bounded adoption snapshot
priv/journey_evidence/
  phoenix_clean_room_1.3.0.json      # advisory result manifest, no payload
  phoenix_clean_room_1.3.0.md        # concise human transcript
scripts/
  adoption_snapshot.exs               # one-shot retrieval + validation + write procedure
  phoenix_clean_room_proof.exs        # isolated generated-app orchestration
test/docs_contract/
  adoption_evidence_contract_test.exs
  phoenix_newcomer_contract_test.exs
test/scripts/
  phoenix_clean_room_proof_test.exs   # unit tests for pure parser/template helpers
guides/
  presets.md                          # canonical snippet source/selection remains here
README.md                             # short README-first install → select → serve route
examples/phoenix_example/             # existing fast regression fixture, unchanged authority
```

Likely release/package edits are `mix.exs` (`@version`, package `files`, docs extras), `CHANGELOG.md`, `README.md`, `ADOPTION.md`, the release/HexDocs workflows only if an existing handoff is demonstrably broken, and new bounded evidence/harness/test files. Do not add Phoenix to root dependencies. [VERIFIED: codebase]

### Pattern 1: Evidence is a typed projection, not prose parsing

**What:** Capture network observations in one versioned JSON sidecar, then render a compact human index in `ADOPTION.md`; deterministic tests parse JSON and enforce invariants without the network.

**When to use:** Every dated gate review. It prevents stale prose, unavailable-as-zero arithmetic, and raw-body/privacy creep.

**Recommended schema semantics:**

```json
{
  "schema_version": 1,
  "reviewed_at_utc": "2026-08-21T00:00:00Z",
  "families": {
    "downloads": {
      "retrieval": {"status": "AVAILABLE", "url": "https://hex.pm/api/packages/rendro", "outcome": "HTTP_200"},
      "raw": {"all": 3149, "week": 182},
      "decision": "ACCUMULATING",
      "reason": "..."
    }
  },
  "composite": {"decision": "HOLD", "rule": "minimum family decision"}
}
```

Use distinct enums: retrieval is `AVAILABLE | UNAVAILABLE`; decision is `HOLD | ACCUMULATING | TRIGGER`. `UNAVAILABLE` requires a bounded failure reason and no invented `raw` number. `TRIGGER` requires `AVAILABLE` plus all existing family threshold predicates. Composite equals the minimum ordinal of all three decisions and can be `TRIGGER` only when all three are `TRIGGER`. [VERIFIED: 131-CONTEXT.md]

### Pattern 2: App-owned document module, thin Phoenix controller

**What:** The generated app owns fixture/domain mapping and its selected theme/document; the controller delegates the response.

**Example:**

```elixir
# Source: formatter-owned snippet vocabulary in lib/rendro/theme/snippet.ex
defmodule CleanRoom.InvoiceDocument do
  def build do
    invoice = %{id: "INV-131", date: ~D[2026-08-21], items: [%{name: "Consulting", qty: 1, price: 100}]}
    preset = :swiss
    theme = Rendro.Theme.preset(preset, accent: {44, 107, 237}, mode: :light)

    invoice
    |> Rendro.Recipes.Invoice.document(theme: theme)
    |> Rendro.Theme.Presets.register_fonts(preset)
  end
end

def download(conn, _params), do: Rendro.Adapters.Phoenix.render_pdf(conn, CleanRoom.InvoiceDocument.build(), "invoice.pdf")
```

The explicit font registration is load-bearing: the canonical snippet deliberately makes it document-scoped, not global. The adapter already sets `application/pdf`, attachment disposition, sends the response, and translates `Rendro.Error`; do not duplicate those details in controller code. [VERIFIED: codebase]

### Pattern 3: Clean room is isolation plus negative proof

**What:** Fresh paths alone are insufficient; generate with `--no-install`, set fresh run roots, unset cache/path overrides, then inspect config and `mix.lock` before and after fetch.

**Required command shape:**

```sh
env -u PHX_NEW_CACHE_DIR -u MIX_DEPS_PATH -u MIX_BUILD_PATH -u MIX_ARCHIVES \
  MIX_HOME="$run_root/mix" HEX_HOME="$run_root/hex" \
  mix phx.new "$app_dir" --no-ecto --no-html --no-assets --no-mailer --no-install --no-agents-md
```

Use an explicit unique `mktemp -d` run root under the system temp directory; validate it is neither the repository nor `$HOME`; install/dependency paths must remain below that root or the generated app. A prefetch and postfetch audit must reject `path:`, `git:`, the repository absolute path, pre-existing `deps`, `_build`, or `mix.lock`, and any reused generated app. Phoenix documents that `PHX_NEW_CACHE_DIR` copies a cache containing `_build`, `deps`, and `mix.lock`, which is precisely why it must be unset. [CITED: https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html]

### Anti-Patterns to Avoid

- **Treating `examples/phoenix_example` as adoption proof:** it declares `{:rendro, path: "../.."}`. Preserve it as a fast regression fixture only. [VERIFIED: codebase]
- **Hand-copying the theme snippet into README/controller/example:** use the formatter-owned selection seam or a generated template derived from it; otherwise canonical code drifts. [VERIFIED: codebase]
- **JSON `null` or zero for failed retrieval:** an unavailable source is non-evaluable, not evidence of no demand/downloads/contributors. [VERIFIED: 131-CONTEXT.md]
- **Using a mocked Hex request as public-install success:** it can test the harness parser but cannot prove publication. [VERIFIED: 131-CONTEXT.md]
- **Adding Ecto, LiveView, assets, or a new installer UI:** those obscure the HTTP-adapter job and widen phase scope. [VERIFIED: 131-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| HTTP PDF response | Manual headers/sending/error response in each controller | `Rendro.Adapters.Phoenix.render_pdf/3` | Existing adapter owns successful and Rendro-error response semantics. [VERIFIED: codebase] |
| Phoenix test scaffold | Bespoke plug/server simulator | Generated `ConnCase` and `Phoenix.ConnTest` | Idiomatic route/controller boundary with clear failure localization. [CITED: https://phoenix.hexdocs.pm/testing_controllers.html] |
| Canonical code variant | Another theme-code formatter | `Rendro.Theme.Snippet` / configurator index | One source prevents README/configurator/Livebook divergence. [VERIFIED: codebase] |
| Release flow | New local `hex.publish` script | Existing tag-driven workflow + `mix release.preflight` | Keeps version parity, dry-run, CI, approval environment, and audit path intact. [VERIFIED: codebase] |
| Adoption polling | Scheduled job/analytics | One deliberate script/run and committed evidence | Preserves truthful advisory evidence and locked no-telemetry boundary. [VERIFIED: 131-CONTEXT.md] |

## Common Pitfalls

### Pitfall 1: Releasing before a public-surface gate

**What goes wrong:** A source tag exists but Hex/HexDocs lacks the intended package, assets, or docs; the consumer proof then diagnoses misleading downstream failures.  
**How to avoid:** Human checkpoint immediately before tag/publish; after publication query Hex API, inspect package contents, confirm versioned HexDocs and preset/font/adapter source surfaces before harness generation. Stop on any absence. [VERIFIED: 131-CONTEXT.md]

### Pitfall 2: Cache isolation that still leaks an installed project

**What goes wrong:** `PHX_NEW_CACHE_DIR` can copy `deps`, `_build`, and `mix.lock`; path overrides and existing state can silently satisfy dependencies.  
**How to avoid:** `env -u` PHX/Mix overrides, fresh `MIX_HOME`/`HEX_HOME`, empty generated path, before/after source audits, and manifest the exact lock hash. [CITED: https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html]

### Pitfall 3: Overclaiming the live run

**What goes wrong:** A committed successful transcript later reads like CI authority even after registry/version/network conditions change.  
**How to avoid:** Name its lane `advisory_external_evidence`; contracts validate only structure and retained facts. CI never refetches the sources by default. [VERIFIED: 131-CONTEXT.md]

### Pitfall 4: Testing only the controller or only the server

**What goes wrong:** ConnCase misses listener/process startup; curl-only has poorer route/controller regression diagnosis.  
**How to avoid:** assert the same response contract in both. Phoenix documents ConnCase controller testing as the normal integration boundary. [CITED: https://phoenix.hexdocs.pm/testing_controllers.html]

### Pitfall 5: Publishing sensitive or unbounded evidence

**What goes wrong:** Issue bodies, user data, auth headers, and raw caches enter git/package.  
**How to avoid:** sidecar allows query, URL, UTC, pagination limit, outcome, candidate metadata URL, digest, disposition, and bounded error only; redact environment and never serialize headers/tokens/PDF bytes. [VERIFIED: 131-CONTEXT.md]

## Code Examples

### ConnCase response contract

```elixir
# Source: Phoenix ConnCase pattern + existing Phoenix example assertions
test "GET /invoice.pdf returns the selected PDF", %{conn: conn} do
  conn = get(conn, "/invoice.pdf")

  assert conn.status == 200
  assert [content_type] = get_resp_header(conn, "content-type")
  assert String.starts_with?(content_type, "application/pdf")
  assert get_resp_header(conn, "content-disposition") == ["attachment; filename=\"invoice.pdf\""]
  assert is_binary(conn.resp_body) and byte_size(conn.resp_body) > 0
  assert binary_part(conn.resp_body, 0, 5) == "%PDF-"
end
```

### Advisory manifest fields

```json
{
  "schema_version": 1,
  "lane": "advisory_external_evidence",
  "executed_at_utc": "...",
  "declared": {"rendro": "1.3.0"},
  "resolved": {"elixir": "...", "otp": "...", "hex": "...", "phx_new": "...", "phoenix": "...", "plug": "...", "bandit": "...", "rendro": "1.3.0", "mix_lock_sha256": "..."},
  "isolation": {"phx_new_cache_dir": "UNSET", "forbidden_sources": []},
  "steps": [{"name": "conn_case", "exit_code": 0}, {"name": "loopback_http", "status": 200, "content_type": "application/pdf; charset=utf-8", "disposition": "attachment; filename=\"invoice.pdf\"", "body_bytes": 1234, "pdf_magic": true, "body_sha256": "..."}],
  "repairs": []
}
```

Never save the request/response body, local port, full local filesystem path, process PID, cache contents, token, or issue body. Store a bounded command representation with secrets removed. [VERIFIED: 131-CONTEXT.md]

## State of the Art

| Old approach | Current approach | Impact |
|---|---|---|
| Repository example with a path dependency | Ephemeral Phoenix consumer app resolving public Hex `1.3.0` | Separates regression convenience from adoption truth. [VERIFIED: codebase] |
| Distributed human-only ADOPTION tables | Human index plus typed immutable sidecar | Enables offline validation and accurate unavailable semantics. [VERIFIED: 131-CONTEXT.md] |
| One response proof | ConnCase plus loopback HTTP | Covers both internal routing and actual endpoint handoff. [VERIFIED: 131-CONTEXT.md] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | `MIX_HOME`/`HEX_HOME` plus unset overrides fully isolate every cache relevant to this installed local toolchain. | Architecture Patterns | Harness may need an additional documented env/cache root after rehearsal. |
| A2 | `sha256sum` is consistently available in the execution environment; fallback may be needed. | Standard Stack | Hash capture command portability. |

## Open Questions

1. **Exact HexDocs verification endpoint and package-content inspection command**
   - What we know: Hex API confirms the current public package is `1.0.0`; `mix.exs` package allowlist currently includes `ADOPTION.md` but not `priv/adoption_evidence/`. [VERIFIED: Hex package API] [VERIFIED: codebase]
   - What's unclear: the exact noninteractive public package-contents command used by existing release evidence.
   - Recommendation: planner should inspect existing release scripts/workflows first and make the command an explicit pre-harness stop condition.
2. **Generated app's exact Phoenix/Plug/Bandit releases**
   - What we know: local `phx_new` is `1.8.9`; Phoenix docs currently show 1.8.x generator flags. [VERIFIED: local environment] [CITED: https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html]
   - What's unclear: public resolver outcome at execution.
   - Recommendation: do not predeclare it; retain the resolved `mix.lock` identity in advisory evidence.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir/Mix | release/harness/tests | ✓ | Elixir/Mix 1.19.5, OTP 28 | — |
| `mix phx.new` | clean app generation | ✓ | Phoenix installer 1.8.9 | Record it; do not silently substitute a repo example |
| Hex | public resolution | ✓ | local config readable; record runtime version | Public release gate blocks if unavailable |
| `gh` | adoption issue/PR observation | ✓ | 2.95.0 | Record `UNAVAILABLE`, not zero, if auth/network fails |
| `curl`, `jq`, hashing | API/HTTP/evidence capture | ✓ | curl 8.7.1; jq 1.7.1 | `shasum -a 256` for hashing |

**Missing dependencies with no fallback:** None observed for planning; public release credentials are intentionally not probed or recorded.  
**Missing dependencies with fallback:** None observed.

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit (repository standard) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/docs_contract/adoption_evidence_contract_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs test/scripts/phoenix_clean_room_proof_test.exs` |
| Full suite command | `mix ci.fast` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| SIGNAL-02 | Sidecar has dated Hex URL/outcome/raw totals or explicit unavailable state | contract/unit | focused ExUnit command above | ❌ Wave 0 |
| SIGNAL-03 | Issue query, page bound, candidates, disposition, and no-body rule are valid | contract/unit | focused ExUnit command above | ❌ Wave 0 |
| SIGNAL-04 | PR query/exclusions and contributor disposition are valid | contract/unit | focused ExUnit command above | ❌ Wave 0 |
| SIGNAL-05 | status enums, unavailable-not-zero, thresholds and min composite are enforced | pure unit + contract | focused ExUnit command above | ❌ Wave 0 |
| JOURNEY-01 | harness command unsets cache overrides and rejects forbidden sources | unit/contract | focused ExUnit command above | ❌ Wave 0 |
| JOURNEY-02 | README/presets/configurator bind to one canonical snippet and app template calls it | docs contract | focused ExUnit command above | ❌ Wave 0 |
| JOURNEY-03 | generated-app ConnCase and live captured result assert PDF contract | integration template + advisory run | harness explicit invocation | ❌ Wave 0 |
| JOURNEY-04 | manifest/transcript are bounded, typed, lock-identified and no-payload | contract | focused ExUnit command above | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** focused ExUnit contracts for edited boundary.
- **Per wave merge:** `mix ci.fast`.
- **Phase gate:** full suite green plus a separately labeled, successful advisory release/public-journey run after the human publish checkpoint.

### Wave 0 Gaps

- [ ] `test/docs_contract/adoption_evidence_contract_test.exs` — schema/status/threshold/package binding.
- [ ] `test/docs_contract/phoenix_newcomer_contract_test.exs` — README/snippet/harness/manifest no-leakage contract.
- [ ] `test/scripts/phoenix_clean_room_proof_test.exs` — pure command/path/lock/result helper tests.
- [ ] Exclude the live publish, Hex/GitHub fetch, and endpoint execution from default deterministic CI; invoke them only as named advisory procedures.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | Yes, release credentials | Existing GitHub protected `Hex Publish` environment; never write/echo `HEX_API_KEY`. [VERIFIED: codebase] |
| V3 Session Management | No | No user session is introduced. |
| V4 Access Control | Yes, one-way release | Human checkpoint and existing protected CI publish path. [VERIFIED: 131-CONTEXT.md] |
| V5 Input Validation | Yes | Strict JSON schemas/enums, bounded paths/commands, reject path/git dependencies and untrusted response bodies. |
| V6 Cryptography | Yes, integrity only | Use SHA-256 identifiers supplied by system tools; do not invent cryptography. [ASSUMED] |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Secret or private body included in evidence | Information disclosure | Allowlist sidecar keys, redaction test, never serialize env/headers/body/cache. |
| Path/Git dependency or cache makes proof appear public | Tampering | Before/after source audits and fresh isolated run roots. |
| Unreviewed publish | Elevation of privilege | Human checkpoint before tag/publish and protected existing workflow. |
| Local server hangs/port collision | Denial of service | Random available loopback port, bounded readiness retries/timeouts, trap cleanup, no retained PID. [ASSUMED] |

## Sources

### Primary (HIGH confidence)

- [Hex Rendro package API](https://hex.pm/api/packages/rendro) — current `1.0.0` public release and current download totals, queried 2026-08-21.
- Repository `mix.exs`, `lib/rendro/adapters/phoenix.ex`, `lib/rendro/theme/snippet.ex`, `ADOPTION.md`, tests, and release workflow — actual seams and package/release constraints.
- Phase 131 `CONTEXT.md` — locked execution boundary and evidence semantics.

### Secondary (MEDIUM confidence)

- [Phoenix `mix phx.new`](https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html) — API-only flags, no-install behavior, and cache-copy warning.
- [Phoenix controller testing](https://phoenix.hexdocs.pm/testing_controllers.html) — ConnCase/ConnTest testing pattern.
- [Hex configuration](https://hex.hexdocs.pm/Mix.Tasks.Hex.Config.html) — local Hex configuration behavior.
- [GitHub CLI issue list](https://cli.github.com/manual/gh_issue_list) and [PR list](https://cli.github.com/manual/gh_pr_list) — scoped structured CLI observation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — locked decision plus live Hex/package/code verification.
- Architecture: HIGH — existing core/adapter/snippet/release boundaries match locked decisions.
- Pitfalls: MEDIUM — Phoenix official documentation plus codebase evidence; env-variable completeness remains rehearsal-verified.

**Research date:** 2026-08-21  
**Valid until:** 2026-08-28 for public package/generator observations; repository facts remain valid until changed.
