defmodule Rendro.Pipeline.Measure do
  @moduledoc """
  Calculates dimensions for blocks that don't have explicit sizes.

  Uses font metrics to compute text width and derives height from font size.
  """

  alias Rendro.PDF.Font

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Rendro.Document{pages: pages} = doc) do
    font = Font.helvetica()
    measured_pages = Enum.map(pages, &measure_page(&1, font))
    {:ok, %{doc | pages: measured_pages}}
  end

  defp measure_page(%Rendro.Page{blocks: blocks} = page, font) do
    measured_blocks = Enum.map(blocks, &measure_block(&1, font))
    %{page | blocks: measured_blocks}
  end

  defp measure_block(%Rendro.Block{content: %Rendro.Text{} = text, width: nil} = block, font) do
    width = Font.text_width(font, text.content, text.size)
    height = text.size * 1.2
    %{block | width: width, height: height}
  end

  defp measure_block(%Rendro.Block{content: %Rendro.Text{} = text, height: nil} = block, _font) do
    %{block | height: text.size * 1.2}
  end

  defp measure_block(block, _font), do: block
end
