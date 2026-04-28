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
    Code.eval_string("import ExUnit.Assertions\n#{code}", [], file: file)
  end
end
