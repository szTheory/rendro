defmodule Rendro.PDF.PNG do
  @moduledoc false

  def decode(binary) do
    <<137, 80, 78, 71, 13, 10, 26, 10, rest::binary>> = binary
    chunks = parse_chunks(rest, [])

    {"IHDR",
     <<width::32, height::32, bit_depth::8, color_type::8, comp::8, filter::8, interlace::8>>} =
      List.keyfind(chunks, "IHDR", 0)

    if interlace != 0 do
      {:error, :interlaced}
    else
      idat_data =
        chunks
        |> Enum.filter(fn {type, _} -> type == "IDAT" end)
        |> Enum.map(fn {_, data} -> data end)
        |> IO.iodata_to_binary()

      palette =
        case List.keyfind(chunks, "PLTE", 0) do
          nil -> nil
          {"PLTE", data} -> data
        end

      transparent =
        case List.keyfind(chunks, "tRNS", 0) do
          nil -> nil
          {"tRNS", data} -> data
        end

      {:ok,
       %{
         width: width,
         height: height,
         bit_depth: bit_depth,
         color_type: color_type,
         compression: comp,
         filter: filter,
         palette: palette,
         transparent: transparent,
         idat: idat_data
       }}
    end
  end

  def process_for_pdf(binary) do
    case decode(binary) do
      {:ok, png} ->
        color_space = get_color_space(png)

        if png.color_type in [0, 2, 3] do
          decode_parms = %{
            Predictor: 15,
            Colors: channels(png.color_type),
            BitsPerComponent: png.bit_depth,
            Columns: png.width
          }

          {:pass_through, png.idat, decode_parms, color_space}
        else
          pixels = decode_pixels(png)
          {color, alpha} = split_alpha(pixels, channels(png.color_type))
          {:split, :zlib.compress(color), :zlib.compress(alpha), color_space}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_color_space(%{color_type: 0}), do: {:name, "DeviceGray"}
  defp get_color_space(%{color_type: 4}), do: {:name, "DeviceGray"}
  defp get_color_space(%{color_type: 2}), do: {:name, "DeviceRGB"}
  defp get_color_space(%{color_type: 6}), do: {:name, "DeviceRGB"}

  defp get_color_space(%{color_type: 3, palette: palette}) do
    max_index = div(byte_size(palette), 3) - 1
    [:Indexed, {:name, "DeviceRGB"}, max_index, palette]
  end

  defp parse_chunks(<<>>, acc), do: Enum.reverse(acc)

  defp parse_chunks(
         <<length::32, type::binary-size(4), data::binary-size(length), _crc::32, rest::binary>>,
         acc
       ) do
    parse_chunks(rest, [{type, data} | acc])
  end

  def decode_pixels(png) do
    bpp = bytes_per_pixel(png.color_type, png.bit_depth)
    scanline_len = div(png.width * png.bit_depth * channels(png.color_type) + 7, 8)

    uncompressed = :zlib.uncompress(png.idat)

    unfilter_rows(
      uncompressed,
      png.height,
      bpp,
      scanline_len,
      :binary.copy(<<0>>, scanline_len),
      <<>>
    )
  end

  defp channels(0), do: 1
  defp channels(2), do: 3
  defp channels(3), do: 1
  defp channels(4), do: 2
  defp channels(6), do: 4

  defp bytes_per_pixel(color_type, bit_depth) do
    max(1, div(bit_depth * channels(color_type), 8))
  end

  defp unfilter_rows(<<>>, 0, _bpp, _len, _prev, acc), do: acc

  defp unfilter_rows(<<type::8, rest::binary>>, rows_left, bpp, len, prev_row, acc) do
    <<row::binary-size(len), next_rows::binary>> = rest
    unfiltered = apply_filter(type, row, prev_row, bpp, len)

    unfilter_rows(
      next_rows,
      rows_left - 1,
      bpp,
      len,
      unfiltered,
      <<acc::binary, unfiltered::binary>>
    )
  end

  defp apply_filter(0, row, _prev, _bpp, _len), do: row

  defp apply_filter(1, row, _prev, bpp, _len) do
    unfilter_sub(row, bpp, :binary.copy(<<0>>, bpp), <<>>)
  end

  defp apply_filter(2, row, prev, _bpp, _len) do
    unfilter_up(row, prev, <<>>)
  end

  defp apply_filter(3, row, prev, bpp, _len) do
    unfilter_avg(row, prev, bpp, :binary.copy(<<0>>, bpp), <<>>)
  end

  defp apply_filter(4, row, prev, bpp, _len) do
    unfilter_paeth(row, prev, bpp, :binary.copy(<<0>>, bpp), :binary.copy(<<0>>, bpp), <<>>)
  end

  defp unfilter_sub(<<>>, _bpp, _prev_bytes, acc), do: acc

  defp unfilter_sub(row_rest, bpp, prev_bytes, acc) do
    # extract 1 byte from row_rest
    <<x, rest::binary>> = row_rest
    <<prev_x, new_prev_bytes::binary>> = prev_bytes
    v = Integer.mod(x + prev_x, 256)
    unfilter_sub(rest, bpp, <<new_prev_bytes::binary, v>>, <<acc::binary, v>>)
  end

  defp unfilter_up(<<>>, <<>>, acc), do: acc

  defp unfilter_up(<<x, rest::binary>>, <<b, rest_b::binary>>, acc) do
    v = Integer.mod(x + b, 256)
    unfilter_up(rest, rest_b, <<acc::binary, v>>)
  end

  defp unfilter_avg(<<>>, <<>>, _bpp, _prev_bytes, acc), do: acc

  defp unfilter_avg(<<x, rest::binary>>, <<b, rest_b::binary>>, bpp, prev_bytes, acc) do
    <<prev_x, new_prev_bytes::binary>> = prev_bytes
    v = Integer.mod(x + div(prev_x + b, 2), 256)
    unfilter_avg(rest, rest_b, bpp, <<new_prev_bytes::binary, v>>, <<acc::binary, v>>)
  end

  defp unfilter_paeth(<<>>, <<>>, _bpp, _a_bytes, _c_bytes, acc), do: acc

  defp unfilter_paeth(<<x, rest::binary>>, <<b, rest_b::binary>>, bpp, a_bytes, c_bytes, acc) do
    <<a, new_a_bytes::binary>> = a_bytes
    <<c, new_c_bytes::binary>> = c_bytes

    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)

    pr =
      cond do
        pa <= pb and pa <= pc -> a
        pb <= pc -> b
        true -> c
      end

    v = Integer.mod(x + pr, 256)

    unfilter_paeth(
      rest,
      rest_b,
      bpp,
      <<new_a_bytes::binary, v>>,
      <<new_c_bytes::binary, b>>,
      <<acc::binary, v>>
    )
  end

  def split_alpha(pixels, channels) do
    color_bytes = channels - 1
    do_split_alpha(pixels, color_bytes, <<>>, <<>>)
  end

  defp do_split_alpha(<<>>, _color_bytes, color_acc, alpha_acc), do: {color_acc, alpha_acc}

  defp do_split_alpha(binary, color_bytes, color_acc, alpha_acc) do
    <<color::binary-size(color_bytes), alpha::8, rest::binary>> = binary

    do_split_alpha(
      rest,
      color_bytes,
      <<color_acc::binary, color::binary>>,
      <<alpha_acc::binary, alpha::8>>
    )
  end
end
