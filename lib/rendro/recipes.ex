defmodule Rendro.Recipes do
  @moduledoc """
  Canonical PDF recipes for standard document types.

  These recipes provide a starting point for common documents like
  invoices and reports, demonstrating best practices for layout
  and pagination.
  """

  @doc """
  Builds a standard invoice document.
  """
  def invoice(data) do
    # data: %{id: "...", items: [%{name: "...", qty: 1, price: 100}], ...}

    header = [
      Rendro.block(Rendro.text("INVOICE ##{data.id}", size: 18))
    ]

    table_rows =
      Enum.map(data.items, fn item ->
        [item.name, Integer.to_string(item.qty), "$#{item.price}"]
      end)

    table = Rendro.table(table_rows,
      header: ["Item", "Qty", "Price"],
      columns: [{:share, 1}, {:fixed, 50}, {:fixed, 80}]
    )

    footer = [
      Rendro.block(Rendro.text("Thank you for your business!", size: 10))
    ]

    Rendro.flow(
      [
        Rendro.block(Rendro.text("Date: #{data.date}")),
        Rendro.block(table)
      ],
      header: header,
      footer: footer
    )
  end
end
