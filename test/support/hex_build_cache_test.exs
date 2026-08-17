defmodule Rendro.Test.HexBuildCacheTest do
  use ExUnit.Case, async: false

  alias Rendro.Test.HexBuildCache

  setup do
    # Reset the cache state for testing without killing the global process
    if Process.whereis(HexBuildCache) do
      Agent.update(HexBuildCache, fn _ -> nil end)
    else
      start_supervised(HexBuildCache)
    end

    on_exit(fn ->
      # This test deliberately stores a synthetic result. Clear it so later
      # package contracts always invoke the real Hex build runner.
      Agent.update(HexBuildCache, fn _ -> nil end)
    end)

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
    assert {"test_output", 0} =
             HexBuildCache.get_build_output(fn ->
               send(parent, :runner_called_unexpectedly)
               {"error", 1}
             end)

    refute_received :runner_called_unexpectedly
  end
end
