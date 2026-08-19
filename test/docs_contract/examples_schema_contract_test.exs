defmodule Rendro.DocsContract.ExamplesSchemaContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @schema_path "priv/schemas/examples.schema.json"
  @original_fixture_sha256 %{
    "priv/examples/certificate/summit-training-institute/certificate.json" =>
      "f59c4d721f61152462c389e418148ccdb0bd9702703f9e9a482d9785d766bed4",
    "priv/examples/invoice/acme-phoenix-saas/invoice.json" =>
      "7368479dfc51b23a09be216f5496c1d209ec7dd543e972b3b367db6525cdafd1",
    "priv/examples/payslip/aurora-live/payslip.json" =>
      "9924c3f434b323a2a8ff8f3c9df5427517fbb6d69c25ba87900e8f2a5d3dda05",
    "priv/examples/receipt/harbor-and-oak-cafe/receipt.json" =>
      "64f7bc857d25b887e5d5381ccbef3ae4c1be16e484a9fe0cbfa7f11b53f474ed",
    "priv/examples/statement/northwind-ledger-co/statement.json" =>
      "f31fe677f47cbe20bf3b1280465d09cb896a70f0eb0fc230448e5d189f18df1e",
    "priv/examples/ticket/aurora-live/ticket.json" =>
      "af45c414e7bcd7641877478fd5e745c0ba140dee7417b8dbf5d0d0a9f6a9a715"
  }

  @expected_new_brands [
    {"certificate", "aster-institute", "Aster Institute", "#1F4FB8", "swiss"},
    {"certificate", "meridian-arts-fellowship", "Meridian Arts Fellowship", "#6E3CB8",
     "editorial"},
    {"invoice", "cedar-mutual", "Cedar Mutual", "#1F4FB8", "corporate_classic"},
    {"invoice", "northline-logistics", "Northline Logistics", "#2C6BED", "swiss"},
    {"payslip", "cedar-mutual", "Cedar Mutual", "#1F4FB8", "corporate_classic"},
    {"payslip", "northline-logistics", "Northline Logistics", "#2C6BED", "swiss"},
    {"receipt", "circuit-supply-co", "Circuit Supply Co.", "#2C6BED", "minimal_mono"},
    {"receipt", "poppy-and-grain", "Poppy & Grain", "#147A4B", "humanist"},
    {"statement", "aster-research-fund", "Aster Research Fund", "#6E3CB8", "editorial"},
    {"statement", "signal-ledger", "Signal Ledger", "#0E7C76", "minimal_mono"},
    {"ticket", "field-notes-conference", "Field Notes Conference", "#0E7C76", "minimal_mono"},
    {"ticket", "the-letterpress-hall", "The Letterpress Hall", "#C24132", "editorial"}
  ]

  defp examples_schema do
    @schema_path
    |> File.read!()
    |> JSON.decode!()
    |> JSV.build!()
  end

  test "at least one example fixture exists under priv/examples/" do
    assert Path.wildcard("priv/examples/**/*.json") != [],
           "expected at least one fixture under priv/examples/**/*.json; found none " <>
             "(guards against the validation loop silently passing over zero files)"
  end

  test "every fixture under priv/examples/ validates against examples.schema.json" do
    schema = examples_schema()

    for path <- Path.wildcard("priv/examples/**/*.json") do
      fixture = path |> File.read!() |> JSON.decode!()
      assert {:ok, _} = JSV.validate(fixture, schema), "#{path} failed schema validation"
    end
  end

  test "generic brand metadata requires a complete safe local identity tuple" do
    schema = examples_schema()
    base = %{"fixture_id" => "brand_contract_fixture"}

    valid_brand = %{
      "slug" => "northline-logistics",
      "display_name" => "Northline Logistics",
      "accent" => "#2C6BED",
      "recommended_preset" => "swiss",
      "logo" => "logo.svg"
    }

    assert {:ok, _} = JSV.validate(Map.put(base, "brand", valid_brand), schema)

    for invalid_brand <- [
          Map.put(valid_brand, "slug", "Northline Logistics"),
          Map.put(valid_brand, "accent", "2C6BED"),
          Map.put(valid_brand, "recommended_preset", "Swiss"),
          Map.put(valid_brand, "logo", "../logo.svg"),
          Map.put(valid_brand, "logo", "https://assets.example/logo.svg"),
          Map.delete(valid_brand, "display_name")
        ] do
      assert {:error, _} = JSV.validate(Map.put(base, "brand", invalid_brand), schema)
    end
  end

  test "Invoice adds the locked Northline and Cedar brand fixtures with exact Decimal totals" do
    assert invoice_paths() == [
             "priv/examples/invoice/acme-phoenix-saas/invoice.json",
             "priv/examples/invoice/cedar-mutual/invoice.json",
             "priv/examples/invoice/northline-logistics/invoice.json"
           ]

    assert_brand_fixture!("invoice/northline-logistics/invoice.json", %{
      "slug" => "northline-logistics",
      "display_name" => "Northline Logistics",
      "accent" => "#2C6BED",
      "recommended_preset" => "swiss"
    })

    assert_brand_fixture!("invoice/cedar-mutual/invoice.json", %{
      "slug" => "cedar-mutual",
      "display_name" => "Cedar Mutual",
      "accent" => "#1F4FB8",
      "recommended_preset" => "corporate_classic"
    })

    for path <- invoice_paths() -- ["priv/examples/invoice/acme-phoenix-saas/invoice.json"] do
      fixture = path |> File.read!() |> JSON.decode!()

      subtotal =
        fixture["items"]
        |> Enum.reduce(Decimal.new(0), fn item, total ->
          Decimal.add(total, Decimal.mult(Decimal.new(item["qty"]), Decimal.new(item["price"])))
        end)

      assert Decimal.equal?(subtotal, Decimal.new(fixture["totals"]["subtotal"]))

      assert Decimal.equal?(
               Decimal.add(subtotal, Decimal.new(fixture["totals"]["tax"])),
               Decimal.new(fixture["totals"]["total"])
             )
    end

    assert_original_fixture_bytes!()
  end

  test "Payslip reuses the locked brands with matching marks and exact period and YTD arithmetic" do
    assert payslip_paths() == [
             "priv/examples/payslip/aurora-live/payslip.json",
             "priv/examples/payslip/cedar-mutual/payslip.json",
             "priv/examples/payslip/northline-logistics/payslip.json"
           ]

    assert_cross_domain_brand!("northline-logistics", "#2C6BED", "swiss")
    assert_cross_domain_brand!("cedar-mutual", "#1F4FB8", "corporate_classic")

    identities =
      for path <- Path.wildcard("priv/examples/**/*.json") do
        fixture = path |> File.read!() |> JSON.decode!()

        case fixture["brand"] do
          %{"slug" => slug} -> {Path.basename(Path.dirname(Path.dirname(path))), slug}
          _ -> nil
        end
      end
      |> Enum.reject(&is_nil/1)

    assert length(identities) == length(Enum.uniq(identities))

    for path <- payslip_paths() -- ["priv/examples/payslip/aurora-live/payslip.json"] do
      fixture = path |> File.read!() |> JSON.decode!()
      assert_payslip_arithmetic!(fixture)
      assert_synthetic_fixture!(fixture)
    end

    assert_original_fixture_bytes!()
  end

  test "Statement adds the locked Signal Ledger and Aster Research Fund fixtures with exact continuity" do
    assert statement_paths() == [
             "priv/examples/statement/aster-research-fund/statement.json",
             "priv/examples/statement/northwind-ledger-co/statement.json",
             "priv/examples/statement/signal-ledger/statement.json"
           ]

    assert_brand_fixture!("statement/signal-ledger/statement.json", %{
      "slug" => "signal-ledger",
      "display_name" => "Signal Ledger",
      "accent" => "#0E7C76",
      "recommended_preset" => "minimal_mono"
    })

    assert_brand_fixture!("statement/aster-research-fund/statement.json", %{
      "slug" => "aster-research-fund",
      "display_name" => "Aster Research Fund",
      "accent" => "#6E3CB8",
      "recommended_preset" => "editorial"
    })

    for path <-
          statement_paths() -- ["priv/examples/statement/northwind-ledger-co/statement.json"] do
      fixture = path |> File.read!() |> JSON.decode!()
      assert_statement_continuity!(fixture)
      assert_synthetic_fixture!(fixture)
    end
  end

  test "Receipt adds the locked Poppy and Grain and Circuit Supply Co fixtures with exact totals" do
    assert receipt_paths() == [
             "priv/examples/receipt/circuit-supply-co/receipt.json",
             "priv/examples/receipt/harbor-and-oak-cafe/receipt.json",
             "priv/examples/receipt/poppy-and-grain/receipt.json"
           ]

    assert_brand_fixture!("receipt/poppy-and-grain/receipt.json", %{
      "slug" => "poppy-and-grain",
      "display_name" => "Poppy & Grain",
      "accent" => "#147A4B",
      "recommended_preset" => "humanist"
    })

    assert_brand_fixture!("receipt/circuit-supply-co/receipt.json", %{
      "slug" => "circuit-supply-co",
      "display_name" => "Circuit Supply Co.",
      "accent" => "#2C6BED",
      "recommended_preset" => "minimal_mono"
    })

    for path <- receipt_paths() -- ["priv/examples/receipt/harbor-and-oak-cafe/receipt.json"] do
      fixture = path |> File.read!() |> JSON.decode!()
      assert_receipt_totals!(fixture)
      assert_synthetic_fixture!(fixture)
    end
  end

  test "Certificate adds the locked Aster Institute and Meridian Arts Fellowship fixtures" do
    assert certificate_paths() == [
             "priv/examples/certificate/aster-institute/certificate.json",
             "priv/examples/certificate/meridian-arts-fellowship/certificate.json",
             "priv/examples/certificate/summit-training-institute/certificate.json"
           ]

    assert_brand_fixture!("certificate/aster-institute/certificate.json", %{
      "slug" => "aster-institute",
      "display_name" => "Aster Institute",
      "accent" => "#1F4FB8",
      "recommended_preset" => "swiss"
    })

    assert_brand_fixture!("certificate/meridian-arts-fellowship/certificate.json", %{
      "slug" => "meridian-arts-fellowship",
      "display_name" => "Meridian Arts Fellowship",
      "accent" => "#6E3CB8",
      "recommended_preset" => "editorial"
    })

    for path <-
          certificate_paths() --
            ["priv/examples/certificate/summit-training-institute/certificate.json"] do
      fixture = path |> File.read!() |> JSON.decode!()
      assert_synthetic_fixture!(fixture)
    end
  end

  test "Ticket adds the locked Field Notes Conference and The Letterpress Hall fixtures" do
    assert ticket_paths() == [
             "priv/examples/ticket/aurora-live/ticket.json",
             "priv/examples/ticket/field-notes-conference/ticket.json",
             "priv/examples/ticket/the-letterpress-hall/ticket.json"
           ]

    assert_brand_fixture!("ticket/field-notes-conference/ticket.json", %{
      "slug" => "field-notes-conference",
      "display_name" => "Field Notes Conference",
      "accent" => "#0E7C76",
      "recommended_preset" => "minimal_mono"
    })

    assert_brand_fixture!("ticket/the-letterpress-hall/ticket.json", %{
      "slug" => "the-letterpress-hall",
      "display_name" => "The Letterpress Hall",
      "accent" => "#C24132",
      "recommended_preset" => "editorial"
    })
  end

  test "the closed six-domain corpus has two safe data-only additions per domain" do
    expected_paths =
      for {domain, slug, _display_name, _accent, _preset} <- @expected_new_brands do
        "priv/examples/#{domain}/#{slug}/#{fixture_filename(domain)}"
      end

    assert Enum.sort(
             Path.wildcard("priv/examples/**/*.json") -- Map.keys(@original_fixture_sha256)
           ) ==
             Enum.sort(expected_paths)

    for domain <- fixture_domains() do
      assert Path.wildcard("priv/examples/#{domain}/**/*.json") |> length() == 3
    end

    for {domain, slug, display_name, accent, recommended_preset} <- @expected_new_brands do
      path = "#{domain}/#{slug}/#{fixture_filename(domain)}"

      assert_brand_fixture!(path, %{
        "slug" => slug,
        "display_name" => display_name,
        "accent" => accent,
        "recommended_preset" => recommended_preset
      })

      "priv/examples"
      |> Path.join(path)
      |> File.read!()
      |> JSON.decode!()
      |> assert_synthetic_fixture!()
    end

    identities =
      for path <- expected_paths do
        fixture = path |> File.read!() |> JSON.decode!()
        {Path.basename(Path.dirname(Path.dirname(path))), fixture["brand"]["slug"]}
      end

    assert length(identities) == 12
    assert length(identities) == length(Enum.uniq(identities))
    assert Path.wildcard("priv/examples/**/*.ex") == []
    assert_original_fixture_bytes!()
  end

  defp invoice_paths do
    Path.wildcard("priv/examples/invoice/**/*.json") |> Enum.sort()
  end

  defp payslip_paths do
    Path.wildcard("priv/examples/payslip/**/*.json") |> Enum.sort()
  end

  defp statement_paths do
    Path.wildcard("priv/examples/statement/**/*.json") |> Enum.sort()
  end

  defp receipt_paths do
    Path.wildcard("priv/examples/receipt/**/*.json") |> Enum.sort()
  end

  defp certificate_paths do
    Path.wildcard("priv/examples/certificate/**/*.json") |> Enum.sort()
  end

  defp ticket_paths do
    Path.wildcard("priv/examples/ticket/**/*.json") |> Enum.sort()
  end

  defp fixture_domains, do: ~w(certificate invoice payslip receipt statement ticket)

  defp fixture_filename("certificate"), do: "certificate.json"
  defp fixture_filename("invoice"), do: "invoice.json"
  defp fixture_filename("payslip"), do: "payslip.json"
  defp fixture_filename("receipt"), do: "receipt.json"
  defp fixture_filename("statement"), do: "statement.json"
  defp fixture_filename("ticket"), do: "ticket.json"

  defp assert_cross_domain_brand!(slug, accent, recommended_preset) do
    invoice_path = "priv/examples/invoice/#{slug}/invoice.json"
    payslip_path = "priv/examples/payslip/#{slug}/payslip.json"
    invoice = invoice_path |> File.read!() |> JSON.decode!()
    payslip = payslip_path |> File.read!() |> JSON.decode!()

    assert Map.take(invoice["brand"], ["slug", "display_name", "accent", "recommended_preset"]) ==
             Map.take(payslip["brand"], ["slug", "display_name", "accent", "recommended_preset"])

    assert invoice["brand"]["slug"] == slug
    assert invoice["brand"]["accent"] == accent
    assert invoice["brand"]["recommended_preset"] == recommended_preset

    assert File.read!(Path.join(Path.dirname(invoice_path), "logo.svg")) ==
             File.read!(Path.join(Path.dirname(payslip_path), "logo.svg"))
  end

  defp assert_payslip_arithmetic!(fixture) do
    gross = decimal_sum(fixture["earnings"], "amount")
    deductions = decimal_sum(fixture["deductions"], "amount")
    gross_ytd = decimal_sum(fixture["earnings"], "ytd")
    deductions_ytd = decimal_sum(fixture["deductions"], "ytd")

    assert Decimal.equal?(Decimal.sub(gross, deductions), Decimal.new(fixture["net_pay"]))

    assert Decimal.equal?(
             Decimal.sub(gross_ytd, deductions_ytd),
             Decimal.new(fixture["net_pay_ytd"])
           )
  end

  defp assert_statement_continuity!(fixture) do
    transactions = decimal_sum(fixture["lines"], "amount")

    assert Decimal.equal?(
             Decimal.add(Decimal.new(fixture["opening_balance"]), transactions),
             Decimal.new(fixture["closing_balance"])
           )
  end

  defp assert_receipt_totals!(fixture) do
    subtotal = decimal_sum(fixture["lines"], "amount")
    totals = fixture["totals"]

    assert Decimal.equal?(subtotal, Decimal.new(totals["subtotal"]))

    assert Decimal.equal?(
             Decimal.add(subtotal, Decimal.new(totals["tax"])),
             Decimal.new(totals["total"])
           )
  end

  defp decimal_sum(lines, key) do
    Enum.reduce(lines, Decimal.new(0), fn line, total ->
      Decimal.add(total, Decimal.new(line[key]))
    end)
  end

  defp assert_synthetic_fixture!(fixture) do
    text = inspect(fixture)
    refute text =~ ~r/(?:password|api[_ -]?key|secret|https?:\/\/|\b\d{16}\b)/i

    if employee_id = get_in(fixture, ["employee", "id"]) do
      refute employee_id =~ ~r/^\d{3}-\d{2}-\d{4}$/
    end
  end

  defp assert_brand_fixture!(relative_path, expected_brand) do
    path = Path.join("priv/examples", relative_path)
    fixture = path |> File.read!() |> JSON.decode!()

    assert Map.take(fixture["brand"], Map.keys(expected_brand)) == expected_brand
    assert fixture["brand"]["logo"] == "logo.svg"

    logo_path = Path.join(Path.dirname(path), fixture["brand"]["logo"])
    assert File.regular?(logo_path)
    assert_svg_contract!(logo_path)
  end

  defp assert_svg_contract!(path) do
    svg = File.read!(path)

    assert svg =~ "<svg"
    refute svg =~ ~r/<(?:script|image|foreignObject)\b/i
    refute svg =~ ~r/(?:href\s*=|url\(|(?:linear|radial)Gradient|<filter\b)/i
    refute svg =~ ~r/<text\b/i
    assert length(Regex.scan(~r/#[0-9A-Fa-f]{6}\b/, svg)) == 1
  end

  defp sha256(path) do
    path
    |> File.read!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp assert_original_fixture_bytes! do
    for {path, expected_sha256} <- @original_fixture_sha256 do
      assert sha256(path) == expected_sha256
    end
  end

  describe "hex tarball contents" do
    test "priv/examples/ ships in the built tarball and every entry is text-only" do
      tarball = Rendro.Test.HexBuildCache.tarball_path!()

      {output, 0} = Rendro.Test.HexBuildCache.get_build_output()
      assert output =~ Path.basename(tarball)
      assert File.exists?(tarball)

      list_cmd = "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"
      {contents, 0} = System.cmd("sh", ["-c", list_cmd], stderr_to_stdout: true)

      shipped =
        contents
        |> String.split("\n", trim: true)
        |> Enum.filter(&String.starts_with?(&1, "priv/examples/"))

      assert shipped != [],
             "expected priv/examples/ entries in the shipped tarball; found none"

      for path <- shipped do
        assert Path.extname(path) in [".json", ".md", ".svg"],
               "#{path} shipped in the Hex tarball but is not text-only (.json/.md/.svg)"
      end
    end
  end
end
