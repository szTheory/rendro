defmodule Rendro.PageTest do
  use ExUnit.Case, async: true

  alias Rendro.{Block, Page, PageTemplate, Region, Text}

  describe "struct construction" do
    test "creates with A4 defaults" do
      page = %Page{}
      assert page.blocks == []
      assert page.width == 595.28
      assert page.height == 841.89
      assert page.margin_top == 72
      assert page.margin_right == 72
      assert page.margin_bottom == 72
      assert page.margin_left == 72
    end

    test "creates with custom dimensions and margins" do
      page = %Page{
        width: 612,
        height: 792,
        margin_top: 36,
        margin_right: 36,
        margin_bottom: 36,
        margin_left: 36
      }

      assert page.width == 612
      assert page.height == 792
      assert page.margin_top == 36
    end

    test "creates with blocks" do
      block = %Block{content: %Text{content: "hello"}}
      page = %Page{blocks: [block]}
      assert length(page.blocks) == 1
    end

    test "rejects unknown keys" do
      assert_raise KeyError, fn ->
        struct!(Page, bogus: true)
      end
    end
  end

  describe "page template compatibility" do
    test "creates a default page template with named regions" do
      template = %PageTemplate{}

      assert template.width == 595.28
      assert template.height == 841.89
      assert template.margin_top == 72
      assert template.margin_right == 72
      assert template.margin_bottom == 72
      assert template.margin_left == 72
      assert Enum.map(template.regions, & &1.name) == [:header, :body, :footer]

      assert [%Region{role: :header}, %Region{role: :body}, %Region{role: :footer}] =
               template.regions
    end

    test "rejects unknown template keys" do
      assert_raise KeyError, fn ->
        struct!(PageTemplate, bogus: true)
      end
    end
  end
end
