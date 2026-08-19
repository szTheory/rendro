defmodule Rendro.Test.HexBuildCache do
  @moduledoc false
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
  def get_build_output, do: package_build!().result

  def get_build_output(runner) when is_function(runner, 0) do
    Agent.get_and_update(
      __MODULE__,
      fn
        nil ->
          result = runner.()
          {result, %{result: result, tarball_path: nil}}

        %{result: result} = cached ->
          {result, cached}
      end,
      :infinity
    )
  end

  @doc """
  Returns the immutable, per-test-VM archive produced by the cached package build.

  Hex normally writes `<app>-<version>.tar` in the repository root. That path is
  shared by concurrent test processes, so callers must inspect this isolated path
  rather than the root-level convenience artifact.
  """
  def tarball_path!, do: package_build!().tarball_path

  defp package_build! do
    Agent.get_and_update(
      __MODULE__,
      fn
        nil ->
          tarball_path =
            Path.join(
              System.tmp_dir!(),
              "rendro-hex-build-#{System.unique_integer([:positive, :monotonic])}.tar"
            )

          result =
            System.cmd("mix", ["hex.build", "--output", tarball_path],
              env: [{"MIX_ENV", "dev"}],
              stderr_to_stdout: true
            )

          cached = %{result: result, tarball_path: tarball_path}
          {cached, cached}

        %{tarball_path: nil} ->
          raise "HexBuildCache cannot provide a tarball after a custom runner"

        cached ->
          {cached, cached}
      end,
      :infinity
    )
  end
end
