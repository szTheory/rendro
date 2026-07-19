defmodule Rendro.ExamplesTest do
  use ExUnit.Case, async: true

  describe "load!/1" do
    test "returns a decoded map for the acme-phoenix-saas invoice fixture" do
      fixture = Rendro.Examples.load!("invoice/acme-phoenix-saas/invoice.json")
      assert is_map(fixture)
      assert fixture["fixture_id"] == "invoice_v1"
    end

    test "raises ArgumentError on a path-traversal attempt before reading the file" do
      assert_raise ArgumentError, fn ->
        Rendro.Examples.load!("../../../etc/passwd")
      end
    end
  end

  describe "list/1" do
    test "returns a non-empty list of absolute .json paths including the acme fixture" do
      paths = Rendro.Examples.list("invoice")
      assert is_list(paths)
      assert paths != []
      assert Enum.all?(paths, &(Path.extname(&1) == ".json"))
      assert Enum.all?(paths, &(Path.type(&1) == :absolute))
      assert Enum.any?(paths, &String.ends_with?(&1, "invoice/acme-phoenix-saas/invoice.json"))
    end

    test "raises ArgumentError on a domain traversal attempt before wildcarding" do
      assert_raise ArgumentError, fn ->
        Rendro.Examples.list("../../etc")
      end
    end
  end

  describe "priv/examples extension ban (EXL-05, in-repo half)" do
    test "every file under priv/examples has a text extension (.json/.md/.svg)" do
      allowed = [".json", ".md", ".svg"]

      offenders =
        "priv/examples/**/*"
        |> Path.wildcard()
        |> Enum.filter(&File.regular?/1)
        |> Enum.reject(&(Path.extname(&1) in allowed))

      assert offenders == [],
             "Found non-text (potentially raster/binary) files under priv/examples/: " <>
               inspect(offenders)
    end
  end
end
