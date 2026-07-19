defmodule Rendro.DocsContract.ExamplesSchemaContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @schema_path "priv/schemas/examples.schema.json"

  defp examples_schema do
    @schema_path
    |> File.read!()
    |> JSON.decode!()
    |> JSV.build!()
  end

  test "at least one example fixture exists under priv/examples/" do
    assert Path.wildcard("priv/examples/**/*.json") != [],
           "expected at least one fixture under priv/examples/**/*.json; found none " <>
             "(guards against the validation loop silently passing over zero files)"
  end

  test "every fixture under priv/examples/ validates against examples.schema.json" do
    schema = examples_schema()

    for path <- Path.wildcard("priv/examples/**/*.json") do
      fixture = path |> File.read!() |> JSON.decode!()
      assert {:ok, _} = JSV.validate(fixture, schema), "#{path} failed schema validation"
    end
  end

  describe "hex tarball contents" do
    test "priv/examples/ ships in the built tarball and every entry is text-only" do
      tarball = "rendro-#{Mix.Project.config()[:version]}.tar"

      {output, 0} = Rendro.Test.HexBuildCache.get_build_output()
      assert output =~ tarball
      assert File.exists?(tarball)

      list_cmd = "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"
      {contents, 0} = System.cmd("sh", ["-c", list_cmd], stderr_to_stdout: true)

      shipped =
        contents
        |> String.split("\n", trim: true)
        |> Enum.filter(&String.starts_with?(&1, "priv/examples/"))

      assert shipped != [],
             "expected priv/examples/ entries in the shipped tarball; found none"

      for path <- shipped do
        assert Path.extname(path) in [".json", ".md", ".svg"],
               "#{path} shipped in the Hex tarball but is not text-only (.json/.md/.svg)"
      end
    end
  end
end
