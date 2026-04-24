defmodule Rendro.Test.TelemetryHelper do
  @moduledoc false

  def attach(test_pid \\ self()) do
    events = Rendro.Telemetry.all_event_names()
    handler_id = "test-#{System.unique_integer([:positive])}"

    :telemetry.attach_many(
      handler_id,
      events,
      fn event, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, event, measurements, metadata})
      end,
      nil
    )

    handler_id
  end

  def detach(handler_id) do
    :telemetry.detach(handler_id)
  end

  def collect_events(timeout \\ 100) do
    collect_events([], timeout)
  end

  defp collect_events(acc, timeout) do
    receive do
      {:telemetry_event, event, measurements, metadata} ->
        collect_events([{event, measurements, metadata} | acc], timeout)
    after
      timeout -> Enum.reverse(acc)
    end
  end
end
