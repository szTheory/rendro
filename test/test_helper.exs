ExUnit.start()

# Start the HexBuildCache agent to avoid redundant mix hex.build calls in tests (TEST-05)
Rendro.Test.HexBuildCache.start_link()

# D-01: ExUnit.configure test layering and exclusion strategy.
# - :quarantine tests are known flakes, isolated to a nightly verify.flake lane.
# - :live_pdf_tools, :live_signing, and :raster_snapshot are specialized tests excluded by default.
ExUnit.configure(exclude: [quarantine: true, live_pdf_tools: true, live_signing: true, raster_snapshot: true])

# Testing Strategy Documentation (TEST-05):
# - Partitioning Rejected (D-01): The use of `mix test --partitions N` is explicitly rejected in favor of
#   maximizing `async: true`. The multi-runner BEAM initialization overhead outweighs the benefits for this library.
# - Sequential Tests: Remaining `async: false` tests are kept sequential for valid architectural reasons
#   (e.g., modifying global `Application.put_env` for adapters).
# - Test Signal: Per Phase 108 audit, no low-signal tests were found for removal (TEST-04),
#   and tests are layered efficiently.

# Initialize the ETS-backed Threadline call recorder used by adapter tests.
Rendro.Test.Mocks.ensure_table!()

# Recompile optional adapters after Swoosh/Threadline/Mailglass stubs in
# test/support/mocks.ex have been defined so their `Code.ensure_loaded?/1`
# guards in lib/ re-evaluate against the test environment.
Rendro.Test.Mocks.AdapterReloader.recompile()

# The default suite intentionally runs under the DEFAULT shaper
# (Rendro.Text.Shaper.Simple) — the code path hex consumers actually receive
# on a clean install. Do NOT auto-activate the HarfBuzz adapter here via
# Code.ensure_loaded? (WR-03): that masks default-path regressions and turns
# determinism proofs into proofs about the optional NIF engine. Tests that
# need the HarfBuzz adapter must opt in explicitly — either by calling
# Rendro.Adapters.HarfBuzz directly (see test/rendro/adapters/harfbuzz_test.exs)
# or via the per-render `shaper:` option / a per-test Application.put_env in
# their own async: false setup.
