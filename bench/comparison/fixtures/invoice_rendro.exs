fixture_id = "invoice_v1"
data = "bench/comparison/fixtures/invoice_data.json" |> File.read!() |> JSON.decode!()

unless data["fixture_id"] == fixture_id do
  raise "expected #{fixture_id}, got #{inspect(data["fixture_id"])}"
end

items =
  Enum.map(data["items"], fn item ->
    %{
      name: "#{item["name"]} - #{item["description"]}",
      qty: item["qty"],
      price: div(item["price_cents"], 100)
    }
  end)

invoice = %{
  id: data["invoice"]["id"],
  date: Date.from_iso8601!(data["invoice"]["date"]),
  items: items
}

doc = Rendro.Recipes.Invoice.document(invoice)
{:ok, pdf} = Rendro.render(doc, deterministic: true)

output_path = System.get_env("RENDRO_BENCH_OUTPUT") || "bench/results/raw/rendro-invoice.pdf"
File.mkdir_p!(Path.dirname(output_path))
File.write!(output_path, pdf)
