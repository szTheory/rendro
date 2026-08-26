defmodule Rendro.RepositoryEvidenceTest do
  use ExUnit.Case, async: true

  alias Rendro.RepositoryEvidence

  @capsule Path.expand("../../evidence/releases/v1.3.4", __DIR__)
  @roles [:public_prerequisite, :release_identity, :validation, :journey_index]

  test "preserves the first four journey attempts as ordered paired records" do
    assert {:ok, index} = RepositoryEvidence.load_role(:journey_index)

    assert index["entries"] == [
             "RE-V134-JOURNEY-001",
             "RE-V134-JOURNEY-002",
             "RE-V134-JOURNEY-003",
             "RE-V134-JOURNEY-004"
           ]

    for number <- 1..4 do
      stem = "journey-" <> String.pad_leading(Integer.to_string(number), 3, "0")
      assert File.regular?(Path.join([@capsule, "journey", stem <> ".json"]))
      assert File.regular?(Path.join([@capsule, "journey", stem <> ".md"]))
    end
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
end
