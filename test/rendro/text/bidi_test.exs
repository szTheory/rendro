defmodule Rendro.Text.BidiTest do
  use ExUnit.Case, async: true
  alias Rendro.Text.Bidi

  describe "split_runs/1" do
    test "splits mixed Latin and Arabic text into distinct runs" do
      # "Hello " (Latin) + "مرحبا" (Arabic) + " World" (Latin)
      text = "Hello مرحبا World"

      runs = Bidi.split_runs(text)

      assert [
               %{text: "Hello ", script: :latn, direction: :ltr},
               %{text: "مرحبا", script: :arab, direction: :rtl},
               %{text: " World", script: :latn, direction: :ltr}
             ] = runs
    end

    test "handles pure Latin text as a single run" do
      runs = Bidi.split_runs("Just Latin")

      assert [
               %{text: "Just Latin", script: :latn, direction: :ltr}
             ] = runs
    end

    test "handles pure Arabic text as a single run" do
      runs = Bidi.split_runs("مرحبا")

      assert [
               %{text: "مرحبا", script: :arab, direction: :rtl}
             ] = runs
    end

    test "handles punctuation gracefully" do
      text = "Hello! مرحبا?"

      runs = Bidi.split_runs(text)

      assert [
               %{text: "Hello! ", script: :latn, direction: :ltr},
               %{text: "مرحبا?", script: :arab, direction: :rtl}
             ] = runs
    end
  end
end
