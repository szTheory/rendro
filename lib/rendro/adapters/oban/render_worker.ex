if Code.ensure_loaded?(Oban) do
  defmodule Rendro.Adapters.Oban.RenderWorker do
    @moduledoc """
    Oban worker pattern for background PDF rendering.
    """

    use Oban.Worker, queue: :render, max_attempts: 3

    @supported_policies %{
      "max_pages" => :max_pages,
      "max_bytes" => :max_bytes,
      "timeout" => :timeout
    }

    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) when is_map(args) do
      with {:ok, module} <- fetch_module(args),
           {:ok, builder_args} <- fetch_builder_args(args),
           {:ok, output_path} <- fetch_output_path(args),
           {:ok, policies} <- fetch_policies(args),
           {:ok, doc} <- build_document(module, builder_args) do
        doc
        |> inject_missing_policies(policies)
        |> render_document(output_path)
      end
    end

    def perform(%Oban.Job{args: args}), do: {:error, {:invalid_worker_field, :args, args}}

    defp fetch_module(%{"module" => value}), do: resolve_module(value)
    defp fetch_module(_args), do: {:error, {:missing_worker_field, :module}}

    defp fetch_builder_args(%{"args" => value}) when is_map(value), do: {:ok, value}

    defp fetch_builder_args(%{"args" => value}),
      do: {:error, {:invalid_worker_field, :args, value}}

    defp fetch_builder_args(_args), do: {:error, {:missing_worker_field, :args}}

    defp fetch_output_path(%{"output_path" => value}) when is_binary(value) and value != "",
      do: {:ok, value}

    defp fetch_output_path(%{"output_path" => value}),
      do: {:error, {:invalid_worker_field, :output_path, value}}

    defp fetch_output_path(_args), do: {:error, {:missing_worker_field, :output_path}}

    defp fetch_policies(%{"policies" => value}) when is_map(value), do: normalize_policies(value)

    defp fetch_policies(%{"policies" => value}),
      do: {:error, {:invalid_worker_field, :policies, value}}

    defp fetch_policies(_args), do: {:ok, []}

    defp resolve_module(module) when is_atom(module) do
      validate_builder_module(module, module)
    end

    defp resolve_module(module) when is_binary(module) do
      module
      |> module_name_candidates()
      |> Enum.find_value(fn candidate ->
        try do
          candidate
          |> String.to_existing_atom()
          |> validate_builder_module(module)
        rescue
          ArgumentError -> nil
        end
      end)
      |> case do
        nil -> {:error, {:unknown_worker_module, module}}
        result -> result
      end
    end

    defp resolve_module(value), do: {:error, {:invalid_worker_field, :module, value}}

    defp validate_builder_module(module, module_input) do
      cond do
        not Code.ensure_loaded?(module) ->
          {:error, {:unknown_worker_module, module_input}}

        not function_exported?(module, :build_document, 1) ->
          {:error, {:invalid_worker_module, module}}

        true ->
          {:ok, module}
      end
    end

    defp normalize_policies(policies) do
      Enum.reduce_while(policies, {:ok, []}, fn {key, value}, {:ok, acc} ->
        case normalize_policy(key, value) do
          {:ok, policy} -> {:cont, {:ok, [policy | acc]}}
          {:error, _} = error -> {:halt, error}
        end
      end)
      |> case do
        {:ok, acc} -> {:ok, Enum.reverse(acc)}
        error -> error
      end
    end

    defp normalize_policy(key, value) when is_atom(key) do
      normalize_policy(Atom.to_string(key), value)
    end

    defp normalize_policy(key, value) when is_binary(key) do
      case @supported_policies do
        %{^key => atom_key} -> validate_policy_value(atom_key, value)
        _ -> {:error, {:unknown_worker_policy, key}}
      end
    end

    defp normalize_policy(key, _value), do: {:error, {:unknown_worker_policy, key}}

    defp validate_policy_value(policy, value) when is_integer(value) and value >= 0,
      do: {:ok, {policy, value}}

    defp validate_policy_value(policy, value),
      do: {:error, {:invalid_worker_policy, policy, value}}

    defp build_document(module, args) do
      case module.build_document(args) do
        %Rendro.Document{} = doc -> {:ok, doc}
        other -> {:error, {:invalid_worker_document, module, other}}
      end
    end

    defp inject_missing_policies(%Rendro.Document{} = doc, []), do: doc

    defp inject_missing_policies(%Rendro.Document{} = doc, policies) do
      existing = doc.options |> Map.get(:policies, []) |> List.wrap()

      merged =
        Enum.reduce(policies, existing, fn {key, value}, acc ->
          if Keyword.has_key?(acc, key), do: acc, else: Keyword.put(acc, key, value)
        end)

      put_in(doc.options[:policies], merged)
    end

    defp render_document(doc, output_path) do
      case Rendro.render(doc, output: output_path) do
        {:ok, _binary} -> :ok
        {:error, error} -> {:error, error.reason}
      end
    end

    defp module_name_candidates("Elixir." <> _ = module), do: [module]
    defp module_name_candidates(module), do: [module, "Elixir." <> module]
  end
end
