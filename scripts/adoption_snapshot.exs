defmodule Rendro.AdoptionSnapshot do
  @moduledoc false

  @states %{"HOLD" => 0, "ACCUMULATING" => 1, "TRIGGER" => 2}
  @hex_url "https://hex.pm/api/packages/rendro"
  @baseline_all 867
  @baseline_date "2026-06-12"

  def run(args, context \\ default_context()) do
    with {:ok, options} <- parse_args(args, context),
         {:ok, snapshot} <- build_snapshot(options, context),
         :ok <- write_snapshot(options.output, snapshot) do
      IO.puts("wrote bounded advisory adoption snapshot to #{options.output}")
      :ok
    else
      {:error, message} ->
        Mix.shell().error(to_string(message))
        {:error, message}
    end
  end

  def parse_args(args, _context \\ default_context()) do
    {opts, _argv, invalid} =
      OptionParser.parse(args,
        strict: [
          output: :string,
          date: :string,
          issues_limit: :integer,
          prs_limit: :integer,
          help: :boolean
        ],
        aliases: [o: :output]
      )

    cond do
      invalid != [] ->
        {:error, "invalid options"}

      opts[:help] ->
        {:error, help_text()}

      is_nil(opts[:output]) ->
        {:error, "missing required --output PATH"}

      !Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, opts[:date] || "") ->
        {:error, "--date must be YYYY-MM-DD"}

      (opts[:issues_limit] || 50) not in 1..100 ->
        {:error, "--issues-limit must be 1..100"}

      (opts[:prs_limit] || 50) not in 1..100 ->
        {:error, "--prs-limit must be 1..100"}

      true ->
        {:ok,
         %{
           output: opts[:output],
           date: opts[:date],
           issues_limit: opts[:issues_limit] || 50,
           prs_limit: opts[:prs_limit] || 50
         }}
    end
  end

  def build_snapshot(options, context) do
    retrieved_at = Map.get(context, :now, DateTime.utc_now() |> DateTime.to_iso8601())

    downloads = retrieve_hex(context, retrieved_at)

    demand =
      retrieve_candidates("demand", issue_command(options.issues_limit), context, retrieved_at)

    contributor =
      retrieve_candidates("contributor", pr_command(options.prs_limit), context, retrieved_at)

    families = %{downloads: downloads, demand: demand, contributor: contributor}

    {:ok,
     %{
       "schema_version" => 1,
       "review_date" => options.date,
       "families" =>
         Map.new(families, fn {key, value} -> {Atom.to_string(key), encode_family(value)} end),
       "composite" => %{
         "decision" => composite_decision(Map.values(families)),
         "rule" => "minimum family decision"
       }
     }}
  end

  def hex_family(%{"downloads" => %{"all" => all, "week" => week}}, retrieved_at)
      when is_integer(all) and all >= 0 and is_integer(week) and week >= 0 do
    {:ok,
     %{
       retrieval: "AVAILABLE",
       decision: downloads_decision(all, week),
       source: @hex_url,
       query: @hex_url,
       pagination_limit: 1,
       retrieved_at: retrieved_at,
       raw: %{all: all, week: week}
     }}
  end

  def hex_family(_, _),
    do:
      {:error, "Hex metadata must contain non-negative downloads.all and downloads.week integers"}

  def candidate_family(kind, candidates, retrieved_at)
      when kind in ["demand", "contributor"] and is_list(candidates) do
    with :ok <- validate_candidates(candidates) do
      decision = if candidates == [], do: "HOLD", else: "ACCUMULATING"

      {:ok,
       %{
         retrieval: "AVAILABLE",
         decision: decision,
         source: "https://github.com/szTheory/rendro",
         query: "bounded #{kind} review",
         pagination_limit: 50,
         retrieved_at: retrieved_at,
         candidate_count: length(candidates),
         candidates: candidates
       }}
    end
  end

  def candidate_family(_, _, _), do: {:error, "candidate result must be a list"}

  def unavailable_family(kind, reason)
      when kind in ["downloads", "demand", "contributor"] and is_binary(reason) do
    %{
      retrieval: "UNAVAILABLE",
      decision: "HOLD",
      source: source_for(kind),
      query: query_for(kind),
      pagination_limit: 50,
      failure_reason: bounded_reason(reason)
    }
  end

  def triggerable?(%{retrieval: "AVAILABLE", decision: "TRIGGER"}), do: true
  def triggerable?(_), do: false

  def digest(value),
    do:
      value |> canonical_json() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)

  def write_snapshot(path, payload) when is_binary(path) and is_map(payload) do
    with :ok <- File.mkdir_p(Path.dirname(path)),
         {:ok, temp} <- write_temp(path, Jason.encode!(payload)) do
      try do
        case link_exclusively(temp, path) do
          :ok -> :ok
          {:error, :eexist} -> {:error, :target_exists}
          {:error, _} = error -> error
        end
      after
        _ = File.rm(temp)
      end
    end
  end

  def composite_decision(families) when is_list(families) do
    families
    |> Enum.map(& &1.decision)
    |> Enum.min_by(&Map.fetch!(@states, &1))
  end

  defp retrieve_hex(context, retrieved_at) do
    case run_command(context, "curl", ["-fsSL", @hex_url]) do
      {output, 0} ->
        with {:ok, decoded} <- Jason.decode(output),
             {:ok, family} <- hex_family(decoded, retrieved_at) do
          Map.put(family, :result_digest, digest(decoded))
        else
          {:error, reason} -> unavailable_family("downloads", "invalid Hex response: #{reason}")
        end

      {output, status} ->
        unavailable_family(
          "downloads",
          "Hex retrieval failed (exit #{status}): #{bounded_reason(output)}"
        )
    end
  end

  defp retrieve_candidates(kind, {command, args, limit}, context, retrieved_at) do
    case run_command(context, command, args) do
      {output, 0} ->
        with {:ok, decoded} <- Jason.decode(output),
             {:ok, candidates} <- normalize_candidates(kind, decoded),
             {:ok, family} <- candidate_family(kind, candidates, retrieved_at) do
          family
          |> Map.put(:query, Enum.join([command | args], " "))
          |> Map.put(:pagination_limit, limit)
          |> Map.put(:result_digest, digest(decoded))
        else
          {:error, reason} -> unavailable_family(kind, "invalid #{kind} response: #{reason}")
        end

      {output, status} ->
        unavailable_family(
          kind,
          "#{kind} retrieval failed (exit #{status}): #{bounded_reason(output)}"
        )
    end
  end

  defp normalize_candidates(kind, candidates) when is_list(candidates),
    do:
      Enum.reduce_while(candidates, {:ok, []}, fn candidate, {:ok, acc} ->
        case normalize_candidate(kind, candidate) do
          {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
          error -> {:halt, error}
        end
      end)
      |> then(fn
        {:ok, values} -> {:ok, Enum.reverse(values)}
        error -> error
      end)

  defp normalize_candidates(_, _), do: {:error, "candidate response must be a JSON array"}

  defp normalize_candidate(
         kind,
         %{"number" => number, "title" => title, "url" => url} = candidate
       )
       when is_integer(number) and number > 0 and is_binary(title) and is_binary(url) do
    author = get_in(candidate, ["author", "login"])
    merged_at = candidate["mergedAt"]

    if is_binary(author) and (kind == "demand" || is_binary(merged_at)) do
      {:ok,
       %{
         number: number,
         title: bounded_text(title),
         url: url,
         author: author,
         merged_at: merged_at,
         disposition: "rejected",
         reason: default_reason(kind, candidate)
       }}
    else
      {:error, "candidate metadata is incomplete"}
    end
  end

  defp normalize_candidate(_, _), do: {:error, "candidate metadata is malformed"}

  defp validate_candidates(candidates),
    do:
      Enum.reduce_while(candidates, :ok, fn candidate, :ok ->
        if is_map(candidate) and is_integer(candidate[:number]) and is_binary(candidate[:url]),
          do: {:cont, :ok},
          else: {:halt, {:error, "candidate metadata is malformed"}}
      end)

  defp downloads_decision(all, week) when all - @baseline_all >= 1_500 and week >= 150,
    do: "ACCUMULATING"

  defp downloads_decision(_, _), do: "HOLD"

  defp encode_family(family),
    do: family |> Map.new(fn {key, value} -> {Atom.to_string(key), value} end)

  defp write_temp(path, contents) do
    temp = path <> ".tmp-" <> Integer.to_string(System.unique_integer([:positive]))

    case File.open(temp, [:write, :exclusive, :binary]) do
      {:ok, io} ->
        IO.binwrite(io, contents)
        :ok = :file.sync(io)
        :ok = File.close(io)
        {:ok, temp}

      error ->
        error
    end
  end

  defp link_exclusively(temp, path),
    do: :file.make_link(String.to_charlist(temp), String.to_charlist(path))

  defp run_command(context, command, args),
    do: context.runner.(command, args, stderr_to_stdout: true)

  defp default_context, do: %{runner: &System.cmd/3}

  defp issue_command(limit),
    do:
      {"gh",
       [
         "issue",
         "list",
         "--state",
         "all",
         "--search",
         "label:adoption:signal OR label:area:text-shaping",
         "--limit",
         Integer.to_string(limit),
         "--json",
         "number,title,author,createdAt,url,labels"
       ], limit}

  defp pr_command(limit),
    do:
      {"gh",
       [
         "pr",
         "list",
         "--state",
         "merged",
         "--search",
         "merged:>=#{@baseline_date} -author:szTheory",
         "--limit",
         Integer.to_string(limit),
         "--json",
         "number,title,author,mergedAt,url"
       ], limit}

  defp source_for("downloads"), do: @hex_url
  defp source_for(_), do: "https://github.com/szTheory/rendro"
  defp query_for("downloads"), do: @hex_url
  defp query_for(kind), do: "bounded #{kind} review"

  defp bounded_reason(reason),
    do: reason |> to_string() |> String.replace(~r/[\r\n\t]+/, " ") |> String.slice(0, 240)

  defp bounded_text(text), do: text |> String.slice(0, 240)

  defp default_reason("demand", _),
    do:
      "requires maintainer qualification against requester, organization, use-case, and blocking rules"

  defp default_reason("contributor", candidate),
    do:
      if(bot?(candidate),
        do: "bot or Dependabot author excluded",
        else: "requires material non-maintainer contribution review"
      )

  defp bot?(candidate),
    do: get_in(candidate, ["author", "login"]) in ["dependabot[bot]", "dependabot"]

  defp canonical_json(value) when is_map(value),
    do:
      value
      |> Enum.map(fn {key, item} -> {to_string(key), item} end)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map_join(",", fn {key, item} ->
        Jason.encode!(key) <> ":" <> canonical_json(item)
      end)
      |> then(&("{" <> &1 <> "}"))

  defp canonical_json(value) when is_list(value),
    do: "[" <> Enum.map_join(value, ",", &canonical_json/1) <> "]"

  defp canonical_json(value), do: Jason.encode!(value)

  defp help_text,
    do:
      "usage: mix run --require scripts/adoption_snapshot.exs -- --output PATH --date YYYY-MM-DD [--issues-limit 1..100] [--prs-limit 1..100]"
end

unless Code.ensure_loaded?(ExUnit.Server) and Process.whereis(ExUnit.Server) do
  Rendro.AdoptionSnapshot.run(System.argv())
end
