Code.require_file("scripts/release_preflight_proof.exs", File.cwd!())

defmodule Rendro.ReleasePreflightProofTest do
  use ExUnit.Case, async: false

  alias Rendro.ReleasePreflightProof

  test "requires explicit ref and worktree arguments" do
    assert {:error, "missing required --ref vX.Y.Z or --current-version-tag"} =
             ReleasePreflightProof.parse_args([])

    assert {:error, "missing required --worktree PATH"} =
             ReleasePreflightProof.parse_args(["--ref", "v0.1.0"])
  end

  test "current version tag mode derives the exact tag from mix project version" do
    assert {:ok,
            %{
              ref: "v9.9.9",
              worktree: "/tmp/release-proof",
              synthetic_tag: true
            }} =
             ReleasePreflightProof.parse_args(
               ["--current-version-tag", "--worktree", "/tmp/release-proof"],
               %{project_config: [version: "9.9.9"]}
             )
  end

  test "rejects ambiguous or non-release refs" do
    assert {:error, "ref must be an exact release tag like v0.1.0; got not-a-real-tag"} =
             ReleasePreflightProof.validate_ref("not-a-real-tag")
  end

  test "dry run refuses non-release refs without creating the worktree path" do
    worktree = Path.join(File.cwd!(), "tmp/release-preflight-proof-test")
    File.rm_rf!(worktree)

    {output, status} =
      System.cmd(
        "mix",
        [
          "run",
          "scripts/release_preflight_proof.exs",
          "--dry-run",
          "--ref",
          "not-a-real-tag",
          "--worktree",
          worktree
        ],
        stderr_to_stdout: true
      )

    assert status == 1
    assert output =~ "ref must be an exact release tag like v0.1.0"
    refute File.exists?(worktree)
  end

  test "rejects using the active workspace as the proof worktree" do
    assert {:error, "worktree path must be isolated from the active workspace"} =
             ReleasePreflightProof.validate_worktree(File.cwd!())
  end

  test "synthetic tag proof creates and cleans up isolated release state on success" do
    runner =
      command_runner_for(%{
        {"git", ["rev-parse", "--verify", "refs/tags/v0.1.0^{commit}"]} => {"", 1},
        {"git", ["tag", "-f", "v0.1.0", "HEAD"]} => {"Updated tag\n", 0},
        {"git", ["rev-parse", "--verify", "v0.1.0^{commit}"]} => {"abc123\n", 0},
        {"git", ["worktree", "add", "--detach", "/tmp/release-proof", "v0.1.0"]} => {"", 0},
        {"mix", ["deps.get"]} => {"deps ok\n", 0},
        {"mix", ["release.preflight"]} => {"preflight ok\n", 0},
        {"git", ["worktree", "remove", "--force", "/tmp/release-proof"]} => {"", 0},
        {"git", ["tag", "-d", "v0.1.0"]} => {"Deleted tag\n", 0}
      })

    assert {:ok, output} =
             ReleasePreflightProof.execute_proof(
               %{
                 ref: "v0.1.0",
                 worktree: "/tmp/release-proof",
                 dry_run: false,
                 keep: false,
                 synthetic_tag: true
               },
               %{runner: runner, project_config: [version: "0.1.0"]}
             )

    assert output =~ "deps ok"
    assert output =~ "preflight ok"

    assert_received {:proof_command, "git", ["tag", "-f", "v0.1.0", "HEAD"], _}
    assert_received {:proof_command, "mix", ["deps.get"], opts}
    assert opts[:cd] == "/tmp/release-proof"
    assert opts[:stderr_to_stdout] == true

    assert_received {:proof_command, "mix", ["release.preflight"], opts}
    assert opts[:cd] == "/tmp/release-proof"
    assert opts[:stderr_to_stdout] == true

    assert_received {:proof_command, "git",
                     ["worktree", "remove", "--force", "/tmp/release-proof"], _}

    assert_received {:proof_command, "git", ["tag", "-d", "v0.1.0"], _}
  end

  test "synthetic tag proof restores previous tag target and cleans up after failure" do
    runner =
      command_runner_for(%{
        {"git", ["rev-parse", "--verify", "refs/tags/v0.1.0^{commit}"]} => {"deadbeef\n", 0},
        {"git", ["tag", "-f", "v0.1.0", "HEAD"]} => {"Updated tag\n", 0},
        {"git", ["rev-parse", "--verify", "v0.1.0^{commit}"]} => {"abc123\n", 0},
        {"git", ["worktree", "add", "--detach", "/tmp/release-proof", "v0.1.0"]} => {"", 0},
        {"mix", ["deps.get"]} => {"deps ok\n", 0},
        {"mix", ["release.preflight"]} => {"preflight failed\n", 1},
        {"git", ["worktree", "remove", "--force", "/tmp/release-proof"]} => {"", 0},
        {"git", ["tag", "-f", "v0.1.0", "deadbeef"]} => {"Restored tag\n", 0}
      })

    assert {:error, 1, "deps ok\npreflight failed\n"} =
             ReleasePreflightProof.execute_proof(
               %{
                 ref: "v0.1.0",
                 worktree: "/tmp/release-proof",
                 dry_run: false,
                 keep: false,
                 synthetic_tag: true
               },
               %{runner: runner, project_config: [version: "0.1.0"]}
             )

    assert_received {:proof_command, "git",
                     ["worktree", "remove", "--force", "/tmp/release-proof"], _}

    assert_received {:proof_command, "git", ["tag", "-f", "v0.1.0", "deadbeef"], _}
  end

  defp command_runner_for(responses) do
    test_pid = self()

    fn command, args, opts ->
      send(test_pid, {:proof_command, command, args, opts})
      Map.fetch!(responses, {command, args})
    end
  end
end
