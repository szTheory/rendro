defmodule Rendro.CatalogEvidenceParity do
  @moduledoc false

  @routes ~w(phase126_preset_review phase127_catalog_review phase130_review phase130_canonical)a

  @spec compare(map(), map(), atom() | String.t()) :: {:ok, map()} | {:error, [atom()]}
  def compare(legacy_root, generic_root, route)
      when is_map(legacy_root) and is_map(generic_root) do
    route = normalize_route(route)

    with :ok <- validate_route(route),
         :ok <- validate_root(legacy_root),
         :ok <- validate_root(generic_root),
         :ok <- compare_authority(legacy_root, generic_root) do
      {:ok,
       %{
         "route" => Atom.to_string(route),
         "shared" => shared_facts(legacy_root),
         "legacy" => provenance(legacy_root),
         "generic" => provenance(generic_root)
       }}
    else
      {:error, reasons} when is_list(reasons) -> {:error, reasons}
      {:error, reason} -> {:error, [reason]}
    end
  end

  def compare(_legacy_root, _generic_root, _route), do: {:error, [:invalid_parity_input]}

  defp validate_route(route) when route in @routes, do: :ok
  defp validate_route(_route), do: {:error, [:invalid_route]}

  defp validate_root(root) do
    reasons =
      []
      |> invalid_unless(
        valid_sha?(root["candidate_sha"]) and root["candidate_sha"] == root["checked_out_head"],
        :invalid_identity
      )
      |> invalid_unless(valid_renderer?(root["renderer"]), :invalid_renderer)
      |> invalid_unless(valid_payloads?(root["payloads"]), :invalid_payloads)
      |> invalid_unless(
        valid_actions?(root["actions"]) and valid_permissions?(root["permissions"]),
        :invalid_control_plane
      )
      |> invalid_unless(valid_reviewer?(root["reviewer"]), :invalid_reviewer)
      |> Kernel.++(provenance_errors(root))

    if reasons == [], do: :ok, else: {:error, Enum.uniq(reasons)}
  end

  defp compare_authority(legacy, generic) do
    if shared_facts(legacy) == shared_facts(generic),
      do: :ok,
      else: {:error, [:shared_authority_mismatch]}
  end

  defp shared_facts(root) do
    Map.take(
      root,
      ~w(candidate_sha checked_out_head renderer payloads actions permissions reviewer)
    )
  end

  defp provenance(root) do
    Map.take(
      root,
      ~w(run_id run_attempt run_url artifact_identity upload_digest provenance_candidate_sha)
    )
  end

  defp provenance_errors(root) do
    provenance = provenance(root)

    []
    |> invalid_unless(
      is_binary(provenance["run_id"]) and
        Regex.match?(~r/\A[A-Za-z0-9._-]+\z/, provenance["run_id"] || ""),
      :invalid_provenance
    )
    |> invalid_unless(
      is_integer(provenance["run_attempt"]) and provenance["run_attempt"] > 0,
      :invalid_provenance
    )
    |> invalid_unless(
      is_binary(provenance["run_url"]) and
        String.starts_with?(provenance["run_url"] || "", "https://"),
      :invalid_provenance
    )
    |> invalid_unless(
      is_binary(provenance["artifact_identity"]) and
        String.trim(provenance["artifact_identity"] || "") != "",
      :invalid_provenance
    )
    |> invalid_unless(valid_sha256?(provenance["upload_digest"]), :invalid_provenance)
    |> invalid_unless(
      provenance["provenance_candidate_sha"] == root["candidate_sha"],
      :misbound_provenance
    )
    |> Enum.reverse()
  end

  defp valid_renderer?(%{"version" => version, "binary_sha256" => binary_sha, "dpi" => dpi}),
    do:
      is_binary(version) and version != "" and valid_sha256?(binary_sha) and is_integer(dpi) and
        dpi > 0

  defp valid_renderer?(_renderer), do: false

  defp valid_payloads?(payloads) when is_list(payloads) and payloads != [] do
    roles = Enum.map(payloads, &Map.get(&1, "role"))

    roles == Enum.sort(roles) and length(roles) == length(Enum.uniq(roles)) and
      Enum.all?(payloads, fn payload ->
        is_binary(payload["role"]) and valid_sha256?(payload["sha256"]) and
          is_integer(payload["count"]) and payload["count"] > 0
      end)
  end

  defp valid_payloads?(_payloads), do: false

  defp valid_actions?(%{"checkout" => pin}),
    do: is_binary(pin) and Regex.match?(~r/\A[0-9a-f]{40}\z/, pin)

  defp valid_actions?(_actions), do: false
  defp valid_permissions?(%{"contents" => "read"}), do: true
  defp valid_permissions?(_permissions), do: false
  defp valid_reviewer?(%{"required" => required}) when is_boolean(required), do: true
  defp valid_reviewer?(_reviewer), do: false

  defp valid_sha?(value), do: is_binary(value) and Regex.match?(~r/\A[0-9a-f]{40}\z/, value)
  defp valid_sha256?(value), do: is_binary(value) and Regex.match?(~r/\A[0-9a-f]{64}\z/, value)

  defp invalid_unless(reasons, true, _reason), do: reasons
  defp invalid_unless(reasons, false, reason), do: [reason | reasons]

  defp normalize_route(route) when route in @routes, do: route

  defp normalize_route(route) when is_binary(route) do
    Enum.find(@routes, &(Atom.to_string(&1) == route)) || :invalid
  end

  defp normalize_route(_route), do: :invalid
end
