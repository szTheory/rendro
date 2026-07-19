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
  # Money is coerced with `Decimal.new/1` so cents are preserved exactly —
  # never a lossy float/integer coercion (118-08 gap-closure: the invoice
  # money path used to route the legacy line `:price` through
  # `Decimal.to_float/1` to satisfy `Rendro.Recipes.Invoice.validate_data!/1`'s
  # historical is_number-only guard, which produced the `$79.0` one-decimal
  # money defect. The Invoice recipe's legacy `:price` slot now also accepts
  # `%Decimal{}` (rendered via `Rendro.Format.money/1` for faithful 2-decimal
  # cents), so this module never needs `Decimal.to_float/1` or
  # `Decimal.to_integer/1` anywhere on the invoice money path.)
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

    base = %{
      id: invoice["id"],
      date: date(invoice["date"]),
      items:
        Enum.map(data["items"], fn item ->
          %{
            name: "#{item["name"]} - #{item["description"]}",
            qty: item["qty"],
            # 118-08 gap-closure: legacy line :price is now a faithful
            # Decimal (never Decimal.to_float/1 or Decimal.to_integer/1) —
            # Rendro.Recipes.Invoice's legacy price slot accepts %Decimal{}
            # and formats it via Rendro.Format.money/1 for exact 2-decimal
            # cents (fixes the `$79.0` one-decimal money defect).
            price: money(item["price"])
          }
        end)
    }

    base
    |> put_optional(:issuer, data["issuer"], &transform_party/1)
    |> put_optional(:customer, data["customer"], &transform_party/1)
    |> put_optional(:due_date, invoice["due_date"], &date/1)
    |> put_optional(:terms, invoice["terms"], & &1)
    |> put_optional(:totals, data["totals"], &transform_totals/1)
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

    base =
      base
      # 118-08 gap-closure: thread the merchant identity fixture -> transform
      # -> recipe (previously absent from the data path entirely).
      |> put_optional(:merchant, data["merchant"], &transform_party/1)

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

  # Shared party transform (118-08) — invoice :issuer/:customer and receipt
  # :merchant all share the same `priv/schemas/examples.schema.json`
  # `$defs/party` shape (name + optional street/city/region/postal_code).
  # Produces the `%{name:, address:}` shape the recipes' issuer_block/
  # customer_block/merchant renderers already expect.
  defp transform_party(party) do
    %{name: party["name"], address: format_address(party)}
  end

  defp format_address(party) do
    [party["street"], city_line(party)]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(", ")
  end

  defp city_line(party) do
    [party["city"], region_postal(party)]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(", ")
  end

  defp region_postal(party) do
    [party["region"], party["postal_code"]]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
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

  defp date(str) when is_binary(str), do: Date.from_iso8601!(str)

  defp put_optional(map, _key, nil, _fun), do: map
  defp put_optional(map, key, value, fun), do: Map.put(map, key, fun.(value))
end
