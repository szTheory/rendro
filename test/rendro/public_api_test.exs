defmodule Rendro.PublicApiTest do
  use ExUnit.Case, async: false

  alias Rendro.PublicApi

  describe "tier_of/1" do
    test "returns :stable for Rendro (tagged [:stable] in plan 02)" do
      assert PublicApi.tier_of(Rendro) == :stable
    end

    test "returns :adapter for Rendro.Recipes.Invoice (tagged [:adapter] in plan 02)" do
      assert PublicApi.tier_of(Rendro.Recipes.Invoice) == :adapter
    end

    test "returns :untagged for Rendro.PDF.CidFont (@moduledoc false, not tagged)" do
      assert PublicApi.tier_of(Rendro.PDF.CidFont) == :untagged
    end
  end

  describe "public_functions/1" do
    test "returns a sorted list of public function strings for Rendro.Error" do
      functions = PublicApi.public_functions(Rendro.Error)
      assert is_list(functions)
      assert length(functions) > 0
      # All entries should be in "name/arity" format
      assert Enum.all?(functions, fn f -> String.contains?(f, "/") end)
      # List must be sorted
      assert functions == Enum.sort(functions)
      # from_stage/2 and from_stage/3 have defaults; to_string/1 is public
      assert "from_stage/3" in functions or "from_stage/2" in functions or "to_string/1" in functions
    end
  end

  describe "public_types/1" do
    test "returns a sorted list of type strings for Rendro.Document" do
      types = PublicApi.public_types(Rendro.Document)
      assert is_list(types)
      assert length(types) > 0
      # All entries should be in "name/arity" format
      assert Enum.all?(types, fn t -> String.contains?(t, "/") end)
      # List must be sorted
      assert types == Enum.sort(types)
      # t/0 is a documented public type in Rendro.Document
      assert "t/0" in types
    end
  end

  describe "build_manifest/1" do
    test "returns a map with top-level 'modules' key" do
      manifest = PublicApi.build_manifest([Rendro, Rendro.Document])
      assert is_map(manifest)
      assert Map.has_key?(manifest, "modules")
    end

    test "module entries use Elixir.ModName string keys" do
      manifest = PublicApi.build_manifest([Rendro, Rendro.Document])
      modules = manifest["modules"]
      assert Map.has_key?(modules, "Elixir.Rendro")
      assert Map.has_key?(modules, "Elixir.Rendro.Document")
    end

    test "each module entry has 'tier', 'functions', 'types' keys" do
      manifest = PublicApi.build_manifest([Rendro])
      entry = manifest["modules"]["Elixir.Rendro"]
      assert Map.has_key?(entry, "tier")
      assert Map.has_key?(entry, "functions")
      assert Map.has_key?(entry, "types")
    end

    test "all 'functions' and 'types' lists in build_manifest output are sorted" do
      manifest = PublicApi.build_manifest([Rendro, Rendro.Document])
      for {_mod, entry} <- manifest["modules"] do
        assert entry["functions"] == Enum.sort(entry["functions"])
        assert entry["types"] == Enum.sort(entry["types"])
      end
    end

    test "build_manifest output has no 'schema_version' key at the top level (D-17)" do
      manifest = PublicApi.build_manifest([Rendro])
      refute Map.has_key?(manifest, "schema_version")
    end
  end

  describe "recompile_conditional_adapters/0" do
    test "returns :ok without error" do
      assert PublicApi.recompile_conditional_adapters() == :ok
    end

    test "after recompile, Rendro.Adapters.Phoenix has :adapter tier (not :untagged)" do
      PublicApi.recompile_conditional_adapters()
      assert PublicApi.tier_of(Rendro.Adapters.Phoenix) == :adapter
    end

    test "after recompile, Rendro.Adapters.Threadline module is loaded in memory" do
      # Threadline is available as a test stub, so recompile ensures the adapter is defined
      PublicApi.recompile_conditional_adapters()
      # The module should be loaded in memory (Code.ensure_loaded? checks in-memory modules too)
      assert Code.ensure_loaded?(Rendro.Adapters.Threadline) == true
    end
  end

  describe "full-surface sweep" do
    @tag :sweep
    test "full-surface sweep: every :rendro application module is hidden or tagged" do
      # Ensure conditional adapter modules are compiled and available
      PublicApi.recompile_conditional_adapters()

      # Get the ground truth: all modules compiled into the :rendro OTP application
      {:ok, all_modules} = :application.get_key(:rendro, :modules)

      # For each module, check: hidden OR tagged [:stable | :adapter]
      untagged_visible =
        Enum.filter(all_modules, fn module ->
          module_doc =
            case Code.fetch_docs(module) do
              {:docs_v1, _, _, _, module_doc, _, _} -> module_doc
              {:error, _} -> :hidden
            end

          # Only flag modules that are visible (not :hidden) AND untagged
          module_doc != :hidden and PublicApi.tier_of(module) == :untagged
        end)

      assert untagged_visible == [],
             "Found #{length(untagged_visible)} visible-but-untagged modules. " <>
               "Each must be tagged @moduledoc tags: [:stable] or [:adapter], " <>
               "or hidden with @moduledoc false. Offending modules:\n" <>
               Enum.map_join(untagged_visible, "\n", fn m -> "  #{inspect(m)}" end)
    end
  end
end
