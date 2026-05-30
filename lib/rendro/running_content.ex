defmodule Rendro.RunningContent do
  @moduledoc """
  Wraps a per-page content function for use in running header/footer regions.

  A running-content block carries a function that is evaluated once per page during
  pagination. The function receives the current page index and total page count as a
  2-tuple and returns a list of `Rendro.Block.t()` to render on that page.

  Functions must be pure and terminating. Infinite loops are not defended against
  (Elixir has no timeout primitive without Task). Use simple, deterministic functions.
  """
  @moduledoc tags: [:stable]

  @enforce_keys [:fun]
  defstruct fun: nil

  @type t :: %__MODULE__{
          fun: ({pos_integer(), pos_integer()} -> [Rendro.Block.t()] | nil)
        }
end
