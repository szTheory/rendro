defmodule Rendro.Error do
  @moduledoc """
  Structured diagnostics for render failures.

  The pipeline wraps stage failures in this struct so callers receive
  actionable context (`what/where/why/next`) plus correlation metadata.
  """

  @enforce_keys [:what, :where, :why, :next, :stage]
  defstruct [:what, :where, :why, :next, :stage, :reason, :render_id, details: %{}]

  @type t :: %__MODULE__{
          what: String.t(),
          where: String.t(),
          why: String.t(),
          next: String.t(),
          stage: atom(),
          reason: term() | nil,
          render_id: String.t() | nil,
          details: map()
        }

  @spec from_stage(atom(), term(), map()) :: t()
  def from_stage(stage, reason, context \\ %{}) when is_atom(stage) do
    %__MODULE__{
      what: what(stage, reason),
      where: "Rendro.Pipeline.#{stage_module_suffix(stage)}",
      why: why(reason),
      next: next_step(stage, reason),
      stage: stage,
      reason: reason,
      render_id: Map.get(context, :render_id),
      details: %{
        document_type: Map.get(context, :document_type),
        deterministic: Map.get(context, :deterministic)
      }
    }
  end

  defp what(:build, _reason), do: "Input document failed pipeline validation."
  defp what(:compose, _reason), do: "Document composition failed before measurement."
  defp what(:measure, _reason), do: "Block measurement failed while computing dimensions."
  defp what(:paginate, _reason), do: "Pagination failed while assigning content to pages."
  defp what(:render, _reason), do: "PDF serialization failed during render."
  defp what(stage, _reason), do: "Render pipeline failed in stage #{inspect(stage)}."

  defp why(reason) when is_atom(reason),
    do: reason |> Atom.to_string() |> String.replace("_", " ")

  defp why(reason) when is_binary(reason), do: reason
  defp why(reason), do: Exception.format_banner(:error, reason)

  defp next_step(:build, :no_pages) do
    "Add at least one page before rendering (Rendro.document(pages: [...]))."
  end

  defp next_step(:build, :invalid_page_dimensions) do
    "Ensure every page has positive width and height values."
  end

  defp next_step(:build, :invalid_document) do
    "Pass a %Rendro.Document{} struct to Rendro.render/1 or Rendro.render/2."
  end

  defp next_step(:paginate, :content_overflow) do
    "Reduce the height of the failing block or increase page dimensions (margin/height)."
  end

  defp next_step(:paginate, :max_pages_exceeded) do
    "Reduce document length or increase the :max_pages policy limit."
  end

  defp next_step(:render, :max_bytes_exceeded) do
    "Reduce content complexity or increase the :max_bytes policy limit."
  end

  defp next_step(:render, :timeout) do
    "Optimize document complexity or increase the :timeout policy limit."
  end

  defp next_step(:render, _reason) do
    "Inspect telemetry events for the same render_id and verify PDF object generation inputs."
  end

  defp next_step(_stage, _reason) do
    "Inspect stage inputs and rerun with telemetry attached for the same render_id."
  end

  defp stage_module_suffix(stage) do
    stage
    |> Atom.to_string()
    |> Macro.camelize()
  end
end
