defmodule Rendro.TestSupport.FontFixture do
  @moduledoc false

  @spec supported_font() :: %{path: Path.t(), bytes: binary()}
  def supported_font do
    path = Path.join(:code.priv_dir(:rendro), "branded/fonts/B612-Regular.ttf")
    %{path: path, bytes: File.read!(path)}
  end

  @spec restricted_font(binary()) :: binary()
  def restricted_font(bytes) when is_binary(bytes) do
    case table_range(bytes, "OS/2") do
      {:ok, offset, length} when length >= 10 ->
        <<prefix::binary-size(offset + 8), _existing::16, suffix::binary>> = bytes
        prefix <> <<0x0002::16>> <> suffix

      _ ->
        raise "test font fixture is missing a writable OS/2 table"
    end
  end

  defp table_range(
         <<_version::binary-size(4), num_tables::16, _search_range::16, _entry_selector::16,
           _range_shift::16, directory::binary>>,
         tag
       ) do
    directory
    |> binary_part(0, num_tables * 16)
    |> find_table(tag)
  end

  defp table_range(_bytes, _tag), do: :error

  defp find_table(<<>>, _tag), do: :error

  defp find_table(
         <<current_tag::binary-size(4), _checksum::32, offset::32, length::32, rest::binary>>,
         tag
       ) do
    if current_tag == tag do
      {:ok, offset, length}
    else
      find_table(rest, tag)
    end
  end
end
