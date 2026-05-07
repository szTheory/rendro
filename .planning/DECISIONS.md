# Architectural Decisions

- 2026-05-03 [v1.4]: Pure-Elixir Font Subsetting and Shaping — To avoid relying on external C bindings (like HarfBuzz) and ensure strict output determinism, Rendro will leverage or implement pure-Elixir font parsers and shapers for advanced typography.
- 2026-05-03 [v1.4]: Explicit Table Fragmentation — Tables will not use auto-sizing HTML/CSS models. Rendro will extend explicit constraints (`{:fixed, ...}` and `{:share, ...}`) to define exact cell fragmentation across pages to maintain the core deterministic DNA.\n- 2026-05-04 [v1.5]: Prioritize core layout/bulletproof validation over Hex.pm integrations — The user explicitly wants to ensure PDF generation is feature complete and robust before adopting or integrating with other ecosystem libraries.
- 2026-05-05 [Phase 45]: Generate AcroForms with pre-filled fields (no external parsing) — sticks strictly to our deterministic generation mandate.
- 2026-05-05 [Phase 45]: Introduce explicit Rendro.form_field DSL block — separates form field logic (Widget, AP) from pure text layout.
- 2026-05-05 [Phase 45]: Rendro generates Appearance Streams (AP) for form fields — setting NeedAppearances delegates rendering to viewers and breaks our deterministic layout rule.
- 2026-05-05 [Phase 45]: AcroForm foundation + Text fields only — limits scope to high-complexity AP generation first, deferring other field types.
- 2026-05-05 [Phase 45]: Restrict Default Appearance (DA) to Standard 14 fonts — avoids file bloat and custom font editing complexity in Acrobat.
