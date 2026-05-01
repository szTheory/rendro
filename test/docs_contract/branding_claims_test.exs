defmodule Rendro.DocsContract.BrandingClaimsTest do
  use ExUnit.Case, async: false

  describe "NOTICE file (D-13)" do
    test "exists at top level" do
      assert File.exists?("NOTICE")
    end

    test "contains verbatim SIL OFL attribution substrings" do
      content = File.read!("NOTICE")
      assert content =~ "SIL OPEN FONT LICENSE Version 1.1"
      assert content =~ "Copyright 2012 The B612 Project Authors"
      assert content =~ "http://scripts.sil.org/OFL"
    end
  end

  describe "shipped brand assets" do
    test "B612-Regular.ttf is exactly 153_192 bytes" do
      path = "priv/branded/fonts/B612-Regular.ttf"
      assert File.exists?(path)
      assert byte_size(File.read!(path)) == 153_192
    end

    test "rendro-logo.png exists and is under 2_000 bytes" do
      path = "priv/branded/images/rendro-logo.png"
      assert File.exists?(path)
      assert byte_size(File.read!(path)) < 2_000
    end
  end

  describe "README pointer and docs metadata" do
    test "README.md contains the Branded Documents pointer" do
      assert File.read!("README.md") =~ "Branded Documents"
    end

    test "mix.exs includes guides/branding.md in docs extras" do
      assert File.read!("mix.exs") =~ "\"guides/branding.md\""
    end
  end

  describe "hex tarball contents" do
    test "built tarball includes branded assets and NOTICE" do
      tarball = "rendro-#{Mix.Project.config()[:version]}.tar"
      File.rm(tarball)

      {output, 0} = System.cmd("mix", ["hex.build"], stderr_to_stdout: true)
      assert output =~ tarball
      assert File.exists?(tarball)

      list_cmd = "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"
      {contents, 0} = System.cmd("sh", ["-c", list_cmd], stderr_to_stdout: true)

      assert contents =~ "priv/branded/fonts/B612-Regular.ttf"
      assert contents =~ "priv/branded/images/rendro-logo.png"
      assert contents =~ "NOTICE"
    end
  end

  describe "missing-asset diagnostics" do
    test "render returns a structural Rendro.Error for an unregistered asset" do
      template = Rendro.Recipes.BrandedInvoice.page_template()

      doc =
        Rendro.Document.new()
        |> Rendro.Document.add_template(template)
        |> Rendro.Document.set_template(template.name)
        |> Rendro.Document.add_section(
          Rendro.section(
            name: :missing_logo,
            region: :logo,
            content: [Rendro.Component.image(:missing_logo, fit: {64, 64})]
          )
        )

      assert {:error, %Rendro.Error{stage: :measure, reason: {:missing_asset, :missing_logo}}} =
               Rendro.render(doc)
    end
  end
end
