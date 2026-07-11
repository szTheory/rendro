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
end
