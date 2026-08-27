defmodule Mix.Tasks.Quality.Uat do
  @moduledoc false
  use Mix.Task

  @shortdoc "Projects deterministic summary coverage into terminal UAT"
  @coverage_keys MapSet.new([
                   "id",
                   "description",
                   "requirement",
                   "verification",
                   "human_judgment"
                 ])
  @verification_keys MapSet.new(["kind", "ref", "status"])
  @verification_kinds MapSet.new([
                        "unit",
                        "integration",
                        "e2e",
                        "automated_ui",
                        "manual_procedural",
                        "other"
                      ])

  @impl Mix.Task
  def run(args) do
    {opts, positional, invalid} =
      OptionParser.parse(args, strict: [all: :boolean, check: :boolean, write: :boolean])

    if invalid != [] or (opts[:all] == true and positional != []) or
         (opts[:all] != true and length(positional) != 1) or
         (opts[:check] == true and opts[:write] == true) do
      Mix.raise(
        "usage: mix quality.uat PHASE --write | mix quality.uat PHASE --check | mix quality.uat --all --check"
      )
    end

    if opts[:all] == true and opts[:check] != true, do: Mix.raise("--all requires --check")

    if opts[:all] != true and opts[:check] != true and opts[:write] != true,
      do: Mix.raise("choose --write or --check")

    root = File.cwd!()
    phases_root = Path.join(root, ".planning/phases")

    dirs =
      if opts[:all],
        do: discover(phases_root),
        else: [resolve_phase!(phases_root, hd(positional))]

    Enum.each(dirs, fn dir ->
      {number, slug} = phase_identity!(dir)
      records = summaries!(dir)
      canonical = render(number, slug, records)
      uat_path = Path.join(dir, "#{number}-UAT.md")

      cond do
        opts[:write] -> atomic_write!(uat_path, canonical)
        File.read(uat_path) == {:ok, canonical} -> :ok
        true -> Mix.raise("#{uat_path}: missing or stale terminal UAT")
      end
    end)
  end

  def parse_summary(source, text) when is_binary(source) and is_binary(text) do
    case frontmatter(text) do
      {:ok, frontmatter} ->
        with :ok <- completed_requirements(source, frontmatter),
             {:ok, coverage} <- fetch_coverage(source, frontmatter),
             {:ok, records} <-
               validate_coverage(source, coverage, frontmatter["requirements-completed"]) do
          {:ok, records}
        end

      {:error, message} ->
        {:error, "#{source}: #{message}"}
    end
  end

  def render(number, slug, records) do
    blocks =
      records
      |> Enum.with_index(1)
      |> Enum.map(fn {record, index} ->
        refs =
          Enum.map_join(record.verification, "\n", fn verification ->
            "automated: #{verification["ref"]}"
          end)

        "### #{index}. #{record.id} — #{record.description}\n\nsource: #{record.source}\nexpected: #{record.description}\n#{refs}\nresult: pass\n"
      end)

    """
    ---
    phase: #{number}
    slug: #{slug}
    status: terminal
    generated_by: mix quality.uat
    ---

    # Phase #{number} Automated UAT

    #{Enum.join(blocks, "\n")}
    ## Summary

    total: #{length(records)}
    passed: #{length(records)}
    issues: 0
    remaining: 0
    skipped: 0
    blocked: 0
    """
  end

  defp discover(phases_root) do
    phases_root
    |> File.ls!()
    |> Enum.filter(&Regex.match?(~r/^\d+-/, &1))
    |> Enum.map(&Path.join(phases_root, &1))
    |> Enum.reject(&symlink?/1)
    |> Enum.filter(fn dir ->
      {number, _} = phase_identity!(dir)
      number >= 134 and summaries_present?(dir)
    end)
    |> Enum.sort()
  end

  defp resolve_phase!(phases_root, phase) do
    if Path.type(phase) == :absolute or String.contains?(phase, ["/", "\\"]) or
         String.contains?(phase, "..") do
      Mix.raise("unsafe phase selector: #{inspect(phase)}")
    end

    names = File.ls!(phases_root)

    matching_names =
      if Regex.match?(~r/^\d+$/, phase),
        do: Enum.filter(names, &String.starts_with?(&1, "#{phase}-")),
        else: Enum.filter(names, &(&1 == phase))

    matches = Enum.map(matching_names, &Path.join(phases_root, &1))

    if Enum.any?(matches, &symlink?/1),
      do: Mix.raise("symlinked phase directory is not allowed: #{phase}")

    case matches do
      [dir] -> dir
      [] -> Mix.raise("unknown phase selector: #{phase}")
      _ -> Mix.raise("ambiguous phase selector: #{phase}")
    end
  end

  defp phase_identity!(dir) do
    case Regex.run(~r/(\d+)-(.+)$/, Path.basename(dir)) do
      [_, number, slug] -> {String.to_integer(number), slug}
      _ -> Mix.raise("invalid phase directory: #{dir}")
    end
  end

  defp summaries!(dir) do
    dir
    |> Path.join("*-SUMMARY.md")
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.flat_map(fn path ->
      case parse_summary(Path.basename(path), File.read!(path)) do
        {:ok, records} -> records
        {:error, message} -> Mix.raise(message)
      end
    end)
    |> case do
      [] -> Mix.raise("#{dir}: no completed summary coverage")
      records -> records
    end
  end

  defp summaries_present?(dir), do: Path.wildcard(Path.join(dir, "*-SUMMARY.md")) != []
  defp symlink?(path), do: match?({:ok, %File.Stat{type: :symlink}}, File.lstat(path))

  defp frontmatter("---\n" <> rest) do
    case String.split(rest, "\n---\n", parts: 2) do
      [yaml, _body] ->
        case YamlElixir.read_from_string(yaml) do
          {:ok, document} ->
            {:ok, document}

          {:error, error} ->
            {:error, "summary: malformed frontmatter: #{Exception.message(error)}"}
        end

      _ ->
        {:error, "summary: malformed frontmatter"}
    end
  end

  defp frontmatter(_), do: {:error, "summary: missing leading frontmatter"}

  defp completed_requirements(source, %{
         "status" => "complete",
         "requirements-completed" => requirements
       })
       when is_list(requirements) and requirements != [] do
    if Enum.all?(requirements, &is_binary/1),
      do: :ok,
      else: {:error, "#{source}: requirements-completed must contain strings"}
  end

  defp completed_requirements(source, _),
    do: {:error, "#{source}: completed summary needs nonempty requirements-completed"}

  defp fetch_coverage(_source, %{"coverage" => coverage})
       when is_list(coverage) and coverage != [], do: {:ok, coverage}

  defp fetch_coverage(source, _), do: {:error, "#{source}: coverage must be a nonempty list"}

  defp validate_coverage(source, coverage, requirements) do
    with :ok <- unique_ids(source, coverage) do
      coverage
      |> Enum.reduce_while({:ok, []}, fn item, {:ok, records} ->
        case validate_record(source, item, requirements) do
          {:ok, record} -> {:cont, {:ok, records ++ [record]}}
          error -> {:halt, error}
        end
      end)
    end
  end

  defp unique_ids(source, coverage) do
    ids = Enum.map(coverage, &Map.get(&1, "id"))
    if Enum.uniq(ids) == ids, do: :ok, else: {:error, "#{source}: duplicate coverage id"}
  end

  defp validate_record(source, item, requirements) when is_map(item) do
    keys = item |> Map.keys() |> MapSet.new()

    cond do
      !MapSet.subset?(keys, @coverage_keys) ->
        {:error, "#{source}: coverage has unknown field"}

      !is_binary(item["id"]) or item["id"] == "" ->
        {:error, "#{source}: coverage.id is required"}

      !is_binary(item["description"]) or item["description"] == "" ->
        {:error, "#{source}: coverage.description is required"}

      item["human_judgment"] != false ->
        {:error, "#{source}: coverage.human_judgment must be false"}

      item["requirement"] && item["requirement"] not in requirements ->
        {:error, "#{source}: coverage.requirement is not completed"}

      true ->
        validate_verification(source, item)
    end
  end

  defp validate_record(source, _, _), do: {:error, "#{source}: coverage entry must be a map"}

  defp validate_verification(source, item) do
    verifications = item["verification"]

    if is_list(verifications) and verifications != [] and
         Enum.all?(verifications, fn verification ->
           is_map(verification) and MapSet.new(Map.keys(verification)) == @verification_keys and
             verification["kind"] in @verification_kinds and executable_ref?(verification["ref"]) and
             verification["status"] == "pass"
         end) do
      {:ok,
       %{
         id: item["id"],
         description: item["description"],
         verification: verifications,
         source: source
       }}
    else
      {:error, "#{source}: coverage.verification must contain only passing executable maps"}
    end
  end

  defp executable_ref?(ref) when is_binary(ref) do
    String.trim(ref) == ref and ref != "" and not String.contains?(ref, ["\n", "\r", "\t"]) and
      Regex.match?(~r/^(mix|node|elixir|git|sh|bash)\s+/, ref)
  end

  defp executable_ref?(_), do: false

  defp atomic_write!(path, contents) do
    temp = path <> ".tmp-#{System.unique_integer([:positive])}"
    File.write!(temp, contents)
    File.rename!(temp, path)
  end
end
