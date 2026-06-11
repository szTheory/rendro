ExUnit.start()
ExUnit.configure(exclude: [live_pdf_tools: true, live_signing: true, raster_snapshot: true])

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
