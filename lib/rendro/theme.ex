defmodule Rendro.Theme do
  @moduledoc """
  The pure, inert design-token value for a Rendro document.

  A `%Rendro.Theme{}` is a plain data value: color roles, typography, spacing,
  rules, radius, density, and mode. It performs no I/O, touches no registry, and
  never reaches the deterministic render pipeline directly — recipes read token
  values from it (e.g. `theme.colors.ink`, `theme.typography.scale.body`).

  Construct one of four core ways:

    * `default/0` — the built-in light theme.
    * `resolve/1` — deep-merge a partial `keyword`/`map`/`%Theme{}` onto the
      defaults, validating every color role.
    * `dark/1` — swap the resolved light role tuples to their dark counterparts.
    * `from_brand/2` — derive a full theme from a single brand `accent:` seed.

  ## Field shape vs. token values

  The **field shape** (group names, keys, nesting, arities) is stable — treat it
  as a public contract. The **token values** (the default palette, the type
  scale numbers, leading) and the rendered bytes they produce **may evolve**
  across minor versions. Callers who need an exact frozen appearance should pin
  it in their own golden/snapshot tests rather than relying on literal values.

  ## Flat elevation

  There is no `shadow`, `elevation`, `z-index`, `opacity`, or `gradient` field,
  by design — those do not map to deterministic print output. Express elevation
  flatly via a `surface` tint plus a `rule` hairline; the page (`background`)
  stays pure white.

  ## `on_accent` derivation

  `from_brand/2` derives a readable `on_accent` by picking whichever of the
  theme's own neutral poles (`background` vs `ink`) has the greater WCAG
  contrast against the accent. This is a sensible readable default, **not** a
  WCAG-AA/AAA or PDF-UA conformance claim — mid-tone accents may miss 4.5:1
  either way; pass an explicit `on_accent:` to override.
  """
  @moduledoc tags: [:adapter]

  alias Rendro.Color

  # Default light palette — integer {r,g,b} tuples mined from the warm-paper /
  # cool-ink token system at authoring time (D-05). All 9 roles are always
  # present; none is ever nil.
  @default_colors %{
    ink: {16, 24, 39},
    muted: {91, 101, 115},
    accent: {44, 107, 237},
    on_accent: {255, 255, 255},
    background: {255, 255, 255},
    surface: {247, 243, 234},
    rule: {196, 188, 169},
    positive: {20, 122, 75},
    negative: {194, 65, 50}
  }

  # Dark-mode role swaps (D-05). accent and on_accent are intentionally absent —
  # accent stays unchanged and on_accent stays white in dark mode (R2).
  @dark_colors %{
    ink: {242, 236, 224},
    muted: {150, 143, 126},
    background: {27, 23, 19},
    surface: {35, 32, 25},
    rule: {74, 68, 57},
    positive: {63, 179, 127},
    negative: {224, 113, 95}
  }

  # Type scale as explicit materialized points (D-03) — never a runtime formula.
  # widows/orphans are metric-identical to %Rendro.Text{} defaults. leading is
  # 1.35 (D-01/DEFAULT-01, Brand Book §9 Swiss print-prose band 1.3-1.45) — the
  # sole strong-default value change; it reflows wrapped multi-line prose on
  # the themed path only (the no-theme literal 1.2 path never reads default/0).
  @default_typography %{
    fonts: %{heading: :default, body: :default, mono: :default},
    scale: %{display: 21, title: 16.5, subtitle: 13, body: 10.5, small: 9, caption: 8},
    leading: 1.35,
    widows: 2,
    orphans: 2
  }

  # Semantic named steps (points). The SHAPE is frozen; these Evolving numbers
  # refine at rubric closure.
  @default_spacing %{unit: 6, tight: 4, normal: 8, loose: 12, section: 24}
  @default_rules %{hairline: 0.5, thin: 1, thick: 2}
  @default_radius %{none: 0, sm: 2, md: 4}

  # Shallow compact-density honoring: a pure leading nudge (no new field).
  @compact_leading 1.1

  @enforce_keys []
  defstruct colors: @default_colors,
            typography: @default_typography,
            spacing: @default_spacing,
            rules: @default_rules,
            radius: @default_radius,
            density: :comfortable,
            mode: :light

  @type rgb :: {0..255, 0..255, 0..255}
  @type font_role :: atom()
  @type type_step :: number()

  @type colors :: %{
          required(:ink) => rgb(),
          required(:muted) => rgb(),
          required(:accent) => rgb(),
          required(:on_accent) => rgb(),
          required(:background) => rgb(),
          required(:surface) => rgb(),
          required(:rule) => rgb(),
          required(:positive) => rgb(),
          required(:negative) => rgb()
        }

  @type typography :: %{
          required(:fonts) => %{
            required(:heading) => font_role(),
            required(:body) => font_role(),
            required(:mono) => font_role()
          },
          required(:scale) => %{
            required(:display) => type_step(),
            required(:title) => type_step(),
            required(:subtitle) => type_step(),
            required(:body) => type_step(),
            required(:small) => type_step(),
            required(:caption) => type_step()
          },
          required(:leading) => number(),
          required(:widows) => non_neg_integer(),
          required(:orphans) => non_neg_integer()
        }

  @type spacing :: %{
          required(:unit) => number(),
          required(:tight) => number(),
          required(:normal) => number(),
          required(:loose) => number(),
          required(:section) => number()
        }

  @type rules :: %{
          required(:hairline) => number(),
          required(:thin) => number(),
          required(:thick) => number()
        }

  @type radius :: %{
          required(:none) => number(),
          required(:sm) => number(),
          required(:md) => number()
        }

  @type t :: %__MODULE__{
          colors: colors(),
          typography: typography(),
          spacing: spacing(),
          rules: rules(),
          radius: radius(),
          density: :comfortable | :compact,
          mode: :light | :dark
        }

  @doc """
  Returns the built-in light theme — the shared-attribute defaults.

  A bare `%Rendro.Theme{}` is equal to `default/0`; there is no half-nil trap.

  ## Examples

      iex> Rendro.Theme.default() == %Rendro.Theme{}
      true

      iex> Rendro.Theme.default().colors.background
      {255, 255, 255}
  """
  @spec default() :: t()
  def default, do: %__MODULE__{}

  @doc """
  Returns a fully resolved curated theme selection.

  The first argument must be canonical and `opts` must include an `:accent`
  color. The returned value is pure; register required curated fonts explicitly
  on the document through the sibling module.
  """
  @spec preset(atom(), keyword()) :: t()
  def preset(genre, opts), do: Rendro.Theme.Presets.preset(genre, opts)

  @doc """
  Resolves a partial input onto the defaults, returning a full `%Theme{}`.

  Accepts a `keyword`, `map`, or existing `%Theme{}`. Partial input is
  deep-merged onto the default groups (never raising `KeyError`), then **every**
  color role is validated via `Rendro.Color.validate/1`; an invalid token raises
  an instructive `ArgumentError`. `resolve/1` is idempotent —
  `resolve(resolve(x)) == resolve(x)`.

  ## Examples

      iex> Rendro.Theme.resolve(mode: :light).colors.ink
      {16, 24, 39}

      iex> Rendro.Theme.resolve(colors: %{ink: {0, 0, 0}}).colors.ink
      {0, 0, 0}
  """
  @spec resolve(t() | map() | keyword()) :: t()
  def resolve(input) do
    attrs = normalize(input)

    colors = deep_merge(@default_colors, Map.get(attrs, :colors, %{}))
    validate_colors!(colors)

    density = Map.get(attrs, :density, :comfortable)

    typography =
      @default_typography
      |> deep_merge(Map.get(attrs, :typography, %{}))
      |> apply_density(density)

    %__MODULE__{
      colors: colors,
      typography: typography,
      spacing: deep_merge(@default_spacing, Map.get(attrs, :spacing, %{})),
      rules: deep_merge(@default_rules, Map.get(attrs, :rules, %{})),
      radius: deep_merge(@default_radius, Map.get(attrs, :radius, %{})),
      density: density,
      mode: Map.get(attrs, :mode, :light)
    }
  end

  @doc """
  Returns the dark counterpart of a theme.

  Resolves the input, then swaps the pre-resolved integer role tuples to their
  dark targets and sets `mode: :dark`. `accent` is unchanged and `on_accent`
  stays white (R2) — no transcendental color math at draw time.

  Dark is screen-oriented, not recommended for print: it carries no print,
  accessibility, PDF/UA, or WCAG contrast support claim.

  ## Examples

      iex> Rendro.Theme.dark(Rendro.Theme.default()).mode
      :dark

      iex> Rendro.Theme.dark(Rendro.Theme.default()).colors.background
      {27, 23, 19}
  """
  @spec dark(t()) :: t()
  def dark(theme) do
    resolved = resolve(theme)
    %{resolved | colors: Map.merge(resolved.colors, @dark_colors), mode: :dark}
  end

  @doc """
  Derives a full theme from brand tokens carrying a single `accent:` seed.

  `brand_tokens` is a keyword list with a required `accent:` and optional color
  roles plus an optional `on_accent:` override. `opts` carries `mode:`/`density:`.
  When `on_accent:` is not supplied it is derived by WCAG max-contrast between
  the accent and the theme's neutral poles (always an integer tuple, one of the
  theme's own poles). Emits tokens only — registers no font or asset.

  ## Examples

      iex> Rendro.Theme.from_brand(accent: {44, 107, 237}).colors.accent
      {44, 107, 237}

      iex> Rendro.Theme.from_brand(accent: {44, 107, 237}, on_accent: {1, 2, 3}).colors.on_accent
      {1, 2, 3}
  """
  @spec from_brand(keyword(), keyword()) :: t()
  def from_brand(brand_tokens, opts \\ []) do
    # Brand tokens are authoring-time input: coerce any hex string at this
    # boundary to an integer {r,g,b} so stored values stay tuples.
    brand = Map.new(brand_tokens, fn {role, value} -> {role, coerce_color(value)} end)
    accent = Map.fetch!(brand, :accent)

    provided =
      Map.take(brand, [
        :ink,
        :muted,
        :accent,
        :on_accent,
        :background,
        :surface,
        :rule,
        :positive,
        :negative
      ])

    base_colors = Map.merge(@default_colors, provided)

    on_accent =
      case Map.fetch(brand, :on_accent) do
        {:ok, override} -> override
        :error -> on_accent_for(accent, base_colors)
      end

    colors = Map.put(base_colors, :on_accent, on_accent)

    opts
    |> Map.new()
    |> Map.put(:colors, colors)
    |> resolve()
  end

  # --- Private helpers (never manifested) ------------------------------------

  # Normalizes any accepted input to a plain group map.
  @doc false
  defp normalize(%__MODULE__{} = theme), do: Map.from_struct(theme)
  defp normalize(input) when is_list(input), do: Map.new(input)
  defp normalize(input) when is_map(input), do: input

  # Recursively merges override onto base; nested maps merge, everything else
  # (including {r,g,b} tuples) is replaced wholesale by the override.
  @doc false
  defp deep_merge(base, override) when is_map(base) and is_map(override) do
    Map.merge(base, override, fn _key, b, o ->
      if is_map(b) and is_map(o), do: deep_merge(b, o), else: o
    end)
  end

  # Compact density is a shallow, idempotent leading nudge — set to a fixed
  # constant so re-resolving yields the same value.
  @doc false
  defp apply_density(typography, :compact), do: %{typography | leading: @compact_leading}
  defp apply_density(typography, _density), do: typography

  # Validates every color role, raising the instructive Color error verbatim.
  @doc false
  defp validate_colors!(colors) do
    Enum.each(colors, fn {_role, value} ->
      case Color.validate(value) do
        :ok -> :ok
        {:error, reason} -> raise ArgumentError, reason
      end
    end)
  end

  # Picks whichever neutral pole (background vs ink) has greater WCAG contrast
  # against the accent. The luminance floats select a branch only; the output is
  # always one of the theme's own integer tuples (D-04).
  @doc false
  defp on_accent_for(accent, colors) do
    background = colors.background
    ink = colors.ink

    if contrast_ratio(accent, background) >= contrast_ratio(accent, ink) do
      background
    else
      ink
    end
  end

  # WCAG contrast ratio between two colors: (L_light + 0.05) / (L_dark + 0.05).
  @doc false
  defp contrast_ratio(c1, c2) do
    l1 = luminance(c1)
    l2 = luminance(c2)
    {lighter, darker} = if l1 >= l2, do: {l1, l2}, else: {l2, l1}
    (lighter + 0.05) / (darker + 0.05)
  end

  # WCAG relative luminance of an {r,g,b} tuple.
  @doc false
  defp luminance({r, g, b}) do
    0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
  end

  # WCAG sRGB gamma expansion of a single 0–255 channel. The non-integer 2.4
  # exponent is computed via exp/log so no runtime power feeds any stored value
  # (this float only picks the on_accent branch; the type scale stays explicit).
  @doc false
  defp linearize(channel) do
    c = channel / 255

    if c <= 0.03928 do
      c / 12.92
    else
      base = (c + 0.055) / 1.055
      :math.exp(2.4 * :math.log(base))
    end
  end

  # Coerces an authoring-time color value: a hex string becomes an integer
  # {r,g,b} tuple; anything else passes through unchanged (validated later).
  @doc false
  defp coerce_color(value) when is_binary(value), do: hex_to_rgb(value)
  defp coerce_color(value), do: value

  # Authoring-boundary hex -> integer {r,g,b}. Stored attribute values are
  # already tuples; this converts hex only at the from_brand/2 input boundary.
  @doc false
  defp hex_to_rgb("#" <> hex), do: hex_to_rgb(hex)

  defp hex_to_rgb(hex) do
    <<r, g, b>> = Base.decode16!(hex, case: :mixed)
    {r, g, b}
  end
end
