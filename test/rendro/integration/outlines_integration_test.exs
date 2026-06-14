defmodule Rendro.OutlinesIntegrationTest do
  use ExUnit.Case, async: true

  test "0-human verification: E2E outlines are accurately harvested and serialized into the PDF binary" do
    doc = Rendro.document(
      pages: [
        Rendro.page(
          blocks: [
            Rendro.block(Rendro.text("English text"), x: 72, y: 72, outline: "Non-Latin ページ", outline_level: 1)
          ]
        ),
        Rendro.page(
          blocks: [
            Rendro.block(Rendro.text("Child Node"), x: 72, y: 72, outline: "Custom Child Title", outline_level: 2)
          ]
        )
      ]
    )

    assert {:ok, pdf} = Rendro.render(doc)

    # 1. Structural Verification: /Outlines in Catalog
    assert pdf =~ "/Type /Catalog"
    assert pdf =~ "/Outlines"
    assert pdf =~ "/Type /Outlines"

    # 2. Hierarchy Verification: /First, /Last, /Parent
    assert pdf =~ "/First"
    assert pdf =~ "/Last"
    assert pdf =~ "/Parent"

    # 3. UTF-16BE encoding Verification:
    bom = <<0xFE, 0xFF>>
    expected_hex_title1 = Base.encode16(bom <> :unicode.characters_to_binary("Non-Latin ページ", :utf8, {:utf16, :big}))
    assert pdf =~ "/Title <#{expected_hex_title1}>"

    expected_hex_title2 = Base.encode16(bom <> :unicode.characters_to_binary("Custom Child Title", :utf8, {:utf16, :big}))
    assert pdf =~ "/Title <#{expected_hex_title2}>"

    # 4. Destination Mapping Verification
    # Assert destination structures are mapped (e.g. /Dest [ 4 0 R /XYZ 72 72 null ])
    assert pdf =~ "/Dest ["
    assert pdf =~ "/XYZ"
  end
end
