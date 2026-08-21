Code.require_file("scripts/verify_public_release.exs", File.cwd!())

defmodule Rendro.PublicReleaseVerifierTest do
  use ExUnit.Case, async: true

  alias Rendro.PublicReleaseVerifier

  test "refuses a tag object when its peeled commit differs from the candidate" do
    facts = valid_facts(%{"peeled_tag_sha" => "different"})

    assert {:error, "peeled tag does not match candidate"} =
             PublicReleaseVerifier.validate(facts)
  end

  test "refuses stale workflow, archive, and HexDocs facts" do
    assert {:error, "release workflow did not conclude successfully"} =
             PublicReleaseVerifier.validate(valid_facts(%{"release_conclusion" => "failure"}))

    assert {:error, "package archive is missing required member README.md"} =
             PublicReleaseVerifier.validate(valid_facts(%{"archive_members" => ["mix.exs"]}))

    assert {:error, "HexDocs version does not match candidate version"} =
             PublicReleaseVerifier.validate(valid_facts(%{"hexdocs_version" => "1.2.0"}))
  end

  test "writes a bounded VERIFIED record only after every fact agrees" do
    path = Path.join(System.tmp_dir!(), "rendro-public-release-#{System.unique_integer([:positive])}.json")
    on_exit(fn -> File.rm(path) end)

    assert :ok = PublicReleaseVerifier.write_verified(path, valid_facts())
    assert %{"public_prerequisite" => "VERIFIED", "candidate_commit_sha" => @candidate} =
             path |> File.read!() |> JSON.decode!()
  end

  @candidate String.duplicate("a", 40)

  defp valid_facts(overrides \\ %{}) do
    Map.merge(
      %{
        "candidate_commit_sha" => @candidate,
        "peeled_tag_sha" => @candidate,
        "release_head_sha" => @candidate,
        "release_conclusion" => "success",
        "release_event" => "push",
        "hexdocs_head_sha" => @candidate,
        "hexdocs_conclusion" => "success",
        "hexdocs_event" => "workflow_dispatch",
        "version" => "1.3.0",
        "hex_version" => "1.3.0",
        "hexdocs_version" => "1.3.0",
        "hexdocs_source_sha" => @candidate,
        "archive_members" => ["mix.exs", "README.md", "guides/presets.md", "assets/rendro/configurator/index.html"],
        "hexdocs_symbols" => ["Rendro.Theme", "Rendro.Theme.Presets", "Rendro.Adapters.Phoenix.render_pdf/3"]
      },
      overrides
    )
  end
end
