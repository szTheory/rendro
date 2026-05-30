defmodule Rendro.Component do
  @moduledoc """
  Component-based layout pattern for reusable PDF UI parts.
  """
  @moduledoc tags: [:stable]

  @doc """
  Renders a component by calling its `render/1` function.
  """
  def render_component(module, assigns \\ []) do
    module.render(assigns)
  end

  @doc """
  Creates a standard `Rendro.Block` containing a `Rendro.Image`.
  Requires at least one constraint: `:width`, `:height`, or `:fit`.
  """
  def image(logical_name, opts \\ []) do
    width = Keyword.get(opts, :width)
    height = Keyword.get(opts, :height)
    fit = Keyword.get(opts, :fit)

    if is_nil(width) and is_nil(height) and is_nil(fit) do
      raise ArgumentError,
            "Image component requires at least one constraint: :width, :height, or :fit"
    end

    %Rendro.Block{
      content: %Rendro.Image{
        logical_name: logical_name,
        fit: fit
      },
      width: width,
      height: height
    }
  end
end
