defmodule Rendro.Text.Shaper do
  @moduledoc """
  Behaviour for text shaping adapters.

  Implement this behaviour to provide a custom text shaping engine.
  The default implementation is `Rendro.Text.Shaper.Simple` (pure Elixir, cmap + advance widths).
  For complex scripts (Arabic, Indic, Thai, etc.) configure `Rendro.Adapters.HarfBuzz`.

  ## Configuration

      config :rendro, shaper: Rendro.Adapters.HarfBuzz

  ## Per-render override

      Rendro.render(doc, shaper: Rendro.Adapters.HarfBuzz)

  Precedence: per-render `:shaper` option > application config > `Rendro.Text.Shaper.Simple`.
  The per-render option is threaded through the pipeline as the `:shaper` key in
  the `opts` passed to `shape/3`.
  """
  @moduledoc tags: [:stable]

  @typedoc """
  A shaped glyph.

  * `:gid` — glyph id in the font, or `0` when the shaping engine does not
    expose glyph ids.
  * `:cluster` — byte offset (into the input text) of the first byte of the
    cluster this glyph belongs to, non-decreasing in logical order. A shaper
    that does not compute cluster boundaries MUST return `0` for every glyph;
    such output is interpreted as one-glyph-per-grapheme when the glyph count
    equals the input grapheme count, and as a single atomic cluster spanning
    the whole input text otherwise.
  * `:x_advance` / `:y_advance` / `:x_offset` / `:y_offset` — metrics in font
    units (the caller scales by the font's `units_per_em`).
  * `:name` — optional glyph (or grapheme) name; `".notdef"` marks a missing
    glyph.
  """
  @type glyph :: %{
          :gid => non_neg_integer(),
          :cluster => non_neg_integer(),
          :x_advance => integer(),
          :y_advance => integer(),
          :x_offset => integer(),
          :y_offset => integer(),
          optional(:name) => String.t()
        }

  @doc """
  Shapes `text` for `font`, returning shaped glyphs in the engine's output order.

  ## Options

  * `:script` — OpenType script tag atom for the run (e.g. `:latn`, `:arab`)
    as produced by the Bidi itemizer; defaults to `:latn`.
    `Rendro.Text.Shaper.Simple` uses it to gate requires-shaping scripts.
  * `:shaper` — effective shaper module for this render (per-render override,
    resolved by `Rendro.Text.Shaper.shape/3`); implementations may ignore it.
  """
  @callback shape(Rendro.PDF.Font.t(), String.t(), opts :: keyword()) ::
              {:ok, [glyph()]} | {:error, term()}

  @spec impl() :: module()
  def impl do
    Application.get_env(:rendro, :shaper, Rendro.Text.Shaper.Simple)
  end

  @doc """
  Shapes `text` with the effective shaper implementation.

  The effective shaper is `opts[:shaper]` when present (per-render override),
  otherwise the application-configured `impl/0`.
  """
  @spec shape(Rendro.PDF.Font.t(), String.t(), keyword()) ::
          {:ok, [glyph()]} | {:error, term()}
  def shape(font, text, opts \\ []) do
    shaper = Keyword.get(opts, :shaper) || impl()
    shaper.shape(font, text, opts)
  end
end
