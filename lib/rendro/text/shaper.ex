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

  @type glyph :: %{
          gid: non_neg_integer(),
          cluster: non_neg_integer(),
          x_advance: integer(),
          y_advance: integer(),
          x_offset: integer(),
          y_offset: integer()
        }

  @callback shape(Rendro.PDF.Font.t(), String.t(), keyword()) ::
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
