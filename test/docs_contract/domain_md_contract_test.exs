defmodule Rendro.DocsContract.DomainMdContractTest do
  use ExUnit.Case, async: true

  @required_headings [
    "## Domain Language",
    "## Personas & Jobs-to-be-Done",
    "## Reading Context",
    "## Layout & Typographic Conventions"
  ]

  describe "DOMAIN.md structural contract (RUB-01)" do
    test "at least one domain DOMAIN.md exists" do
      assert Path.wildcard("priv/examples/*/DOMAIN.md") != [],
             "expected at least one priv/examples/*/DOMAIN.md, found none"
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
