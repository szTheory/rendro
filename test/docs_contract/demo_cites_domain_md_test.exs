defmodule Rendro.DocsContract.DemoCitesDomainMdTest do
  use ExUnit.Case, async: true

  @manifest_path "priv/quality/rubric_scores.json"

  defp scores do
    @manifest_path
    |> File.read!()
    |> JSON.decode!()
    |> Map.fetch!("scores")
  end

  # Derive the demonstrated-domain set from the fixture directories on disk
  # (priv/examples/<domain>/<business>/<domain>.json) so future domains inherit
  # the contract automatically — never a hardcoded family list.
  defp demonstrated_domains do
    "priv/examples/*/*/*.json"
    |> Path.wildcard()
    |> Enum.map(fn path ->
      path |> Path.relative_to("priv/examples") |> Path.split() |> hd()
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  describe "demo-cites-DOMAIN.md citation contract (D-05)" do
    test "non-vacuity guard: the scores array is non-empty" do
      assert scores() != [],
             "expected at least one rubric score entry in #{@manifest_path}, found none " <>
               "(this contract must not pass vacuously once demos are scored)"
    end

    test "every score entry carries a domain_md path that exists on disk" do
      for entry <- scores() do
        domain_md = Map.get(entry, "domain_md")

        assert is_binary(domain_md) and domain_md != "",
               "score entry #{inspect(entry["demo_id"])} is missing a non-empty domain_md citation"

        assert File.exists?(domain_md),
               "score entry #{inspect(entry["demo_id"])} cites domain_md #{inspect(domain_md)} " <>
                 "which does not exist on disk"
      end
    end

    test "every demonstrated domain is cited by at least one score entry (D-05)" do
      cited =
        scores()
        |> Enum.map(&Map.get(&1, "domain_md"))
        |> Enum.reject(&is_nil/1)
        |> MapSet.new()

      for domain <- demonstrated_domains() do
        expected = Path.join(["priv/examples", domain, "DOMAIN.md"])

        assert MapSet.member?(cited, expected),
               "demonstrated domain #{inspect(domain)} is not cited by any score entry's " <>
                 "domain_md (expected a score entry citing #{expected})"
      end
    end
  end
end
