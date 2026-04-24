defmodule Rendro.Pipeline.BuildTest do
  use ExUnit.Case, async: true

  alias Rendro.Pipeline.Build

  describe "run/1" do
    test "returns {:ok, document} for a valid document" do
      doc = %Rendro.Document{
        pages: [%Rendro.Page{blocks: []}],
        metadata: %Rendro.Metadata{}
      }

      assert {:ok, ^doc} = Build.run(doc)
    end

    test "normalizes nil metadata to default Metadata struct" do
      doc = %Rendro.Document{
        pages: [%Rendro.Page{blocks: []}],
        metadata: nil
      }

      assert {:ok, result} = Build.run(doc)
      assert %Rendro.Metadata{} = result.metadata
    end

    test "returns error for empty pages" do
      doc = %Rendro.Document{pages: [], metadata: %Rendro.Metadata{}}
      assert {:error, :no_pages} = Build.run(doc)
    end

    test "returns error for invalid page dimensions (zero width)" do
      page = %Rendro.Page{blocks: [], width: 0, height: 100}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}
      assert {:error, :invalid_page_dimensions} = Build.run(doc)
    end

    test "returns error for negative dimensions" do
      page = %Rendro.Page{blocks: [], width: 100, height: -50}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}
      assert {:error, :invalid_page_dimensions} = Build.run(doc)
    end

    test "returns error for non-document input" do
      assert {:error, :invalid_document} = Build.run(%{})
    end

    test "validates all pages, not just the first" do
      good_page = %Rendro.Page{blocks: [], width: 612, height: 792}
      bad_page = %Rendro.Page{blocks: [], width: -1, height: 792}

      doc = %Rendro.Document{
        pages: [good_page, bad_page],
        metadata: %Rendro.Metadata{}
      }

      assert {:error, :invalid_page_dimensions} = Build.run(doc)
    end
  end
end
