defmodule Rendro.Test.GoldenTest do
  # async: false — these cases mutate the process-wide MIX_GOLDEN_BLESS /
  # MIX_GOLDEN_DUMP env vars, mirroring the raster analog's env-safety discipline
  # (test/rendro/adapters/pdfium_raster_snapshot_test.exs:42-43).
  use ExUnit.Case, async: false

  alias Rendro.Test.Golden

  # A trivial, always-renderable document reused across the determinism cases.
  defp fixture_doc do
    Rendro.flow([Rendro.block(Rendro.text("golden helper self-test"))])
  end

  # A unique scratch base_dir per case, always cleaned up via on_exit — so no
  # self-test call ever writes into the real committed priv/goldens/ tree.
  defp scratch_dir do
    dir =
      Path.join(
        System.tmp_dir!(),
        "rendro-golden-selftest-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf!(dir) end)
    dir
  end

  # Save/restore MIX_GOLDEN_BLESS exactly like the raster analog's restore_env/2 —
  # never leave the env var mutated for later tests.
  defp restore_env(name, nil), do: System.delete_env(name)
  defp restore_env(name, value), do: System.put_env(name, value)

  defp with_bless(value, fun) do
    prior = System.get_env("MIX_GOLDEN_BLESS")
    on_exit(fn -> restore_env("MIX_GOLDEN_BLESS", prior) end)

    case value do
      nil -> System.delete_env("MIX_GOLDEN_BLESS")
      v -> System.put_env("MIX_GOLDEN_BLESS", v)
    end

    fun.()
  end

  defp with_dump(value, fun) do
    prior = System.get_env("MIX_GOLDEN_DUMP")
    on_exit(fn -> restore_env("MIX_GOLDEN_DUMP", prior) end)

    case value do
      nil -> System.delete_env("MIX_GOLDEN_DUMP")
      v -> System.put_env("MIX_GOLDEN_DUMP", v)
    end

    fun.()
  end

  describe "assert_deterministic!/1" do
    test "renders twice with deterministic: true and returns the byte-identical PDF" do
      pdf = Golden.assert_deterministic!(fixture_doc())

      assert is_binary(pdf)
      {:ok, again} = Rendro.render(fixture_doc(), deterministic: true)
      assert pdf == again
    end
  end

  describe "assert_or_bless/3 — missing ref (unblessed)" do
    test "hard-flunks with 'Missing golden ref' and the exact path, writing nothing" do
      base_dir = scratch_dir()
      pdf = Golden.assert_deterministic!(fixture_doc())
      ref_path = "#{base_dir}/invoice/text_wrap.sha256"

      with_bless(nil, fn ->
        error =
          assert_raise ExUnit.AssertionError, fn ->
            Golden.assert_or_bless({:invoice, :text_wrap}, pdf, base_dir: base_dir)
          end

        assert error.message =~ "Missing golden ref"
        assert error.message =~ ref_path
      end)

      refute File.exists?(ref_path)
    end
  end

  describe "assert_or_bless/3 — bless (MIX_GOLDEN_BLESS=true), un-gated" do
    test "writes lowercase-hex sha256 + newline, creating the dir, and returns :ok" do
      base_dir = scratch_dir()
      pdf = Golden.assert_deterministic!(fixture_doc())
      ref_path = "#{base_dir}/invoice/text_wrap.sha256"
      expected = Base.encode16(:crypto.hash(:sha256, pdf), case: :lower)

      with_bless("true", fn ->
        # No GITHUB_ACTIONS gate — byte hashes are cross-platform stable (D-04).
        assert :ok = Golden.assert_or_bless({:invoice, :text_wrap}, pdf, base_dir: base_dir)
      end)

      assert File.exists?(ref_path)
      assert File.read!(ref_path) == expected <> "\n"
    end
  end

  describe "assert_or_bless/3 — existing ref" do
    test "returns :ok when the stored hash matches" do
      base_dir = scratch_dir()
      pdf = Golden.assert_deterministic!(fixture_doc())
      hash = Base.encode16(:crypto.hash(:sha256, pdf), case: :lower)
      ref_path = "#{base_dir}/invoice/text_wrap.sha256"
      File.mkdir_p!(Path.dirname(ref_path))
      File.write!(ref_path, hash <> "\n")

      with_bless(nil, fn ->
        assert :ok = Golden.assert_or_bless({:invoice, :text_wrap}, pdf, base_dir: base_dir)
      end)
    end

    test "fails with 'Golden hash mismatch' and the DEFECT-not-refresh doctrine on mismatch" do
      base_dir = scratch_dir()
      pdf = Golden.assert_deterministic!(fixture_doc())
      ref_path = "#{base_dir}/invoice/text_wrap.sha256"
      File.mkdir_p!(Path.dirname(ref_path))
      File.write!(ref_path, String.duplicate("0", 64) <> "\n")

      with_bless(nil, fn ->
        error =
          assert_raise ExUnit.AssertionError, fn ->
            Golden.assert_or_bless({:invoice, :text_wrap}, pdf, base_dir: base_dir)
          end

        assert error.message =~ "Golden hash mismatch"
        assert error.message =~ "a hash change is a DEFECT, not a refresh"
      end)
    end
  end

  describe "assert_or_bless/3 — default base_dir" do
    test "defaults to priv/goldens without touching the real tree" do
      pdf = Golden.assert_deterministic!(fixture_doc())

      # Guaranteed-nonexistent pair: proves the default path is rooted at
      # priv/goldens via the (read-only) missing-ref flunk message, never
      # writing or blessing anything under the real committed tree.
      with_bless(nil, fn ->
        error =
          assert_raise ExUnit.AssertionError, fn ->
            Golden.assert_or_bless(
              {:__nonexistent_family__, :__nonexistent_dimension__},
              pdf
            )
          end

        assert error.message =~
                 "priv/goldens/__nonexistent_family__/__nonexistent_dimension__.sha256"
      end)

      refute File.exists?("priv/goldens/__nonexistent_family__/__nonexistent_dimension__.sha256")
    end
  end

  describe "assert_or_bless/3 — MIX_GOLDEN_DUMP escape hatch" do
    test "when set, dumps raw PDF bytes to <dir>/<family>_<dimension>.pdf, creating the dir" do
      base_dir = scratch_dir()
      dump_dir = scratch_dir()
      pdf = Golden.assert_deterministic!(fixture_doc())

      # Bless branch so the underlying call succeeds — dump is independent of it.
      dumped = Path.join(dump_dir, "invoice_text_wrap.pdf")

      with_bless("true", fn ->
        with_dump(dump_dir, fn ->
          assert :ok = Golden.assert_or_bless({:invoice, :text_wrap}, pdf, base_dir: base_dir)
        end)
      end)

      assert File.exists?(dumped)
      assert File.read!(dumped) == pdf
    end

    test "when unset, writes no dump file and creates no dump directory" do
      base_dir = scratch_dir()

      dump_dir =
        Path.join(System.tmp_dir!(), "rendro-golden-nodump-#{System.unique_integer([:positive])}")

      on_exit(fn -> File.rm_rf!(dump_dir) end)
      pdf = Golden.assert_deterministic!(fixture_doc())

      with_bless("true", fn ->
        with_dump(nil, fn ->
          assert :ok = Golden.assert_or_bless({:invoice, :text_wrap}, pdf, base_dir: base_dir)
        end)
      end)

      refute File.exists?(dump_dir)
    end

    test "dump never alters the assert outcome — a ref mismatch still fails while dumping" do
      base_dir = scratch_dir()
      dump_dir = scratch_dir()
      pdf = Golden.assert_deterministic!(fixture_doc())
      ref_path = "#{base_dir}/invoice/text_wrap.sha256"
      File.mkdir_p!(Path.dirname(ref_path))
      File.write!(ref_path, String.duplicate("0", 64) <> "\n")
      dumped = Path.join(dump_dir, "invoice_text_wrap.pdf")

      with_bless(nil, fn ->
        with_dump(dump_dir, fn ->
          assert_raise ExUnit.AssertionError, fn ->
            Golden.assert_or_bless({:invoice, :text_wrap}, pdf, base_dir: base_dir)
          end
        end)
      end)

      # The mismatch still failed AND the eyeball dump was still written.
      assert File.exists?(dumped)
      assert File.read!(dumped) == pdf
    end
  end
end
