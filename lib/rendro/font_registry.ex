defmodule Rendro.FontRegistry do
  @moduledoc """
  Pure data registry for document-owned logical font registrations.

  Public authoring code registers logical names such as `:body` or `:heading`
  against a narrow built-in descriptor. PDF object names and writer resource
  allocation stay private implementation details.
  """

  @default_font :default
  @helvetica_descriptor %{source: :built_in, family: :helvetica}
  @embedded_family_variants [:regular, :bold, :italic, :bold_italic]

  @enforce_keys [:fonts, :default_font]
  defstruct fonts: %{@default_font => @helvetica_descriptor}, default_font: @default_font

  @type logical_name :: atom()
  @type built_in_family :: :helvetica
  @type embedded_source_kind :: :path | :binary
  @type embedded_variant :: :regular | :bold | :italic | :bold_italic
  @type embedded_normalized_source ::
          %{
            required(:status) => :ok,
            required(:kind) => embedded_source_kind(),
            required(:bytes) => binary(),
            required(:byte_size) => non_neg_integer()
          }
          | %{
              required(:status) => :error,
              required(:kind) => embedded_source_kind(),
              required(:reason) => term()
            }
  @type built_in_descriptor :: %{
          required(:source) => :built_in,
          required(:family) => built_in_family(),
          optional(:fallbacks) => [logical_name()]
        }
  @type embedded_descriptor :: %{
          required(:source) => :embedded,
          required(:source_kind) => embedded_source_kind(),
          required(:variant) => embedded_variant(),
          required(:source_data) => embedded_normalized_source(),
          optional(:pdf_font) => Rendro.PDF.Font.t(),
          optional(:fallbacks) => [logical_name()]
        }
  @type descriptor :: built_in_descriptor() | embedded_descriptor()

  @type resolve_error ::
          {:unknown_logical_font, logical_name()}
          | {:unsupported_font_reference, term()}
          | {:invalid_embedded_font,
             %{
               required(:logical_name) => logical_name(),
               required(:source_kind) => embedded_source_kind(),
               required(:reason) => term()
             }}

  @type t :: %__MODULE__{
          fonts: %{optional(logical_name()) => descriptor()},
          default_font: logical_name()
        }

  @doc """
  Returns a registry seeded with the built-in Helvetica-compatible default entry.
  """
  @spec new() :: t()
  def new,
    do: %__MODULE__{fonts: %{@default_font => @helvetica_descriptor}, default_font: @default_font}

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

    descriptor =
      case Keyword.fetch(opts, :fallbacks) do
        {:ok, fallbacks} when is_list(fallbacks) -> Map.put(descriptor, :fallbacks, fallbacks)
        _ -> descriptor
      end

    %__MODULE__{registry | fonts: Map.put(registry.fonts, logical_name, descriptor)}
  end

  @doc """
  Registers a logical font name against an explicit embedded font source.
  """
  @spec register_embedded(t(), logical_name(), {:path, Path.t()} | {:binary, binary()}, keyword()) ::
          t()
  def register_embedded(%__MODULE__{} = registry, logical_name, source, opts \\ [])
      when is_atom(logical_name) and is_list(opts) do
    descriptor = embedded_descriptor(source, :regular)

    descriptor =
      case Keyword.fetch(opts, :fallbacks) do
        {:ok, fallbacks} when is_list(fallbacks) -> Map.put(descriptor, :fallbacks, fallbacks)
        _ -> descriptor
      end

    %__MODULE__{registry | fonts: Map.put(registry.fonts, logical_name, descriptor)}
  end

  @doc """
  Registers a narrow four-variant embedded font family.

  The root logical name resolves to the `:regular` face and the helper also
  registers `:<family>_bold`, `:<family>_italic`, and `:<family>_bold_italic`.
  """
  @spec register_embedded_family(
          t(),
          logical_name(),
          %{required(embedded_variant()) => {:path, Path.t()} | {:binary, binary()}}
        ) :: t()
  def register_embedded_family(%__MODULE__{} = registry, family_name, variants)
      when is_atom(family_name) and is_map(variants) do
    validate_embedded_family!(family_name, variants)

    registrations = [
      {family_name, embedded_descriptor(Map.fetch!(variants, :regular), :regular)},
      {variant_logical_name(family_name, :bold),
       embedded_descriptor(Map.fetch!(variants, :bold), :bold)},
      {variant_logical_name(family_name, :italic),
       embedded_descriptor(Map.fetch!(variants, :italic), :italic)},
      {variant_logical_name(family_name, :bold_italic),
       embedded_descriptor(Map.fetch!(variants, :bold_italic), :bold_italic)}
    ]

    %__MODULE__{
      registry
      | fonts:
          Enum.reduce(registrations, registry.fonts, fn {logical_name, descriptor}, fonts ->
            Map.put(fonts, logical_name, descriptor)
          end)
    }
  end

  @doc """
  Fetches a registered logical font descriptor.
  """
  @spec fetch(t(), logical_name()) :: {:ok, descriptor()} | :error
  def fetch(%__MODULE__{} = registry, logical_name) when is_atom(logical_name) do
    Map.fetch(registry.fonts, logical_name)
  end

  @doc """
  Preflights embedded font registrations into cached PDF font descriptors.
  """
  @spec preflight(t()) :: {:ok, t()} | {:error, resolve_error()}
  def preflight(%__MODULE__{} = registry) do
    with :ok <- validate_fallbacks(registry) do
      registry.fonts
      |> Enum.reduce_while({:ok, %{}}, fn {logical_name, descriptor}, {:ok, acc} ->
        case preflight_descriptor(logical_name, descriptor) do
          {:ok, updated_descriptor} ->
            {:cont, {:ok, Map.put(acc, logical_name, updated_descriptor)}}

          {:error, _} = error ->
            {:halt, error}
        end
      end)
      |> case do
        {:ok, fonts} -> {:ok, %__MODULE__{registry | fonts: fonts}}
        {:error, _} = error -> error
      end
    end
  end

  defp validate_fallbacks(registry) do
    Enum.reduce_while(registry.fonts, :ok, fn {logical_name, descriptor}, :ok ->
      fallbacks = Map.get(descriptor, :fallbacks, [])

      case Enum.find(fallbacks, fn fallback -> not Map.has_key?(registry.fonts, fallback) end) do
        nil -> {:cont, :ok}
        missing -> {:halt, {:error, {:missing_fallback_target, missing, logical_name}}}
      end
    end)
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
         {:ok, descriptor} <- fetch_descriptor(registry, logical_name),
         {:ok, pdf_font} <- to_pdf_font(logical_name, descriptor) do
      {:ok, pdf_font}
    end
  end

  @doc """
  Resolves an authored text font reference into a chain of concrete PDF font
  structs, recursively resolving fallbacks.
  """
  @spec resolve_pdf_font_chain(t(), Rendro.Text.font_ref(), logical_name()) ::
          {:ok, [Rendro.PDF.Font.t()]} | {:error, term()}
  def resolve_pdf_font_chain(%__MODULE__{} = registry, text_font_ref, document_default_font) do
    with {:ok, primary_logical_name} <- normalize_reference(text_font_ref, document_default_font) do
      resolve_chain(registry, primary_logical_name, [primary_logical_name], [])
    end
  end

  defp resolve_chain(registry, logical_name, visited, acc) do
    with {:ok, descriptor} <- fetch_descriptor(registry, logical_name),
         {:ok, pdf_font} <- to_pdf_font(logical_name, descriptor) do
      acc = acc ++ [pdf_font]
      fallbacks = Map.get(descriptor, :fallbacks, [])

      # Depth-first or breadth-first? For a simple chain, depth-first (recursing on fallbacks in order).
      # If a font has multiple fallbacks, we iterate through them.
      # To prevent cycle issues and just linearize the chain:
      Enum.reduce_while(fallbacks, {:ok, acc, visited}, fn fallback_name,
                                                           {:ok, current_acc, current_visited} ->
        if fallback_name in current_visited do
          {:halt,
           {:error,
            {:fallback_cycle_detected,
             Enum.reverse([fallback_name | current_visited]) |> Enum.reverse()}}}
        else
          case resolve_chain(
                 registry,
                 fallback_name,
                 [fallback_name | current_visited],
                 current_acc
               ) do
            {:ok, new_acc} -> {:cont, {:ok, new_acc, [fallback_name | current_visited]}}
            {:error, _} = err -> {:halt, err}
          end
        end
      end)
      |> case do
        {:ok, final_acc, _visited} -> {:ok, final_acc}
        {:error, _} = err -> err
      end
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
    %Rendro.PDF.Font{
      Rendro.PDF.Font.helvetica()
      | name: resource_name(logical_name),
        logical_name: logical_name
    }
  end

  @spec variant_logical_name(logical_name(), embedded_variant()) :: logical_name()
  def variant_logical_name(family_name, :regular) when is_atom(family_name), do: family_name

  def variant_logical_name(family_name, variant)
      when is_atom(family_name) and variant in @embedded_family_variants do
    :"#{family_name}_#{variant}"
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

  defp embedded_descriptor(source, variant) when variant in @embedded_family_variants do
    %{
      source: :embedded,
      source_kind: embedded_source_kind!(source),
      variant: variant,
      source_data: normalize_embedded_source(source)
    }
  end

  defp embedded_source_kind!({:path, _path}), do: :path
  defp embedded_source_kind!({:binary, _bytes}), do: :binary

  defp embedded_source_kind!(source) do
    raise ArgumentError,
          "embedded fonts require {:path, path} or {:binary, bytes}; got: #{inspect(source)}"
  end

  defp normalize_embedded_source({:path, path}) when is_binary(path) do
    case File.read(path) do
      {:ok, bytes} ->
        %{status: :ok, kind: :path, bytes: :binary.copy(bytes), byte_size: byte_size(bytes)}

      {:error, reason} ->
        %{status: :error, kind: :path, reason: {:file_read_failed, reason}}
    end
  end

  defp normalize_embedded_source({:binary, bytes}) when is_binary(bytes) do
    copied = :binary.copy(bytes)
    %{status: :ok, kind: :binary, bytes: copied, byte_size: byte_size(copied)}
  end

  defp normalize_embedded_source({:path, path}) do
    raise ArgumentError, "embedded font paths must be binaries; got: #{inspect(path)}"
  end

  defp normalize_embedded_source({:binary, bytes}) do
    raise ArgumentError, "embedded font binary sources must be binaries; got: #{inspect(bytes)}"
  end

  defp validate_embedded_family!(family_name, variants) do
    keys = Map.keys(variants)
    missing = @embedded_family_variants -- keys
    extra = keys -- @embedded_family_variants

    if missing != [] or extra != [] do
      raise Rendro.FontRegistry.EmbeddedFontFamilyError,
        family_name: family_name,
        missing_variants: missing,
        extra_variants: extra,
        provided_kinds: provided_kinds(variants),
        reason: :incomplete_embedded_family
    end
  end

  defp provided_kinds(variants) do
    Map.new(variants, fn {variant, source} -> {variant, embedded_source_kind!(source)} end)
  end

  defp fetch_descriptor(registry, logical_name) do
    case fetch(registry, logical_name) do
      {:ok, descriptor} -> {:ok, descriptor}
      :error -> {:error, {:unknown_logical_font, logical_name}}
    end
  end

  defp preflight_descriptor(_logical_name, %{source: :built_in} = descriptor),
    do: {:ok, descriptor}

  defp preflight_descriptor(
         _logical_name,
         %{source: :embedded, pdf_font: %Rendro.PDF.Font{}} = descriptor
       ),
       do: {:ok, descriptor}

  defp preflight_descriptor(logical_name, %{
         source: :embedded,
         source_kind: source_kind,
         source_data: %{status: :error, reason: reason}
       }) do
    {:error, invalid_embedded_font_error(logical_name, source_kind, reason)}
  end

  defp preflight_descriptor(
         logical_name,
         %{source: :embedded, source_kind: source_kind, source_data: %{status: :ok, bytes: bytes}} =
           descriptor
       ) do
    case Rendro.PDF.FontParser.parse(bytes) do
      {:ok, parsed} ->
        pdf_font =
          Rendro.PDF.Font.embedded(
            name: resource_name(logical_name),
            logical_name: logical_name,
            base_font: parsed.base_font,
            source_kind: source_kind,
            font_bytes: bytes,
            units_per_em: parsed.units_per_em,
            ascent: parsed.ascent,
            descent: parsed.descent,
            default_width: parsed.default_width,
            widths: parsed.widths
          )

        {:ok, Map.put(descriptor, :pdf_font, pdf_font)}

      {:error, reason} ->
        {:error, invalid_embedded_font_error(logical_name, source_kind, reason)}
    end
  end

  defp to_pdf_font(logical_name, %{source: :built_in} = descriptor),
    do: {:ok, built_in(descriptor, logical_name)}

  defp to_pdf_font(_logical_name, %{source: :embedded, pdf_font: %Rendro.PDF.Font{} = pdf_font}),
    do: {:ok, pdf_font}

  defp to_pdf_font(logical_name, %{source: :embedded} = descriptor) do
    with {:ok, descriptor} <- preflight_descriptor(logical_name, descriptor),
         %Rendro.PDF.Font{} = pdf_font <- Map.fetch!(descriptor, :pdf_font) do
      {:ok, pdf_font}
    end
  end

  defp invalid_embedded_font_error(logical_name, source_kind, reason) do
    {:invalid_embedded_font,
     %{logical_name: logical_name, source_kind: source_kind, reason: reason}}
  end

  defp resource_name(logical_name) do
    logical_name
    |> Atom.to_string()
    |> String.upcase()
    |> String.replace(~r/[^A-Z0-9]/u, "_")
    |> then(&"F_#{&1}")
  end
end

defmodule Rendro.FontRegistry.EmbeddedFontFamilyError do
  defexception [
    :message,
    :family_name,
    :missing_variants,
    :extra_variants,
    :provided_kinds,
    :reason
  ]

  @impl true
  def exception(opts) do
    family_name = Keyword.fetch!(opts, :family_name)
    missing_variants = Keyword.get(opts, :missing_variants, [])
    extra_variants = Keyword.get(opts, :extra_variants, [])
    provided_kinds = Keyword.get(opts, :provided_kinds, %{})
    reason = Keyword.get(opts, :reason, :incomplete_embedded_family)

    message =
      "embedded font family #{inspect(family_name)} is invalid: " <>
        "missing=#{inspect(missing_variants)} extra=#{inspect(extra_variants)} " <>
        "provided_kinds=#{inspect(provided_kinds)} reason=#{inspect(reason)}"

    %__MODULE__{
      family_name: family_name,
      missing_variants: missing_variants,
      extra_variants: extra_variants,
      provided_kinds: provided_kinds,
      reason: reason,
      message: message
    }
  end
end
