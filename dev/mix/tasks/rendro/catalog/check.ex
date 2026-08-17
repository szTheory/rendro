defmodule Mix.Tasks.Rendro.Catalog.Check do
  use Mix.Task

  @moduledoc false
  @shortdoc "Verify bounded Rendro catalog artifacts without writing"
  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case Rendro.Catalog.check(parse_opts(args)) do
      :ok ->
        Mix.shell().info("Catalog VERIFIED")

      {:error, errors} ->
        shell = Mix.shell()
        Enum.each(errors, &shell.error/1)
        exit({:shutdown, 1})
    end
  end

  defp parse_opts(args) do
    {opts, rest, invalid} = OptionParser.parse(args, strict: [pdfium: :string])

    if rest != [] or invalid != [],
      do:
        Mix.raise(
          "Unexpected catalog arguments: #{Enum.join(rest ++ Enum.map(invalid, &elem(&1, 0)), " ")}"
        ),
      else: opts
  end
end
