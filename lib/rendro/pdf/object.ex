defmodule Rendro.PDF.Object do
  @moduledoc """
  PDF value type serialization per PDF 1.4 spec.

  Converts Elixir terms into their PDF binary representations:
  integers, floats, booleans, names, strings, arrays, dictionaries,
  streams, and indirect object references.
  """

  @type ref :: {non_neg_integer(), non_neg_integer()}

  @spec serialize(term()) :: iodata()
  def serialize(value) when is_integer(value), do: Integer.to_string(value)
  def serialize(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 4)
  def serialize(true), do: "true"
  def serialize(false), do: "false"
  def serialize(nil), do: "null"

  def serialize({:name, name}) when is_binary(name), do: ["/", name]

  def serialize({:string, str}) when is_binary(str) do
    ["(", escape_string(str), ")"]
  end

  def serialize({:hex_string, str}) when is_binary(str) do
    ["<", Base.encode16(str), ">"]
  end

  def serialize({:ref, obj_num, gen_num}) do
    [Integer.to_string(obj_num), " ", Integer.to_string(gen_num), " R"]
  end

  def serialize({:array, items}) when is_list(items) do
    inner = Enum.intersperse(Enum.map(items, &serialize/1), " ")
    ["[", inner, "]"]
  end

  def serialize({:dict, entries}) when is_list(entries) do
    inner =
      Enum.map(entries, fn {key, value} ->
        [serialize({:name, key}), " ", serialize(value)]
      end)

    ["<<\n", Enum.intersperse(inner, "\n"), "\n>>"]
  end

  def serialize({:stream, dict_entries, data}) when is_list(dict_entries) and is_binary(data) do
    entries_with_length = dict_entries ++ [{"Length", byte_size(data)}]

    [
      serialize({:dict, entries_with_length}),
      "\nstream\n",
      data,
      "\nendstream"
    ]
  end

  @spec indirect_object(non_neg_integer(), non_neg_integer(), iodata()) :: iodata()
  def indirect_object(obj_num, gen_num, content) do
    [
      Integer.to_string(obj_num),
      " ",
      Integer.to_string(gen_num),
      " obj\n",
      content,
      "\nendobj\n"
    ]
  end

  defp escape_string(str) do
    str
    |> String.replace("\\", "\\\\")
    |> String.replace("(", "\\(")
    |> String.replace(")", "\\)")
  end
end
