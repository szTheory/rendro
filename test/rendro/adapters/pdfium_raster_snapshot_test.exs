defmodule Rendro.Adapters.PdfiumRasterSnapshotTest do
  use ExUnit.Case, async: false

  # Bless guard: MIX_RASTER_BLESS=true outside GITHUB_ACTIONS must raise.
  # This test runs in normal `mix test` (no tag) — covers RAST-02b.
  test "bless guard raises when MIX_RASTER_BLESS=true outside GITHUB_ACTIONS" do
    System.put_env("MIX_RASTER_BLESS", "true")

    on_exit(fn ->
      System.delete_env("MIX_RASTER_BLESS")
      System.delete_env("GITHUB_ACTIONS")
    end)

    System.delete_env("GITHUB_ACTIONS")

    assert_raise RuntimeError, ~r/must only run in the pinned CI container/, fn ->
      assert_or_bless_stub()
    end
  end

  # Hash-equality fast path — skips gracefully when ref files do not yet exist.
  # Excluded from default `mix test` by the raster_snapshot tag.
  @tag raster_snapshot: true
  test "hash-equality fast path skips gracefully when ref hashes do not exist" do
    ref_path = "priv/raster_refs/invoice/page_1.sha256"

    if File.exists?(ref_path) do
      png_binary = File.read!(ref_path)
      expected_hash = String.trim(png_binary)
      actual_hash = Base.encode16(:crypto.hash(:sha256, png_binary), case: :lower)

      assert actual_hash == expected_hash,
             "Hash-equality fast path mismatch. Run in CI with MIX_RASTER_BLESS=true to update refs."
    else
      IO.puts("Skipping: no ref hashes yet — bless in CI first")
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

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
  defp bless_refs(fixture_name, pngs) do
    Enum.each(Enum.with_index(pngs, 1), fn {png, page_num} ->
      ref_path = "priv/raster_refs/#{fixture_name}/page_#{page_num}.sha256"
      File.mkdir_p!(Path.dirname(ref_path))
      hash = Base.encode16(:crypto.hash(:sha256, png), case: :lower)
      File.write!(ref_path, hash <> "\n")
    end)
  end
end
