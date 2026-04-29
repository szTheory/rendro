defmodule Rendro.Test.Generators do
  @moduledoc false

  use ExUnitProperties

  @renderable_max_text_length 20
  @renderable_max_text_size 24.0
  @renderable_block_max_x 150.0
  @renderable_block_max_y 500.0

  def text_gen do
    gen all(
          raw <- string(:printable, min_length: 1, max_length: 50),
          content = String.replace(raw, ~r/[()\\]/, ""),
          content != "",
          size <- float(min: 6.0, max: 72.0),
          r <- integer(0..255),
          g <- integer(0..255),
          b <- integer(0..255)
        ) do
      %Rendro.Text{content: content, font: "Helvetica", size: size, color: {r, g, b}}
    end
  end

  def block_gen do
    gen all(
          text <- text_gen(),
          x <- float(min: 0.0, max: 400.0),
          y <- float(min: 0.0, max: 700.0)
        ) do
      %Rendro.Block{content: text, x: x, y: y}
    end
  end

  def page_gen do
    gen all(
          blocks <- list_of(block_gen(), min_length: 0, max_length: 3),
          width <- member_of([595.28, 612.0]),
          height <- member_of([841.89, 792.0])
        ) do
      %Rendro.Page{blocks: blocks, width: width, height: height}
    end
  end

  def metadata_gen do
    gen all(
          title <- one_of([constant(nil), string(:printable, min_length: 1, max_length: 20)]),
          author <- one_of([constant(nil), string(:printable, min_length: 1, max_length: 20)])
        ) do
      %Rendro.Metadata{title: title, author: author}
    end
  end

  def document_gen do
    gen all(
          pages <- list_of(page_gen(), min_length: 1, max_length: 3),
          metadata <- metadata_gen()
        ) do
      %Rendro.Document{pages: pages, metadata: metadata, options: %{}}
    end
  end

  def renderable_document_gen do
    gen all(
          pages <- list_of(renderable_page_gen(), min_length: 1, max_length: 3),
          metadata <- metadata_gen()
        ) do
      %Rendro.Document{pages: pages, metadata: metadata, options: %{}}
    end
  end

  defp renderable_page_gen do
    gen all(
          blocks <- list_of(renderable_block_gen(), min_length: 0, max_length: 3),
          width <- member_of([595.28, 612.0]),
          height <- member_of([841.89, 792.0])
        ) do
      %Rendro.Page{blocks: blocks, width: width, height: height}
    end
  end

  defp renderable_block_gen do
    gen all(
          text <- renderable_text_gen(),
          x <- float(min: 0.0, max: @renderable_block_max_x),
          y <- float(min: 0.0, max: @renderable_block_max_y)
        ) do
      %Rendro.Block{content: text, x: x, y: y}
    end
  end

  defp renderable_text_gen do
    gen all(
          raw <- string(:printable, min_length: 1, max_length: @renderable_max_text_length),
          content = String.replace(raw, ~r/[()\\]/, ""),
          content != "",
          size <- float(min: 6.0, max: @renderable_max_text_size),
          r <- integer(0..255),
          g <- integer(0..255),
          b <- integer(0..255)
        ) do
      %Rendro.Text{content: content, font: "Helvetica", size: size, color: {r, g, b}}
    end
  end
end
