defmodule Rendro.RepositoryEvidenceTest do
  use ExUnit.Case, async: true

  alias Rendro.RepositoryEvidence

  @capsule Path.expand("../../evidence/releases/v1.3.4", __DIR__)
  @roles [:public_prerequisite, :release_identity, :validation, :journey_index]
  @attempt_schema "priv/schemas/release_evidence_attempt.schema.json"
  @preserved_attempts [
    {"RE-V134-JOURNEY-001", "priv/journey_evidence/phoenix_clean_room_1.3.4_failed_attempt.json",
     "8cb4a6a1d00e7b1160531ac3a01b8bbf989e16d9d84e1601a5d69134dfe57436",
     "a00010bb91484cb102e721c847efaaf8bc0a4724",
     "a212a93b96d31c6facf1f7527813f32c7e229fead58cb09a47d7031e0b335047",
     "c42d9969dc6aaecefb60a753438230130ff63110398390f63efcbf682c3cc13f"},
    {"RE-V134-JOURNEY-002",
     "priv/journey_evidence/phoenix_clean_room_1.3.4_second_failed_attempt.json",
     "e36e6671dfe69a3c783bc4ce069708b650e089e8d27f1fc5f4d0b4666f2a5b51",
     "ed69d9c905a4d495444bdd6215513b51c4265b6d",
     "dbeed509ba6879f4fcf57d980a74307be202cfcd386a757410c6c5795f392cd5",
     "1d008406a451b23ff99462dcc5da2888dee49954c8dc1927b322d4198efe6a6c"},
    {"RE-V134-JOURNEY-003",
     "priv/journey_evidence/phoenix_clean_room_1.3.4_third_failed_attempt.json",
     "e299610dd0d66d660f8148d6bdd0fbf92df5ebb60bdc55fae2764d523c638658",
     "01b64464b0b5fea14527b29957fb03d36a6a3a7b",
     "a3dc63e6bf842818b7db32c1eaff071ed2a51fa5e0d392574369554349041a4a",
     "f53c270e07c9402409ea486888b0cf0bb9cfd49612b6b98670cfd8ac48120f26"},
    {"RE-V134-JOURNEY-004",
     "priv/journey_evidence/phoenix_clean_room_1.3.4_fourth_failed_attempt.json",
     "efc0d3303a946b20dfe60832b368a2b643cfad80b768a5517b261c54a0c1bba1",
     "caf9e256fcf99c2fbb8770a1107a575390ec83eb",
     "2b72678ba7fc193723c7c9d47df579232f71b92bb89c145112a976af099accd4",
     "4b46c1e8660cba574ed55f191bc2810632499d34386399ea2700adde2b9969b6"},
    {"RE-V134-JOURNEY-005",
     "priv/journey_evidence/phoenix_clean_room_1.3.4_fifth_failed_attempt.json",
     "d6f7c0935eb04c9dedbd26813c72832b2c5a3a85768c4e0a19d185b511d3374b",
     "81ba9aad5cfab61b8cfe111b0092c9f7221853b7",
     "a59eddd557150e818a4d5b79ed2cf3ae77076571ca64d9fbf13756511d097728",
     "2f80cabc688c9393ba3c4eec1d91fa8da29ad8964d858f9ec2183fe170d46427"},
    {"RE-V134-JOURNEY-006",
     "priv/journey_evidence/phoenix_clean_room_1.3.4_sixth_failed_attempt.json",
     "80a69cb16d783a59f0ca6be4d04d7db4812b562bc91a36309f358f2585a0abda",
     "204f2318b4f3d07109718a2b28fcbe5ebbe01ae8",
     "3bee4a8d69d8bbf68c7ca668c9a51d7086d1cda5de28be4631851734db7da38f",
     "5b4b639156a7ed6351431663a2103be2bf024cda1bc072ca86ab11111d71afed"},
    {"RE-V134-JOURNEY-007",
     "priv/journey_evidence/phoenix_clean_room_1.3.4_pre_schema_success.json",
     "a4f0e53e9c4d9a9afa14f8b3959e739522cbf5c644e81107f59d46bbf0b66f1d",
     "0006fd9707898e306c10b485315062131921aa8d",
     "a4f0e53e9c4d9a9afa14f8b3959e739522cbf5c644e81107f59d46bbf0b66f1d", nil},
    {"RE-V134-JOURNEY-008",
     "priv/journey_evidence/phoenix_clean_room_1.3.4_seventh_failed_attempt.json",
     "d03753cf77dd4f2a642053a7ebd486ba2c95c253275f1f05bcc34ea63ff13350",
     "0006fd9707898e306c10b485315062131921aa8d",
     "5eba4a91bf0b370d89c219509f17231035ac5ab4f2d85e993cd5b86d2904d852",
     "2016ed177e279bc98aa94ff39c736ac382a29b14812e2b6d5800b16e2048feab"},
    {"RE-V134-JOURNEY-009", "priv/journey_evidence/phoenix_clean_room_1.3.4.json",
     "a59706f89b4c4226c184509457856d1bd75474a495efaf6427e396307d3a2bfd",
     "1b34dece3d26cd50b6e3e5362a8b9d591c97c63d",
     "a59706f89b4c4226c184509457856d1bd75474a495efaf6427e396307d3a2bfd",
     "971539bdeec59b73ab354494fd77f5ea16e5b469bfaa89d3374a17fc720da9c7"}
  ]

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

    for {{id, source_path, source_sha256, source_commit, facts_sha256, sidecar_sha256}, number} <-
          Enum.zip(@preserved_attempts, 1..9) do
      stem = "journey-" <> String.pad_leading(Integer.to_string(number), 3, "0")
      json_path = Path.join([@capsule, "journey", stem <> ".json"])
      sidecar_path = Path.join([@capsule, "journey", stem <> ".md"])
      record = Enum.find(attempts, &(&1["id"] == id))

      assert File.regular?(json_path)
      assert id in index["entries"]
      assert record["path"] == Path.join("journey", stem <> ".json")
      assert record["sha256"] == sha256(json_path)

      attempt = json_path |> File.read!() |> JSON.decode!()
      assert {:ok, _} = JSV.validate(attempt, schema)
      assert attempt["id"] == id

      assert attempt["source"] == %{
               "path" => source_path,
               "sha256" => source_sha256,
               "commit" => source_commit
             }

      assert sha256_json(attempt["facts"]) == facts_sha256
      assert attempt["redaction"]["classification"] == "none"
      assert attempt["supersedes"] == []

      case number do
        7 ->
          assert attempt["narrative"] == %{
                   "role" => "absent",
                   "reason" => "The pre-schema source has no Markdown sidecar."
                 }

          refute File.exists?(sidecar_path)

        _ ->
          assert File.regular?(sidecar_path)
          assert attempt["narrative"]["role"] == "explanatory_sidecar"
          assert attempt["narrative"]["path"] == Path.join("journey", stem <> ".md")
          assert attempt["narrative"]["sha256"] == sidecar_sha256
          assert sha256(sidecar_path) == sidecar_sha256
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

  test "fails closed when journey index records, payloads, or sidecars no longer match" do
    for {name, mutate} <- [
          {"duplicate index entry",
           fn root ->
             replace_payload(root, "journey/index.json", "entries", ["RE-V134-JOURNEY-001"])
             sync_record_digest(root, "journey_index")
           end},
          {"journey payload ID",
           fn root ->
             replace_payload(root, "journey/journey-001.json", "id", "RE-V134-JOURNEY-999")
             sync_record_digest(root, "journey_attempt")
           end},
          {"journey sidecar digest",
           fn root ->
             File.write!(journey_path(root, "journey-001.md"), "altered explanatory evidence")
           end}
        ] do
      with_temporary_capsule(fn root ->
        mutate.(root)

        assert {:error, diagnostics} = RepositoryEvidence.load_role(:journey_index, root: root),
               "#{name} must fail closed"

        assert diagnostics == Enum.sort(diagnostics)
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

    for path <-
          [
            "manifest.json",
            "public_prerequisite.json",
            "release_identity.json",
            "validation.json"
          ] ++ journey_files() do
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

  defp journey_files do
    @capsule
    |> Path.join("journey/*")
    |> Path.wildcard()
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(&Path.relative_to(&1, @capsule))
  end

  defp journey_path(root, name),
    do: Path.join([root, "evidence", "releases", "v1.3.4", "journey", name])

  defp sha256_json(value), do: value |> Jason.encode!() |> sha256_contents()

  defp sha256(path),
    do: path |> File.read!() |> sha256_contents()

  defp sha256_contents(contents),
    do: :crypto.hash(:sha256, contents) |> Base.encode16(case: :lower)
end
