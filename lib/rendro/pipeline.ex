defmodule Rendro.Pipeline do
  @moduledoc """
  Orchestrates the render pipeline: build -> compose -> measure -> paginate -> render.

  Each stage returns `{:ok, result} | {:error, reason}`. The pipeline halts
  on the first error and returns it to the caller.
  """

  alias Rendro.Pipeline.{Build, Compose, Measure, Paginate, Render}

  @spec run(Rendro.Document.t()) :: {:ok, binary()} | {:error, term()}
  def run(%Rendro.Document{} = doc) do
    with {:ok, doc} <- Build.run(doc),
         {:ok, doc} <- Compose.run(doc),
         {:ok, doc} <- Measure.run(doc),
         {:ok, doc} <- Paginate.run(doc) do
      Render.run(doc)
    end
  end
end
