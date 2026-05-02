defmodule Rendro.Pipeline.Build do
  @moduledoc """
  Validates and normalizes a Document struct for the render pipeline.
  """

  alias Rendro.FontRegistry

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Rendro.Document{pages: pages} = doc) when is_list(pages) do
    with {:ok, doc} <- preflight_font_registry(doc),
         :ok <- validate(doc) do
      {:ok, normalize(doc)}
    else
      {:error, _} = err -> err
    end
  end

  def run(_), do: {:error, :invalid_document}

  defp validate(
         %Rendro.Document{
           pages: pages,
           content: content,
           sections: sections,
           font_registry: registry,
           default_font: default_font
         } = doc
       ) do
    cond do
      not default_font_registered?(registry, default_font) ->
        {:error, {:unknown_default_font, default_font}}

      pages != [] ->
        with :ok <- validate_pages(pages),
             :ok <- validate_pages_fonts(doc, pages) do
          :ok
        end

      content != [] ->
        with :ok <- validate_content(content),
             :ok <- validate_content_fonts(doc, content) do
          :ok
        end

      sections != [] ->
        validate_sections(doc, sections)

      true ->
        {:error, :no_pages}
    end
  end

  defp validate_pages(pages) do
    Enum.reduce_while(pages, :ok, fn page, :ok ->
      case validate_page(page) do
        :ok -> {:cont, :ok}
        err -> {:halt, err}
      end
    end)
  end

  defp validate_content(content) do
    Enum.reduce_while(content, :ok, fn block, :ok ->
      case validate_block(block) do
        :ok -> {:cont, :ok}
        err -> {:halt, err}
      end
    end)
  end

  defp validate_sections(doc, sections) do
    Enum.reduce_while(sections, :ok, fn
      %Rendro.Section{content: content}, :ok ->
        with :ok <- validate_content(content),
             :ok <- validate_content_fonts(doc, content) do
          {:cont, :ok}
        else
          err -> {:halt, err}
        end

      _, :ok ->
        {:halt, {:error, :invalid_content_block}}
    end)
  end

  defp validate_pages_fonts(doc, pages) do
    Enum.reduce_while(pages, :ok, fn %Rendro.Page{blocks: blocks}, :ok ->
      case validate_content_fonts(doc, blocks) do
        :ok -> {:cont, :ok}
        err -> {:halt, err}
      end
    end)
  end

  defp validate_content_fonts(doc, content) do
    Enum.reduce_while(content, :ok, fn block, :ok ->
      case validate_block_fonts(doc, block) do
        :ok -> {:cont, :ok}
        err -> {:halt, err}
      end
    end)
  end

  defp validate_block_fonts(
         %Rendro.Document{font_registry: registry, default_font: default_font},
         %Rendro.Block{content: %Rendro.Text{font: font}}
       ) do
    case FontRegistry.resolve_pdf_font(registry, font, default_font) do
      {:ok, _font} ->
        :ok

      {:error, {:unknown_logical_font, logical_name}} ->
        {:error, {:unknown_text_font, logical_name}}

      {:error, {:unsupported_font_reference, font_ref}} ->
        {:error, {:invalid_text_font, font_ref}}

      {:error, {:invalid_embedded_font, _details} = reason} ->
        {:error, reason}
    end
  end

  defp validate_block_fonts(doc, %Rendro.Block{content: %Rendro.Table{} = table}) do
    with :ok <- validate_table_row_fonts(doc, table.header),
         :ok <- validate_table_rows_fonts(doc, table.rows) do
      :ok
    end
  end

  defp validate_block_fonts(_doc, %Rendro.Block{}), do: :ok

  defp validate_table_rows_fonts(doc, rows) do
    Enum.reduce_while(rows, :ok, fn row, :ok ->
      case validate_table_row_fonts(doc, row) do
        :ok -> {:cont, :ok}
        err -> {:halt, err}
      end
    end)
  end

  defp validate_table_row_fonts(_doc, nil), do: :ok

  defp validate_table_row_fonts(doc, row) do
    Enum.reduce_while(row, :ok, fn cell, :ok ->
      case validate_table_cell_font(doc, cell) do
        :ok -> {:cont, :ok}
        err -> {:halt, err}
      end
    end)
  end

  defp validate_table_cell_font(doc, %Rendro.Block{} = block),
    do: validate_block_fonts(doc, block)

  defp validate_table_cell_font(_doc, _cell), do: :ok

  defp default_font_registered?(registry, default_font) do
    case FontRegistry.fetch(registry, default_font) do
      {:ok, _descriptor} ->
        true

      :error ->
        false
    end
  end

  defp validate_block(%Rendro.Block{}), do: :ok
  defp validate_block(_), do: {:error, :invalid_content_block}

  defp validate_page(%Rendro.Page{width: w, height: h})
       when is_number(w) and w > 0 and is_number(h) and h > 0,
       do: :ok

  defp validate_page(%Rendro.Page{}), do: {:error, :invalid_page_dimensions}
  defp validate_page(_), do: {:error, :invalid_page}

  defp preflight_font_registry(%Rendro.Document{font_registry: registry} = doc) do
    case FontRegistry.preflight(registry) do
      {:ok, preflighted_registry} ->
        {:ok, %{doc | font_registry: preflighted_registry}}

      {:error, _} = error ->
        error
    end
  end

  defp normalize(%Rendro.Document{metadata: nil} = doc) do
    %{doc | metadata: %Rendro.Metadata{}}
  end

  defp normalize(doc), do: doc
end
