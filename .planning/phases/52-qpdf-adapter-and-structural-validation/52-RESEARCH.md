# Phase 52: qpdf Adapter and Structural Validation - Research

**Researched:** 2026-05-06  
**Domain:** Optional external `qpdf` protection adapter, password-aware Poppler structural validation, and proof-lane design for protected PDFs  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

_Verbatim copy from `.planning/phases/52-qpdf-adapter-and-structural-validation/52-CONTEXT.md`. [VERIFIED: repo inspection]_

### Locked Decisions
- **D-01:** `Rendro.Adapters.Poppler.validate/2` should be `open_password`-first. If `open_password` is present and non-empty, use only Poppler's `-upw` path.
- **D-02:** `owner_password` is accepted only as a fallback when `open_password` is not provided. Do not silently retry owner-password validation after an `open_password` failure.
- **D-03:** Do not add a generic `password:` validation option in Phase 52. Keep validation terminology aligned with the public protection contract from Phase 51.
- **D-04:** Docs and tests must state plainly that owner-only validation proves structural decryptability, not the normative password-to-open recipient path.

### qpdf permission mapping posture
- **D-05:** Do not widen Phase 52 toward lower-level qpdf parity. Keep the public advisory-permissions contract intentionally small and Phoenix-friendly.
- **D-06:** Tighten the curated whitelist once by removing or deprecating `:extract_for_accessibility`, since modern readers are expected to ignore that restriction and keeping it would create misleading expectations.
- **D-07:** Keep the rest of the public advisory-permission atoms narrow and high-signal: `:print`, `:copy`, `:modify`, `:annotate`, `:fill_forms`, and `:assemble`.
- **D-08:** Do not expose raw qpdf args, print-tier variants, modify sub-modes, metadata-encryption toggles, insecure flags, or other expert escape hatches in this milestone.

### Proof strategy for the protected-PDF lane
- **D-09:** Phase 52 should use a hybrid proof pyramid: hermetic fast tests for option mapping/redaction/temp-dir behavior, plus a narrow live-tool lane using real `qpdf` and `pdfinfo`.
- **D-10:** Default `mix test` should remain host-tool-light and contributor-friendly. Live qpdf/Poppler checks belong in an explicit tagged integration/proof lane that skips cleanly when tools are unavailable.
- **D-11:** The live lane should generate or build unprotected fixtures, protect them with real qpdf, confirm the protected artifact actually requires a password, and then validate structural readability with `pdfinfo` using the intended password path.
- **D-12:** Commit unprotected seed builders or representative authored fixtures, not protected binaries. Protected output is intentionally non-deterministic and should be generated during proof execution.

### Failure and diagnostics shape
- **D-13:** Keep public failures typed and sanitized. Do not make raw qpdf or Poppler stderr/stdout part of the stable tuple contract.
- **D-14:** Align Poppler with the existing `:protect` posture by normalizing raw `pdfinfo` failures into a small stable reason set rather than returning arbitrary tool text.
- **D-15:** Accept a small, operator-useful classification surface for validation failures such as structural invalidity, password required, incorrect password, missing executable, and generic tool failure. Keep the set intentionally small to avoid binding Rendro to vendor wording.
- **D-16:** Password values, raw command lines, temp paths, argfile contents, and rich vendor output must stay out of public errors, metadata, proof artifacts, and routine logs. Public error details may carry only narrow safe signals such as password-presence booleans or stable exit-status classes where explicitly intended.

### Downstream GSD default
- **D-17:** For this phase and similar adapter/proof/documentation work, downstream GSD agents should synthesize one cohesive recommendation set by default instead of surfacing broad menus of equivalent options.
- **D-18:** Escalate to the user only when a decision materially changes public semantics, security/trust posture, milestone scope, or release positioning. Routine tradeoff resolution should be shifted left into GSD.

### the agent's Discretion
- Exact Poppler normalized reason atom names, as long as the public classification surface stays small, stable, and redacted.
- Exact tagged-test naming and CI-lane placement, as long as the fast local lane stays low-friction and the live-tool proof lane remains explicit.
- Whether `:extract_for_accessibility` is removed immediately or deprecated with a narrow migration note, as long as the end state removes it from the truthful long-term contract.
- Exact qpdf-side proof commands used in the live lane, as long as they confirm both actual protection and structural readability.

### Deferred Ideas (OUT OF SCOPE)
- Low-level qpdf parity controls such as print tiers, modify sub-modes, metadata-encryption toggles, insecure/test-only flags, or raw CLI passthrough.
- A generic one-password validation API that collapses `open_password` and `owner_password`.
- Rich public exposure of vendor stderr/stdout or deep CLI diagnostics.
- Any viewer-behavior promotion, manual viewer proof, or release-tail work assigned to Phases 53 and 54.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADAPT-01 | Rendro ships a first-party `qpdf` protection adapter that remains an optional runtime executable rather than a hard dependency. | Keep `Rendro.Adapters.Qpdf` as a runtime executable seam with injected executable lookup/command runner, argfile-based secret passing, curated permission mapping, and no new Mix dependency. [VERIFIED: repo inspection][CITED: https://qpdf.readthedocs.io/en/latest/cli.html][CITED: https://github.com/qpdf/qpdf] |
| ADAPT-02 | Poppler structural validation can validate protected PDFs when the caller supplies the appropriate password. | Make `Rendro.Adapters.Poppler.validate/2` use `open_password` first via `-upw`, use `owner_password` only as fallback via `-opw`, normalize failures into a stable redacted reason set, and prove the behavior with a tagged live qpdf+pdfinfo lane. [VERIFIED: repo inspection][CITED: https://manpages.debian.org/testing/poppler-utils/pdfinfo.1.en.html][CITED: https://qpdf.readthedocs.io/en/latest/cli.html] |

</phase_requirements>

## Summary

Phase 52 should be planned as boundary hardening and proof-lane closure, not as a new product-surface expansion. The repo already contains the optional `Rendro.Adapters.Qpdf` executable seam, argfile temp-dir handling, `Rendro.Protect` option normalization, and a basic `Rendro.Adapters.Poppler.validate/2` password API; the missing work is truthful contraction of the public permission list, stricter Poppler password semantics, stable failure normalization, and a live proof lane that exercises real `qpdf` and `pdfinfo`. [VERIFIED: repo inspection]

The primary external-tool posture is straightforward: keep `qpdf` runtime-optional and first-party, keep secrets off argv by continuing to use `@argfile`, and do not expose more of qpdf than the narrow advisory-permissions contract already implies. qpdf’s current stable GitHub release is `12.3.2` dated January 24, 2026, and its manual explicitly documents both `@filename` argument files and the curated encryption/permission flags Rendro already maps. [CITED: https://github.com/qpdf/qpdf][CITED: https://qpdf.readthedocs.io/en/latest/cli.html]

Poppler should stay proof-oriented rather than convenience-oriented. `pdfinfo` documents distinct `-upw` and `-opw` flags, with `-opw` explicitly bypassing security restrictions, so a successful validation must prove the intended credential path, not whichever password happened to work. The live lane should therefore prove four things in order: the seed PDF is structurally valid, qpdf made the output encrypted, the output actually requires a password, and `pdfinfo` can read it through the intended password path. [CITED: https://manpages.debian.org/testing/poppler-utils/pdfinfo.1.en.html][CITED: https://qpdf.readthedocs.io/en/latest/cli.html]

**Primary recommendation:** keep one narrow public contract: `qpdf` remains an optional executable with six truthful advisory-permission atoms, Poppler validates via exactly one password path per call, and real-tool proof runs only in an explicit tagged lane that `mix test` excludes by default. [VERIFIED: repo inspection][CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Protection option normalization | API / Backend | — | `Rendro.Protect.password/2` already owns password and permission validation and should remain the single contract gate. [VERIFIED: repo inspection] |
| qpdf encryption execution | External runtime tool | API / Backend | qpdf performs the PDF encryption; Rendro prepares inputs, constrains semantics, and wraps outputs. [VERIFIED: repo inspection][CITED: https://github.com/qpdf/qpdf] |
| Structural validation of protected output | External runtime tool | API / Backend | `pdfinfo` performs structural readback while Rendro selects the intended password path and normalizes failures. [VERIFIED: repo inspection][CITED: https://manpages.debian.org/testing/poppler-utils/pdfinfo.1.en.html] |
| Password redaction and failure shaping | API / Backend | Audit / Docs | Password presence booleans and typed reasons belong in code; raw tool text and temp-path details do not. [VERIFIED: repo inspection] |
| Live proof-lane orchestration | Test / CI | Local developer workflow | The lane depends on host tools and must be explicit so default local tests stay fast and contributor-friendly. [VERIFIED: local environment][CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html] |

## Project Constraints

- Keep `rendro` core pure and avoid hard dependencies on Phoenix, Oban, or external PDF packages. [VERIFIED: AGENTS.md]
- Preserve deterministic core rendering and keep protected output as a post-render, non-deterministic artifact transform. [VERIFIED: AGENTS.md][VERIFIED: repo inspection]
- Treat documentation claims as contracts and do not let proof language drift ahead of what the structural lane actually demonstrates. [VERIFIED: AGENTS.md][VERIFIED: guides/api_stability.md]
- Preserve the existing `build -> compose -> measure -> paginate -> render -> validate` engine and keep protection/validation as artifact-side adapters. [VERIFIED: AGENTS.md][VERIFIED: repo inspection]

## Standard Stack

### Core
| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| `Rendro.Protect` | repo-local | Canonical artifact-first protection boundary | It already owns typed option validation, adapter selection, metadata shaping, and redaction. [VERIFIED: repo inspection] |
| `Rendro.Adapters.Qpdf` | repo-local over `qpdf` `12.3.2` stable release | First-party external protection backend | It matches the Phase 51 contract and keeps encryption outside the deterministic core. [VERIFIED: repo inspection][CITED: https://github.com/qpdf/qpdf] |
| `qpdf` CLI | `12.3.2` latest stable GitHub release on 2026-01-24 | AES-256 protection, encryption inspection, and proof support | Official docs cover `--encrypt`, `--is-encrypted`, `--requires-password`, `@filename`, and the relevant permission flags. [CITED: https://github.com/qpdf/qpdf][CITED: https://qpdf.readthedocs.io/en/latest/cli.html] |
| `Rendro.Adapters.Poppler` | repo-local over `pdfinfo` | Structural validation boundary | It is already the project’s structural proof tool and already accepts password-shaped options. [VERIFIED: repo inspection] |
| `pdfinfo` / Poppler | host has `26.04.0`; docs verified against `25.03.0` manpage | Structural readability checks for protected PDFs | Official manpage documents `-upw`, `-opw`, and exit-code classes. [VERIFIED: local environment][CITED: https://manpages.debian.org/testing/poppler-utils/pdfinfo.1.en.html] |

### Supporting
| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| ExUnit | bundled with Elixir `1.19.5` | Hermetic unit tests and tagged live-tool lane | Use default-fast tests plus `--include` for proof lanes. [VERIFIED: local environment][CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html] |
| Mix test filters | bundled with Elixir `1.19.5` | Include/exclude tagged lanes from CLI | Use to keep `mix test` fast and opt into qpdf+pdfinfo proof explicitly. [VERIFIED: local environment][CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] |
| Docs-contract lane | repo-local `scripts/verify_docs.exs` | Contract regression for support wording | Reuse if Phase 52 touches `guides/api_stability.md` or `priv/support_matrix.json`. [VERIFIED: repo inspection] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `qpdf` executable seam | Native in-core encryption | Out of scope for v1.10 and would widen non-deterministic core behavior. [VERIFIED: requirements and roadmap] |
| Curated permission atoms | Raw qpdf passthrough | Exposes low-level flags, misleading combinations, and public contract surface Rendro does not want to support. [CITED: https://qpdf.readthedocs.io/en/latest/cli.html][VERIFIED: phase context] |
| Explicit live proof lane | Always-on host-tool tests | Breaks fast default `mix test` and adds nondeterministic contributor setup requirements. [VERIFIED: local environment][CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html] |

## Architecture Patterns

### System Architecture Diagram

```text
unprotected seed artifact / fixture
        |
        v
Rendro.Protect.password/2
  - validate passwords + curated permissions
  - select adapter
        |
        v
Rendro.Adapters.Qpdf
  - find executable
  - write 0700 temp dir
  - write 0600 input + argfile
  - qpdf @argfile protect
        |
        v
protected PDF bytes
        |
        +--> qpdf --is-encrypted / --requires-password
        |      confirms encryption + password requirement
        |
        v
Rendro.Adapters.Poppler.validate/2
  - choose exactly one password path
  - pdfinfo reads structure
  - normalize failure reason
        |
        v
typed, redacted result
```

### Recommended Project Structure

```text
lib/rendro/
├── protect.ex                  # public option validation and wrapping
├── protect/adapter.ex          # adapter behaviour
└── adapters/
    ├── qpdf.ex                 # external qpdf executable seam
    └── poppler.ex              # external pdfinfo validation seam

test/rendro/adapters/
├── qpdf_test.exs               # hermetic mapping/cleanup tests + optional live qpdf proof
└── poppler_test.exs            # hermetic normalization tests + optional live pdfinfo proof

test/support/
└── ...                         # seed builders / fixture helpers for unprotected PDFs
```

### Pattern 1: Keep `qpdf` optional and secret-light
**What:** Continue treating `qpdf` as a runtime executable boundary, not a dependency, while passing secrets through `@argfile` instead of argv. [VERIFIED: repo inspection][CITED: https://qpdf.readthedocs.io/en/latest/cli.html]  
**When to use:** For every public protection call in Phase 52.  
**Example:**
```elixir
# Source: repo seam + qpdf docs
case System.find_executable("qpdf") do
  nil -> {:error, {:missing_executable, "qpdf"}}
  path -> System.cmd(path, ["@" <> argfile_path], stderr_to_stdout: true)
end
```

### Pattern 2: Immediate permission contraction
**What:** Reduce the public advisory-permissions list to `:print`, `:copy`, `:modify`, `:annotate`, `:fill_forms`, and `:assemble`, and remove `:extract_for_accessibility` from the truthful contract. qpdf documents that for AES-based encryption conforming readers should disregard the accessibility restriction, and the qpdf library disregards that field for AES 128/256. [VERIFIED: repo inspection][CITED: https://qpdf.readthedocs.io/en/latest/cli.html]  
**When to use:** In `Rendro.Protect.supported_permissions/0`, option validation, docs, and tests.  
**Recommended mapping:**  
- `:print` -> `--print=full` / `--print=none` [VERIFIED: repo inspection][CITED: https://qpdf.readthedocs.io/en/latest/cli.html]  
- `:copy` -> `--extract=y` / `--extract=n` [VERIFIED: repo inspection][CITED: https://qpdf.readthedocs.io/en/latest/cli.html]  
- `:modify` -> `--modify=all` / `--modify=none` [VERIFIED: repo inspection][CITED: https://qpdf.readthedocs.io/en/latest/cli.html]  
- `:annotate` -> `--annotate=y` / `--annotate=n` [VERIFIED: repo inspection][CITED: https://qpdf.readthedocs.io/en/latest/cli.html]  
- `:fill_forms` -> `--form=y` / `--form=n` [VERIFIED: repo inspection][CITED: https://qpdf.readthedocs.io/en/latest/cli.html]  
- `:assemble` -> `--assemble=y` / `--assemble=n` [VERIFIED: repo inspection][CITED: https://qpdf.readthedocs.io/en/latest/cli.html]

### Pattern 3: One password path per Poppler validation call
**What:** If `open_password` is present, pass only `-upw`; otherwise if `owner_password` is present, pass only `-opw`; otherwise pass neither. `pdfinfo` documents `-opw` as bypassing restrictions, so using both would weaken the proof semantics of a successful run. [VERIFIED: repo inspection][CITED: https://manpages.debian.org/testing/poppler-utils/pdfinfo.1.en.html]  
**When to use:** In `Rendro.Adapters.Poppler.validate/2`.  
**Example:**
```elixir
# Source: pdfinfo manpage semantics
args =
  cond do
    present?(opts[:open_password]) -> ["-upw", opts[:open_password], file_path]
    present?(opts[:owner_password]) -> ["-opw", opts[:owner_password], file_path]
    true -> [file_path]
  end
```

### Pattern 4: Split hermetic tests from live proof
**What:** Keep unit tests pure by injecting executable finders/runners and tagging real-tool proof separately. ExUnit supports excluding tagged tests by default and including them explicitly from the CLI. [VERIFIED: repo inspection][CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html][CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html]  
**When to use:** For all qpdf/pdfinfo integration coverage in Phase 52.  
**Example:**
```elixir
# Source: ExUnit docs
ExUnit.start()
ExUnit.configure(exclude: [live_pdf_tools: true])

@tag live_pdf_tools: true
test "qpdf + pdfinfo proof lane" do
  ...
end
```

### Anti-Patterns to Avoid

- **Do not pass both `-upw` and `-opw` to `pdfinfo`:** it blurs whether validation succeeded via the user/open path or the owner bypass path. [CITED: https://manpages.debian.org/testing/poppler-utils/pdfinfo.1.en.html]
- **Do not keep `:extract_for_accessibility` as a truthful permission atom:** qpdf documents that this restriction is disregarded for AES paths and should generally not be disabled. [CITED: https://qpdf.readthedocs.io/en/latest/cli.html]
- **Do not commit protected fixture binaries:** protected output is intentionally non-deterministic and Phase 52 context explicitly rejects committing protected artifacts. [VERIFIED: phase context][VERIFIED: guides/api_stability.md]
- **Do not expose raw qpdf/pdfinfo stderr in stable tuples:** current local `pdfinfo` emits free-form warning/error text on corrupt input, which is exactly the volatility the phase wants to normalize away. [VERIFIED: local environment]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PDF encryption engine | Native AES writer logic in core | `qpdf` executable seam | Keeps crypto outside the deterministic render engine and reuses a battle-tested PDF transformer. [VERIFIED: requirements and roadmap][CITED: https://github.com/qpdf/qpdf] |
| Permission-bit translation DSL | Raw PDF permission mask or raw qpdf flag passthrough | Fixed atom whitelist mapped to six qpdf flags | qpdf exposes more granularity than Rendro wants to promise; narrow atoms avoid misleading public semantics. [CITED: https://qpdf.readthedocs.io/en/latest/cli.html][VERIFIED: phase context] |
| Password-path heuristics in docs | “Any password works” wording | Explicit `open_password`-first and `owner_password` fallback contract | `pdfinfo` differentiates user and owner flags, and owner bypass has different proof meaning. [CITED: https://manpages.debian.org/testing/poppler-utils/pdfinfo.1.en.html] |
| Golden protected binaries | Checked-in encrypted fixtures | Unprotected seed builders plus runtime protection in tagged tests | Protected output is non-deterministic and would create brittle fixture churn. [VERIFIED: phase context][VERIFIED: guides/api_stability.md] |
| Public error free text | Stable tuples containing stderr text | Small normalized reason set plus safe booleans or exit-status class | Existing Rendro error posture is typed and redacted rather than vendor-text-shaped. [VERIFIED: repo inspection] |

**Key insight:** Phase 52 succeeds by narrowing semantics, not by surfacing more of qpdf or Poppler. The more vendor detail leaked into the public contract, the more future tool-version drift becomes a breaking API problem. [VERIFIED: repo inspection][CITED: https://github.com/qpdf/qpdf][CITED: https://manpages.debian.org/testing/poppler-utils/pdfinfo.1.en.html]

## Common Pitfalls

### Pitfall 1: Proving the wrong password path
**What goes wrong:** Validation succeeds with `owner_password`, and tests/docs accidentally treat that as proof of the password-to-open path. [CITED: https://manpages.debian.org/testing/poppler-utils/pdfinfo.1.en.html]  
**Why it happens:** `-opw` bypasses restrictions while `-upw` proves the user/open path. [CITED: https://manpages.debian.org/testing/poppler-utils/pdfinfo.1.en.html]  
**How to avoid:** Pass exactly one password flag and prefer `open_password` whenever present. [VERIFIED: phase context]  
**Warning signs:** Tests pass even when `open_password` is intentionally wrong but `owner_password` is correct. [ASSUMED]

### Pitfall 2: Shipping a misleading accessibility permission
**What goes wrong:** Rendro implies a meaningful accessibility restriction even though qpdf and the PDF spec expect conforming readers to ignore it for modern AES paths. [CITED: https://qpdf.readthedocs.io/en/latest/cli.html]  
**Why it happens:** The current Phase 51 code still exposes `:extract_for_accessibility` in the whitelist. [VERIFIED: repo inspection]  
**How to avoid:** Remove the atom from the public list and update tests/docs in the same phase. [VERIFIED: phase context]  
**Warning signs:** `supported_permissions/0` and docs mention accessibility restriction after Phase 52 lands. [VERIFIED: repo inspection]

### Pitfall 3: Letting raw tool text become API
**What goes wrong:** `Poppler.validate/2` returns raw `pdfinfo` stderr, binding Rendro to unstable wording and risking secret/path leakage. [VERIFIED: repo inspection]  
**Why it happens:** The current implementation returns `{:invalid_pdf, String.trim(output)}` on failure. [VERIFIED: repo inspection]  
**How to avoid:** Normalize to a small stable reason set and keep raw text only for ephemeral internal debugging, not stable tuples. [VERIFIED: phase context]  
**Warning signs:** Tests assert on full `pdfinfo` output strings or include temp-path/password substrings. [VERIFIED: repo inspection]

### Pitfall 4: Making the live lane part of default `mix test`
**What goes wrong:** Contributors without qpdf fail ordinary local tests or incur avoidable runtime/tooling friction. [VERIFIED: local environment]  
**Why it happens:** This host already lacks `qpdf` while still being a valid Elixir development environment. [VERIFIED: local environment]  
**How to avoid:** Exclude the tagged live lane by default and include it only in explicit commands or CI jobs. [CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html]  
**Warning signs:** `mix test` starts shelling out to `qpdf` on a clean machine without any `--include` opt-in. [ASSUMED]

## Code Examples

### Live proof command sequence
```bash
# Source: qpdf + pdfinfo official docs
qpdf @"$ARGFILE"
qpdf --is-encrypted protected.pdf
qpdf --requires-password protected.pdf
qpdf --password="$OPEN_PASSWORD" --requires-password protected.pdf
pdfinfo -upw "$OPEN_PASSWORD" protected.pdf
```
[CITED: https://qpdf.readthedocs.io/en/latest/cli.html][CITED: https://manpages.debian.org/testing/poppler-utils/pdfinfo.1.en.html]

### Tagged ExUnit lane
```elixir
# Source: ExUnit filter docs
ExUnit.configure(exclude: [live_pdf_tools: true])

@tag live_pdf_tools: true
test "protected pdf round-trip with qpdf and pdfinfo" do
  ...
end
```
[CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Flatten user/open and owner password semantics | Preserve distinct password roles in both protection and validation | Already reflected in Phase 51/52 context and current API shape | Keeps proof language honest and avoids owner-bypass false positives. [VERIFIED: repo inspection][CITED: https://manpages.debian.org/testing/poppler-utils/pdfinfo.1.en.html] |
| Treat accessibility restriction as a normal permission bit | Treat it as non-truthful for modern AES paths and remove it from Rendro’s public contract | Current qpdf docs explicitly describe the restriction as disregarded for AES 128/256 | Prevents misleading security/accessibility narratives. [CITED: https://qpdf.readthedocs.io/en/latest/cli.html] |
| Always-on integration tests | Explicit tagged proof lane with hermetic default tests | Supported by ExUnit/Mix filtering and required by current host-tool reality | Preserves fast `mix test` while still enabling real-tool proof. [VERIFIED: local environment][CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html] |
| Raw vendor stderr in tuples | Normalized stable reason atoms with redaction | Required by Phase 52 decisions and aligned with existing `Rendro.Error` posture | Reduces API drift and secret-leak risk. [VERIFIED: phase context][VERIFIED: repo inspection] |

**Deprecated/outdated:** `:extract_for_accessibility` as a truthful public advisory-permission atom is outdated for Phase 52’s AES-256-only contract. [VERIFIED: repo inspection][CITED: https://qpdf.readthedocs.io/en/latest/cli.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `pdfinfo` wrong-password and password-required failures can be separated reliably enough by internal heuristics without exposing raw vendor text, but the exact stderr/exit-code combination still needs capture on a qpdf-enabled host. [ASSUMED] | Common Pitfalls / Validation Architecture | Medium — the planner may need an extra implementation task to record and freeze the heuristic with live-tool tests. |

## Resolved Contract Decision

1. **Poppler should preserve the outer `{:invalid_pdf, reason}` tuple shape in Phase 52.**
   - Decision: keep the existing public outer tuple and normalize only the inner reason, for example `{:error, {:invalid_pdf, :password_required}}` or `{:error, {:invalid_pdf, :incorrect_password}}`. [VERIFIED: repo inspection][VERIFIED: phase context]
   - Rationale: this preserves caller expectations around the current adapter surface while still removing raw `pdfinfo` text from the stable contract. [VERIFIED: repo inspection]
   - Planning consequence: live-tool tests must pin at least `:password_required` and `:incorrect_password` against real `qpdf` plus `pdfinfo` behavior so the classifier does not drift silently. [VERIFIED: phase context]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `qpdf` | Live protection proof lane and real adapter execution | ✗ | — | Hermetic adapter tests remain available; CI or an explicit local setup must provide qpdf for proof. [VERIFIED: local environment] |
| `pdfinfo` | Structural validation adapter and live proof lane | ✓ | `26.04.0` on this host | — [VERIFIED: local environment] |
| `mix` / ExUnit | All hermetic and live test lanes | ✓ | Elixir `1.19.5`, OTP `28` | — [VERIFIED: local environment] |

**Missing dependencies with no fallback:**
- Real qpdf-backed proof on this machine is blocked until `qpdf` is installed. Hermetic unit coverage is not blocked. [VERIFIED: local environment]

**Missing dependencies with fallback:**
- None beyond the hermetic-vs-live split already recommended. [VERIFIED: local environment]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit bundled with Elixir `1.19.5` [VERIFIED: local environment] |
| Config file | `test/test_helper.exs` only; no special ExUnit filter config yet. [VERIFIED: repo inspection] |
| Quick run command | `mix test` [VERIFIED: repo inspection] |
| Full suite command | `mix ci` [VERIFIED: repo inspection] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADAPT-01 | qpdf remains optional, uses curated permission mapping, cleans temp artifacts, and never leaks secrets in public failures | unit + tagged live proof | `mix test test/rendro/adapters/qpdf_test.exs` and `mix test --include live_pdf_tools:true test/rendro/adapters/qpdf_test.exs` | `test/rendro/adapters/qpdf_test.exs` exists; live subset not yet explicit. [VERIFIED: repo inspection] |
| ADAPT-02 | Poppler validates protected PDFs through the intended password path and normalizes failures | unit + tagged live proof | `mix test test/rendro/adapters/poppler_test.exs` and `mix test --include live_pdf_tools:true test/rendro/adapters/poppler_test.exs` | `test/rendro/adapters/poppler_test.exs` exists; protected live proof coverage not yet present. [VERIFIED: repo inspection] |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/adapters/qpdf_test.exs test/rendro/adapters/poppler_test.exs test/rendro/protect_test.exs test/rendro/error_test.exs` [VERIFIED: repo inspection]
- **Per wave merge:** `mix test` plus `mix test --include live_pdf_tools:true test/rendro/adapters/qpdf_test.exs test/rendro/adapters/poppler_test.exs` on a host with both tools. [CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html][VERIFIED: local environment]
- **Phase gate:** `mix ci` plus the explicit live-tool lane green before `/gsd-verify-work`. [VERIFIED: repo inspection]

### Wave 0 Gaps
- [ ] Add a default ExUnit exclude for the live lane in `test/test_helper.exs`, for example `ExUnit.configure(exclude: [live_pdf_tools: true])`. [CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html][VERIFIED: repo inspection]
- [ ] Add explicit tagged live proof cases that generate an unprotected seed, protect it with real qpdf, assert `--is-encrypted` and `--requires-password`, and then validate with `pdfinfo`. [VERIFIED: phase context]
- [ ] Add focused Poppler normalization tests that lock the stable reason set without asserting on raw vendor wording. [VERIFIED: phase context][VERIFIED: repo inspection]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | PDF passwords here are document credentials, not application authentication. [VERIFIED: phase scope] |
| V3 Session Management | no | No session state is introduced in this phase. [VERIFIED: phase scope] |
| V4 Access Control | no | Advisory permissions are intentionally documented as non-enforcing viewer hints, not application access control. [VERIFIED: guides/api_stability.md][CITED: https://qpdf.readthedocs.io/en/latest/cli.html] |
| V5 Input Validation | yes | Keep validation at `Rendro.Protect.password/2` and restrict Poppler/qpdf inputs to explicit password and curated permission fields. [VERIFIED: repo inspection] |
| V6 Cryptography | yes | Use `qpdf` for encryption; do not hand-roll crypto or expose insecure qpdf flags in the public contract. [VERIFIED: requirements and roadmap][CITED: https://qpdf.readthedocs.io/en/latest/cli.html] |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Password leakage through argv, logs, or public errors | Information Disclosure | Keep `qpdf` secrets in `@argfile`, redact error details, and never surface raw stderr or temp paths in stable tuples. [VERIFIED: repo inspection][CITED: https://qpdf.readthedocs.io/en/latest/cli.html] |
| Command/flag injection through password content | Tampering | Keep current password validation that rejects control characters and never invoke a shell. [VERIFIED: repo inspection] |
| False proof via owner-password bypass | Spoofing | Use exactly one Poppler password path per call and prefer `open_password` when present. [CITED: https://manpages.debian.org/testing/poppler-utils/pdfinfo.1.en.html] |
| Misleading advisory-permission claims | Repudiation | Publish only the six curated atoms and remove accessibility restriction from the truthful contract. [VERIFIED: phase context][CITED: https://qpdf.readthedocs.io/en/latest/cli.html] |
| Fixture drift from checked-in protected binaries | Integrity | Generate protected outputs during proof execution from unprotected seeds only. [VERIFIED: phase context] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/52-qpdf-adapter-and-structural-validation/52-CONTEXT.md` - locked scope, decisions, and proof posture. [VERIFIED: repo inspection]
- `.planning/REQUIREMENTS.md` - `ADAPT-01` and `ADAPT-02` phase requirements. [VERIFIED: repo inspection]
- `.planning/milestones/v1.10-ROADMAP.md` - phase goal and plan split. [VERIFIED: repo inspection]
- `lib/rendro/protect.ex` - current public protection contract and permission whitelist. [VERIFIED: repo inspection]
- `lib/rendro/adapters/qpdf.ex` - current qpdf executable seam, argfile use, and mapping logic. [VERIFIED: repo inspection]
- `lib/rendro/adapters/poppler.ex` - current password flag behavior and raw failure handling. [VERIFIED: repo inspection]
- `lib/rendro/error.ex` - existing typed error posture. [VERIFIED: repo inspection]
- `test/rendro/adapters/qpdf_test.exs` and `test/rendro/adapters/poppler_test.exs` - current hermetic test seams. [VERIFIED: repo inspection]
- `guides/api_stability.md` and `priv/support_matrix.json` - existing truthful support wording. [VERIFIED: repo inspection]
- qpdf manual (`Running qpdf` / `qpdf Command-line Options`) - encryption, `@filename`, permission flags, `--is-encrypted`, and `--requires-password`. [CITED: https://qpdf.readthedocs.io/en/latest/cli.html][CITED: https://qpdf.readthedocs.io/en/stable/qpdf-options.html]
- qpdf GitHub repo - latest stable release `12.3.2` dated 2026-01-24. [CITED: https://github.com/qpdf/qpdf]
- Poppler `pdfinfo` manpage - `-upw`, `-opw`, and exit-code classes. [CITED: https://manpages.debian.org/testing/poppler-utils/pdfinfo.1.en.html]
- ExUnit and Mix test docs - tag include/exclude behavior. [CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html][CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html]

### Secondary (MEDIUM confidence)
- Local host behavior: `pdfinfo` is installed as `26.04.0`, `qpdf` is missing, and corrupt/valid PDFs produce exit `1`/`0` respectively on this machine. [VERIFIED: local environment]

### Tertiary (LOW confidence)
- None. [VERIFIED: research session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - repository seams and official qpdf/pdfinfo docs line up cleanly. [VERIFIED: repo inspection][CITED: https://qpdf.readthedocs.io/en/latest/cli.html][CITED: https://manpages.debian.org/testing/poppler-utils/pdfinfo.1.en.html]
- Architecture: HIGH - phase scope is tightly locked by context and current code already reflects the intended artifact-first adapter pattern. [VERIFIED: phase context][VERIFIED: repo inspection]
- Pitfalls: MEDIUM - most pitfalls are verified directly, but the exact Poppler wrong-password heuristic still needs capture on a qpdf-enabled host. [VERIFIED: repo inspection][ASSUMED]

**Research date:** 2026-05-06  
**Valid until:** 2026-06-05
