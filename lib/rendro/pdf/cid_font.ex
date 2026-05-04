defmodule Rendro.PDF.CidFont do
  @moduledoc """
  Generates PDF dictionaries for CID-keyed (Type0 / Identity-H) fonts.
  """

  alias Rendro.PDF.{Font, Object}

  @doc """
  Builds the list of indirect objects required for a CID font.
  Takes the font, pre-allocated object numbers, and serialization options.
  """
  def build_objects(
        %Font{embedded?: true, subtype: :truetype} = font,
        %{
          font_obj_num: type0_obj_num,
          cid_font_obj_num: cid_font_obj_num,
          descriptor_obj_num: descriptor_obj_num,
          widths_obj_num: widths_obj_num,
          font_file_obj_num: font_file_obj_num
        },
        opts
      ) do
    # Type0 Font Dictionary
    type0_dict =
      {:dict,
       [
         {"Type", {:name, "Font"}},
         {"Subtype", {:name, "Type0"}},
         {"BaseFont", {:name, font.base_font}},
         {"Encoding", {:name, "Identity-H"}},
         {"DescendantFonts", {:array, [{:ref, cid_font_obj_num, 0}]}}
       ]}

    type0_obj =
      {type0_obj_num,
       Object.indirect_object(type0_obj_num, 0, Object.serialize(type0_dict, opts))}

    # CIDFontType2 Dictionary
    cid_font_dict =
      {:dict,
       [
         {"Type", {:name, "Font"}},
         {"Subtype", {:name, "CIDFontType2"}},
         {"BaseFont", {:name, font.base_font}},
         {"CIDSystemInfo",
          {:dict,
           [
             {"Registry", {:string, "Adobe"}},
             {"Ordering", {:string, "Identity"}},
             {"Supplement", 0}
           ]}},
         {"FontDescriptor", {:ref, descriptor_obj_num, 0}},
         {"W", {:ref, widths_obj_num, 0}}
       ]}

    cid_font_obj =
      {cid_font_obj_num,
       Object.indirect_object(cid_font_obj_num, 0, Object.serialize(cid_font_dict, opts))}

    # FontDescriptor Dictionary
    descriptor_dict =
      {:dict,
       [
         {"Type", {:name, "FontDescriptor"}},
         {"FontName", {:name, font.base_font}},
         {"Flags", 32},
         {"FontBBox",
          {:array,
           [
             0,
             scale_metric(font.descent, font.units_per_em),
             1000,
             scale_metric(font.ascent, font.units_per_em)
           ]}},
         {"Ascent", scale_metric(font.ascent, font.units_per_em)},
         {"Descent", scale_metric(font.descent, font.units_per_em)},
         {"CapHeight", scale_metric(font.ascent, font.units_per_em)},
         {"ItalicAngle", 0},
         {"StemV", 80},
         {"FontFile2", {:ref, font_file_obj_num, 0}}
       ]}

    descriptor_obj =
      {descriptor_obj_num,
       Object.indirect_object(descriptor_obj_num, 0, Object.serialize(descriptor_dict, opts))}

    # Widths Array
    widths = build_widths_array(font)

    widths_obj =
      {widths_obj_num,
       Object.indirect_object(widths_obj_num, 0, Object.serialize({:array, widths}, opts))}

    # FontFile Stream
    font_file_stream =
      {:stream,
       [
         {"Subtype", {:name, "OpenType"}},
         {"Length1", byte_size(font.font_bytes)}
       ], font.font_bytes}

    font_file_obj =
      {font_file_obj_num,
       Object.indirect_object(font_file_obj_num, 0, Object.serialize(font_file_stream, opts))}

    [type0_obj, cid_font_obj, descriptor_obj, widths_obj, font_file_obj]
  end

  defp build_widths_array(%Font{} = font) do
    # The /W array can be [ c [ w1 w2 ... ] ]
    # We will just generate [ 0 [ w0 w1 w2 ... ] ] up to the max encoded glyph

    max_glyph =
      if map_size(font.widths) > 0 do
        font.widths |> Map.keys() |> Enum.max()
      else
        0
      end

    widths =
      0..max_glyph
      |> Enum.map(fn gid ->
        Map.get(font.widths, gid, font.default_width) |> scale_metric(font.units_per_em)
      end)

    [0, {:array, widths}]
  end

  defp scale_metric(metric, units_per_em) do
    round(metric * 1000 / units_per_em)
  end
end
