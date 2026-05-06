ExUnit.start()
ExUnit.configure(exclude: [live_pdf_tools: true])

# Initialize the ETS-backed Threadline call recorder used by adapter tests.
Rendro.Test.Mocks.ensure_table!()

# Recompile optional adapters after Swoosh/Threadline/Mailglass stubs in
# test/support/mocks.ex have been defined so their `Code.ensure_loaded?/1`
# guards in lib/ re-evaluate against the test environment.
Rendro.Test.Mocks.AdapterReloader.recompile()
