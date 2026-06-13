# Phase 91 Validation Map: PDF.js Advisory Proof Lane

**Created:** 2026-06-13
**Status:** passed
**Requirements:** PDFJS-01, PDFJS-02, PDFJS-03

## Validation Strategy

Phase 91 is an advisory evidence slice. Validation must prove the observer is reproducible and useful to maintainers while preventing accidental support, runtime, or required-CI claims.

The required Elixir test lane must stay free of Node/npm. Node-based verification belongs only to the new `pdfjs-advisory` CI job and explicit maintainer commands.

## Requirement Coverage

| Requirement | Verification | Command |
|---|---|---|
| PDFJS-01 | `scripts/pdfjs_observer/observe.mjs --check` re-observes committed fixture PDFs and compares stable PDF.js facts; docs-contract tests validate compact JSON shape, exact `pdfjs-dist` pin, Node version metadata, page counts, dimensions, warnings, and errors. | `node scripts/pdfjs_observer/observe.mjs --check`; `mix test test/docs_contract/pdfjs_advisory_claims_test.exs` |
| PDFJS-02 | Guardrail JSON lists `pdfjs-advisory` only under `advisory_contexts`; CI job has `continue-on-error: true` and no `needs:`; required `test` job has no Node/npm/pdfjs fragments. | `mix test test/guardrails/required_checks_contract_test.exs` |
| PDFJS-03 | Docs-contract tests ban unqualified "PDF.js support" wording in public docs and assert existing PDF.js viewer rows remain `explicit_deferral` without evidence promotion fields. | `mix test test/docs_contract/pdfjs_advisory_claims_test.exs test/docs_contract/forms_claims_test.exs test/docs_contract/signing_claims_test.exs` |

## Focused Test Set

Run after implementation:

```bash
node scripts/pdfjs_observer/observe.mjs --check
mix test test/docs_contract/pdfjs_advisory_claims_test.exs test/guardrails/required_checks_contract_test.exs
mix test test/docs_contract/forms_claims_test.exs test/docs_contract/signing_claims_test.exs test/docs_contract/viewer_evidence_claims_test.exs
mix run scripts/verify_docs.exs
```

## Full Gate

Run before phase closeout:

```bash
mix ci
```

If `mix ci` is too slow or unavailable locally, record the reason and run the focused commands plus `mix test`.

## Known Validation Choices

- First-page PNG hashing is deferred unless repeated local and CI-like runs prove stable output. PDFJS-01 makes this optional; metadata observation is the required contract.
- `--check` compares stable PDF.js facts, not `recorded_at` or OS/architecture, so a locally recorded observation can still pass in Ubuntu advisory CI.
- Node version is pinned to `22.14.0` in the advisory job to match `pdfjs-dist@6.0.227` engine requirements and the local recording environment.

