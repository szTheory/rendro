defmodule Rendro.RenderLogo do
  @moduledoc false

  @output_path "priv/branded/images/rendro-logo.png"
  @size 64
  @background <<13, 71, 76, 255>>
  @foreground <<240, 240, 240, 255>>
  @accent <<245, 166, 35, 255>>

  def run do
    File.mkdir_p!(Path.dirname(@output_path))
    File.write!(@output_path, png())
    IO.puts("Wrote #{@output_path} (#{byte_size(png())} bytes)")
  end

  defp png do
    <<137, 80, 78, 71, 13, 10, 26, 10>> <>
      chunk("IHDR", <<@size::32, @size::32, 8, 6, 0, 0, 0>>) <>
      chunk("IDAT", :zlib.compress(pixels())) <>
      chunk("IEND", <<>>)
  end

  defp pixels do
    for y <- 0..(@size - 1), into: <<>> do
      row =
        for x <- 0..(@size - 1), into: <<>> do
          pixel(x, y)
        end

      <<0>> <> row
    end
  end

  defp pixel(x, y) do
    dx = x - 31.5
    dy = y - 31.5
    distance = dx * dx + dy * dy

    cond do
      distance <= 17 * 17 -> @accent
      distance <= 25 * 25 -> @foreground
      true -> @background
    end
  end

  defp chunk(type, data) when byte_size(type) == 4 do
    crc = :erlang.crc32(type <> data)
    <<byte_size(data)::32, type::binary, data::binary, crc::32>>
  end
end

unless Code.ensure_loaded?(ExUnit.Server) and Process.whereis(ExUnit.Server) do
  Rendro.RenderLogo.run()
end
