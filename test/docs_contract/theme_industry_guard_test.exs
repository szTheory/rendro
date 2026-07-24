defmodule Rendro.DocsContract.ThemeIndustryGuardTest do
  @moduledoc """
  CONTRACT-03 / D-02 source-grep tripwire for `lib/rendro/theme.ex`.

  `Rendro.Theme` is industry-agnostic by construction: it ships exactly one
  theme (`default/0`) plus a `from_brand/2` brand-token entry point, and MUST
  NOT name any industry, recipe-family, or named brand, nor carry any
  genre/preset/catalog/configurator machinery. This guard reads the source
  statically (no compilation, no rendering, no I/O beyond the read) and fails
  the instant any forbidden term leaks into the public theme surface.

  Mirrors the working `File.read!` + `refute source =~ term` shape from
  `integrations_claims_test.exs:35-45` (inverted from `assert` to `refute`).
  """
  use ExUnit.Case, async: true

  @theme_source "lib/rendro/theme.ex"

  test "theme.ex names no industry, recipe family, or named brand (CONTRACT-03 / D-02)" do
    source = File.read!(@theme_source)

    # Verbatim recipe-family / industry terms from 119-PATTERNS.md:165-166.
    forbidden = ~w(invoice payslip ticket certificate statement receipt
                   medical legal restaurant retail)

    for term <- forbidden, do: refute source =~ term
  end

  test "theme.ex ships one theme + from_brand/2 only — no genre/preset machinery (CONTRACT-03 / D-02)" do
    source = File.read!(@theme_source)

    for term <- ~w(preset catalog configurator genre), do: refute source =~ term
  end

  test "theme.ex exposes exactly the one-theme + from_brand/2 positive surface (CONTRACT-03)" do
    source = File.read!(@theme_source)

    assert source =~ "def default"
    assert source =~ "def from_brand"
  end
end
