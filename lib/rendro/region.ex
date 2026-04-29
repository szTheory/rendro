defmodule Rendro.Region do
  @moduledoc """
  Bounded layout region with named role and anchoring metadata.
  """

  @enforce_keys []
  defstruct name: nil,
            role: :body,
            anchor: :flow,
            x: 0,
            y: 0,
            width: nil,
            height: nil

  @type role :: :header | :body | :footer | :sidebar | :custom
  @type anchor :: :top | :flow | :bottom | :fixed

  @type t :: %__MODULE__{
          name: atom() | String.t() | nil,
          role: role(),
          anchor: anchor(),
          x: number(),
          y: number(),
          width: number() | nil,
          height: number() | nil
        }
end
