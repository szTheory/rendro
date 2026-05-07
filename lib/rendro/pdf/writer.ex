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
    form_fields = collect_form_fields(doc)
    embedded_files = collect_embedded_files(doc)
    link_annotations = collect_link_annotations(doc)
    obj_num = 1
    catalog_num = obj_num

    {page_obj_nums, next_num} = allocate_page_nums(pages, obj_num + 1)
    {font_objects, next_num} = allocate_font_nums(fonts, next_num)
    {image_objects, next_num} = allocate_image_nums(images, next_num)
    {form_field_objects, next_num} = allocate_form_field_nums(form_fields, next_num)
    {embedded_file_objects, next_num} = allocate_embedded_file_nums(embedded_files, next_num)

    {link_annotation_objects, next_num} =
      allocate_link_annotation_nums(link_annotations, next_num)

    pages_num = next_num
    next_num = next_num + 1

    info_num = next_num
    next_num = next_num + 1

    font_pdf_objects = build_font_objects(font_objects, opts)
    image_pdf_objects = build_image_objects(image_objects, opts)
    form_field_pdf_objects = build_radio_group_objects(form_field_objects, opts)
    embedded_file_pdf_objects = build_embedded_file_objects(embedded_file_objects, opts)

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
       pages_num
       |> maybe_add_acro_form_entry(form_field_objects)
       |> maybe_add_embedded_files_entries(embedded_file_objects)}

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
        form_field_objects,
        link_annotation_objects,
        font_map,
        image_map,
        opts
      )

    info_dict = build_info_dict(metadata, opts)
    info_obj = Object.indirect_object(info_num, 0, Object.serialize(info_dict, opts))

    total_objects = next_num

    numbered_objects =
      ([{catalog_num, catalog_obj}] ++
         font_pdf_objects ++
         image_pdf_objects ++
         form_field_pdf_objects ++
         embedded_file_pdf_objects ++
         [{pages_num, pages_obj}] ++
         page_objects ++
         [{info_num, info_obj}])
      |> Enum.sort_by(&elem(&1, 0))

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

  defp allocate_form_field_nums(form_fields, start_num) do
    {families, radio_groups} =
      Enum.reduce(form_fields, {[], %{}}, fn form_field, {families, radio_groups} ->
        case form_field.field.type do
          :radio ->
            key = {:radio_group, form_field.field.group}

            if Map.has_key?(radio_groups, key) do
              {families, Map.update!(radio_groups, key, &(&1 ++ [form_field]))}
            else
              {[key | families], Map.put(radio_groups, key, [form_field])}
            end

          _ ->
            {[{:standalone, form_field} | families], radio_groups}
        end
      end)

    Enum.map_reduce(Enum.reverse(families), start_num, fn
      {:standalone, form_field}, num ->
        {allocate_standalone_form_field(form_field, num), next_form_field_num(form_field, num)}

      radio_group_key, num ->
        allocation = allocate_radio_group(Map.fetch!(radio_groups, radio_group_key), num)
        {allocation, next_radio_group_num(allocation)}
    end)
  end

  defp allocate_embedded_file_nums(embedded_files, start_num) do
    Enum.map_reduce(embedded_files, start_num, fn embedded_file, num ->
      {%{embedded_file: embedded_file, stream_obj_num: num, file_spec_obj_num: num + 1}, num + 2}
    end)
  end

  defp allocate_link_annotation_nums(link_annotations, start_num) do
    Enum.map_reduce(link_annotations, start_num, fn annotation, num ->
      {Map.put(annotation, :obj_num, num), num + 1}
    end)
  end

  defp allocate_standalone_form_field(form_field, num) do
    base = %{
      type: form_field.field.type,
      field_obj_num: num,
      block: form_field.block,
      field: form_field.field,
      page_index: form_field.page_index,
      widget_obj_num: num
    }

    case form_field.field.type do
      :checkbox ->
        Map.merge(base, %{
          checked_appearance_obj_num: num + 1,
          unchecked_appearance_obj_num: num + 2
        })

      _ ->
        Map.put(base, :appearance_obj_num, num + 1)
    end
  end

  defp next_form_field_num(%{field: %{type: :checkbox}}, num), do: num + 3
  defp next_form_field_num(_form_field, num), do: num + 2

  defp allocate_radio_group([first | _] = widgets, num) do
    {widget_allocations, next_num} =
      Enum.map_reduce(widgets, num + 1, fn widget, widget_num ->
        allocation = %{
          type: :radio,
          block: widget.block,
          field: widget.field,
          page_index: widget.page_index,
          parent_obj_num: num,
          widget_obj_num: widget_num,
          checked_appearance_obj_num: widget_num + 1,
          unchecked_appearance_obj_num: widget_num + 2
        }

        {allocation, widget_num + 3}
      end)

    checked_widget = Enum.find(widget_allocations, & &1.field.checked)

    %{
      type: :radio_group,
      group: first.field.group,
      field_obj_num: num,
      value: if(checked_widget, do: checked_widget.field.export_value, else: "Off"),
      widgets: widget_allocations,
      next_num: next_num
    }
  end

  defp next_radio_group_num(%{next_num: next_num}), do: next_num

  defp build_radio_group_objects(form_field_allocations, opts) do
    form_field_allocations
    |> Enum.filter(&(&1.type == :radio_group))
    |> Enum.map(fn allocation ->
      {allocation.field_obj_num, build_radio_group_field_object(allocation, opts)}
    end)
  end

  defp build_embedded_file_objects(embedded_file_allocations, opts) do
    Enum.flat_map(embedded_file_allocations, &build_embedded_file_object(&1, opts))
  end

  defp build_embedded_file_object(
         %{
           embedded_file: embedded_file,
           stream_obj_num: stream_obj_num,
           file_spec_obj_num: file_spec_obj_num
         },
         opts
       ) do
    params =
      [
        {"Size", embedded_file.byte_size},
        {"CheckSum", {:hex_string, :crypto.hash(:md5, embedded_file.bytes)}}
      ]
      |> maybe_add_pdf_entry("CreationDate", maybe_format_pdf_date(embedded_file[:created_at]))
      |> maybe_add_pdf_entry("ModDate", maybe_format_pdf_date(embedded_file[:modified_at]))

    stream =
      {:stream,
       [
         {"Type", {:name, "EmbeddedFile"}},
         {"Subtype", {:name, encode_pdf_name(embedded_file.mime_type)}},
         {"Params", {:dict, params}}
       ], embedded_file.bytes}

    file_spec =
      {:dict,
       [
         {"Type", {:name, "Filespec"}},
         {"F", {:string, embedded_file.filename}},
         {"UF", {:string, embedded_file.filename}},
         {"EF", {:dict, [{"F", {:ref, stream_obj_num, 0}}]}}
       ]
       |> maybe_add_dict_entry("Desc", embedded_file[:description])}

    [
      {stream_obj_num, Object.indirect_object(stream_obj_num, 0, Object.serialize(stream, opts))},
      {file_spec_obj_num,
       Object.indirect_object(file_spec_obj_num, 0, Object.serialize(file_spec, opts))}
    ]
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
         form_field_allocations,
         link_annotation_allocations,
         font_map,
         image_map,
         opts
       ) do
    Enum.zip(pages, page_obj_nums)
    |> Enum.with_index()
    |> Enum.flat_map(fn {{page, {page_num, content_num}}, page_index} ->
      content_data = build_content_stream(doc, page, font_map, image_map)

      content_stream =
        {:stream, [], content_data}

      content_obj = Object.indirect_object(content_num, 0, Object.serialize(content_stream, opts))

      {form_annot_refs, form_objects} =
        build_form_field_objects(page, page_num, form_field_allocations, page_index, opts)

      {link_annot_refs, link_objects} =
        build_link_annotation_objects(
          page,
          page_obj_nums,
          link_annotation_allocations,
          page_index,
          opts
        )

      annot_refs = form_annot_refs ++ link_annot_refs

      resources_dict =
        []
        |> maybe_add_resource("Font", font_resource_entries(font_allocations))
        |> maybe_add_resource("XObject", image_resource_entries(image_allocations))

      resources = {:dict, resources_dict}

      media_box =
        {:array, [0, 0, page.width, page.height]}

      page_dict =
        {:dict, maybe_add_annots_entry(pages_num, content_num, media_box, resources, annot_refs)}

      page_obj = Object.indirect_object(page_num, 0, Object.serialize(page_dict, opts))

      [{page_num, page_obj}, {content_num, content_obj}] ++ form_objects ++ link_objects
    end)
  end

  defp maybe_add_resource(entries, _key, []), do: entries
  defp maybe_add_resource(entries, key, value), do: [{key, {:dict, value}} | entries]

  defp maybe_add_annots_entry(pages_num, content_num, media_box, resources, []) do
    base_page_entries(pages_num, content_num, media_box, resources)
  end

  defp maybe_add_annots_entry(pages_num, content_num, media_box, resources, annot_refs) do
    base_page_entries(pages_num, content_num, media_box, resources) ++
      [{"Annots", {:array, annot_refs}}]
  end

  defp base_page_entries(pages_num, content_num, media_box, resources) do
    [
      {"Type", {:name, "Page"}},
      {"Parent", {:ref, pages_num, 0}},
      {"MediaBox", media_box},
      {"Contents", {:ref, content_num, 0}},
      {"Resources", resources}
    ]
  end

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
         %Rendro.Block{content: %Rendro.Link{content: inner}} = block,
         page,
         font_map,
         image_map
       ) do
    render_block(doc, %{block | content: inner}, page, font_map, image_map)
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

  defp collect_block_fonts(doc, %Rendro.Block{content: %Rendro.Link{content: inner}}, acc) do
    collect_block_fonts(doc, %Rendro.Block{content: inner}, acc)
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

  defp collect_block_images(doc, %Rendro.Block{content: %Rendro.Link{content: inner}}, acc) do
    collect_block_images(doc, %Rendro.Block{content: inner}, acc)
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

  defp build_form_field_objects(page, page_num, form_field_allocations, page_index, opts) do
    page_allocations = page_form_field_allocations(form_field_allocations, page_index)

    case page_allocations do
      [] ->
        {[], []}

      _ ->
        Enum.map_reduce(page_allocations, [], fn allocation, acc ->
          rect = form_field_rect(page, allocation.block)

          {widget_obj, appearance_objects} =
            build_widget_objects(allocation, page_num, rect, opts)

          widget_ref = {:ref, allocation.widget_obj_num, 0}

          {
            widget_ref,
            acc ++ [{allocation.widget_obj_num, widget_obj} | appearance_objects]
          }
        end)
    end
  end

  defp build_link_annotation_objects(
         page,
         page_obj_nums,
         link_annotation_allocations,
         page_index,
         opts
       ) do
    page_allocations = page_link_annotation_allocations(link_annotation_allocations, page_index)

    case page_allocations do
      [] ->
        {[], []}

      _ ->
        Enum.map_reduce(page_allocations, [], fn allocation, acc ->
          rect = form_field_rect(page, allocation.block)

          link_obj =
            build_link_annotation_object(
              allocation.obj_num,
              rect,
              allocation.target,
              page_obj_nums,
              opts
            )

          link_ref = {:ref, allocation.obj_num, 0}

          {link_ref, acc ++ [{allocation.obj_num, link_obj}]}
        end)
    end
  end

  defp page_link_annotation_allocations(link_annotation_allocations, page_index) do
    Enum.filter(link_annotation_allocations, &(&1.page_index == page_index))
  end

  defp build_link_annotation_object(obj_num, rect, {:uri, uri}, _page_obj_nums, opts) do
    dict =
      {:dict,
       [
         {"Type", {:name, "Annot"}},
         {"Subtype", {:name, "Link"}},
         {"Rect", {:array, rect}},
         {"Border", {:array, [0, 0, 0]}},
         {"A", {:dict, [{"S", {:name, "URI"}}, {"URI", {:string, uri}}]}}
       ]}

    Object.indirect_object(obj_num, 0, Object.serialize(dict, opts))
  end

  defp build_link_annotation_object(obj_num, rect, {:page, page_number}, page_obj_nums, opts) do
    {target_page_obj_num, _content_obj_num} = Enum.at(page_obj_nums, page_number - 1)

    dict =
      {:dict,
       [
         {"Type", {:name, "Annot"}},
         {"Subtype", {:name, "Link"}},
         {"Rect", {:array, rect}},
         {"Border", {:array, [0, 0, 0]}},
         {"Dest", {:array, [{:ref, target_page_obj_num, 0}, {:name, "Fit"}]}}
       ]}

    Object.indirect_object(obj_num, 0, Object.serialize(dict, opts))
  end

  defp page_form_field_allocations(form_field_allocations, page_index) do
    Enum.flat_map(form_field_allocations, fn
      %{type: :radio_group, widgets: widgets} ->
        Enum.filter(widgets, &(&1.page_index == page_index))

      %{page_index: ^page_index} = allocation ->
        [allocation]

      _ ->
        []
    end)
  end

  defp build_widget_objects(%{type: :text} = allocation, page_num, rect, opts) do
    widget_obj =
      build_widget_annotation_object(
        allocation.widget_obj_num,
        page_num,
        allocation.appearance_obj_num,
        rect,
        allocation.field
      )

    appearance_obj =
      build_form_field_appearance_object(
        allocation.appearance_obj_num,
        rect_width(rect),
        rect_height(rect),
        allocation.field,
        opts
      )

    {widget_obj, [{allocation.appearance_obj_num, appearance_obj}]}
  end

  defp build_widget_objects(%{type: :checkbox} = allocation, page_num, rect, opts) do
    widget_obj =
      build_checkbox_widget_annotation_object(
        allocation.widget_obj_num,
        page_num,
        allocation.checked_appearance_obj_num,
        allocation.unchecked_appearance_obj_num,
        rect,
        allocation.field
      )

    appearance_objects =
      build_checkbox_appearance_objects(
        allocation,
        rect_width(rect),
        rect_height(rect),
        opts
      )

    {widget_obj, appearance_objects}
  end

  defp build_widget_objects(%{type: :signature} = allocation, page_num, rect, opts) do
    widget_obj =
      build_signature_widget_annotation_object(
        allocation.widget_obj_num,
        page_num,
        allocation.appearance_obj_num,
        rect,
        allocation.field
      )

    appearance_obj =
      build_signature_appearance_object(
        allocation.appearance_obj_num,
        rect_width(rect),
        rect_height(rect),
        opts
      )

    {widget_obj, [{allocation.appearance_obj_num, appearance_obj}]}
  end

  defp build_widget_objects(%{type: :radio} = allocation, page_num, rect, opts) do
    widget_obj =
      build_radio_widget_annotation_object(
        allocation.widget_obj_num,
        page_num,
        allocation.parent_obj_num,
        allocation.checked_appearance_obj_num,
        allocation.unchecked_appearance_obj_num,
        rect,
        allocation.field
      )

    appearance_objects =
      build_radio_appearance_objects(
        allocation,
        rect_width(rect),
        rect_height(rect),
        opts
      )

    {widget_obj, appearance_objects}
  end

  defp build_widget_annotation_object(widget_obj_num, page_num, appearance_obj_num, rect, field) do
    rect_serialized = IO.iodata_to_binary(Object.serialize({:array, rect}, []))
    default_appearance = pdf_literal_string("/Helv #{format_num(field.size)} Tf 0 g")

    widget_dict = [
      "<<\n",
      "/Type /Annot\n",
      "/Subtype /Widget\n",
      "/FT /Tx\n",
      "/Rect ",
      rect_serialized,
      "\n/T ",
      pdf_literal_string(field.name),
      "\n/V ",
      pdf_literal_string(field.value),
      "\n/DA ",
      default_appearance,
      "\n/AP <<\n/N ",
      Integer.to_string(appearance_obj_num),
      " 0 R\n>>\n/P ",
      Integer.to_string(page_num),
      " 0 R\n>>"
    ]

    Object.indirect_object(widget_obj_num, 0, {:raw, widget_dict}, [])
  end

  defp build_checkbox_widget_annotation_object(
         widget_obj_num,
         page_num,
         checked_appearance_obj_num,
         unchecked_appearance_obj_num,
         rect,
         field
       ) do
    rect_serialized = IO.iodata_to_binary(Object.serialize({:array, rect}, []))
    checked_state = button_state_name(field.export_value)
    current_state = if(field.checked, do: checked_state, else: "Off")

    widget_dict = [
      "<<\n",
      "/Type /Annot\n",
      "/Subtype /Widget\n",
      "/FT /Btn\n",
      "/Rect ",
      rect_serialized,
      "\n/T ",
      pdf_literal_string(field.name),
      "\n/V ",
      Object.serialize({:name, current_state}, []),
      "\n/AS ",
      Object.serialize({:name, current_state}, []),
      "\n/AP <<\n/N <<\n",
      Object.serialize({:name, checked_state}, []),
      " ",
      Integer.to_string(checked_appearance_obj_num),
      " 0 R\n",
      "/Off ",
      Integer.to_string(unchecked_appearance_obj_num),
      " 0 R\n>>\n>>\n/P ",
      Integer.to_string(page_num),
      " 0 R\n>>"
    ]

    Object.indirect_object(widget_obj_num, 0, {:raw, widget_dict}, [])
  end

  defp build_signature_widget_annotation_object(
         widget_obj_num,
         page_num,
         appearance_obj_num,
         rect,
         field
       ) do
    rect_serialized = IO.iodata_to_binary(Object.serialize({:array, rect}, []))

    widget_dict = [
      "<<\n",
      "/Type /Annot\n",
      "/Subtype /Widget\n",
      "/FT /Sig\n",
      "/Rect ",
      rect_serialized,
      "\n/T ",
      pdf_literal_string(field.name),
      "\n/AP <<\n/N ",
      Integer.to_string(appearance_obj_num),
      " 0 R\n>>\n/P ",
      Integer.to_string(page_num),
      " 0 R\n>>"
    ]

    Object.indirect_object(widget_obj_num, 0, {:raw, widget_dict}, [])
  end

  defp build_radio_widget_annotation_object(
         widget_obj_num,
         page_num,
         parent_obj_num,
         checked_appearance_obj_num,
         unchecked_appearance_obj_num,
         rect,
         field
       ) do
    rect_serialized = IO.iodata_to_binary(Object.serialize({:array, rect}, []))
    checked_state = button_state_name(field.export_value)
    current_state = if(field.checked, do: checked_state, else: "Off")

    widget_dict = [
      "<<\n",
      "/Type /Annot\n",
      "/Subtype /Widget\n",
      "/Rect ",
      rect_serialized,
      "\n/Parent ",
      Integer.to_string(parent_obj_num),
      " 0 R\n/AS ",
      Object.serialize({:name, current_state}, []),
      "\n/AP <<\n/N <<\n",
      Object.serialize({:name, checked_state}, []),
      " ",
      Integer.to_string(checked_appearance_obj_num),
      " 0 R\n",
      "/Off ",
      Integer.to_string(unchecked_appearance_obj_num),
      " 0 R\n>>\n>>\n/P ",
      Integer.to_string(page_num),
      " 0 R\n>>"
    ]

    Object.indirect_object(widget_obj_num, 0, {:raw, widget_dict}, [])
  end

  defp build_radio_group_field_object(allocation, opts) do
    kids =
      {:array, Enum.map(allocation.widgets, fn widget -> {:ref, widget.widget_obj_num, 0} end)}

    field_dict =
      {:dict,
       [
         {"FT", {:name, "Btn"}},
         {"T", {:string, allocation.group}},
         {"Ff", 49_152},
         {"Kids", kids},
         {"V", {:name, button_state_name(allocation.value)}}
       ]}

    Object.indirect_object(allocation.field_obj_num, 0, Object.serialize(field_dict, opts))
  end

  defp build_form_field_appearance_object(obj_num, width, height, field, opts) do
    stream =
      {:stream,
       [
         {"Type", {:name, "XObject"}},
         {"Subtype", {:name, "Form"}},
         {"BBox", {:array, [0, 0, width, height]}},
         {"Resources", {:dict, [{"Font", {:dict, [{"Helv", helvetica_font_dict()}]}}]}}
       ], build_form_field_appearance_stream(width, height, field)}

    Object.indirect_object(obj_num, 0, Object.serialize(stream, opts))
  end

  defp build_checkbox_appearance_objects(allocation, width, height, opts) do
    [
      {allocation.checked_appearance_obj_num,
       build_button_appearance_object(
         allocation.checked_appearance_obj_num,
         width,
         height,
         build_checkbox_appearance_stream(width, height, true),
         opts
       )},
      {allocation.unchecked_appearance_obj_num,
       build_button_appearance_object(
         allocation.unchecked_appearance_obj_num,
         width,
         height,
         build_checkbox_appearance_stream(width, height, false),
         opts
       )}
    ]
  end

  defp build_radio_appearance_objects(allocation, width, height, opts) do
    [
      {allocation.checked_appearance_obj_num,
       build_button_appearance_object(
         allocation.checked_appearance_obj_num,
         width,
         height,
         build_radio_appearance_stream(width, height, true),
         opts
       )},
      {allocation.unchecked_appearance_obj_num,
       build_button_appearance_object(
         allocation.unchecked_appearance_obj_num,
         width,
         height,
         build_radio_appearance_stream(width, height, false),
         opts
       )}
    ]
  end

  defp build_button_appearance_object(obj_num, width, height, stream_data, opts) do
    stream =
      {:stream,
       [
         {"Type", {:name, "XObject"}},
         {"Subtype", {:name, "Form"}},
         {"BBox", {:array, [0, 0, width, height]}}
       ], stream_data}

    Object.indirect_object(obj_num, 0, Object.serialize(stream, opts))
  end

  defp build_signature_appearance_object(obj_num, width, height, opts) do
    stream =
      {:stream,
       [
         {"Type", {:name, "XObject"}},
         {"Subtype", {:name, "Form"}},
         {"BBox", {:array, [0, 0, width, height]}}
       ], build_signature_appearance_stream(width, height)}

    Object.indirect_object(obj_num, 0, Object.serialize(stream, opts))
  end

  defp build_form_field_appearance_stream(width, height, field) do
    inset_x = 2
    baseline_y = max(2.0, (height - field.size) / 2.0)

    [
      "q\n",
      "1 1 1 rg\n",
      "0 0 ",
      format_num(width),
      " ",
      format_num(height),
      " re\nf\n",
      "0 0 0 RG\n",
      "0 0 ",
      format_num(width),
      " ",
      format_num(height),
      " re\nS\n",
      "BT\n",
      "/Helv ",
      format_num(field.size),
      " Tf\n",
      "0 g\n",
      format_num(inset_x),
      " ",
      format_num(baseline_y),
      " Td\n",
      "(",
      escape_pdf_string(field.value),
      ") Tj\n",
      "ET\nQ"
    ]
    |> IO.iodata_to_binary()
  end

  defp build_signature_appearance_stream(width, height) do
    line_inset = min(width, height) * 0.125
    mid_y = height / 2.0

    [
      "q\n",
      "1 1 1 rg\n",
      "0 0 ",
      format_num(width),
      " ",
      format_num(height),
      " re\nf\n",
      "0 0 0 RG\n",
      "1 w\n",
      "0.5 0.5 ",
      format_num(width - 1.0),
      " ",
      format_num(height - 1.0),
      " re\nS\n",
      format_num(line_inset),
      " ",
      format_num(mid_y),
      " m\n",
      format_num(width - line_inset),
      " ",
      format_num(mid_y),
      " l\nS\n",
      "Q"
    ]
    |> IO.iodata_to_binary()
  end

  defp build_checkbox_appearance_stream(width, height, checked?) do
    mark =
      if checked? do
        inset = 4.0

        [
          "1.5 w\n",
          format_num(inset),
          " ",
          format_num(inset),
          " m\n",
          format_num(width - inset),
          " ",
          format_num(height - inset),
          " l\nS\n",
          format_num(inset),
          " ",
          format_num(height - inset),
          " m\n",
          format_num(width - inset),
          " ",
          format_num(inset),
          " l\nS\n"
        ]
      else
        []
      end

    [
      "q\n",
      "1 1 1 rg\n",
      "0 0 ",
      format_num(width),
      " ",
      format_num(height),
      " re\nf\n",
      "0 0 0 RG\n",
      "1 w\n",
      "0.5 0.5 ",
      format_num(width - 1.0),
      " ",
      format_num(height - 1.0),
      " re\nS\n",
      mark,
      "Q"
    ]
    |> IO.iodata_to_binary()
  end

  defp build_radio_appearance_stream(width, height, checked?) do
    outer = circle_path(width, height, 1.5)

    inner =
      if checked? do
        circle_path(width, height, min(width, height) * 0.27)
      else
        []
      end

    [
      "q\n",
      "1 1 1 rg\n",
      outer,
      "f\n",
      "0 0 0 RG\n",
      "1 w\n",
      outer,
      "S\n",
      if(checked?, do: ["0 g\n", inner, "f\n"], else: []),
      "Q"
    ]
    |> IO.iodata_to_binary()
  end

  defp circle_path(width, height, inset) do
    radius = max(min(width, height) / 2.0 - inset, 1.0)
    center_x = width / 2.0
    center_y = height / 2.0
    control = radius * 0.5522847498
    left = center_x - radius
    right = center_x + radius
    top = center_y + radius
    bottom = center_y - radius

    [
      format_num(center_x),
      " ",
      format_num(top),
      " m\n",
      format_num(center_x + control),
      " ",
      format_num(top),
      " ",
      format_num(right),
      " ",
      format_num(center_y + control),
      " ",
      format_num(right),
      " ",
      format_num(center_y),
      " c\n",
      format_num(right),
      " ",
      format_num(center_y - control),
      " ",
      format_num(center_x + control),
      " ",
      format_num(bottom),
      " ",
      format_num(center_x),
      " ",
      format_num(bottom),
      " c\n",
      format_num(center_x - control),
      " ",
      format_num(bottom),
      " ",
      format_num(left),
      " ",
      format_num(center_y - control),
      " ",
      format_num(left),
      " ",
      format_num(center_y),
      " c\n",
      format_num(left),
      " ",
      format_num(center_y + control),
      " ",
      format_num(center_x - control),
      " ",
      format_num(top),
      " ",
      format_num(center_x),
      " ",
      format_num(top),
      " c\n"
    ]
  end

  defp form_field_rect(page, block) do
    x = block.x + page.margin_left
    y = page.height - (block.y + block.height) - page.margin_top
    [x, y, x + block.width, y + block.height]
  end

  defp rect_width([left, _bottom, right, _top]), do: right - left
  defp rect_height([_left, bottom, _right, top]), do: top - bottom

  defp collect_link_annotations(%Rendro.Document{pages: pages}) do
    pages
    |> Enum.with_index()
    |> Enum.flat_map(fn {%Rendro.Page{blocks: blocks}, page_index} ->
      Enum.flat_map(blocks, fn
        %Rendro.Block{content: %Rendro.Link{target: target}} = block ->
          [%{page_index: page_index, block: block, target: target}]

        _block ->
          []
      end)
    end)
  end

  defp collect_form_fields(%Rendro.Document{pages: pages}) do
    pages
    |> Enum.with_index()
    |> Enum.flat_map(fn {%Rendro.Page{blocks: blocks}, page_index} ->
      collect_page_form_fields(blocks, page_index)
    end)
  end

  defp collect_embedded_files(%Rendro.Document{embedded_file_registry: registry}) do
    registry.files
    |> Map.values()
    |> Enum.sort_by(fn embedded_file ->
      {embedded_file.filename, Atom.to_string(embedded_file.logical_name)}
    end)
  end

  defp collect_page_form_fields(blocks, page_index) do
    Enum.flat_map(blocks, &collect_block_form_fields(&1, page_index))
  end

  defp collect_block_form_fields(%Rendro.Block{content: %Rendro.Table{} = table}, page_index) do
    header_fields = collect_row_form_fields(table.header, page_index)
    row_fields = Enum.flat_map(table.rows, &collect_row_form_fields(&1, page_index))
    header_fields ++ row_fields
  end

  defp collect_block_form_fields(
         %Rendro.Block{content: %Rendro.FormField{} = field} = block,
         page_index
       ) do
    [%{block: block, field: field, page_index: page_index}]
  end

  defp collect_block_form_fields(%Rendro.Block{}, _page_index), do: []

  defp collect_row_form_fields(nil, _page_index), do: []

  defp collect_row_form_fields(%Rendro.Row{cells: cells}, page_index) do
    Enum.flat_map(cells, fn %Rendro.Cell{content: block} ->
      collect_block_form_fields(block, page_index)
    end)
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

  defp maybe_format_pdf_date(nil), do: nil
  defp maybe_format_pdf_date(%DateTime{} = dt), do: {:string, format_date(dt)}

  defp maybe_add(entries, _key, nil), do: entries
  defp maybe_add(entries, key, value), do: [{key, {:string, value}} | entries]

  defp maybe_add_dict_entry(entries, _key, nil), do: entries
  defp maybe_add_dict_entry(entries, key, value), do: entries ++ [{key, {:string, value}}]

  defp maybe_add_pdf_entry(entries, _key, nil), do: entries
  defp maybe_add_pdf_entry(entries, key, value), do: entries ++ [{key, value}]

  defp pdf_literal_string(str), do: ["(", escape_pdf_string(str), ")"]

  defp button_state_name("Off"), do: "Off"
  defp button_state_name(value), do: encode_pdf_name(value)

  defp helvetica_font_dict do
    {:dict,
     [
       {"Type", {:name, "Font"}},
       {"Subtype", {:name, "Type1"}},
       {"BaseFont", {:name, "Helvetica"}}
     ]}
  end

  defp maybe_add_acro_form_entry(pages_num, []),
    do: [{"Type", {:name, "Catalog"}}, {"Pages", {:ref, pages_num, 0}}]

  defp maybe_add_acro_form_entry(pages_num, form_field_allocations) do
    field_refs = {:array, Enum.map(form_field_allocations, &{:ref, &1.field_obj_num, 0})}

    acro_form =
      {:dict,
       [
         {"Fields", field_refs},
         {"DA", {:string, "/Helv 12 Tf 0 g"}},
         {"DR",
          {:dict,
           [
             {"Font",
              {:dict,
               [
                 {"Helv", helvetica_font_dict()}
               ]}}
           ]}}
       ]}

    [
      {"Type", {:name, "Catalog"}},
      {"Pages", {:ref, pages_num, 0}},
      {"AcroForm", acro_form}
    ]
  end

  defp maybe_add_embedded_files_entries(entries, []), do: entries

  defp maybe_add_embedded_files_entries(entries, embedded_file_allocations) do
    names =
      embedded_file_allocations
      |> Enum.flat_map(fn allocation ->
        [
          {:string, allocation.embedded_file.filename},
          {:ref, allocation.file_spec_obj_num, 0}
        ]
      end)

    entries ++
      [
        {"Names",
         {:dict,
          [
            {"EmbeddedFiles", {:dict, [{"Names", {:array, names}}]}}
          ]}},
        {"AF", {:array, Enum.map(embedded_file_allocations, &{:ref, &1.file_spec_obj_num, 0})}}
      ]
  end

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

  defp encode_pdf_name(name) do
    name
    |> to_string()
    |> String.to_charlist()
    |> Enum.map(fn char ->
      if char in ?A..?Z or char in ?a..?z or char in ?0..?9 or char in [?-, ?_, ?.] do
        <<char>>
      else
        "#" <> String.upcase(Integer.to_string(char, 16) |> String.pad_leading(2, "0"))
      end
    end)
    |> IO.iodata_to_binary()
  end
end
