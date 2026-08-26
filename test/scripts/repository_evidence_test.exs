defmodule Rendro.RepositoryEvidenceTest do
  use ExUnit.Case, async: true

  alias Rendro.RepositoryEvidence

  @capsule Path.expand("../../evidence/releases/v1.3.4", __DIR__)

  test "resolves the public prerequisite through the sole capsule entry point" do
    assert {:ok, facts} = RepositoryEvidence.load_public_prerequisite()
    assert facts["version"] == "1.3.4"
    assert facts["tag"] == "v1.3.4"
    assert facts["public_prerequisite"] == "VERIFIED"
  end

  test "fails closed with stable diagnostics for malformed manifest and payload mutations" do
    for {name, mutate} <- mutations() do
      with_temporary_capsule(fn root ->
        mutate.(root)

        assert {:error, diagnostics} = RepositoryEvidence.load_public_prerequisite(root: root),
               "#{name} must fail closed"

        assert diagnostics == Enum.sort(diagnostics), "#{name} diagnostics must be stable"
        assert Enum.all?(diagnostics, &(is_binary(&1) and &1 != ""))
      end)
    end
  end

  test "rejects duplicate record identities, paths, roles, and equal record identity" do
    for duplicate <- [:id, :path, :role, :identity] do
      with_temporary_capsule(fn root ->
        manifest_path = Path.join([root, "evidence", "releases", "v1.3.4", "manifest.json"])
        manifest = manifest_path |> File.read!() |> JSON.decode!()
        [record] = manifest["records"]

        duplicate_record =
          case duplicate do
            :id -> Map.put(record, "id", record["id"])
            :path -> Map.put(record, "path", record["path"])
            :role -> Map.put(record, "role", record["role"])
            :identity -> record
          end

        File.write!(
          manifest_path,
          Jason.encode!(Map.put(manifest, "records", [record, duplicate_record]), pretty: true)
        )

        assert {:error, diagnostics} = RepositoryEvidence.load_public_prerequisite(root: root)
        assert diagnostics == Enum.sort(diagnostics)
        assert Enum.any?(diagnostics, &String.contains?(&1, "duplicate"))
      end)
    end
  end

  defp mutations do
    [
      {"empty manifest", &File.write!(manifest_path(&1), "")},
      {"missing manifest", &File.rm!(manifest_path(&1))},
      {"missing record", &replace_manifest(&1, "records", [])},
      {"empty record", &File.write!(payload_path(&1), "")},
      {"missing record file", &File.rm!(payload_path(&1))},
      {"traversal", &replace_record(&1, "path", "../public_prerequisite.json")},
      {"symlink substitution", &substitute_payload_with_symlink/1},
      {"unsupported media", &replace_record(&1, "media_type", "text/plain")},
      {"unsupported manifest version", &replace_manifest(&1, "schema_version", 2)},
      {"unknown role", &replace_record(&1, "role", "unknown")},
      {"digest mismatch", &replace_record(&1, "sha256", String.duplicate("0", 64))},
      {"release binding mismatch", &replace_payload(&1, "tag", "v9.9.9")}
    ]
  end

  defp with_temporary_capsule(fun) do
    root = Path.join(System.tmp_dir!(), "rendro-evidence-#{System.unique_integer([:positive])}")

    File.mkdir_p!(
      Path.dirname(Path.join([root, "evidence", "releases", "v1.3.4", "manifest.json"]))
    )

    File.cp!(Path.join(@capsule, "manifest.json"), manifest_path(root))
    File.cp!(Path.join(@capsule, "public_prerequisite.json"), payload_path(root))

    try do
      fun.(root)
    after
      File.rm_rf!(root)
    end
  end

  defp replace_manifest(root, key, value) do
    path = manifest_path(root)

    File.write!(
      path,
      Jason.encode!(Map.put(JSON.decode!(File.read!(path)), key, value), pretty: true)
    )
  end

  defp replace_record(root, key, value) do
    path = manifest_path(root)
    manifest = JSON.decode!(File.read!(path))
    [record] = manifest["records"]

    File.write!(
      path,
      Jason.encode!(Map.put(manifest, "records", [Map.put(record, key, value)]), pretty: true)
    )
  end

  defp replace_payload(root, key, value) do
    path = payload_path(root)

    File.write!(
      path,
      Jason.encode!(Map.put(JSON.decode!(File.read!(path)), key, value), pretty: true)
    )
  end

  defp substitute_payload_with_symlink(root) do
    path = payload_path(root)
    File.rm!(path)
    assert :ok = File.ln_s("/dev/null", path)
  end

  defp manifest_path(root),
    do: Path.join([root, "evidence", "releases", "v1.3.4", "manifest.json"])

  defp payload_path(root),
    do: Path.join([root, "evidence", "releases", "v1.3.4", "public_prerequisite.json"])
end
