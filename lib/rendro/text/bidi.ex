defmodule Rendro.Text.Bidi do
  @moduledoc false

  @doc """
  Splits mixed string into distinct runs.
  """
  def split_runs(text) when is_binary(text) do
    do_split(text, nil, <<>>, <<>>, [])
  end

  defp do_split(<<>>, nil, _acc, <<>>, runs), do: Enum.reverse(runs)

  defp do_split(<<>>, nil, _acc, neutral_acc, runs) do
    # Pure neutral string defaults to Latin LTR
    state = %{script: :latn, direction: :ltr}
    Enum.reverse([build_run(state, neutral_acc) | runs])
  end

  defp do_split(<<>>, current_state, acc, neutral_acc, runs) do
    # At the end of the string, any trailing neutrals attach to the last strong run
    Enum.reverse([build_run(current_state, acc <> neutral_acc) | runs])
  end

  defp do_split(<<cp::utf8, rest::binary>>, current_state, acc, neutral_acc, runs) do
    char_state = resolve_state(cp)
    is_neutral = char_state.direction == :neutral or char_state.script == :common

    cond do
      current_state == nil ->
        if is_neutral do
          do_split(rest, nil, <<>>, neutral_acc <> <<cp::utf8>>, runs)
        else
          # First strong char found, attach preceding neutrals to it
          do_split(rest, char_state, neutral_acc <> <<cp::utf8>>, <<>>, runs)
        end

      is_neutral ->
        # Accumulate neutral chars separately
        do_split(rest, current_state, acc, neutral_acc <> <<cp::utf8>>, runs)

      char_state.script == current_state.script and
          char_state.direction == current_state.direction ->
        # Same strong state, flush neutrals into the accumulator and add the char
        do_split(rest, current_state, acc <> neutral_acc <> <<cp::utf8>>, <<>>, runs)

      true ->
        # State boundary (different strong states)
        # Rule for neutrals between different states based on paragraph direction preference (LTR):
        # If the new state is Latin (LTR), neutrals attach to the NEW state.
        # If the new state is Arabic (RTL), neutrals attach to the OLD state (Latin LTR).
        if char_state.script == :latn do
          # Neutrals go to the new state
          run = build_run(current_state, acc)
          do_split(rest, char_state, neutral_acc <> <<cp::utf8>>, <<>>, [run | runs])
        else
          # Neutrals go to the old state
          run = build_run(current_state, acc <> neutral_acc)
          do_split(rest, char_state, <<cp::utf8>>, <<>>, [run | runs])
        end
    end
  end

  defp resolve_state(cp) do
    script_atom = Unicode.script(cp)

    script_tag =
      if script_atom in [:common, :inherited, :unknown] do
        :common
      else
        to_opentype_tag(script_atom)
      end

    bidi_class = Unicode.BidiClass.bidi_class(cp)

    direction =
      case bidi_class do
        :l -> :ltr
        :r -> :rtl
        :al -> :rtl
        _ -> :neutral
      end

    %{script: script_tag, direction: direction}
  end

  defp build_run(state, text) do
    script = if state.script == :common, do: :latn, else: state.script
    direction = if state.direction == :neutral, do: :ltr, else: state.direction

    %{text: text, script: script, direction: direction}
  end

  # OpenType 4-letter script tag mapping from Unicode script atom names
  # Covers the 20 complex scripts gated in Shaper.Simple plus common supported scripts
  defp to_opentype_tag(:arabic), do: :arab
  defp to_opentype_tag(:syriac), do: :syrc
  defp to_opentype_tag(:nko), do: :nkoo
  defp to_opentype_tag(:mongolian), do: :mong
  defp to_opentype_tag(:hebrew), do: :hebr
  defp to_opentype_tag(:devanagari), do: :deva
  defp to_opentype_tag(:bengali), do: :beng
  defp to_opentype_tag(:gurmukhi), do: :guru
  defp to_opentype_tag(:gujarati), do: :gujr
  defp to_opentype_tag(:oriya), do: :orya
  defp to_opentype_tag(:tamil), do: :taml
  defp to_opentype_tag(:telugu), do: :telu
  defp to_opentype_tag(:kannada), do: :knda
  defp to_opentype_tag(:malayalam), do: :mlym
  defp to_opentype_tag(:sinhala), do: :sinh
  defp to_opentype_tag(:thai), do: :thai
  defp to_opentype_tag(:lao), do: :laoo
  defp to_opentype_tag(:khmer), do: :khmr
  defp to_opentype_tag(:myanmar), do: :mymr
  defp to_opentype_tag(:tibetan), do: :tibt
  defp to_opentype_tag(:latin), do: :latn
  defp to_opentype_tag(:greek), do: :grek
  defp to_opentype_tag(:cyrillic), do: :cyrl
  defp to_opentype_tag(:armenian), do: :armn
  defp to_opentype_tag(:georgian), do: :geor
  defp to_opentype_tag(:han), do: :hani
  defp to_opentype_tag(:hiragana), do: :hira
  defp to_opentype_tag(:katakana), do: :kana
  defp to_opentype_tag(:hangul), do: :hang
  defp to_opentype_tag(:bopomofo), do: :bopo
  defp to_opentype_tag(:cherokee), do: :cher
  defp to_opentype_tag(:ethiopic), do: :ethi
  defp to_opentype_tag(:gothic), do: :goth
  defp to_opentype_tag(:runic), do: :runr
  defp to_opentype_tag(:khojki), do: :khoj
  defp to_opentype_tag(:old_italic), do: :ital
  defp to_opentype_tag(:ogham), do: :ogam
  defp to_opentype_tag(:old_turkic), do: :otk
  defp to_opentype_tag(:rejang), do: :rjng
  defp to_opentype_tag(:shavian), do: :shaw
  defp to_opentype_tag(:sundanese), do: :sund
  defp to_opentype_tag(:syloti_nagri), do: :sylo
  defp to_opentype_tag(:tagalog), do: :tglg
  defp to_opentype_tag(:tagbanwa), do: :tagb
  defp to_opentype_tag(:tai_le), do: :tale
  defp to_opentype_tag(:yi), do: :yiii
  defp to_opentype_tag(:old_persian), do: :xpeo
  # Fallback: pass atom through unchanged
  defp to_opentype_tag(script), do: script
end
