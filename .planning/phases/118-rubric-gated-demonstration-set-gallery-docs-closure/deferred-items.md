# Deferred Items — Phase 118

Out-of-scope discoveries logged during execution (not fixed in the discovering plan).

- **[118-03] Statement recipe lacks a unicode fallback font.** The Statement recipe builds `Rendro.Document.new()` (built-in Helvetica, ASCII-only) with no opts injection point, so realistic typographic glyphs (em-dash `—`, middle-dot account masking `····`) abort rendering with `{:unsupported_glyph}`. Payslip solved the same problem in 116-02 via `with_unicode_fallback_font/1` (B612) + `glyph_safe/1` (·→•). 118-03 worked around it by ASCII-ifying the statement fixture. **Realism-maximizing upgrade (future plan):** give Statement the same B612 fallback + middle-dot glyph_safe treatment, then restore the en/em-dash + middle-dot masking in `priv/examples/statement/northwind-ledger-co/statement.json`. No statement byte-goldens currently exist, so the font change is low-risk.
