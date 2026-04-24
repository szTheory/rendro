if Code.ensure_loaded?(Oban) do
  defmodule Rendro.Adapters.Oban.RenderWorker do
    @moduledoc """
    Oban worker pattern for background PDF rendering.
    """

    use Oban.Worker, queue: :render, max_attempts: 3

    @impl Oban.Worker
    def perform(%Oban.Job{args: %{"module" => module_str, "args" => args, "output_path" => path}}) do
      module = String.to_existing_atom(module_str)
      doc = module.build_document(args)

      case Rendro.render(doc, output: path) do
        {:ok, _binary} -> :ok
        {:error, error} -> {:error, error.reason}
      end
    end
  end
end
