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

  def run(argv, context \\ default_context()) do
    with {:ok, options} <- parse_args(argv),
         {:ok, candidate} <- candidate_from_record(options.candidate_record),
         :ok <- validate_candidate(candidate),
         :ok <- validate_tag(options.tag),
         {:ok, facts} <- context.collect.(options, candidate),
         :ok <- validate(facts),
         :ok <- write_verified(options.output, facts) do
      :ok
    else
      {:error, message} -> {:error, message}
    end
  end

  def parse_args(argv) do
    argv = if List.first(argv) == "--", do: tl(argv), else: argv

    {opts, positional, invalid} =
      OptionParser.parse(argv,
        strict: [
          candidate_record: :string,
          tag: :string,
          release_run_id: :string,
          hexdocs_run_id: :string,
          output: :string,
          check_existing: :boolean
        ]
      )

    required = [:candidate_record, :tag, :release_run_id, :hexdocs_run_id, :output]

    cond do
      positional != [] ->
        {:error, "unexpected positional arguments"}

      invalid != [] ->
        {:error, "invalid options: #{format_invalid(invalid)}"}

      duplicate_option?(argv) ->
        {:error, "duplicate option"}

      Enum.any?(required, &is_nil(opts[&1])) ->
        {:error, "missing required public-release option"}

      opts[:check_existing] != true ->
        {:error, "missing required --check-existing"}

      !Regex.match?(~r/^\d+$/, opts[:release_run_id]) ->
        {:error, "release run ID must be numeric"}

      !Regex.match?(~r/^\d+$/, opts[:hexdocs_run_id]) ->
        {:error, "HexDocs run ID must be numeric"}

      true ->
        {:ok, Map.new(opts)}
    end
  end

  def validate(facts) when is_map(facts) do
    candidate = facts["candidate_commit_sha"]

    with :ok <- validate_candidate(candidate),
         :ok <- equal?(facts["peeled_tag_sha"], candidate, "peeled tag does not match candidate"),
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
           equal?(facts["release_name"], "Release to Hex", "release workflow name is incorrect"),
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
         :ok <- equal?(facts["hexdocs_name"], "HexDocs", "HexDocs workflow name is incorrect"),
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
         :ok <- ensure_safe_output(path),
         record <- Map.put(facts, "public_prerequisite", "VERIFIED"),
         encoded <- JSON.encode!(bounded_record(record)),
         :ok <- atomic_write(path, encoded) do
      :ok
    end
  end

  defp default_context do
    %{collect: &collect_public_facts/2}
  end

  # Test fixtures are deliberately available only in MIX_ENV=test. Production always
  # uses read-only GitHub, Hex, and HexDocs probes below.
  defp collect_public_facts(options, candidate) do
    case System.get_env("RENDRO_PUBLIC_RELEASE_FIXTURE") do
      nil ->
        collect_live_facts(options, candidate)

      path ->
        if Mix.env() == :test do
          collect_fixture_facts(path, options, candidate)
        else
          {:error, "fixture injection is unavailable outside MIX_ENV=test"}
        end
    end
  end

  defp collect_fixture_facts(path, options, candidate) do
    with {:ok, encoded} <- File.read(path),
         {:ok, facts} <- JSON.decode(encoded),
         :ok <-
           equal?(
             facts["candidate_commit_sha"],
             candidate,
             "fixture candidate does not match record"
           ),
         :ok <- equal?(facts["tag"], options.tag, "fixture tag does not match requested tag"),
         :ok <-
           equal?(
             facts["release_run_id"],
             options.release_run_id,
             "fixture release run ID does not match"
           ),
         :ok <-
           equal?(
             facts["hexdocs_run_id"],
             options.hexdocs_run_id,
             "fixture HexDocs run ID does not match"
           ) do
      {:ok, Map.drop(facts, ["tag", "release_run_id", "hexdocs_run_id"])}
    else
      {:error, reason} when is_binary(reason) -> {:error, reason}
      {:error, _} -> {:error, "fixture is not valid JSON"}
    end
  end

  defp collect_live_facts(options, candidate) do
    with {:ok, repository} <- repository(),
         {:ok, peeled_tag_sha} <- github_tag(repository, options.tag),
         {:ok, release} <- github_run(options.release_run_id),
         {:ok, hexdocs} <- github_run(options.hexdocs_run_id),
         {:ok, hex} <- hex_release(options.tag),
         {:ok, archive_members} <- archive_members(options.tag),
         {:ok, docs} <- hexdocs_probes(options.tag, candidate) do
      {:ok,
       Map.merge(docs, %{
         "candidate_commit_sha" => candidate,
         "peeled_tag_sha" => peeled_tag_sha,
         "release_head_sha" => release["headSha"],
         "release_conclusion" => release["conclusion"],
         "release_event" => release["event"],
         "release_name" => release["name"],
         "hexdocs_head_sha" => hexdocs["headSha"],
         "hexdocs_conclusion" => hexdocs["conclusion"],
         "hexdocs_event" => hexdocs["event"],
         "hexdocs_name" => hexdocs["name"],
         "version" => String.trim_leading(options.tag, "v"),
         "hex_version" => hex["version"],
         "archive_members" => archive_members
       })}
    end
  end

  defp repository do
    with {remote, 0} <- System.cmd("git", ["remote", "get-url", "origin"]),
         [_, repository] <-
           Regex.run(~r{(?:github\.com[:/])([^/]+/[^/.]+)(?:\.git)?$}, String.trim(remote)) do
      {:ok, repository}
    else
      _ -> {:error, "could not determine GitHub repository"}
    end
  end

  defp github_tag(repository, tag) do
    with {:ok, ref} <- github_json(["api", "repos/#{repository}/git/ref/tags/#{tag}"]),
         %{"object" => %{"sha" => object_sha, "type" => "tag"}} <- ref,
         {:ok, tag_object} <- github_json(["api", "repos/#{repository}/git/tags/#{object_sha}"]),
         %{"object" => %{"sha" => peeled_sha, "type" => "commit"}} <- tag_object do
      {:ok, peeled_sha}
    else
      _ -> {:error, "remote tag is not an annotated tag pointing at a commit"}
    end
  end

  defp github_run(id),
    do: github_json(["run", "view", id, "--json", "conclusion,event,headSha,name"])

  defp github_json(args) do
    case System.cmd("gh", args, stderr_to_stdout: true) do
      {output, 0} -> decode_json(output, "GitHub response was not valid JSON")
      _ -> {:error, "read-only GitHub probe failed"}
    end
  end

  defp hex_release(tag) do
    version = String.trim_leading(tag, "v")

    case curl_json("https://hex.pm/api/packages/rendro/releases/#{version}") do
      {:ok, %{"version" => ^version} = release} -> {:ok, release}
      {:ok, _} -> {:error, "Hex release version is incorrect"}
      error -> error
    end
  end

  defp archive_members(tag) do
    version = String.trim_leading(tag, "v")

    path =
      Path.join(System.tmp_dir!(), "rendro-#{version}-#{System.unique_integer([:positive])}.tar")

    try do
      with {_, 0} <-
             System.cmd("curl", [
               "--fail",
               "--silent",
               "--show-error",
               "--output",
               path,
               "https://repo.hex.pm/tarballs/rendro-#{version}.tar"
             ]),
           {members, 0} <- System.cmd("tar", ["-tf", path]) do
        {:ok, String.split(members, "\n", trim: true)}
      else
        _ -> {:error, "read-only Hex archive probe failed"}
      end
    after
      File.rm(path)
    end
  end

  defp hexdocs_probes(tag, candidate) do
    version = String.trim_leading(tag, "v")
    base = "https://hexdocs.pm/rendro/#{version}"

    with {:ok, theme} <- curl_text("#{base}/Rendro.Theme.html"),
         {:ok, presets} <- curl_text("#{base}/Rendro.Theme.Presets.html"),
         {:ok, phoenix} <- curl_text("#{base}/Rendro.Adapters.Phoenix.html"),
         {:ok, readme} <- curl_text("#{base}/readme.html"),
         true <- Enum.all?([theme, presets, phoenix, readme], &String.contains?(&1, version)),
         true <- String.contains?(theme, candidate),
         true <- String.contains?(phoenix, "render_pdf/3") do
      {:ok,
       %{
         "hexdocs_version" => version,
         "hexdocs_source_sha" => candidate,
         "hexdocs_symbols" => @required_symbols
       }}
    else
      _ -> {:error, "read-only versioned HexDocs probes failed"}
    end
  end

  defp curl_json(url) do
    with {:ok, text} <- curl_text(url), do: decode_json(text, "HTTP response was not valid JSON")
  end

  defp curl_text(url) do
    case System.cmd("curl", ["--fail", "--silent", "--show-error", "--location", url],
           stderr_to_stdout: true
         ) do
      {text, 0} -> {:ok, text}
      _ -> {:error, "read-only HTTP probe failed"}
    end
  end

  defp candidate_from_record(path) do
    with {:ok, record} <- File.read(path),
         [candidate] <-
           Regex.run(~r/^candidate_commit_sha:\s*([0-9a-f]{40})\s*$/m, record,
             capture: :all_but_first
           ) do
      {:ok, candidate}
    else
      _ -> {:error, "candidate record lacks an exact candidate_commit_sha"}
    end
  end

  defp validate_candidate(candidate) when is_binary(candidate) do
    if Regex.match?(~r/^[0-9a-f]{40}$/, candidate),
      do: :ok,
      else: {:error, "candidate SHA must be 40 lowercase hex characters"}
  end

  defp validate_candidate(_), do: {:error, "candidate SHA must be 40 lowercase hex characters"}

  defp validate_tag("v" <> version) do
    if Regex.match?(~r/^\d+\.\d+\.\d+$/, version),
      do: :ok,
      else: {:error, "tag must be an exact vX.Y.Z release tag"}
  end

  defp validate_tag(_), do: {:error, "tag must be an exact vX.Y.Z release tag"}

  defp ensure_safe_output(path) do
    if path == "" or File.exists?(path), do: {:error, "output must not already exist"}, else: :ok
  end

  defp atomic_write(path, encoded) do
    directory = Path.dirname(path)

    temporary =
      Path.join(directory, ".#{Path.basename(path)}.#{System.unique_integer([:positive])}.tmp")

    with :ok <- File.write(temporary, encoded, [:binary]),
         :ok <- File.rename(temporary, path) do
      :ok
    else
      _ ->
        File.rm(temporary)
        {:error, "could not atomically write public prerequisite record"}
    end
  end

  defp bounded_record(record) do
    record
    |> Map.take([
      "public_prerequisite",
      "candidate_commit_sha",
      "peeled_tag_sha",
      "release_head_sha",
      "release_conclusion",
      "release_event",
      "release_name",
      "hexdocs_head_sha",
      "hexdocs_conclusion",
      "hexdocs_event",
      "hexdocs_name",
      "version",
      "hex_version",
      "hexdocs_version",
      "hexdocs_source_sha",
      "archive_members",
      "hexdocs_symbols"
    ])
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

  defp duplicate_option?(argv) do
    argv
    |> Enum.filter(&String.starts_with?(&1, "--"))
    |> Enum.frequencies()
    |> Enum.any?(fn {_option, count} -> count > 1 end)
  end

  defp format_invalid(invalid), do: Enum.map_join(invalid, ", ", fn {key, _} -> "--#{key}" end)

  defp decode_json(text, error) do
    case JSON.decode(text) do
      {:ok, decoded} -> {:ok, decoded}
      _ -> {:error, error}
    end
  end
end

unless Code.ensure_loaded?(ExUnit.Server) and Process.whereis(ExUnit.Server) do
  case Rendro.PublicReleaseVerifier.run(System.argv()) do
    :ok ->
      :ok

    {:error, message} ->
      IO.puts(:stderr, message)
      System.halt(1)
  end
end
