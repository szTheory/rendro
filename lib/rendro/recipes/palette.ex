defmodule Rendro.Recipes.Palette do
  @moduledoc false

  @spec resolve(keyword(), map()) :: map()
  def resolve(opts, defaults) do
    base =
      case opts[:theme] do
        nil -> defaults
        theme -> Rendro.Theme.resolve(theme).colors
      end

    Map.merge(base, Keyword.get(opts, :palette, %{}))
  end
end
