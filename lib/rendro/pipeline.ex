defmodule Rendro.Pipeline do
  @moduledoc """
  Orchestrates the render pipeline: build -> measure -> paginate -> compose -> render.

  Each stage returns `{:ok, result} | {:error, reason}`. The pipeline halts
  on the first error and returns it to the caller.

  All stages are instrumented with `:telemetry.span/3`. A top-level
  `[:rendro, :render]` span wraps the full pipeline, and each stage emits
  `[:rendro, :pipeline, :stage_name]` events.
  """

  alias Rendro.Error
  alias Rendro.Pipeline.{Build, Compose, Measure, Paginate, Render}

  @spec run(Rendro.Document.t()) :: {:ok, binary()} | {:error, Rendro.Error.t()}
  def run(%Rendro.Document{} = doc) do
    render_id = Rendro.Telemetry.generate_render_id()
    render_opts = Map.get(doc.options, :render, [])
    deterministic = Keyword.get(render_opts, :deterministic, false) == true
    policies = Map.get(doc.options, :policies, [])

    base_meta = %{
      render_id: render_id,
      document_type: :pdf,
      deterministic: deterministic
    }

    timeout = Keyword.get(policies, :timeout, 30_000)

    task = Task.async(fn -> execute_with_telemetry(doc, base_meta, policies) end)

    case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, result} -> result
      nil -> {:error, Error.from_stage(:render, :timeout, base_meta)}
    end
  end

  defp execute_with_telemetry(doc, base_meta, policies) do
    :telemetry.span(Rendro.Telemetry.render_prefix(), Map.put(base_meta, :stage, :render), fn ->
      result = run_stages(doc, base_meta, policies)
      {result, build_stop_meta(result, doc, base_meta)}
    end)
  end

  defp build_stop_meta(result, doc, base_meta) do
    case result do
      {:ok, pdf_binary} ->
        %{
          render_id: base_meta.render_id,
          status: :ok,
          page_count: length(doc.pages),
          byte_size: byte_size(pdf_binary)
        }

      {:error, _error} ->
        %{render_id: base_meta.render_id, status: :error, page_count: 0, byte_size: 0}
    end
  end

  defp run_stages(doc, base_meta, policies) do
    with {:ok, doc} <- span(:build, base_meta, fn -> Build.run(doc) end, doc),
         {:ok, doc} <- span(:measure, base_meta, fn -> Measure.run(doc) end, doc),
         {:ok, doc} <- span(:paginate, base_meta, fn -> Paginate.run(doc) end, doc),
         :ok <- validate_policy(:pages, doc, policies, base_meta),
         {:ok, doc} <- span(:compose, base_meta, fn -> Compose.run(doc) end, doc),
         {:ok, pdf_binary} <- span(:render, base_meta, fn -> Render.run(doc) end, doc),
         :ok <- validate_policy(:bytes, pdf_binary, policies, base_meta) do
      {:ok, pdf_binary}
    end
  end

  defp validate_policy(:pages, %Rendro.Document{pages: pages}, policies, base_meta) do
    max_pages = Keyword.get(policies, :max_pages)

    if max_pages && length(pages) > max_pages do
      {:error, Error.from_stage(:paginate, :max_pages_exceeded, base_meta)}
    else
      :ok
    end
  end

  defp validate_policy(:bytes, pdf_binary, policies, base_meta) do
    max_bytes = Keyword.get(policies, :max_bytes)

    if max_bytes && byte_size(pdf_binary) > max_bytes do
      {:error, Error.from_stage(:render, :max_bytes_exceeded, base_meta)}
    else
      :ok
    end
  end

  defp span(stage, base_meta, fun, doc) do
    meta = Map.put(base_meta, :stage, stage)

    :telemetry.span([:rendro, :pipeline, stage], meta, fn ->
      case fun.() do
        {:ok, result} ->
          stop_meta =
            stage_stop_meta(stage, result, doc)
            |> Map.put(:render_id, base_meta.render_id)

          {{:ok, result}, stop_meta}

        {:error, %Error{} = error} ->
          stop_meta = %{render_id: base_meta.render_id, status: :error, page_count: 0, byte_size: 0}
          {{:error, error}, stop_meta}

        {:error, reason} ->
          error = Error.from_stage(stage, reason, base_meta)
          stop_meta = %{render_id: base_meta.render_id, status: :error, page_count: 0, byte_size: 0}
          {{:error, error}, stop_meta}
      end
    end)
  end

  defp stage_stop_meta(:render, pdf_binary, %Rendro.Document{pages: pages}) when is_binary(pdf_binary) do
    %{status: :ok, page_count: length(pages), byte_size: byte_size(pdf_binary)}
  end

  defp stage_stop_meta(_stage, %Rendro.Document{pages: pages}, _doc) do
    %{status: :ok, page_count: length(pages), byte_size: 0}
  end

  defp stage_stop_meta(_stage, _result, _doc) do
    %{status: :ok, page_count: 0, byte_size: 0}
  end
end
