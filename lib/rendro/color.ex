defmodule Rendro.Color do
  @moduledoc false

  @doc """
  Returns the PDF `rg` (fill color) operator string for the given RGB tuple.

  ## Example

      iex> Rendro.Color.rg({255, 128, 0})
      "1.0000 0.5020 0.0000 rg\\n"

  """
  @spec rg({non_neg_integer(), non_neg_integer(), non_neg_integer()}) :: String.t()
  def rg({r, g, b}) do
    "#{format_num(r / 255)} #{format_num(g / 255)} #{format_num(b / 255)} rg\n"
  end

  @doc """
  Returns the PDF `RG` (stroke color) operator string for the given RGB tuple.

  ## Example

      iex> Rendro.Color.rg_stroke({255, 0, 0})
      "1.0000 0.0000 0.0000 RG\\n"

  """
  @spec rg_stroke({non_neg_integer(), non_neg_integer(), non_neg_integer()}) :: String.t()
  def rg_stroke({r, g, b}) do
    "#{format_num(r / 255)} #{format_num(g / 255)} #{format_num(b / 255)} RG\n"
  end

  @doc """
  Returns the PDF color components as a tuple of floats in the range 0.0–1.0.

  ## Example

      iex> Rendro.Color.to_pdf_components({255, 128, 0})
      {1.0, 0.5019607843137255, 0.0}

  """
  @spec to_pdf_components({non_neg_integer(), non_neg_integer(), non_neg_integer()}) ::
          {float(), float(), float()}
  def to_pdf_components({r, g, b}) do
    {r / 255, g / 255, b / 255}
  end

  @doc """
  Validates that the given value is an RGB color tuple with integer components in 0–255.

  Returns `:ok` on success, or `{:error, reason}` with a descriptive message otherwise.

  The error message always mentions "hex" to warn about the common footgun of passing
  a hex string like `"#000"` where a `{r, g, b}` tuple is required.

  ## Examples

      iex> Rendro.Color.validate({0, 0, 0})
      :ok

      iex> Rendro.Color.validate({255, 255, 255})
      :ok

      iex> Rendro.Color.validate("#000")
      {:error, "..."}

  """
  @spec validate(term()) :: :ok | {:error, String.t()}
  def validate({r, g, b})
      when is_integer(r) and is_integer(g) and is_integer(b) and
             r >= 0 and r <= 255 and
             g >= 0 and g <= 255 and
             b >= 0 and b <= 255 do
    :ok
  end

  def validate(value) do
    reason = build_error_message(value)
    {:error, reason}
  end

  # Private

  defp build_error_message(value) do
    what = "Invalid color value."
    where = "Rendro.Color.validate/1"

    why =
      cond do
        is_binary(value) ->
          "Got a hex string #{inspect(value)}. Rendro uses {r, g, b} integer tuples (0–255), never hex strings."

        is_atom(value) ->
          "Got an atom #{inspect(value)}. Rendro uses {r, g, b} integer tuples (0–255), not named color atoms."

        is_tuple(value) and tuple_size(value) != 3 ->
          "Got a tuple of size #{tuple_size(value)}. Rendro requires exactly {r, g, b} — a 3-element tuple."

        is_tuple(value) and tuple_size(value) == 3 ->
          {r, g, b} = value
          bad = Enum.reject([{"r", r}, {"g", g}, {"b", b}], fn {_, v} -> is_integer(v) && v >= 0 && v <= 255 end)
          bad_desc = Enum.map_join(bad, ", ", fn {label, v} ->
            cond do
              is_float(v) -> "#{label}=#{inspect(v)} (float, must be integer)"
              is_integer(v) -> "#{label}=#{inspect(v)} (out of range 0–255)"
              true -> "#{label}=#{inspect(v)} (not an integer)"
            end
          end)
          "Got #{inspect(value)} with invalid component(s): #{bad_desc}."

        true ->
          "Got #{inspect(value)}. Expected a {r, g, b} integer tuple."
      end

    next =
      "Provide a 3-element tuple of integers in 0–255 range, e.g. {0, 0, 0} for black or {255, 255, 255} for white. " <>
        "To convert a hex color: \"#2C6BED\" → {44, 107, 237}."

    """
    #{what}

    What:  #{what}
    Where: #{where}
    Why:   #{why}
    Next:  #{next}
    """
  end

  # Verbatim copy of format_num/1 from lib/rendro/pdf/writer.ex:1758-1762
  defp format_num(n) when is_integer(n), do: Integer.to_string(n)

  defp format_num(n) when is_float(n) do
    :erlang.float_to_binary(n * 1.0, decimals: 4)
  end
end
