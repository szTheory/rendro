Code.require_file("scripts/release_preflight_proof.exs", File.cwd!())

defmodule Rendro.ReleasePreflightProofTest do
  use ExUnit.Case, async: false

  alias Rendro.ReleasePreflightProof

  test "requires explicit ref and worktree arguments" do
    assert {:error, "missing required --ref vX.Y.Z"} = ReleasePreflightProof.parse_args([])

    assert {:error, "missing required --worktree PATH"} =
             ReleasePreflightProof.parse_args(["--ref", "v0.1.0"])
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
        ], stderr_to_stdout: true)

    assert status == 1
    assert output =~ "ref must be an exact release tag like v0.1.0"
    refute File.exists?(worktree)
  end

  test "rejects using the active workspace as the proof worktree" do
    assert {:error, "worktree path must be isolated from the active workspace"} =
             ReleasePreflightProof.validate_worktree(File.cwd!())
  end
end
