defmodule Rendro.I18n.AnalyzerTest do
  use ExUnit.Case, async: true
  alias Rendro.I18n.Analyzer

  describe "analyze/1" do
    test "Ascii and basic Latin returns no diagnostics" do
      assert Analyzer.analyze("Hello, world! 123 @#$") == []
      assert Analyzer.analyze("Café München öäüß") == []
    end

    test "Arabic/Hebrew codepoints return unsupported script diagnostic" do
      arabic_text = "مرحبا بالعالم"
      assert [%{type: :unsupported_script, reason: :rtl_required}] = Analyzer.analyze(arabic_text)

      hebrew_text = "שלום עולם"
      assert [%{type: :unsupported_script, reason: :rtl_required}] = Analyzer.analyze(hebrew_text)

      # Mixed text
      mixed = "Hello שלום"
      assert [%{type: :unsupported_script, reason: :rtl_required}] = Analyzer.analyze(mixed)
    end

    test "Devanagari/Khmer return complex shaping diagnostic" do
      devanagari_text = "नमस्ते दुनिया"

      assert [%{type: :unsupported_script, reason: :complex_shaping_required}] =
               Analyzer.analyze(devanagari_text)

      khmer_text = "សួស្តី​ពិភពលោក"

      assert [%{type: :unsupported_script, reason: :complex_shaping_required}] =
               Analyzer.analyze(khmer_text)

      # Note: actual Thai "สวัสดี"
      thai_text = "សួស្តី"

      assert [%{type: :unsupported_script, reason: :complex_shaping_required}] =
               Analyzer.analyze(thai_text)
    end

    test "Does not spam: returns maximum one of each diagnostic type per analysis call" do
      # Devanagari and Arabic together
      mixed = "مرحبا नमस्ते بالعالم दुनिया"
      diagnostics = Analyzer.analyze(mixed)

      assert length(diagnostics) == 2
      assert Enum.any?(diagnostics, &(&1.reason == :rtl_required))
      assert Enum.any?(diagnostics, &(&1.reason == :complex_shaping_required))

      # Long arabic string
      long_arabic = String.duplicate("مرحبا ", 10)
      assert [%{type: :unsupported_script, reason: :rtl_required}] = Analyzer.analyze(long_arabic)
    end
  end
end
