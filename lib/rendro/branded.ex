defmodule Rendro.Branded do
  @moduledoc false

  @doc """
  Returns the absolute path to the shipped B612 Regular demo font.
  """
  @spec font_path() :: Path.t()
  def font_path, do: Application.app_dir(:rendro, "priv/branded/fonts/B612-Regular.ttf")

  @doc """
  Returns the absolute path to the shipped branded demo logo.
  """
  @spec logo_path() :: Path.t()
  def logo_path, do: Application.app_dir(:rendro, "priv/branded/images/rendro-logo.png")
end
