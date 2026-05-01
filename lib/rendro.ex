defmodule Rendro do
  @moduledoc """
  Pure-Elixir, Phoenix-first PDF/document generation with deterministic layout and pagination.
  """

  alias Rendro.{Block, Document, Metadata, Page, PageTemplate, Pipeline, Region, Section, Table, Text}

  @type render_option :: {:output, Path.t()} | {:deterministic, boolean()}
  @type render_options :: [render_option()]

  @spec render(Document.t(), render_options()) :: {:ok, binary()} | {:error, Rendro.Error.t()}
  def render(%Document{} = doc, opts \\ []) when is_list(opts) do
    case render_with_diagnostics(doc, opts) do
      {:ok, pdf_binary, _doc} -> {:ok, pdf_binary}
      error -> error
    end
  end

  @doc """
  Renders the document and returns the binary along with the fully populated document struct.
  Useful for inspecting layout or reading populated diagnostics.

  `final_doc.diagnostics` is a list of user-inspectable structured maps. Stable
  common keys such as `:level` and `:type` are present on every entry, while
  event-specific optional keys may include `:message`, `:page_index`, `:reason`,
  and `:keep_rule`. This is the developer-facing layout-debug surface; telemetry
  remains the operational span surface.
  """
  @spec render_with_diagnostics(Document.t(), render_options()) ::
          {:ok, binary(), Document.t()} | {:error, Rendro.Error.t()}
  def render_with_diagnostics(%Document{} = doc, opts \\ []) when is_list(opts) do
    render_opts =
      if Keyword.get(opts, :deterministic, false),
        do: [deterministic: true],
        else: []

    doc = put_in(doc.options[:render], render_opts)

    with {:ok, pdf_binary, doc} <- Pipeline.run_with_diagnostics(doc) do
      case Keyword.get(opts, :output) do
        nil -> {:ok, pdf_binary, doc}
        path ->
          {:ok, _} = write_output(pdf_binary, path)
          {:ok, pdf_binary, doc}
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

  @doc """
  Registers a logical font name on a document.
  """
  @spec register_font(Document.t(), Rendro.FontRegistry.logical_name(), keyword()) :: Document.t()
  def register_font(%Document{} = doc, logical_name, opts)
      when is_atom(logical_name) and is_list(opts) do
    Document.register_font(doc, logical_name, opts)
  end

  @doc """
  Sets the default logical font for a document.
  """
  @spec put_default_font(Document.t(), Rendro.FontRegistry.logical_name()) :: Document.t()
  def put_default_font(%Document{} = doc, logical_name) when is_atom(logical_name) do
    Document.put_default_font(doc, logical_name)
  end

  @doc """
  Registers an explicit embedded font source on a document.
  """
  @spec register_embedded_font(
          Document.t(),
          Rendro.FontRegistry.logical_name(),
          {:path, Path.t()} | {:binary, binary()}
        ) :: Document.t()
  def register_embedded_font(%Document{} = doc, logical_name, source)
      when is_atom(logical_name) do
    Document.register_embedded_font(doc, logical_name, source)
  end

  @doc """
  Registers a four-variant embedded font family on a document.
  """
  @spec register_embedded_font_family(
          Document.t(),
          Rendro.FontRegistry.logical_name(),
          %{required(Rendro.FontRegistry.embedded_variant()) => {:path, Path.t()} | {:binary, binary()}}
        ) :: Document.t()
  def register_embedded_font_family(%Document{} = doc, family_name, variants)
      when is_atom(family_name) and is_map(variants) do
    Document.register_embedded_font_family(doc, family_name, variants)
  end

  @spec page(keyword()) :: Page.t()
  def page(attrs \\ []) do
    struct!(Page, attrs)
  end

  @spec page_template(keyword()) :: PageTemplate.t()
  def page_template(attrs \\ []) do
    struct!(PageTemplate, attrs)
  end

  @spec region(keyword()) :: Region.t()
  def region(attrs \\ []) do
    struct!(Region, attrs)
  end

  @spec section(keyword()) :: Section.t()
  def section(attrs \\ []) do
    struct!(Section, attrs)
  end

  @spec block(Text.t() | term(), keyword()) :: Block.t()
  def block(content, attrs \\ []) do
    struct!(Block, Keyword.put(attrs, :content, content))
  end

  @spec text(String.t(), keyword()) :: Text.t()
  def text(content, attrs \\ []) do
    attrs
    |> normalize_text_attrs()
    |> Keyword.put(:content, content)
    |> then(&struct!(Text, &1))
  end

  @spec metadata(keyword()) :: Metadata.t()
  def metadata(attrs \\ []) do
    struct!(Metadata, attrs)
  end

  @spec table([Table.row()], keyword()) :: Table.t()
  def table(rows, attrs \\ []) do
    if Keyword.has_key?(attrs, :width) or Keyword.has_key?(attrs, :border) do
      raise ArgumentError, "Rendro.table/2 no longer supports :width or :border. Use explicit block width and table :columns rules instead."
    end

    attrs
    |> normalize_table_attrs()
    |> Keyword.put(:rows, rows)
    |> then(&struct!(Table, &1))
  end

  defp normalize_table_attrs(attrs) do
    case Keyword.get(attrs, :split_policy, :row_atomic) do
      :row_atomic ->
        Keyword.put(attrs, :split_policy, :row_atomic)

      :atomic ->
        Keyword.put(attrs, :split_policy, :row_atomic)

      split_policy ->
        raise ArgumentError,
              "Rendro.table/2 only supports split_policy: :row_atomic" <>
                " (or temporary alias :atomic); got: #{inspect(split_policy)}"
    end
  end

  defp normalize_text_attrs(attrs) do
    case Keyword.fetch(attrs, :font) do
      {:ok, font} -> Keyword.put(attrs, :font, Text.normalize_font(font))
      :error -> attrs
    end
  end
end
