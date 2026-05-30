defmodule Rendro.DocsContract.PublicApiContractTest do
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

  # Assertion 1 — Schema validation (D-01)
  describe "schema validation (D-01)" do
    test "on-disk manifest validates against priv/schemas/public_api.schema.json" do
      manifest = Loader.load!()
      assert Validator.validate(manifest) == :ok
    end
  end

  # Assertion 2 — Manifest surface equality with two-list drift diff (D-01/D-03)
  describe "manifest surface equality (D-01/D-03)" do
    test "freshly-generated manifest is byte-identical to the checked-in priv/public_api.json" do
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

      # Encode with the same deterministic encoder as the generator.
      # The <> "\n" is mandatory: the generator appends it on write; omitting causes
      # a one-byte mismatch.
      fresh_json = Mix.Tasks.Rendro.Api.Gen.encode_manifest(fresh_manifest) <> "\n"

      # Read the checked-in file
      checked_in = File.read!("priv/public_api.json")

      # Two-list drift diff for human-readable error UX (D-03)
      on_disk_manifest = JSON.decode!(checked_in)
      fresh_keys = Map.keys(fresh_manifest["modules"]) |> MapSet.new()
      on_disk_keys = Map.keys(on_disk_manifest["modules"]) |> MapSet.new()

      in_code_not_manifested = MapSet.difference(fresh_keys, on_disk_keys) |> Enum.sort()
      manifested_not_in_code = MapSet.difference(on_disk_keys, fresh_keys) |> Enum.sort()

      if in_code_not_manifested != [] or manifested_not_in_code != [] do
        flunk("""
        Public API surface has drifted from priv/public_api.json.

        In code but NOT in manifest (newly public — should they be?):
        #{Enum.map_join(in_code_not_manifested, "\n", fn m -> "  + #{m}" end)}

        In manifest but NOT in code (removed or hidden — intentional?):
        #{Enum.map_join(manifested_not_in_code, "\n", fn m -> "  - #{m}" end)}

        If this change is intentional, regenerate the manifest:
          mix rendro.api.gen
        Then commit the updated priv/public_api.json.
        """)
      end

      assert fresh_json == checked_in,
             """
             The freshly-generated manifest does not byte-match priv/public_api.json.
             Per-module function drift detected (a function was added or removed within
             an already-manifested module). Run: mix rendro.api.gen
             and commit the updated priv/public_api.json.
             """
    end
  end

  # Assertion 3 — Known internals are :hidden (D-05)
  describe "known internal modules are :hidden (D-05)" do
    test "internal engine modules have @moduledoc false (:hidden) in Code.fetch_docs/1" do
      hidden_modules = [
        Rendro.PDF.CidFont,
        Rendro.PDF.FontSubsetter,
        Rendro.Text.Bidi,
        Rendro.Text.Shaper,
        Rendro.Format,
        Rendro.Audit
      ]

      for module <- hidden_modules do
        # Guard against a false pass: a missing/uncompiled module must FAIL this
        # assertion, not be silently treated as :hidden. Otherwise renaming or
        # deleting a tracked internal would pass the very check meant to catch it.
        assert Code.ensure_loaded?(module),
               "Expected internal module #{inspect(module)} to exist and be compiled, " <>
                 "but it could not be loaded — was it renamed or deleted? " <>
                 "The hidden-internals contract must track real modules."

        module_doc =
          case Code.fetch_docs(module) do
            {:docs_v1, _, _, _, module_doc, _, _} ->
              module_doc

            {:error, reason} ->
              flunk(
                "Could not fetch docs for #{inspect(module)} (#{inspect(reason)}); " <>
                  "expected it to report :hidden via @moduledoc false."
              )
          end

        assert module_doc == :hidden,
               "Expected #{inspect(module)} to have @moduledoc false (:hidden), " <>
                 "but module_doc is: #{inspect(module_doc)}"
      end
    end

    test "known redact_* helpers have @doc false in Rendro.Sign and Rendro.Protect" do
      hidden_helpers = [
        {Rendro.Sign,
         [:redact_opts, :redact_prepare_opts, :redact_sign_opts, :redact_augment_opts]},
        {Rendro.Protect, [:redact_opts]}
      ]

      for {module, names} <- hidden_helpers do
        docs =
          case Code.fetch_docs(module) do
            {:docs_v1, _, _, _, _, _, docs} ->
              docs

            other ->
              flunk(
                "Could not fetch docs for #{inspect(module)} (got #{inspect(other)}); " <>
                  "expected its redact_* helpers to report doc: :hidden."
              )
          end

        for name <- names do
          matching_entries =
            Enum.filter(docs, fn
              {{:function, ^name, _arity}, _, _, _, _} -> true
              _ -> false
            end)

          assert matching_entries != [],
                 "Expected to find function #{name}/N in #{inspect(module)} docs but found none"

          for entry <- matching_entries do
            {{:function, fn_name, arity}, _anno, _sig, doc, _meta} = entry

            assert doc == :hidden,
                   "Expected #{inspect(module)}.#{fn_name}/#{arity} to have doc: :hidden, " <>
                     "but got: #{inspect(doc)}"
          end
        end
      end
    end
  end

  # Assertion 4 — Exactly one tier tag per module (D-06)
  describe "tier-tag exactly one per module (D-06)" do
    test "every public module has exactly one tier tag: :stable xor :adapter" do
      manifest = Loader.load!()

      violations =
        manifest["modules"]
        |> Enum.flat_map(fn {mod_key, _entry} ->
          case resolve_manifest_module(mod_key) do
            # A manifest key with no live module is reported cleanly by Assertion 2's
            # surface-equality drift diff; skip here to avoid confusing parallel crashes.
            :stale ->
              []

            {:ok, module} ->
              tags =
                case Code.fetch_docs(module) do
                  {:docs_v1, _, _, _, _, %{tags: tags}, _} -> tags
                  _ -> []
                end

              tier_tags = Enum.filter(tags, &(&1 in [:stable, :adapter]))

              cond do
                length(tier_tags) == 1 ->
                  []

                tier_tags == [] ->
                  ["#{mod_key}: no tier tag (expected exactly one: :stable or :adapter)"]

                true ->
                  [
                    "#{mod_key}: #{length(tier_tags)} tier tags #{inspect(tier_tags)} (expected exactly one)"
                  ]
              end
          end
        end)

      assert violations == [],
             "Tier-tag invariant violated:\n  " <> Enum.join(violations, "\n  ")
    end
  end

  # Assertion 5 — Stable-tier @spec coverage (D-04)
  # NOTE: This assertion intentionally starts RED because Rendro.Component has zero @spec
  # annotations on its 2 public functions (image/2 and render_component/2). Plan 02 backfills
  # those specs to make this assertion GREEN. Do NOT weaken this assertion to make it pass.
  describe "stable-tier @spec coverage (D-04)" do
    test "every stable-tier manifested function has a @spec — uses Code.Typespec.fetch_specs/1" do
      manifest = Loader.load!()

      unspecced =
        manifest["modules"]
        |> Enum.filter(fn {_key, entry} -> entry["tier"] == "stable" end)
        |> Enum.flat_map(fn {mod_key, entry} ->
          case resolve_manifest_module(mod_key) do
            # Stale key → reported by Assertion 2; skip to avoid confusing parallel crashes.
            :stale ->
              []

            {:ok, module} ->
              specced =
                case Code.Typespec.fetch_specs(module) do
                  {:ok, specs} ->
                    Enum.map(specs, fn {{name, arity}, _} -> "#{name}/#{arity}" end)

                  :error ->
                    []
                end

              entry["functions"]
              |> Enum.reject(fn fn_str -> fn_str in specced end)
              |> Enum.map(fn fn_str -> "#{mod_key}.#{fn_str}" end)
          end
        end)

      assert unspecced == [],
             "Stable-tier functions missing @spec:\n  " <> Enum.join(unspecced, "\n  ")
    end
  end

  # Resolves a manifest module key (e.g. "Elixir.Rendro.Table") to its atom.
  # A stale key (module renamed/deleted) returns :stale rather than crashing with
  # ArgumentError — the surface-equality assertion (Assertion 2) is the authoritative
  # reporter for that drift, so degrading cleanly here keeps failure output readable.
  defp resolve_manifest_module(mod_key) do
    {:ok, String.to_existing_atom(mod_key)}
  rescue
    ArgumentError -> :stale
  end
end
