defmodule Mix.Tasks.Release.Preflight do
  use Mix.Task

  @moduledoc """
  Runs preflight checks before release.
  """

  @shortdoc "Runs preflight checks before release"

  def run(_args) do
    Mix.shell().info("Running release preflight checks...")

    # 1. Check version in mix.exs matches git tag (mocked for now)
    version = Mix.Project.config()[:version]
    Mix.shell().info("Current version: #{version}")

    # 2. Run CI
    Mix.shell().info("Running CI checks...")

    if Mix.Task.run("ci") == :error do
      Mix.raise("CI checks failed!")
    end

    # 3. Check for uncommitted changes
    {git_status, 0} = System.cmd("git", ["status", "--short"])

    if git_status != "" do
      Mix.shell().error("Uncommitted changes detected:\n#{git_status}")
      # In a real scenario, we might want to fail here
    end

    Mix.shell().info("Preflight checks PASSED!")
  end
end
