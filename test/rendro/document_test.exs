defmodule Rendro.DocumentTest do
  use ExUnit.Case, async: true

  alias Rendro.{Document, Metadata, Page, PageTemplate, Section}

  describe "struct construction" do
    test "creates with defaults" do
      doc = %Document{}
      assert doc.pages == []
      assert doc.page_templates == []
      assert doc.page_template == nil
      assert doc.sections == []
      assert doc.metadata == %Metadata{}
      assert doc.options == %{}
    end

    test "creates with all fields" do
      page = %Page{}
      meta = %Metadata{title: "Test"}
      template = %PageTemplate{name: :invoice}
      section = %Section{name: :summary, region: :body}

      doc = %Document{
        pages: [page],
        page_templates: [template],
        page_template: :invoice,
        sections: [section],
        metadata: meta,
        options: %{deterministic: true}
      }

      assert doc.pages == [page]
      assert doc.page_templates == [template]
      assert doc.page_template == :invoice
      assert doc.sections == [section]
      assert doc.metadata.title == "Test"
      assert doc.options.deterministic == true
    end

    test "rejects unknown keys" do
      assert_raise KeyError, fn ->
        struct!(Document, bogus: true)
      end
    end
  end
end
