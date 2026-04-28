# Deferred Items

## 2026-04-28

- `mix ci` now truthfully runs `format --check-formatted` and fails on pre-existing formatting drift outside Plan `12-03` scope:
  - `test/rendro/adapters/phoenix_test.exs`
  - `lib/rendro/adapters/mailglass.ex`
  - `lib/rendro/adapters/threadline.ex`
  - `lib/rendro/recipes.ex`
  - `test/rendro/policy_test.exs`
