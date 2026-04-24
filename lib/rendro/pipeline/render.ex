defmodule Rendro.Pipeline.Render do
  @moduledoc """
  Converts a paginated document into PDF binary via the Writer.
  """

  alias Rendro.PDF.Writer

  @spec run(Rendro.Document.t()) :: {:ok, binary()} | {:error, term()}
  def run(%Rendro.Document{} = doc) do
    opts = Map.get(doc.options, :render, [])
    Writer.render(doc, opts)
  end
end
