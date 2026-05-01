defmodule Rendro.DocumentTest do
  use ExUnit.Case, async: true

  alias Rendro.{Document, FontRegistry, Metadata, Page, PageTemplate, Section}
  alias Rendro.FontRegistry.EmbeddedFontFamilyError

  describe "struct construction" do
    test "creates with defaults" do
      doc = %Document{}
      assert doc.pages == []
      assert doc.page_templates == []
      assert doc.page_template == nil
      assert doc.sections == []
      assert doc.diagnostics == []
      assert doc.font_registry == FontRegistry.new()
      assert doc.default_font == :default
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
        diagnostics: [%{level: :info, type: :table_split}],
        font_registry: Document.new().font_registry,
        default_font: :default,
        metadata: meta,
        options: %{deterministic: true}
      }

      assert doc.pages == [page]
      assert doc.page_templates == [template]
      assert doc.page_template == :invoice
      assert doc.sections == [section]
      assert doc.diagnostics == [%{level: :info, type: :table_split}]
      assert doc.font_registry.default_font == :default
      assert doc.default_font == :default
      assert doc.metadata.title == "Test"
      assert doc.options.deterministic == true
    end

    test "rejects unknown keys" do
      assert_raise KeyError, fn ->
        struct!(Document, bogus: true)
      end
    end
  end

  describe "pipeline builder API" do
    test "new/0 returns an empty Document struct" do
      doc = Document.new()
      assert %Document{} = doc
      assert doc.pages == []
      assert doc.content == []
      assert doc.page_templates == []
      assert doc.page_template == nil
      assert doc.sections == []
      assert doc.diagnostics == []
      assert doc.font_registry == FontRegistry.new()
      assert doc.default_font == :default
      assert doc.metadata == %Metadata{}
      assert doc.options == %{}
    end

    test "new/1 accepts keyword opts and returns populated Document struct" do
      meta = %Metadata{title: "Seeded"}
      doc = Document.new(metadata: meta)
      assert %Document{} = doc
      assert doc.metadata.title == "Seeded"
    end

    test "put_metadata/2 updates the metadata struct" do
      meta = %Metadata{title: "Invoice", author: "Acme Corp"}
      doc = Document.new() |> Document.put_metadata(meta)
      assert %Document{} = doc
      assert doc.metadata.title == "Invoice"
      assert doc.metadata.author == "Acme Corp"
    end

    test "add_template/2 appends to page_templates" do
      template_a = %PageTemplate{name: :invoice}
      template_b = %PageTemplate{name: :summary}

      doc =
        Document.new()
        |> Document.add_template(template_a)
        |> Document.add_template(template_b)

      assert length(doc.page_templates) == 2
      assert Enum.at(doc.page_templates, 0) == template_a
      assert Enum.at(doc.page_templates, 1) == template_b
    end

    test "set_template/2 sets the active page_template name" do
      doc = Document.new() |> Document.set_template(:invoice)
      assert doc.page_template == :invoice
    end

    test "add_section/2 appends to sections list" do
      section_a = %Section{name: :header, region: :header}
      section_b = %Section{name: :body, region: :body}

      doc =
        Document.new()
        |> Document.add_section(section_a)
        |> Document.add_section(section_b)

      assert length(doc.sections) == 2
      assert Enum.at(doc.sections, 0) == section_a
      assert Enum.at(doc.sections, 1) == section_b
    end

    test "put_options/2 merges options map" do
      doc =
        Document.new()
        |> Document.put_options(%{deterministic: true})
        |> Document.put_options(%{compress: false})

      assert doc.options.deterministic == true
      assert doc.options.compress == false
    end

    test "builder functions compose via pipe" do
      template = %PageTemplate{name: :report}
      section = %Section{name: :content, region: :body}
      meta = %Metadata{title: "Annual Report"}

      doc =
        Document.new()
        |> Document.put_metadata(meta)
        |> Document.add_template(template)
        |> Document.set_template(:report)
        |> Document.add_section(section)
        |> Document.put_options(%{deterministic: true})

      assert %Document{} = doc
      assert doc.metadata.title == "Annual Report"
      assert doc.page_templates == [template]
      assert doc.page_template == :report
      assert doc.sections == [section]
      assert doc.options.deterministic == true
    end

    test "documents keep a built-in Helvetica-compatible default path" do
      doc = Document.new()

      assert doc.default_font == :default
      assert {:ok, %{source: :built_in, family: :helvetica}} =
               FontRegistry.fetch(doc.font_registry, :default)
    end

    test "register_font/3 adds a second logical font without mutating the source document" do
      doc = Document.new()
      updated_doc = Document.register_font(doc, :heading, built_in: :helvetica)

      assert {:ok, %{source: :built_in, family: :helvetica}} =
               FontRegistry.fetch(updated_doc.font_registry, :heading)

      assert :error = FontRegistry.fetch(doc.font_registry, :heading)
      assert doc.default_font == :default
      assert updated_doc.default_font == :default
    end

    test "put_default_font/2 switches the document default to a registered logical font" do
      doc =
        Document.new()
        |> Document.register_font(:body, built_in: "Helvetica")
        |> Document.put_default_font(:body)

      assert doc.default_font == :body
      assert doc.font_registry.default_font == :body
      assert {:ok, %{source: :built_in, family: :helvetica}} =
               FontRegistry.fetch(doc.font_registry, :body)
    end

    test "register_embedded_font/3 eagerly normalizes path input into owned bytes" do
      path = Path.join(System.tmp_dir!(), "rendro-embedded-path-#{System.unique_integer([:positive])}.ttf")
      bytes = <<0, 1, 2, 3, 4, 5, 6, 7>>
      File.write!(path, bytes)

      doc = Document.new() |> Document.register_embedded_font(:brand, {:path, path})

      assert {:ok,
              %{
                source: :embedded,
                source_kind: :path,
                variant: :regular,
                source_data: %{status: :ok, kind: :path, bytes: ^bytes, byte_size: 8}
              }} = FontRegistry.fetch(doc.font_registry, :brand)

      refute get_in(doc.font_registry.fonts[:brand], [:source_data, :path])
      File.rm!(path)
    end

    test "register_embedded_font/3 stores binary input as owned pure data" do
      bytes = <<10, 20, 30, 40>>
      doc = Document.new() |> Document.register_embedded_font(:brand, {:binary, bytes})

      assert {:ok,
              %{
                source: :embedded,
                source_kind: :binary,
                source_data: %{status: :ok, kind: :binary, bytes: ^bytes, byte_size: 4}
              }} = FontRegistry.fetch(doc.font_registry, :brand)
    end

    test "register_embedded_font_family/3 fails before partial registration with typed details" do
      bytes = <<1, 2, 3>>

      error =
        assert_raise EmbeddedFontFamilyError, fn ->
          Document.new()
          |> Document.register_embedded_font_family(:brand, %{
            regular: {:binary, bytes},
            bold: {:path, "/tmp/brand-bold.ttf"}
          })
        end

      assert error.family_name == :brand
      assert error.reason == :incomplete_embedded_family
      assert error.missing_variants == [:italic, :bold_italic]
      assert error.provided_kinds == %{regular: :binary, bold: :path}
    end
  end
end
