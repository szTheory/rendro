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
    script_name = UnicodeData.Script.script_from_codepoint(cp)

    script_tag =
      if script_name in ["Common", "Inherited", "Unknown"] do
        :common
      else
        script_name |> UnicodeData.Script.script_to_tag() |> String.to_atom()
      end

    bidi_class = UnicodeData.Bidi.bidi_class(cp)

    direction =
      case bidi_class do
        "L" -> :ltr
        "R" -> :rtl
        "AL" -> :rtl
        _ -> :neutral
      end

    %{script: script_tag, direction: direction}
  end

  defp build_run(state, text) do
    script = if state.script == :common, do: :latn, else: state.script
    direction = if state.direction == :neutral, do: :ltr, else: state.direction

    %{text: text, script: script, direction: direction}
  end
end
