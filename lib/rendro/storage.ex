defmodule Rendro.Storage do
  @moduledoc """
  Behavior for artifact storage adapters.

  Defines the contract for persisting `Rendro.Artifact` structures to external
  storage systems (S3, local disk, database, etc.) without coupling core
  rendering logic to any specific storage implementation.
  """

  @doc """
  Persists an artifact.

  Implementations must return `{:ok, identifier}` where `identifier` is a stable
  string/URI referencing the stored document. They may also return `{:error, reason}`.
  """
  @callback put(Rendro.Artifact.t(), keyword()) :: {:ok, String.t()} | {:error, term()}

  @doc """
  Retrieves a stored artifact by its identifier.

  Returns `{:ok, Artifact.t()}` if found, or `{:error, :not_found}` / `{:error, reason}`.
  """
  @callback get(String.t(), keyword()) :: {:ok, Rendro.Artifact.t()} | {:error, term()}

  @doc """
  Deletes a stored artifact by its identifier.

  Returns `:ok` on successful deletion, or `{:error, reason}`.
  """
  @callback delete(String.t(), keyword()) :: :ok | {:error, term()}
end
