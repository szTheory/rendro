defmodule Rendro.DocsContract.ComparisonClaimsTest do
  use ExUnit.Case, async: false

  @guide_path "guides/comparison.md"
  @livebook_path "guides/livebook/first_invoice.livemd"
  @manifest_path "bench/results/comparison.json"
  @readme_path "README.md"
  @required_sections [
    "The Short Version",
    "Choose By Job",
    "Measured Operational Tradeoffs",
    "Where HTML/CSS Renderers Still Win",
    "Text, Fonts, and Complex Scripts",
    "Reproduce These Numbers",
    "Try Rendro In Livebook"
  ]
  @choose_sentences [
    "Choose ChromicPDF when your source of truth is already HTML/CSS or browser CSS fidelity is the requirement.",
    "Choose Typst when your team wants Typst templates and its layout language is already part of your workflow.",
    "Choose Rendro when your PDF is authored from Elixir data and you want deterministic layout, pagination, telemetry, and no browser runtime."
  ]
  @limitation_sentences [
    "Rendro does not render arbitrary HTML/CSS.",
    "Complex-script and RTL support are bounded by priv/support_matrix.json.",
    "Unsupported shaping cases fail explicitly instead of producing silent broken output."
  ]
  @comparative_phrases [
    "faster",
    "smaller",
    "lower RSS",
    "fewer dependencies",
    "lighter",
    "no Chrome runtime"
  ]
  @banned_phrases [
    "bloated",
    "kills Chrome",
    "replaces every PDF tool",
    "pixel-perfect HTML-to-PDF",
    "works everywhere"
  ]

  test "comparison static contract is current" do
    assert Rendro.Comparison.static_contract_errors() == []
  end

  test "manifest records the required comparator ids" do
    manifest = Rendro.Comparison.read_manifest!()
    ids = Enum.map(manifest["comparators"], & &1["id"])

    for id <- ~w(rendro chromic_pdf chromic_pdf_warm_pool pdf_generator typst_cli) do
      assert id in ids
    end
  end

  test "guide generated blocks match the manifest-backed generators" do
    manifest = Rendro.Comparison.read_manifest!()
    guide = File.read!(@guide_path)

    assert extract_block(guide, Rendro.Comparison.fit_markers()) ==
             Rendro.Comparison.fit_block(manifest)

    assert extract_block(guide, Rendro.Comparison.results_markers()) ==
             Rendro.Comparison.results_block(manifest)

    assert extract_block(guide, Rendro.Comparison.evidence_markers()) ==
             Rendro.Comparison.evidence_block(manifest)
  end

  test "public claim ids are unique and resolve to guide citations" do
    manifest = Rendro.Comparison.read_manifest!()
    public_claims = Enum.filter(manifest["claims"], &(Map.get(&1, "public", true) != false))
    public_ids = Enum.map(public_claims, & &1["id"])

    assert public_ids == Enum.uniq(public_ids)

    guide = File.read!(@guide_path)
    citations = Regex.scan(~r/\[bench:(CMP-[A-Z0-9-]+)\]/, guide, capture: :all_but_first)
    cited_ids = citations |> List.flatten() |> Enum.uniq()

    for id <- cited_ids do
      assert id in public_ids
    end

    for id <- public_ids do
      assert guide =~ "[bench:#{id}]"
    end
  end

  test "guide has required title, sections, fit sentences, and limitation copy" do
    guide = File.read!(@guide_path)

    assert guide =~ "# Generating PDFs in Elixir without Chrome"

    section_positions =
      Enum.map(@required_sections, fn section ->
        {section, :binary.match(guide, "## #{section}")}
      end)

    for {section, match} <- section_positions do
      assert match != :nomatch, "missing required section #{section}"
    end

    positions = Enum.map(section_positions, fn {_section, {position, _length}} -> position end)
    assert positions == Enum.sort(positions)

    for sentence <- @choose_sentences do
      assert guide =~ sentence
    end

    for sentence <- @limitation_sentences do
      assert guide =~ sentence
    end
  end

  test "comparison guide has no uncited comparative or banned phrases" do
    guide = File.read!(@guide_path)

    guide
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.each(fn {line, number} ->
      for phrase <- @comparative_phrases do
        if contains_phrase?(line, phrase) do
          assert line =~ ~r/\[bench:CMP-[A-Z0-9-]+\]/,
                 "line #{number} has uncited comparative phrase #{inspect(phrase)}"
        end
      end

      for phrase <- @banned_phrases do
        refute contains_phrase?(line, phrase),
               "line #{number} contains banned comparison phrase #{inspect(phrase)}"
      end
    end)
  end

  test "docs verification script includes exactly one comparison claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert length(Regex.scan(~r/\{"Comparison claims lane"/, script)) == 1

    assert script =~
             ~r/\{"Comparison claims lane",\s*\["test",\s*"test\/docs_contract\/comparison_claims_test\.exs"\]\}/s
  end

  test "ExDoc registers comparison guide and Livebook tutorial as evaluation extras" do
    docs = Rendro.MixProject.project() |> Keyword.fetch!(:docs)
    extras = Keyword.fetch!(docs, :extras)
    groups = Keyword.fetch!(docs, :groups_for_extras)

    assert @guide_path in extras
    assert @livebook_path in extras

    assert Keyword.fetch!(groups, :Evaluation) == [
             @guide_path,
             @livebook_path
           ]
  end

  test "README Guides section links to comparison guide and Livebook tutorial" do
    guides_section = readme_guides_section()

    assert guides_section =~ @guide_path
    assert guides_section =~ @livebook_path
    assert guides_section =~ "Generating PDFs in Elixir without Chrome"
    assert guides_section =~ "First Invoice Livebook"
  end

  test "hex package includes comparison guide, notebook, manifest, and raw artifacts" do
    tarball = "rendro-#{Mix.Project.config()[:version]}.tar"
    File.rm(tarball)
    on_exit(fn -> File.rm(tarball) end)

    {output, 0} = System.cmd("mix", ["hex.build"], stderr_to_stdout: true)
    assert output =~ tarball
    assert File.exists?(tarball)

    list_cmd = "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"
    {contents, 0} = System.cmd("sh", ["-c", list_cmd], stderr_to_stdout: true)

    expected_paths =
      [
        @guide_path,
        @livebook_path,
        @manifest_path
      ] ++ manifest_raw_artifacts()

    for path <- expected_paths do
      assert contents =~ path
    end
  end

  defp extract_block(content, {start_marker, end_marker}) do
    pattern = ~r/#{Regex.escape(start_marker)}.*?#{Regex.escape(end_marker)}/s

    case Regex.run(pattern, content) do
      [block] -> String.trim(block)
      _ -> flunk("expected generated block #{start_marker} / #{end_marker}")
    end
  end

  defp contains_phrase?(line, phrase) do
    line
    |> String.downcase()
    |> String.contains?(String.downcase(phrase))
  end

  defp manifest_raw_artifacts do
    Rendro.Comparison.read_manifest!()
    |> Map.fetch!("results")
    |> Enum.map(&Map.fetch!(&1, "raw_artifact"))
    |> Enum.uniq()
  end

  defp readme_guides_section do
    readme = File.read!(@readme_path)

    pattern = ~r/## Guides\n(?<section>.*?)\n## Getting Started with the Builder API/s

    case Regex.named_captures(pattern, readme) do
      %{"section" => section} -> section
      _ -> flunk("expected README Guides section before Builder API section")
    end
  end
end
