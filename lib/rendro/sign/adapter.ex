defmodule Rendro.Sign.Adapter do
  @moduledoc """
  Optional behaviour for external signing adapters.

  Core Rendro stops at prepared artifact output. Optional adapters can inspect
  that prepared artifact, derive adapter-local handoff data, and return updated
  bytes plus namespaced metadata without widening the shared core manifest.
  """
  @moduledoc tags: [:adapter]

  @optional_callbacks augment: 2

  @callback prepare(Rendro.Artifact.t(), map()) ::
              {:ok, binary(), map()} | {:error, term()}

  @callback sign(Rendro.Artifact.t(), map()) ::
              {:ok, binary(), map()} | {:error, term()}

  @callback augment(Rendro.Artifact.t(), map()) ::
              {:ok, binary(), map()} | {:error, term()}
end
