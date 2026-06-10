if Code.ensure_loaded?(HarfbuzzEx) do
  defmodule Rendro.Adapters.HarfBuzz do
    @moduledoc """
    HarfBuzz text shaping adapter via the `harfbuzz_ex` NIF.

    Requires `{:harfbuzz_ex, "~> 1.2", optional: true}` in your mix.exs and:

        config :rendro, shaper: Rendro.Adapters.HarfBuzz

    This adapter handles all scripts including Arabic, Indic, Thai, Hebrew, and other
    complex scripts. It delegates to `HarfbuzzEx.get!/3` with a SHA256-keyed font cache
    kept in a rendro-private (0700) subdirectory of the system temp dir; cached files
    are content-verified before reuse and written atomically. Cache files persist for
    the host's lifetime (one file per distinct embedded font).

    This module is only compiled when `HarfbuzzEx` is available at compile time
    (via `Code.ensure_loaded?/1`). If `harfbuzz_ex` is not in your dependencies,
    this module is absent and core Rendro is unaffected.
    """
    @moduledoc tags: [:adapter]

    @behaviour Rendro.Text.Shaper

    @spec shape(Rendro.PDF.Font.t(), String.t(), keyword()) ::
            {:ok, [Rendro.Text.Shaper.glyph()]} | {:error, term()}
    @impl Rendro.Text.Shaper
    def shape(%Rendro.PDF.Font{source: :built_in} = font, text, opts) do
      # Delegate built-in fonts to Simple (cmap + advance widths, no NIF required)
      Rendro.Text.Shaper.Simple.shape(font, text, opts)
    end

    def shape(%Rendro.PDF.Font{source: :embedded, font_bytes: bytes}, text, _opts)
        when is_binary(bytes) and is_binary(text) do
      font_path = cached_font_path(bytes)

      raw_glyphs = HarfbuzzEx.get!(font_path, text, :all)
      glyphs = enrich_with_cluster(raw_glyphs, text)

      missing_count = Enum.count(glyphs, fn g -> Map.get(g, :name) == ".notdef" end)

      if missing_count > 0 do
        :telemetry.execute(
          [:rendro, :shaper, :missing_glyph],
          %{count: missing_count},
          %{font: font_path, text: text}
        )
      end

      {:ok, glyphs}
    rescue
      e -> {:error, e}
    end

    # SHA256-keyed font cache hardened against shared-tmp attacks (CR-05):
    #
    #   * Files live in a rendro-private subdirectory created (and re-chmodded)
    #     with 0700 permissions instead of directly in the world-writable tmp dir.
    #   * A cache hit is only trusted when File.lstat reports a regular file
    #     (symlinks are rejected) AND its content matches the font bytes exactly
    #     — pre-planted or stale/partial files are detected and rewritten.
    #   * Writes go to a unique temp name and are published with an atomic
    #     File.rename, so concurrent renders can never observe a torn write.
    #
    # Dependency-free by design; raised filesystem errors are converted to
    # {:error, exception} by the rescue clause in shape/3.
    defp cached_font_path(bytes) do
      hash = :crypto.hash(:sha256, bytes) |> Base.encode16()
      dir = Path.join(System.tmp_dir!(), "rendro_fonts_#{:erlang.phash2({node(), :rendro})}")
      File.mkdir_p!(dir)
      _ = File.chmod(dir, 0o700)
      font_path = Path.join(dir, "#{hash}.ttf")

      if cached_font_valid?(font_path, bytes) do
        font_path
      else
        write_font_atomically(dir, font_path, bytes)
      end
    end

    defp cached_font_valid?(font_path, bytes) do
      with {:ok, %File.Stat{type: :regular}} <- File.lstat(font_path),
           {:ok, existing} <- File.read(font_path) do
        existing == bytes
      else
        _ -> false
      end
    end

    defp write_font_atomically(dir, font_path, bytes) do
      tmp =
        Path.join(dir, "#{Path.basename(font_path)}.#{System.unique_integer([:positive])}.tmp")

      File.write!(tmp, bytes)
      _ = File.chmod(tmp, 0o600)

      # If font_path exists as a symlink or stale file, rename atomically
      # replaces the link/file itself (not its target). If it is something
      # rename cannot replace (e.g. a planted directory), remove it first.
      case File.rename(tmp, font_path) do
        :ok ->
          font_path

        {:error, _} ->
          _ = File.rm_rf(font_path)
          File.rename!(tmp, font_path)
          font_path
      end
    end

    # HarfbuzzEx 1.2 (rustybuzz wrapper) exposes only name/advances/offsets per
    # glyph — no cluster values and no glyph ids. Cluster mapping is therefore
    # derived conservatively rather than positionally fabricated (CR-04):
    #
    #   * glyph count == grapheme count (no ligation/decomposition): assign each
    #     glyph the byte offset of the grapheme at the same index. Exact for the
    #     1:1 LTR case. (For RTL output HarfBuzz returns visual order, so the
    #     per-index pairing can attribute swapped advances within a run; widths
    #     still sum exactly and boundaries stay grapheme-aligned. Visual
    #     reordering itself is deferred to the v2.7 shaping slice.)
    #
    #   * glyph count != grapheme count (ligatures, decompositions, marks):
    #     emit cluster: 0 for every glyph. The measure stage then treats the run
    #     as a single atomic cluster-run with summed advances — correct total
    #     width and no fabricated (wrong) cluster boundaries.
    #
    # gid stays 0 because the NIF does not expose glyph ids (only glyph names);
    # the writer keys rendering on run text, not gids.
    defp enrich_with_cluster(raw_glyphs, text) do
      graphemes = String.graphemes(text)

      if length(raw_glyphs) == length(graphemes) do
        grapheme_offsets =
          graphemes
          |> Enum.scan(0, fn g, offset -> offset + byte_size(g) end)
          |> List.insert_at(0, 0)
          |> Enum.drop(-1)

        Enum.zip(raw_glyphs, grapheme_offsets)
        |> Enum.map(fn {g, cluster} ->
          Map.from_struct(g) |> Map.put(:cluster, cluster) |> Map.put(:gid, 0)
        end)
      else
        Enum.map(raw_glyphs, fn g ->
          Map.from_struct(g) |> Map.put(:cluster, 0) |> Map.put(:gid, 0)
        end)
      end
    end
  end
end
