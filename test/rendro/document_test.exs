defmodule Rendro.DocumentTest do
  use ExUnit.Case, async: true

  alias Rendro.{Document, Metadata, Page}

  describe "struct construction" do
    test "creates with defaults" do
      doc = %Document{}
      assert doc.pages == []
      assert doc.metadata == %Metadata{}
      assert doc.options == %{}
    end

    test "creates with all fields" do
      page = %Page{}
      meta = %Metadata{title: "Test"}

      doc = %Document{
        pages: [page],
        metadata: meta,
        options: %{deterministic: true}
      }

      assert doc.pages == [page]
      assert doc.metadata.title == "Test"
      assert doc.options.deterministic == true
    end

    test "rejects unknown keys" do
      assert_raise KeyError, fn ->
        struct!(Document, bogus: true)
      end
    end
  end
end
