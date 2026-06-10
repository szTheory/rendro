ExUnit.start()
ExUnit.configure(exclude: [live_pdf_tools: true, live_signing: true])

# Initialize the ETS-backed Threadline call recorder used by adapter tests.
Rendro.Test.Mocks.ensure_table!()

# Recompile optional adapters after Swoosh/Threadline/Mailglass stubs in
# test/support/mocks.ex have been defined so their `Code.ensure_loaded?/1`
# guards in lib/ re-evaluate against the test environment.
Rendro.Test.Mocks.AdapterReloader.recompile()

# Configure the HarfBuzz shaper for the test environment when harfbuzz_ex is available.
# Tests that use embedded fonts require a shaping adapter; Shaper.Simple only handles
# built-in fonts. Production callers set: config :rendro, shaper: Rendro.Adapters.HarfBuzz
# HarfBuzz delegates built-in font calls to Shaper.Simple, so all tests remain correct.
if Code.ensure_loaded?(HarfbuzzEx) and Code.ensure_loaded?(Rendro.Adapters.HarfBuzz) do
  Application.put_env(:rendro, :shaper, Rendro.Adapters.HarfBuzz)
end
