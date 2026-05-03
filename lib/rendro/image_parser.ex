defmodule Rendro.ImageParser do
  @moduledoc false

  @png_signature <<137, 80, 78, 71, 13, 10, 26, 10>>
  @jpeg_signature <<0xFF, 0xD8>>

  @sof_markers [
    0xC0,
    0xC1,
    0xC2,
    0xC3,
    0xC5,
    0xC6,
    0xC7,
    0xC9,
    0xCA,
    0xCB,
    0xCD,
    0xCE,
    0xCF
  ]

  @spec parse(binary()) ::
          {:ok, %{width: pos_integer(), height: pos_integer(), mime: String.t()}}
          | {:error, term()}
  def parse(
        <<@png_signature, _length::32, "IHDR", width::32, height::32, bit_depth::8, color_type::8,
          _comp::8, _filter::8, interlace::8, _crc::32, _rest::binary>>
      ) do
    {:ok,
     %{
       width: width,
       height: height,
       mime: "image/png",
       bit_depth: bit_depth,
       color_type: color_type,
       interlace: interlace
     }}
  end

  def parse(<<@jpeg_signature, rest::binary>>) do
    parse_jpeg_markers(rest)
  end

  def parse(_bytes) do
    {:error, :unsupported_image_format}
  end

  defp parse_jpeg_markers(<<0xFF, 0xFF, rest::binary>>) do
    parse_jpeg_markers(<<0xFF, rest::binary>>)
  end

  defp parse_jpeg_markers(<<0xFF, marker, length::16, rest::binary>>)
       when marker not in [0x00, 0xFF, 0xD8, 0xD9] do
    if marker in @sof_markers do
      <<_precision::8, height::16, width::16, _::binary>> = rest
      {:ok, %{width: width, height: height, mime: "image/jpeg"}}
    else
      chunk_data_len = length - 2

      case rest do
        <<_skip::binary-size(chunk_data_len), next::binary>> ->
          parse_jpeg_markers(next)

        _ ->
          {:error, :unsupported_image_format}
      end
    end
  end

  defp parse_jpeg_markers(_) do
    {:error, :unsupported_image_format}
  end
end
