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

  defp validate(%Rendro.Document{pages: []}), do: {:error, :no_pages}

  defp validate(%Rendro.Document{pages: pages}) do
    Enum.reduce_while(pages, :ok, fn page, :ok ->
      case validate_page(page) do
        :ok -> {:cont, :ok}
        err -> {:halt, err}
      end
    end)
  end

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
