defmodule PngTest do
  def test do
    bytes = File.read!("priv/branded/images/rendro-logo.png")
    <<137, 80, 78, 71, 13, 10, 26, 10, rest::binary>> = bytes
    IO.inspect(parse_chunks(rest, []))
  end

  def parse_chunks(<<>>, acc), do: Enum.reverse(acc)
  def parse_chunks(<<length::32, type::binary-size(4), data::binary-size(length), crc::32, rest::binary>>, acc) do
    parse_chunks(rest, [{type, length} | acc])
  end
end
PngTest.test()
