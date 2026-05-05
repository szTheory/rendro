defmodule Rendro.Rules.CheckBounds do
  @moduledoc false

  def check(%Rendro.Page{width: w, height: h}, _doc)
      when is_number(w) and w > 0 and is_number(h) and h > 0 do
    :ok
  end

  def check(%Rendro.Page{}, _doc), do: {:error, :invalid_page_bounds}

  def check(%Rendro.Block{x: x, y: y, width: w, height: h}, _doc)
      when is_number(x) and is_number(y) and is_number(w) and is_number(h) and w >= 0 and h >= 0 do
    :ok
  end

  def check(%Rendro.Block{}, _doc), do: {:error, :invalid_block_bounds}

  def check(_, _doc), do: :ok
end
