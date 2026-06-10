defmodule Rendro do
  @moduledoc """
  Pure-Elixir, Phoenix-first PDF/document generation with deterministic layout and pagination.
  """
  @moduledoc tags: [:stable]

  alias Rendro.{
    Artifact,
    Block,
    Document,
    FormField,
    Link,
    Metadata,
    Page,
    PageTemplate,
    Protect,
    Pipeline,
    Region,
    Section,
    Sign,
    Table,
    Text
  }

  @signature_rejection_attrs [
    :reason,
    :location,
    :contact,
    :signing_date,
    :lock,
    :seed_value,
    :certification,
    :filter,
    :subfilter,
    :byte_range,
    :contents,
    :reference
  ]

  @type render_option ::
          {:output, Path.t()} | {:deterministic, boolean()} | {:shaper, module()}
  @type render_options :: [render_option()]

  @spec render(Document.t(), render_options()) :: {:ok, binary()} | {:error, Rendro.Error.t()}
  def render(%Document{} = doc, opts \\ []) when is_list(opts) do
    case render_with_diagnostics(doc, opts) do
      {:ok, pdf_binary, _doc} -> {:ok, pdf_binary}
      error -> error
    end
  end

  @doc """
  Renders the document and returns a `Rendro.Artifact` which contains the PDF
  binary, a deterministic hash, diagnostics, and metadata.
  """
  @spec render_to_artifact(Document.t(), render_options()) ::
          {:ok, Artifact.t()} | {:error, Rendro.Error.t()}
  def render_to_artifact(%Document{} = doc, opts \\ []) when is_list(opts) do
    case render_with_diagnostics(doc, opts) do
      {:ok, pdf_binary, final_doc} ->
        metadata = %{
          deterministic: Keyword.get(opts, :deterministic, false)
        }

        {:ok, Artifact.new(pdf_binary, final_doc, metadata)}

      error ->
        error
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

    # Per-render shaper override (D-01). Precedence at the shaping seam:
    # per-render opt > app config (:rendro, :shaper) > Shaper.Simple default.
    render_opts =
      case Keyword.fetch(opts, :shaper) do
        {:ok, shaper} when is_atom(shaper) and not is_nil(shaper) ->
          Keyword.put(render_opts, :shaper, shaper)

        _ ->
          render_opts
      end

    doc = put_in(doc.options[:render], render_opts)

    with {:ok, pdf_binary, doc} <- Pipeline.run_with_diagnostics(doc) do
      case Keyword.get(opts, :output) do
        nil ->
          {:ok, pdf_binary, doc}

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
  Registers a document-level embedded file on a document.
  """
  @spec register_embedded_file(
          Document.t(),
          atom(),
          {:path, Path.t()} | {:binary, binary()},
          keyword()
        ) :: Document.t()
  def register_embedded_file(%Document{} = doc, logical_name, source, metadata)
      when is_atom(logical_name) and is_list(metadata) do
    Document.register_embedded_file(doc, logical_name, source, metadata)
  end

  @doc """
  Registers a four-variant embedded font family on a document.
  """
  @spec register_embedded_font_family(
          Document.t(),
          Rendro.FontRegistry.logical_name(),
          %{
            required(Rendro.FontRegistry.embedded_variant()) =>
              {:path, Path.t()} | {:binary, binary()}
          }
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

  @spec page_number(keyword()) :: Block.t()
  def page_number(opts \\ []) do
    format = Keyword.get(opts, :format, "Page {{page_number}} of {{total_pages}}")
    text_opts = Keyword.drop(opts, [:format])
    block(text(format, text_opts))
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

  @spec path([term()], keyword()) :: Block.t()
  def path(ops, attrs \\ []) do
    attrs
    |> normalize_path_attrs()
    |> Keyword.put(:ops, ops)
    |> then(&struct!(Rendro.Path, &1))
    |> then(&struct!(Block, content: &1))
  end

  @spec form_field(String.t(), String.t(), keyword()) :: Block.t()
  def form_field(name, value \\ "", attrs \\ []) do
    type = Keyword.get(attrs, :type, :text)
    {signature_rejections, attrs} = extract_signature_rejections(type, attrs)

    {field_attrs, block_attrs} =
      Keyword.split(attrs, [:font, :size, :type, :checked, :group, :export_value])

    field_attrs =
      maybe_put_signature_rejections(field_attrs, type, signature_rejections)

    field = struct!(FormField, Keyword.merge(field_attrs, name: name, value: value))
    struct!(Block, Keyword.put(block_attrs, :content, field))
  end

  @spec signature_field(String.t(), keyword()) :: Block.t()
  def signature_field(name, attrs \\ []) do
    form_field(name, "", Keyword.put(attrs, :type, :signature))
  end

  @doc """
  Wraps exactly one authored block with a curated external URI or internal page target.
  """
  @spec link(Block.t(), keyword()) :: Block.t()
  def link(%Block{} = block, opts) when is_list(opts) do
    %Block{block | content: %Link{content: block.content, target: normalize_link_target(opts)}}
  end

  @doc """
  Renders the document to an artifact and then applies the configured
  protection adapter.
  """
  @spec render_protected(Document.t(), render_options(), keyword()) ::
          {:ok, Artifact.t()} | {:error, Rendro.Error.t()}
  def render_protected(%Document{} = doc, render_opts \\ [], protect_opts)
      when is_list(render_opts) and is_list(protect_opts) do
    with {:ok, artifact} <- render_to_artifact(doc, render_opts) do
      Protect.password(artifact, protect_opts)
    end
  end

  @doc """
  Renders the document to an artifact and then applies the configured
  signing adapter.
  """
  @spec render_signed(Document.t(), render_options(), keyword()) ::
          {:ok, Artifact.t()} | {:error, Rendro.Error.t()}
  def render_signed(%Document{} = doc, render_opts \\ [], sign_opts)
      when is_list(render_opts) and is_list(sign_opts) do
    with {:ok, artifact} <- render_to_artifact(doc, render_opts) do
      Sign.sign(artifact, sign_opts)
    end
  end

  @spec metadata(keyword()) :: Metadata.t()
  def metadata(attrs \\ []) do
    struct!(Metadata, attrs)
  end

  @spec table([Table.row()], keyword()) :: Table.t()
  def table(rows, attrs \\ []) do
    if Keyword.has_key?(attrs, :width) or Keyword.has_key?(attrs, :border) do
      raise ArgumentError,
            "Rendro.table/2 no longer supports :width or :border. Use explicit block width and table :columns rules instead."
    end

    attrs
    |> normalize_table_attrs()
    |> Keyword.put(:rows, rows)
    |> then(&struct!(Table, &1))
  end

  @doc """
  Returns `{header_height, row_heights}` (in points) for `rows` laid out as a
  `Rendro.table/2` of total `width`, using `document`'s font metrics.

  This is a **read-only** projection of the engine's OWN table measurement: it
  builds an ephemeral table, measures it through the same private measurement
  logic the paginator uses, and returns the geometry. It does not paginate,
  render, cache, or mutate any engine state, so PAGE-04 single-pass behavior is
  unchanged.

  It exists so recipes can chunk transaction rows by the engine's actual row
  heights — rather than a recipe-local estimate that would drift into
  `:content_overflow` — and therefore place page breaks and carried/brought-forward
  rows on the correct pages.

  `table_opts` are forwarded to `Rendro.table/2` (e.g. `:header`, `:columns`).
  Raises `ArgumentError` if the table cannot be measured (e.g. unsupported glyph).
  """
  @spec measure_rows([Table.row()], number(), Document.t(), keyword()) ::
          {number(), [number()]}
  def measure_rows(rows, width, %Document{} = document, table_opts \\ [])
      when is_list(rows) and is_number(width) and is_list(table_opts) do
    case Pipeline.Measure.measure_rows(document, rows, width, table_opts) do
      {:ok, {header_height, row_heights}} ->
        {header_height, row_heights}

      {:error, reason} ->
        raise ArgumentError,
              "Rendro.measure_rows/4 could not measure the table: #{inspect(reason)}"
    end
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

  defp normalize_path_attrs(attrs) do
    attrs
    |> validate_color_attr(:stroke)
    |> validate_color_attr(:fill)
  end

  defp validate_color_attr(attrs, key) do
    case Keyword.get(attrs, key) do
      nil ->
        attrs

      {_r, _g, _b} = color ->
        case Rendro.Color.validate(color) do
          :ok -> attrs
          {:error, msg} -> raise ArgumentError, msg
        end

      %{color: color} = _map ->
        case Rendro.Color.validate(color) do
          :ok -> attrs
          {:error, msg} -> raise ArgumentError, msg
        end

      _other ->
        attrs
    end
  end

  defp extract_signature_rejections(:signature, attrs) do
    Keyword.split(attrs, @signature_rejection_attrs)
  end

  defp extract_signature_rejections(_type, attrs), do: {[], attrs}

  defp maybe_put_signature_rejections(field_attrs, :signature, signature_rejections) do
    Keyword.put(field_attrs, :signature_rejections, signature_rejections)
  end

  defp maybe_put_signature_rejections(field_attrs, _type, _signature_rejections), do: field_attrs

  defp normalize_text_attrs(attrs) do
    case Keyword.fetch(attrs, :font) do
      {:ok, font} -> Keyword.put(attrs, :font, Text.normalize_font(font))
      :error -> attrs
    end
  end

  defp normalize_link_target(opts) do
    target_opts = Keyword.take(opts, [:uri, :page])
    unsupported_keys = opts |> Keyword.keys() |> Kernel.--([:uri, :page])

    cond do
      unsupported_keys != [] ->
        raise ArgumentError,
              "Rendro.link/2 received unsupported link options: #{inspect(unsupported_keys)}"

      Keyword.has_key?(target_opts, :uri) and Keyword.has_key?(target_opts, :page) ->
        raise ArgumentError, "Rendro.link/2 requires exactly one of :uri or :page"

      Keyword.has_key?(target_opts, :uri) ->
        {:uri, Keyword.fetch!(target_opts, :uri)}

      Keyword.has_key?(target_opts, :page) ->
        {:page, Keyword.fetch!(target_opts, :page)}

      true ->
        raise ArgumentError, "Rendro.link/2 requires exactly one of :uri or :page"
    end
  end
end
