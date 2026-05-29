defmodule PhoenixExampleWeb.ErrorJSON do
  # Renders e.g. "404.json" / "500.json" into a JSON error body.
  # Phoenix 1.7+/1.8 generator-default convention.
  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
