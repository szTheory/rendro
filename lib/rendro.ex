defmodule Rendro do
  @moduledoc """
  Pure-Elixir, Phoenix-first PDF/document generation with deterministic layout and pagination.
  """

  alias Rendro.{Block, Document, Metadata, Page, Pipeline, Table, Text}

  @type render_option :: {:output, Path.t()} | {:deterministic, boolean()}
  @type render_options :: [render_option()]

  @spec render(Document.t()) :: {:ok, binary()} | {:error, Rendro.Error.t()}
  def render(%Document{} = doc) do
    Pipeline.run(doc)
  end

  @spec render(Document.t(), render_options()) :: {:ok, binary()} | {:error, Rendro.Error.t()}
  def render(%Document{} = doc, opts) when is_list(opts) do
    render_opts =
      if Keyword.get(opts, :deterministic, false),
        do: [deterministic: true],
        else: []

    doc = put_in(doc.options[:render], render_opts)

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

  @doc """
  Creates a fixed-position document from a list of pages.
  """
  @spec fixed([Page.t()], keyword()) :: Document.t()
  def fixed(pages, opts \\ []) do
    document(Keyword.put(opts, :pages, pages))
  end

  @doc """
  Creates a flow document from a list of content blocks.
  """
  @spec flow([Block.t()], keyword()) :: Document.t()
  def flow(content, opts \\ []) do
    document(Keyword.put(opts, :content, content))
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

  @spec table([Table.row()], keyword()) :: Table.t()
  def table(rows, attrs \\ []) do
    struct!(Table, Keyword.put(attrs, :rows, rows))
  end
end
