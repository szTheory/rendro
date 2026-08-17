defmodule Rendro.Theme.Presets do
  @moduledoc false

  alias Rendro.{Document, FontRegistry, Theme}

  @canonical_genres [:swiss, :humanist, :editorial, :corporate_classic, :minimal_mono]
  @allowed_options [:accent, :on_accent, :mode, :density]

  @font_paths %{
    rendro_preset_grotesque: "priv/fonts/inter/Inter-Regular.ttf",
    rendro_preset_mono: "priv/fonts/jetbrains-mono/JetBrainsMono-Regular.ttf"
  }

  @spec preset(atom(), keyword()) :: Theme.t()
  def preset(genre, opts) do
    validate_genre!(genre)
    validate_options!(opts)

    accent = Keyword.fetch!(opts, :accent) |> validate_color!(:accent)
    on_accent = Keyword.get(opts, :on_accent) |> validate_optional_color!(:on_accent)
    mode = Keyword.get(opts, :mode, :light) |> validate_mode!()
    density = Keyword.get(opts, :density, :comfortable) |> validate_density!()

    colors =
      [accent: accent]
      |> maybe_put(:on_accent, on_accent)

    base = Theme.from_brand(colors)

    theme =
      base
      |> Map.from_struct()
      |> Map.merge(genre_tokens(genre))
      |> Map.put(:density, density)
      |> Theme.resolve()

    if mode == :dark, do: Theme.dark(theme), else: theme
  end

  @spec register_fonts(Document.t(), atom()) :: Document.t()
  def register_fonts(%Document{} = document, genre) do
    validate_genre!(genre)

    genre
    |> font_roles()
    |> Enum.reduce(document, &register_font(&2, &1))
  end

  defp register_font(document, role) do
    expected = descriptor(role)

    case FontRegistry.fetch(document.font_registry, role) do
      :error ->
        Document.register_embedded_font(document, role, {:path, font_path(role)})

      {:ok, ^expected} ->
        document

      {:ok, _existing} ->
        raise ArgumentError,
              "Rendro.Theme.Presets.register_fonts/2 collision for #{inspect(role)}; " <>
                "the document already owns a different descriptor. Choose another logical role " <>
                "or remove the conflicting registration before registering #{inspect(role)}."
    end
  end

  defp descriptor(role) do
    document = Document.new() |> Document.register_embedded_font(role, {:path, font_path(role)})
    {:ok, descriptor} = FontRegistry.fetch(document.font_registry, role)
    descriptor
  end

  defp font_path(role) do
    :rendro
    |> Application.app_dir(Map.fetch!(@font_paths, role))
  end

  defp font_roles(:swiss), do: [:rendro_preset_grotesque, :rendro_preset_mono]
  defp font_roles(:humanist), do: [:rendro_preset_mono]
  defp font_roles(:editorial), do: [:rendro_preset_mono]
  defp font_roles(:corporate_classic), do: [:rendro_preset_mono]
  defp font_roles(:minimal_mono), do: [:rendro_preset_mono, :rendro_preset_grotesque]

  defp genre_tokens(:swiss) do
    %{
      typography: %{
        fonts: %{
          heading: :rendro_preset_grotesque,
          body: :rendro_preset_grotesque,
          mono: :rendro_preset_mono
        },
        scale: %{display: 21, title: 16.5, subtitle: 13, body: 10.5, small: 9, caption: 8},
        leading: 1.3
      },
      spacing: %{unit: 6, tight: 4, normal: 8, loose: 12, section: 24},
      rules: %{hairline: 0.5, thin: 1, thick: 2},
      radius: %{none: 0, sm: 1, md: 2}
    }
  end

  defp validate_genre!(genre) when genre in @canonical_genres, do: :ok

  defp validate_genre!(genre) do
    raise ArgumentError,
          "invalid preset #{inspect(genre)}; canonical presets are #{inspect(@canonical_genres)}"
  end

  defp validate_options!(opts) when is_list(opts) do
    if Keyword.keyword?(opts) do
      unknown = Keyword.keys(opts) -- @allowed_options

      if unknown != [] do
        raise ArgumentError,
              "unknown preset option(s) #{inspect(unknown)}; accepted options are #{inspect(@allowed_options)}"
      end

      if Keyword.has_key?(opts, :accent) do
        :ok
      else
        raise ArgumentError, "missing required :accent option for Theme.preset/2"
      end
    else
      invalid_options!(opts)
    end
  end

  defp validate_options!(opts) do
    invalid_options!(opts)
  end

  defp invalid_options!(opts) do
    raise ArgumentError,
          "preset options must be a keyword list, got: #{inspect(opts)}; try accent: \"#2C6BED\""
  end

  defp validate_color!(value, _role) when is_tuple(value) do
    validate_theme_color!(value)
  end

  defp validate_color!(value, role) when is_binary(value) do
    case Regex.match?(~r/^#[0-9A-Fa-f]{6}$/, value) do
      true -> value |> String.trim_leading("#") |> Base.decode16!(case: :mixed) |> rgb()
      false -> invalid_color!(role, value)
    end
  end

  defp validate_color!(value, role), do: invalid_color!(role, value)
  defp validate_optional_color!(nil, _role), do: nil
  defp validate_optional_color!(value, role), do: validate_color!(value, role)

  defp validate_theme_color!(value) do
    case Rendro.Color.validate(value) do
      :ok -> value
      {:error, _reason} -> invalid_color!(:accent, value)
    end
  end

  defp invalid_color!(role, value) do
    raise ArgumentError,
          "invalid #{role} #{inspect(value)}; use an RGB tuple such as {44, 107, 237} or a six-digit hex string such as \"#2C6BED\""
  end

  defp rgb(<<r, g, b>>), do: {r, g, b}
  defp validate_mode!(mode) when mode in [:light, :dark], do: mode

  defp validate_mode!(mode) do
    raise ArgumentError, "invalid mode #{inspect(mode)}; canonical modes are [:light, :dark]"
  end

  defp validate_density!(density) when density in [:comfortable, :compact], do: density

  defp validate_density!(density) do
    raise ArgumentError,
          "invalid density #{inspect(density)}; canonical densities are [:comfortable, :compact]"
  end

  defp maybe_put(keywords, _key, nil), do: keywords
  defp maybe_put(keywords, key, value), do: Keyword.put(keywords, key, value)
end
