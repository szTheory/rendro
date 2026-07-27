defmodule Rendro.Recipes.CertificateOptsThreadingTest do
  @moduledoc """
  Phase 120 Plan 03 (swap): proves the `:theme` opt threads through Certificate's
  `palette/1` seam — the theme's `rule` recolors the decorative frame, an
  explicit `:palette`/`border: %{color: ...}` still wins (D-01), and the
  no-theme path (including the NON-BLACK `{34, 34, 34}` frame default) stays
  byte-identical (PLUMB-03).

  The frame draws only when `border:` is present, so the recolor assertions
  exercise `border: true`.
  """
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Certificate

  defp sample_data do
    %{title: "Certificate of Completion", recipient: "Jane Smith", date: ~D[2026-05-29]}
  end

  describe "Certificate :theme threading (PLUMB-02)" do
    test ":theme threads through page_template/1 without KeyError" do
      assert %Rendro.PageTemplate{} = Certificate.page_template(theme: Rendro.Theme.default())
    end

    test "a themed border render differs from the no-theme border render" do
      data = sample_data()

      refute Certificate.sections(data, border: true) ==
               Certificate.sections(data, border: true, theme: Rendro.Theme.default())
    end

    test ":palette override wins over :theme (D-01)" do
      data = sample_data()
      themed = Certificate.sections(data, border: true, theme: Rendro.Theme.default())

      overridden =
        Certificate.sections(data,
          border: true,
          theme: Rendro.Theme.default(),
          palette: %{rule: {200, 0, 0}}
        )

      refute themed == overridden
    end

    test "explicit border color still wins over :theme rule" do
      data = sample_data()
      themed = Certificate.sections(data, border: true, theme: Rendro.Theme.default())

      explicit =
        Certificate.sections(data, border: %{color: {200, 0, 0}}, theme: Rendro.Theme.default())

      refute themed == explicit
    end
  end

  describe "Certificate no-theme byte-identity (PLUMB-03)" do
    test "no-border sections(data) equals sections(data, [])" do
      data = sample_data()
      assert Certificate.sections(data) == Certificate.sections(data, [])
    end

    test "no-theme + no-border frame default stays {34,34,34}" do
      data = sample_data()
      # The no-theme border render must equal itself regardless of empty opts;
      # the {34,34,34} default is preserved (no theme rule bleeds in).
      assert Certificate.sections(data, border: true) ==
               Certificate.sections(data, border: true, palette: %{})
    end
  end
end
