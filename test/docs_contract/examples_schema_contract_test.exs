defmodule Rendro.DocsContract.ExamplesSchemaContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @schema_path "priv/schemas/examples.schema.json"
  @original_invoice_sha256 "7368479dfc51b23a09be216f5496c1d209ec7dd543e972b3b367db6525cdafd1"
  @original_payslip_sha256 "9924c3f434b323a2a8ff8f3c9df5427517fbb6d69c25ba87900e8f2a5d3dda05"

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

    assert sha256("priv/examples/invoice/acme-phoenix-saas/invoice.json") ==
             @original_invoice_sha256
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

    assert sha256("priv/examples/payslip/aurora-live/payslip.json") == @original_payslip_sha256
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

  defp invoice_paths do
    Path.wildcard("priv/examples/invoice/**/*.json") |> Enum.sort()
  end

  defp payslip_paths do
    Path.wildcard("priv/examples/payslip/**/*.json") |> Enum.sort()
  end

  defp statement_paths do
    Path.wildcard("priv/examples/statement/**/*.json") |> Enum.sort()
  end

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

  describe "hex tarball contents" do
    test "priv/examples/ ships in the built tarball and every entry is text-only" do
      tarball = "rendro-#{Mix.Project.config()[:version]}.tar"

      {output, 0} = Rendro.Test.HexBuildCache.get_build_output()
      assert output =~ tarball
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
