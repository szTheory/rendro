defmodule Rendro.PDF.Writer do
  @moduledoc false

  alias Rendro.FontRegistry
  alias Rendro.PDF.{Font, Object, PNG}
  alias Rendro.Pipeline.MeasuredText

  @pdf_header "%PDF-1.4\n%\xE2\xE3\xCF\xD3\n"

  @spec render(Rendro.Document.t()) :: {:ok, binary()}
  def render(%Rendro.Document{} = doc) do
    render(doc, [])
  end

  @spec render(Rendro.Document.t(), Object.serialize_opts()) :: {:ok, binary()}
  def render(%Rendro.Document{} = doc, opts) when is_list(opts) do
    with {:ok, fonts} <- collect_fonts(doc),
         {:ok, images} <- collect_images(doc),
         {numbered_objects, catalog_num, info_num, total_objects} <-
           build_objects(doc, fonts, images, opts) do
      pdf = assemble({numbered_objects, catalog_num, info_num, total_objects}, catalog_num, opts)
      {:ok, IO.iodata_to_binary(pdf)}
    end
  end

  defp build_objects(
         %Rendro.Document{pages: pages, metadata: metadata} = doc,
         fonts,
         images,
         opts
       ) do
    obj_num = 1
    catalog_num = obj_num

    {page_obj_nums, next_num} = allocate_page_nums(pages, obj_num + 1)
    {font_objects, next_num} = allocate_font_nums(fonts, next_num)
    {image_objects, next_num} = allocate_image_nums(images, next_num)
    pages_num = next_num
    next_num = next_num + 1

    info_num = next_num
    next_num = next_num + 1

    font_pdf_objects = build_font_objects(font_objects, opts)
    image_pdf_objects = build_image_objects(image_objects, opts)

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

    font_map = doc_font_map(font_objects)
    image_map = doc_image_map(image_objects)

    page_objects =
      build_page_objects(
        doc,
        page_obj_nums,
        pages_num,
        font_objects,
        image_objects,
        font_map,
        image_map,
        opts
      )

    info_dict = build_info_dict(metadata, opts)
    info_obj = Object.indirect_object(info_num, 0, Object.serialize(info_dict, opts))

    total_objects = next_num

    numbered_objects =
      [{catalog_num, catalog_obj}] ++
        font_pdf_objects ++
        image_pdf_objects ++
        [{pages_num, pages_obj}] ++
        Enum.zip(
          Enum.flat_map(page_obj_nums, fn {p, c} -> [p, c] end),
          page_objects
        ) ++ [{info_num, info_obj}]

    {numbered_objects, catalog_num, info_num, total_objects}
  end

  defp allocate_page_nums(pages, start_num) do
    {page_nums, next} =
      Enum.reduce(pages, {[], start_num}, fn _page, {acc, num} ->
        page_num = num
        content_num = num + 1
        {acc ++ [{page_num, content_num}], num + 2}
      end)

    {page_nums, next}
  end

  defp allocate_font_nums(fonts, start_num) do
    Enum.map_reduce(fonts, start_num, fn font, num ->
      allocation =
        if font.embedded? do
          %{
            font: font,
            font_obj_num: num,
            cid_font_obj_num: num + 1,
            descriptor_obj_num: num + 2,
            widths_obj_num: num + 3,
            font_file_obj_num: num + 4
          }
        else
          %{font: font, font_obj_num: num}
        end

      {allocation, next_font_num(allocation)}
    end)
  end

  defp next_font_num(%{font_file_obj_num: obj_num}), do: obj_num + 1
  defp next_font_num(%{font_obj_num: obj_num}), do: obj_num + 1

  defp build_font_objects(font_allocations, opts) do
    Enum.flat_map(font_allocations, fn allocation ->
      build_font_object(allocation, opts)
    end)
  end

  defp build_font_object(%{font: %Font{embedded?: false} = font, font_obj_num: obj_num}, opts) do
    font_dict =
      {:dict,
       [
         {"Type", {:name, "Font"}},
         {"Subtype", {:name, "Type1"}},
         {"BaseFont", {:name, font.base_font}}
       ]}

    [{obj_num, Object.indirect_object(obj_num, 0, Object.serialize(font_dict, opts))}]
  end

  defp build_font_object(%{font: %Font{embedded?: true}} = allocation, opts) do
    Rendro.PDF.CidFont.build_objects(allocation.font, allocation, opts)
  end

  defp allocate_image_nums(images, start_num) do
    Enum.map_reduce(images, start_num, fn image, num ->
      if image.mime == "image/png" and image.color_type in [4, 6] do
        {%{image: image, obj_num: num, smask_obj_num: num + 1}, num + 2}
      else
        {%{image: image, obj_num: num}, num + 1}
      end
    end)
  end

  defp build_image_objects(image_allocations, opts) do
    Enum.flat_map(image_allocations, fn alloc ->
      build_image_object(alloc, opts)
    end)
  end

  defp build_image_object(%{image: %{mime: "image/jpeg"} = image, obj_num: obj_num}, opts) do
    entries = [
      {"Type", {:name, "XObject"}},
      {"Subtype", {:name, "Image"}},
      {"Width", image.width},
      {"Height", image.height},
      {"ColorSpace", {:name, "DeviceRGB"}},
      {"BitsPerComponent", 8},
      {"Filter", {:name, "DCTDecode"}}
    ]

    stream = {:stream, entries, image.binary}
    [{obj_num, Object.indirect_object(obj_num, 0, Object.serialize(stream, opts))}]
  end

  defp build_image_object(%{image: %{mime: "image/png"} = image} = alloc, opts) do
    obj_num = alloc.obj_num

    case PNG.process_for_pdf(image.binary) do
      {:split, color_stream_data, alpha_stream_data, color_space} ->
        smask_obj_num = alloc.smask_obj_num

        color_stream =
          {:stream,
           [
             {"Type", {:name, "XObject"}},
             {"Subtype", {:name, "Image"}},
             {"Width", image.width},
             {"Height", image.height},
             {"ColorSpace", format_color_space(color_space)},
             {"BitsPerComponent", image.bit_depth},
             {"Filter", {:name, "FlateDecode"}},
             {"SMask", {:ref, smask_obj_num, 0}}
           ], color_stream_data}

        smask_stream =
          {:stream,
           [
             {"Type", {:name, "XObject"}},
             {"Subtype", {:name, "Image"}},
             {"Width", image.width},
             {"Height", image.height},
             {"ColorSpace", {:name, "DeviceGray"}},
             {"BitsPerComponent", image.bit_depth},
             {"Filter", {:name, "FlateDecode"}}
           ], alpha_stream_data}

        [
          {obj_num, Object.indirect_object(obj_num, 0, Object.serialize(color_stream, opts))},
          {smask_obj_num,
           Object.indirect_object(smask_obj_num, 0, Object.serialize(smask_stream, opts))}
        ]

      {:pass_through, idat, decode_parms, color_space} ->
        pdf_decode_parms =
          {:dict, Enum.map(decode_parms, fn {k, v} -> {to_string(k), v} end)}

        entries = [
          {"Type", {:name, "XObject"}},
          {"Subtype", {:name, "Image"}},
          {"Width", image.width},
          {"Height", image.height},
          {"ColorSpace", format_color_space(color_space)},
          {"BitsPerComponent", image.bit_depth},
          {"Filter", {:name, "FlateDecode"}},
          {"DecodeParms", pdf_decode_parms}
        ]

        stream = {:stream, entries, idat}
        [{obj_num, Object.indirect_object(obj_num, 0, Object.serialize(stream, opts))}]

      {:error, reason} ->
        raise "Failed to process PNG image: #{inspect(reason)}"
    end
  end

  defp format_color_space([:Indexed, base, max_index, palette]) do
    {:array, [{:name, "Indexed"}, format_color_space(base), max_index, {:string, palette}]}
  end

  defp format_color_space(cs), do: cs

  defp scale_font_metric(metric, units_per_em)
       when is_integer(metric) and is_integer(units_per_em) do
    round(metric * 1000 / units_per_em)
  end

  defp doc_font_map(font_allocations) do
    Map.new(font_allocations, fn %{font: font} = allocation -> {font.name, allocation} end)
  end

  defp doc_image_map(image_allocations) do
    Map.new(image_allocations, fn %{image: image} = allocation ->
      {image.logical_name, allocation}
    end)
  end

  defp build_page_objects(
         %Rendro.Document{pages: pages} = doc,
         page_obj_nums,
         pages_num,
         font_allocations,
         image_allocations,
         font_map,
         image_map,
         opts
       ) do
    Enum.zip(pages, page_obj_nums)
    |> Enum.flat_map(fn {page, {page_num, content_num}} ->
      content_data = build_content_stream(doc, page, font_map, image_map)

      content_stream =
        {:stream, [], content_data}

      content_obj = Object.indirect_object(content_num, 0, Object.serialize(content_stream, opts))

      resources_dict =
        []
        |> maybe_add_resource("Font", font_resource_entries(font_allocations))
        |> maybe_add_resource("XObject", image_resource_entries(image_allocations))

      resources = {:dict, resources_dict}

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

  defp maybe_add_resource(entries, _key, []), do: entries
  defp maybe_add_resource(entries, key, value), do: [{key, {:dict, value}} | entries]

  defp build_content_stream(doc, %Rendro.Page{} = page, font_map, image_map) do
    Enum.map_join(page.blocks, "\n", fn block ->
      render_block(doc, block, page, font_map, image_map)
    end)
  end

  defp render_block(
         doc,
         %Rendro.Block{content: %Rendro.Table{} = table},
         page,
         font_map,
         image_map
       ) do
    header_ops =
      if table.header do
        Enum.map(table.header.cells, fn %Rendro.Cell{content: block} ->
          render_block(doc, block, page, font_map, image_map)
        end)
      else
        []
      end

    rows_ops =
      Enum.map(table.rows, fn %Rendro.Row{cells: cells} ->
        Enum.map(cells, fn %Rendro.Cell{content: block} ->
          render_block(doc, block, page, font_map, image_map)
        end)
      end)

    [header_ops | rows_ops] |> List.flatten() |> Enum.join("\n")
  end

  defp render_block(
         doc,
         %Rendro.Block{content: %Rendro.Text{}} = block,
         page,
         font_map,
         image_map
       ) do
    render_block(doc, block, page, font_map, image_map, 0, 0)
  end

  defp render_block(
         doc,
         %Rendro.Block{content: %MeasuredText{}} = block,
         page,
         font_map,
         image_map
       ) do
    render_block(doc, block, page, font_map, image_map, 0, 0)
  end

  defp render_block(
         doc,
         %Rendro.Block{content: %Rendro.Image{}} = block,
         page,
         font_map,
         image_map
       ) do
    render_block(doc, block, page, font_map, image_map, 0, 0)
  end

  defp render_block(_doc, _block, _page, _font_map, _image_map), do: ""

  defp render_block(
         doc,
         %Rendro.Block{content: %Rendro.Text{} = text} = block,
         page,
         font_map,
         _image_map,
         ox,
         oy
       ) do
    case resolve_text_font(doc, text) do
      {:ok, font} ->
        lines = [[%{font: font, text: text.content}]]
        render_text_block(block, page, ox, oy, text, lines, text.line_height, font_map)

      {:error, _} ->
        ""
    end
  end

  defp render_block(
         _doc,
         %Rendro.Block{content: %MeasuredText{} = text} = block,
         page,
         font_map,
         _image_map,
         ox,
         oy
       ) do
    render_text_block(block, page, ox, oy, text.source, text.lines, text.line_height, font_map)
  end

  defp render_block(
         _doc,
         %Rendro.Block{content: %Rendro.Image{} = image} = block,
         page,
         _font_map,
         image_map,
         ox,
         oy
       ) do
    case Map.fetch(image_map, image.logical_name) do
      {:ok, _allocation} ->
        x = block.x + ox + page.margin_left
        y = page.height - (block.y + oy + block.height) - page.margin_top
        w = block.width
        h = block.height

        img_name = image_resource_name(image.logical_name)

        "q\n#{format_num(w)} 0 0 #{format_num(h)} #{format_num(x)} #{format_num(y)} cm\n/#{img_name} Do\nQ"

      :error ->
        ""
    end
  end

  defp render_text_block(block, page, ox, oy, text, lines, line_height, font_map) do
    x = block.x + ox + page.margin_left
    y = page.height - (block.y + oy) - page.margin_top - text.size
    {r, g, b} = text.color
    color_op = "#{format_num(r / 255)} #{format_num(g / 255)} #{format_num(b / 255)} rg"
    line_offset = text.size * line_height

    line_ops =
      lines
      |> Enum.with_index()
      |> Enum.flat_map(fn {runs, index} ->
        pos_op =
          if index == 0 do
            "#{format_num(x)} #{format_num(y)} Td"
          else
            "0 #{format_num(-line_offset)} Td"
          end

        runs_ops =
          Enum.flat_map(runs, fn run ->
            font_name = resolved_font_name(run.font, font_map)

            [
              "/#{font_name} #{format_num(text.size)} Tf",
              "#{encode_text(run.font, run.text)} Tj"
            ]
          end)

        [pos_op | runs_ops]
      end)

    [
      "BT",
      color_op,
      line_ops,
      "ET"
    ]
    |> List.flatten()
    |> Enum.join("\n")
  end

  defp encode_text(%Rendro.PDF.Font{embedded?: true} = font, text) do
    hex_glyphs =
      text
      |> String.to_charlist()
      |> Enum.map(fn codepoint ->
        glyph_id = Map.get(font.cmap || %{}, codepoint, 0)
        :io_lib.format("~4.16.0B", [glyph_id]) |> to_string()
      end)
      |> Enum.join("")

    "<#{hex_glyphs}>"
  end

  defp encode_text(%Rendro.PDF.Font{embedded?: false}, text) do
    "(#{escape_pdf_string(text)})"
  end

  defp collect_fonts(%Rendro.Document{pages: pages} = doc) do
    pages
    |> Enum.reduce_while({:ok, %{}}, fn page, {:ok, acc} ->
      case collect_page_fonts(doc, page, acc) do
        {:ok, page_fonts} -> {:cont, {:ok, page_fonts}}
        {:error, _} = err -> {:halt, err}
      end
    end)
    |> case do
      {:ok, font_map} ->
        {:ok, font_map |> Map.values() |> Enum.sort_by(& &1.name)}

      {:error, _} = err ->
        err
    end
  end

  defp collect_page_fonts(doc, %Rendro.Page{blocks: blocks}, acc) do
    Enum.reduce_while(blocks, {:ok, acc}, fn block, {:ok, fonts} ->
      case collect_block_fonts(doc, block, fonts) do
        {:ok, collected} -> {:cont, {:ok, collected}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp collect_block_fonts(doc, %Rendro.Block{content: %Rendro.Table{} = table}, acc) do
    with {:ok, acc} <- collect_row_fonts(doc, table.header, acc),
         {:ok, acc} <- collect_rows_fonts(doc, table.rows, acc) do
      {:ok, acc}
    end
  end

  defp collect_block_fonts(doc, %Rendro.Block{content: %Rendro.Text{} = text}, acc) do
    with {:ok, font} <- resolve_text_font(doc, text) do
      {:ok, Map.put(acc, font.name, font)}
    end
  end

  defp collect_block_fonts(_doc, %Rendro.Block{content: %MeasuredText{lines: lines}}, acc) do
    new_acc =
      Enum.reduce(lines, acc, fn line, line_acc ->
        Enum.reduce(line, line_acc, fn run, run_acc ->
          Map.put(run_acc, run.font.name, run.font)
        end)
      end)

    {:ok, new_acc}
  end

  defp collect_block_fonts(_doc, %Rendro.Block{}, acc), do: {:ok, acc}

  defp collect_rows_fonts(doc, rows, acc) do
    Enum.reduce_while(rows, {:ok, acc}, fn row, {:ok, fonts} ->
      case collect_row_fonts(doc, row, fonts) do
        {:ok, collected} -> {:cont, {:ok, collected}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp collect_row_fonts(_doc, nil, acc), do: {:ok, acc}

  defp collect_row_fonts(doc, %Rendro.Row{cells: cells}, acc) do
    Enum.reduce_while(cells, {:ok, acc}, fn %Rendro.Cell{content: block}, {:ok, fonts} ->
      case collect_block_fonts(doc, block, fonts) do
        {:ok, collected} -> {:cont, {:ok, collected}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp font_resource_entries(font_object_refs) do
    Enum.map(font_object_refs, fn %{font: font, font_obj_num: obj_num} ->
      {font.name, {:ref, obj_num, 0}}
    end)
  end

  defp collect_images(%Rendro.Document{pages: pages} = doc) do
    pages
    |> Enum.reduce_while({:ok, MapSet.new()}, fn page, {:ok, acc} ->
      case collect_page_images(doc, page, acc) do
        {:ok, page_images} -> {:cont, {:ok, page_images}}
        {:error, _} = err -> {:halt, err}
      end
    end)
    |> case do
      {:ok, image_names} ->
        images =
          Enum.map(image_names, fn name ->
            case Rendro.AssetRegistry.fetch(doc.asset_registry, name) do
              {:ok, asset} -> Map.put(asset, :logical_name, name)
              :error -> raise "Missing asset: #{name}"
            end
          end)
          |> Enum.sort_by(& &1.logical_name)

        {:ok, images}

      {:error, _} = err ->
        err
    end
  end

  defp collect_page_images(doc, %Rendro.Page{blocks: blocks}, acc) do
    Enum.reduce_while(blocks, {:ok, acc}, fn block, {:ok, images} ->
      case collect_block_images(doc, block, images) do
        {:ok, collected} -> {:cont, {:ok, collected}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp collect_block_images(doc, %Rendro.Block{content: %Rendro.Table{} = table}, acc) do
    with {:ok, acc} <- collect_row_images(doc, table.header, acc),
         {:ok, acc} <- collect_rows_images(doc, table.rows, acc) do
      {:ok, acc}
    end
  end

  defp collect_block_images(_doc, %Rendro.Block{content: %Rendro.Image{} = image}, acc) do
    {:ok, MapSet.put(acc, image.logical_name)}
  end

  defp collect_block_images(_doc, %Rendro.Block{}, acc), do: {:ok, acc}

  defp collect_rows_images(doc, rows, acc) do
    Enum.reduce_while(rows, {:ok, acc}, fn row, {:ok, images} ->
      case collect_row_images(doc, row, images) do
        {:ok, collected} -> {:cont, {:ok, collected}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp collect_row_images(_doc, nil, acc), do: {:ok, acc}

  defp collect_row_images(doc, %Rendro.Row{cells: cells}, acc) do
    Enum.reduce_while(cells, {:ok, acc}, fn %Rendro.Cell{content: block}, {:ok, images} ->
      case collect_block_images(doc, block, images) do
        {:ok, collected} -> {:cont, {:ok, collected}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp image_resource_entries(image_object_refs) do
    Enum.map(image_object_refs, fn %{image: image, obj_num: obj_num} ->
      {image_resource_name(image.logical_name), {:ref, obj_num, 0}}
    end)
  end

  defp image_resource_name(logical_name) do
    "IM_#{String.upcase(to_string(logical_name))}"
  end

  defp resolve_text_font(
         %Rendro.Document{font_registry: registry, default_font: default_font},
         %Rendro.Text{font: font}
       ) do
    FontRegistry.resolve_pdf_font(registry, font, default_font)
  end

  defp resolved_font_name(font, font_map) do
    case Map.fetch(font_map, font.name) do
      {:ok, _font_ref} ->
        font.name

      :error ->
        raise ArgumentError, "missing collected PDF font resource for #{inspect(font.name)}"
    end
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
