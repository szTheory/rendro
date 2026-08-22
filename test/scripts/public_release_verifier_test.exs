Code.require_file("scripts/verify_public_release.exs", File.cwd!())

defmodule Rendro.PublicReleaseVerifierTest do
  use ExUnit.Case, async: false

  alias Rendro.PublicReleaseVerifier

  @candidate String.duplicate("a", 40)
  @script Path.expand("../../scripts/verify_public_release.exs", __DIR__)
  @candidate_record ".planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-RELEASE-CANDIDATE.md"

  test "private candidate binds the exact recovery target while retaining the immutable incident" do
    record = File.read!(@candidate_record)

    assert record =~ ~r/^version: 1\.3\.2$/m
    assert record =~ ~r/^release_ref: v1\.3\.2$/m
    assert record =~ ~r/^candidate_commit_sha: [0-9a-f]{40}$/m
    assert record =~ ~r/^package_checksum: [0-9a-f]{64}$/m
    assert record =~ "tag_pushed: false"
    assert record =~ "hexdocs_dispatched: false"
    assert record =~ "registry_mutated: false"
    assert record =~ "3d014b8194782fc29bc685c0d5e84e4adc64b2c3"
    assert record =~ "32513353551"
    assert record =~ "32539594278"
    assert record =~ "b386d1e39b6c9e63af58aa1fa5890d93909d278f"
    assert record =~ "concluded **failure** before Hex"
    assert record =~ "publication. The version extraction"
    assert record =~ "Hex package `1.3.0` is absent"
    assert record =~ "HexDocs `1.3.0` was not dispatched and is absent"
  end

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

  test "refuses candidate verification unless both immutable failed incidents remain exact" do
    assert {:error, "v1.3.0 incident peeled SHA is incorrect"} =
             PublicReleaseVerifier.validate(valid_facts(%{"v1_3_0_peeled_sha" => "different"}))

    assert {:error, "v1.3.1 incident publish job was not skipped"} =
             PublicReleaseVerifier.validate(valid_facts(%{"v1_3_1_publish_job_skipped" => false}))
  end

  test "real CLI invocation writes a bounded parseable VERIFIED record from test fixture facts" do
    {record, fixture, output} = fixture_paths()
    on_exit(fn -> Enum.each([record, fixture, output], &File.rm/1) end)
    File.write!(record, "candidate_commit_sha: #{@candidate}\n")
    File.write!(fixture, JSON.encode!(valid_facts() |> Map.merge(fixture_metadata())))

    assert {_, 0} = run_cli(record, output, fixture)

    assert %{"public_prerequisite" => "VERIFIED", "candidate_commit_sha" => @candidate} =
             output |> File.read!() |> JSON.decode!()

    assert byte_size(File.read!(output)) < 5_000
  end

  test "CLI rejects missing, duplicate, and invalid arguments without writing output" do
    {record, fixture, output} = fixture_paths()
    on_exit(fn -> Enum.each([record, fixture, output], &File.rm/1) end)
    File.write!(record, "candidate_commit_sha: #{@candidate}\n")
    File.write!(fixture, JSON.encode!(valid_facts() |> Map.merge(fixture_metadata())))

    assert {_, status} = run_cli(record, output, fixture, ["--tag", "v1.3.2"])
    assert status != 0
    refute File.exists?(output)

    assert {_, status} = run_cli(record, output, fixture, ["--release-run-id", "12"])
    assert status != 0
    refute File.exists?(output)

    assert {_, status} = run_cli(record, output, fixture, ["--hexdocs-run-id", "not-a-number"])
    assert status != 0
    refute File.exists?(output)
  end

  test "a failing public fact produces no VERIFIED output" do
    {record, fixture, output} = fixture_paths()
    on_exit(fn -> Enum.each([record, fixture, output], &File.rm/1) end)
    File.write!(record, "candidate_commit_sha: #{@candidate}\n")

    File.write!(
      fixture,
      JSON.encode!(
        valid_facts(%{"hexdocs_source_sha" => String.duplicate("b", 40)})
        |> Map.merge(fixture_metadata())
      )
    )

    assert {_, status} = run_cli(record, output, fixture)
    assert status != 0
    refute File.exists?(output)
  end

  test "the exact planned production command cannot exit zero with an empty record" do
    {record, _fixture, output} = fixture_paths()
    on_exit(fn -> Enum.each([record, output], &File.rm/1) end)
    File.write!(record, "candidate_commit_sha: #{@candidate}\n")

    {_, status} = run_cli(record, output, nil)

    assert status != 0 or (File.exists?(output) and File.stat!(output).size > 0)
    refute File.exists?(output) and File.stat!(output).size == 0
  end

  defp run_cli(record, output, fixture, extra_args \\ []) do
    args =
      [
        "run",
        @script,
        "--",
        "--candidate-record",
        record,
        "--tag",
        "v1.3.2",
        "--release-run-id",
        "12",
        "--hexdocs-run-id",
        "34",
        "--output",
        output,
        "--check-existing"
      ] ++ extra_args

    environment =
      [{"MIX_ENV", "test"}] ++
        if fixture, do: [{"RENDRO_PUBLIC_RELEASE_FIXTURE", fixture}], else: []

    System.cmd("mix", args, cd: File.cwd!(), env: environment, stderr_to_stdout: true)
  end

  defp fixture_paths do
    root =
      Path.join(System.tmp_dir!(), "rendro-public-release-#{System.unique_integer([:positive])}")

    {root <> ".candidate", root <> ".fixture.json", root <> ".json"}
  end

  defp fixture_metadata do
    %{"tag" => "v1.3.2", "release_run_id" => "12", "hexdocs_run_id" => "34"}
  end

  defp valid_facts(overrides \\ %{}) do
    Map.merge(
      %{
        "candidate_commit_sha" => @candidate,
        "peeled_tag_sha" => @candidate,
        "release_head_sha" => @candidate,
        "release_conclusion" => "success",
        "release_event" => "push",
        "release_name" => "Release to Hex",
        "hexdocs_head_sha" => @candidate,
        "hexdocs_conclusion" => "success",
        "hexdocs_event" => "workflow_dispatch",
        "hexdocs_name" => "HexDocs",
        "version" => "1.3.2",
        "hex_version" => "1.3.2",
        "hexdocs_version" => "1.3.2",
        "hexdocs_source_sha" => @candidate,
        "archive_members" => [
          "mix.exs",
          "README.md",
          "guides/presets.md",
          "assets/rendro/configurator/index.html"
        ],
        "hexdocs_symbols" => [
          "Rendro.Theme",
          "Rendro.Theme.Presets",
          "Rendro.Adapters.Phoenix.render_pdf/3"
        ],
        "v1_3_0_peeled_sha" => "3d014b8194782fc29bc685c0d5e84e4adc64b2c3",
        "v1_3_0_run_id" => "32513353551",
        "v1_3_0_conclusion" => "failure",
        "v1_3_0_hex_absent" => true,
        "v1_3_0_hexdocs_absent" => true,
        "v1_3_1_tag_object_sha" => "b386d1e39b6c9e63af58aa1fa5890d93909d278f",
        "v1_3_1_peeled_sha" => "7afb1dd056bba234d1bd4ec1c4487f2ea8e308f1",
        "v1_3_1_run_id" => "32539594278",
        "v1_3_1_conclusion" => "cancelled",
        "v1_3_1_publish_job_skipped" => true,
        "v1_3_1_hex_absent" => true,
        "v1_3_1_hexdocs_absent" => true
      },
      overrides
    )
  end
end
