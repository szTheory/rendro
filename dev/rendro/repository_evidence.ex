defmodule Rendro.RepositoryEvidence do
  @moduledoc false

  @capsule ["evidence", "releases", "v1.3.4"]
  @manifest_schema "priv/schemas/release_evidence_manifest.schema.json"
  @role_schemas %{
    "public_prerequisite" => "priv/schemas/release_evidence_prerequisite.schema.json",
    "release_identity" => "priv/schemas/release_evidence_identity.schema.json",
    "validation" => "priv/schemas/release_evidence_validation.schema.json",
    "journey_index" => "priv/schemas/release_evidence_journey_index.schema.json"
  }
  @core_roles Map.keys(@role_schemas)

  @spec load_public_prerequisite(keyword()) :: {:ok, map()} | {:error, [String.t()]}
  def load_public_prerequisite(options \\ []) do
    with {:ok, payload} <- load_role(:public_prerequisite, options) do
      {:ok, payload["facts"]}
    end
  end

  @spec load_role(
          :public_prerequisite | :release_identity | :validation | :journey_index,
          keyword()
        ) ::
          {:ok, map()} | {:error, [String.t()]}
  def load_role(role, options \\ [])

  def load_role(role, options)
      when role in [:public_prerequisite, :release_identity, :validation, :journey_index] do
    root = options |> Keyword.get(:root, File.cwd!()) |> Path.expand()
    capsule_root = Path.join([root | @capsule])
    requested_role = Atom.to_string(role)

    with {:ok, manifest} <- load_json(Path.join(capsule_root, "manifest.json"), "manifest"),
         :ok <- validate_schema(manifest, @manifest_schema, "manifest"),
         :ok <- validate_record_uniqueness(manifest["records"]),
         :ok <- validate_core_roles(manifest["records"]),
         {:ok, record} <- fetch_role(manifest["records"], requested_role),
         :ok <- validate_record_media_type(record),
         {:ok, payload_path} <- confined_regular_path(capsule_root, record["path"]),
         :ok <- verify_digest(payload_path, record["sha256"]),
         {:ok, payload} <- load_json(payload_path, requested_role),
         :ok <-
           validate_schema(payload, Map.fetch!(@role_schemas, requested_role), requested_role),
         :ok <- validate_role_and_binding(manifest["release"], record, payload) do
      {:ok, payload}
    else
      {:error, diagnostics} when is_list(diagnostics) -> {:error, Enum.sort(diagnostics)}
      {:error, diagnostic} -> {:error, [diagnostic]}
    end
  end

  def load_role(_, _), do: {:error, ["unknown repository evidence role"]}

  defp load_json(path, label) do
    with {:ok, stat} <- File.lstat(path),
         :regular <- stat.type,
         {:ok, contents} <- File.read(path) do
      {:ok, JSON.decode!(contents)}
    else
      {:error, _} -> {:error, "#{label} is missing or unreadable"}
      type when type != :regular -> {:error, "#{label} must be a regular non-symlink file"}
      _ -> {:error, "#{label} contains invalid JSON"}
    end
  rescue
    _ -> {:error, "#{label} contains invalid JSON"}
  end

  defp validate_schema(value, schema_path, label) do
    schema = schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()

    case JSV.validate(value, schema) do
      {:ok, _} ->
        :ok

      {:error, error} ->
        {:error,
         "#{label} schema validation failed: #{error |> JSV.normalize_error() |> inspect(limit: :infinity)}"}
    end
  end

  defp validate_record_uniqueness(records) do
    singleton_roles =
      records
      |> Enum.reject(&(&1["role"] == "journey_attempt"))
      |> Enum.map(& &1["role"])

    diagnostics =
      for {values, label} <- [
            {Enum.map(records, & &1["id"]), "ID"},
            {Enum.map(records, & &1["path"]), "path"},
            {singleton_roles, "role"}
          ],
          length(values) != length(Enum.uniq(values)),
          do: "manifest has duplicate record #{label}"

    if diagnostics == [], do: :ok, else: {:error, diagnostics}
  end

  defp validate_core_roles(records) do
    present = MapSet.new(records, & &1["role"])
    missing = Enum.reject(@core_roles, &MapSet.member?(present, &1))
    if missing == [], do: :ok, else: {:error, Enum.map(missing, &"manifest has no #{&1} record")}
  end

  defp fetch_role(records, role) do
    case Enum.filter(records, &(&1["role"] == role)) do
      [record] -> {:ok, record}
      [] -> {:error, "manifest has no #{role} record"}
      _ -> {:error, "manifest has duplicate record role"}
    end
  end

  defp validate_record_media_type(%{"media_type" => "application/json"}), do: :ok
  defp validate_record_media_type(_), do: {:error, "manifest record media type is unsupported"}

  defp confined_regular_path(root, relative_path) when is_binary(relative_path) do
    expanded = Path.expand(relative_path, root)

    cond do
      Path.type(relative_path) == :absolute or Path.safe_relative(relative_path) == :error ->
        {:error, "manifest record path escapes capsule root"}

      not String.starts_with?(expanded, root <> "/") ->
        {:error, "manifest record path escapes capsule root"}

      true ->
        case File.lstat(expanded) do
          {:ok, %{type: :regular}} -> {:ok, expanded}
          _ -> {:error, "manifest record must reference a regular non-symlink file"}
        end
    end
  end

  defp confined_regular_path(_, _), do: {:error, "manifest record path is invalid"}

  defp verify_digest(path, expected) do
    actual = :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)
    if actual == expected, do: :ok, else: {:error, "manifest record digest mismatch"}
  end

  defp validate_role_and_binding(release, record, payload) do
    facts = payload["facts"] || %{}
    candidate = payload["candidate_commit_sha"] || facts["candidate_commit_sha"]

    if payload["role"] == record["role"] and payload["release"] == release and
         candidate == release["candidate_commit_sha"] do
      :ok
    else
      {:error, "#{record["role"]} role or release/candidate/tag binding mismatch"}
    end
  end
end
