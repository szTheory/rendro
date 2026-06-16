defmodule Rendro.Test.HexBuildCacheTest do
  use ExUnit.Case, async: false

  alias Rendro.Test.HexBuildCache

  setup do
    # Ensure the Agent is started, or restart it to have a clean state for testing
    if pid = Process.whereis(HexBuildCache) do
      Process.exit(pid, :kill)
      # Wait for it to die
      Process.sleep(10)
    end
    start_supervised(HexBuildCache)
    :ok
  end

  test "get_build_output/1 runs the build and caches the result" do
    parent = self()

    runner = fn ->
      send(parent, :runner_called)
      {"test_output", 0}
    end

    assert {"test_output", 0} = HexBuildCache.get_build_output(runner)
    assert_received :runner_called

    # Subsequent call should return cached result without calling runner
    assert {"test_output", 0} = HexBuildCache.get_build_output(fn ->
      send(parent, :runner_called_unexpectedly)
      {"error", 1}
    end)

    refute_received :runner_called_unexpectedly
  end
end
