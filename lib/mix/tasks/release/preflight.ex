defmodule Mix.Tasks.Release.Preflight do
  use Mix.Task

  @moduledoc """
  Runs preflight checks before release.
  """
  @moduledoc tags: [:adapter]

  @shortdoc "Runs preflight checks before release"
  @phase_2_checks [
    {"CI", ["ci"]},
    {"Docs Contract", ["docs.contract"]},
    {"Hex Build Unpack", ["hex.build", "--unpack"]},
    {"Hex Publish Dry Run", ["hex.publish", "--dry-run", "--yes"]},
    {"Hex Audit", ["hex.audit"]},
    {"Deps Audit", ["deps.audit", "--ignore-file", ".mix_audit.ignore"]}
  ]

  def run(_args) do
    case run_with_context(default_context()) do
      {:ok, _results} ->
        :ok

      {:error, _results} ->
        exit({:shutdown, 1})
    end
  end

  def run_with_context(context) do
    version = context.project_config[:version]
    Mix.shell().info("=== RELEASE PREFLIGHT ===")
    Mix.shell().info("Version: #{version}")
    Mix.shell().info("Phase 1: boundary blockers")

    phase_1_results = [
      check_clean_worktree(context),
      check_exact_tag(context, version),
      check_package_metadata(context.project_config),
      check_source_ref_parity(context, version),
      check_changelog_release_tail(context),
      check_hex_artifacts(context, version)
    ]

    Enum.each(phase_1_results, &print_result/1)

    if Enum.any?(phase_1_results, &(&1.status == :fail)) do
      print_summary(phase_1_results, [])
      {:error, %{phase_1: phase_1_results, phase_2: []}}
    else
      Mix.shell().info("Phase 2: release parity checks")

      phase_2_results =
        Enum.map(@phase_2_checks, fn {name, args} ->
          result = run_mix_check(context, name, args)
          print_result(result)
          result
        end)

      print_summary(phase_1_results, phase_2_results)

      if Enum.any?(phase_2_results, &(&1.status == :fail)) do
        {:error, %{phase_1: phase_1_results, phase_2: phase_2_results}}
      else
        {:ok, %{phase_1: phase_1_results, phase_2: phase_2_results}}
      end
    end
  end

  defp default_context do
    project_config = Mix.Project.config()

    command_runner =
      Application.get_env(:rendro, :release_preflight_command_runner, &streaming_system_cmd/3)

    %{
      project_config: project_config,
      command_runner: command_runner,
      env: System.get_env()
    }
  end

  defp check_clean_worktree(context) do
    case run_command(context, "git", ["status", "--short"]) do
      {"", 0} ->
        pass("Clean worktree")

      {output, 0} ->
        fail("Clean worktree", "uncommitted changes detected:\n#{output}")

      {output, status} ->
        fail("Clean worktree", "git status failed (#{status})\n#{output}")
    end
  end

  defp check_exact_tag(context, version) do
    expected_tag = "v#{version}"

    case run_command(context, "git", ["describe", "--tags", "--exact-match"]) do
      {^expected_tag <> "\n", 0} ->
        pass("Exact tag parity")

      {actual_tag, 0} ->
        fail("Exact tag parity", "expected #{expected_tag}, got #{String.trim(actual_tag)}")

      {output, _status} ->
        fail("Exact tag parity", "expected #{expected_tag}, got no exact tag\n#{output}")
    end
  end

  defp check_package_metadata(project_config) do
    package = project_config[:package] || []
    missing = []
    missing = if package[:licenses] in [nil, []], do: ["licenses" | missing], else: missing
    missing = if package[:links] in [nil, %{}], do: ["links" | missing], else: missing

    if missing == [] do
      pass("Package metadata")
    else
      fail(
        "Package metadata",
        "missing metadata fields: #{missing |> Enum.reverse() |> Enum.join(", ")}"
      )
    end
  end

  defp check_changelog_release_tail(context) do
    changelog_path = Map.get(context, :changelog_path, "CHANGELOG.md")
    version = context.project_config[:version]

    with {:ok, changelog} <- File.read(changelog_path),
         true <- Regex.match?(~r/## \[#{version}\] - (\d{4}-\d{2}-\d{2}|Unreleased)/, changelog) do
      pass("Changelog release tail")
    else
      false ->
        fail(
          "Changelog release tail",
          "CHANGELOG.md is missing the current release-tail pointer or date"
        )

      {:error, reason} ->
        fail("Changelog release tail", "unable to read CHANGELOG.md: #{inspect(reason)}")
    end
  end

  defp check_hex_artifacts(context, version) do
    case run_command(context, "mix", ["hex.build", "--unpack"]) do
      {_output, 0} ->
        dir = "rendro-#{version}"

        required_files = [
          "LICENSE",
          "README.md",
          "CHANGELOG.md",
          "guides/api_stability.md",
          "guides/branding.md",
          "guides/integrations.md"
        ]

        missing_files =
          Enum.reject(required_files, fn file ->
            File.exists?(Path.join(dir, file))
          end)

        forbidden_paths = [
          "priv/support_matrix.json",
          "priv/viewer_evidence/",
          "priv/guardrails/",
          "scripts/",
          "test/"
        ]

        leaked_files =
          Enum.filter(forbidden_paths, fn path ->
            File.exists?(Path.join(dir, path))
          end)

        File.rm_rf!(dir)
        File.rm(dir <> ".tar")

        cond do
          missing_files != [] ->
            fail(
              "Hex Build Artifacts",
              "missing files in unpacked artifact: #{Enum.join(missing_files, ", ")}"
            )

          leaked_files != [] ->
            fail(
              "Hex Build Artifacts",
              "forbidden files leaked into unpacked artifact: #{Enum.join(leaked_files, ", ")}"
            )

          true ->
            pass("Hex Build Artifacts")
        end

      {output, status} ->
        fail("Hex Build Artifacts", "hex.build failed (#{status})\n#{output}")
    end
  end

  defp check_source_ref_parity(context, version) do
    docs_config = context.project_config[:docs] || []
    expected_ref = "v#{version}"

    if docs_config[:source_ref] == expected_ref do
      pass("Source Ref Parity")
    else
      fail(
        "Source Ref Parity",
        "expected docs[:source_ref] to be #{expected_ref}, got #{inspect(docs_config[:source_ref])}"
      )
    end
  end

  defp run_mix_check(context, "Hex Publish Dry Run" = name, args) do
    if authenticated_hex?(context) do
      do_run_mix_check(name, args, run_command(context, "mix", args))
    else
      command = "printf 'n\\n' | mix #{Enum.join(args, " ")}"

      case run_command(context, "sh", ["-c", command]) do
        {output, 0} ->
          %{name: name, status: :pass, output: output, command: "mix #{Enum.join(args, " ")}"}

        {output, _status} ->
          if anonymous_publish_dry_run_boundary?(output) do
            %{
              name: name,
              status: :pass,
              output: output,
              command: "mix #{Enum.join(args, " ")}"
            }
          else
            fail(name, "hex.publish dry-run failed before authentication boundary\n#{output}")
          end
      end
    end
  end

  defp run_mix_check(context, name, args) do
    do_run_mix_check(name, args, run_command(context, "mix", args))
  end

  defp do_run_mix_check(name, args, result) do
    case result do
      {output, 0} ->
        %{name: name, status: :pass, output: output, command: Enum.join(["mix" | args], " ")}

      {output, status} ->
        %{
          name: name,
          status: :fail,
          output: output,
          code: status,
          command: Enum.join(["mix" | args], " ")
        }
    end
  end

  defp authenticated_hex?(context) do
    context
    |> Map.get(:env, %{})
    |> Map.get("HEX_API_KEY")
    |> case do
      nil -> false
      "" -> false
      _key -> true
    end
  end

  defp anonymous_publish_dry_run_boundary?(output) do
    output =~ "Building " and
      output =~ "Publishing package to public repository hexpm" and
      output =~ "No authenticated user found"
  end

  defp run_command(context, command, args) do
    Mix.shell().info("$ #{Enum.join([command | args], " ")}")
    context.command_runner.(command, args, stderr_to_stdout: true)
  end

  defp streaming_system_cmd(command, args, opts) do
    System.cmd(
      command,
      args,
      Keyword.put_new(opts, :into, %Rendro.Release.StreamingCommandCapture{})
    )
  end

  defp print_result(%{name: name, status: :pass}) do
    Mix.shell().info("  - #{name}: PASS")
  end

  defp print_result(%{name: name, status: :fail, output: output}) do
    Mix.shell().error("  - #{name}: FAIL")
    Mix.shell().error(output)
  end

  defp print_summary(phase_1_results, phase_2_results) do
    Mix.shell().info("RELEASE PREFLIGHT COMPLETE")
    Mix.shell().info("Summary:")

    Enum.each(phase_1_results, fn %{name: name, status: status} ->
      Mix.shell().info("  - [Phase 1] #{name}: #{String.upcase(to_string(status))}")
    end)

    Enum.each(phase_2_results, fn %{name: name, status: status} ->
      Mix.shell().info("  - [Phase 2] #{name}: #{String.upcase(to_string(status))}")
    end)

    if Enum.any?(phase_1_results ++ phase_2_results, &(&1.status == :fail)) do
      Mix.shell().error("Overall: FAIL")
    else
      Mix.shell().info("Overall: PASS")
    end
  end

  defp pass(name), do: %{name: name, status: :pass}
  defp fail(name, output), do: %{name: name, status: :fail, output: output}
end
