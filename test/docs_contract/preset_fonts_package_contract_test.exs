defmodule Rendro.DocsContract.PresetFontsPackageContractTest do
  use ExUnit.Case, async: false

  @font_paths [
    "priv/fonts/inter/Inter-Regular.ttf",
    "priv/fonts/source-sans-3/SourceSans3-Regular.ttf",
    "priv/fonts/source-serif-4/SourceSerif4-Regular.ttf",
    "priv/fonts/jetbrains-mono/JetBrainsMono-Regular.ttf"
  ]

  test "built Hex archive includes all curated faces and NOTICE" do
    tarball = Rendro.Test.HexBuildCache.tarball_path!()
    {output, 0} = Rendro.Test.HexBuildCache.get_build_output()
    assert output =~ Path.basename(tarball)
    assert File.exists?(tarball)

    {contents, 0} = System.cmd("sh", ["-c", "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"])

    for path <- @font_paths do
      assert path in String.split(contents, "\n", trim: true), "expected #{path} in Hex archive"
    end

    assert "NOTICE" in String.split(contents, "\n", trim: true)
  end
end
