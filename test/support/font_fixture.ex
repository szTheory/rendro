defmodule Rendro.TestSupport.FontFixture do
  @moduledoc false

  @candidate_paths [
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf",
    "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf",
    "/opt/homebrew/Library/Homebrew/vendor/portable-ruby/4.0.3/lib/ruby/gems/4.0.0/gems/rdoc-7.0.3/lib/rdoc/generator/template/darkfish/fonts/Lato-Regular.ttf",
    "/opt/homebrew/Library/Homebrew/vendor/portable-ruby/4.0.3/lib/ruby/gems/4.0.0/gems/rdoc-7.0.3/lib/rdoc/generator/template/darkfish/fonts/SourceCodePro-Regular.ttf",
    "/opt/homebrew/Cellar/tesseract/5.5.0/share/tessdata/pdf.ttf"
  ]

  @spec supported_font() :: %{path: Path.t(), bytes: binary()}
  def supported_font do
    case Enum.find(@candidate_paths, &File.exists?/1) do
      nil ->
        raise """
        no supported test font fixture found.
        looked in:
        #{Enum.map_join(@candidate_paths, "\n", &"  - #{&1}")}
        """

      path ->
        %{path: path, bytes: File.read!(path)}
    end
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
