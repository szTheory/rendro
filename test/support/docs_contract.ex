defmodule Rendro.Test.DocsContract do
  @moduledoc false

  @fence_regex ~r/```(?<lang>[[:alnum:]_-]+)\n(?<code>.*?)```/ms
  @id_regex ~r/^\s*#\s*docs-contract:\s*(?<id>[[:alnum:]_-]+)\s*$/m

  def verified_fences(path) do
    path
    |> File.read!()
    |> then(&Regex.scan(@fence_regex, &1))
    |> Enum.filter(fn [_full, lang, _code] -> lang == "elixir" end)
    |> Enum.map(fn [_full, _lang, code] ->
      case Regex.named_captures(@id_regex, code) do
        %{"id" => id} -> %{id: id, code: code}
        _ -> raise ArgumentError, "verified elixir fence in #{path} is missing a docs-contract id"
      end
    end)
  end

  def evaluate!(code, file) do
    ast = Code.string_to_quoted!("import ExUnit.Assertions\n#{code}")

    Macro.prewalk(ast, fn
      {{:., _, [{:__aliases__, _, [:File]}, func]}, _, _}
      when func in [:write, :write!, :rm, :rm!, :rm_rf, :mkdir, :mkdir!, :cp, :cp!] ->
        raise "Docs contract evaluator cannot perform File.#{func} writes"

      {{:., _, [{:__aliases__, _, [:System]}, cmd]}, _, _}
      when cmd in [:cmd] ->
        raise "Docs contract evaluator cannot run System.#{cmd}"

      {{:., _, [{:__aliases__, _, [:Mix, :Task]}, run]}, _, _}
      when run in [:run, :clear] ->
        raise "Docs contract evaluator cannot invoke Mix.Task.#{run}"

      node ->
        node
    end)

    Code.eval_quoted(ast, [], file: file)
  end
end
