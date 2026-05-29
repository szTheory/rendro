defmodule Rendro.AuditBranchProtection do
  @moduledoc """
  Close-ritual live GitHub branch-protection audit.

  Compares live protection on the baseline branch against
  `priv/guardrails/required_status_checks.json`. Run at Phase 72 close and
  optionally before tagging a release.

  ## Usage

      GITHUB_TOKEN=ghp_... mix run scripts/audit_branch_protection.exs

  ## Token scope

  Requires a `GITHUB_TOKEN` with repository administration read access (`repo`
  scope for classic tokens, or equivalent fine-grained admin read on branch
  protection). The token is read from the environment only and is never logged.

  ## Output

  On success, prints normalized JSON to stdout:

      {"strict": true, "contexts": ["long-lived-live-proof", "release-proof", "signing-live-proof", "test"]}

  On failure, prints missing contexts or strictness gaps to stderr and exits 1.
  This script is intentionally **not** part of `mix ci` (fork PR safety).
  """

  @baseline_path "priv/guardrails/required_status_checks.json"
  @api_version "2022-11-28"

  def run(_args \\ []) do
    with {:ok, baseline} <- load_baseline(),
         {:ok, token} <- fetch_token(),
         {:ok, owner, repo} <- parse_repo_slug(),
         {:ok, protection} <- fetch_protection(owner, repo, baseline["branch"], token) do
      audit(protection, baseline)
    else
      {:error, message} ->
        Mix.shell().error(message)
        System.halt(1)
    end
  end

  defp load_baseline do
    with {:ok, contents} <- File.read(@baseline_path),
         {:ok, baseline} <- Jason.decode(contents) do
      {:ok, baseline}
    else
      {:error, reason} ->
        {:error, "failed to read baseline #{@baseline_path}: #{inspect(reason)}"}
    end
  end

  defp fetch_token do
    case System.get_env("GITHUB_TOKEN") do
      token when is_binary(token) and token != "" -> {:ok, token}
      _ -> {:error, "GITHUB_TOKEN is not set; export a token with repo admin read scope"}
    end
  end

  defp parse_repo_slug do
    source_url = Mix.Project.config()[:source_url]

    case URI.parse(source_url) do
      %URI{host: "github.com", path: "/" <> path} ->
        case String.split(path, "/", parts: 2) do
          [owner, repo] -> {:ok, owner, repo}
          _ -> {:error, "could not parse owner/repo from source_url #{inspect(source_url)}"}
        end

      _ ->
        {:error, "unsupported source_url for GitHub audit: #{inspect(source_url)}"}
    end
  end

  defp fetch_protection(owner, repo, branch, token) do
    url = "https://api.github.com/repos/#{owner}/#{repo}/branches/#{branch}/protection"

    case Req.get(url,
           headers: [
             {"authorization", "Bearer #{token}"},
             {"accept", "application/vnd.github+json"},
             {"x-github-api-version", @api_version}
           ]
         ) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: 404}} ->
        {:error, "branch protection not found for #{owner}/#{repo}:#{branch}"}

      {:ok, %{status: status, body: body}} ->
        {:error, "GitHub API returned HTTP #{status}: #{inspect(body)}"}

      {:error, exception} ->
        {:error, "GitHub API request failed: #{Exception.message(exception)}"}
    end
  end

  defp audit(protection, baseline) do
    live_strict = get_in(protection, ["required_status_checks", "strict"])
    live_contexts = normalize_contexts(protection)
    baseline_required = baseline["required_contexts"]
    missing = baseline_required -- live_contexts

    cond do
      live_strict != true ->
        Mix.shell().error("branch protection strict is #{inspect(live_strict)}; expected true")
        System.halt(1)

      missing != [] ->
        Mix.shell().error("missing required contexts: #{Enum.join(missing, ", ")}")
        System.halt(1)

      true ->
        payload = %{"strict" => true, "contexts" => live_contexts}
        IO.puts(Jason.encode!(payload))
        :ok
    end
  end

  defp normalize_contexts(protection) do
    checks = get_in(protection, ["required_status_checks", "checks"]) || []

    contexts =
      if checks != [] do
        Enum.map(checks, & &1["context"])
      else
        get_in(protection, ["required_status_checks", "contexts"]) || []
      end

    contexts |> Enum.sort()
  end
end

unless Code.ensure_loaded?(ExUnit.Server) and Process.whereis(ExUnit.Server) do
  Rendro.AuditBranchProtection.run(System.argv())
end
