defmodule Rendro.PublicReleaseVerifier do
  @moduledoc false

  @required_archive_members [
    "mix.exs",
    "README.md",
    "guides/presets.md",
    "assets/rendro/configurator/index.html"
  ]
  @required_symbols [
    "Rendro.Theme",
    "Rendro.Theme.Presets",
    "Rendro.Adapters.Phoenix.render_pdf/3"
  ]

  def validate(facts) when is_map(facts) do
    candidate = facts["candidate_commit_sha"]

    with :ok <- equal?(facts["peeled_tag_sha"], candidate, "peeled tag does not match candidate"),
         :ok <-
           equal?(
             facts["release_head_sha"],
             candidate,
             "release workflow head does not match candidate"
           ),
         :ok <-
           equal?(
             facts["release_conclusion"],
             "success",
             "release workflow did not conclude successfully"
           ),
         :ok <- equal?(facts["release_event"], "push", "release workflow event is not a tag push"),
         :ok <-
           equal?(
             facts["hexdocs_head_sha"],
             candidate,
             "HexDocs workflow head does not match candidate"
           ),
         :ok <-
           equal?(
             facts["hexdocs_conclusion"],
             "success",
             "HexDocs workflow did not conclude successfully"
           ),
         :ok <-
           equal?(
             facts["hexdocs_event"],
             "workflow_dispatch",
             "HexDocs workflow event is not dispatch"
           ),
         :ok <-
           equal?(
             facts["hex_version"],
             facts["version"],
             "Hex version does not match candidate version"
           ),
         :ok <-
           equal?(
             facts["hexdocs_version"],
             facts["version"],
             "HexDocs version does not match candidate version"
           ),
         :ok <-
           equal?(
             facts["hexdocs_source_sha"],
             candidate,
             "HexDocs source does not match candidate"
           ),
         :ok <- require_members(facts["archive_members"] || []),
         :ok <- require_symbols(facts["hexdocs_symbols"] || []) do
      :ok
    end
  end

  def write_verified(path, facts) do
    with :ok <- validate(facts),
         record <- Map.put(facts, "public_prerequisite", "VERIFIED"),
         :ok <- File.write(path, JSON.encode!(record)) do
      :ok
    end
  end

  defp equal?(value, value, _message) when is_binary(value), do: :ok
  defp equal?(_actual, _expected, message), do: {:error, message}

  defp require_members(members) do
    case Enum.find(@required_archive_members, &(&1 not in members)) do
      nil -> :ok
      member -> {:error, "package archive is missing required member #{member}"}
    end
  end

  defp require_symbols(symbols) do
    case Enum.find(@required_symbols, &(&1 not in symbols)) do
      nil -> :ok
      symbol -> {:error, "HexDocs is missing required symbol #{symbol}"}
    end
  end
end
