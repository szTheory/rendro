defmodule Rendro.Pipeline do
  @moduledoc false

  alias Rendro.Error
  alias Rendro.Pipeline.{Build, Compose, Measure, Paginate, Render, Validate}

  @spec run(Rendro.Document.t()) :: {:ok, binary()} | {:error, Rendro.Error.t()}
  def run(%Rendro.Document{} = doc) do
    case run_with_diagnostics(doc) do
      {:ok, pdf_binary, _doc} -> {:ok, pdf_binary}
      error -> error
    end
  end

  @doc """
  Runs the pipeline and returns the generated PDF binary along with the final paginated document
  containing populated diagnostics.
  """
  @spec run_with_diagnostics(Rendro.Document.t()) ::
          {:ok, binary(), Rendro.Document.t()} | {:error, Rendro.Error.t()}
  def run_with_diagnostics(%Rendro.Document{} = doc) do
    render_id = Rendro.Telemetry.generate_render_id()
    render_opts = Map.get(doc.options, :render, [])
    deterministic = Keyword.get(render_opts, :deterministic, false) == true
    policies = Map.get(doc.options, :policies, [])

    base_meta = %{
      render_id: render_id,
      document_type: :pdf,
      deterministic: deterministic
    }

    with {:ok, timeout} <- validate_timeout_policy(policies, base_meta) do
      started_at = System.monotonic_time()

      :telemetry.execute(
        Rendro.Telemetry.render_prefix() ++ [:start],
        %{},
        Map.put(base_meta, :stage, :render)
      )

      progress_ref = make_ref()
      owner = self()

      task =
        Task.async(fn ->
          run_stages_with_capture(doc, base_meta, policies, owner, progress_ref)
        end)

      case Task.yield(task, timeout) || Task.shutdown(task) do
        {:ok, {:ok, result}} ->
          latest_progress_page_count(progress_ref, length(doc.pages))
          emit_render_stop(result, doc, base_meta, started_at)
          unwrap_run_result(result)

        {:ok, {:exception, kind, reason, stacktrace}} ->
          latest_progress_page_count(progress_ref, length(doc.pages))
          emit_render_exception(base_meta, started_at, kind, reason, stacktrace)
          :erlang.raise(kind, reason, stacktrace)

        nil ->
          page_count = latest_progress_page_count(progress_ref, length(doc.pages))
          error = Error.from_stage(:render, :timeout, base_meta)
          result = {:error_with_page_count, error, page_count}
          emit_render_stop(result, doc, base_meta, started_at)
          {:error, error}
      end
    end
  end

  defp build_stop_meta(result, doc, base_meta) do
    case result do
      {:ok, {pdf_binary, %Rendro.Document{} = final_doc}} ->
        %{
          render_id: base_meta.render_id,
          document_type: base_meta.document_type,
          deterministic: base_meta.deterministic,
          stage: :render,
          status: :ok,
          page_count: length(final_doc.pages),
          byte_size: byte_size(pdf_binary)
        }

      {:ok, pdf_binary} when is_binary(pdf_binary) ->
        %{
          render_id: base_meta.render_id,
          document_type: base_meta.document_type,
          deterministic: base_meta.deterministic,
          stage: :render,
          status: :ok,
          page_count: length(doc.pages),
          byte_size: byte_size(pdf_binary)
        }

      {:error_with_page_count, %Error{} = error, page_count} ->
        %{
          render_id: base_meta.render_id,
          document_type: base_meta.document_type,
          deterministic: base_meta.deterministic,
          stage: error.stage,
          status: :error,
          page_count: page_count,
          byte_size: 0,
          error: %{kind: error.reason, stage: error.stage}
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

  defp emit_render_stop(result, doc, base_meta, started_at) do
    :telemetry.execute(
      Rendro.Telemetry.render_prefix() ++ [:stop],
      %{duration: System.monotonic_time() - started_at},
      build_stop_meta(result, doc, base_meta)
    )
  end

  defp emit_render_exception(base_meta, started_at, kind, reason, stacktrace) do
    :telemetry.execute(
      Rendro.Telemetry.render_prefix() ++ [:exception],
      %{duration: System.monotonic_time() - started_at},
      Map.merge(base_meta, %{kind: kind, reason: reason, stacktrace: stacktrace, stage: :render})
    )
  end

  defp validate_timeout_policy(policies, base_meta) do
    case Keyword.get(policies, :timeout, 30_000) do
      value when is_integer(value) and value >= 0 -> {:ok, value}
      value -> {:error, Error.from_stage(:render, {:invalid_policy, :timeout, value}, base_meta)}
    end
  end

  defp run_stages_with_capture(doc, base_meta, policies, owner, progress_ref) do
    {:ok, run_stages(doc, base_meta, policies, owner, progress_ref)}
  rescue
    exception ->
      {:exception, :error, exception, __STACKTRACE__}
  catch
    kind, reason ->
      {:exception, kind, reason, __STACKTRACE__}
  end

  defp unwrap_run_result({:ok, {pdf_binary, doc}}), do: {:ok, pdf_binary, doc}
  defp unwrap_run_result(result), do: result

  defp run_stages(doc, base_meta, policies, owner, progress_ref) do
    with {:ok, doc} <- span(:build, base_meta, fn -> Build.run(doc) end, doc),
         {:ok, doc} <- span(:compose, base_meta, fn -> Compose.run(doc) end, doc),
         {:ok, doc} <- span(:measure, base_meta, fn -> Measure.run(doc) end, doc),
         {:ok, doc} <- span(:paginate, base_meta, fn -> Paginate.run(doc) end, doc),
         :ok <- report_page_count(owner, progress_ref, doc),
         :ok <- validate_policy(:pages, doc, policies, base_meta),
         {:ok, pdf_binary} <- span(:render, base_meta, fn -> Render.run(doc) end, doc),
         {:ok, pdf_binary} <-
           span(:validate, base_meta, fn -> Validate.run(pdf_binary, doc) end, doc) do
      {:ok, {pdf_binary, doc}}
    end
  end

  defp report_page_count(owner, progress_ref, %Rendro.Document{pages: pages}) do
    send(owner, {:rendro_progress_page_count, progress_ref, length(pages)})
    :ok
  end

  defp latest_progress_page_count(progress_ref, fallback) do
    receive do
      {:rendro_progress_page_count, ^progress_ref, page_count} ->
        latest_progress_page_count(progress_ref, page_count)
    after
      0 -> fallback
    end
  end
end
