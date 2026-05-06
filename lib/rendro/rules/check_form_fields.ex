defmodule Rendro.Rules.CheckFormFields do
  @moduledoc false

  alias Rendro.{Block, Document, FormField, Page, Row, Table, Text}

  @supported_types [:text, :checkbox, :radio]

  def check(%Document{} = doc, _root_doc) do
    errors =
      duplicate_form_field_names(doc) ++
        duplicate_radio_export_values(doc) ++
        duplicate_checked_radio_groups(doc)

    case errors do
      [] -> :ok
      _ -> {:errors, errors}
    end
  end

  def check(%FormField{name: name}, _doc) when not (is_binary(name) and byte_size(name) > 0),
    do: {:error, {:missing_required_key, :name}}

  def check(%FormField{type: type}, _doc) when type not in @supported_types,
    do: {:error, {:invalid_form_field_type, type}}

  def check(%FormField{name: name} = field, _doc) do
    if String.contains?(name, ".") do
      {:error, {:unsupported_form_field_name, name}}
    else
      check_field_contract(field)
    end
  end

  def check(_, _doc), do: :ok

  defp check_field_contract(%FormField{type: :text, value: value}) when not is_binary(value),
    do: {:error, {:invalid_form_field_value, value}}

  defp check_field_contract(%FormField{font: font} = field) do
    if font == Text.default_font() do
      check_size_contract(field)
    else
      {:error, {:invalid_form_field_font, font}}
    end
  end

  defp check_size_contract(%FormField{size: size}) when not (is_number(size) and size > 0),
    do: {:error, {:invalid_form_field_size, size}}

  defp check_size_contract(%FormField{checked: checked}) when not is_boolean(checked),
    do: {:error, {:invalid_form_field_checked, checked}}

  defp check_size_contract(%FormField{type: :radio, group: group})
       when not (is_binary(group) and byte_size(group) > 0),
       do: {:error, {:missing_required_key, :group}}

  defp check_size_contract(%FormField{type: :radio, group: group} = field) do
    if String.contains?(group, ".") do
      {:error, {:unsupported_form_field_name, group}}
    else
      check_export_value_contract(field)
    end
  end

  defp check_size_contract(%FormField{} = field), do: check_export_value_contract(field)

  defp check_export_value_contract(%FormField{type: type, export_value: export_value})
       when type in [:checkbox, :radio] and
              not (is_binary(export_value) and byte_size(export_value) > 0),
       do: {:error, {:invalid_form_field_export_value, export_value}}

  defp check_export_value_contract(%FormField{type: :checkbox, value: value})
       when not is_binary(value),
       do: {:error, {:invalid_form_field_value, value}}

  defp check_export_value_contract(%FormField{type: :radio, value: value})
       when not is_binary(value),
       do: {:error, {:invalid_form_field_value, value}}

  defp check_export_value_contract(%FormField{}), do: :ok

  defp duplicate_form_field_names(%Document{} = doc) do
    fields = collect_form_fields(doc)

    group_names =
      fields
      |> Enum.filter(&(&1.type == :radio))
      |> Enum.map(& &1.group)
      |> Enum.filter(&valid_identity?/1)
      |> Enum.uniq()

    fields
    |> Enum.map(& &1.name)
    |> Enum.filter(&valid_identity?/1)
    |> Kernel.++(group_names)
    |> duplicate_strings()
    |> Enum.map(&{:duplicate_form_field_name, &1})
  end

  defp duplicate_radio_export_values(%Document{} = doc) do
    doc
    |> collect_form_fields()
    |> Enum.filter(&(&1.type == :radio and valid_identity?(&1.group)))
    |> Enum.group_by(& &1.group)
    |> Enum.flat_map(fn {group, fields} ->
      fields
      |> Enum.map(& &1.export_value)
      |> Enum.filter(&valid_identity?/1)
      |> duplicate_strings()
      |> Enum.map(&{:duplicate_radio_export_value, group, &1})
    end)
  end

  defp duplicate_checked_radio_groups(%Document{} = doc) do
    doc
    |> collect_form_fields()
    |> Enum.filter(&(&1.type == :radio and &1.checked and valid_identity?(&1.group)))
    |> Enum.group_by(& &1.group)
    |> Enum.filter(fn {_group, fields} -> length(fields) > 1 end)
    |> Enum.map(fn {group, _fields} -> {:radio_group_multiple_checked_defaults, group} end)
  end

  defp collect_form_fields(%Document{pages: pages}) do
    Enum.flat_map(pages, &collect_page_form_fields/1)
  end

  defp collect_page_form_fields(%Page{blocks: blocks}) do
    Enum.flat_map(blocks, &collect_block_form_fields/1)
  end

  defp collect_block_form_fields(%Block{content: %Table{} = table}) do
    collect_row_form_fields(table.header) ++
      Enum.flat_map(table.rows, &collect_row_form_fields/1)
  end

  defp collect_block_form_fields(%Block{content: %FormField{} = field}), do: [field]
  defp collect_block_form_fields(%Block{}), do: []

  defp collect_row_form_fields(nil), do: []

  defp collect_row_form_fields(%Row{cells: cells}) do
    Enum.flat_map(cells, fn %Rendro.Cell{content: block} -> collect_block_form_fields(block) end)
  end

  defp duplicate_strings(values) do
    values
    |> Enum.group_by(& &1)
    |> Enum.filter(fn {_value, grouped} -> length(grouped) > 1 end)
    |> Enum.map(fn {value, _grouped} -> value end)
    |> Enum.sort()
  end

  defp valid_identity?(value), do: is_binary(value) and byte_size(value) > 0
end
