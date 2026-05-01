defmodule Rendro.AssetRegistryTest do
  use ExUnit.Case, async: true
  alias Rendro.AssetRegistry

  @png_bytes Base.decode64!("iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVQIW2NkYGD4z8DAwMgAI0AMADjKAu09+3WTAAAAAElFTkSuQmCC")

  describe "new/0" do
    test "returns empty registry" do
      assert %AssetRegistry{assets: %{}} = AssetRegistry.new()
    end
  end

  describe "register_image/3" do
    test "stores valid image from binary with extracted dimensions" do
      registry = AssetRegistry.new()
      
      registry = AssetRegistry.register_image(registry, :my_logo, {:binary, @png_bytes})
      
      assert {:ok, %{width: 2, height: 2, mime: "image/png", binary: @png_bytes}} = 
               AssetRegistry.fetch(registry, :my_logo)
    end

    test "stores valid image from path with extracted dimensions" do
      path = Path.join(System.tmp_dir!(), "test_logo.png")
      File.write!(path, @png_bytes)
      
      registry = AssetRegistry.new()
      registry = AssetRegistry.register_image(registry, :path_logo, {:path, path})
      
      assert {:ok, %{width: 2, height: 2, mime: "image/png", binary: @png_bytes}} = 
               AssetRegistry.fetch(registry, :path_logo)
               
      File.rm!(path)
    end

    test "raises InvalidAssetError if image format is unsupported" do
      registry = AssetRegistry.new()
      
      assert_raise AssetRegistry.InvalidAssetError, fn ->
        AssetRegistry.register_image(registry, :bad_logo, {:binary, <<"invalid">>})
      end
    end
  end
end
