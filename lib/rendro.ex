defmodule Rendro do
  @moduledoc """
  Pure-Elixir, Phoenix-first PDF/document generation with deterministic layout and pagination.
  """

  alias Rendro.{Block, Document, Metadata, Page, Text}

  @spec document(keyword()) :: Document.t()
  def document(attrs \\ []) do
    struct!(Document, attrs)
  end

  @spec page(keyword()) :: Page.t()
  def page(attrs \\ []) do
    struct!(Page, attrs)
  end

  @spec block(Text.t() | term(), keyword()) :: Block.t()
  def block(content, attrs \\ []) do
    struct!(Block, Keyword.put(attrs, :content, content))
  end

  @spec text(String.t(), keyword()) :: Text.t()
  def text(content, attrs \\ []) do
    struct!(Text, Keyword.put(attrs, :content, content))
  end

  @spec metadata(keyword()) :: Metadata.t()
  def metadata(attrs \\ []) do
    struct!(Metadata, attrs)
  end
end
