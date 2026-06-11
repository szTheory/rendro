# verify_docs.exs
# Runs the explicit docs-contract lanes for README doctests, curated integration
# examples, and semantic claim regressions.

Mix.Task.run("app.start")

# formatter: off
lanes = [
  {"README doctest lane", ["test", "test/docs_contract/readme_doctest_test.exs"]},
  {"Integration contract lane", ["test", "test/docs_contract/integrations_contract_test.exs"]},
  {"Integration semantic-claims lane",
   ["test", "test/docs_contract/integrations_claims_test.exs"]},
  {"Forms semantic-claims lane", ["test", "test/docs_contract/forms_claims_test.exs"]},
  {"Signing semantic-claims lane", ["test", "test/docs_contract/signing_claims_test.exs"]},
  {"Embedded artifact semantic-claims lane",
   ["test", "test/docs_contract/embedded_artifact_claims_test.exs"]},
  {"Protection semantic-claims lane", ["test", "test/docs_contract/protection_claims_test.exs"]},
  {"Viewer evidence semantic-claims lane",
   ["test", "test/docs_contract/viewer_evidence_claims_test.exs"]},
  {"Recipes semantic-claims lane", ["test", "test/docs_contract/recipes_claims_test.exs"]},
  {"Page-primitive semantic-claims lane",
   ["test", "test/docs_contract/page_primitive_claims_test.exs"]},
  {"Public API contract lane", ["test", "test/docs_contract/public_api_contract_test.exs"]},
  {"API stability claims lane", ["test", "test/docs_contract/api_stability_claims_test.exs"]},
  {"Script support claims lane", ["test", "test/docs_contract/script_support_claims_test.exs"]},
  {"Path claims lane", ["test", "test/docs_contract/path_claims_test.exs"]},
  {"Raster claims lane", ["test", "test/docs_contract/raster_claims_test.exs"]},
  {"Launch artifacts claims lane",
   ["test", "test/docs_contract/launch_artifacts_claims_test.exs"]}
]

# formatter: on

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
