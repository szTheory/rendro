---
status: partial
phase: 05-early-ecosystem-recipes
source: [05-VERIFICATION.md]
started: 2026-04-26T20:05:00Z
updated: 2026-04-26T20:05:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Mailglass custom wrapper dispatch via `put_swoosh/2` (REVIEW CR-01)
expected: |
  In an environment with a real `:mailglass` dependency, create a struct module
  named `MyApp.Invoice.Message` that (a) ends in `.Message`, (b) exports its own
  `update_swoosh/2`, and (c) has a `:swoosh` field holding a `%Swoosh.Email{}`.
  Then `Rendro.Adapters.Mailglass.attach_pdf(msg, doc, "invoice.pdf")` should
  return `{:ok, %MyApp.Invoice.Message{}}` with the attachment added — not crash
  with `FunctionClauseError`.

  Per the code trace: `put_swoosh/2` (lib/rendro/adapters/mailglass.ex:130) calls
  `apply(Mailglass.Message, :update_swoosh, [...])` regardless of the input
  struct, so a non-`%Mailglass.Message{}` wrapper crashes.

  Cannot be reproduced in CI because the test fixture `Mailglass.Wrapper.Message`
  has no `:swoosh` field, so it bails earlier in `extract_swoosh/1`.

  Decision required: does the canonical `%Mailglass.Message{}` recipe satisfy
  SC1 ("tested recipes for mailglass"), or must the custom-wrapper dispatch be
  fixed first? See `05-VERIFICATION.md` and `05-REVIEW.md` (CR-01) for the
  5-line fix.
result: [pending]

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps
