defmodule Rendro.Recipes.PayslipByteIdentityTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Payslip

  # Frozen golden, computed by actually running a render on pristine (fully
  # implemented) `payslip.ex` via `mix run` -- never hand-typed. A fresh
  # render of the SAME fixed, deterministic fixture must keep hashing to this
  # exact value. Changing this hash is a defect, not a golden-file refresh,
  # unless a human explicitly re-authorizes a new baseline.
  @toy_golden_sha256 "3e89a150660a037f352f38c3a66ef07773f0b438611f38c8be1b985c9b20c2bd"

  # Fixed, deterministic minimal fixture (no anatomy variance) -- one
  # earnings line, one deductions line, no :totals, no accented content, so
  # the golden hash exercises the frozen happy path exactly.
  defp fixture_data do
    %{
      employer: %{name: "Aurora Textiles Co.", address: "500 Loom Street, Raleigh, NC 27601"},
      employee: %{name: "Jordan Rivera", id: "E-·····4821", tax_code: "1257L"},
      period: %{from: ~D[2026-06-01], to: ~D[2026-06-30]},
      pay_date: ~D[2026-07-05],
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
      payment_method: "Direct Deposit ···· 4321"
    }
  end

  describe "D-13/D-14 byte-identity baseline" do
    test "two deterministic renders are byte-identical" do
      doc = Payslip.document(fixture_data())
      assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "fresh render sha256 matches the frozen golden" do
      doc = Payslip.document(fixture_data())
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)

      sha256 = :crypto.hash(:sha256, pdf) |> Base.encode16(case: :lower)

      assert sha256 == @toy_golden_sha256,
             "payslip render drifted from the frozen byte-identity baseline. " <>
               "If this drift is an intentional, human-approved change, " <>
               "recompute @toy_golden_sha256 and update it deliberately."
    end
  end
end
