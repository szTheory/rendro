defmodule Rendro.Format do
  @moduledoc """
  Pure, deterministic, locale-free default formatter for the Statement recipe.

  `Rendro.Format` renders money, dates, and statement labels into stable strings
  that are **byte-identical across runs** regardless of the host's ambient locale,
  process dictionary, or system time zone. It deliberately takes **no** dependency
  on any locale-aware library (no CLDR, no message-translation framework, no
  currency-locale package): locale-aware formatting is runtime-locale-dependent
  and would break Rendro's deterministic output contract.

  This is the *default* applied to both caller-supplied amounts and the
  running/carried balances the recipe computes itself. Callers who need
  locale-aware or currency-specific output override the default from their own
  application via the recipe's escape hatch — wiring in their own currency/locale
  library without pulling that dependency into Rendro's core:

      Rendro.Recipes.Statement.document(data,
        formatters: [
          amount: fn %Decimal{} = d -> MyApp.Money.format(d) end,
          date: fn %Date{} = d -> MyApp.Locale.format_date(d) end
        ],
        labels: %{carried_forward: "Saldo a cuenta nueva"}
      )

  ## Default forms

    * Money: `$1,234.50`, thousands grouped with `,`, always 2 decimal places,
      negatives wrapped in parentheses (`($1,234.50)`) with no leading minus.
    * Dates: ISO 8601 `YYYY-MM-DD` via `Date.to_iso8601/1`.
    * Labels: the five default statement labels (see `label/1`).
  """

  @labels %{
    balance: "Balance",
    brought_forward: "Brought forward",
    carried_forward: "Carried forward",
    opening_balance: "Opening balance",
    closing_balance: "Closing balance"
  }

  @doc """
  Formats a `Decimal` money amount as a deterministic grouped currency string.

  The amount is rounded to 2 decimal places (half-up), the integer part is grouped
  into comma-separated thousands, prefixed with `$`, and negatives are wrapped in
  parentheses with no leading minus. The result is locale-independent and
  byte-identical across runs.

  ## Examples

      iex> Rendro.Format.money(Decimal.new("1234.5"))
      "$1,234.50"

      iex> Rendro.Format.money(Decimal.new("1234.567"))
      "$1,234.57"

      iex> Rendro.Format.money(Decimal.new("-1234.5"))
      "($1,234.50)"

      iex> Rendro.Format.money(Decimal.new("0"))
      "$0.00"

      iex> Rendro.Format.money(Decimal.new("1000000"))
      "$1,000,000.00"
  """
  @spec money(Decimal.t()) :: String.t()
  def money(%Decimal{} = amount) do
    rounded = Decimal.round(amount, 2)
    magnitude = "$" <> grouped(Decimal.abs(rounded))

    if Decimal.negative?(rounded) do
      "(" <> magnitude <> ")"
    else
      magnitude
    end
  end

  @doc """
  Formats a `Date` as an ISO 8601 `YYYY-MM-DD` string.

  Locale-independent (uses `Date.to_iso8601/1`) and byte-identical across runs.

  ## Examples

      iex> Rendro.Format.date(~D[2026-05-29])
      "2026-05-29"
  """
  @spec date(Date.t()) :: String.t()
  def date(%Date{} = date), do: Date.to_iso8601(date)

  @doc """
  Returns the default English label for a statement field.

  Supported keys: `:balance`, `:brought_forward`, `:carried_forward`,
  `:opening_balance`, `:closing_balance`.

  ## Examples

      iex> Rendro.Format.label(:carried_forward)
      "Carried forward"

      iex> Rendro.Format.label(:opening_balance)
      "Opening balance"
  """
  @spec label(
          :balance
          | :brought_forward
          | :carried_forward
          | :opening_balance
          | :closing_balance
        ) ::
          String.t()
  def label(key) when is_map_key(@labels, key), do: Map.fetch!(@labels, key)

  # Renders a non-negative, already-rounded Decimal to a fixed-2-dp string with
  # comma-grouped thousands in the integer part (e.g. "1,234.50").
  defp grouped(%Decimal{} = non_negative) do
    [int_part, frac_part] =
      non_negative
      |> Decimal.to_string(:normal)
      |> ensure_two_decimals()

    group_thousands(int_part) <> "." <> frac_part
  end

  # Decimal.round/2 guarantees a 2-dp scale, but Decimal.to_string/2 may drop a
  # trailing ".00" for whole values; normalize back to exactly two fractional
  # digits and split into [integer, fraction].
  defp ensure_two_decimals(string) do
    case String.split(string, ".") do
      [int_part] -> [int_part, "00"]
      [int_part, frac] -> [int_part, String.pad_trailing(String.slice(frac, 0, 2), 2, "0")]
    end
  end

  # Inserts a comma every three digits from the right of the integer string.
  defp group_thousands(int_part) do
    int_part
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.join/1)
    |> Enum.join(",")
    |> String.reverse()
  end
end
