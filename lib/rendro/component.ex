defmodule Rendro.Component do
  @moduledoc """
  Component-based layout pattern for reusable PDF UI parts.
  """

  @doc """
  Renders a component by calling its `render/1` function.
  """
  def render_component(module, assigns \\ []) do
    module.render(assigns)
  end
end
