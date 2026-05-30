defmodule Rendro.Test.ComplexFonts do
  @moduledoc false

  # Since we are not checking in CJK fonts, we can use the branded B612 font
  # for basic tests, and mock the shaper for CJK/Arabic if needed.

  def b612_path do
    Path.join(:code.priv_dir(:rendro), "branded/fonts/B612-Regular.ttf")
  end

  def mock_cjk_path do
    # Just a placeholder path for tests that mock the file system or native calls
    "priv/test/mock_cjk.ttf"
  end

  def mock_arabic_path do
    "priv/test/mock_arabic.ttf"
  end
end
