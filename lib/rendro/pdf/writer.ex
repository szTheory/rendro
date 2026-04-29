defmodule Rendro.PDF.Writer do
  @moduledoc """
  Serializes a `Rendro.Document` into a valid PDF 1.4 binary.

  Builds the complete PDF structure: header, indirect object body,
  cross-reference table, and trailer with catalog root. Each page
  gets a content stream with Tf/Td/Tj text operators for its blocks.
  """

  alias Rendro.PDF.{Font, Object}
  alias Rendro.Pipeline.MeasuredText

  @pdf_header "%PDF-1.4\n%\xE2\xE3\xCF\xD3\n"

  @spec render(Rendro.Document.t()) :: {:ok, binary()}
  def render(%Rendro.Document{} = doc) do
    render(doc, [])
  end

  @spec render(Rendro.Document.t(), Object.serialize_opts()) :: {:ok, binary()}
  def render(%Rendro.Document{} = doc, opts) when is_list(opts) do
    font = Font.helvetica()
    {numbered_objects, catalog_num, info_num, total_objects} = build_objects(doc, font, opts)
    pdf = assemble({numbered_objects, catalog_num, info_num, total_objects}, catalog_num, opts)
    {:ok, IO.iodata_to_binary(pdf)}
  end

  defp build_objects(%Rendro.Document{pages: pages, metadata: metadata}, font, opts) do
    obj_num = 1
    catalog_num = obj_num

    {page_obj_nums, font_obj_num, next_num} = allocate_page_nums(pages, obj_num + 1, font)
    pages_num = next_num
    next_num = next_num + 1

    info_num = next_num
    next_num = next_num + 1

    font_dict =
      {:dict,
       [
         {"Type", {:name, "Font"}},
         {"Subtype", {:name, "Type1"}},
         {"BaseFont", {:name, font.base_font}}
       ]}

    font_obj = Object.indirect_object(font_obj_num, 0, Object.serialize(font_dict, opts))

    page_tree_kids =
      {:array, Enum.map(page_obj_nums, fn {page_num, _} -> {:ref, page_num, 0} end)}

    pages_dict =
      {:dict,
       [
         {"Type", {:name, "Pages"}},
         {"Kids", page_tree_kids},
         {"Count", length(pages)}
       ]}

    pages_obj = Object.indirect_object(pages_num, 0, Object.serialize(pages_dict, opts))

    catalog_dict =
      {:dict,
       [
         {"Type", {:name, "Catalog"}},
         {"Pages", {:ref, pages_num, 0}}
       ]}

    catalog_obj = Object.indirect_object(catalog_num, 0, Object.serialize(catalog_dict, opts))

    page_objects = build_page_objects(pages, page_obj_nums, pages_num, font_obj_num, font, opts)

    info_dict = build_info_dict(metadata, opts)
    info_obj = Object.indirect_object(info_num, 0, Object.serialize(info_dict, opts))

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

  defp build_page_objects(pages, page_obj_nums, pages_num, font_obj_num, font, opts) do
    Enum.zip(pages, page_obj_nums)
    |> Enum.flat_map(fn {page, {page_num, content_num}} ->
      content_data = build_content_stream(page, font)

      content_stream =
        {:stream, [], content_data}

      content_obj = Object.indirect_object(content_num, 0, Object.serialize(content_stream, opts))

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

      page_obj = Object.indirect_object(page_num, 0, Object.serialize(page_dict, opts))

      [page_obj, content_obj]
    end)
  end

  defp build_content_stream(%Rendro.Page{} = page, font) do
    Enum.map_join(page.blocks, "\n", fn block -> render_block(block, page, font) end)
  end

  defp render_block(%Rendro.Block{content: %Rendro.Table{} = table} = block, page, font) do
    header_ops =
      if table.header do
        Enum.map(table.header, &render_block(&1, page, font, block.x, block.y))
      else
        []
      end

    rows_ops =
      Enum.map(table.rows, fn row ->
        Enum.map(row, &render_block(&1, page, font, block.x, block.y))
      end)

    [header_ops | rows_ops] |> List.flatten() |> Enum.join("\n")
  end

  defp render_block(%Rendro.Block{content: %Rendro.Text{}} = block, page, font) do
    render_block(block, page, font, 0, 0)
  end

  defp render_block(%Rendro.Block{content: %MeasuredText{}} = block, page, font) do
    render_block(block, page, font, 0, 0)
  end

  defp render_block(_block, _page, _font), do: ""

  defp render_block(%Rendro.Block{content: %Rendro.Text{} = text} = block, page, _font, ox, oy) do
    render_text_block(block, page, ox, oy, text, [text.content], text.line_height)
  end

  defp render_block(%Rendro.Block{content: %MeasuredText{} = text} = block, page, _font, ox, oy) do
    render_text_block(block, page, ox, oy, text.source, text.lines, text.line_height)
  end

  defp render_text_block(block, page, ox, oy, text, lines, line_height) do
    x = block.x + ox + page.margin_left
    y = page.height - (block.y + oy) - page.margin_top - text.size
    {r, g, b} = text.color
    color_op = "#{format_num(r / 255)} #{format_num(g / 255)} #{format_num(b / 255)} rg"
    line_offset = text.size * line_height

    line_ops =
      lines
      |> Enum.with_index()
      |> Enum.flat_map(fn {line, index} ->
        if index == 0 do
          ["#{format_num(x)} #{format_num(y)} Td", "(#{escape_pdf_string(line)}) Tj"]
        else
          ["0 #{format_num(-line_offset)} Td", "(#{escape_pdf_string(line)}) Tj"]
        end
      end)

    [
      "BT",
      color_op,
      "/F1 #{format_num(text.size)} Tf",
      line_ops,
      "ET"
    ]
    |> Enum.join("\n")
  end

  @deterministic_date "D:20000101000000Z"

  defp build_info_dict(%Rendro.Metadata{} = meta, opts) do
    deterministic? = Keyword.get(opts, :deterministic, false)

    entries =
      []
      |> maybe_add("Title", meta.title)
      |> maybe_add("Author", meta.author)
      |> maybe_add("Creator", meta.creator)
      |> maybe_add("Producer", "Rendro")

    entries =
      if deterministic? do
        entries
        |> List.keydelete("CreationDate", 0)
        |> List.keydelete("ModDate", 0)
        |> Kernel.++([
          {"CreationDate", {:string, @deterministic_date}},
          {"ModDate", {:string, @deterministic_date}}
        ])
      else
        add_date_entries(entries, meta)
      end

    {:dict, Enum.reverse(entries)}
  end

  defp add_date_entries(entries, %Rendro.Metadata{} = meta) do
    entries
    |> maybe_add("CreationDate", format_date(meta.creation_date))
    |> maybe_add("ModDate", format_date(meta.modification_date))
  end

  defp format_date(nil), do: nil

  defp format_date(%DateTime{} = dt) do
    Calendar.strftime(dt, "D:%Y%m%d%H%M%SZ")
  end

  defp maybe_add(entries, _key, nil), do: entries
  defp maybe_add(entries, key, value), do: [{key, {:string, value}} | entries]

  defp assemble(
         {numbered_objects, catalog_num, info_num, _total_objects},
         _catalog_num_arg,
         opts
       ) do
    header = @pdf_header
    header_size = byte_size(header)

    {body_parts, xref_entries} =
      Enum.reduce(numbered_objects, {[], [{0, 65_535, "f"}]}, fn {obj_num, obj_iodata},
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

    deterministic? = Keyword.get(opts, :deterministic, false)

    id_entry =
      if deterministic? do
        content_hash = :crypto.hash(:md5, IO.iodata_to_binary(body_parts))
        id_hex = {:hex_string, content_hash}
        [{"ID", {:array, [id_hex, id_hex]}}]
      else
        []
      end

    trailer_dict =
      {:dict,
       [
         {"Size", num_entries},
         {"Root", {:ref, catalog_num, 0}},
         {"Info", {:ref, info_num, 0}}
       ] ++ id_entry}

    [
      header,
      body_parts,
      "xref\n",
      "0 #{num_entries}\n",
      xref_lines,
      "trailer\n",
      Object.serialize(trailer_dict, opts),
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
