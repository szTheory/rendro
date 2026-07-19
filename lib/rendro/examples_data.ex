defmodule Rendro.ExamplesData do
  @moduledoc false

  # Faithful JSON->recipe transform layer (D-06 single data source).
  #
  # `Rendro.Examples.load!/1` returns raw string-keyed JSON where money is a
  # decimal string and dates are ISO-8601 strings. Every recipe's `document/2`
  # instead consumes an atom-keyed map with `Decimal.t()` money and `Date.t()`
  # dates. This module is the one-source-of-truth seam both the demonstration
  # set (SHOW-01) and the gallery (SHOW-03) render through.
  #
  # Money is coerced with `Decimal.new/1` so cents are preserved (never the
  # lossy integer coercion the bench script uses, INV-02). The one exception is
  # the Invoice recipe's legacy line `:price`, which its `validate_data!/1`
  # requires to be a bare number (Decimal is explicitly rejected for byte-compat
  # with the toy call, INV-02's split); there we coerce via `Decimal.to_float/1`
  # so cents are still preserved.
  #
  # Callers pass the loaded map; this module never reads files directly (the
  # `Path.safe_relative/1` guard lives in `Rendro.Examples.load!/1`).

  @doc false
  @spec transform(atom(), map()) :: map()
  def transform(:invoice, data), do: transform_invoice(data)
  def transform(:statement, data), do: transform_statement(data)
  def transform(:receipt, data), do: transform_receipt(data)
  def transform(:certificate, data), do: transform_certificate(data)
  def transform(:payslip, data), do: transform_payslip(data)
  def transform(:ticket, data), do: transform_ticket(data)

  @doc false
  @spec transform_invoice(map()) :: map()
  def transform_invoice(data) do
    invoice = Map.fetch!(data, "invoice")

    %{
      id: invoice["id"],
      date: date(invoice["date"]),
      items:
        Enum.map(data["items"], fn item ->
          %{
            name: "#{item["name"]} - #{item["description"]}",
            qty: item["qty"],
            # Legacy bare-number price (INV-02): faithful cents via to_float,
            # never Decimal (rejected) nor a lossy integer coercion.
            price: bare_money(item["price"])
          }
        end)
    }
  end

  @doc false
  @spec transform_statement(map()) :: map()
  def transform_statement(data) do
    base = %{
      period: %{
        from: date(data["period"]["from"]),
        to: date(data["period"]["to"])
      },
      account: %{name: data["account"]["name"]},
      opening_balance: money(data["opening_balance"]),
      lines:
        Enum.map(data["lines"], fn line ->
          %{
            date: date(line["date"]),
            description: line["description"],
            amount: money(line["amount"])
          }
        end)
    }

    base
    |> put_optional(:closing_balance, data["closing_balance"], &money/1)
    |> put_optional(:summary, data["summary"], & &1)
  end

  @doc false
  @spec transform_receipt(map()) :: map()
  def transform_receipt(data) do
    base = %{
      title: data["title"],
      date: date(data["date"]),
      customer: %{name: data["customer"]["name"]},
      lines:
        Enum.map(data["lines"], fn line ->
          %{
            description: line["description"],
            amount: money(line["amount"])
          }
        end)
    }

    case data["totals"] do
      totals when is_map(totals) -> Map.put(base, :totals, transform_totals(totals))
      _ -> base
    end
  end

  @doc false
  @spec transform_certificate(map()) :: map()
  def transform_certificate(data) do
    # Note: the empty S4 `brand: %{logo: nil}` slot is intentionally dropped —
    # Certificate.validate_data!/1 rejects that shape (it only accepts nil or a
    # fully-populated %{font_name:, logo_name:}). Render with `border: true`.
    base = %{
      title: data["title"],
      recipient: data["recipient"],
      date: date(data["date"])
    }

    base
    |> put_optional(:body, data["body"], & &1)
    |> put_optional(:seal_line, data["seal_line"], & &1)
  end

  @doc false
  @spec transform_payslip(map()) :: map()
  def transform_payslip(data) do
    base = %{
      employer: %{
        name: data["employer"]["name"],
        address: data["employer"]["address"]
      },
      employee: %{
        name: data["employee"]["name"],
        id: data["employee"]["id"],
        tax_code: data["employee"]["tax_code"]
      },
      period: %{
        from: date(data["period"]["from"]),
        to: date(data["period"]["to"])
      },
      pay_date: date(data["pay_date"]),
      earnings: Enum.map(data["earnings"], &transform_pay_line/1),
      deductions: Enum.map(data["deductions"], &transform_pay_line/1),
      net_pay: money(data["net_pay"])
    }

    put_optional(base, :payment_method, data["payment_method"], & &1)
  end

  @doc false
  @spec transform_ticket(map()) :: map()
  def transform_ticket(data) do
    # Strings only. Pass the human-readable `code.reference`; do NOT synthesize a
    # `code.image` (no caller-supplied ticket-code asset in the shipped fixture).
    base = %{
      issuer: transform_ticket_issuer(data["issuer"]),
      title: data["title"],
      placement:
        Enum.map(data["placement"], fn entry ->
          %{label: entry["label"], value: entry["value"]}
        end),
      code: %{reference: data["code"]["reference"]}
    }

    base
    |> put_optional(:subtitle, data["subtitle"], & &1)
    |> put_optional(:terms, data["terms"], & &1)
  end

  # --- helpers -------------------------------------------------------------

  defp transform_pay_line(line) do
    %{
      description: line["description"],
      amount: money(line["amount"]),
      ytd: money(line["ytd"])
    }
  end

  defp transform_ticket_issuer(issuer) do
    base = %{name: issuer["name"]}
    put_optional(base, :venue, issuer["venue"], & &1)
  end

  defp transform_totals(totals) do
    %{}
    |> put_optional(:subtotal, totals["subtotal"], &money/1)
    |> put_optional(:tax, totals["tax"], &money/1)
    |> put_optional(:discount, totals["discount"], &money/1)
    |> put_optional(:total, totals["total"], &money/1)
  end

  # Faithful Decimal money — preserves cents.
  defp money(nil), do: nil
  defp money(str) when is_binary(str), do: Decimal.new(str)

  # Invoice-only legacy bare-number price: Decimal.to_float preserves cents
  # (unlike the lossy integer coercion) while satisfying the is_number guard.
  defp bare_money(str) when is_binary(str), do: str |> Decimal.new() |> Decimal.to_float()

  defp date(str) when is_binary(str), do: Date.from_iso8601!(str)

  defp put_optional(map, _key, nil, _fun), do: map
  defp put_optional(map, key, value, fun), do: Map.put(map, key, fun.(value))
end
