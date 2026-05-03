defmodule Rendro.Pipeline.Compose do
  @moduledoc false

  alias Rendro.{Document, PageTemplate, Region, Section}

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Document{pages: pages, content: content, header: header, footer: footer} = doc) do
    composed_pages = Enum.map(pages, &compose_page/1)
    composed_content = Enum.map(content, &compose_block/1)
    composed_header = Enum.map(header, &compose_block/1)
    composed_footer = Enum.map(footer, &compose_block/1)

    doc = %{
      doc
      | pages: composed_pages,
        content: composed_content,
        header: composed_header,
        footer: composed_footer
    }

    {:ok, normalize_flow_layout(doc)}
  end

  defp compose_page(%Rendro.Page{blocks: blocks} = page) do
    composed_blocks = Enum.map(blocks, &compose_block/1)
    %{page | blocks: composed_blocks}
  end

  defp compose_block(%Rendro.Block{content: %Rendro.Table{} = table} = block) do
    normalized_header = if table.header, do: normalize_row(table.header), else: nil
    normalized_rows = Enum.map(table.rows, &normalize_row/1)
    %{block | content: %{table | header: normalized_header, rows: normalized_rows}}
  end

  defp compose_block(block), do: block

  defp normalize_row(row) do
    Enum.map(row, fn
      %Rendro.Block{} = b -> b
      content when is_binary(content) -> Rendro.block(Rendro.text(content))
      other -> Rendro.block(other)
    end)
  end

  defp normalize_flow_layout(%Document{pages: [_ | _]} = doc), do: doc

  defp normalize_flow_layout(%Document{} = doc) do
    template = resolve_template(doc)
    region_map = template.regions |> Enum.map(&{&1.name, &1}) |> Map.new()

    entries =
      [
        %{name: :content, region: :body, blocks: doc.content, page_template: doc.page_template},
        Enum.with_index(doc.sections, 1)
        |> Enum.map(fn {section, index} -> normalize_section(section, index) end)
      ]
      |> List.flatten()

    body_blocks = blocks_for_region(entries, :body)
    header_blocks = doc.header ++ blocks_for_region(entries, :header)
    footer_blocks = doc.footer ++ blocks_for_region(entries, :footer)

    region_blocks =
      Enum.reduce(entries, %{}, fn entry, acc ->
        Map.update(acc, entry.region, entry.blocks, &(&1 ++ entry.blocks))
      end)
      |> Map.put_new(:body, body_blocks)
      |> Map.put(:header, header_blocks)
      |> Map.put(:footer, footer_blocks)

    layout = %{
      template: template,
      region_map: region_map,
      body_region: Map.get(region_map, :body, default_body_region(template)),
      header_region: Map.get(region_map, :header),
      footer_region: Map.get(region_map, :footer),
      region_blocks: region_blocks,
      entries: entries
    }

    put_in(doc.options[:layout], layout)
    |> Map.put(:content, body_blocks)
    |> Map.put(:header, header_blocks)
    |> Map.put(:footer, footer_blocks)
  end

  defp normalize_section(%Section{} = section, index) do
    %{
      name: section.name || :"section_#{index}",
      region: section.region || :body,
      blocks: Enum.map(section.content, &compose_block/1),
      page_template: section.page_template
    }
  end

  defp resolve_template(%Document{page_templates: [], page_template: nil}), do: %PageTemplate{}

  defp resolve_template(%Document{page_templates: [], page_template: name}),
    do: %PageTemplate{name: name}

  defp resolve_template(%Document{page_templates: templates, page_template: nil}) do
    List.first(templates) || %PageTemplate{}
  end

  defp resolve_template(%Document{page_templates: templates, page_template: name}) do
    Enum.find(templates, &(&1.name == name)) || %PageTemplate{name: name}
  end

  defp blocks_for_region(entries, region_name) do
    entries
    |> Enum.filter(&(&1.region == region_name))
    |> Enum.flat_map(& &1.blocks)
  end

  defp default_body_region(%PageTemplate{} = template) do
    %Region{
      name: :body,
      role: :body,
      anchor: :flow,
      x: template.margin_left,
      y: template.margin_top,
      width: template.width - template.margin_left - template.margin_right,
      height: template.height - template.margin_top - template.margin_bottom
    }
  end
end
