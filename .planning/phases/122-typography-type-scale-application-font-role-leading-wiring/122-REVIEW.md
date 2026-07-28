---
phase: 122-typography-type-scale-application-font-role-leading-wiring
reviewed: 2026-07-28T15:11:51Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - lib/rendro/recipes/branded_invoice.ex
  - lib/rendro/recipes/certificate.ex
  - lib/rendro/recipes/invoice.ex
  - lib/rendro/recipes/payslip.ex
  - lib/rendro/recipes/receipt.ex
  - lib/rendro/recipes/statement.ex
  - lib/rendro/recipes/ticket.ex
  - priv/goldens/certificate/dark.sha256
  - priv/goldens/statement/dark.sha256
  - test/rendro/recipes/branded_invoice_opts_threading_test.exs
  - test/rendro/recipes/certificate_opts_threading_test.exs
  - test/rendro/recipes/invoice_opts_threading_test.exs
  - test/rendro/recipes/invoice_typography_test.exs
  - test/rendro/recipes/no_inline_color_literals_test.exs
  - test/rendro/recipes/no_inline_size_literals_test.exs
  - test/rendro/recipes/payslip_opts_threading_test.exs
  - test/rendro/recipes/receipt_opts_threading_test.exs
  - test/rendro/recipes/statement_opts_threading_test.exs
  - test/rendro/recipes/statement_typography_test.exs
  - test/rendro/recipes/ticket_opts_threading_test.exs
  - test/rendro/recipes/ticket_typography_test.exs
  - lib/rendro/font_registry.ex
findings:
  critical: 1
  warning: 2
  info: 2
  total: 5
status: issues_found
---

# Phase 122: Code Review Report

**Reviewed:** 2026-07-28T15:11:51Z
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Summary

Phase 122 adds a `defp typography/1` seam (structural twin of `palette/1`) to
all seven recipes, threading `size:`, `font:`, and `line_height/widows/orphans`
from a resolved type scale into every `%Text{}`. The no-theme byte-identity
contract holds: I ran all seven `*_byte_identity_test.exs`, the two static-scan
teeth tests, all three typography raise-path tests, and every `*_opts_threading`
test — **125+ tests, 0 failures**. The subtle `:default`-atom vs.
`"Helvetica"`-string resolution reasoning in the `typography/1` doc comments was
verified against `font_registry.ex` `normalize_reference/2` and is correct: both
normalize to the same logical `:default` descriptor for documents that do not
call `put_default_font`, so seaming `font: :default` is genuinely byte-identical
to the prior no-`font:` runs.

The seam is well-executed on the **no-theme** path. The defects are on the
**themed** path, which the phase's own tests never exercise beyond `%Section{}`
struct equality (they never `render/2` or `measure_rows/4`). One is a hard
render regression (BLOCKER); the rest are robustness/coverage gaps.

## Critical Issues

### CR-01: Font seam drops Payslip's unicode fallback under any theme — themed Payslip fails to render

**File:** `lib/rendro/recipes/payslip.ex:877-894` (typography seam) with call sites `633-644` (`cell_text/2`) and `781-811` (`footer_section/2`)

**Issue:**
Payslip is the one recipe that registers a document default font *with a B612
unicode fallback* (`with_unicode_fallback_font/1`, lines 267-278:
`put_default_font(:payslip_sans)`, whose descriptor carries
`fallbacks: [:payslip_unicode_fallback]`). Its `typography/1` **no-theme** branch
correctly uses the string `"Helvetica"` for every font role, because
`normalize_reference("Helvetica", :payslip_sans)` resolves to `:payslip_sans`
(fallback-bearing). The doc comment (lines 862-875) explains this carefully.

But the **theme** branch returns `Rendro.Theme.resolve(theme).typography`, whose
`fonts.<role>` values are the bare `:default` atom. `normalize_reference(:default, _)`
passes straight through to `:default` — the bare built-in Helvetica descriptor
with **no fallback**. So under *any* theme, every Payslip text run loses the B612
fallback that its own default data handling depends on:

- `glyph_safe/1` (line 417) rewrites the D-14 masking middot `"·"` to `"•"`
  (U+2022). U+2022 is **not** in the base Helvetica metrics table (ASCII 32-126
  only), so a masked `payment_method` — the canonical documented format — makes a
  themed Payslip fail.
- D-17 accented `:description` content (e.g. `"Impôt…"`, the module's own
  example) fails the same way.

Reproduced (default theme, otherwise-valid data):

```
# ASCII payslip + documented "···· 4321" payment mask, theme: Rendro.Theme.default()
{:error, %Rendro.Error{reason: {:unsupported_glyph, "•"}, stage: :measure, ...}}

# earnings description "Impôt Base", same theme
** (ArgumentError) Rendro.measure_rows/4 could not measure the table:
   {:unsupported_glyph, "ô"}   (raised from payslip.ex:582 inside document/2)
```

This is a regression introduced by this phase: before the font seam, themed
Payslip (Phase 121 added `:theme` for colors only) kept the struct-default
`"Helvetica"` → `:payslip_sans` resolution and rendered these glyphs fine. The
`:theme` branch now overrides fonts and severs the fallback.

**Fix:** The theme's font roles must resolve through Payslip's fallback-bearing
font, not the bare `:default`. Remap the resolved theme typography's `fonts` onto
`:payslip_sans` (or register the fallback chain on whatever role the theme names)
before threading:

```elixir
theme ->
  t = Rendro.Theme.resolve(theme).typography
  # Payslip's glyph_safe/D-17 output needs the B612 fallback on every role.
  %{t | fonts: %{heading: :payslip_sans, body: :payslip_sans, mono: :payslip_sans}}
```

(or, better, keep the theme's font intent but register those atoms *with*
`fallbacks: [:payslip_unicode_fallback]` in `with_unicode_fallback_font/1`).
Then add the themed-render test called for in WR-02.

## Warnings

### WR-01: Certificate centering measures with hardcoded Helvetica but renders with the seamed font role — de-centers under a custom-font theme

**File:** `lib/rendro/recipes/certificate.ex:340`, `352`, `406-422`

**Issue:**
`body_section/2` fixes `font = Rendro.PDF.Font.helvetica()` (line 340) and uses it
for every centering measurement — `text_width(font, body_text, body_size)` (line
352) and inside `centered_line/7` `text_width(font, text, size)` (line 407) — to
compute `x = max((region_w - width) / 2, 0)`. But the emitted `%Text{}` run now
carries `font: font_role` where `font_role` = `type.fonts.heading` /
`type.fonts.body` from the seam (lines 367-388, 411-419). The seam's own
"measurement coupling" comment (lines 311-314, 400-405) explicitly resolves the
*size* once for both measurement and rendering — but the *font* was not given the
same treatment. On the no-theme / default-theme path `type.fonts.*` == `:default`
== built-in Helvetica, so measurement matches. Under a theme whose
`typography.fonts.heading`/`.body` names a real non-Helvetica embedded font
(the raise-path tests prove `fonts.<role>` is freely settable to arbitrary
atoms), the recipient name / title / body would be measured with Helvetica
metrics but rendered with the themed font, producing visibly mis-centered text.
Not a crash, but a correctness gap in the exact "font-role wiring" this phase
delivers.

**Fix:** Resolve the measurement font from the same seam role used for the run,
e.g. resolve the run's `font_role` to its PDF font via the document font registry
and measure against that (or, minimally, document that Certificate centering is
only correct for Helvetica-metric font roles and guard/normalize accordingly).

### WR-02: Themed recipe rendering is untested — only `%Section{}` struct equality is asserted

**File:** `test/rendro/recipes/payslip_opts_threading_test.exs:33-51` (representative; same pattern in every `*_opts_threading_test.exs`)

**Issue:**
Every `:theme` assertion in the threading tests compares `sections/2` output
(`refute Payslip.sections(data) == Payslip.sections(data, theme: …)`), which
builds `%Section{}` structs but never calls `render/2` or `measure_rows/4`. The
TYPE-02 raise-path tests render, but only for Invoice/Statement/Ticket with
ASCII sample data — never Payslip, and never with the non-ASCII data Payslip's
own D-14/D-17 features generate. That is precisely why CR-01 (a themed Payslip
render failure) passes CI. The teeth for "font role wiring is correct under a
theme" are missing.

**Fix:** Add a themed end-to-end render assertion for Payslip that includes a
masked `payment_method` (middot) and an accented `:description`, asserting
`{:ok, _} = Rendro.render(Payslip.document(data, theme: Rendro.Theme.default()))`.
Consider one themed render smoke test per recipe.

## Info

### IN-01: `no_inline_size_literals_test` proves absence of literals, not sourcing from the seam

**File:** `test/rendro/recipes/no_inline_size_literals_test.exs:78-102`

**Issue:**
The test asserts no inline numeric `size:` literal survives outside the
`typography/1` body. That has real teeth against re-introduced hardcoded numbers,
but it does not prove a size actually flows from `type.scale.<role>` — a builder
passing `size: some_local_var` unrelated to the seam would still pass. The
module's claim that "every recipe section builder MUST source its text sizes from
typography/1" is therefore only partially enforced. Acceptable for a completeness
proof; noted so the guarantee is not overstated.

### IN-02: Ticket's two mono micro-sizes bypass the seam, so TYPE-01 is not literally "every size through the seam"

**File:** `lib/rendro/recipes/ticket.ex:438-439`, `519-527`, `550-559`

**Issue:**
`@caption_size 7` and `@present_code_size 6` are read as `size: @caption_size` /
`size: @present_code_size` (variable reads, so the teeth test does not flag them,
by design). Consequently these two runs never scale with a theme's type scale —
they stay 7pt / 6pt under every theme. This is a documented Q3 decision (7 distinct
sizes cannot map onto 6 roles without a byte-changing collapse), and it is a
reasonable trade-off; flagged only so downstream readers know two ticket sizes are
intentionally exempt from the type-scale seam.

---

_Reviewed: 2026-07-28T15:11:51Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
