defmodule Mix.Tasks.Rendro.Livebook.Check do
  use Mix.Task

  @shortdoc "Execute the Rendro first-invoice Livebook without starting a server"

  @moduledoc """
  Converts `guides/livebook/first_invoice.livemd` with
  `Livebook.live_markdown_to_elixir/1` and executes the resulting script with
  `RENDRO_LIVEBOOK_LOCAL=1`.

      mix rendro.livebook.check
  """
  @moduledoc tags: [:adapter]
  @compile {:no_warn_undefined, Livebook}

  @default_notebook_path "guides/livebook/first_invoice.livemd"
  @converter_env :livebook_converter
  @command_runner_env :livebook_command_runner

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    notebook_path = parse_args(args)

    case check(notebook_path) do
      {:ok, output} ->
        Mix.shell().info(output)

      {:error, message} ->
        Mix.shell().error(message)
        exit({:shutdown, 1})
    end
  end

  def check(notebook_path \\ @default_notebook_path) do
    with {:ok, markdown} <- read_notebook(notebook_path),
         {:ok, elixir_source} <- convert_notebook(markdown),
         {:ok, output} <- run_script(elixir_source) do
      {:ok, String.trim("Livebook tutorial VERIFIED\n#{output}")}
    end
  end

  defp parse_args([]), do: @default_notebook_path
  defp parse_args([path]), do: path
  defp parse_args(args), do: Mix.raise("Unexpected arguments: #{Enum.join(args, " ")}")

  defp read_notebook(path) do
    case File.read(path) do
      {:ok, markdown} -> {:ok, markdown}
      {:error, reason} -> {:error, "could not read #{path}: #{:file.format_error(reason)}"}
    end
  end

  defp convert_notebook(markdown) do
    converter = Application.get_env(:rendro, @converter_env) || (&default_converter/1)
    converter.(markdown)
  rescue
    exception -> {:error, "Livebook conversion failed: #{Exception.message(exception)}"}
  end

  defp default_converter(markdown) do
    case Code.ensure_loaded(Livebook) do
      {:module, Livebook} ->
        {:ok, Livebook.live_markdown_to_elixir(markdown)}

      {:error, _reason} ->
        {:error,
         "Livebook is not available; run mix deps.get and keep :livebook as a dev/test runtime:false dependency"}
    end
  end

  defp run_script(elixir_source) do
    runner = Application.get_env(:rendro, @command_runner_env) || (&System.cmd/3)

    tmp_path =
      Path.join(System.tmp_dir!(), "rendro-livebook-#{System.unique_integer([:positive])}.exs")

    File.write!(tmp_path, elixir_source)

    try do
      opts = [
        stderr_to_stdout: true,
        env: [
          {"RENDRO_LIVEBOOK_LOCAL", "1"},
          {"RENDRO_LIVEBOOK_PATH", File.cwd!()}
        ]
      ]

      case runner.("elixir", [tmp_path], opts) do
        {output, 0} -> {:ok, output}
        {output, status} -> {:error, "Livebook tutorial failed with status #{status}:\n#{output}"}
      end
    after
      File.rm(tmp_path)
    end
  end
end
