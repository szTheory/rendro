defmodule Rendro.Pipeline.Build do
  @moduledoc """
  Validates and normalizes a Document struct for the render pipeline.
  """

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Rendro.Document{pages: pages} = doc) when is_list(pages) do
    case validate(doc) do
      :ok -> {:ok, normalize(doc)}
      {:error, _} = err -> err
    end
  end

  def run(_), do: {:error, :invalid_document}

  defp validate(%Rendro.Document{pages: pages, content: content, sections: sections}) do
    cond do
      pages != [] -> validate_pages(pages)
      content != [] -> validate_content(content)
      sections != [] -> validate_sections(sections)
      true -> {:error, :no_pages}
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

  defp validate_sections(sections) do
    Enum.reduce_while(sections, :ok, fn
      %Rendro.Section{content: content}, :ok ->
        case validate_content(content) do
          :ok -> {:cont, :ok}
          err -> {:halt, err}
        end

      _, :ok ->
        {:halt, {:error, :invalid_content_block}}
    end)
  end

  defp validate_block(%Rendro.Block{}), do: :ok
  defp validate_block(_), do: {:error, :invalid_content_block}

  defp validate_page(%Rendro.Page{width: w, height: h})
       when is_number(w) and w > 0 and is_number(h) and h > 0,
       do: :ok

  defp validate_page(%Rendro.Page{}), do: {:error, :invalid_page_dimensions}
  defp validate_page(_), do: {:error, :invalid_page}

  defp normalize(%Rendro.Document{metadata: nil} = doc) do
    %{doc | metadata: %Rendro.Metadata{}}
  end

  defp normalize(doc), do: doc
end
