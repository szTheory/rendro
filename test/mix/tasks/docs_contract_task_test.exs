defmodule Mix.Tasks.Docs.ContractTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Docs.Contract

  test "runs the canonical docs verifier command" do
    runner = fn "mix", ["run", "scripts/verify_docs.exs"], _opts ->
      {"Docs contract VERIFIED!\n", 0}
    end

    Application.put_env(:rendro, :docs_contract_command_runner, runner)

    on_exit(fn ->
      Application.delete_env(:rendro, :docs_contract_command_runner)
    end)

    {messages, result} = capture_shell_messages(fn -> Contract.run([]) end)

    assert result == :ok
    assert Enum.join(messages, "\n") =~ "Docs contract VERIFIED!"
  end

  test "exits non-zero when the canonical docs verifier fails" do
    runner = fn "mix", ["run", "scripts/verify_docs.exs"], _opts ->
      {"docs failed\n", 1}
    end

    Application.put_env(:rendro, :docs_contract_command_runner, runner)

    on_exit(fn ->
      Application.delete_env(:rendro, :docs_contract_command_runner)
    end)

    {messages, exit_reason} =
      capture_shell_messages(fn ->
        catch_exit(Contract.run([]))
      end)

    assert exit_reason == {:shutdown, 1}
    assert Enum.join(messages, "\n") =~ "docs failed"
  end

  defp capture_shell_messages(fun) do
    original_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    result =
      try do
        fun.()
      after
        Mix.shell(original_shell)
      end

    {flush_shell_messages([]), result}
  end

  defp flush_shell_messages(messages) do
    receive do
      {:mix_shell, _level, payload} ->
        flush_shell_messages([IO.iodata_to_binary(payload) | messages])
    after
      0 -> Enum.reverse(messages)
    end
  end
end
