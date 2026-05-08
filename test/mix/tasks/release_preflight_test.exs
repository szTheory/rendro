defmodule Mix.Tasks.Release.PreflightTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Release.Preflight

  test "fails in phase 1 before any expensive checks when the worktree is dirty" do
    runner =
      command_runner_for(%{
        {"git", ["status", "--short"]} => {" M README.md\n", 0},
        {"git", ["describe", "--tags", "--exact-match"]} => {"v0.3.0\n", 0},
        {"mix", ["hex.build", "--unpack"]} => {"hex build ok", 0}
      })

    Application.put_env(:rendro, :release_preflight_command_runner, runner)

    on_exit(fn ->
      Application.delete_env(:rendro, :release_preflight_command_runner)
    end)

    {messages, exit_reason} =
      capture_shell_messages(fn ->
        catch_exit(Preflight.run([]))
      end)

    output = Enum.join(messages, "\n")

    assert exit_reason == {:shutdown, 1}
    assert output =~ "Phase 1: boundary blockers"
    assert output =~ "Clean worktree: FAIL"
    assert output =~ "RELEASE PREFLIGHT COMPLETE"
    assert output =~ "Overall: FAIL"
    refute output =~ "Phase 2: release parity checks"
    refute output =~ "CI: PASS"

    assert_received {:preflight_command, "git", ["status", "--short"]}
    assert_received {:preflight_command, "git", ["describe", "--tags", "--exact-match"]}
    refute_received {:preflight_command, "mix", ["ci"]}
  end

  test "runs every phase 2 check and exits only after the final summary" do
    runner =
      command_runner_for(%{
        {"git", ["status", "--short"]} => {"", 0},
        {"git", ["describe", "--tags", "--exact-match"]} => {"v0.3.0\n", 0},
        {"mix", ["ci"]} => {"ci ok", 0},
        {"mix", ["docs.contract"]} => {"docs drifted", 1},
        {"mix", ["hex.build", "--unpack"]} => {"hex build ok", 0},
        {"mix", ["hex.publish", "--dry-run", "--yes"]} => {"dry run ok", 0}
      })

    Application.put_env(:rendro, :release_preflight_command_runner, runner)

    on_exit(fn ->
      Application.delete_env(:rendro, :release_preflight_command_runner)
    end)

    {messages, exit_reason} =
      capture_shell_messages(fn ->
        catch_exit(Preflight.run([]))
      end)

    output = Enum.join(messages, "\n")

    assert exit_reason == {:shutdown, 1}
    assert output =~ "Phase 2: release parity checks"
    assert output =~ "Docs Contract: FAIL"
    assert output =~ "Hex Build Artifacts: PASS"
    assert output =~ "Hex Publish Dry Run: PASS"
    assert output =~ "RELEASE PREFLIGHT COMPLETE"
    assert output =~ "Overall: FAIL"

    assert message_index(output, "RELEASE PREFLIGHT COMPLETE") <
             message_index(output, "Overall: FAIL")

    assert_received {:preflight_command, "mix", ["ci"]}
    assert_received {:preflight_command, "mix", ["docs.contract"]}
    assert_received {:preflight_command, "mix", ["hex.build", "--unpack"]}
    assert_received {:preflight_command, "mix", ["hex.publish", "--dry-run", "--yes"]}
  end

  test "fails before phase 2 when the changelog release-tail pointer is missing" do
    changelog_path =
      Path.join(
        System.tmp_dir!(),
        "rendro-preflight-changelog-#{System.unique_integer([:positive])}.md"
      )

    File.write!(changelog_path, """
    # Changelog

    ## [0.2.0] - Unreleased

    ### Added

    - protection support without the canonical release-tail pointer
    """)

    on_exit(fn ->
      File.rm_rf(changelog_path)
    end)

    runner =
      command_runner_for(%{
        {"git", ["status", "--short"]} => {"", 0},
        {"git", ["describe", "--tags", "--exact-match"]} => {"v0.2.0\n", 0},
        {"mix", ["hex.build", "--unpack"]} => {"hex build ok", 0}
      })

    {messages, result} =
      capture_shell_messages(fn ->
        Preflight.run_with_context(%{
          project_config: [
            version: "0.2.0",
            package: [licenses: ["Apache-2.0"], links: %{"GitHub" => "https://example.test"}]
          ],
          command_runner: runner,
          changelog_path: changelog_path
        })
      end)

    output = Enum.join(messages, "\n")

    assert match?({:error, _}, result)
    assert output =~ "Changelog release tail: FAIL"
    assert output =~ "CHANGELOG.md is missing the current release-tail protected-delivery pointer"
    refute output =~ "Phase 2: release parity checks"
    refute_received {:preflight_command, "mix", ["ci"]}
  end

  defp command_runner_for(responses) do
    test_pid = self()

    fn command, args, _opts ->
      send(test_pid, {:preflight_command, command, args})

      if command == "mix" and args == ["hex.build", "--unpack"] do
        version = Mix.Project.config()[:version]
        File.mkdir_p!("rendro-#{version}/guides")

        Enum.each(
          [
            "LICENSE",
            "README.md",
            "CHANGELOG.md",
            "guides/api_stability.md",
            "guides/branding.md",
            "guides/integrations.md"
          ],
          fn file ->
            File.touch!(Path.join("rendro-#{version}", file))
          end
        )

        File.touch!("rendro-#{version}.tar")
      end

      Map.fetch!(responses, {command, args})
    end
  end

  defp capture_shell_messages(fun) do
    original_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    result =
      try do
        fun.()
      after
        Mix.shell(original_shell)
      end

    {flush_shell_messages([]), result}
  end

  defp flush_shell_messages(messages) do
    receive do
      {:mix_shell, _level, payload} ->
        flush_shell_messages([IO.iodata_to_binary(payload) | messages])
    after
      0 -> Enum.reverse(messages)
    end
  end

  defp message_index(output, needle) do
    case :binary.match(output, needle) do
      {index, _length} -> index
      :nomatch -> flunk("expected #{inspect(needle)} to appear in #{inspect(output)}")
    end
  end
end
