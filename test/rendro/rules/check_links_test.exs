defmodule Rendro.Rules.CheckLinksTest do
  use ExUnit.Case, async: true

  alias Rendro.{Block, Document, FormField, Link, Page, Text}
  alias Rendro.Pipeline.Validate
  alias Rendro.Rules.CheckLinks

  describe "check/2" do
    test "accepts absolute http and https link targets unchanged" do
      uri_doc =
        link_document(%Link{
          content: %Text{content: "Guide"},
          target: {:uri, "https://example.com/guide?ref=docs"}
        })

      page_doc =
        %Document{
          pages: [
            %Page{
              width: 500,
              height: 500,
              blocks: [link_block(%Link{content: %Text{content: "One"}, target: {:page, 2}})]
            },
            %Page{width: 500, height: 500, blocks: []}
          ]
        }

      assert :ok =
               CheckLinks.check(
                 uri_doc.pages |> hd() |> Map.fetch!(:blocks) |> hd() |> Map.fetch!(:content),
                 uri_doc
               )

      assert :ok =
               CheckLinks.check(
                 page_doc.pages |> hd() |> Map.fetch!(:blocks) |> hd() |> Map.fetch!(:content),
                 page_doc
               )
    end

    test "rejects malformed relative hostless and unsupported-scheme URIs with typed tuples" do
      malformed = %Link{content: %Text{content: "Broken"}, target: {:uri, "https://exa mple.com"}}
      relative = %Link{content: %Text{content: "Relative"}, target: {:uri, "/docs"}}
      hostless = %Link{content: %Text{content: "Hostless"}, target: {:uri, "https:///docs"}}
      mailto = %Link{content: %Text{content: "Mail"}, target: {:uri, "mailto:jon@example.com"}}

      assert {:error, {:invalid_link_uri, "https://exa mple.com"}} =
               CheckLinks.check(malformed, %Document{})

      assert {:error, {:invalid_link_uri, "/docs"}} =
               CheckLinks.check(relative, %Document{})

      assert {:error, {:invalid_link_uri, "https:///docs"}} =
               CheckLinks.check(hostless, %Document{})

      assert {:error, {:unsupported_link_scheme, "mailto"}} =
               CheckLinks.check(mailto, %Document{})
    end

    test "rejects out-of-range page destinations" do
      doc =
        %Document{
          pages: [
            %Page{
              width: 500,
              height: 500,
              blocks: [link_block(%Link{content: %Text{content: "Jump"}, target: {:page, 3}})]
            },
            %Page{width: 500, height: 500, blocks: []}
          ]
        }

      assert {:error, {:invalid_link_page, 3}} =
               CheckLinks.check(
                 doc.pages |> hd() |> Map.fetch!(:blocks) |> hd() |> Map.fetch!(:content),
                 doc
               )
    end

    test "rejects links wrapping form fields" do
      link = %Link{content: %FormField{name: "email"}, target: {:uri, "https://example.com"}}

      assert {:error, {:unsupported_link_content, :form_field}} =
               CheckLinks.check(link, %Document{})
    end
  end

  describe "Validate.run/1" do
    test "aggregates typed link tuples in the validate-stage error envelope" do
      doc =
        %Document{
          pages: [
            %Page{
              width: 500,
              height: 500,
              blocks: [
                link_block(%Link{
                  content: %Text{content: "Mail"},
                  target: {:uri, "mailto:jon@example.com"}
                }),
                link_block(%Link{content: %Text{content: "Jump"}, target: {:page, 4}}),
                link_block(%Link{
                  content: %FormField{name: "email"},
                  target: {:uri, "https://example.com"}
                })
              ]
            },
            %Page{width: 500, height: 500, blocks: []}
          ]
        }

      assert {:error,
              %Rendro.Error{
                stage: :validate,
                reason: :structural_corruption,
                details: %{errors: errors}
              }} = Validate.run(doc)

      assert {:unsupported_link_scheme, "mailto"} in errors
      assert {:invalid_link_page, 4} in errors
      assert {:unsupported_link_content, :form_field} in errors
    end
  end

  defp link_document(%Link{} = link) do
    %Document{
      pages: [
        %Page{
          width: 500,
          height: 500,
          blocks: [link_block(link)]
        }
      ]
    }
  end

  defp link_block(%Link{} = link) do
    %Block{content: link, x: 10, y: 20, width: 100, height: 24}
  end
end
