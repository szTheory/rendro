defmodule Rendro.PDF.Writer do
  @moduledoc """
  Serializes a `Rendro.Document` into a valid PDF 1.4 binary.

  Builds the complete PDF structure: header, indirect object body,
  cross-reference table, and trailer with catalog root. Each page
  gets a content stream with Tf/Td/Tj text operators for its blocks.
  """

  alias Rendro.PDF.{Font, Object}

  @pdf_header "%PDF-1.4\n%\xE2\xE3\xCF\xD3\n"

  @spec render(Rendro.Document.t()) :: {:ok, binary()}
  def render(%Rendro.Document{} = doc) do
    font = Font.helvetica()
    {numbered_objects, catalog_num, info_num, total_objects} = build_objects(doc, font)
    pdf = assemble({numbered_objects, catalog_num, info_num, total_objects}, catalog_num)
    {:ok, IO.iodata_to_binary(pdf)}
  end

  defp build_objects(%Rendro.Document{pages: pages, metadata: metadata}, font) do
    obj_num = 1
    catalog_num = obj_num

    {page_obj_nums, font_obj_num, next_num} = allocate_page_nums(pages, obj_num + 1, font)
    pages_num = next_num
    next_num = next_num + 1

    info_num = next_num
    next_num = next_num + 1

    font_dict =
      {:dict, [{"Type", {:name, "Font"}}, {"Subtype", {:name, "Type1"}}, {"BaseFont", {:name, font.base_font}}]}

    font_obj = Object.indirect_object(font_obj_num, 0, Object.serialize(font_dict))

    page_tree_kids = {:array, Enum.map(page_obj_nums, fn {page_num, _} -> {:ref, page_num, 0} end)}

    pages_dict =
      {:dict,
       [
         {"Type", {:name, "Pages"}},
         {"Kids", page_tree_kids},
         {"Count", length(pages)}
       ]}

    pages_obj = Object.indirect_object(pages_num, 0, Object.serialize(pages_dict))

    catalog_dict =
      {:dict,
       [
         {"Type", {:name, "Catalog"}},
         {"Pages", {:ref, pages_num, 0}}
       ]}

    catalog_obj = Object.indirect_object(catalog_num, 0, Object.serialize(catalog_dict))

    page_objects = build_page_objects(pages, page_obj_nums, pages_num, font_obj_num, font)

    info_dict = build_info_dict(metadata)
    info_obj = Object.indirect_object(info_num, 0, Object.serialize(info_dict))

    total_objects = next_num
    objects = [catalog_obj, font_obj, pages_obj | page_objects] ++ [info_obj]

    {Enum.zip(
       [catalog_num, font_obj_num, pages_num] ++
         Enum.flat_map(page_obj_nums, fn {p, c} -> [p, c] end) ++
         [info_num],
       objects
     ), catalog_num, info_num, total_objects}
  end

  defp allocate_page_nums(pages, start_num, _font) do
    {page_nums, next} =
      Enum.reduce(pages, {[], start_num}, fn _page, {acc, num} ->
        page_num = num
        content_num = num + 1
        {acc ++ [{page_num, content_num}], num + 2}
      end)

    font_obj_num = next
    {page_nums, font_obj_num, next + 1}
  end

  defp build_page_objects(pages, page_obj_nums, pages_num, font_obj_num, font) do
    Enum.zip(pages, page_obj_nums)
    |> Enum.flat_map(fn {page, {page_num, content_num}} ->
      content_data = build_content_stream(page, font)

      content_stream =
        {:stream, [], content_data}

      content_obj = Object.indirect_object(content_num, 0, Object.serialize(content_stream))

      resources =
        {:dict,
         [
           {"Font",
            {:dict,
             [
               {font.name, {:ref, font_obj_num, 0}}
             ]}}
         ]}

      media_box =
        {:array, [0, 0, page.width, page.height]}

      page_dict =
        {:dict,
         [
           {"Type", {:name, "Page"}},
           {"Parent", {:ref, pages_num, 0}},
           {"MediaBox", media_box},
           {"Contents", {:ref, content_num, 0}},
           {"Resources", resources}
         ]}

      page_obj = Object.indirect_object(page_num, 0, Object.serialize(page_dict))

      [page_obj, content_obj]
    end)
  end

  defp build_content_stream(%Rendro.Page{} = page, font) do
    page.blocks
    |> Enum.map(fn block -> render_block(block, page, font) end)
    |> Enum.join("\n")
  end

  defp render_block(%Rendro.Block{content: %Rendro.Text{} = text} = block, page, _font) do
    x = block.x + page.margin_left
    y = page.height - block.y - page.margin_top - text.size

    {r, g, b} = text.color
    color_op = "#{format_num(r / 255)} #{format_num(g / 255)} #{format_num(b / 255)} rg"

    [
      "BT",
      color_op,
      "/F1 #{format_num(text.size)} Tf",
      "#{format_num(x)} #{format_num(y)} Td",
      "(#{escape_pdf_string(text.content)}) Tj",
      "ET"
    ]
    |> Enum.join("\n")
  end

  defp render_block(_block, _page, _font), do: ""

  defp build_info_dict(%Rendro.Metadata{} = meta) do
    entries =
      []
      |> maybe_add("Title", meta.title)
      |> maybe_add("Author", meta.author)
      |> maybe_add("Creator", meta.creator)
      |> maybe_add("Producer", "Rendro")

    {:dict, Enum.reverse(entries)}
  end

  defp maybe_add(entries, _key, nil), do: entries
  defp maybe_add(entries, key, value), do: [{key, {:string, value}} | entries]

  defp assemble(
         {numbered_objects, catalog_num, info_num, _total_objects},
         _catalog_num_arg
       ) do
    header = @pdf_header
    header_size = byte_size(header)

    {body_parts, xref_entries} =
      Enum.reduce(numbered_objects, {[], [{0, 65535, "f"}]}, fn {obj_num, obj_iodata},
                                                                 {parts, entries} ->
        current_offset =
          header_size +
            (parts |> Enum.map(&IO.iodata_length/1) |> Enum.sum())

        obj_binary = IO.iodata_to_binary(obj_iodata)
        {parts ++ [obj_binary], entries ++ [{current_offset, 0, "n", obj_num}]}
      end)

    xref_offset = header_size + (body_parts |> Enum.map(&byte_size/1) |> Enum.sum())

    sorted_entries =
      xref_entries
      |> Enum.sort_by(fn
        {_, _, "f"} -> 0
        {_, _, "n", num} -> num
      end)

    num_entries = length(sorted_entries)

    xref_lines =
      Enum.map(sorted_entries, fn
        {offset, gen, "f"} ->
          :io_lib.format("~10..0B ~5..0B f \n", [offset, gen])

        {offset, gen, "n", _num} ->
          :io_lib.format("~10..0B ~5..0B n \n", [offset, gen])
      end)

    trailer_dict =
      {:dict,
       [
         {"Size", num_entries},
         {"Root", {:ref, catalog_num, 0}},
         {"Info", {:ref, info_num, 0}}
       ]}

    [
      header,
      body_parts,
      "xref\n",
      "0 #{num_entries}\n",
      xref_lines,
      "trailer\n",
      Object.serialize(trailer_dict),
      "\nstartxref\n",
      Integer.to_string(xref_offset),
      "\n%%EOF\n"
    ]
  end

  defp format_num(n) when is_integer(n), do: Integer.to_string(n)

  defp format_num(n) when is_float(n) do
    :erlang.float_to_binary(n * 1.0, decimals: 4)
  end

  defp escape_pdf_string(str) do
    str
    |> String.replace("\\", "\\\\")
    |> String.replace("(", "\\(")
    |> String.replace(")", "\\)")
  end
end
