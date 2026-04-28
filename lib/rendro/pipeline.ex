defmodule Rendro.Pipeline do
  @moduledoc """
  Orchestrates the render pipeline: build -> compose -> measure -> paginate -> render -> validate.

  Each stage returns `{:ok, result} | {:error, reason}`. The pipeline halts
  on the first error and returns it to the caller.

  All stages are instrumented with `:telemetry.span/3`. A top-level
  `[:rendro, :render]` span wraps the full pipeline, and each stage emits
  `[:rendro, :pipeline, :stage_name]` events.

  The `:max_pages` policy guard runs after `:paginate` and before `:render`
  (page count is final after pagination); the `:max_bytes` policy guard
  runs inside the `:validate` stage (output size is only knowable post-render).
  """

  alias Rendro.Error
  alias Rendro.Pipeline.{Build, Compose, Measure, Paginate, Render, Validate}

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
          document_type: base_meta.document_type,
          deterministic: base_meta.deterministic,
          stage: :render,
          status: :ok,
          page_count: length(doc.pages),
          byte_size: byte_size(pdf_binary)
        }

      {:error, %Error{} = error} ->
        %{
          render_id: base_meta.render_id,
          document_type: base_meta.document_type,
          deterministic: base_meta.deterministic,
          stage: error.stage,
          status: :error,
          page_count: length(doc.pages),
          byte_size: 0,
          error: %{kind: error.reason, stage: error.stage}
        }
    end
  end

  defp run_stages(doc, base_meta, policies) do
    with {:ok, doc} <- span(:build, base_meta, fn -> Build.run(doc) end, doc),
         {:ok, doc} <- span(:compose, base_meta, fn -> Compose.run(doc) end, doc),
         {:ok, doc} <- span(:measure, base_meta, fn -> Measure.run(doc) end, doc),
         {:ok, doc} <- span(:paginate, base_meta, fn -> Paginate.run(doc) end, doc),
         :ok <- validate_policy(:pages, doc, policies, base_meta),
         {:ok, pdf_binary} <- span(:render, base_meta, fn -> Render.run(doc) end, doc) do
      span(:validate, base_meta, fn -> Validate.run(pdf_binary, doc) end, doc)
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

  defp span(stage, base_meta, fun, last_doc) do
    start_meta = Map.put(base_meta, :stage, stage)

    :telemetry.span([:rendro, :pipeline, stage], start_meta, fn ->
      case fun.() do
        {:ok, result} ->
          {{:ok, result}, stage_stop_meta(stage, :ok, result, last_doc, base_meta)}

        {:error, %Error{} = error} ->
          {{:error, error}, stage_stop_meta(stage, {:error, error}, nil, last_doc, base_meta)}

        {:error, reason} ->
          error = Error.from_stage(stage, reason, base_meta)
          {{:error, error}, stage_stop_meta(stage, {:error, error}, nil, last_doc, base_meta)}
      end
    end)
  end

  defp stage_stop_meta(stage, status_or_error, result, last_doc, base_meta) do
    page_count = derive_page_count(result, last_doc)
    byte_size = derive_byte_size(stage, result)

    base = %{
      render_id: base_meta.render_id,
      document_type: base_meta.document_type,
      deterministic: base_meta.deterministic,
      stage: stage,
      status: if(status_or_error == :ok, do: :ok, else: :error),
      page_count: page_count,
      byte_size: byte_size
    }

    case status_or_error do
      :ok -> base
      {:error, %Error{} = e} -> Map.put(base, :error, %{kind: e.reason, stage: e.stage})
    end
  end

  defp derive_page_count(%Rendro.Document{pages: pages}, _last), do: length(pages)
  defp derive_page_count(_result, %Rendro.Document{pages: pages}), do: length(pages)
  defp derive_page_count(_result, _last), do: 0

  defp derive_byte_size(:render, pdf) when is_binary(pdf), do: byte_size(pdf)
  defp derive_byte_size(:validate, pdf) when is_binary(pdf), do: byte_size(pdf)
  defp derive_byte_size(_stage, _result), do: 0
end
