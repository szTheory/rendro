defmodule Rendro.Test.DocsContractTest do
  use ExUnit.Case, async: true
  alias Rendro.Test.DocsContract

  describe "evaluate!/2" do
    test "evaluates standard valid Elixir assertions normally" do
      code = """
      assert 1 + 1 == 2
      """
      # Shouldn't raise
      assert {_, _} = DocsContract.evaluate!(code, "test.md")
    end

    test "raises an error before execution when snippet contains File operations" do
      code = """
      File.write!("foo.txt", "bar")
      """
      assert_raise RuntimeError, ~r/Docs contract evaluator cannot perform File\.write! writes/, fn ->
        DocsContract.evaluate!(code, "test.md")
      end

      code2 = """
      File.rm("foo.txt")
      """
      assert_raise RuntimeError, ~r/Docs contract evaluator cannot perform File\.rm writes/, fn ->
        DocsContract.evaluate!(code2, "test.md")
      end
    end

    test "raises an error before execution when snippet contains System.cmd" do
      code = """
      System.cmd("echo", ["hello"])
      """
      assert_raise RuntimeError, ~r/Docs contract evaluator cannot run System\.cmd/, fn ->
        DocsContract.evaluate!(code, "test.md")
      end
    end

    test "raises an error before execution when snippet contains Mix.Task.run" do
      code = """
      Mix.Task.run("test")
      """
      assert_raise RuntimeError, ~r/Docs contract evaluator cannot invoke Mix\.Task\.run/, fn ->
        DocsContract.evaluate!(code, "test.md")
      end
    end
  end
end
