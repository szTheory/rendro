defmodule Rendro.PDF.CidFontTest do
  use ExUnit.Case, async: true

  alias Rendro.PDF.{CidFont, Font}

  test "CID widths follow emitted glyph IDs rather than Unicode codepoints" do
    font =
      Font.embedded(
        name: "F1",
        logical_name: :curated,
        base_font: "Curated",
        source_kind: :binary,
        font_bytes: "ttf",
        units_per_em: 1000,
        ascent: 800,
        descent: -200,
        default_width: 500,
        widths: %{65 => 500},
        glyph_widths: %{0 => 500, 7 => 750},
        cmap: %{65 => 7}
      )

    objects =
      CidFont.build_objects(
        font,
        %{
          font_obj_num: 1,
          cid_font_obj_num: 2,
          descriptor_obj_num: 3,
          widths_obj_num: 4,
          font_file_obj_num: 5
        },
        deterministic: true
      )

    widths_object = objects |> Enum.at(3) |> elem(1) |> IO.iodata_to_binary()

    assert widths_object =~ "4 0 obj\n[0 [500 500 500 500 500 500 500 750]]"
  end
end
