defmodule Rendro.Link do
  @moduledoc """
  Explicit authored link content wrapper with a narrow target contract.
  """
  @moduledoc tags: [:stable]

  @typedoc "Curated link target variants supported in Phase 49."
  @type target :: {:uri, String.t()} | {:page, pos_integer()}

  @enforce_keys [:content, :target]
  defstruct [:content, :target]

  @type t :: %__MODULE__{
          content: Rendro.Text.t() | Rendro.Table.t() | term(),
          target: target()
        }
end
