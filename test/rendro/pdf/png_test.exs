defmodule Rendro.PDF.PNGTest do
  use ExUnit.Case
  alias Rendro.PDF.PNG

  # Helpers to build PNG chunks
  defp build_chunk(type, data) do
    length = byte_size(data)
    crc = :erlang.crc32(type <> data)
    <<length::32, type::binary, data::binary, crc::32>>
  end

  defp build_png(ihdr, chunks) do
    magic = <<137, 80, 78, 71, 13, 10, 26, 10>>
    ihdr_chunk = build_chunk("IHDR", ihdr)
    iend_chunk = build_chunk("IEND", <<>>)

    encoded_chunks = Enum.map(chunks, fn {type, data} -> build_chunk(type, data) end)

    Enum.join([magic, ihdr_chunk | encoded_chunks] ++ [iend_chunk])
  end

  describe "decode/1 and process_for_pdf/1" do
    test "Test 1: Returns {:error, :interlaced} for a PNG with interlace=1" do
      # IHDR: width=1, height=1, bit_depth=8, color_type=2, comp=0, filter=0, interlace=1
      ihdr = <<1::32, 1::32, 8::8, 2::8, 0::8, 0::8, 1::8>>
      png = build_png(ihdr, [{"IDAT", <<>>}])

      assert PNG.decode(png) == {:error, :interlaced}
      assert PNG.process_for_pdf(png) == {:error, :interlaced}
    end

    test "Test 2: For RGB PNG, returns {:pass_through, idat, parms, {:name, \"DeviceRGB\"}}" do
      ihdr = <<1::32, 1::32, 8::8, 2::8, 0::8, 0::8, 0::8>>
      # filter=0, RGB=255,0,0
      idat_data = :zlib.compress(<<0, 255, 0, 0>>)
      png = build_png(ihdr, [{"IDAT", idat_data}])

      assert {:pass_through, idat, parms, cs} = PNG.process_for_pdf(png)
      assert idat == idat_data
      assert parms == %{Predictor: 15, Colors: 3, BitsPerComponent: 8, Columns: 1}
      assert cs == {:name, "DeviceRGB"}
    end

    test "Test 3: For RGBA PNG, returns {:split, color, alpha, {:name, \"DeviceRGB\"}}" do
      ihdr = <<1::32, 1::32, 8::8, 6::8, 0::8, 0::8, 0::8>>
      # filter=0, RGBA=255,0,0,128
      idat_data = :zlib.compress(<<0, 255, 0, 0, 128>>)
      png = build_png(ihdr, [{"IDAT", idat_data}])

      assert {:split, color, alpha, cs} = PNG.process_for_pdf(png)

      # Uncompress to check separated values
      assert :zlib.uncompress(color) == <<255, 0, 0>>
      assert :zlib.uncompress(alpha) == <<128>>
      assert cs == {:name, "DeviceRGB"}
    end

    test "Test 4: For Indexed PNG, returns {:pass_through, idat, parms, [:Indexed, {:name, \"DeviceRGB\"}, n, palette]}" do
      ihdr = <<1::32, 1::32, 8::8, 3::8, 0::8, 0::8, 0::8>>
      # filter=0, index=0
      idat_data = :zlib.compress(<<0, 0>>)
      # Two colors: red, green
      palette = <<255, 0, 0, 0, 255, 0>>
      png = build_png(ihdr, [{"PLTE", palette}, {"IDAT", idat_data}])

      assert {:pass_through, idat, parms, cs} = PNG.process_for_pdf(png)
      assert idat == idat_data
      assert parms == %{Predictor: 15, Colors: 1, BitsPerComponent: 8, Columns: 1}
      assert cs == [:Indexed, {:name, "DeviceRGB"}, 1, palette]
    end
  end
end
