defmodule Mix.Tasks.VerifyTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Verify

  test "run_with_lanes executes advisory steps even after deterministic failure" do
    lanes = [
      {"DETERMINISTIC (CORE)", [{"CI", fn -> {:error, 2, "ci failed"} end}]},
      {"ADVISORY (ADAPTERS)", [{"Phoenix Example", fn -> :ok end}]}
    ]

    {messages, {:error, results}} = capture_shell_messages(fn -> Verify.run_with_lanes(lanes) end)
    output = Enum.join(messages, "\n")

    assert Enum.map(results, & &1.lane) == ["DETERMINISTIC (CORE)", "ADVISORY (ADAPTERS)"]
    assert Enum.map(results, & &1.step) == ["CI", "Phoenix Example"]
    assert Enum.map(results, & &1.status) == [:fail, :pass]
    assert output =~ "DETERMINISTIC (CORE)"
    assert output =~ "ADVISORY (ADAPTERS)"
    assert output =~ "Running Phoenix Example..."
    assert output =~ "VERIFICATION COMPLETE"
    assert String.contains?(output, "Summary:")
    assert String.contains?(output, "Overall: FAIL")
    assert String.contains?(output, "[ADVISORY (ADAPTERS)] Phoenix Example: PASS")

    assert message_index(output, "DETERMINISTIC (CORE)") <
             message_index(output, "ADVISORY (ADAPTERS)")

    assert message_index(output, "Running Phoenix Example...") >
             message_index(output, "DETERMINISTIC (CORE)")
  end

  test "run_with_lanes returns failing status only after summary output is printed" do
    lanes = [
      {"DETERMINISTIC (CORE)", [{"CI", fn -> :ok end}]},
      {"ADVISORY (ADAPTERS)", [{"Phoenix Example", fn -> {:error, 3, "example failed"} end}]}
    ]

    {messages, {:error, results}} = capture_shell_messages(fn -> Verify.run_with_lanes(lanes) end)
    output = Enum.join(messages, "\n")

    assert Enum.map(results, & &1.status) == [:pass, :fail]
    assert output =~ "VERIFICATION COMPLETE"
    assert output =~ "Summary:"
    assert output =~ "[ADVISORY (ADAPTERS)] Phoenix Example: FAIL"
    assert output =~ "Overall: FAIL"

    assert message_index(output, "VERIFICATION COMPLETE") <
             message_index(output, "Overall: FAIL")
  end

  test "run exits non-zero only after final summary output" do
    lanes = [
      {"DETERMINISTIC (CORE)", [{"CI", fn -> {:error, 2, "ci failed"} end}]},
      {"ADVISORY (ADAPTERS)", [{"Phoenix Example", fn -> :ok end}]}
    ]

    Application.put_env(:rendro, :verify_test_lanes, lanes)

    on_exit(fn ->
      Application.delete_env(:rendro, :verify_test_lanes)
    end)

    {messages, exit_reason} =
      capture_shell_messages(fn ->
        catch_exit(Verify.run([]))
      end)

    output = Enum.join(messages, "\n")

    assert exit_reason == {:shutdown, 1}
    assert output =~ "VERIFICATION COMPLETE"
    assert output =~ "Overall: FAIL"
    assert output =~ "ci failed"
    assert output =~ "[ADVISORY (ADAPTERS)] Phoenix Example: PASS"
    refute output =~ "Docs Contract"

    assert message_index(output, "VERIFICATION COMPLETE") <
             message_index(output, "Overall: FAIL")
  end

  test "default docs lane uses the canonical docs.contract task" do
    source = File.read!("lib/mix/tasks/verify.ex")

    assert source =~ "Mix.Task.run(\"docs.contract\")"
    refute source =~ "Mix.Task.run(\"run\", [\"scripts/verify_docs.exs\"])"
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

  defp message_index(output, needle) do
    case :binary.match(output, needle) do
      {index, _length} -> index
      :nomatch -> flunk("expected #{inspect(needle)} to appear in #{inspect(output)}")
    end
  end
end
