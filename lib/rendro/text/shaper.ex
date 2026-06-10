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

  @spec shape(Rendro.PDF.Font.t(), String.t(), keyword()) ::
          {:ok, [glyph()]} | {:error, term()}
  def shape(font, text, opts \\ []) do
    impl().shape(font, text, opts)
  end
end
