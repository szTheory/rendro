defmodule Rendro.PDF.ObjectTest do
  use ExUnit.Case, async: true

  alias Rendro.PDF.Object

  describe "serialize/1 primitives" do
    test "integer" do
      assert IO.iodata_to_binary(Object.serialize(42)) == "42"
      assert IO.iodata_to_binary(Object.serialize(0)) == "0"
      assert IO.iodata_to_binary(Object.serialize(-1)) == "-1"
    end

    test "float" do
      assert IO.iodata_to_binary(Object.serialize(3.14)) == "3.1400"
      assert IO.iodata_to_binary(Object.serialize(0.0)) == "0.0000"
    end

    test "boolean" do
      assert IO.iodata_to_binary(Object.serialize(true)) == "true"
      assert IO.iodata_to_binary(Object.serialize(false)) == "false"
    end

    test "null" do
      assert IO.iodata_to_binary(Object.serialize(nil)) == "null"
    end
  end

  describe "serialize/1 names" do
    test "simple name" do
      assert IO.iodata_to_binary(Object.serialize({:name, "Type"})) == "/Type"
    end

    test "multi-word name" do
      assert IO.iodata_to_binary(Object.serialize({:name, "BaseFont"})) == "/BaseFont"
    end
  end

  describe "serialize/1 strings" do
    test "literal string" do
      assert IO.iodata_to_binary(Object.serialize({:string, "Hello"})) == "(Hello)"
    end

    test "string with special characters" do
      result = IO.iodata_to_binary(Object.serialize({:string, "a(b)c\\d"}))
      assert result == "(a\\(b\\)c\\\\d)"
    end

    test "hex string" do
      result = IO.iodata_to_binary(Object.serialize({:hex_string, "AB"}))
      assert result == "<4142>"
    end
  end

  describe "serialize/1 references" do
    test "indirect reference" do
      assert IO.iodata_to_binary(Object.serialize({:ref, 3, 0})) == "3 0 R"
    end
  end

  describe "serialize/1 arrays" do
    test "array of integers" do
      result = IO.iodata_to_binary(Object.serialize({:array, [0, 0, 612, 792]}))
      assert result == "[0 0 612 792]"
    end

    test "empty array" do
      assert IO.iodata_to_binary(Object.serialize({:array, []})) == "[]"
    end

    test "array with mixed types" do
      arr = {:array, [1, {:name, "Type"}, {:string, "test"}]}
      result = IO.iodata_to_binary(Object.serialize(arr))
      assert result == "[1 /Type (test)]"
    end
  end

  describe "serialize/1 dictionaries" do
    test "simple dictionary" do
      dict = {:dict, [{"Type", {:name, "Catalog"}}]}
      result = IO.iodata_to_binary(Object.serialize(dict))
      assert result =~ "/Type /Catalog"
      assert result =~ "<<"
      assert result =~ ">>"
    end

    test "dictionary with multiple entries" do
      dict = {:dict, [{"Type", {:name, "Page"}}, {"Parent", {:ref, 2, 0}}]}
      result = IO.iodata_to_binary(Object.serialize(dict))
      assert result =~ "/Type /Page"
      assert result =~ "/Parent 2 0 R"
    end
  end

  describe "serialize/1 streams" do
    test "stream with data" do
      stream = {:stream, [], "BT /F1 12 Tf (Hello) Tj ET"}
      result = IO.iodata_to_binary(Object.serialize(stream))
      assert result =~ "/Length #{byte_size("BT /F1 12 Tf (Hello) Tj ET")}"
      assert result =~ "stream\n"
      assert result =~ "BT /F1 12 Tf (Hello) Tj ET"
      assert result =~ "\nendstream"
    end
  end

  describe "indirect_object/3" do
    test "wraps content in obj/endobj" do
      content = Object.serialize({:name, "Catalog"})
      result = IO.iodata_to_binary(Object.indirect_object(1, 0, content))
      assert result =~ "1 0 obj\n"
      assert result =~ "/Catalog"
      assert result =~ "\nendobj\n"
    end
  end
end
