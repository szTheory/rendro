defmodule Rendro.Text.ScriptTagsTest do
  use ExUnit.Case, async: true

  alias Rendro.Text.ScriptTags

  describe "to_opentype_tag/1" do
    test "maps :arabic to :arab" do
      assert ScriptTags.to_opentype_tag(:arabic) == :arab
    end

    test "maps :latin to :latn" do
      assert ScriptTags.to_opentype_tag(:latin) == :latn
    end

    test "maps :hebrew to :hebr" do
      assert ScriptTags.to_opentype_tag(:hebrew) == :hebr
    end

    test "maps :devanagari to :deva" do
      assert ScriptTags.to_opentype_tag(:devanagari) == :deva
    end

    test "maps :thai to :thai" do
      assert ScriptTags.to_opentype_tag(:thai) == :thai
    end

    test "maps :greek to :grek" do
      assert ScriptTags.to_opentype_tag(:greek) == :grek
    end

    test "maps :cyrillic to :cyrl" do
      assert ScriptTags.to_opentype_tag(:cyrillic) == :cyrl
    end

    test "maps :han to :hani" do
      assert ScriptTags.to_opentype_tag(:han) == :hani
    end

    test "maps :hiragana to :hira" do
      assert ScriptTags.to_opentype_tag(:hiragana) == :hira
    end

    test "maps :katakana to :kana" do
      assert ScriptTags.to_opentype_tag(:katakana) == :kana
    end

    test "maps :hangul to :hang" do
      assert ScriptTags.to_opentype_tag(:hangul) == :hang
    end

    test "maps :syriac to :syrc" do
      assert ScriptTags.to_opentype_tag(:syriac) == :syrc
    end

    test "maps :nko to :nkoo" do
      assert ScriptTags.to_opentype_tag(:nko) == :nkoo
    end

    test "maps :mongolian to :mong" do
      assert ScriptTags.to_opentype_tag(:mongolian) == :mong
    end

    test "maps :bengali to :beng" do
      assert ScriptTags.to_opentype_tag(:bengali) == :beng
    end

    test "maps :gurmukhi to :guru" do
      assert ScriptTags.to_opentype_tag(:gurmukhi) == :guru
    end

    test "maps :gujarati to :gujr" do
      assert ScriptTags.to_opentype_tag(:gujarati) == :gujr
    end

    test "maps :oriya to :orya" do
      assert ScriptTags.to_opentype_tag(:oriya) == :orya
    end

    test "maps :tamil to :taml" do
      assert ScriptTags.to_opentype_tag(:tamil) == :taml
    end

    test "maps :telugu to :telu" do
      assert ScriptTags.to_opentype_tag(:telugu) == :telu
    end

    test "maps :kannada to :knda" do
      assert ScriptTags.to_opentype_tag(:kannada) == :knda
    end

    test "maps :malayalam to :mlym" do
      assert ScriptTags.to_opentype_tag(:malayalam) == :mlym
    end

    test "maps :sinhala to :sinh" do
      assert ScriptTags.to_opentype_tag(:sinhala) == :sinh
    end

    test "maps :lao to :laoo" do
      assert ScriptTags.to_opentype_tag(:lao) == :laoo
    end

    test "maps :khmer to :khmr" do
      assert ScriptTags.to_opentype_tag(:khmer) == :khmr
    end

    test "maps :myanmar to :mymr" do
      assert ScriptTags.to_opentype_tag(:myanmar) == :mymr
    end

    test "maps :tibetan to :tibt" do
      assert ScriptTags.to_opentype_tag(:tibetan) == :tibt
    end

    test "passes through unknown script atoms unchanged (fallback)" do
      assert ScriptTags.to_opentype_tag(:unknown_script) == :unknown_script
      assert ScriptTags.to_opentype_tag(:some_made_up_script) == :some_made_up_script
    end
  end
end
