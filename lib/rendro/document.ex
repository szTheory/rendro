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
  """

  @enforce_keys []
  defstruct pages: [],
            content: [],
            page_templates: [],
            page_template: nil,
            sections: [],
            diagnostics: [],
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
          header: [Rendro.Block.t()],
          footer: [Rendro.Block.t()],
          metadata: Rendro.Metadata.t(),
          options: %{optional(atom()) => term()}
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
