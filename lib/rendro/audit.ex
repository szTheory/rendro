defmodule Rendro.Audit do
  @moduledoc """
  Behavior for audit logging of Rendro render lifecycle events.

  Implementations record render activity to an audit backend (e.g. `Threadline`,
  a custom log table, or an external SIEM). The behavior is intentionally
  minimal: a single callback that receives a render id and a metadata map.

  ## Adopting

      defmodule MyApp.RenderAuditor do
        @behaviour Rendro.Audit

        @impl true
        def track_render(render_id, metadata) do
          MyApp.AuditLog.insert(render_id, metadata)
          :ok
        end
      end

  ## PII safety

  Implementations should treat the metadata map as untrusted input. Rendro
  emits Telemetry metadata that has already been stripped of document content
  (`render_id`, `stage`, `status`, `page_count`, `byte_size`, `duration`,
  `document_type`, `deterministic`). Implementations MUST NOT log raw document
  bodies, attachment binaries, or user-controlled strings without redaction.

  ## Built-in adapters

  - `Rendro.Adapters.Threadline` (optional) — wires Telemetry render events
    into `Threadline.record_action/2` for ecosystem audit trails.
  """

  @typedoc "Stable identifier for a single render invocation"
  @type render_id :: String.t()

  @typedoc "Audit metadata map. Keys mirror Rendro telemetry metadata."
  @type metadata :: %{optional(atom()) => term()}

  @doc """
  Records a render lifecycle event in the audit backend.

  Returns `:ok` on success. Returns `{:error, reason}` on failure; callers
  should NOT raise — audit failures must not break the render pipeline.
  """
  @callback track_render(render_id, metadata) :: :ok | {:error, term()}
end
