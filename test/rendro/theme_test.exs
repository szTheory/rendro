defmodule Rendro.ThemeTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Rendro.Color
  alias Rendro.Theme

  @color_roles [
    :accent,
    :background,
    :ink,
    :muted,
    :negative,
    :on_accent,
    :positive,
    :rule,
    :surface
  ]

  @scale_steps [:display, :title, :subtitle, :body, :small, :caption]

  @web_concepts [:shadow, :elevation, :z_index, :opacity, :gradient, :motion, :letter_spacing]

  # --- Generators ------------------------------------------------------------

  defp rgb_gen do
    gen all(
          r <- integer(0..255),
          g <- integer(0..255),
          b <- integer(0..255)
        ) do
      {r, g, b}
    end
  end

  defp partial_map do
    gen all(
          roles <- list_of(member_of(@color_roles), max_length: 4),
          values <- list_of(rgb_gen(), length: length(roles)),
          mode <- member_of([:light, :dark]),
          density <- member_of([:comfortable, :compact])
        ) do
      %{
        colors: Map.new(Enum.zip(roles, values)),
        mode: mode,
        density: density
      }
    end
  end

  defp theme_or_partial do
    gen all(
          part <- partial_map(),
          shape <- member_of([:map, :keyword, :theme])
        ) do
      case shape do
        :map -> part
        :keyword -> Enum.into(part, [])
        :theme -> Theme.resolve(part)
      end
    end
  end

  # --- THEME-01: full frozen field set ---------------------------------------

  describe "THEME-01 — frozen field set" do
    test "bare %Theme{} equals default/0 (no half-nil trap)" do
      assert %Theme{} == Theme.default()
    end

    test "colors carry exactly the 9 roles, each an integer {r,g,b}" do
      t = Theme.default()
      assert Enum.sort(Map.keys(t.colors)) == @color_roles

      for {_role, value} <- t.colors do
        assert Color.validate(value) == :ok
      end
    end

    test "typography scale has the 6 D-03 steps and metric-no-op defaults" do
      t = Theme.default()
      assert Enum.sort(Map.keys(t.typography.scale)) == Enum.sort(@scale_steps)

      assert t.typography.scale == %{
               display: 21,
               title: 16.5,
               subtitle: 13,
               body: 10.5,
               small: 9,
               caption: 8
             }

      assert t.typography.leading == 1.35
      assert t.typography.widows == 2
      assert t.typography.orphans == 2
      assert t.typography.fonts == %{heading: :default, body: :default, mono: :default}
    end

    test "leading is 1.35 (D-01/DEFAULT-01) and the colour surface is untouched by it" do
      assert Theme.default().typography.leading == 1.35
      assert Theme.resolve(Theme.default()).colors.accent == {44, 107, 237}
    end

    test "spacing, rules, radius, density, and mode are all present" do
      t = Theme.default()
      assert Map.keys(t.spacing) != []
      assert Map.keys(t.rules) != []
      assert Map.keys(t.radius) != []
      assert t.density == :comfortable
      assert t.mode == :light
    end

    test "default palette matches the D-05 light column" do
      c = Theme.default().colors
      assert c.background == {255, 255, 255}
      assert c.surface == {247, 243, 234}
      assert c.rule == {196, 188, 169}
      assert c.ink == {16, 24, 39}
      assert c.accent == {44, 107, 237}
    end
  end

  # --- THEME-02: resolve idempotence, deep-merge, validation -----------------

  describe "THEME-02 — resolve/1" do
    property "is idempotent for keyword | map | %Theme{} input" do
      check all(t <- theme_or_partial()) do
        assert Theme.resolve(Theme.resolve(t)) == Theme.resolve(t)
      end
    end

    property "deep-merges partial input without KeyError, returning a full %Theme{}" do
      check all(part <- partial_map()) do
        assert match?(%Theme{}, Theme.resolve(part))
      end
    end

    property "validates every color role of any resolved theme" do
      check all(part <- partial_map()) do
        resolved = Theme.resolve(part)

        for {_role, value} <- resolved.colors do
          assert Color.validate(value) == :ok
        end
      end
    end

    test "raises an instructive ArgumentError on a bad (hex) token" do
      assert_raise ArgumentError, ~r/hex/, fn ->
        Theme.resolve(colors: %{ink: "#000"})
      end
    end

    test "honors density :compact as a shallow leading nudge, idempotently" do
      compact = Theme.resolve(density: :compact)
      assert compact.density == :compact
      assert compact.typography.leading == Theme.resolve(compact).typography.leading
    end
  end

  # --- COLOR-01: the 9 roles are the only color surface ----------------------

  describe "COLOR-01 — color surface" do
    test "exact key set is the 9 roles" do
      assert Enum.sort(Map.keys(Theme.default().colors)) == @color_roles
    end
  end

  # --- COLOR-02: from_brand/2 derivation -------------------------------------

  describe "COLOR-02 — from_brand/2" do
    test "keeps the seed accent and derives on_accent to one of the theme's poles" do
      t = Theme.from_brand(accent: {44, 107, 237})
      assert t.colors.accent == {44, 107, 237}
      assert t.colors.on_accent in [t.colors.background, t.colors.ink]
    end

    test "respects an explicit on_accent override, never recomputing it" do
      t = Theme.from_brand(accent: {44, 107, 237}, on_accent: {1, 2, 3})
      assert t.colors.on_accent == {1, 2, 3}
    end

    property "derives an integer-tuple on_accent, deterministically, for any accent" do
      check all(rgb <- rgb_gen()) do
        first = Theme.from_brand(accent: rgb)
        second = Theme.from_brand(accent: rgb)

        {r, g, b} = first.colors.on_accent
        assert is_integer(r) and is_integer(g) and is_integer(b)
        assert first.colors.on_accent == second.colors.on_accent
        assert first.colors.on_accent in [first.colors.background, first.colors.ink]
      end
    end

    test "emits tokens only — the struct carries logical font atoms, no registry work" do
      t = Theme.from_brand(accent: {44, 107, 237})
      assert match?(%Theme{}, t)
      assert t.typography.fonts == %{heading: :default, body: :default, mono: :default}
    end
  end

  # --- dark/1 swap -----------------------------------------------------------

  describe "dark/1" do
    test "swaps to the D-05 dark column, keeping accent and white on_accent (R2)" do
      d = Theme.dark(Theme.default())
      assert d.mode == :dark
      assert d.colors.ink == {242, 236, 224}
      assert d.colors.background == {27, 23, 19}
      assert d.colors.surface == {35, 32, 25}
      assert d.colors.rule == {74, 68, 57}
      assert d.colors.accent == {44, 107, 237}
      assert d.colors.on_accent == {255, 255, 255}
    end
  end

  # --- THEME-04: web concepts absent by construction -------------------------

  describe "THEME-04 — web concepts excluded" do
    test "no group map carries a web-concept key" do
      t = Theme.default()

      for group <- [t.colors, t.typography, t.spacing, t.rules, t.radius] do
        assert_no_web_concept(group)
      end
    end
  end

  # --- THEME-03: @spec presence ----------------------------------------------

  describe "THEME-03 — @spec presence" do
    test "default/0, resolve/1, dark/1, from_brand/2 each have a @spec" do
      {:ok, specs} = Code.Typespec.fetch_specs(Theme)
      spec_keys = for {{name, arity}, _} <- specs, into: MapSet.new(), do: {name, arity}

      for fun <- [{:default, 0}, {:resolve, 1}, {:dark, 1}, {:from_brand, 2}] do
        assert fun in spec_keys, "missing @spec for #{inspect(fun)}"
      end
    end
  end

  # --- Byte-reproducibility --------------------------------------------------

  describe "byte reproducibility" do
    test "all default and dark color values are integer tuples" do
      for theme <- [Theme.default(), Theme.dark(Theme.default())],
          {_role, {r, g, b}} <- theme.colors do
        assert is_integer(r) and is_integer(g) and is_integer(b)
      end
    end

    test "type-scale values are integers or single decimals (no :math.pow irrationals)" do
      for {_step, v} <- Theme.default().typography.scale do
        assert v == Float.round(v * 1.0, 1)
      end
    end
  end

  # --- Helpers ---------------------------------------------------------------

  defp assert_no_web_concept(map) when is_map(map) do
    for key <- Map.keys(map) do
      refute key in @web_concepts, "web-concept key #{inspect(key)} must not exist"
    end

    for {_k, v} <- map, is_map(v) do
      assert_no_web_concept(v)
    end
  end
end
