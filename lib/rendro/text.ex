defmodule Rendro.Text do
  @moduledoc """
  Text content with logical font, size, and color attributes.

  `font` is a public authoring reference, not a PDF writer resource name.
  Prefer logical names such as `:body` or `:heading` that the document resolves
  through its owned font registry. A narrow Helvetica compatibility path remains
  available for the current built-in default behavior.
  """

  @helvetica_aliases ["Helvetica", "helvetica"]

  @enforce_keys [:content]
  defstruct [
    :content,
    font: "Helvetica",
    size: 12,
    color: {0, 0, 0},
    line_height: 1.2,
    widows: 2,
    orphans: 2
  ]

  @type logical_font_name :: atom()
  @type compatibility_font_alias :: String.t()
  @type font_ref :: logical_font_name() | compatibility_font_alias()

  @type t :: %__MODULE__{
          content: String.t(),
          font: font_ref(),
          size: number(),
          color: {non_neg_integer(), non_neg_integer(), non_neg_integer()},
          line_height: float(),
          widows: non_neg_integer(),
          orphans: non_neg_integer()
        }

  @doc """
  Returns the current narrow compatibility default for authored text.
  """
  @spec default_font() :: String.t()
  def default_font, do: "Helvetica"

  @doc """
  Normalizes a public font reference.

  Logical font atoms are passed through unchanged. String compatibility aliases
  are intentionally narrow and currently only support Helvetica.
  """
  @spec normalize_font(font_ref()) :: font_ref()
  def normalize_font(font) when is_atom(font), do: font

  def normalize_font(font) when is_binary(font) do
    if font in @helvetica_aliases do
      default_font()
    else
      raise ArgumentError,
            "Rendro.text/2 only supports logical font atoms or the narrow Helvetica compatibility aliases; got: #{inspect(font)}"
    end
  end
end
