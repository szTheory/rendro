defmodule Rendro.Pipeline.Validate do
  @moduledoc false

  alias Rendro.Document
  alias Rendro.Rules.{
    CheckBounds,
    CheckEmbeddedFiles,
    CheckFormFields,
    CheckReferences,
    CheckRequiredKeys
  }

  @default_rules [CheckReferences, CheckBounds, CheckRequiredKeys, CheckFormFields, CheckEmbeddedFiles]

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, Rendro.Error.t()}
  def run(%Document{} = doc) do
    rules = Application.get_env(:rendro, :validation_rules, @default_rules)

    case walk(doc, doc, rules) do
      [] ->
        {:ok, doc}

      errors ->
        {:error,
         Rendro.Error.from_stage(:validate, :structural_corruption, %{details: %{errors: errors}})}
    end
  end

  defp walk(node, doc, rules) do
    node_errors =
      Enum.flat_map(rules, fn rule ->
        case rule.check(node, doc) do
          :ok -> []
          {:error, reason} -> [reason]
          {:errors, reasons} -> reasons
        end
      end)

    child_errors = walk_children(node, doc, rules)
    node_errors ++ child_errors
  end

  defp walk_children(%Document{pages: pages}, doc, rules) do
    Enum.flat_map(pages, &walk(&1, doc, rules))
  end

  defp walk_children(%Rendro.Page{blocks: blocks}, doc, rules) do
    Enum.flat_map(blocks, &walk(&1, doc, rules))
  end

  defp walk_children(%Rendro.Block{content: content}, doc, rules) do
    walk(content, doc, rules)
  end

  defp walk_children(%Rendro.Table{header: header, rows: rows}, doc, rules) do
    header_errors = if header, do: walk(header, doc, rules), else: []
    row_errors = Enum.flat_map(rows, &walk(&1, doc, rules))
    header_errors ++ row_errors
  end

  defp walk_children(%Rendro.Row{cells: cells}, doc, rules) do
    Enum.flat_map(cells, &walk(&1, doc, rules))
  end

  defp walk_children(%Rendro.Cell{content: content}, doc, rules) do
    walk(content, doc, rules)
  end

  defp walk_children(_, _doc, _rules), do: []
end
