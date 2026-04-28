if Code.ensure_loaded?(Threadline) do
  defmodule Rendro.Adapters.Threadline do
    @moduledoc """
    Optional Threadline integration that funnels Rendro render events into
    `Threadline.record_action/2` for ecosystem-wide audit trails.

    This module is only compiled when `Threadline` is available at compile
    time (via `Code.ensure_loaded?/1`). If `:threadline` is not in your
    project's dependencies, this module is absent and core Rendro is
    unaffected.

    ## Usage

    Attach the handler once at application start (e.g. from your
    `Application.start/2` callback):

        Rendro.Adapters.Threadline.attach()

    The handler subscribes to:

      * `[:rendro, :render, :stop]` — successful or failed renders
      * `[:rendro, :render, :exception]` — crashed renders

    On `:stop` with `status: :ok` → `Threadline.record_action(:render_succeeded, metadata)`.
    On `:stop` with `status: :error` or `:exception` → `Threadline.record_action(:render_failed, metadata)`.

    ## PII safety

    Only telemetry metadata is forwarded. Document bodies, attachment
    binaries, and rendered PDFs are NOT included in audit events. The
    metadata fields are: `:render_id`, `:stage`, `:status`, `:page_count`,
    `:byte_size`, `:duration`, `:document_type`, `:deterministic`, and the
    nested `:error` map on failed renders.

    ## Detaching

    To remove the handler (e.g. in a test teardown):

        Rendro.Adapters.Threadline.detach()
    """

    @behaviour Rendro.Audit

    @handler_id "rendro-threadline-audit"
    @events [
      [:rendro, :render, :stop],
      [:rendro, :render, :exception]
    ]

    @doc """
    Attaches the Threadline audit handler to Rendro telemetry events.

    Returns `:ok` on success or if the handler was already attached.
    """
    @spec attach() :: :ok
    def attach do
      case :telemetry.attach_many(@handler_id, @events, &__MODULE__.handle_event/4, nil) do
        :ok -> :ok
        {:error, :already_exists} -> :ok
      end
    end

    @doc """
    Detaches the Threadline audit handler. Safe to call when not attached.
    """
    @spec detach() :: :ok
    def detach do
      _ = :telemetry.detach(@handler_id)
      :ok
    end

    @doc false
    @spec handle_event(list(atom()), map(), map(), term()) :: :ok | {:error, term()}
    def handle_event([:rendro, :render, :stop], measurements, metadata, _config) do
      meta = build_audit_metadata(measurements, metadata)

      action =
        if Map.get(metadata, :status) == :error, do: :render_failed, else: :render_succeeded

      track_render(meta.render_id, Map.put(meta, :action, action))
    end

    def handle_event([:rendro, :render, :exception], measurements, metadata, _config) do
      meta = build_audit_metadata(measurements, metadata)
      track_render(meta.render_id, Map.put(meta, :action, :render_failed))
    end

    @impl Rendro.Audit
    def track_render(render_id, metadata) do
      action = Map.get(metadata, :action, :render_succeeded)
      payload = Map.put(metadata, :render_id, render_id)

      try do
        case Threadline.record_action(action, payload) do
          :ok -> :ok
          {:ok, _result} -> :ok
          {:error, reason} -> {:error, reason}
          other -> {:error, {:unexpected_return, other}}
        end
      rescue
        e -> {:error, {:exception, e}}
      end
    end

    defp build_audit_metadata(measurements, metadata) do
      metadata
      |> Map.take([
        :render_id,
        :stage,
        :status,
        :page_count,
        :byte_size,
        :document_type,
        :deterministic,
        :error,
        :kind,
        :reason
      ])
      |> Map.put(:duration, Map.get(measurements, :duration))
    end
  end
end
