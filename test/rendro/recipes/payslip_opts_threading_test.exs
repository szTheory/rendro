defmodule Rendro.Recipes.PayslipOptsThreadingTest do
  @moduledoc """
  Phase 120 Plan 04 (swap): proves the `:theme` opt threads through Payslip's
  `palette/1` seam — recolors the seamed text (ink/muted roles), respects
  `:palette` override precedence (D-01), and leaves the no-theme path
  byte-identical (PLUMB-03).
  """
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Payslip

  defp sample_data do
    %{
      employer: %{name: "Aurora Textiles Co.", address: "500 Loom Street, Raleigh, NC 27601"},
      employee: %{name: "Jordan Rivera", id: "E-4821", tax_code: "1257L"},
      period: %{from: ~D[2026-06-01], to: ~D[2026-06-30]},
      pay_date: ~D[2026-07-05],
      earnings: [
        %{description: "Base Salary", amount: Decimal.new("4200.00"), ytd: Decimal.new("25200.00")}
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
    }
  end

  describe "Payslip :theme threading (PLUMB-02 swap)" do
    test ":theme threads through page_template/1 without KeyError" do
      assert %Rendro.PageTemplate{} = Payslip.page_template(theme: Rendro.Theme.default())
    end

    test "a themed render differs from the no-theme render" do
      data = sample_data()
      refute Payslip.sections(data) == Payslip.sections(data, theme: Rendro.Theme.default())
    end

    test ":palette override wins over :theme (D-01)" do
      data = sample_data()
      themed = Payslip.sections(data, theme: Rendro.Theme.default())

      overridden =
        Payslip.sections(data, theme: Rendro.Theme.default(), palette: %{ink: {200, 0, 0}})

      refute themed == overridden
    end
  end

  describe "Payslip no-theme byte-identity (PLUMB-03)" do
    test "sections(data) equals sections(data, [])" do
      data = sample_data()
      assert Payslip.sections(data) == Payslip.sections(data, [])
    end

    test "default palette (no override) renders byte-identically" do
      data = sample_data()
      assert Payslip.sections(data) == Payslip.sections(data, palette: %{})
    end
  end

  describe "typography(opts) seam (TYPE-01/02/03)" do
    test "no-op: sections(data) equals sections(data, typography: %{})" do
      data = sample_data()
      assert Payslip.sections(data) == Payslip.sections(data, typography: %{})
    end

    test "a :typography override changes the output (live seam)" do
      data = sample_data()

      # `leading` is threaded onto every %Text{} block, so overriding it is
      # guaranteed to change the sections — proving the seam is live, not inert.
      refute Payslip.sections(data) == Payslip.sections(data, typography: %{leading: 2.0})
    end

    # CR-01 regression (122-VERIFICATION): the themed font branch used to return
    # the resolved theme's bare `:default` font roles, severing the B612 unicode
    # fallback carried by `:payslip_sans` and crashing a themed render on
    # Payslip's own documented data (`{:unsupported_glyph, "•"}`). This exercises
    # the full `render/2` path (not `%Section{}` struct equality — the coverage
    # hole that let CR-01 ship) on the masked-middot payment_method (D-14 `•`)
    # plus accented (D-17) content.
    test "themed render succeeds on masked-middot + accented content (CR-01)" do
      data = %{
        employer: %{name: "Aurora Textiles Co.", address: "500 Loom Street, Raleigh, NC 27601"},
        employee: %{name: "Jordan Rivera", id: "E-·····4821", tax_code: "1257L"},
        period: %{from: ~D[2026-06-01], to: ~D[2026-06-30]},
        pay_date: ~D[2026-07-05],
        earnings: [
          %{description: "Base Salary", amount: Decimal.new("4200.00"), ytd: Decimal.new("25200.00")}
        ],
        deductions: [
          %{
            description: "Federal Income Tax",
            amount: Decimal.new("620.00"),
            ytd: Decimal.new("3720.00")
          },
          %{
            description: "Impôt sur le revenu",
            amount: Decimal.new("100.00"),
            ytd: Decimal.new("600.00")
          }
        ],
        # gross 4200.00 - deductions 720.00 = net 3480.00 (D-13 reconciliation)
        net_pay: Decimal.new("3480.00"),
        payment_method: "Direct Deposit ···· 4321"
      }

      assert {:ok, _} = Rendro.render(Payslip.document(data, theme: Rendro.Theme.default()))
    end
  end
end
