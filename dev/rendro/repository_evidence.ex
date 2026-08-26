defmodule Rendro.RepositoryEvidence do
  @moduledoc false

  @capsule ["evidence", "releases", "v1.3.4"]
  @manifest_schema "priv/schemas/release_evidence_manifest.schema.json"
  @prerequisite_schema "priv/schemas/release_evidence_prerequisite.schema.json"

  @spec load_public_prerequisite(keyword()) :: {:ok, map()} | {:error, [String.t()]}
  def load_public_prerequisite(options \\ []) do
    root = options |> Keyword.get(:root, File.cwd!()) |> Path.expand()
    capsule_root = Path.join([root | @capsule])

    with {:ok, manifest} <- load_json(Path.join(capsule_root, "manifest.json"), "manifest"),
         :ok <- validate_schema(manifest, @manifest_schema, "manifest"),
         :ok <- validate_record_uniqueness(manifest["records"]),
         {:ok, record} <- fetch_public_prerequisite(manifest["records"]),
         {:ok, payload_path} <- confined_regular_path(capsule_root, record["path"]),
         :ok <- verify_digest(payload_path, record["sha256"]),
         {:ok, payload} <- load_json(payload_path, "public prerequisite"),
         :ok <- validate_schema(payload, @prerequisite_schema, "public prerequisite"),
         :ok <- validate_binding(manifest["release"], payload) do
      {:ok, payload["facts"]}
    else
      {:error, diagnostics} when is_list(diagnostics) -> {:error, Enum.sort(diagnostics)}
      {:error, diagnostic} -> {:error, [diagnostic]}
    end
  end

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
    diagnostics =
      for {key, label} <- [{"id", "ID"}, {"path", "path"}, {"role", "role"}],
          values = Enum.map(records, & &1[key]),
          length(values) != length(Enum.uniq(values)),
          do: "manifest has duplicate record #{label}"

    if diagnostics == [], do: :ok, else: {:error, diagnostics}
  end

  defp fetch_public_prerequisite(records) do
    case Enum.filter(records, &(&1["role"] == "public_prerequisite")) do
      [record] -> {:ok, record}
      [] -> {:error, "manifest has no public_prerequisite record"}
      _ -> {:error, "manifest has duplicate record role"}
    end
  end

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

  defp validate_binding(release, payload) do
    facts = payload["facts"]

    if payload["release"] == release and facts["version"] == release["version"] and
         facts["tag"] == release["tag"] do
      :ok
    else
      {:error, "public prerequisite release binding mismatch"}
    end
  end
end
