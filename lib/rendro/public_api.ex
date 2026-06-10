defmodule Rendro.PublicApi do
  @moduledoc false
  # Internal introspection module — consumed by mix rendro.api.gen and Phase 79 contract test.
  # Do NOT call from application code.

  @adapter_files [
    "lib/rendro/adapters/harfbuzz.ex",
    "lib/rendro/adapters/threadline.ex",
    "lib/rendro/adapters/mailglass.ex",
    "lib/rendro/adapters/accrue.ex",
    "lib/rendro/adapters/phoenix.ex",
    "lib/rendro/adapters/oban/render_worker.ex"
  ]

  @spec tier_of(module()) :: :stable | :adapter | :untagged
  def tier_of(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, %{tags: tags}, _} ->
        cond do
          :stable in tags -> :stable
          :adapter in tags -> :adapter
          true -> :untagged
        end

      _ ->
        :untagged
    end
  end

  @spec public_functions(module()) :: [String.t()]
  def public_functions(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, docs} ->
        docs
        |> Enum.filter(fn
          {{:function, _name, _arity}, _anno, _sig, doc, _meta} ->
            doc != :hidden

          _ ->
            false
        end)
        |> Enum.map(fn {{:function, name, arity}, _, _, _, _} ->
          "#{name}/#{arity}"
        end)
        |> Enum.sort()

      _ ->
        []
    end
  end

  @spec public_types(module()) :: [String.t()]
  def public_types(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, docs} ->
        docs
        |> Enum.filter(fn
          {{:type, _name, _arity}, _anno, _sig, doc, _meta} ->
            doc != :hidden

          _ ->
            false
        end)
        |> Enum.map(fn {{:type, name, arity}, _, _, _, _} ->
          "#{name}/#{arity}"
        end)
        |> Enum.sort()

      _ ->
        []
    end
  end

  @spec build_manifest([module()]) :: map()
  def build_manifest(modules) do
    module_entries =
      modules
      |> Enum.map(fn mod ->
        {Atom.to_string(mod),
         %{
           "tier" => to_string(tier_of(mod)),
           "functions" => public_functions(mod),
           "types" => public_types(mod)
         }}
      end)
      |> Enum.sort_by(fn {name, _} -> name end)
      |> Map.new()

    %{"modules" => module_entries}
  end

  @spec recompile_conditional_adapters() :: :ok
  def recompile_conditional_adapters do
    project_root = File.cwd!()

    for relative <- @adapter_files,
        path = Path.join(project_root, relative),
        File.exists?(path) do
      Code.compile_file(path)
    end

    :ok
  end
end
