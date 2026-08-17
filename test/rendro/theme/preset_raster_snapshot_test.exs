defmodule Rendro.Theme.PresetRasterSnapshotTest do
  use ExUnit.Case, async: false

  alias Rendro.Adapters.Pdfium
  alias Rendro.Recipes.{BrandedInvoice, Certificate, Invoice, Payslip, Receipt, Statement, Ticket}
  alias Rendro.Theme.Presets

  @review_dir_env "RENDRO_PRESET_RASTER_REVIEW_DIR"
  @rows Rendro.TestSupport.PresetRenderMatrix.rows()

  @tag raster_snapshot: true
  test "six genre pairs render through pinned PDFium to committed page-one hashes" do
    assert_complete_matrix_contract!()
    assert_pinned_pdfium!()

    for {id, genre, mode, recipe} <- @rows do
      theme = Rendro.Theme.preset(genre, accent: "#2C6BED", mode: mode)
      document = recipe |> document_for(theme) |> Presets.register_fonts(genre)

      assert {:ok, pdf} = Rendro.render(document, deterministic: true)
      assert {:ok, [png]} = Pdfium.render(pdf, dpi: 150, pages: "1")

      write_review_png(id, png)
      assert_or_bless_page_one_hash(genre, mode, png)
    end
  end

  defp assert_complete_matrix_contract! do
    row_ids = Enum.map(@rows, &elem(&1, 0))

    reference_paths =
      Enum.map(@rows, fn {_id, genre, mode, _recipe} -> reference_path(genre, mode) end)

    assert length(@rows) == 12
    assert length(Enum.uniq(row_ids)) == 12
    assert length(Enum.uniq(reference_paths)) == 12

    assert Enum.frequencies_by(@rows, fn {_id, genre, _mode, _recipe} -> genre end) == %{
             swiss: 2,
             humanist: 2,
             editorial: 2,
             corporate_classic: 2,
             minimal_mono: 2,
             brutalist: 2
           }

    unless raster_blessing?() do
      assert Enum.all?(reference_paths, &File.regular?/1)
    end
  end

  defp assert_pinned_pdfium! do
    pin = File.read!("priv/pdfium_pin.json") |> JSON.decode!()

    assert {:ok, version} = Pdfium.version()
    assert version == pin["version"], "raster snapshots require the project-pinned PDFium version"
  end

  defp assert_or_bless_page_one_hash(genre, mode, png) do
    reference_path = reference_path(genre, mode)
    actual_hash = Base.encode16(:crypto.hash(:sha256, png), case: :lower)

    if raster_blessing?() do
      if System.get_env("GITHUB_ACTIONS") != "true" do
        raise """
        MIX_RASTER_BLESS=true must only run in the pinned CI container.
        Raster hashes are not deterministic across platforms.
        """
      end

      File.mkdir_p!(Path.dirname(reference_path))
      File.write!(reference_path, actual_hash <> "\n")
    else
      expected_hash = reference_path |> File.read!() |> String.trim()

      assert actual_hash == expected_hash,
             "pinned PDFium page-one hash mismatch for #{genre}/#{mode}; review the advisory raster in the bounded caller-provided directory before updating the reference"
    end
  end

  defp raster_blessing?, do: System.get_env("MIX_RASTER_BLESS") == "true"

  defp reference_path(genre, mode),
    do: Path.join(["priv", "raster_refs", "presets", Atom.to_string(genre), "#{mode}.sha256"])

  defp write_review_png(id, png) do
    case System.get_env(@review_dir_env) do
      nil ->
        :ok

      "" ->
        :ok

      directory ->
        expanded_directory = Path.expand(directory)
        project_root = File.cwd!() |> Path.expand()
        approved_review_directory = Path.join(project_root, "tmp/rendro_preset_raster_review")

        if expanded_directory != approved_review_directory and
             (expanded_directory == project_root or
                String.starts_with?(expanded_directory, project_root <> "/")) do
          raise ArgumentError,
                "#{@review_dir_env} must point outside the repository or use #{approved_review_directory}"
        end

        File.mkdir_p!(expanded_directory)
        File.write!(Path.join(expanded_directory, "#{id}_page_1.png"), png)
    end
  end

  defp document_for(:invoice, theme) do
    Invoice.document(
      %{
        id: "INV-MATRIX-001",
        date: ~D[2026-08-16],
        items: [%{name: "Layout audit", qty: 1, price: 250}]
      },
      theme: theme,
      header_height: 90
    )
  end

  defp document_for(:branded_invoice, theme) do
    BrandedInvoice.document(
      %{
        id: "INV-MATRIX-002",
        date: ~D[2026-08-16],
        items: [%{name: "Brand audit", qty: 1, price: 250}],
        brand: %{font_name: :brand_heading, logo_name: :company_logo}
      },
      theme: theme,
      header_height: 90
    )
  end

  defp document_for(:certificate, theme) do
    Certificate.document(
      %{
        title: "Certificate of Completion",
        recipient: "Jane Smith",
        date: ~D[2026-08-16],
        body: "For outstanding achievement and dedication.",
        seal_line: "Awarded 2026"
      },
      theme: theme
    )
  end

  defp document_for(:receipt, theme) do
    Receipt.document(
      %{
        title: "Payment Receipt",
        date: ~D[2026-08-16],
        customer: %{name: "Acme Corp"},
        lines: [%{description: "Layout audit", amount: Decimal.new("250.00")}],
        totals: %{subtotal: Decimal.new("250.00"), total: Decimal.new("250.00")}
      },
      theme: theme
    )
  end

  defp document_for(:payslip, theme) do
    Payslip.document(
      %{
        employer: %{name: "Aurora Textiles Co."},
        employee: %{name: "Jordan Rivera", id: "E-4821", tax_code: "1257L"},
        period: %{from: ~D[2026-07-01], to: ~D[2026-07-31]},
        pay_date: ~D[2026-08-05],
        earnings: [
          %{
            description: "Base Salary",
            amount: Decimal.new("4200.00"),
            ytd: Decimal.new("25200.00")
          }
        ],
        deductions: [
          %{
            description: "Federal Income Tax",
            amount: Decimal.new("620.00"),
            ytd: Decimal.new("3720.00")
          }
        ],
        net_pay: Decimal.new("3580.00"),
        payment_method: "Direct Deposit 4321"
      },
      theme: theme
    )
  end

  defp document_for(:statement, theme) do
    Statement.document(
      %{
        period: %{from: ~D[2026-07-01], to: ~D[2026-07-31]},
        account: %{name: "Acme Corp"},
        opening_balance: Decimal.new("100.00"),
        lines: [%{date: ~D[2026-07-05], description: "Payment", amount: Decimal.new("-25.00")}]
      },
      theme: theme
    )
  end

  defp document_for(:ticket, theme) do
    Ticket.document(
      %{
        issuer: %{name: "Aurora Live"},
        title: "Indie Night: The Lumen Set",
        placement: [
          %{label: "Section", value: "GA"},
          %{label: "Row", value: "H"},
          %{label: "Seat", value: "24"}
        ],
        code: %{reference: "AUR-88213-GA"}
      },
      theme: theme,
      page_size: :a4
    )
  end
end
