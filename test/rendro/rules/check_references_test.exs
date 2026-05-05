defmodule Rendro.Rules.CheckReferencesTest do
  use ExUnit.Case, async: true

  alias Rendro.Rules.CheckReferences
  alias Rendro.{Document, Image, Text, AssetRegistry}

  setup do
    doc = Document.new()
    doc = Document.register_font(doc, :helvetica, built_in: :helvetica)
    # create a basic binary image mock
    registry =
      AssetRegistry.register_image(
        doc.asset_registry,
        :logo,
        {:binary,
         <<137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1,
           8, 2, 0, 0, 0, 144, 119, 83, 222, 0, 0, 0, 12, 73, 68, 65, 84, 8, 215, 99, 248, 255,
           255, 63, 0, 5, 254, 2, 254, 220, 204, 89, 231, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96,
           130>>}
      )

    doc = %{doc | asset_registry: registry}

    {:ok, doc: doc}
  end

  test "returns :ok for valid image references", %{doc: doc} do
    image = %Image{logical_name: :logo}
    assert :ok = CheckReferences.check(image, doc)
  end

  test "returns error for missing image references", %{doc: doc} do
    image = %Image{logical_name: :missing_logo}
    assert {:error, {:missing_image_reference, :missing_logo}} = CheckReferences.check(image, doc)
  end

  test "returns :ok for valid text font references", %{doc: doc} do
    text = %Text{content: "Hello", font: :helvetica}
    assert :ok = CheckReferences.check(text, doc)
  end

  test "returns error for missing text font references", %{doc: doc} do
    text = %Text{content: "Hello", font: :comic_sans}
    assert {:error, {:missing_font_reference, :comic_sans}} = CheckReferences.check(text, doc)
  end

  test "ignores unknown structs", %{doc: doc} do
    assert :ok = CheckReferences.check(%Rendro.Page{}, doc)
  end
end
