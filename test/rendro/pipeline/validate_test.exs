defmodule Rendro.Pipeline.ValidateTest do
  use ExUnit.Case, async: true

  alias Rendro.Pipeline.Validate
  alias Rendro.{Block, Document, FormField, Link, Page, Text}

  defp sample_document do
    doc = Document.new()
    doc = Document.register_font(doc, :helvetica, built_in: :helvetica)

    text = %Text{content: "Hello!", font: :helvetica, size: 12, color: {0, 0, 0}}
    block = %Block{content: text, x: 10, y: 20, width: 100, height: 20}
    page = %Page{blocks: [block], width: 500, height: 500}

    %{doc | pages: [page]}
  end

  describe "run/1" do
    test "returns {:ok, doc} unchanged for a well-formed 1-page render" do
      doc = sample_document()
      assert {:ok, ^doc} = Validate.run(doc)
    end

    test "bubbles up errors if validation fails" do
      doc = sample_document()
      # Corrupt the document to trigger rule failures
      bad_block = %Block{content: nil, x: "not a number", y: 20, width: 100, height: 20}
      bad_page = %Page{blocks: [bad_block], width: 500, height: 500}
      doc = %{doc | pages: [bad_page]}

      assert {:error,
              %Rendro.Error{
                stage: :validate,
                reason: :structural_corruption,
                details: %{errors: errors}
              }} = Validate.run(doc)

      assert :invalid_block_bounds in errors
      assert {:missing_required_key, :content} in errors
    end

    test "aggregates form semantic failures alongside other validation errors" do
      doc =
        %Document{
          pages: [
            %Page{
              width: 500,
              height: 500,
              blocks: [
                %Block{content: %FormField{name: "contact"}},
                %Block{
                  content: %FormField{
                    name: "contact_email",
                    type: :radio,
                    group: "contact",
                    export_value: "email"
                  }
                },
                %Block{
                  content: %FormField{
                    name: "contact_phone",
                    type: :radio,
                    group: "contact",
                    export_value: "email"
                  }
                }
              ]
            }
          ]
        }

      assert {:error,
              %Rendro.Error{
                stage: :validate,
                reason: :structural_corruption,
                details: %{errors: errors}
              }} = Validate.run(doc)

      assert {:duplicate_form_field_name, "contact"} in errors
      assert {:duplicate_radio_export_value, "contact", "email"} in errors
    end

    test "reports signature-specific validate errors for blocked attrs and zero-rect placeholders" do
      doc =
        %Document{
          pages: [
            %Page{
              width: 500,
              height: 500,
              blocks: [
                %Block{
                  content: %FormField{
                    name: "customer_signature",
                    type: :signature,
                    signature_rejections: [reason: "Approved"]
                  },
                  x: 10,
                  y: 20,
                  width: 0,
                  height: 48
                }
              ]
            }
          ]
        }

      assert {:error,
              %Rendro.Error{
                stage: :validate,
                reason: :structural_corruption,
                details: %{errors: errors}
              }} = Validate.run(doc)

      assert {:unsupported_signature_attr, :reason, "Approved"} in errors
      assert {:invalid_signature_placeholder_bounds, "customer_signature"} in errors
    end

    test "aggregates embedded-file semantic failures alongside other validation errors" do
      doc =
        %Document{
          embedded_file_registry: %Rendro.EmbeddedFileRegistry{
            files: %{
              invoice_csv: %{
                logical_name: :invoice_csv,
                source_kind: :binary,
                bytes: "a,b\n1,2\n",
                byte_size: 8,
                filename: "invoice.csv",
                mime_type: "text/csv"
              },
              backup_csv: %{
                logical_name: :backup_csv,
                source_kind: :binary,
                bytes: "x,y\n3,4\n",
                byte_size: 8,
                filename: "invoice.csv",
                mime_type: ""
              }
            }
          },
          pages: [
            %Page{
              width: 500,
              height: 500,
              blocks: [%Block{content: nil, x: "not a number", y: 20, width: 100, height: 20}]
            }
          ]
        }

      assert {:error,
              %Rendro.Error{
                stage: :validate,
                reason: :structural_corruption,
                details: %{errors: errors}
              }} = Validate.run(doc)

      assert :invalid_block_bounds in errors
      assert {:missing_required_key, :content} in errors
      assert {:duplicate_embedded_file_name, "invoice.csv"} in errors
      assert {:invalid_embedded_file_mime_type, ""} in errors
    end

    test "aggregates link semantic failures alongside other validation errors" do
      doc =
        %Document{
          pages: [
            %Page{
              width: 500,
              height: 500,
              blocks: [
                %Block{
                  content: %Link{
                    content: %Text{content: "Docs", font: "Helvetica", size: 12, color: {0, 0, 0}},
                    target: {:uri, "mailto:jon@example.com"}
                  },
                  x: 10,
                  y: 20,
                  width: 100,
                  height: 20
                },
                %Block{
                  content: %Link{
                    content: %FormField{name: "email"},
                    target: {:uri, "https://example.com"}
                  },
                  x: 10,
                  y: 50,
                  width: 100,
                  height: 20
                },
                %Block{content: nil, x: "not a number", y: 20, width: 100, height: 20}
              ]
            }
          ]
        }

      assert {:error,
              %Rendro.Error{
                stage: :validate,
                reason: :structural_corruption,
                details: %{errors: errors}
              }} = Validate.run(doc)

      assert :invalid_block_bounds in errors
      assert {:missing_required_key, :content} in errors
      assert {:unsupported_link_scheme, "mailto"} in errors
      assert {:unsupported_link_content, :form_field} in errors
    end

    test "stress test: traverses a deeply nested AST with acceptable performance" do
      doc = Document.new()
      doc = Document.register_font(doc, :helvetica, built_in: :helvetica)

      # Generate 10,000 pages, each with 10 blocks
      text = %Text{content: "P", font: :helvetica, size: 12, color: {0, 0, 0}}
      block = %Block{content: text, x: 10, y: 20, width: 50, height: 10}

      blocks = List.duplicate(block, 10)
      page = %Page{blocks: blocks, width: 500, height: 500}

      pages = List.duplicate(page, 10_000)
      doc = %{doc | pages: pages}

      {time_us, result} = :timer.tc(fn -> Validate.run(doc) end)

      assert {:ok, ^doc} = result
      # Stress test must be < 500ms for 100k nodes (O(N) single-pass)
      assert time_us < 500_000, "expected validation of 100k nodes to be <500ms; got #{time_us}us"
    end
  end
end
