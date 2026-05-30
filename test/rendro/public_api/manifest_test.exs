defmodule Rendro.PublicApi.ManifestTest do
  use ExUnit.Case, async: false

  alias Rendro.PublicApi
  alias Rendro.PublicApi.Loader
  alias Rendro.PublicApi.Validator

  setup_all do
    # Ensure conditional adapters are compiled and available for all tests.
    # This mirrors what mix rendro.api.gen does before introspecting.
    PublicApi.recompile_conditional_adapters()
    :ok
  end

  # Test 1 — Schema validation
  describe "schema validation" do
    test "loaded manifest validates against priv/schemas/public_api.schema.json" do
      manifest = Loader.load!()
      assert Validator.validate(manifest) == :ok
    end
  end

  # Test 2 — Hidden module exclusion
  describe "hidden module exclusion" do
    test "internal engine modules are absent from the manifest" do
      manifest = Loader.load!()
      module_keys = Map.keys(manifest["modules"])

      hidden_modules = [
        "Elixir.Rendro.PDF.CidFont",
        "Elixir.Rendro.PDF.FontSubsetter",
        "Elixir.Rendro.Text.Bidi",
        "Elixir.Rendro.Text.Shaper",
        "Elixir.Rendro.Format",
        "Elixir.Rendro.Audit"
      ]

      for mod_key <- hidden_modules do
        refute mod_key in module_keys,
               "#{mod_key} should be hidden from the manifest but was found"
      end
    end
  end

  # Test 3 — Metadata visible
  describe "Rendro.Metadata visibility" do
    test "Rendro.Metadata is present in the manifest with tier stable" do
      manifest = Loader.load!()

      assert Map.has_key?(manifest["modules"], "Elixir.Rendro.Metadata"),
             "Elixir.Rendro.Metadata should be present in the manifest"

      assert manifest["modules"]["Elixir.Rendro.Metadata"]["tier"] == "stable"
    end
  end

  # Test 4 — Tier coverage
  describe "tier coverage" do
    test "every module entry has tier stable or adapter — no untagged entries" do
      manifest = Loader.load!()

      untagged =
        manifest["modules"]
        |> Enum.filter(fn {_key, entry} ->
          entry["tier"] not in ["stable", "adapter"]
        end)
        |> Enum.map(fn {key, entry} -> "#{key} (tier=#{entry["tier"]})" end)

      assert untagged == [],
             "Found modules with invalid tier in manifest:\n  #{Enum.join(untagged, "\n  ")}"
    end
  end

  # Test 5 — Idempotency + byte-equality (D-15 drift treadmill guard)
  describe "idempotency and byte-equality (D-15)" do
    test "freshly-generated manifest is byte-identical to the checked-in priv/public_api.json" do
      # Recompile adapters so conditional modules are available if deps are present
      PublicApi.recompile_conditional_adapters()

      # Use the same module list as the generator (filtered to modules with BEAM docs).
      # Code.compile_file produces in-memory modules without BEAM files; Code.fetch_docs
      # requires a BEAM file on disk. We filter to only modules with proper BEAM docs to
      # match the generator's exact behavior.
      loaded_modules =
        Mix.Tasks.Rendro.Api.Gen.public_modules()
        |> Enum.filter(fn mod ->
          Code.ensure_loaded?(mod) and
            match?({:docs_v1, _, _, _, _, _, _}, Code.fetch_docs(mod))
        end)

      # Build fresh manifest using the same code path as mix rendro.api.gen
      fresh_manifest = PublicApi.build_manifest(loaded_modules)

      # Encode with the same deterministic encoder as the generator
      fresh_json = Mix.Tasks.Rendro.Api.Gen.encode_manifest(fresh_manifest) <> "\n"

      # Read the checked-in file
      checked_in = File.read!("priv/public_api.json")

      assert fresh_json == checked_in,
             """
             The freshly-generated manifest does not byte-match priv/public_api.json.
             This means the manifest is out of date. Run: mix rendro.api.gen
             and commit the result (D-15 drift treadmill guard).
             """
    end
  end

  # Test 6 — Conditional adapter presence
  describe "conditional adapter tier" do
    test "Rendro.Adapters.Phoenix is loaded and has adapter tier" do
      # Phoenix is always available in test/dev (listed in deps)
      assert Code.ensure_loaded?(Rendro.Adapters.Phoenix),
             "Rendro.Adapters.Phoenix should be loaded"

      assert PublicApi.tier_of(Rendro.Adapters.Phoenix) == :adapter
    end

    test "conditional adapters in registry have adapter tier when BEAM is available" do
      # Threadline, Mailglass, Accrue are conditional — only assert tier when their BEAM
      # is available on disk. Code.compile_file produces in-memory modules; Code.fetch_docs
      # requires a BEAM file, so in-memory-only compilation yields :untagged. Only modules
      # whose real optional dep is present (not a stub) will have BEAM on disk.
      conditional = [
        Rendro.Adapters.Threadline,
        Rendro.Adapters.Mailglass,
        Rendro.Adapters.Accrue
      ]

      for mod <- conditional,
          Code.ensure_loaded?(mod),
          match?({:docs_v1, _, _, _, _, _, _}, Code.fetch_docs(mod)) do
        assert PublicApi.tier_of(mod) == :adapter,
               "#{inspect(mod)} has BEAM docs but does not have :adapter tier"
      end
    end
  end

  # Test 7 — redact helpers hidden
  describe "redact helpers hidden from public docs" do
    test "redact_opts/1, redact_prepare_opts/1, redact_sign_opts/1, redact_augment_opts/1 have doc: :hidden in Rendro.Sign" do
      {:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(Rendro.Sign)

      hidden_targets = [
        :redact_opts,
        :redact_prepare_opts,
        :redact_sign_opts,
        :redact_augment_opts
      ]

      for name <- hidden_targets do
        matching_entries =
          Enum.filter(docs, fn
            {{:function, ^name, _arity}, _, _, _, _} -> true
            _ -> false
          end)

        assert matching_entries != [],
               "Expected to find function #{name}/N in Rendro.Sign docs but found none"

        for entry <- matching_entries do
          {{:function, fn_name, arity}, _anno, _sig, doc, _meta} = entry

          assert doc == :hidden,
                 "Expected #{fn_name}/#{arity} in Rendro.Sign to have doc: :hidden, " <>
                   "but got: #{inspect(doc)}"
        end
      end
    end
  end
end
