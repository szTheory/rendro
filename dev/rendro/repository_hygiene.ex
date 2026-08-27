defmodule Rendro.RepositoryHygiene do
  @moduledoc false

  @manifest_path "priv/quality/package-members-v1.json"
  @inventory_path "scripts/README.md"

  @spec run(keyword()) :: :ok | {:error, [String.t()]}
  def run(options \\ []) do
    root = unique_root(Keyword.get(options, :temp_parent, System.tmp_dir!()))
    build = Keyword.get(options, :build, &build_package/1)

    try do
      with :ok <- File.mkdir_p(root),
           {:ok, members} <- build.(root) do
        if Keyword.get(options, :skip_checks, false) do
          :ok
        else
          check_repository(members)
        end
      end
    after
      File.rm_rf(root)
    end
  end

  @spec check_members([String.t()], map()) :: :ok | {:error, [String.t()]}
  def check_members(actual, %{"members" => expected})
      when is_list(actual) and is_list(expected) do
    actual = actual |> Enum.uniq() |> Enum.sort()
    expected = expected |> Enum.uniq() |> Enum.sort()

    diagnostics =
      Enum.map(
        expected -- actual,
        &"missing package member: #{&1}; update the package boundary or manifest."
      ) ++
        Enum.map(
          actual -- expected,
          &"unexpected package member: #{&1}; remove it from the package or add a reviewed manifest entry."
        ) ++
        Enum.map(Enum.filter(actual, &forbidden_package_path?/1), fn path ->
          "forbidden package member: #{path}; internal/planning/proof material must not ship."
        end)

    result(diagnostics)
  end

  def check_members(_, _),
    do: {:error, ["package-members manifest is invalid; restore its sorted members list."]}

  @spec check_tracked_paths(binary()) :: :ok | {:error, [String.t()]}
  def check_tracked_paths(nul_paths) when is_binary(nul_paths) do
    nul_paths
    |> String.split("\0", trim: true)
    |> Enum.filter(&String.starts_with?(&1, ".planning/"))
    |> Enum.reject(&canonical_planning_path?/1)
    |> Enum.map(fn path ->
      "#{path}: invalid planning placement; use an active .planning/phases/<NN>-<slug>/ directory or a milestone archive."
    end)
    |> result()
  end

  @spec check_operational_sources(%{String.t() => String.t()}) :: :ok | {:error, [String.t()]}
  def check_operational_sources(sources) when is_map(sources) do
    sources
    |> Enum.flat_map(fn {path, contents} ->
      if gsd_tooling?(path) or not operational_source?(path) or not archive_reference?(contents) do
        []
      else
        [
          "#{path}: archive consumer; use repository-owned evidence or remove the planning dependency."
        ]
      end
    end)
    |> result()
  end

  @spec check_script_inventory(String.t(), [String.t()]) :: :ok | {:error, [String.t()]}
  def check_script_inventory(inventory, tracked_paths)
      when is_binary(inventory) and is_list(tracked_paths) do
    tracked_paths
    |> Enum.filter(&String.starts_with?(&1, "scripts/"))
    |> Enum.filter(&executable_script?/1)
    |> Enum.reject(&String.contains?(inventory, "`#{&1}`"))
    |> Enum.map(fn path ->
      "#{path}: missing owner-bearing inventory row; add the script to scripts/README.md or remove it."
    end)
    |> result()
  end

  defp check_repository(members) do
    manifest = @manifest_path |> File.read!() |> JSON.decode!()
    {tracked, 0} = System.cmd("git", ["ls-files", "-z"], stderr_to_stdout: true)
    paths = String.split(tracked, "\0", trim: true)

    sources =
      paths
      |> Enum.filter(&operational_source?/1)
      |> Map.new(fn path -> {path, File.read!(path)} end)

    diagnostics =
      diagnostics(check_members(members, manifest)) ++
        diagnostics(check_tracked_paths(tracked)) ++
        diagnostics(check_operational_sources(sources)) ++
        diagnostics(check_script_inventory(File.read!(@inventory_path), paths))

    result(diagnostics)
  rescue
    error ->
      {:error,
       ["repository hygiene could not inspect tracked inputs: #{Exception.message(error)}"]}
  end

  defp build_package(root) do
    tarball = Path.join(root, "rendro.tar")

    {output, status} =
      System.cmd("mix", ["hex.build", "--output", tarball], stderr_to_stdout: true)

    with 0 <- status,
         {:ok, files} <- :erl_tar.extract(String.to_charlist(tarball), [:memory]),
         {_, contents} when is_binary(contents) <-
           Enum.find(files, fn {name, _} -> to_string(name) == "contents.tar.gz" end),
         contents_tar = Path.join(root, "contents.tar.gz"),
         :ok <- File.write(contents_tar, contents),
         :ok <- extract_contents(contents_tar, root) do
      {:ok,
       root
       |> Path.join("**/*")
       |> Path.wildcard(match_dot: true)
       |> Enum.flat_map(&package_files(&1, root))
       |> Enum.sort()}
    else
      nil -> {:error, ["package build did not contain contents.tar.gz"]}
      _ -> {:error, ["package build failed: #{String.trim(output)}"]}
    end
  end

  defp extract_contents(contents_tar, root) do
    case :erl_tar.extract(String.to_charlist(contents_tar), [
           :compressed,
           {:cwd, String.to_charlist(root)}
         ]) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp package_files(path, root) do
    if File.regular?(path) and Path.basename(path) not in ["rendro.tar", "contents.tar.gz"] do
      [Path.relative_to(path, root)]
    else
      []
    end
  end

  defp forbidden_package_path?(path) do
    String.starts_with?(path, [
      ".planning/",
      "evidence/",
      "test/",
      "scripts/",
      ".github/",
      "priv/schemas/",
      "priv/journey_evidence/"
    ]) or
      String.contains?(path, ["/.git", "/.DS_Store", "/node_modules/"]) or
      (String.starts_with?(path, "bench/results/raw/") and String.ends_with?(path, ".pdf"))
  end

  defp canonical_planning_path?(path) do
    Regex.match?(~r{^\.planning/[^/]+$}, path) or
      Regex.match?(~r{^\.planning/phases/\d+(?:\.\d+)?-[a-z0-9-]+/}, path) or
      Regex.match?(~r{^\.planning/milestones/}, path) or
      Regex.match?(~r{^\.planning/(debug|quality|notes|quick|research|seeds|threads)/}, path)
  end

  defp operational_source?(path),
    do:
      String.match?(
        path,
        ~r{^(lib|dev|scripts|\.github)/.+\.(ex|exs|js|cjs|mjs|sh|bash|yml|yaml)$}
      )

  defp executable_script?(path), do: String.match?(path, ~r{\.(exs|sh|js|cjs|mjs)$})
  # These maintainer-only checks inspect planning structure as their explicit subject.
  # They are never package, runtime, release, or ordinary-regression consumers.
  defp gsd_tooling?(path),
    do: path in ["dev/rendro/repository_hygiene.ex", "scripts/quality_governance.cjs"]

  defp archive_reference?(contents), do: String.contains?(contents, ".planning/phases/")
  defp diagnostics(:ok), do: []
  defp diagnostics({:error, values}), do: values
  defp result([]), do: :ok
  defp result(values), do: {:error, values |> Enum.uniq() |> Enum.sort()}

  defp unique_root(parent) do
    suffix = Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)

    Path.join(
      parent,
      "rendro-hygiene-#{System.unique_integer([:positive, :monotonic])}-#{suffix}"
    )
  end
end
