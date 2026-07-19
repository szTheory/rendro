defmodule Rendro.Test.Golden do
  @moduledoc false
  #
  # Shared byte-golden assert/bless helper for the family × stress-dimension
  # matrix (117-04) and the raster fixtures (117-06).
  #
  # This is the *un-gated* sibling of the raster `assert_or_bless`
  # (test/rendro/adapters/pdfium_raster_snapshot_test.exs). Unlike raster hashes,
  # PDF-byte SHA-256 hashes are cross-platform stable — embedded fonts + the
  # fixed epoch `D:20000101000000Z` + sorted dict keys make
  # `Rendro.render(doc, deterministic: true)` portable — so there is
  # deliberately NO `GITHUB_ACTIONS` container gate on blessing (D-04).
  #
  # Doctrine (D-04): default `mix test` is assert-only; a MISSING ref
  # hard-flunks (never a silent auto-create — the deliberate inverse of Jest's
  # `-u` footgun); a hash change is a DEFECT, not a refresh, unless a human
  # re-authorizes it via `MIX_GOLDEN_BLESS=true mix test <file>`.

  @default_base_dir "priv/goldens"

  @doc """
  Renders `doc` twice with `deterministic: true`, asserts the two binaries are
  byte-equal (so a non-determinism leak can never be blessed into a ref), and
  returns the identical PDF bytes.
  """
  @spec assert_deterministic!(Rendro.Document.t()) :: binary()
  def assert_deterministic!(doc) do
    {:ok, pdf1} = Rendro.render(doc, deterministic: true)
    {:ok, pdf2} = Rendro.render(doc, deterministic: true)
    ExUnit.Assertions.assert(pdf1 == pdf2, "non-determinism leak — refusing to bless")
    pdf1
  end

  @doc """
  Compares the SHA-256 of `pdf` against the committed ref at
  `\#{base_dir}/\#{family}/\#{dimension}.sha256`, or blesses it when
  `MIX_GOLDEN_BLESS=true`.

  `opts[:base_dir]` defaults to `"priv/goldens"` (the production default; the
  self-test overrides it to a scratch dir so it never writes into the real
  committed golden tree).
  """
  @spec assert_or_bless({atom(), atom()}, binary(), keyword()) :: :ok
  def assert_or_bless({family, dimension}, pdf, opts \\ []) do
    base_dir = Keyword.get(opts, :base_dir, @default_base_dir)
    ref_path = "#{base_dir}/#{family}/#{dimension}.sha256"
    actual = Base.encode16(:crypto.hash(:sha256, pdf), case: :lower)

    cond do
      System.get_env("MIX_GOLDEN_BLESS") == "true" ->
        # Un-gated bless (D-04): no GITHUB_ACTIONS check — byte hashes are
        # cross-platform stable. Writes only the one-line hash, never PDF bytes.
        File.mkdir_p!(Path.dirname(ref_path))
        File.write!(ref_path, actual <> "\n")
        :ok

      not File.exists?(ref_path) ->
        ExUnit.Assertions.flunk("""
        Missing golden ref: #{ref_path}

        A missing golden ref is a HARD failure — Rendro never silently
        auto-creates one (the deliberate inverse of Jest's `-u` auto-bless).
        A hash change is a DEFECT, not a refresh, unless a human re-authorizes it.

        If this is an intentional, human-authorized new baseline, re-run:
            MIX_GOLDEN_BLESS=true mix test <file>
        which writes only the one-line #{ref_path} hash.
        """)

      true ->
        expected = ref_path |> File.read!() |> String.trim()

        ExUnit.Assertions.assert(
          actual == expected,
          """
          Golden hash mismatch for #{family}/#{dimension} (ref: #{ref_path}).

          a hash change is a DEFECT, not a refresh, unless a human re-authorizes it.

          If this drift is an intentional, human-approved change, re-run:
              MIX_GOLDEN_BLESS=true mix test <file>
          (Note: an authorized `Rendro.Format` string evolution will correctly
          flap these goldens too — distinguish that from a determinism regression.)
          """
        )

        :ok
    end
  end
end
