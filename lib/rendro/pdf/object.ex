defmodule Rendro.PDF.Object do
  @moduledoc false

  @type ref :: {non_neg_integer(), non_neg_integer()}

  @type serialize_opts :: [deterministic: boolean()]

  @spec serialize(term()) :: iodata()
  def serialize(value), do: serialize(value, [])

  @spec serialize(term(), serialize_opts()) :: iodata()
  def serialize(value, _opts) when is_integer(value), do: Integer.to_string(value)

  def serialize(value, _opts) when is_float(value),
    do: :erlang.float_to_binary(value, decimals: 4)

  def serialize(true, _opts), do: "true"
  def serialize(false, _opts), do: "false"
  def serialize(nil, _opts), do: "null"

  def serialize({:name, name}, _opts) when is_binary(name), do: ["/", name]

  def serialize({:string, str}, _opts) when is_binary(str) do
    ["(", escape_string(str), ")"]
  end

  def serialize({:hex_string, str}, _opts) when is_binary(str) do
    ["<", Base.encode16(str), ">"]
  end

  def serialize({:ref, obj_num, gen_num}, _opts) do
    [Integer.to_string(obj_num), " ", Integer.to_string(gen_num), " R"]
  end

  def serialize({:array, items}, opts) when is_list(items) do
    inner = Enum.intersperse(Enum.map(items, &serialize(&1, opts)), " ")
    ["[", inner, "]"]
  end

  def serialize({:dict, entries}, opts) when is_list(entries) do
    sorted =
      if Keyword.get(opts, :deterministic, false),
        do: Enum.sort_by(entries, fn {key, _} -> key end),
        else: entries

    inner =
      Enum.map(sorted, fn {key, value} ->
        [serialize({:name, key}, opts), " ", serialize(value, opts)]
      end)

    ["<<\n", Enum.intersperse(inner, "\n"), "\n>>"]
  end

  def serialize({:stream, dict_entries, data}, opts)
      when is_list(dict_entries) and is_binary(data) do
    entries_with_length = dict_entries ++ [{"Length", byte_size(data)}]

    [
      serialize({:dict, entries_with_length}, opts),
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

  @doc "Serialize a value and wrap it in an indirect object."
  @spec indirect_object(non_neg_integer(), non_neg_integer(), term(), serialize_opts()) ::
          iodata()
  def indirect_object(obj_num, gen_num, {:raw, content}, _opts) do
    indirect_object(obj_num, gen_num, content)
  end

  def indirect_object(obj_num, gen_num, value, opts) do
    indirect_object(obj_num, gen_num, serialize(value, opts))
  end

  defp escape_string(str) do
    str
    |> String.replace("\\", "\\\\")
    |> String.replace("(", "\\(")
    |> String.replace(")", "\\)")
  end
end
