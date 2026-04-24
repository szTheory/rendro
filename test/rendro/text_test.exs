defmodule Rendro.TextTest do
  use ExUnit.Case, async: true

  alias Rendro.Text

  describe "struct construction" do
    test "creates with content and defaults" do
      text = %Text{content: "hello"}
      assert text.content == "hello"
      assert text.font == "Helvetica"
      assert text.size == 12
      assert text.color == {0, 0, 0}
    end

    test "creates with all fields" do
      text = %Text{
        content: "styled",
        font: "Courier",
        size: 24,
        color: {255, 0, 0}
      }

      assert text.content == "styled"
      assert text.font == "Courier"
      assert text.size == 24
      assert text.color == {255, 0, 0}
    end
  end

  describe "@enforce_keys" do
    test "raises without content" do
      assert_raise ArgumentError, ~r/the following keys must also be given/, fn ->
        struct!(Text, [])
      end
    end
  end
end
