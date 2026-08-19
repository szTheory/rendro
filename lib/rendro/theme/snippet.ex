defmodule Rendro.Theme.Snippet do
  @moduledoc false

  @schema_version 1
  @generated_by "mix rendro.configurator.gen"

  @families [
    {"invoice", "Invoice", "invoice", Rendro.Recipes.Invoice},
    {"statement", "Statement", "statement", Rendro.Recipes.Statement},
    {"receipt", "Receipt", "receipt", Rendro.Recipes.Receipt},
    {"certificate", "Certificate", "certificate", Rendro.Recipes.Certificate},
    {"payslip", "Payslip", "payslip", Rendro.Recipes.Payslip},
    {"ticket", "Ticket", "ticket", Rendro.Recipes.Ticket}
  ]

  @presets [
    {"swiss", "Swiss", :swiss},
    {"humanist", "Humanist", :humanist},
    {"editorial", "Editorial", :editorial},
    {"corporate-classic", "Corporate Classic", :corporate_classic},
    {"minimal-mono", "Minimal Mono", :minimal_mono},
    {"brutalist", "Brutalist", :brutalist}
  ]

  @accents [
    {"#0E7C76", "Teal", {14, 124, 118}},
    {"#147A4B", "Green", {20, 122, 75}},
    {"#1F4FB8", "Blue", {31, 79, 184}},
    {"#2C6BED", "Bright Blue", {44, 107, 237}},
    {"#6E3CB8", "Purple", {110, 60, 184}},
    {"#C24132", "Red", {194, 65, 50}},
    {"#C78600", "Gold", {199, 134, 0}}
  ]

  @modes [{"light", "Light", :light}, {"dark", "Dark", :dark}]

  @spec options() :: map()
  def options do
    %{
      "families" => Enum.map(@families, &option/1),
      "presets" => Enum.map(@presets, &option/1),
      "accents" => Enum.map(@accents, &option/1),
      "modes" => Enum.map(@modes, &option/1)
    }
  end

  @spec preset_call(String.t(), String.t(), String.t()) :: String.t()
  def preset_call(preset, accent, mode) do
    preset_atom = preset_atom!(preset)
    {red, green, blue} = accent_rgb!(accent)
    mode_atom = mode_atom!(mode)

    "Rendro.Theme.preset(:#{preset_atom}, accent: {#{red}, #{green}, #{blue}}, mode: :#{mode_atom})"
  end

  @spec usage_snippet(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def usage_snippet(family, preset, accent, mode) do
    {variable, recipe_module} = family_source!(family)
    preset_atom = preset_atom!(preset)
    {red, green, blue} = accent_rgb!(accent)
    mode_atom = mode_atom!(mode)

    """
    preset = :#{preset_atom}

    theme =
      Rendro.Theme.preset(preset, accent: {#{red}, #{green}, #{blue}}, mode: :#{mode_atom})

    document =
      #{variable}
      |> #{inspect(recipe_module)}.document(theme: theme)
      |> Rendro.Theme.Presets.register_fonts(preset)
    """
  end

  @spec module_source(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def module_source(module, preset, accent, mode) when is_binary(module) do
    preset_atom = preset_atom!(preset)

    """
    defmodule #{module} do
      @moduledoc false

      @spec theme() :: Rendro.Theme.t()
      def theme do
        #{preset_call(preset, accent, mode)}
      end

      @spec register_fonts(Rendro.Document.t()) :: Rendro.Document.t()
      def register_fonts(document) do
        Rendro.Theme.Presets.register_fonts(document, :#{preset_atom})
      end
    end
    """
    |> Code.format_string!()
    |> IO.iodata_to_binary()
  end

  @spec records() :: [map()]
  def records do
    for {family, _label, _variable, _module} <- @families,
        {preset, _label, _atom} <- @presets,
        {accent, _label, _rgb} <- @accents,
        {mode, _label, _atom} <- @modes do
      %{
        "key" => Enum.join([family, preset, accent, mode], "--"),
        "family" => family,
        "preset" => preset,
        "accent" => accent,
        "mode" => mode,
        "snippet" => usage_snippet(family, preset, accent, mode)
      }
    end
  end

  @spec index_json() :: binary()
  def index_json do
    %{
      "schema_version" => @schema_version,
      "generated_by" => @generated_by,
      "options" => options(),
      "records" => records()
    }
    |> JSON.encode!()
    |> Kernel.<>("\n")
  end

  defp option({value, label, _}), do: %{"value" => value, "label" => label}
  defp option({value, label, _, _}), do: %{"value" => value, "label" => label}

  defp family_source!(family) do
    case Enum.find(@families, fn {value, _, _, _} -> value == family end) do
      {_, _, variable, recipe_module} -> {variable, recipe_module}
      nil -> invalid!("family", family, Enum.map(@families, &elem(&1, 0)))
    end
  end

  defp preset_atom!(preset) do
    case Enum.find(@presets, fn {value, _, _} -> value == preset end) do
      {_, _, atom} -> atom
      nil -> invalid!("preset", preset, Enum.map(@presets, &elem(&1, 0)))
    end
  end

  defp accent_rgb!(accent) do
    case Enum.find(@accents, fn {value, _, _} -> value == accent end) do
      {_, _, rgb} -> rgb
      nil -> invalid!("accent", accent, Enum.map(@accents, &elem(&1, 0)))
    end
  end

  defp mode_atom!(mode) do
    case Enum.find(@modes, fn {value, _, _} -> value == mode end) do
      {_, _, atom} -> atom
      nil -> invalid!("mode", mode, Enum.map(@modes, &elem(&1, 0)))
    end
  end

  defp invalid!(kind, value, values) do
    raise ArgumentError,
          "invalid #{kind} #{inspect(value)}; accepted values are #{inspect(values)}"
  end
end
