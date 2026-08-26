defmodule Rendro.RepositoryEvidenceTest do
  use ExUnit.Case, async: true

  alias Rendro.RepositoryEvidence

  @capsule Path.expand("../../evidence/releases/v1.3.4", __DIR__)
  @roles [:public_prerequisite, :release_identity, :validation, :journey_index]
  @attempt_schema "priv/schemas/release_evidence_attempt.schema.json"

  test "preserves all nine journey attempts as ordered, digest-bound records" do
    assert {:ok, index} = RepositoryEvidence.load_role(:journey_index)

    assert index["entries"] == [
             "RE-V134-JOURNEY-001",
             "RE-V134-JOURNEY-002",
             "RE-V134-JOURNEY-003",
             "RE-V134-JOURNEY-004",
             "RE-V134-JOURNEY-005",
             "RE-V134-JOURNEY-006",
             "RE-V134-JOURNEY-007",
             "RE-V134-JOURNEY-008",
             "RE-V134-JOURNEY-009"
           ]

    manifest = @capsule |> Path.join("manifest.json") |> File.read!() |> JSON.decode!()
    attempts = Enum.filter(manifest["records"], &(&1["role"] == "journey_attempt"))
    assert Enum.map(attempts, & &1["id"]) == index["entries"]
    assert length(Enum.uniq(index["entries"])) == 9

    schema = @attempt_schema |> File.read!() |> JSON.decode!() |> JSV.build!()

    for {id, number} <- Enum.with_index(index["entries"], 1) do
      stem = "journey-" <> String.pad_leading(Integer.to_string(number), 3, "0")
      json_path = Path.join([@capsule, "journey", stem <> ".json"])
      sidecar_path = Path.join([@capsule, "journey", stem <> ".md"])
      record = Enum.find(attempts, &(&1["id"] == id))

      assert File.regular?(json_path)
      assert record["path"] == Path.join("journey", stem <> ".json")
      assert record["sha256"] == sha256(json_path)

      attempt = json_path |> File.read!() |> JSON.decode!()
      assert {:ok, _} = JSV.validate(attempt, schema)
      assert attempt["id"] == id
      assert attempt["source"]["sha256"] == sha256(attempt["source"]["path"])
      assert attempt["facts"] == source_facts(attempt)
      assert attempt["redaction"]["classification"] == "none"
      assert attempt["supersedes"] == []

      case number do
        7 ->
          assert attempt["narrative"] == %{
                   "role" => "absent",
                   "reason" => "The pre-schema source has no Markdown sidecar."
                 }

          refute File.exists?(sidecar_path)
          refute File.exists?(source_sidecar_path(attempt))

        _ ->
          assert File.regular?(sidecar_path)
          assert attempt["narrative"]["role"] == "explanatory_sidecar"
          assert attempt["narrative"]["path"] == Path.join("journey", stem <> ".md")
          assert attempt["narrative"]["sha256"] == sha256(sidecar_path)
          assert File.read!(sidecar_path) == File.read!(source_sidecar_path(attempt))
      end
    end

    journey_records =
      Enum.map(index["entries"], fn id ->
        record = Enum.find(attempts, &(&1["id"] == id))
        @capsule |> Path.join(record["path"]) |> File.read!() |> JSON.decode!()
      end)

    sidecar_attempts =
      Enum.filter(journey_records, &(&1["narrative"]["role"] == "explanatory_sidecar"))

    assert length(sidecar_attempts) == 8
    assert length(journey_records) - length(sidecar_attempts) == 1
  end

  test "loads each sealed core role only through the manifest dispatch" do
    for role <- @roles do
      assert {:ok, payload} = RepositoryEvidence.load_role(role)
      assert payload["role"] == Atom.to_string(role)

      assert payload["release"] == %{
               "version" => "1.3.4",
               "tag" => "v1.3.4",
               "candidate_commit_sha" => "f03c78bab54efe1cd1596d51cf3f28193232e2a3"
             }
    end
  end

  test "retains public prerequisite facts through its compatibility wrapper" do
    assert {:ok, facts} = RepositoryEvidence.load_public_prerequisite()
    assert facts["version"] == "1.3.4"
    assert facts["tag"] == "v1.3.4"
    assert facts["public_prerequisite"] == "VERIFIED"
  end

  test "rejects unknown requested roles without returning facts" do
    assert {:error, diagnostics} = RepositoryEvidence.load_role(:unknown)
    assert diagnostics == Enum.sort(diagnostics)
    assert Enum.any?(diagnostics, &String.contains?(&1, "unknown"))
  end

  test "fails closed when a requested role, role schema, binding, digest, path, or core role is invalid" do
    for {name, mutate} <- mutations() do
      with_temporary_capsule(fn root ->
        mutate.(root)

        assert {:error, diagnostics} = RepositoryEvidence.load_role(:release_identity, root: root),
               "#{name} must fail closed"

        assert diagnostics == Enum.sort(diagnostics), "#{name} diagnostics must be stable"
        assert Enum.all?(diagnostics, &(is_binary(&1) and &1 != ""))
      end)
    end
  end

  test "rejects missing and duplicate core roles" do
    for mutation <- [:missing, :duplicate] do
      with_temporary_capsule(fn root ->
        manifest = read_manifest(root)

        records =
          case mutation do
            :missing ->
              Enum.reject(manifest["records"], &(&1["role"] == "validation"))

            :duplicate ->
              manifest["records"] ++
                [Enum.find(manifest["records"], &(&1["role"] == "validation"))]
          end

        write_manifest(root, Map.put(manifest, "records", records))

        assert {:error, diagnostics} = RepositoryEvidence.load_role(:validation, root: root)

        assert Enum.any?(
                 diagnostics,
                 &(String.contains?(&1, "#{mutation}") or String.contains?(&1, "duplicate") or
                     String.contains?(&1, "no validation"))
               )
      end)
    end
  end

  defp mutations do
    [
      {"requested role versus manifest role mismatch",
       fn root -> replace_record(root, "role", "validation") end},
      {"wrong role schema",
       fn root ->
         replace_payload(root, "release_identity.json", "role", "validation")
         sync_record_digest(root, "release_identity")
       end},
      {"release/candidate/tag binding mismatch",
       fn root ->
         replace_payload(
           root,
           "release_identity.json",
           "candidate_commit_sha",
           String.duplicate("0", 40)
         )

         sync_record_digest(root, "release_identity")
       end},
      {"digest mismatch",
       fn root -> replace_record(root, "sha256", String.duplicate("0", 64)) end},
      {"traversal path", fn root -> replace_record(root, "path", "../release_identity.json") end},
      {"absolute path",
       fn root -> replace_record(root, "path", "/tmp/release_identity.json") end},
      {"missing path", fn root -> replace_record(root, "path", "missing.json") end}
    ]
  end

  defp with_temporary_capsule(fun) do
    root = Path.join(System.tmp_dir!(), "rendro-evidence-#{System.unique_integer([:positive])}")
    destination = Path.join([root, "evidence", "releases", "v1.3.4"])
    File.mkdir_p!(Path.join(destination, "journey"))

    for path <- [
          "manifest.json",
          "public_prerequisite.json",
          "release_identity.json",
          "validation.json",
          "journey/index.json"
        ] do
      target = Path.join(destination, path)
      File.mkdir_p!(Path.dirname(target))
      File.cp!(Path.join(@capsule, path), target)
    end

    try do
      fun.(root)
    after
      File.rm_rf!(root)
    end
  end

  defp read_manifest(root), do: root |> manifest_path() |> File.read!() |> JSON.decode!()

  defp write_manifest(root, manifest),
    do: File.write!(manifest_path(root), Jason.encode!(manifest, pretty: true))

  defp replace_record(root, key, value) do
    manifest = read_manifest(root)

    records =
      Enum.map(manifest["records"], fn
        %{"role" => "release_identity"} = record -> Map.put(record, key, value)
        record -> record
      end)

    write_manifest(root, Map.put(manifest, "records", records))
  end

  defp replace_payload(root, relative_path, key, value) do
    path = Path.join([root, "evidence", "releases", "v1.3.4", relative_path])

    File.write!(
      path,
      Jason.encode!(Map.put(JSON.decode!(File.read!(path)), key, value), pretty: true)
    )
  end

  defp sync_record_digest(root, role) do
    manifest = read_manifest(root)

    records =
      Enum.map(manifest["records"], fn
        %{"role" => ^role, "path" => path} = record ->
          payload_path = Path.join([root, "evidence", "releases", "v1.3.4", path])

          Map.put(
            record,
            "sha256",
            :crypto.hash(:sha256, File.read!(payload_path)) |> Base.encode16(case: :lower)
          )

        record ->
          record
      end)

    write_manifest(root, Map.put(manifest, "records", records))
  end

  defp manifest_path(root),
    do: Path.join([root, "evidence", "releases", "v1.3.4", "manifest.json"])

  defp source_facts(attempt) do
    attempt["source"]["path"]
    |> File.read!()
    |> JSON.decode!()
  end

  defp source_sidecar_path(attempt) do
    attempt["source"]["path"]
    |> String.replace_suffix(".json", ".md")
  end


  defp sha256(path),
    do: :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)
end
