defmodule Rendro.I18n.Analyzer do
  @moduledoc """
  Provides I18n script analysis capabilities to detect unsupported script boundaries,
  such as Right-To-Left (RTL) scripts and Complex Shaping scripts.
  """

  @type diagnostic :: %{type: :unsupported_script, reason: atom()}

  @doc """
  Analyzes text and returns a list of diagnostics for unsupported scripts.
  Returns maximum one of each diagnostic type per analysis call.
  """
  @spec analyze(String.t()) :: list(diagnostic)
  def analyze(text) when is_binary(text) do
    do_analyze(text, %{rtl: false, complex: false})
  end

  defp do_analyze(<<>>, state), do: to_diagnostics(state)

  # Optimization: if both found, short-circuit
  defp do_analyze(_, %{rtl: true, complex: true} = state), do: to_diagnostics(state)

  defp do_analyze(<<cp::utf8, rest::binary>>, state) do
    state
    |> check_rtl(cp)
    |> check_complex(cp)
    |> then(&do_analyze(rest, &1))
  end

  # RTL Ranges
  # Hebrew: 0x0590 - 0x05FF
  # Arabic: 0x0600 - 0x06FF, 0x0750 - 0x077F, 0x08A0 - 0x08FF, 0xFB50 - 0xFDFF, 0xFE70 - 0xFEFF
  defp check_rtl(%{rtl: true} = state, _cp), do: state
  defp check_rtl(state, cp) when cp >= 0x0590 and cp <= 0x05FF, do: %{state | rtl: true}
  defp check_rtl(state, cp) when cp >= 0x0600 and cp <= 0x06FF, do: %{state | rtl: true}
  defp check_rtl(state, cp) when cp >= 0x0750 and cp <= 0x077F, do: %{state | rtl: true}
  defp check_rtl(state, cp) when cp >= 0x08A0 and cp <= 0x08FF, do: %{state | rtl: true}
  defp check_rtl(state, cp) when cp >= 0xFB50 and cp <= 0xFDFF, do: %{state | rtl: true}
  defp check_rtl(state, cp) when cp >= 0xFE70 and cp <= 0xFEFF, do: %{state | rtl: true}
  defp check_rtl(state, _cp), do: state

  # Complex Shaping Ranges
  # Devanagari: 0x0900 - 0x097F
  # Thai: 0x0E00 - 0x0E7F
  # Khmer: 0x1780 - 0x17FF
  defp check_complex(%{complex: true} = state, _cp), do: state
  defp check_complex(state, cp) when cp >= 0x0900 and cp <= 0x097F, do: %{state | complex: true}
  defp check_complex(state, cp) when cp >= 0x0E00 and cp <= 0x0E7F, do: %{state | complex: true}
  defp check_complex(state, cp) when cp >= 0x1780 and cp <= 0x17FF, do: %{state | complex: true}
  defp check_complex(state, _cp), do: state

  defp to_diagnostics(%{rtl: rtl, complex: complex}) do
    []
    |> append_if(rtl, %{type: :unsupported_script, reason: :rtl_required})
    |> append_if(complex, %{type: :unsupported_script, reason: :complex_shaping_required})
  end

  defp append_if(list, true, item), do: [item | list]
  defp append_if(list, false, _item), do: list
end
