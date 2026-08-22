defmodule Mix.Tasks.RendroLivebookCheckTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Rendro.Livebook.Check
  alias Rendro.Theme.Snippet

  setup do
    Application.delete_env(:rendro, :livebook_converter)
    Application.delete_env(:rendro, :livebook_command_runner)
    Mix.Task.reenable("rendro.livebook.check")

    on_exit(fn ->
      Application.delete_env(:rendro, :livebook_converter)
      Application.delete_env(:rendro, :livebook_command_runner)
      Mix.Task.reenable("rendro.livebook.check")
    end)

    :ok
  end

  test "task reads the notebook, converts it, and runs the generated script with local checkout env" do
    parent = self()

    Application.put_env(:rendro, :livebook_converter, fn markdown ->
      send(parent, {:converted, markdown})
      {:ok, "IO.puts(\"converted notebook\")"}
    end)

    Application.put_env(:rendro, :livebook_command_runner, fn "elixir", [script_path], opts ->
      send(parent, {:ran, File.read!(script_path), opts})
      {"converted notebook\n", 0}
    end)

    {messages, result} = capture_shell_messages(fn -> Check.run([]) end)

    assert result == :ok
    assert Enum.join(messages, "\n") =~ "Livebook tutorial VERIFIED"
    assert_received {:converted, markdown}
    assert markdown =~ "Kino.Download.new"
    assert_received {:ran, "IO.puts(\"converted notebook\")", opts}
    assert {"RENDRO_LIVEBOOK_LOCAL", "1"} in opts[:env]
    assert {"RENDRO_LIVEBOOK_PATH", File.cwd!()} in opts[:env]
  end

  test "non-zero command runner exit surfaces command output" do
    Application.put_env(:rendro, :livebook_converter, fn _markdown ->
      {:ok, "raise \"boom\""}
    end)

    Application.put_env(:rendro, :livebook_command_runner, fn "elixir", [_script_path], _opts ->
      {"notebook failed\n", 7}
    end)

    {messages, exit_reason} =
      capture_shell_messages(fn ->
        catch_exit(Check.run([]))
      end)

    assert exit_reason == {:shutdown, 1}
    assert Enum.join(messages, "\n") =~ "notebook failed"
    assert Enum.join(messages, "\n") =~ "status 7"
  end

  test "converter failure surfaces a clear error" do
    Application.put_env(:rendro, :livebook_converter, fn _markdown ->
      {:error, "Livebook is not available"}
    end)

    {messages, exit_reason} =
      capture_shell_messages(fn ->
        catch_exit(Check.run([]))
      end)

    assert exit_reason == {:shutdown, 1}
    assert Enum.join(messages, "\n") =~ "Livebook is not available"
  end

  test "production notebook has required preview, download, PDF assertion, and local mode" do
    notebook = File.read!("guides/livebook/first_invoice.livemd")

    assert notebook =~ "RENDRO_LIVEBOOK_LOCAL"
    assert notebook =~ "Rendro.Recipes.Invoice.document"
    assert notebook =~ "Kino.HTML.new"
    assert notebook =~ "Kino.Download.new"
    assert notebook =~ "%PDF-"
    refute notebook =~ "benchmark"
  end

  test "production notebook contains one exact canonical themed invoice path and linked proof" do
    notebook = File.read!("guides/livebook/first_invoice.livemd")

    assert length(Regex.scan(~r/^## Apply a preset$/m, notebook)) == 1

    [_, canonical_block] =
      Regex.run(
        ~r/# rendro-theme-snippet:start\n(?<snippet>.*?)# rendro-theme-snippet:end/s,
        notebook
      )

    assert canonical_block == Snippet.usage_snippet("invoice", "swiss", "#2C6BED", "light")

    assert length(
             Regex.scan(~r/Rendro\.render\(themed_document, deterministic: true\)/, notebook)
           ) == 1

    assert notebook =~ "binary_part(themed_pdf, 0, 5) != \"%PDF-\""
    assert notebook =~ "byte_size(themed_pdf)"
    assert notebook =~ "themed_sha256"
    assert notebook =~ "Base.encode64(themed_pdf)"
    assert notebook =~ "fn -> themed_pdf end"
  end

  test "production notebook keeps preset teaching focused, screen-oriented, and no-server" do
    notebook = File.read!("guides/livebook/first_invoice.livemd")

    assert notebook =~ "edit the\n`preset`, accent, and mode values"
    assert notebook =~ "Presets are working starting points"

    assert notebook =~
             "Screen-oriented; not a print, accessibility, PDF/UA, or WCAG claim."

    for forbidden <- [
          "Kino.Input",
          "Kino.JS",
          "fetch(",
          "Livebook.Server",
          "livebook server",
          "all presets",
          "all-presets",
          "comparison grid"
        ] do
      refute notebook =~ forbidden
    end
  end

  test "task source does not start a Livebook server" do
    source = File.read!("lib/mix/tasks/rendro/livebook/check.ex")

    refute source =~ "Livebook.Server"
    refute source =~ "livebook server"
  end

  test "Livebook authoring tooling is isolated from the root release graph" do
    deps = Keyword.fetch!(Rendro.MixProject.project(), :deps)
    refute Enum.any?(deps, &(elem(&1, 0) == :livebook))

    refute File.read!("mix.lock") =~ "\"livebook\""

    assert File.read!("scripts/verify_livebook.exs") =~
             "Mix.install([{:livebook, \"~> 0.19.9\"}])"

    refute "scripts/verify_livebook.exs" in Keyword.fetch!(Rendro.MixProject.project(), :package)[
             :files
           ]
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
