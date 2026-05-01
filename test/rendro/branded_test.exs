defmodule Rendro.BrandedTest do
  use ExUnit.Case, async: true

  describe "font_path/0" do
    test "returns a binary path that exists on disk" do
      path = Rendro.Branded.font_path()
      assert is_binary(path)
      assert File.exists?(path)
      assert path =~ "priv/branded/fonts/B612-Regular.ttf"
    end
  end

  describe "logo_path/0" do
    test "returns a binary path that exists on disk" do
      path = Rendro.Branded.logo_path()
      assert is_binary(path)
      assert File.exists?(path)
      assert path =~ "priv/branded/images/rendro-logo.png"
    end
  end
end
