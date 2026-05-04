defmodule Rendro.Audit do
  @moduledoc """
  Behavior for rendering audit trails and lifecycle telemetry.

  Defines the contract for persisting or forwarding `Rendro` render events
  (starts, stops, exceptions) to external systems (e.g. `Threadline`, logs)
  without coupling core rendering logic to those systems.
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
