defmodule Rendro.Protect.Adapter do
  @moduledoc """
  Behavior for artifact protection adapters.

  A protection adapter takes a rendered `%Rendro.Artifact{}` and returns a new
  artifact-level PDF binary protected by an external tool or post-processing
  step.
  """

  @callback protect(Rendro.Artifact.t(), map()) ::
              {:ok, binary()} | {:error, term()}
end
