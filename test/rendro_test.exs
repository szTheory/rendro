defmodule RendroTest do
  use ExUnit.Case

  test "module exists" do
    assert Code.ensure_loaded?(Rendro)
  end

  test "render/1 is exported" do
    assert function_exported?(Rendro, :render, 1)
  end

  test "render/2 is exported" do
    assert function_exported?(Rendro, :render, 2)
  end
end
