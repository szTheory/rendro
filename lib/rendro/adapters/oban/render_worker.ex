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
           {:ok, storage_mod, storage_opts} <- fetch_storage(args),
           {:ok, policies} <- fetch_policies(args),
           {:ok, doc} <- build_document(module, builder_args) do
        doc
        |> inject_missing_policies(policies)
        |> render_and_store(storage_mod, storage_opts)
      end
    end

    def perform(%Oban.Job{args: args}), do: {:error, {:invalid_worker_field, :args, args}}

    defp fetch_module(%{"module" => value}), do: resolve_module(value)
    defp fetch_module(_args), do: {:error, {:missing_worker_field, :module}}

    defp fetch_builder_args(%{"args" => value}) when is_map(value), do: {:ok, value}

    defp fetch_builder_args(%{"args" => value}),
      do: {:error, {:invalid_worker_field, :args, value}}

    defp fetch_builder_args(_args), do: {:error, {:missing_worker_field, :args}}

    defp fetch_storage(%{"storage_module" => mod_val} = args) do
      opts_val = Map.get(args, "storage_opts", %{})

      with {:ok, mod} <- resolve_storage_module(mod_val),
           {:ok, opts} <- resolve_storage_opts(opts_val) do
        {:ok, mod, opts}
      end
    end

    defp fetch_storage(%{"output_path" => value}) when is_binary(value) and value != "" do
      {:ok, Rendro.Storage.Local, [path: value]}
    end

    defp fetch_storage(%{"output_path" => value}),
      do: {:error, {:invalid_worker_field, :output_path, value}}

    defp fetch_storage(_args), do: {:error, {:missing_worker_field, :output_path}}

    defp resolve_storage_module(module) when is_binary(module) do
      module
      |> module_name_candidates()
      |> Enum.find_value(fn candidate ->
        try do
          candidate
          |> String.to_existing_atom()
          |> validate_storage_module(module)
        rescue
          ArgumentError -> nil
        end
      end)
      |> case do
        nil -> {:error, {:unknown_worker_storage, module}}
        result -> result
      end
    end

    defp resolve_storage_module(value),
      do: {:error, {:invalid_worker_field, :storage_module, value}}

    defp resolve_storage_opts(opts) when is_map(opts) do
      # Convert string keys to atoms safely
      normalized = Enum.map(opts, fn {k, v} -> {String.to_atom(k), v} end)
      {:ok, normalized}
    end

    defp resolve_storage_opts(opts), do: {:error, {:invalid_worker_field, :storage_opts, opts}}

    defp validate_storage_module(module, module_input) do
      cond do
        not Code.ensure_loaded?(module) -> {:error, {:unknown_worker_storage, module_input}}
        not function_exported?(module, :put, 2) -> {:error, {:invalid_worker_storage, module}}
        true -> {:ok, module}
      end
    end

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

    defp render_and_store(doc, storage_mod, storage_opts) do
      case Rendro.render_to_artifact(doc) do
        {:ok, artifact} ->
          case storage_mod.put(artifact, storage_opts) do
            {:ok, _identifier} -> :ok
            {:error, error} -> {:error, {:storage_error, error}}
          end

        {:error, error} ->
          {:error, error.reason}
      end
    end

    defp module_name_candidates("Elixir." <> _ = module), do: [module]
    defp module_name_candidates(module), do: [module, "Elixir." <> module]
  end
end
