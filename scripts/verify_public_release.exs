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
  @candidate_tag "v1.3.4"
  @v1_3_0_peeled_sha "3d014b8194782fc29bc685c0d5e84e4adc64b2c3"
  @v1_3_0_run_id "32513353551"
  @v1_3_1_tag_object_sha "b386d1e39b6c9e63af58aa1fa5890d93909d278f"
  @v1_3_1_peeled_sha "7afb1dd056bba234d1bd4ec1c4487f2ea8e308f1"
  @v1_3_1_run_id "32539594278"
  @v1_3_2_tag_object_sha "9b7ff50c69c0e9bd6ae39f0c79f76c4663d936fd"
  @v1_3_2_peeled_sha "47af6448d2989ffe69c4b80c77935c896b1ddb07"
  @v1_3_2_run_id "32586098785"
  @v1_3_2_validate_job_id "97062582546"
  @v1_3_2_publish_job_id "97064173653"
  @v1_3_3_tag_object_sha "c96bf205d7216cdcf4846a0f24a312f9c1c75b0f"
  @v1_3_3_peeled_sha "cfc58a81865e060351ce33d98f5e52de8cd198d9"
  @v1_3_3_run_id "32596108284"
  @v1_3_3_validate_job_id "97087204354"
  @v1_3_3_publish_job_id "97088652899"

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
         :ok <- require_symbols(facts["hexdocs_symbols"] || []),
         :ok <- validate_v1_3_0_incident(facts),
         :ok <- validate_v1_3_1_incident(facts),
         :ok <- validate_v1_3_2_incident(facts),
         :ok <- validate_v1_3_3_incident(facts) do
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
         {:ok, docs} <- hexdocs_probes(options.tag, candidate),
         {:ok, incidents} <- collect_incident_facts(repository) do
      {:ok,
       Map.merge(
         incidents,
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
         })
       )}
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

  defp github_tag_object(repository, tag) do
    with {:ok, ref} <- github_json(["api", "repos/#{repository}/git/ref/tags/#{tag}"]),
         %{"object" => %{"sha" => object_sha, "type" => "tag"}} <- ref,
         {:ok, tag_object} <- github_json(["api", "repos/#{repository}/git/tags/#{object_sha}"]),
         %{"object" => %{"sha" => peeled_sha, "type" => "commit"}} <- tag_object do
      {:ok, %{object_sha: object_sha, peeled_sha: peeled_sha}}
    else
      _ -> {:error, "remote tag is not an annotated tag pointing at a commit"}
    end
  end

  defp github_run(id),
    do: github_json(["run", "view", id, "--json", "conclusion,event,headSha,name,jobs"])

  defp collect_incident_facts(repository) do
    with {:ok, v1_3_0} <- github_tag(repository, "v1.3.0"),
         {:ok, v1_3_0_run} <- github_run(@v1_3_0_run_id),
         {:ok, v1_3_1} <- github_tag_object(repository, "v1.3.1"),
         {:ok, v1_3_1_run} <- github_run(@v1_3_1_run_id),
         true <- publish_job_skipped?(v1_3_1_run),
         {:ok, v1_3_2} <- github_tag_object(repository, "v1.3.2"),
         {:ok, v1_3_2_run} <- github_run(@v1_3_2_run_id),
         true <- job_conclusion?(v1_3_2_run, @v1_3_2_validate_job_id, "failure"),
         true <- job_conclusion?(v1_3_2_run, @v1_3_2_publish_job_id, "skipped"),
         {:ok, v1_3_3} <- github_tag_object(repository, "v1.3.3"),
         {:ok, v1_3_3_run} <- github_run(@v1_3_3_run_id),
         true <- job_conclusion?(v1_3_3_run, @v1_3_3_validate_job_id, "failure"),
         true <- job_conclusion?(v1_3_3_run, @v1_3_3_publish_job_id, "skipped"),
         true <- hex_absent?("1.3.0"),
         true <- hexdocs_absent?("1.3.0"),
         true <- hex_absent?("1.3.1"),
         true <- hexdocs_absent?("1.3.1"),
         true <- hex_absent?("1.3.2"),
         true <- hexdocs_absent?("1.3.2"),
         true <- hex_absent?("1.3.3"),
         true <- hexdocs_absent?("1.3.3") do
      {:ok,
       %{
         "v1_3_0_peeled_sha" => v1_3_0,
         "v1_3_0_run_id" => @v1_3_0_run_id,
         "v1_3_0_conclusion" => v1_3_0_run["conclusion"],
         "v1_3_0_hex_absent" => true,
         "v1_3_0_hexdocs_absent" => true,
         "v1_3_1_tag_object_sha" => v1_3_1.object_sha,
         "v1_3_1_peeled_sha" => v1_3_1.peeled_sha,
         "v1_3_1_run_id" => @v1_3_1_run_id,
         "v1_3_1_conclusion" => v1_3_1_run["conclusion"],
         "v1_3_1_publish_job_skipped" => true,
         "v1_3_1_hex_absent" => true,
         "v1_3_1_hexdocs_absent" => true,
         "v1_3_2_tag_object_sha" => v1_3_2.object_sha,
         "v1_3_2_peeled_sha" => v1_3_2.peeled_sha,
         "v1_3_2_run_id" => @v1_3_2_run_id,
         "v1_3_2_conclusion" => v1_3_2_run["conclusion"],
         "v1_3_2_validate_job_id" => @v1_3_2_validate_job_id,
         "v1_3_2_validate_job_conclusion" => "failure",
         "v1_3_2_publish_job_id" => @v1_3_2_publish_job_id,
         "v1_3_2_publish_job_conclusion" => "skipped",
         "v1_3_2_hex_absent" => true,
         "v1_3_2_hexdocs_absent" => true,
         "v1_3_3_tag_object_sha" => v1_3_3.object_sha,
         "v1_3_3_peeled_sha" => v1_3_3.peeled_sha,
         "v1_3_3_run_id" => @v1_3_3_run_id,
         "v1_3_3_conclusion" => v1_3_3_run["conclusion"],
         "v1_3_3_validate_job_id" => @v1_3_3_validate_job_id,
         "v1_3_3_validate_job_conclusion" => "failure",
         "v1_3_3_publish_job_id" => @v1_3_3_publish_job_id,
         "v1_3_3_publish_job_conclusion" => "skipped",
         "v1_3_3_hex_absent" => true,
         "v1_3_3_hexdocs_absent" => true,
         "v1_3_3_hexdocs_dispatch_absent" => true,
         "v1_3_3_verifier_absent" => true
       }}
    else
      _ -> {:error, "immutable failed-release incident probes did not match"}
    end
  end

  defp publish_job_skipped?(%{"jobs" => jobs}) when is_list(jobs) do
    Enum.any?(jobs, fn job -> job["name"] == "publish" and job["conclusion"] == "skipped" end)
  end

  defp publish_job_skipped?(_), do: false

  defp job_conclusion?(%{"jobs" => jobs}, job_id, conclusion) when is_list(jobs) do
    Enum.any?(jobs, fn job ->
      to_string(job["databaseId"] || job["id"]) == job_id and job["conclusion"] == conclusion
    end)
  end

  defp job_conclusion?(_, _, _), do: false

  defp hex_absent?(version),
    do: url_absent?("https://hex.pm/api/packages/rendro/releases/#{version}")

  defp hexdocs_absent?(version), do: url_absent?("https://hexdocs.pm/rendro/#{version}")

  defp url_absent?(url) do
    case System.cmd("curl", [
           "--silent",
           "--location",
           "--max-redirs",
           "5",
           "--output",
           "/dev/null",
           "--write-out",
           "%{http_code}",
           url
         ]) do
      {"404", 0} -> true
      _ -> false
    end
  end

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
           {:ok, archive} <- File.read(path),
           {:ok, outer} <- :erl_tar.extract({:binary, archive}, [:memory]),
           {_, contents} when is_binary(contents) <- List.keyfind(outer, ~c"contents.tar.gz", 0),
           {:ok, inner} <- :erl_tar.extract({:binary, :zlib.gunzip(contents)}, [:memory]) do
        {:ok, Enum.map(inner, fn {member, _contents} -> List.to_string(member) end)}
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

  defp validate_v1_3_0_incident(facts) do
    with :ok <-
           equal?(
             facts["v1_3_0_peeled_sha"],
             @v1_3_0_peeled_sha,
             "v1.3.0 incident peeled SHA is incorrect"
           ),
         :ok <-
           equal?(facts["v1_3_0_run_id"], @v1_3_0_run_id, "v1.3.0 incident run ID is incorrect"),
         :ok <- equal?(facts["v1_3_0_conclusion"], "failure", "v1.3.0 incident did not fail"),
         :ok <- equal?(facts["v1_3_0_hex_absent"], true, "v1.3.0 Hex release is present"),
         :ok <- equal?(facts["v1_3_0_hexdocs_absent"], true, "v1.3.0 HexDocs page is present") do
      :ok
    end
  end

  defp validate_v1_3_1_incident(facts) do
    with :ok <-
           equal?(
             facts["v1_3_1_tag_object_sha"],
             @v1_3_1_tag_object_sha,
             "v1.3.1 incident tag object SHA is incorrect"
           ),
         :ok <-
           equal?(
             facts["v1_3_1_peeled_sha"],
             @v1_3_1_peeled_sha,
             "v1.3.1 incident peeled SHA is incorrect"
           ),
         :ok <-
           equal?(facts["v1_3_1_run_id"], @v1_3_1_run_id, "v1.3.1 incident run ID is incorrect"),
         :ok <-
           equal?(facts["v1_3_1_conclusion"], "cancelled", "v1.3.1 incident was not cancelled"),
         :ok <-
           equal?(
             facts["v1_3_1_publish_job_skipped"],
             true,
             "v1.3.1 incident publish job was not skipped"
           ),
         :ok <- equal?(facts["v1_3_1_hex_absent"], true, "v1.3.1 Hex release is present"),
         :ok <- equal?(facts["v1_3_1_hexdocs_absent"], true, "v1.3.1 HexDocs page is present") do
      :ok
    end
  end

  defp validate_v1_3_2_incident(facts) do
    with :ok <-
           equal?(
             facts["v1_3_2_tag_object_sha"],
             @v1_3_2_tag_object_sha,
             "v1.3.2 incident tag object SHA is incorrect"
           ),
         :ok <-
           equal?(
             facts["v1_3_2_peeled_sha"],
             @v1_3_2_peeled_sha,
             "v1.3.2 incident peeled SHA is incorrect"
           ),
         :ok <-
           equal?(facts["v1_3_2_run_id"], @v1_3_2_run_id, "v1.3.2 incident run ID is incorrect"),
         :ok <- equal?(facts["v1_3_2_conclusion"], "failure", "v1.3.2 incident run did not fail"),
         :ok <-
           equal?(
             facts["v1_3_2_validate_job_id"],
             @v1_3_2_validate_job_id,
             "v1.3.2 incident validate job ID is incorrect"
           ),
         :ok <-
           equal?(
             facts["v1_3_2_validate_job_conclusion"],
             "failure",
             "v1.3.2 incident validate job was not a failure"
           ),
         :ok <-
           equal?(
             facts["v1_3_2_publish_job_id"],
             @v1_3_2_publish_job_id,
             "v1.3.2 incident publish job ID is incorrect"
           ),
         :ok <-
           equal?(
             facts["v1_3_2_publish_job_conclusion"],
             "skipped",
             "v1.3.2 incident publish job was not skipped"
           ),
         :ok <- equal?(facts["v1_3_2_hex_absent"], true, "v1.3.2 Hex release is present"),
         :ok <- equal?(facts["v1_3_2_hexdocs_absent"], true, "v1.3.2 HexDocs page is present") do
      :ok
    end
  end

  defp validate_v1_3_3_incident(facts) do
    with :ok <-
           equal?(
             facts["v1_3_3_tag_object_sha"],
             @v1_3_3_tag_object_sha,
             "v1.3.3 incident tag object SHA is incorrect"
           ),
         :ok <-
           equal?(
             facts["v1_3_3_peeled_sha"],
             @v1_3_3_peeled_sha,
             "v1.3.3 incident peeled SHA is incorrect"
           ),
         :ok <-
           equal?(facts["v1_3_3_run_id"], @v1_3_3_run_id, "v1.3.3 incident run ID is incorrect"),
         :ok <- equal?(facts["v1_3_3_conclusion"], "failure", "v1.3.3 incident run did not fail"),
         :ok <-
           equal?(
             facts["v1_3_3_validate_job_id"],
             @v1_3_3_validate_job_id,
             "v1.3.3 incident validate job ID is incorrect"
           ),
         :ok <-
           equal?(
             facts["v1_3_3_validate_job_conclusion"],
             "failure",
             "v1.3.3 incident validate job was not a failure"
           ),
         :ok <-
           equal?(
             facts["v1_3_3_publish_job_id"],
             @v1_3_3_publish_job_id,
             "v1.3.3 incident publish job ID is incorrect"
           ),
         :ok <-
           equal?(
             facts["v1_3_3_publish_job_conclusion"],
             "skipped",
             "v1.3.3 incident publish job was not skipped"
           ),
         :ok <- equal?(facts["v1_3_3_hex_absent"], true, "v1.3.3 Hex release is present"),
         :ok <- equal?(facts["v1_3_3_hexdocs_absent"], true, "v1.3.3 HexDocs page is present"),
         :ok <-
           equal?(
             facts["v1_3_3_hexdocs_dispatch_absent"],
             true,
             "v1.3.3 incident HexDocs dispatch was not absent"
           ),
         :ok <-
           equal?(
             facts["v1_3_3_verifier_absent"],
             true,
             "v1.3.3 incident verifier was not absent"
           ) do
      :ok
    end
  end

  defp validate_tag(@candidate_tag), do: :ok

  defp validate_tag("v" <> version) do
    if Regex.match?(~r/^\d+\.\d+\.\d+$/, version),
      do: {:error, "tag must match the exact approved recovery candidate #{@candidate_tag}"},
      else: {:error, "tag must be the exact approved recovery candidate #{@candidate_tag}"}
  end

  defp validate_tag(_),
    do: {:error, "tag must be the exact approved recovery candidate #{@candidate_tag}"}

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

  defp equal?(value, value, _message), do: :ok
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
