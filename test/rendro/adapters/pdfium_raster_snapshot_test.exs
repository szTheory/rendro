defmodule Rendro.Adapters.PdfiumRasterSnapshotTest do
  use ExUnit.Case, async: false

  alias Rendro.Adapters.Pdfium
  alias Rendro.Test.EdgeFixtures
  alias Rendro.Test.Golden

  @fixture_name "forms_support_fixture"
  @fixture_path "test/fixtures/forms_support_fixture.pdf"

  # Bless guard: MIX_RASTER_BLESS=true outside GITHUB_ACTIONS must raise.
  # This test runs in normal `mix test` (no tag) — covers RAST-02b.
  test "bless guard raises when MIX_RASTER_BLESS=true outside GITHUB_ACTIONS" do
    prior_bless = System.get_env("MIX_RASTER_BLESS")
    prior_github_actions = System.get_env("GITHUB_ACTIONS")

    System.put_env("MIX_RASTER_BLESS", "true")
    System.delete_env("GITHUB_ACTIONS")

    on_exit(fn ->
      restore_env("MIX_RASTER_BLESS", prior_bless)
      restore_env("GITHUB_ACTIONS", prior_github_actions)
    end)

    assert_raise RuntimeError, ~r/must only run in the pinned CI container/, fn ->
      assert_or_bless_stub()
    end
  end

  @tag raster_snapshot: true
  test "forms support fixture renders to committed golden PNG hash" do
    pdf = File.read!(@fixture_path)

    assert {:ok, pngs} = Pdfium.render(pdf, dpi: 150, pages: "1")
    assert length(pngs) == 1

    assert_or_bless(@fixture_name, pngs)
  end

  # ---------------------------------------------------------------------------
  # D-10 curated raster fixtures (Plan 117-06) — added IN PLACE to this exact
  # file so the CI raster job's hardcoded single-file path
  # (`mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs`)
  # discovers them with zero .github/workflows/ci.yml edit (RESEARCH Landmine 1).
  # Each builds its PDF via Rendro (EdgeFixtures), proves two-run byte-determinism
  # (Golden.assert_deterministic!/1) before rasterization, then reuses the file's
  # existing private assert_or_bless/2. Refs at priv/raster_refs/<fixture>/page_N
  # are blessed once in the pinned CI container (D-11) — not authored here, so
  # these assert-only tests fail at the missing-ref stage until that CI run, just
  # like the forms_support_fixture case does today.
  # ---------------------------------------------------------------------------

  # D-10a combined fixtures: one multi-page render simultaneously proves
  # pagination + 60+ line items + odd/even running-content parity.
  @tag raster_snapshot: true
  test "edge_invoice_pagination_60plus_odd_even renders to committed golden PNG hashes" do
    doc = EdgeFixtures.document(:invoice, :odd_even_running_content)
    pdf = Golden.assert_deterministic!(doc)

    assert {:ok, pngs} = Pdfium.render(pdf, dpi: 150)
    assert length(pngs) >= 2

    assert_or_bless("edge_invoice_pagination_60plus_odd_even", pngs)
  end

  @tag raster_snapshot: true
  test "edge_statement_pagination_60plus_odd_even renders to committed golden PNG hashes" do
    doc = EdgeFixtures.document(:statement, :odd_even_running_content)
    pdf = Golden.assert_deterministic!(doc)

    assert {:ok, pngs} = Pdfium.render(pdf, dpi: 150)
    assert length(pngs) >= 2

    assert_or_bless("edge_statement_pagination_60plus_odd_even", pngs)
  end

  @tag raster_snapshot: true
  test "edge_payslip_pagination_60plus_odd_even renders to committed golden PNG hashes" do
    doc = EdgeFixtures.document(:payslip, :odd_even_running_content)
    pdf = Golden.assert_deterministic!(doc)

    assert {:ok, pngs} = Pdfium.render(pdf, dpi: 150)
    assert length(pngs) >= 2

    assert_or_bless("edge_payslip_pagination_60plus_odd_even", pngs)
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp restore_env(name, nil), do: System.delete_env(name)
  defp restore_env(name, value), do: System.put_env(name, value)

  # Used only to test the bless guard in isolation (called with dummy args).
  defp assert_or_bless_stub do
    assert_or_bless("stub_fixture", [])
  end

  # Routes based on MIX_RASTER_BLESS env + GITHUB_ACTIONS guard.
  # Source: RESEARCH.md Pattern 2 bless guard code example.
  defp assert_or_bless(fixture_name, pngs) do
    if System.get_env("MIX_RASTER_BLESS") == "true" do
      if System.get_env("GITHUB_ACTIONS") != "true" do
        raise """
        MIX_RASTER_BLESS=true must only run in the pinned CI container.
        Raster hashes are not deterministic across platforms.
        """
      end

      bless_refs(fixture_name, pngs)
    else
      assert_golden_hashes(fixture_name, pngs)
    end
  end

  # Compares rendered PNGs against committed .sha256 ref files.
  defp assert_golden_hashes(_fixture_name, []) do
    flunk("render produced no PNGs")
  end

  defp assert_golden_hashes(fixture_name, pngs) do
    Enum.each(Enum.with_index(pngs, 1), fn {png, page_num} ->
      ref_path = "priv/raster_refs/#{fixture_name}/page_#{page_num}.sha256"
      expected_hash = File.read!(ref_path) |> String.trim()
      actual_hash = Base.encode16(:crypto.hash(:sha256, png), case: :lower)

      assert actual_hash == expected_hash,
             "Page #{page_num} hash mismatch for #{fixture_name}. Run in CI with MIX_RASTER_BLESS=true to update refs."
    end)
  end

  # Writes SHA-256 hashes of PNGs as committed ref files (CI-only).
  defp bless_refs(_fixture_name, []) do
    flunk("cannot bless empty PNG list")
  end

  defp bless_refs(fixture_name, pngs) do
    Enum.each(Enum.with_index(pngs, 1), fn {png, page_num} ->
      ref_path = "priv/raster_refs/#{fixture_name}/page_#{page_num}.sha256"
      File.mkdir_p!(Path.dirname(ref_path))
      hash = Base.encode16(:crypto.hash(:sha256, png), case: :lower)
      File.write!(ref_path, hash <> "\n")
    end)
  end
end
