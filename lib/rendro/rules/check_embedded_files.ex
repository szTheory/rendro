defmodule Rendro.Rules.CheckEmbeddedFiles do
  @moduledoc false

  alias Rendro.Document

  def check(%Document{} = doc, _root_doc) do
    errors =
      doc.embedded_file_registry.files
      |> Map.values()
      |> Kernel.++(duplicate_filename_errors(doc))
      |> collect_errors()

    case errors do
      [] -> :ok
      _ -> {:errors, errors}
    end
  end

  def check(_, _doc), do: :ok

  defp collect_errors(entries) do
    Enum.flat_map(entries, fn
      {:duplicate_embedded_file_name, _filename} = error ->
        [error]

      entry ->
        []
        |> maybe_add_invalid_filename(entry)
        |> maybe_add_invalid_mime_type(entry)
        |> maybe_add_invalid_description(entry)
        |> maybe_add_invalid_timestamp(entry, :created_at)
        |> maybe_add_invalid_timestamp(entry, :modified_at)
    end)
  end

  defp duplicate_filename_errors(%Document{} = doc) do
    doc.embedded_file_registry.files
    |> Map.values()
    |> Enum.map(&Map.get(&1, :filename))
    |> Enum.filter(&valid_non_empty_binary?/1)
    |> Enum.group_by(& &1)
    |> Enum.filter(fn {_filename, grouped} -> length(grouped) > 1 end)
    |> Enum.map(fn {filename, _grouped} -> {:duplicate_embedded_file_name, filename} end)
    |> Enum.sort()
  end

  defp maybe_add_invalid_filename(errors, %{filename: filename}) do
    if valid_non_empty_binary?(filename),
      do: errors,
      else: [{:invalid_embedded_file_filename, filename} | errors]
  end

  defp maybe_add_invalid_filename(errors, entry),
    do: [{:invalid_embedded_file_filename, Map.get(entry, :filename)} | errors]

  defp maybe_add_invalid_mime_type(errors, %{mime_type: mime_type}) do
    if valid_non_empty_binary?(mime_type),
      do: errors,
      else: [{:invalid_embedded_file_mime_type, mime_type} | errors]
  end

  defp maybe_add_invalid_mime_type(errors, entry),
    do: [{:invalid_embedded_file_mime_type, Map.get(entry, :mime_type)} | errors]

  defp maybe_add_invalid_description(errors, entry) do
    case Map.fetch(entry, :description) do
      :error -> errors
      {:ok, description} when is_binary(description) -> errors
      {:ok, description} -> [{:invalid_embedded_file_description, description} | errors]
    end
  end

  defp maybe_add_invalid_timestamp(errors, entry, field) do
    case Map.fetch(entry, field) do
      :error -> errors
      {:ok, %DateTime{}} -> errors
      {:ok, value} -> [{:invalid_embedded_file_timestamp, field, value} | errors]
    end
  end

  defp valid_non_empty_binary?(value), do: is_binary(value) and byte_size(value) > 0
end
