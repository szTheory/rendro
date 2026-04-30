defmodule Rendro.FontRegistry do
  @moduledoc """
  Pure data registry for document-owned logical font registrations.

  Public authoring code registers logical names such as `:body` or `:heading`
  against a narrow built-in descriptor. PDF object names and writer resource
  allocation stay private implementation details.
  """

  @default_font :default
  @helvetica_descriptor %{source: :built_in, family: :helvetica}

  @enforce_keys [:fonts, :default_font]
  defstruct fonts: %{@default_font => @helvetica_descriptor}, default_font: @default_font

  @type logical_name :: atom()
  @type built_in_family :: :helvetica
  @type descriptor :: %{
          required(:source) => :built_in,
          required(:family) => built_in_family()
        }

  @type resolve_error ::
          {:unknown_logical_font, logical_name()}
          | {:unsupported_font_reference, term()}

  @type t :: %__MODULE__{
          fonts: %{optional(logical_name()) => descriptor()},
          default_font: logical_name()
        }

  @doc """
  Returns a registry seeded with the built-in Helvetica-compatible default entry.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{fonts: %{@default_font => @helvetica_descriptor}, default_font: @default_font}

  @doc """
  Returns the default logical font name used by new documents.
  """
  @spec default_font() :: logical_name()
  def default_font, do: @default_font

  @doc """
  Registers a logical font name against a supported built-in font descriptor.
  """
  @spec register(t(), logical_name(), keyword()) :: t()
  def register(%__MODULE__{} = registry, logical_name, opts)
      when is_atom(logical_name) and is_list(opts) do
    descriptor =
      opts
      |> Keyword.fetch!(:built_in)
      |> built_in_descriptor()

    %__MODULE__{registry | fonts: Map.put(registry.fonts, logical_name, descriptor)}
  end

  @doc """
  Fetches a registered logical font descriptor.
  """
  @spec fetch(t(), logical_name()) :: {:ok, descriptor()} | :error
  def fetch(%__MODULE__{} = registry, logical_name) when is_atom(logical_name) do
    Map.fetch(registry.fonts, logical_name)
  end

  @doc """
  Sets the registry default to a previously registered logical font name.
  """
  @spec put_default_font(t(), logical_name()) :: t()
  def put_default_font(%__MODULE__{} = registry, logical_name) when is_atom(logical_name) do
    case fetch(registry, logical_name) do
      {:ok, _descriptor} ->
        %__MODULE__{registry | default_font: logical_name}

      :error ->
        raise ArgumentError,
              "unknown logical font #{inspect(logical_name)}; register it before making it default"
    end
  end

  @doc """
  Returns the built-in Helvetica descriptor used by the public compatibility path.
  """
  @spec helvetica() :: descriptor()
  def helvetica, do: @helvetica_descriptor

  @doc """
  Resolves an authored text font reference into one shared built-in descriptor.

  The resolver only supports the registry-backed built-in fonts available in
  Phase 25. It intentionally does not load external files, build fallback
  chains, or expose embedding details.
  """
  @spec resolve(t(), Rendro.Text.font_ref(), logical_name()) ::
          {:ok, descriptor()} | {:error, resolve_error()}
  def resolve(%__MODULE__{} = registry, text_font_ref, document_default_font) do
    with {:ok, logical_name} <- normalize_reference(text_font_ref, document_default_font),
         {:ok, descriptor} <- fetch_descriptor(registry, logical_name) do
      {:ok, descriptor}
    end
  end

  @doc """
  Resolves an authored text font reference into the concrete built-in PDF font
  struct used by deterministic measurement and rendering.
  """
  @spec resolve_pdf_font(t(), Rendro.Text.font_ref(), logical_name()) ::
          {:ok, Rendro.PDF.Font.t()} | {:error, resolve_error()}
  def resolve_pdf_font(%__MODULE__{} = registry, text_font_ref, document_default_font) do
    with {:ok, logical_name} <- normalize_reference(text_font_ref, document_default_font),
         {:ok, descriptor} <- fetch_descriptor(registry, logical_name) do
      {:ok, built_in(descriptor, logical_name)}
    end
  end

  @doc """
  Converts a resolved built-in descriptor into the PDF font definition used by
  downstream measurement and rendering stages.
  """
  @spec built_in(descriptor()) :: Rendro.PDF.Font.t()
  def built_in(%{source: :built_in, family: :helvetica}), do: Rendro.PDF.Font.helvetica()

  @spec built_in(descriptor(), logical_name()) :: Rendro.PDF.Font.t()
  def built_in(%{source: :built_in, family: :helvetica}, logical_name) do
    %Rendro.PDF.Font{Rendro.PDF.Font.helvetica() | name: resource_name(logical_name)}
  end

  defp built_in_descriptor(:helvetica), do: helvetica()
  defp built_in_descriptor(:Helvetica), do: helvetica()
  defp built_in_descriptor("Helvetica"), do: helvetica()
  defp built_in_descriptor("helvetica"), do: helvetica()

  defp built_in_descriptor(built_in) do
    raise ArgumentError,
          "unsupported built_in font #{inspect(built_in)}; only :helvetica compatibility is available in Phase 25"
  end

  defp normalize_reference(font, _document_default_font) when is_atom(font), do: {:ok, font}
  defp normalize_reference(font, document_default_font) when font in ["Helvetica", "helvetica"],
    do: {:ok, document_default_font}

  defp normalize_reference(font, _document_default_font),
    do: {:error, {:unsupported_font_reference, font}}

  defp fetch_descriptor(registry, logical_name) do
    case fetch(registry, logical_name) do
      {:ok, descriptor} -> {:ok, descriptor}
      :error -> {:error, {:unknown_logical_font, logical_name}}
    end
  end

  defp resource_name(logical_name) do
    logical_name
    |> Atom.to_string()
    |> String.upcase()
    |> String.replace(~r/[^A-Z0-9]/u, "_")
    |> then(&"F_#{&1}")
  end
end
