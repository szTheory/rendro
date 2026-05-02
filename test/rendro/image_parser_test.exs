defmodule Rendro.ImageParserTest do
  use ExUnit.Case, async: true
  alias Rendro.ImageParser

  # 2x2 PNG
  @png_bytes Base.decode64!(
               "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVQIW2NkYGD4z8DAwMgAI0AMADjKAu09+3WTAAAAAElFTkSuQmCC"
             )

  # 1x1 JPEG
  @jpeg_bytes Base.decode64!(
                "/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA="
              )

  describe "parse/1" do
    test "extracts width, height, and mime from valid PNG bytes" do
      assert {:ok, %{width: 2, height: 2, mime: "image/png"}} = ImageParser.parse(@png_bytes)
    end

    test "extracts width, height, and mime from valid JPEG bytes" do
      assert {:ok, %{width: 1, height: 1, mime: "image/jpeg"}} = ImageParser.parse(@jpeg_bytes)
    end

    test "returns error for invalid/unsupported bytes" do
      assert {:error, :unsupported_image_format} = ImageParser.parse(<<"invalid">>)
      assert {:error, :unsupported_image_format} = ImageParser.parse(<<0xFF, 0xD8, 0xFF, 0x00>>)
    end
  end
end
