defmodule Rendro.FontRegistryTest do
  use ExUnit.Case, async: true
  alias Rendro.FontRegistry

  describe "fallback chains" do
    test "register_embedded/4 and register/3 accept fallbacks: [:other_logical_name]" do
      registry = FontRegistry.new()

      registry =
        FontRegistry.register(registry, :primary_builtin,
          built_in: :helvetica,
          fallbacks: [:fallback_builtin]
        )

      assert {:ok, %{fallbacks: [:fallback_builtin]}} =
               FontRegistry.fetch(registry, :primary_builtin)

      # Using a mock binary for embedded
      mock_binary = <<0, 1, 2, 3>>

      registry =
        FontRegistry.register_embedded(registry, :primary_embedded, {:binary, mock_binary},
          fallbacks: [:fallback_embedded]
        )

      assert {:ok, %{fallbacks: [:fallback_embedded]}} =
               FontRegistry.fetch(registry, :primary_embedded)
    end

    test "preflight/1 verifies that all fallback logical names actually exist in the registry" do
      registry =
        FontRegistry.new()
        |> FontRegistry.register(:primary, built_in: :helvetica, fallbacks: [:missing_fallback])

      assert {:error, {:missing_fallback_target, :missing_fallback, _path}} =
               FontRegistry.preflight(registry)

      registry_valid =
        FontRegistry.new()
        |> FontRegistry.register(:fallback, built_in: :helvetica)
        |> FontRegistry.register(:primary, built_in: :helvetica, fallbacks: [:fallback])

      assert {:ok, _} = FontRegistry.preflight(registry_valid)
    end

    test "resolve_pdf_font_chain/3 returns {:ok, [Rendro.PDF.Font.t()]} including the primary font and its fallbacks" do
      registry =
        FontRegistry.new()
        |> FontRegistry.register(:fallback_two, built_in: :helvetica)
        |> FontRegistry.register(:fallback_one, built_in: :helvetica, fallbacks: [:fallback_two])
        |> FontRegistry.register(:primary, built_in: :helvetica, fallbacks: [:fallback_one])

      assert {:ok, chain} = FontRegistry.resolve_pdf_font_chain(registry, :primary, :default)

      assert length(chain) == 3
      assert [%Rendro.PDF.Font{}, %Rendro.PDF.Font{}, %Rendro.PDF.Font{}] = chain
      assert Enum.map(chain, & &1.logical_name) == [:primary, :fallback_one, :fallback_two]
    end

    test "resolve_pdf_font_chain/3 prevents infinite loops from fallback cycles" do
      registry =
        FontRegistry.new()
        |> FontRegistry.register(:cycle_two, built_in: :helvetica, fallbacks: [:cycle_one])
        |> FontRegistry.register(:cycle_one, built_in: :helvetica, fallbacks: [:cycle_two])

      assert {:error, {:fallback_cycle_detected, [:cycle_one, :cycle_two, :cycle_one]}} =
               FontRegistry.resolve_pdf_font_chain(registry, :cycle_one, :default)
    end
  end
end
