defmodule Rendro.Rules.CheckRequiredKeys do
  @moduledoc false

  def check(%Rendro.Document{pages: pages}, _doc) when is_list(pages), do: :ok
  def check(%Rendro.Document{}, _doc), do: {:error, {:missing_required_key, :pages}}

  def check(%Rendro.Page{blocks: blocks}, _doc) when is_list(blocks), do: :ok
  def check(%Rendro.Page{}, _doc), do: {:error, {:missing_required_key, :blocks}}

  def check(%Rendro.Block{content: nil}, _doc), do: {:error, {:missing_required_key, :content}}
  def check(%Rendro.Block{}, _doc), do: :ok

  def check(_, _doc), do: :ok
end
