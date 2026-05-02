defmodule Rendro.Document do
  @moduledoc """
  Top-level document: pages, content (flow), metadata, and rendering options.

  ## Pipeline Builder API

  Documents can be composed dynamically using a pipeable builder API, mirroring
  the ergonomics of `Plug.Conn` or `Ecto.Changeset`:

      Rendro.Document.new()
      |> Rendro.Document.put_metadata(%Rendro.Metadata{title: "Invoice"})
      |> Rendro.Document.add_template(page_template)
      |> Rendro.Document.set_template(:invoice)
      |> Rendro.Document.add_section(section)
      |> Rendro.Document.put_options(%{deterministic: true})

  This supports dynamic, conditional assembly during a request cycle while
  keeping each transformation a pure function over the `%Rendro.Document{}` struct.

  ## Diagnostics

  `diagnostics` is the developer-facing layout-debug surface for non-fatal
  pagination and measurement events. Entries stay map-based: stable common keys
  such as `:level` and `:type` are always present, event-specific optional keys
  such as `:message`, `:page_index`, `:reason`, and `:keep_rule` may appear, and
  future additive keys are allowed.

  ## Typography & Honest I18n

  Documents own the logical font registry used by authored content. The default
  registry keeps a narrow Helvetica-compatible path available out of the box
  while letting callers register additional logical names as pure data.

  Rendro embraces an "honest I18n" model: text crossing into unsupported scripts 
  (e.g., RTL, complex shaping) or unmapped glyphs will not silently degrade into 
  squares or overlapping text. Instead, the rendering pipeline will explicitly trap 
  the boundary and return an actionable `Rendro.Error`. Callers can configure 
  fallback font chains when registering fonts to automatically substitute missing 
  glyphs.
  """

  @enforce_keys []
  defstruct pages: [],
            content: [],
            page_templates: [],
            page_template: nil,
            sections: [],
            diagnostics: [],
            font_registry: Rendro.FontRegistry.new(),
            default_font: Rendro.FontRegistry.default_font(),
            asset_registry: Rendro.AssetRegistry.new(),
            header: [],
            footer: [],
            metadata: %Rendro.Metadata{},
            options: %{}

  @type t :: %__MODULE__{
          pages: [Rendro.Page.t()],
          content: [Rendro.Block.t()],
          page_templates: [Rendro.PageTemplate.t()],
          page_template: atom() | String.t() | nil,
          sections: [Rendro.Section.t()],
          diagnostics: [map()],
          font_registry: Rendro.FontRegistry.t(),
          default_font: Rendro.FontRegistry.logical_name(),
          asset_registry: Rendro.AssetRegistry.t(),
          header: [Rendro.Block.t()],
          footer: [Rendro.Block.t()],
          metadata: Rendro.Metadata.t(),
          options: %{optional(atom()) => term()}
        }

  @typedoc """
  Developer-facing layout-debug structured maps emitted during render.

  Stable common keys such as `:level` and `:type` are present on every entry.
  Event-specific optional keys such as `:message`, `:page_index`, `:reason`,
  and `:keep_rule` may appear depending on the pagination event. Future additive
  keys are allowed so callers should match only on the fields they need.
  """
  @type diagnostic :: %{
          required(:level) => atom(),
          required(:type) => atom(),
          optional(:message) => String.t(),
          optional(:page_index) => non_neg_integer(),
          optional(:reason) => term(),
          optional(:keep_rule) => atom(),
          optional(atom()) => term()
        }

  @doc """
  Creates a new empty `%Rendro.Document{}` struct.

  ## Examples

      iex> Rendro.Document.new()
      %Rendro.Document{}

  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Creates a new `%Rendro.Document{}` struct with the given keyword options.

  ## Examples

      iex> Rendro.Document.new(metadata: %Rendro.Metadata{title: "Invoice"})
      %Rendro.Document{metadata: %Rendro.Metadata{title: "Invoice"}}

  """
  @spec new(keyword()) :: t()
  def new(opts) when is_list(opts), do: struct!(__MODULE__, opts)

  @doc """
  Updates the document metadata.

  ## Examples

      iex> doc = Rendro.Document.new()
      iex> Rendro.Document.put_metadata(doc, %Rendro.Metadata{title: "Invoice"})
      %Rendro.Document{metadata: %Rendro.Metadata{title: "Invoice"}}

  """
  @spec put_metadata(t(), Rendro.Metadata.t()) :: t()
  def put_metadata(%__MODULE__{} = doc, %Rendro.Metadata{} = metadata) do
    %__MODULE__{doc | metadata: metadata}
  end

  @doc """
  Registers a logical font name on the document's owned font registry.

  ## Examples

      iex> Rendro.Document.new()
      ...> |> Rendro.Document.register_font(:body, built_in: :helvetica)
      %Rendro.Document{
        font_registry: %Rendro.FontRegistry{
          fonts: %{default: %{source: :built_in, family: :helvetica}, body: %{source: :built_in, family: :helvetica}}
        }
      }

  """
  @spec register_font(t(), Rendro.FontRegistry.logical_name(), keyword()) :: t()
  def register_font(%__MODULE__{} = doc, logical_name, opts)
      when is_atom(logical_name) and is_list(opts) do
    %__MODULE__{
      doc
      | font_registry: Rendro.FontRegistry.register(doc.font_registry, logical_name, opts)
    }
  end

  @doc """
  Registers a logical name against an explicit embedded font source.
  """
  @spec register_embedded_font(
          t(),
          Rendro.FontRegistry.logical_name(),
          {:path, Path.t()} | {:binary, binary()}
        ) :: t()
  def register_embedded_font(%__MODULE__{} = doc, logical_name, source)
      when is_atom(logical_name) do
    %__MODULE__{
      doc
      | font_registry:
          Rendro.FontRegistry.register_embedded(doc.font_registry, logical_name, source)
    }
  end

  @doc """
  Registers a four-variant embedded font family on the document.
  """
  @spec register_embedded_font_family(
          t(),
          Rendro.FontRegistry.logical_name(),
          %{
            required(Rendro.FontRegistry.embedded_variant()) =>
              {:path, Path.t()} | {:binary, binary()}
          }
        ) :: t()
  def register_embedded_font_family(%__MODULE__{} = doc, family_name, variants)
      when is_atom(family_name) and is_map(variants) do
    %__MODULE__{
      doc
      | font_registry:
          Rendro.FontRegistry.register_embedded_family(doc.font_registry, family_name, variants)
    }
  end

  @doc """
  Registers an image asset on the document's owned asset registry.
  """
  @spec register_image(
          t(),
          atom(),
          {:path, Path.t()} | {:binary, binary()}
        ) :: t()
  def register_image(%__MODULE__{} = doc, logical_name, source)
      when is_atom(logical_name) do
    %__MODULE__{
      doc
      | asset_registry:
          Rendro.AssetRegistry.register_image(doc.asset_registry, logical_name, source)
    }
  end

  @doc """
  Sets the document default logical font.

  The logical name must already be registered on the document.
  """
  @spec put_default_font(t(), Rendro.FontRegistry.logical_name()) :: t()
  def put_default_font(%__MODULE__{} = doc, logical_name) when is_atom(logical_name) do
    registry = Rendro.FontRegistry.put_default_font(doc.font_registry, logical_name)
    %__MODULE__{doc | font_registry: registry, default_font: registry.default_font}
  end

  @doc """
  Appends a page template to the document's `page_templates` list.

  ## Examples

      iex> template = %Rendro.PageTemplate{name: :invoice}
      iex> Rendro.Document.new() |> Rendro.Document.add_template(template)
      %Rendro.Document{page_templates: [%Rendro.PageTemplate{name: :invoice}]}

  """
  @spec add_template(t(), Rendro.PageTemplate.t()) :: t()
  def add_template(%__MODULE__{} = doc, %Rendro.PageTemplate{} = template) do
    %__MODULE__{doc | page_templates: doc.page_templates ++ [template]}
  end

  @doc """
  Sets the active page template by name.

  ## Examples

      iex> Rendro.Document.new() |> Rendro.Document.set_template(:invoice)
      %Rendro.Document{page_template: :invoice}

  """
  @spec set_template(t(), atom() | String.t()) :: t()
  def set_template(%__MODULE__{} = doc, name) when is_atom(name) or is_binary(name) do
    %__MODULE__{doc | page_template: name}
  end

  @doc """
  Appends a section to the document's `sections` list.

  ## Examples

      iex> section = %Rendro.Section{name: :body, region: :body}
      iex> Rendro.Document.new() |> Rendro.Document.add_section(section)
      %Rendro.Document{sections: [%Rendro.Section{name: :body, region: :body}]}

  """
  @spec add_section(t(), Rendro.Section.t()) :: t()
  def add_section(%__MODULE__{} = doc, %Rendro.Section{} = section) do
    %__MODULE__{doc | sections: doc.sections ++ [section]}
  end

  @doc """
  Merges the given options map into the document's existing options.

  ## Examples

      iex> Rendro.Document.new()
      iex> |> Rendro.Document.put_options(%{deterministic: true})
      iex> |> Rendro.Document.put_options(%{compress: false})
      %Rendro.Document{options: %{deterministic: true, compress: false}}

  """
  @spec put_options(t(), %{optional(atom()) => term()}) :: t()
  def put_options(%__MODULE__{} = doc, options) when is_map(options) do
    %__MODULE__{doc | options: Map.merge(doc.options, options)}
  end
end
