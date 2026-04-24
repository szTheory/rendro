defmodule Rendro do
  @moduledoc """
  Pure-Elixir, Phoenix-first PDF/document generation with deterministic layout and pagination.
  """

  alias Rendro.{Block, Document, Metadata, Page, Pipeline, Text}

  @type render_option :: {:output, Path.t()}
  @type render_options :: [render_option()]

  @spec render(Document.t()) :: {:ok, binary()} | {:error, term()}
  def render(%Document{} = doc) do
    Pipeline.run(doc)
  end

  @spec render(Document.t(), render_options()) :: {:ok, binary()} | {:error, term()}
  def render(%Document{} = doc, opts) when is_list(opts) do
    with {:ok, pdf_binary} <- Pipeline.run(doc) do
      case Keyword.get(opts, :output) do
        nil -> {:ok, pdf_binary}
        path -> write_output(pdf_binary, path)
      end
    end
  end

  defp write_output(pdf_binary, path) do
    path |> Path.dirname() |> File.mkdir_p!()
    File.write!(path, pdf_binary)
    {:ok, pdf_binary}
  end

  @spec document(keyword()) :: Document.t()
  def document(attrs \\ []) do
    struct!(Document, attrs)
  end

  @spec page(keyword()) :: Page.t()
  def page(attrs \\ []) do
    struct!(Page, attrs)
  end

  @spec block(Text.t() | term(), keyword()) :: Block.t()
  def block(content, attrs \\ []) do
    struct!(Block, Keyword.put(attrs, :content, content))
  end

  @spec text(String.t(), keyword()) :: Text.t()
  def text(content, attrs \\ []) do
    struct!(Text, Keyword.put(attrs, :content, content))
  end

  @spec metadata(keyword()) :: Metadata.t()
  def metadata(attrs \\ []) do
    struct!(Metadata, attrs)
  end
end
