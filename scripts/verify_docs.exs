# verify_docs.exs
# Runs the explicit docs-contract lanes for README doctests, curated integration
# examples, and semantic claim regressions.

Mix.Task.run("app.start")

lanes = [
  {"README doctest lane", ["test", "test/docs_contract/readme_doctest_test.exs"]},
  {"Integration contract lane", ["test", "test/docs_contract/integrations_contract_test.exs"]},
  {"Integration semantic-claims lane", ["test", "test/docs_contract/integrations_claims_test.exs"]},
  {"Forms semantic-claims lane", ["test", "test/docs_contract/forms_claims_test.exs"]}
]

Mix.shell().info("Running explicit docs-contract lanes...")

results =
  Enum.map(lanes, fn {label, args} ->
    Mix.shell().info("  - #{label}")

    {output, status} = System.cmd("mix", args, stderr_to_stdout: true)

    if status == 0 do
      Mix.shell().info("    PASS")
    else
      Mix.shell().error(output)
      Mix.shell().error("    FAIL")
    end

    {label, status}
  end)

if Enum.all?(results, fn {_label, status} -> status == 0 end) do
  Mix.shell().info("Docs contract VERIFIED!")
else
  System.halt(1)
end
