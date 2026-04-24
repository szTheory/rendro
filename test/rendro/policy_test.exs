defmodule Rendro.PolicyTest do
  use ExUnit.Case, async: true

  test "enforces max_pages policy" do
    content = for i <- 1..50, do: Rendro.block(Rendro.text("Line #{i}"))
    doc = Rendro.flow(content)

    # Normally 50 lines is 2 pages. Let's limit to 1.
    doc = put_in(doc.options[:policies], max_pages: 1)

    assert {:error, %Rendro.Error{reason: :max_pages_exceeded}} = Rendro.render(doc)
  end

  test "enforces max_bytes policy" do
    doc = Rendro.flow([Rendro.block(Rendro.text("Hello"))])

    # A tiny PDF is ~500 bytes. Let's limit to 100.
    doc = put_in(doc.options[:policies], max_bytes: 100)

    assert {:error, %Rendro.Error{reason: :max_bytes_exceeded}} = Rendro.render(doc)
  end

  test "enforces timeout policy" do
    # Normally this would be fast, but we set a 0 timeout.
    # To make it more likely to time out even if fast, we can add more content.
    content = for i <- 1..200, do: Rendro.block(Rendro.text("Line #{i}"))
    doc = Rendro.flow(content)
    doc = put_in(doc.options[:policies], timeout: 0)

    assert {:error, %Rendro.Error{reason: :timeout}} = Rendro.render(doc)
  end

end
