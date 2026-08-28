# Compile Rendro.EdgeMatrixTest so stress_fixture_ids/0 is available even when this
# file runs in isolation (`mix test test/docs_contract/rubric_manifest_contract_test.exs`).
# `.exs` test files outside test/support/ are not on elixirc_paths(:test), so without
# this require the module would be undefined. Mirrors test/scripts/release_preflight_proof_test.exs:1.
Code.require_file("test/rendro/edge_matrix_test.exs", File.cwd!())

defmodule Rendro.DocsContract.RubricManifestContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @manifest_path "priv/quality/rubric_scores.json"
  @schema_path "priv/schemas/rubric_scores.schema.json"
  @gallery_manifest_path "assets/rendro/artifacts.json"
  @non_prose_fixture_path "test/fixtures/quality/rubric_scores_phase130_non_prose.json"
  @sign_off_path "priv/quality/SIGN-OFF.md"
  @justification_keys ~w(information_architecture content_hierarchy domain_fit reader_affordances typographic_craft restraint_cohesion)
  @phase130_expected_gzip_base64 "H4sIAAAAAAAC/+2cW2/lyHHHvwohBMiLuGTf2N3xk50NFgmQxIn9EgSBti/VEj085FmSZ7THwX73VDXPTdLhzEi7zszaAwPjI5Jd" <>
                                   "XX371Z/Vzf3v/70JbnbdcH/Xxpt/uGn790MboCwDRDeWm928cx3+NYzbYXQzlKFz09SGsuza+4f55vYmuU3b7c9F8ZIfXU/GLm3g" <>
                                   "5e0IE8x0/bk1vLkZIuCto1V430boA9yNkPAyPgXzVI3Qx3GoDh5Xhxqry3qql65mm99s+3vyob+/mx4cVw1ZdQ2XSnMZkzdBO5VS" <>
                                   "I2KIMclaCFXL1EgjwViBT9raeB6ZtTFY5oVIJqK9adiN6OU2prPZ2kYWhY3SWsZT5DHQ47VTCpTyQdhahMQF1tSAcR6aBlgTQh09" <>
                                   "k0Y4gWZHwGZEiHeO+ovXvClrU/I633rfwuPdNLt5N+HNCZ8EciW2G+indujv8iW8h2M79DP0891DC6MbwwOOk8Inh41r+7vUonF5" <>
                                   "iwOXhnHjZipKD7UzhHk3Qr45gosw3rmEz0SHIzIdLk/ziEbmuzA8ANWaL8/77XA/uu1DG+7C6BJV8NPtzT0OB47ktOvm7NZ2pJKT" <>
                                   "SzCjR/O4g6WiFkeH2j0uF7HklkY+Hp+Z2vseO2VI6c7TlPsXrPbJ1Zfd9afdNLepDbl5ufL15t6007SD8TSvfNt15TzcFvjIZrot" <>
                                   "3GbY9XPRuYgu4p99LOIOioitK8hmAT9u0RbEYh62ZRwe++J+HHbb6Rt05MpQ3PgOi/9xwNlcfIu/2qnY9e0PO+j2WMl4j338tBKc" <>
                                   "FhBhKtrNBmKLV/BBD93wSBVcjupxMRb9buOxRVT62JxqhnEzVT/M+wrHAZs57fxMPlSz+7FaflGNboQCnX6PTmNXue6bm+uz4abD" <>
                                   "OdxN2dPN0MMeS3W7TY9XcOX1SwtgCmO7JUPFI86PqcD5Sw/2M/oMkWxfmTt0DYopuA6yGWwNoMvFjH7MONvno5NTO1HnFo/t/FD0" <>
                                   "QxG6drvF2YRDl3s9NwA7a9thdUtDXs7fG3S+cCFku1jbtHXjROY322Fqs+8Hrx9gPD60dXtypExD2E3UkJ+yceyBPMEWfBmu6lo1" <>
                                   "qQ7Jc2gsMJYaA8pL1XCbouFOA/eMJvNuC1grdtjdX4aBP92+Gfl4+90vTvyD0V+ysWTyGu+1MykqqVN03ggmvYgq1JY7xwXzLFgh" <>
                                   "BY/R+1poljQzdTD4b9MEg0D3fIX3qnZSMeW0d0JqW9dOQNBGRmui5xhWjEFLNUtMYEVBqIjxAWormkYGwOZ+6bwX19eLuLpmxUd5" <>
                                   "n1w3fRT4h4f+0sSf3AYOkEa6UjchgtEf7O4eZ0kHa+g+U3spNhXzA2BZt/Ht/W7YTRgRkFuHmPGCz2nXdcUR0q5387DZnyzlZbMU" <>
                                   "ugrcf8ZwVP0H8vv3xG+EGtZ2GbMW3B+xXhz5jKjEUFFSa0ZHoeWeapsL37nwbiEe3ifc9j0OzBqTNziq7RaJjOsPYpWtY8DrMS65" <>
                                   "7XYcXHjIfeHRKvXsgv8tdjrB2IV5iQubUwuvkLhz+2E3V0cYP4W8383Y0YCBqTi15RHcO1wNxdHGl8rhE5peYJgWOORQUtL0RgR3" <>
                                   "EO9hLMtN27cb/BuD63BFd58KXnD4iYVLEF/aeqPqPtVXPamleuLmquZWHLvfoIJ2vrFWKMls0jWqZRGjjAp47ThzUXoFQkOKumY1" <>
                                   "B0D9HISpmV5hsLapSSB4o6zgDLGrZKNr7z3KeRu9sDxEui8YV2CNrVVsYuJgfXJSevvlMFi9SnOrX73mxjVOhKxwubVDrIYtEHyq" <>
                                   "0KHmwv9fJhfCtCM2EVdonPrQdm02hwIMJR/pPgRGZg72UXh34Nc1ch8s47Md9e0T1Y2j1PYOGYNxgOoiTJePbcQqPK6sFxjfuOkd" <>
                                   "yv1DG26LpRG3R9v4zrB0FCpW10/IPuqQ5c1h3GXKntz4ZLmd6YkmH/LNqVoizHRQoyRMaXL8GZ+gXomje8RQWiDPEEUzORI+BHdc" <>
                                   "vE8iVzbrh7gvTo/vF187cP1vci+RQiau597+cT7FMXL/GEOvYt7hREEpjX3RwVRRDx+6gZ54v2h+5Py4L6DLyDk2Y3o2C1Zwn5yJ" <>
                                   "tQvOiBrBogOTsTEBUnDJNQpqXjdSBvcG3L8Sgm+m/XPJ/QvA/jWC+5OauSa3GxGtVBL/ENJDXScvfaNUkrXRVmG0VcoklMXIXxO5" <>
                                   "aXSDj+hGa+20MEytoD7UAFa6JIPXyTlmgaR3gwU4DiqivwaZsGbpLKsZBOsCNFLpxteBcxu/yu3PJ7cPoCznoTxwj34eGI9N3uUH" <>
                                   "TwD5NCn+HOjn0s+o/gLfp+n9QoIT0jqYYZXC35LE/vac1qh+m3FZ/e7gxMPS3QuWp2EDJzrmfwhzPaBSPKvkW6w87gjOWYIfUbcu" <>
                                   "wynRdDRKtSwB4ayJqY737dR67IJFL6+C+LCerwzBM919Mt72pzthT28sFLimHDA/JsI/M5XXJTil13A0y3I7bLf7Evu0vKeuKsuH" <>
                                   "3cb12Ngr8vtQ6ILHz0pfEvlo543S+1BX9ayG6uTequw2yExTG6cihxgtcMutZID49Y0IlH4W0hhnWJO0wwFAmkKIKmhXO42IXWGx" <>
                                   "lbWrbUiSCy1w+GopNNcKK2qAQe2jkanRIuoAFulsmWAhuWBS0pY56b942a3+WmX3BvBvZOKSK8gJ7sqNKBg3MLdhSQMXWPTwMr8d" <>
                                   "sBnlkMqJcrHEpw8nRtolH4JLH4rYTlt8oS+XPC4O/0sQv/Sm/XN2+2lyeutayq1TBVkn4mxAui15cVwXR4qvQvsoVC8y1iOtmPKo" <>
                                   "qU9aGpX6+5yGRzNYY25MrngNx6i46XXlEcheNW2zyl5LT7vHd49uRF2NXr6bVqlMlf6wawELunGT30AqksoFBg5Ec4uOYseGRSfn" <>
                                   "7u7a7YX6XkyuJaWjVqC5T4ozVQtmhNOIBykM97QJZkLiqJiSfgOHX8GpN0H4uSr+mQx+jSL+aNPW1LCVgglpvbS1CR4ECONVI21K" <>
                                   "gblGB+G99Zw3LARvk6HfYHWD+Gy8kS6sEFg2jEepYm1j0pF54xyWjjEmbkwIBv+HPFcmmhQjjmZSDEc2xjo2TDMHf2sE/uKSz0cm" <>
                                   "XWQIiglQuB5yE6e9vk8H7vL+fhW0z0hJxT4qdR1KuosNvFPG4SJeLMlluM80zq/xC1CX/ACOwDAWtDDO+jEC9lI7kwNHjToC8n38" <>
                                   "5M3AJzr350H2jMrFy2k3Yu/BAtt2OiUkvjyQrovZAONhJkJZ0rYpTqK+dOM8lQkomTY9tNuyxLk1D2NLO34vpO2FiQu0rtm6ZOzJ" <>
                                   "6huF7kXN1Vp91dn1VdkroxcNkyaiSlUsCVM3PIBLHlSNSjfUtZQxNFYo5hQw03hKHQRnDdhYN80KdAWiEwsxoZy1PjVCGZEallDW" <>
                                   "8mB8oymzbALOcdZIVNHKRYnzwDbIeg3af802fy7Zi93eblt6QyTxSLlWlJaU3jzsmdFrI06q/XKewxW0/wQjvWjjv/j62NJL8oHO" <>
                                   "a0D+pw56V/zrMCKpJsLH4SzHbXGuM6dPR4TeRHlMfPcnyKImPZ3xeEHuDlcfwg8R6OYZaHJQpMjZhZPT1MOFm8jvozS+WEm3BSXJ" <>
                                   "7x+QvV3rYVzOjxzejdc187EHpj1GohlrOeVg3YWlyw4iO6s6GVdzKk7dtWxeHmPghCEwJ5svBuIZ3TP5KfW8CvR76GGkDdhHGnhS" <>
                                   "4ku8OPlPFilPsf+oRNa1dMp4pqUGHhN4pAbqtyCxn6zkUguN77XyLamKNxPuFwD9c/n8i3L+NWL6lZ2wJq2DAYEIriFZEVTg2jNu" <>
                                   "HA6Us15pawFqfDAxwPhcO4wGvrEcDFdBCh0VX000uyAM1DWXRumguPEeUEQLLURSUafoPZfRAXhtFRjGao9BwUXOkmmE/Fuj/Jck" <>
                                   "rb9y/ivnf42cX9fzW7en9E5Z9jgmDx02psR72FttmMpyemyn6YqEP5S6wPqV4pdEz4beqNoPlVVXqqgWB1eFegjOaWaCtE44G4iy" <>
                                   "yVoufCNYHbwMnCtpmHdNZLVQwkiLPLd1pOMjHswKwp0xHpjWJiUIGAk4WmRSq6ZhqPi9aaL0xgttNMN3AhO0sIJbr/F9wOK7Afxa" <>
                                   "9wrlG/cKP0Wo/z8RHDbbbtjDWB1+wPGESA9ziTOtmmlPkObgk+MgC0ZGvDrjws8n+5aMwjWC/5245Up8o+rjeY9/g7n4vdvnVOvV" <>
                                   "gyEvcH3FTSxPQWaqKE1Le4BVpI29JXcSdiMd0aj+64/fVujdNFF7Pv3wB47kBhtU/OPZTPHedTs4nL+ms3klLb1jjjsf6Xt+WOI6" <>
                                   "sv99S4QnLxHQGMv2t8V/DjtC/vAe79xTIgc27W5zW/xhCBQA2n7ajeQaPglzOy57qTkx0/oM2OWsy+Gw5KkX8hnwY4Km2/+mcPFP" <>
                                   "bjnqd0zAY4fMGRareZvTGfD2Mtd9Cn55emDgwnU4X2xQzsP2I/uTAlTtTNPUMkSDbKmjbfCa0JIFFqR33kFwLL0hGLwGkG8LAM+l" <>
                                   "/c/l/2vU/Mdbt3owG6QNCpV70txLHWoWYw3WpMbb2mIUFlpz12D3Ry8YQ7lfC+x1bq02ghm5Qv8kfLDGNl5KyxxPljWGvvkBDU4n" <>
                                   "730SgIvMWvzNlEysqRlWoUALz9GDL57+/K/3pMhX/F/fwKQva86HSzy2fvPiJAkpYmRf3g/IWwxL0KiIuhQ8FjQe9glvaZcXSHxi" <>
                                   "O9sNpeCPR1A+dAp8Ofa9fMtDvfX8QPbhMP2S24cPZt+3+P40zznRnjV99uTZuZMnB9cX/8PDSG3/tJPfnxXq66IeH3qH87l0uxFf" <>
                                   "I5H+76Es/bjDR66fNlkKXOD8ouQlxk823ijll3qqC+vV2a1VFR+1QlHtVUjOB94EbwUSXaJejy6gzEYpr1NQKNoZpMAapZzkxjdO" <>
                                   "oRBnul5LxIiIyj/xKLgxTAnpHOVeJAOwAi2x2OjoQTRSp9rIIDlnQTUeKc+ETfariv98GCem3S7HFDb5J846+nqOvjucd37Rh/mL" <>
                                   "xEzBSAunD/P5U8oPf0FJynQ57Hyq4gBrJDAqyPmwWXiq9SXByUOc7xtE99FENYHbVGdPF//OWRf81aFm3eDipqCzLJZVaB+2QDeo" <>
                                   "qIs/wLLDmzV78f13v/3+wFAcv6GYYOtykuX7776vvsd7hJPpdLwDYwxK2e9yFiYHgnw6JrcxC+qs9V1Bk+N0ROfqRiraegf7iy6b" <>
                                   "B2To309P90zPonk74Lp/oMhBW7DZzAeJ/kA2aPM0j3H1uyM5kO/Dkps5hIfjp5TXoe2t5olZmejMmrBcQcQVHeqQVBKIb3xzp6PA" <>
                                   "/g3Q/kS+vRrYz/X3z+D1a6T3B5uzej7bonSOmlvTRFEHqI2VRiYjfO0tF1YHRfucgNRuQhMV9wacTD4BaxoLa5ujrgFKzkitoxU4" <>
                                   "OqwJzrNaquiQz0EKAUwq65gLInAQIsRg61obFSQOp/uqur/i+nPj+gRmSln7DOF8rOSJDF0yLC/qRY4vMrpI9NRugjUOH4JCmemb" <>
                                   "q9vmQ4M5kZP/MwLnr2k+9ST3M8JO56/VSUYvX+scj3BvjifmsVk4Lh+R0J+Lxmf1/D//Bxo/W+GuRAAA"

  defp phase130_expected_records do
    @phase130_expected_gzip_base64
    |> Base.decode64!()
    |> :zlib.gunzip()
    |> JSON.decode!()
  end

  defp manifest do
    @manifest_path
    |> File.read!()
    |> JSON.decode!()
  end

  defp gallery_png_paths do
    @gallery_manifest_path
    |> File.read!()
    |> JSON.decode!()
    |> Map.fetch!("gallery")
    |> MapSet.new(& &1["png_path"])
  end

  defp rubric_schema do
    @schema_path
    |> File.read!()
    |> JSON.decode!()
    |> JSV.build!()
  end

  defp non_prose_fixture do
    @non_prose_fixture_path
    |> File.read!()
    |> JSON.decode!()
  end

  defp replace_catalog_disposition(dispositions, replacement) do
    Enum.map(dispositions, fn disposition ->
      if disposition["catalog_id"] == replacement["catalog_id"],
        do: replacement,
        else: disposition
    end)
  end

  defp mutate_scored_record(record, {:delete, field}), do: Map.delete(record, field)
  defp mutate_scored_record(record, {:blank, field}), do: Map.put(record, field, "")
  defp mutate_scored_record(record, {:date, value}), do: Map.put(record, "signed_off_at", value)

  defp mutate_scored_record(record, {:delete_justification, key}) do
    update_in(record, ["justifications"], &Map.delete(&1, key))
  end

  defp mutate_scored_record(record, {:blank_justification, key}) do
    put_in(record, ["justifications", key], "")
  end

  defp mutate_scored_record(record, :extra_justification) do
    put_in(record, ["justifications", "unsupported_dimension"], "Not approved.")
  end

  defp scored_evidence_mutations do
    Enum.map(
      ~w(signed_off_by signed_off_at resolution_ref supersedes_evidence_ref justifications),
      &{:delete, &1}
    ) ++
      Enum.map(
        ~w(signed_off_by signed_off_at resolution_ref supersedes_evidence_ref),
        &{:blank, &1}
      ) ++
      [{:date, "not-a-date"}, {:date, "2026-02-30"}] ++
      Enum.map(@justification_keys, &{:delete_justification, &1}) ++
      Enum.map(@justification_keys, &{:blank_justification, &1}) ++ [:extra_justification]
  end

  # Test-only pass/fail helper. Mirrors Rendro.Comparison's accumulator style but is
  # scoped entirely to this test file — per Phase 114's "no `lib/` product change
  # except the loader" boundary, the threshold arithmetic lives nowhere in `lib/`.
  #
  # Returns true only when the hierarchy dimension is exactly 5, every other core
  # dimension is >= 4, and every gate result is true.
  defp passed?(dimension_scores, gate_results) do
    hierarchy_ok? = dimension_scores["content_hierarchy"] == 5

    other_cores_ok? =
      dimension_scores
      |> Map.delete("content_hierarchy")
      |> Map.values()
      |> Enum.all?(&(&1 >= 4))

    gates_ok? = gate_results |> Map.values() |> Enum.all?(&(&1 == true))

    hierarchy_ok? and other_cores_ok? and gates_ok?
  end

  test "schema validation: checked-in manifest validates against rubric_scores.schema.json" do
    assert {:ok, _} = JSV.validate(manifest(), rubric_schema()),
           "#{@manifest_path} failed validation against #{@schema_path}"
  end

  test "schema rejects incomplete scored evidence for both passing and failed Phase 130 rows" do
    m = manifest()

    for passed <- [true, false] do
      record =
        Enum.find(
          m["catalog_dispositions"],
          &(&1["review_status"] == "scored" and &1["passed"] == passed)
        )

      for mutation <- scored_evidence_mutations() do
        mutated_record = mutate_scored_record(record, mutation)

        mutated =
          put_in(
            m,
            ["catalog_dispositions"],
            replace_catalog_disposition(m["catalog_dispositions"], mutated_record)
          )

        refute match?({:ok, _}, JSV.validate(mutated, rubric_schema())),
               "#{record["catalog_id"]}: #{inspect(mutation)} must fail schema validation"
      end
    end
  end

  test "the independent pre-fix snapshot preserves every non-prose manifest value" do
    stripped =
      manifest()
      |> update_in(["catalog_dispositions"], fn dispositions ->
        Enum.map(dispositions, fn
          %{"review_status" => "scored"} = disposition ->
            Map.delete(disposition, "justifications")

          disposition ->
            disposition
        end)
      end)

    assert stripped == non_prose_fixture()
  end

  test "structural enumeration: 6 dimensions, 2 gates, hierarchy/core thresholds" do
    m = manifest()

    assert length(m["dimensions"]) == 6
    assert length(m["gates"]) == 2
    assert m["thresholds"]["hierarchy_min"] == 5
    assert m["thresholds"]["core_min"] >= 4
  end

  test "catalog dispositions are additive while the six legacy rubric records remain intact" do
    m = manifest()

    assert length(m["scores"]) == 6,
           "catalog review records must not replace or rewrite the six legacy gallery scores"

    assert Enum.map(m["scores"], & &1["demo_id"]) == [
             "invoice-acme-phoenix-saas",
             "statement-northwind-ledger-co",
             "receipt-harbor-and-oak-cafe",
             "certificate-summit-training-institute",
             "payslip-aurora-live",
             "ticket-aurora-live"
           ]

    assert length(m["catalog_dispositions"]) == 32
    assert Enum.count(m["catalog_dispositions"], &(&1["review_status"] == "scored")) == 12
    assert Enum.count(m["catalog_dispositions"], &(&1["review_status"] == "unscored")) == 20
  end

  test "catalog dispositions recompute from frozen thresholds before projection generation" do
    dispositions = manifest()["catalog_dispositions"]

    for disposition <- dispositions, disposition["review_status"] == "scored" do
      assert disposition["passed"] ==
               passed?(disposition["dimension_scores"], disposition["gate_results"])

      if disposition["passed"] do
        assert is_binary(disposition["supersedes_evidence_ref"])
        assert is_binary(disposition["resolution_ref"])
      end
    end
  end

  test "Phase 130 literally pins all twelve reviewed catalog records and current sign-off evidence" do
    scored = Enum.filter(manifest()["catalog_dispositions"], &(&1["review_status"] == "scored"))
    assert scored == phase130_expected_records()

    assert Enum.map(scored, & &1["catalog_id"]) ==
             Enum.map(phase130_expected_records(), & &1["catalog_id"])

    assert Enum.count(scored, & &1["passed"]) == 4
    assert Enum.count(scored, &(not &1["passed"])) == 8

    sign_off = File.read!(@sign_off_path)
    {current_heading, _} = :binary.match(sign_off, "## Phase 130 catalog review")
    {historical_heading, _} = :binary.match(sign_off, "## Phase 127 catalog flagship review")
    assert current_heading < historical_heading

    {_, last_row_offset} = {nil, current_heading}

    Enum.reduce(phase130_expected_records(), last_row_offset, fn record, prior_offset ->
      scores =
        ~w(information_architecture content_hierarchy domain_fit reader_affordances typographic_craft restraint_cohesion)
        |> Enum.map_join("/", &Integer.to_string(record["dimension_scores"][&1]))

      gates =
        "#{record["gate_results"]["reading_order"]}/#{record["gate_results"]["print_safety"]}; " <>
          if(record["passed"], do: "pass", else: "needs_work")

      expected_row =
        "| `#{record["catalog_id"]}` | `#{record["png_sha256"]}` | `#{record["source_pdf_sha256"]}` | #{scores} | #{gates} |"

      {offset, _} = :binary.match(sign_off, expected_row)

      assert offset > prior_offset,
             "Phase 130 SIGN-OFF rows must retain canonical light-then-dark order"

      offset
    end)

    for expected <- [
          "1646eeb8875cc67d7d452d3f28bc2b0d6503f943a2a6775f7e256a3e51bb3f22",
          "411cdcafa5d3090f3d0ec144c0cba59d991ba99f",
          "30657d92cf8be49f30094c57aaf163b76bd0ad9c",
          "gsd/phase130-candidate-route-411cdcafa5d3090f3d0ec144c0cba59d991ba99f",
          "32417257428",
          "attempt `1`",
          "job `candidate-evidence`",
          "advisory job `96581121473`",
          "adapter `pdfium-render`, executable `pdfium-cli v0.11.0`",
          "b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a",
          "passed = content_hierarchy == 5 AND every other dimension >= 4 AND reading_order == true AND print_safety == true",
          "Four light rows pass; eight rows remain `needs_work`.",
          "Every dark row is screen-oriented and non-print-safe because `print_safety: false`",
          "Statement endpoints close at `$7,500`",
          "Supplied Invoice endpoints show lines 1–40 and 42–65",
          "line 41 is neither asserted nor denied",
          "deterministic-test evidence only",
          "historical; superseded by Phase 130 above"
        ] do
      assert sign_off =~ expected
    end
  end

  test "threshold-arithmetic correctness, not the subjective score" do
    # Synthetic (not real) inputs — the near-miss cases below can't be expressed by the
    # real all-passing demo data, so this proves the arithmetic itself rejects each
    # failure mode independent of any demo's subjective rating. The companion test
    # "recorded `passed` matches recomputation ..." applies the same rule to the real
    # scores[] entries.
    all_pass_scores = %{
      "information_architecture" => 5,
      "content_hierarchy" => 5,
      "domain_fit" => 5,
      "reader_affordances" => 5,
      "typographic_craft" => 5,
      "restraint_cohesion" => 5
    }

    all_pass_gates = %{"reading_order" => true, "print_safety" => true}

    assert passed?(all_pass_scores, all_pass_gates),
           "an all-5s / all-true synthetic input must pass"

    # Near-miss 1: hierarchy = 4 (fails the hierarchy=5 rule)
    refute passed?(%{all_pass_scores | "content_hierarchy" => 4}, all_pass_gates),
           "content_hierarchy below 5 must fail even when every other core is 5"

    # Near-miss 2: one other core dimension = 3 (fails core>=4)
    refute passed?(%{all_pass_scores | "typographic_craft" => 3}, all_pass_gates),
           "a core dimension below 4 must fail"

    # Near-miss 3: one gate = false (fails gates-pass)
    refute passed?(all_pass_scores, %{all_pass_gates | "print_safety" => false}),
           "a failing gate must fail regardless of dimension scores"
  end

  test "recorded `passed` matches recomputation from each entry's own dimensions/gates" do
    # Regression guard for SHOW-01's original failure mode: a manifest entry recorded
    # `passed: true` that did NOT satisfy the passed?/2 arithmetic. This recomputes the
    # verdict from each entry's own dimension_scores/gate_results and asserts it equals
    # the recorded `passed`, so the field can never again be asserted independently.
    scores = manifest()["scores"]

    assert scores != [],
           "manifest scores[] must not be empty once demos are recorded — an empty " <>
             "array would make this tripwire pass vacuously"

    for entry <- scores do
      recomputed = passed?(entry["dimension_scores"], entry["gate_results"])

      assert entry["passed"] == recomputed,
             "demo #{entry["demo_id"]}: recorded passed=#{inspect(entry["passed"])} " <>
               "but recomputation from its own dimension_scores/gate_results yields " <>
               "#{inspect(recomputed)} — the manifest's passed field must equal the " <>
               "passed?/2 arithmetic, never an independent assertion (SHOW-01 honesty gate)"
    end
  end

  test "every passed:true entry carries a live, hash-checked human sign-off (DEFAULT-02 honesty gate)" do
    # D-02 machine-enforced sign-off teeth: a `passed: true` verdict may never be recorded
    # without provenance. This is the load-bearing guard (schema if/then is the secondary
    # layer) — it must fail loud in BOTH directions: a passed:true without a live
    # hash-checked evidence_ref fails the build; a passed:false must never be blocked by
    # this loop (an honest failing finding, e.g. Ticket, must still pass the contract test).
    scores = manifest()["scores"]
    known_png_paths = gallery_png_paths()

    for entry <- scores do
      if entry["passed"] == true do
        signed_off_by = entry["signed_off_by"]
        signed_off_at = entry["signed_off_at"]
        evidence_ref = entry["evidence_ref"]

        assert is_binary(signed_off_by) and signed_off_by != "",
               "demo #{entry["demo_id"]}: passed:true requires a non-empty signed_off_by"

        assert is_binary(signed_off_at) and signed_off_at != "",
               "demo #{entry["demo_id"]}: passed:true requires a non-empty signed_off_at"

        assert is_binary(evidence_ref) and evidence_ref != "",
               "demo #{entry["demo_id"]}: passed:true requires a non-empty evidence_ref"

        assert File.exists?(evidence_ref),
               "demo #{entry["demo_id"]}: evidence_ref #{inspect(evidence_ref)} does not " <>
                 "exist on disk — a passed:true verdict must point at a real artifact"

        assert MapSet.member?(known_png_paths, evidence_ref),
               "demo #{entry["demo_id"]}: evidence_ref #{inspect(evidence_ref)} is not " <>
                 "present in the hash-checked #{@gallery_manifest_path} gallery — a " <>
                 "passed:true verdict must point at a manifest-covered, hash-verified " <>
                 "raster, not an untracked file"
      end
    end
  end

  # --- D-15 fail-loud-in-both-directions stress-exemption guards ------------

  test "D-15i: stress_exemption is present, exempt, and carries a non-empty reason" do
    exemption = manifest()["stress_exemption"]

    assert exemption["exempt"] == true,
           "stress_exemption.exempt must be true"

    assert is_binary(exemption["reason"]) and exemption["reason"] != "",
           "stress_exemption.reason must be a non-empty string"
  end

  test "D-15ii: no scores entry may set stress_exempt to dodge the beauty gate" do
    refute Enum.any?(manifest()["scores"], &Map.get(&1, "stress_exempt", false)),
           "the per-entry stress_exempt field is a loophole tripwire — no real demo " <>
             "score may set it true to bypass the reader-quality rubric"
  end

  test "D-15iii: stress-fixture ID set is disjoint from the scores array's demo_ids" do
    stress_ids = Rendro.EdgeMatrixTest.stress_fixture_ids()
    score_ids = MapSet.new(Enum.map(manifest()["scores"], & &1["demo_id"]))

    assert MapSet.disjoint?(stress_ids, score_ids),
           "stress-matrix fixture IDs must never collide with curated demo demo_ids; " <>
             "overlap: #{inspect(MapSet.intersection(stress_ids, score_ids))}"
  end

  test "D-15iv teeth guard: the stress-fixture ID set is non-empty (62 cells)" do
    assert MapSet.size(Rendro.EdgeMatrixTest.stress_fixture_ids()) == 62,
           "disjointness must not pass vacuously — the imported stress-fixture set " <>
             "must be the full 62 :applies cells"
  end

  test "Phase 136 canonical eligibility fails closed for unavailable review evidence without changing canonical artifacts" do
    catalog = JSON.decode!(File.read!("assets/rendro/catalog.json"))
    sign_off = File.read!(@sign_off_path)

    assert {:canonical_ineligible,
            [
              "missing validated closed review bundle for d547bbfa60760d43f19a15372d88a2d159bfa327",
              "missing six complete named reviewer records",
              "next action: publish the exact candidate object to a remote-reachable ref, dispatch review, validate the closed bundle, then collect six records"
            ]} = phase136_canonical_eligibility(manifest(), catalog, sign_off)

    assert Enum.count(catalog["cells"], &(&1["quality"]["status"] == "unscored")) == 20

    for cell <- catalog["cells"], String.ends_with?(cell["id"], "--dark") do
      assert cell["print_safety"] == false
    end
  end
end
