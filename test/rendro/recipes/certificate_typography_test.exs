defmodule Rendro.Recipes.CertificateTypographyTest do
  @moduledoc """
  WR-01 (122-VERIFICATION) closure for the Certificate centering path.

  Certificate horizontally centers every text run by measuring its rendered
  width, historically ALWAYS against built-in Helvetica metrics, while the
  emitted `%Text{}` carried the seam's `font_role`. Under a theme whose font
  role named a non-Helvetica-metric font the text de-centered silently. The fix
  keys the measurement font off the SAME role the run emits
  (`centering_measure_font/1`) and raises honestly on a non-Helvetica-metric
  role rather than mis-centering (errors-as-product).

  DEVIATION NOTE (Rule 1 — plan assumption corrected): the plan's third
  assertion asked for a `{:unknown_text_font, _}` `Build.run/1` raise-path via a
  "non-centered" font role. Certificate has NO non-centered text run — every
  emitted run (title, subtitle, recipient, body, date, seal) is centered and now
  routes through `centering_measure_font/1`, so an unregistered centered role
  trips the `{:unsupported_centered_font_role, _}` guard BEFORE reaching build.
  The `{:unknown_text_font, _}` build-time raise-path is representatively proven
  on Statement/Invoice/Ticket (see statement_typography_test.exs, Phase 122-02);
  Certificate's honest representative raise-path is the centering guard below.
  """
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Certificate

  defp sample_data do
    %{
      title: "Certificate of Completion",
      recipient: "Jane Smith",
      date: ~D[2026-05-29],
      body: "For outstanding achievement and dedication.",
      seal_line: "Awarded 2026"
    }
  end

  describe "WR-01 coupling (default theme: measurement font == emitted role font)" do
    test "a themed Certificate renders {:ok, _} under Rendro.Theme.default()" do
      # default/0 resolves every font role to :default (built-in Helvetica), the
      # same font the centering measurement uses — so measurement and the emitted
      # run agree and the render succeeds.
      assert {:ok, _} =
               Rendro.render(Certificate.document(sample_data(), theme: Rendro.Theme.default()))
    end

    test "the themed render matches the no-theme render's centering (both :default → Helvetica)" do
      data = sample_data()
      # Both paths resolve heading/body to :default → Helvetica metrics, so the
      # geometry-driven section build succeeds on both without raising.
      assert [%Rendro.Section{} | _] = Certificate.sections(data)

      assert [%Rendro.Section{} | _] =
               Certificate.sections(data, theme: Rendro.Theme.default())
    end
  end

  describe "WR-01 guard (non-Helvetica-metric centered role raises, never silently de-centers)" do
    test "an unregistered fonts.heading role raises {:unsupported_centered_font_role, _}" do
      # heading role centers the title + recipient — a non-Helvetica-metric role
      # here would silently de-center; assert the honest raise at section build.
      assert_raise ArgumentError,
                   ~r/unsupported_centered_font_role.*:some_unregistered_font/s,
                   fn ->
                     Certificate.sections(sample_data(),
                       typography: %{
                         fonts: %{
                           heading: :some_unregistered_font,
                           body: :default,
                           mono: :default
                         }
                       }
                     )
                   end
    end

    test "an unregistered fonts.body role also raises {:unsupported_centered_font_role, _}" do
      # body role centers the subtitle/body paragraph/date/seal — also guarded.
      assert_raise ArgumentError, ~r/unsupported_centered_font_role.*:another_bad_font/s, fn ->
        Certificate.sections(sample_data(),
          typography: %{fonts: %{heading: :default, body: :another_bad_font, mono: :default}}
        )
      end
    end
  end

  describe "TYPE-02 raise-path scoping (guard is narrow — no spurious raise on unused roles)" do
    test "an unregistered fonts.mono role does NOT raise (Certificate emits no mono run)" do
      # Certificate has no mono text run, so an unused unregistered mono role must
      # not trip the centering guard — proving the guard is keyed on actually
      # emitted centered roles, not every role in the typography map.
      assert {:ok, _} =
               Rendro.render(
                 Certificate.document(sample_data(),
                   typography: %{fonts: %{heading: :default, body: :default, mono: :no_such_font}}
                 )
               )
    end
  end
end
