defmodule Rendro.ComponentTest do
  use ExUnit.Case, async: true
  alias Rendro.Component
  alias Rendro.Image
  alias Rendro.Block

  describe "image/2" do
    test "returns a Block containing an Image with width constraint" do
      assert %Block{
               content: %Image{logical_name: :logo},
               width: 100
             } = Component.image(:logo, width: 100)
    end

    test "returns a Block containing an Image with height constraint" do
      assert %Block{
               content: %Image{logical_name: :logo},
               height: 50
             } = Component.image(:logo, height: 50)
    end

    test "returns a Block containing an Image with fit constraint" do
      assert %Block{
               content: %Image{logical_name: :logo, fit: {100, 100}}
             } = Component.image(:logo, fit: {100, 100})
    end

    test "raises ArgumentError when missing required constraints" do
      assert_raise ArgumentError, fn ->
        Component.image(:logo, [])
      end
    end
  end
end
