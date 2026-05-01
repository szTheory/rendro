defmodule Rendro.Branded do
  @moduledoc """
  Path helpers for Rendro's shipped branded demo assets.

  These demo assets are provided for examples and recipe proofs only. They are
  NOT a built-in font or default logo, and callers must still register them on
  each `%Rendro.Document{}` through the public document APIs.
  """

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
