defmodule Rendro.BlockTest do
  use ExUnit.Case, async: true

  alias Rendro.{Block, Text}

  describe "struct construction" do
    test "creates with content and defaults" do
      block = %Block{content: %Text{content: "hello"}}
      assert block.x == 0
      assert block.y == 0
      assert block.width == nil
      assert block.height == nil
    end

    test "creates with all fields" do
      text = %Text{content: "hello"}

      block = %Block{
        content: text,
        x: 100,
        y: 200,
        width: 300,
        height: 50
      }

      assert block.content == text
      assert block.x == 100
      assert block.y == 200
      assert block.width == 300
      assert block.height == 50
    end

    test "accepts non-Text content for extensibility" do
      block = %Block{content: {:image, "logo.png"}}
      assert block.content == {:image, "logo.png"}
    end
  end

  describe "@enforce_keys" do
    test "raises without content" do
      assert_raise ArgumentError, ~r/the following keys must also be given/, fn ->
        struct!(Block, [])
      end
    end
  end
end
