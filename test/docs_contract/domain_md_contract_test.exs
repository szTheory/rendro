defmodule Rendro.DocsContract.DomainMdContractTest do
  use ExUnit.Case, async: true

  @required_headings [
    "## Domain Language",
    "## Personas & Jobs-to-be-Done",
    "## Reading Context",
    "## Layout & Typographic Conventions"
  ]

  describe "DOMAIN.md structural contract (RUB-01)" do
    test "every demonstrated domain has a co-located DOMAIN.md (D-04)" do
      # Derive the demonstrated-domain set from the fixture directories on disk
      # (priv/examples/<domain>/<business>/<domain>.json) so future domains
      # inherit the contract automatically — never a hardcoded family list.
      demonstrated_domains =
        "priv/examples/*/*/*.json"
        |> Path.wildcard()
        |> Enum.map(fn path ->
          path |> Path.relative_to("priv/examples") |> Path.split() |> hd()
        end)
        |> Enum.uniq()
        |> Enum.sort()

      # Non-vacuous guard: the derivation must actually find demonstrated
      # domains, otherwise the per-domain assertion below would pass trivially.
      assert demonstrated_domains != [],
             "expected at least one demonstrated domain under priv/examples/*/*/*.json, found none"

      for domain <- demonstrated_domains do
        path = Path.join(["priv/examples", domain, "DOMAIN.md"])

        assert File.exists?(path),
               "demonstrated domain #{inspect(domain)} is missing its co-located DOMAIN.md (expected #{path})"
      end
    end

    test "every DOMAIN.md carries all four required section headings" do
      for path <- Path.wildcard("priv/examples/*/DOMAIN.md") do
        content = File.read!(path)

        for heading <- @required_headings do
          assert content =~ heading,
                 "#{path} is missing required heading #{inspect(heading)}"
        end
      end
    end
  end
end
