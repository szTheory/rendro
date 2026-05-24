# Phase 27: Architecture Decisions

Based on deep ecosystem research and the goal of providing explicit, honest typography support boundaries (Phase 27), here is the cohesive set of architectural recommendations:

## 1. Font Fallback Chains: Hybrid Registry-First Approach
**Decision:** Define fallback chains at the `FontRegistry` level, mapping a single logical name to a prioritized list of physical fonts (e.g., `FontRegistry.register_fallback(registry, :body, [:helvetica, :noto_cjk])`). Text nodes continue to reference the logical name (e.g., `%Text{font: :body}`).
**Rationale:** This mirrors the declarative idiomatic config seen in Tailwind and CSS. It keeps the document authoring layer pristine and DRY. Explicit inline overrides (e.g., `%Text{font: [:helvetica, :noto_cjk]}`) can be optionally supported in the future if needed, but registry-level chains provide the cleanest baseline DX.

## 2. Diagnostics: Dedicated Validation Stage
**Decision:** Introduce a new `validate_content` or `validate_text` pipeline stage *before* `measure`. This stage traverses all text nodes, resolves their font chains, and inspects the characters.
**Rationale:** Emitting `{:error, :unsupported_glyph}` during layout measurement creates a frustrating "whack-a-mole" debugging loop and pollutes hot-path math. A dedicated pre-layout pass acts like an Ecto changeset validation: it holistically gathers all missing glyphs and unsupported scripts at once, providing the user with a comprehensive error report while keeping the layout engine pure and fast.

## 3. RTL / Complex Script Detection: Standard Library PCRE
**Decision:** Utilize Elixir's built-in Unicode regex support (e.g., `String.match?(text, ~r/\p{Arabic}|\p{Hebrew}|\p{Devanagari}/u)`) within the new Validation stage to reject unsupported scripts.
**Rationale:** While adding a pure-Elixir `unicode` dependency is an option, Erlang's native PCRE engine already supports script properties out of the box with zero additional dependencies. This perfectly aligns with Elixir library idioms: it avoids dependency bloat, fails fast, and stays honest about our current lack of HarfBuzz/complex shaping support without complicating the build tree.

---
**Next Steps:** Proceed to `gsd-plan-phase` using these established decisions.