Code.require_file("scripts/verify_public_release.exs", File.cwd!())

defmodule Rendro.PublicReleaseVerifierTest do
  use ExUnit.Case, async: false

  alias Rendro.PublicReleaseVerifier

  @candidate String.duplicate("a", 40)
  @script Path.expand("../../scripts/verify_public_release.exs", __DIR__)
  @candidate_record ".planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-RELEASE-CANDIDATE.md"

  test "sealed v1.3.4 record retains all four immutable incidents" do
    record = File.read!(@candidate_record)

    assert record =~ ~r/^version: 1\.3\.4$/m
    assert record =~ ~r/^release_ref: v1\.3\.4$/m
    assert record =~ "candidate_status: proof_complete_control_pending"
    assert record =~ "required_fix_ancestor: bbe75d2bf3f53e5235626974c539500395d2032e"
    assert record =~ "tag_pushed: false"
    assert record =~ "hexdocs_dispatched: false"
    assert record =~ "registry_mutated: false"
    assert record =~ "3d014b8194782fc29bc685c0d5e84e4adc64b2c3"
    assert record =~ "32513353551"
    assert record =~ "32539594278"
    assert record =~ "b386d1e39b6c9e63af58aa1fa5890d93909d278f"
    assert record =~ "9b7ff50c69c0e9bd6ae39f0c79f76c4663d936fd"
    assert record =~ "47af6448d2989ffe69c4b80c77935c896b1ddb07"
    assert record =~ "32586098785"
    assert record =~ "97062582546"
    assert record =~ "97064173653"
    assert record =~ "c96bf205d7216cdcf4846a0f24a312f9c1c75b0f"
    assert record =~ "cfc58a81865e060351ce33d98f5e52de8cd198d9"
    assert record =~ "32596108284"
    assert record =~ "97087204354"
    assert record =~ "97088652899"
    assert record =~ "recovery_target: 1.3.4"
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

  test "refuses candidate verification unless all immutable failed incidents remain exact" do
    assert {:error, "v1.3.0 incident peeled SHA is incorrect"} =
             PublicReleaseVerifier.validate(valid_facts(%{"v1_3_0_peeled_sha" => "different"}))

    assert {:error, "v1.3.1 incident publish job was not skipped"} =
             PublicReleaseVerifier.validate(valid_facts(%{"v1_3_1_publish_job_skipped" => false}))

    assert {:error, "v1.3.2 incident validate job was not a failure"} =
             PublicReleaseVerifier.validate(
               valid_facts(%{"v1_3_2_validate_job_conclusion" => "success"})
             )

    assert {:error, "v1.3.3 incident HexDocs dispatch was not absent"} =
             PublicReleaseVerifier.validate(
               valid_facts(%{"v1_3_3_hexdocs_dispatch_absent" => false})
             )
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

    assert {_, status} = run_cli(record, output, fixture, ["--tag", "v1.3.3"])
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
        "v1.3.4",
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
    %{"tag" => "v1.3.4", "release_run_id" => "12", "hexdocs_run_id" => "34"}
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
        "version" => "1.3.4",
        "hex_version" => "1.3.4",
        "hexdocs_version" => "1.3.4",
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
        "v1_3_1_hexdocs_absent" => true,
        "v1_3_2_tag_object_sha" => "9b7ff50c69c0e9bd6ae39f0c79f76c4663d936fd",
        "v1_3_2_peeled_sha" => "47af6448d2989ffe69c4b80c77935c896b1ddb07",
        "v1_3_2_run_id" => "32586098785",
        "v1_3_2_conclusion" => "failure",
        "v1_3_2_validate_job_id" => "97062582546",
        "v1_3_2_validate_job_conclusion" => "failure",
        "v1_3_2_publish_job_id" => "97064173653",
        "v1_3_2_publish_job_conclusion" => "skipped",
        "v1_3_2_hex_absent" => true,
        "v1_3_2_hexdocs_absent" => true,
        "v1_3_3_tag_object_sha" => "c96bf205d7216cdcf4846a0f24a312f9c1c75b0f",
        "v1_3_3_peeled_sha" => "cfc58a81865e060351ce33d98f5e52de8cd198d9",
        "v1_3_3_run_id" => "32596108284",
        "v1_3_3_conclusion" => "failure",
        "v1_3_3_validate_job_id" => "97087204354",
        "v1_3_3_validate_job_conclusion" => "failure",
        "v1_3_3_publish_job_id" => "97088652899",
        "v1_3_3_publish_job_conclusion" => "skipped",
        "v1_3_3_hex_absent" => true,
        "v1_3_3_hexdocs_absent" => true,
        "v1_3_3_hexdocs_dispatch_absent" => true,
        "v1_3_3_verifier_absent" => true
      },
      overrides
    )
  end
end
