defmodule Rendro.PDF.Font do
  @moduledoc false

  @type t :: %__MODULE__{
          name: String.t(),
          source: :built_in | :embedded,
          subtype: :type1 | :truetype,
          logical_name: atom() | nil,
          base_font: String.t(),
          source_kind: :built_in | :path | :binary,
          embedded?: boolean(),
          font_bytes: binary() | nil,
          units_per_em: pos_integer(),
          ascent: integer(),
          descent: integer(),
          default_width: non_neg_integer(),
          widths: %{non_neg_integer() => non_neg_integer()}
        }

  defstruct [
    :name,
    :source,
    :subtype,
    :logical_name,
    :base_font,
    :source_kind,
    :embedded?,
    :font_bytes,
    :units_per_em,
    :ascent,
    :descent,
    :default_width,
    widths: %{}
  ]

  @helvetica_widths %{
    32 => 278,
    33 => 278,
    34 => 355,
    35 => 556,
    36 => 556,
    37 => 889,
    38 => 667,
    39 => 191,
    40 => 333,
    41 => 333,
    42 => 389,
    43 => 584,
    44 => 278,
    45 => 333,
    46 => 278,
    47 => 278,
    48 => 556,
    49 => 556,
    50 => 556,
    51 => 556,
    52 => 556,
    53 => 556,
    54 => 556,
    55 => 556,
    56 => 556,
    57 => 556,
    58 => 278,
    59 => 278,
    60 => 584,
    61 => 584,
    62 => 584,
    63 => 556,
    64 => 1015,
    65 => 667,
    66 => 667,
    67 => 722,
    68 => 722,
    69 => 667,
    70 => 611,
    71 => 778,
    72 => 722,
    73 => 278,
    74 => 500,
    75 => 667,
    76 => 556,
    77 => 833,
    78 => 722,
    79 => 778,
    80 => 667,
    81 => 778,
    82 => 722,
    83 => 667,
    84 => 611,
    85 => 722,
    86 => 667,
    87 => 944,
    88 => 667,
    89 => 667,
    90 => 611,
    91 => 278,
    92 => 278,
    93 => 278,
    94 => 469,
    95 => 556,
    96 => 333,
    97 => 556,
    98 => 556,
    99 => 500,
    100 => 556,
    101 => 556,
    102 => 278,
    103 => 556,
    104 => 556,
    105 => 222,
    106 => 222,
    107 => 500,
    108 => 222,
    109 => 833,
    110 => 556,
    111 => 556,
    112 => 556,
    113 => 556,
    114 => 333,
    115 => 500,
    116 => 278,
    117 => 556,
    118 => 500,
    119 => 722,
    120 => 500,
    121 => 500,
    122 => 500,
    123 => 334,
    124 => 260,
    125 => 334,
    126 => 584
  }

  @spec helvetica() :: t()
  def helvetica do
    %__MODULE__{
      name: "F1",
      source: :built_in,
      subtype: :type1,
      logical_name: nil,
      base_font: "Helvetica",
      source_kind: :built_in,
      embedded?: false,
      font_bytes: nil,
      units_per_em: 1000,
      ascent: 718,
      descent: -207,
      default_width: 556,
      widths: @helvetica_widths
    }
  end

  @spec embedded(keyword()) :: t()
  def embedded(opts) when is_list(opts) do
    %__MODULE__{
      name: Keyword.fetch!(opts, :name),
      source: :embedded,
      subtype: :truetype,
      logical_name: Keyword.fetch!(opts, :logical_name),
      base_font: Keyword.fetch!(opts, :base_font),
      source_kind: Keyword.fetch!(opts, :source_kind),
      embedded?: true,
      font_bytes: Keyword.fetch!(opts, :font_bytes),
      units_per_em: Keyword.fetch!(opts, :units_per_em),
      ascent: Keyword.fetch!(opts, :ascent),
      descent: Keyword.fetch!(opts, :descent),
      default_width: Keyword.fetch!(opts, :default_width),
      widths: Keyword.fetch!(opts, :widths)
    }
  end

  @spec text_width(t(), String.t(), number()) :: float()
  def text_width(%__MODULE__{widths: widths, default_width: default_width}, text, font_size) do
    text
    |> String.to_charlist()
    |> Enum.reduce(0, fn char, acc ->
      acc + Map.get(widths, char, default_width || 556)
    end)
    |> Kernel.*(font_size / 1000)
  end

  @doc """
  Checks if the font has explicitly defined glyphs for all codepoints in the text.
  """
  @spec has_glyph?(t(), String.t()) :: boolean()
  def has_glyph?(%__MODULE__{widths: widths}, text) when is_binary(text) do
    text
    |> String.to_charlist()
    |> Enum.all?(&Map.has_key?(widths, &1))
  end
end
