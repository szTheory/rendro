defmodule Rendro.PDF.Font do
  @moduledoc """
  Built-in PDF Type1 font definitions and glyph width metrics.

  Provides Helvetica (the PDF standard sans-serif) with per-glyph widths
  from the Adobe Font Metrics specification. Widths are in units of 1/1000
  of the font's em-square; multiply by font_size/1000 to get point widths.
  """

  @type t :: %__MODULE__{
          name: String.t(),
          base_font: String.t(),
          widths: %{non_neg_integer() => non_neg_integer()}
        }

  defstruct [:name, :base_font, widths: %{}]

  @helvetica_widths %{
    32 => 278, 33 => 278, 34 => 355, 35 => 556, 36 => 556, 37 => 889,
    38 => 667, 39 => 191, 40 => 333, 41 => 333, 42 => 389, 43 => 584,
    44 => 278, 45 => 333, 46 => 278, 47 => 278, 48 => 556, 49 => 556,
    50 => 556, 51 => 556, 52 => 556, 53 => 556, 54 => 556, 55 => 556,
    56 => 556, 57 => 556, 58 => 278, 59 => 278, 60 => 584, 61 => 584,
    62 => 584, 63 => 556, 64 => 1015, 65 => 667, 66 => 667, 67 => 722,
    68 => 722, 69 => 667, 70 => 611, 71 => 778, 72 => 722, 73 => 278,
    74 => 500, 75 => 667, 76 => 556, 77 => 833, 78 => 722, 79 => 778,
    80 => 667, 81 => 778, 82 => 722, 83 => 667, 84 => 611, 85 => 722,
    86 => 667, 87 => 944, 88 => 667, 89 => 667, 90 => 611, 91 => 278,
    92 => 278, 93 => 278, 94 => 469, 95 => 556, 96 => 333, 97 => 556,
    98 => 556, 99 => 500, 100 => 556, 101 => 556, 102 => 278, 103 => 556,
    104 => 556, 105 => 222, 106 => 222, 107 => 500, 108 => 222, 109 => 833,
    110 => 556, 111 => 556, 112 => 556, 113 => 556, 114 => 333, 115 => 500,
    116 => 278, 117 => 556, 118 => 500, 119 => 722, 120 => 500, 121 => 500,
    122 => 500, 123 => 334, 124 => 260, 125 => 334, 126 => 584
  }

  @spec helvetica() :: t()
  def helvetica do
    %__MODULE__{
      name: "F1",
      base_font: "Helvetica",
      widths: @helvetica_widths
    }
  end

  @spec text_width(t(), String.t(), number()) :: float()
  def text_width(%__MODULE__{widths: widths}, text, font_size) do
    text
    |> String.to_charlist()
    |> Enum.reduce(0, fn char, acc ->
      acc + Map.get(widths, char, 556)
    end)
    |> Kernel.*(font_size / 1000)
  end
end
