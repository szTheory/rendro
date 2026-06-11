defmodule Rendro.DocsContract.LaunchArtifactsClaimsTest do
  use ExUnit.Case, async: false

  @manifest_path "assets/rendro/artifacts.json"
  @readme_path "README.md"
  @recipes_path "guides/recipes.md"

  test "launch artifacts static contract is current" do
    assert Rendro.LaunchArtifacts.static_contract_errors() == []
  end

  test "manifest records exactly the five Phase 86 recipe previews" do
    manifest = Rendro.LaunchArtifacts.read_manifest!()

    assert Enum.map(manifest["gallery"], & &1["id"]) == [
             "invoice",
             "branded_invoice",
             "statement",
             "receipt_report",
             "certificate"
           ]
  end

  test "static contract catches manifest shape and hash drifts without pdfium" do
    manifest = Rendro.LaunchArtifacts.read_manifest!()

    pin_errors =
      manifest
      |> put_in(["renderer", "pin_sha256"], String.duplicate("0", 64))
      |> Rendro.LaunchArtifacts.static_contract_errors()

    alt_errors =
      manifest
      |> put_in(["gallery", Access.at(0), "alt"], "")
      |> Rendro.LaunchArtifacts.static_contract_errors()

    manual_errors =
      manifest
      |> put_in(["manual", "sha256"], String.duplicate("0", 64))
      |> Rendro.LaunchArtifacts.static_contract_errors()

    assert Enum.any?(pin_errors, &String.contains?(&1, "renderer.pin_sha256"))
    assert Enum.any?(alt_errors, &String.contains?(&1, "alt must be a non-empty string"))
    assert Enum.any?(manual_errors, &String.contains?(&1, "manual.pdf hash drift"))
  end

  test "README and recipes generated blocks match the manifest-backed generators" do
    manifest = Rendro.LaunchArtifacts.read_manifest!()
    readme = File.read!(@readme_path)
    recipes = File.read!(@recipes_path)

    assert extract_block(readme, Rendro.LaunchArtifacts.readme_markers()) ==
             Rendro.LaunchArtifacts.readme_block(manifest)

    assert extract_block(recipes, Rendro.LaunchArtifacts.recipes_markers()) ==
             Rendro.LaunchArtifacts.recipes_block(manifest)
  end

  test "README and recipes guide include accessible gallery images, hashes, and manual link" do
    manifest = Rendro.LaunchArtifacts.read_manifest!()
    readme = File.read!(@readme_path)
    recipes = File.read!(@recipes_path)

    for entry <- manifest["gallery"] do
      assert readme =~ entry["png_path"]
      assert recipes =~ entry["png_path"]
      assert readme =~ ~s|alt="#{entry["alt"]}"|
      assert recipes =~ ~s|alt="#{entry["alt"]}"|
      assert String.trim(entry["alt"]) != ""
      assert recipes =~ entry["source_pdf_sha256"]
      assert recipes =~ entry["png_sha256"]
    end

    for [_, href, src] <- Regex.scan(~r/<a href="([^"]+)"><img src="([^"]+)"/, readme) do
      assert href == src
    end

    assert readme =~ manifest["manual"]["path"]
    assert recipes =~ manifest["manual"]["path"]
    assert readme =~ manifest["manual"]["sha256"]
    assert recipes =~ manifest["manual"]["sha256"]
  end

  test "public copy keeps pdfium-render distinct from GUI-viewer proof" do
    manifest = Rendro.LaunchArtifacts.read_manifest!()

    generated_copy =
      Rendro.LaunchArtifacts.readme_block(manifest) <>
        "\n" <> Rendro.LaunchArtifacts.recipes_block(manifest)

    public_copy = File.read!(@readme_path) <> "\n" <> File.read!(@recipes_path)

    assert public_copy =~ "Native PDF layout for Elixir."
    assert generated_copy =~ "curated deterministic recipe fixtures"
    assert generated_copy =~ "Source PDFs and the self-rendered manual are byte-checked"
    assert generated_copy =~ "pinned pdfium-render advisory lane"
    assert generated_copy =~ "not GUI-viewer proof"
    assert generated_copy =~ "canonical recipe defaults remain unchanged"

    assert public_copy =~ "pdfium-render"

    forbidden_claims = [
      "is GUI-viewer proof",
      "are GUI-viewer proof",
      "works in every viewer",
      "PDF/A compliant",
      "PDF/UA compliant",
      "full HTML/CSS rendering",
      "browserless viewer",
      "prepress SDK",
      "pixel-perfect HTML-to-PDF",
      "launch gallery shows default recipe styling"
    ]

    for claim <- forbidden_claims do
      refute public_copy =~ claim
    end
  end

  test "docs verification script includes the launch artifacts lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Launch artifacts claims lane", ["test", "test/docs_contract/launch_artifacts_claims_test.exs"]}|
  end

  test "raster-advisory CI runs the full launch artifact check" do
    ci = File.read!(".github/workflows/ci.yml")
    assert ci =~ "mix rendro.launch_artifacts.check"
  end

  test "hex package includes public launch assets" do
    tarball = "rendro-#{Mix.Project.config()[:version]}.tar"
    File.rm(tarball)
    on_exit(fn -> File.rm(tarball) end)

    {output, 0} = System.cmd("mix", ["hex.build"], stderr_to_stdout: true)
    assert output =~ tarball
    assert File.exists?(tarball)

    list_cmd = "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"
    {contents, 0} = System.cmd("sh", ["-c", list_cmd], stderr_to_stdout: true)

    expected_assets = [
      @manifest_path,
      "assets/rendro/manual.pdf",
      "assets/rendro/gallery/invoice.png",
      "assets/rendro/gallery/branded_invoice.png",
      "assets/rendro/gallery/statement.png",
      "assets/rendro/gallery/receipt_report.png",
      "assets/rendro/gallery/certificate.png"
    ]

    for asset <- expected_assets do
      assert contents =~ asset
    end
  end

  defp extract_block(content, {start_marker, end_marker}) do
    pattern = ~r/#{Regex.escape(start_marker)}.*?#{Regex.escape(end_marker)}/s

    case Regex.run(pattern, content) do
      [block] -> String.trim(block)
      _ -> flunk("expected generated block #{start_marker} / #{end_marker}")
    end
  end
end
