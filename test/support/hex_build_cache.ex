defmodule Rendro.Test.HexBuildCache do
  @moduledoc """
  An Agent to cache the result of `mix hex.build` during test runs.

  This avoids redundant IO operations, reducing test execution time and
  preventing concurrency issues caused by mutating the shared `_build`
  directory.
  """
  use Agent

  @doc """
  Starts the cache Agent. It is registered under the module name.
  """
  def start_link(_opts \\ []) do
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end

  @doc """
  Gets the build output from the cache. If not present, executes the build
  using the provided runner, caches the result, and returns it.

  ## Examples

      {output, exit_code} = Rendro.Test.HexBuildCache.get_build_output()

  """
  def get_build_output(runner \\ &default_runner/0) do
    # Using Agent.update allows us to evaluate the expensive computation
    # inside the Agent process, but getting and updating might be slightly
    # better if we want to avoid blocking other callers entirely while computing?
    # Actually, evaluating inside the Agent blocks others, which is exactly
    # what we want to prevent concurrent builds.
    Agent.get_and_update(__MODULE__, fn
      nil ->
        result = runner.()
        {result, result}

      cached_result ->
        {cached_result, cached_result}
    end)
  end

  defp default_runner do
    System.cmd("mix", ["hex.build"], stderr_to_stdout: true)
  end
end
