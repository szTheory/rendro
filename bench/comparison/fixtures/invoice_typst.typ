#let fixture_id = "invoice_v1"
#let data_path = sys.inputs.at("data-path", default: "invoice_data.json")
#let data = json(data_path)

= Invoice #data.invoice.id

*Fixture:* #fixture_id \
*Date:* #data.invoice.date \
*Issuer:* #data.issuer.name \
*Customer:* #data.customer.name

#table(
  columns: (1fr, 2fr, auto, auto),
  inset: 5pt,
  stroke: 0.5pt + rgb("#d1d5db"),
  [Item], [Description], [Qty], [Price],
  ..data.items.map(item => (
    [#item.name],
    [#item.description],
    [#item.qty],
    [#str(item.price_cents / 100)],
  )).flatten()
)

Total: #str(data.totals.total_cents / 100)
