defmodule Rendro.CrossReferencesIntegrationTest do
  use ExUnit.Case, async: true

  test "0-human verification: PDF anchor link annotations point to valid XYZ destinations" do
    doc = Rendro.document(
      pages: [
        Rendro.page(
          blocks: [
            Rendro.block(
              %Rendro.Link{
                target: {:anchor, "target_id"},
                content: Rendro.text("Click to jump")
              },
              x: 72, y: 72, width: 100, height: 20
            )
          ]
        ),
        Rendro.page(
          blocks: [
            Rendro.block(Rendro.text("Target Section"), x: 144, y: 288, id: "target_id")
          ]
        )
      ]
    )

    assert {:ok, pdf} = Rendro.render(doc)

    # 1. Structural Verification: /Link annotation exists
    assert pdf =~ "/Subtype /Link"
    assert pdf =~ "/Type /Annot"

    # 2. Border is explicitly removed ([0 0 0]) to prevent ugly blue boxes by default
    assert pdf =~ "/Border [0 0 0]"

    # 3. Destination mapping Verification
    # Assert destination structures are mapped (e.g. /Dest [ 4 0 R /XYZ 144 288 null ])
    assert pdf =~ "/Dest ["
    assert pdf =~ "/XYZ 144 288 null"
  end
end