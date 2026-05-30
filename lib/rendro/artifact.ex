defmodule Rendro.Artifact do
  @moduledoc """
  A pure data carrier containing the rendered PDF bytes, a deterministic hash,
  and structured diagnostics from the render pipeline.

  This is the primary boundary struct for async and ecosystem operations.
  """
  @moduledoc tags: [:stable]

  @enforce_keys [:binary, :hash, :diagnostics, :metadata]
  defstruct [:binary, :hash, :diagnostics, :metadata]

  @type t :: %__MODULE__{
          binary: binary(),
          hash: String.t(),
          diagnostics: list(map()),
          metadata: map()
        }

  @doc """
  Creates a new Artifact from the generated binary and the final Document.
  Hashes the binary using SHA-256 for deterministic caching and verification.
  """
  @spec new(binary(), Rendro.Document.t(), map()) :: t()
  def new(pdf_binary, %Rendro.Document{} = doc, base_metadata \\ %{}) do
    hash =
      :crypto.hash(:sha256, pdf_binary)
      |> Base.encode16(case: :lower)

    %__MODULE__{
      binary: pdf_binary,
      hash: hash,
      diagnostics: Map.get(doc, :diagnostics, []),
      metadata: Map.put(base_metadata, :page_count, length(Map.get(doc, :pages, [])))
    }
  end

  @doc """
  Wraps a transformed binary in a new artifact while preserving diagnostics and
  merging metadata from the source artifact.
  """
  @spec wrap(binary(), t(), map()) :: t()
  def wrap(pdf_binary, %__MODULE__{} = source, metadata_updates \\ %{}) do
    %__MODULE__{
      binary: pdf_binary,
      hash: hash_binary(pdf_binary),
      diagnostics: source.diagnostics,
      metadata: Map.merge(source.metadata, metadata_updates)
    }
  end

  defp hash_binary(pdf_binary) do
    :crypto.hash(:sha256, pdf_binary)
    |> Base.encode16(case: :lower)
  end
end
