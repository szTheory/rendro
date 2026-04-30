defmodule Rendro.TextTest do
  use ExUnit.Case, async: true

  alias Rendro.Text

  describe "struct construction" do
    test "creates with content and defaults" do
      text = %Text{content: "hello"}
      assert text.content == "hello"
      assert text.font == Text.default_font()
      assert text.size == 12
      assert text.color == {0, 0, 0}
    end

    test "creates with all fields using a logical font reference" do
      text = %Text{
        content: "styled",
        font: :heading,
        size: 24,
        color: {255, 0, 0}
      }

      assert text.content == "styled"
      assert text.font == :heading
      assert text.size == 24
      assert text.color == {255, 0, 0}
    end
  end

  describe "font normalization" do
    test "keeps logical font atoms unchanged" do
      assert Text.normalize_font(:body) == :body
    end

    test "normalizes the narrow Helvetica compatibility aliases" do
      assert Text.normalize_font("Helvetica") == "Helvetica"
      assert Text.normalize_font("helvetica") == "Helvetica"
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
