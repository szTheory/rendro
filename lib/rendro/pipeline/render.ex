defmodule Rendro.Pipeline.Render do
  @moduledoc false

  alias Rendro.PDF.Writer

  @spec run(Rendro.Document.t()) :: {:ok, binary()} | {:error, term()}
  def run(%Rendro.Document{} = doc) do
    opts = Map.get(doc.options, :render, [])
    policies = Map.get(doc.options, :policies, [])
    max_bytes = Keyword.get(policies, :max_bytes)

    case Writer.render(doc, opts) do
      {:ok, pdf_binary} ->
        if max_bytes && byte_size(pdf_binary) > max_bytes do
          {:error, Rendro.Error.from_stage(:render, :max_bytes_exceeded, %{})}
        else
          {:ok, pdf_binary}
        end
    end
  end
end
