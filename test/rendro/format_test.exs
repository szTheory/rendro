defmodule Rendro.FormatTest do
  use ExUnit.Case, async: true

  alias Rendro.Format

  doctest Rendro.Format

  describe "money/1" do
    test "formats a positive Decimal as a grouped 2-dp currency string" do
      assert Format.money(Decimal.new("1234.5")) == "$1,234.50"
    end

    test "rounds to 2 decimal places (half-up)" do
      assert Format.money(Decimal.new("1234.567")) == "$1,234.57"
    end

    test "wraps negatives in parentheses with no leading minus" do
      assert Format.money(Decimal.new("-1234.5")) == "($1,234.50)"
    end

    test "formats zero" do
      assert Format.money(Decimal.new("0")) == "$0.00"
    end

    test "groups millions" do
      assert Format.money(Decimal.new("1000000")) == "$1,000,000.00"
    end

    test "groups exactly at the thousands boundary" do
      assert Format.money(Decimal.new("999")) == "$999.00"
      assert Format.money(Decimal.new("1000")) == "$1,000.00"
    end

    test "treats negative zero as zero (no parentheses)" do
      assert Format.money(Decimal.new("-0.001")) == "$0.00"
    end

    test "rounds negative magnitudes before grouping" do
      assert Format.money(Decimal.new("-1234.567")) == "($1,234.57)"
    end
  end

  describe "date/1" do
    test "formats a Date as ISO 8601 YYYY-MM-DD" do
      assert Format.date(~D[2026-05-29]) == "2026-05-29"
    end

    test "zero-pads month and day" do
      assert Format.date(~D[2026-01-02]) == "2026-01-02"
    end
  end

  describe "label/1" do
    test "maps the five default statement labels" do
      assert Format.label(:balance) == "Balance"
      assert Format.label(:brought_forward) == "Brought forward"
      assert Format.label(:carried_forward) == "Carried forward"
      assert Format.label(:opening_balance) == "Opening balance"
      assert Format.label(:closing_balance) == "Closing balance"
    end
  end

  describe "determinism" do
    test "money/1 returns byte-identical strings on repeated calls" do
      d = Decimal.new("-1234567.895")
      first = Format.money(d)
      second = Format.money(d)
      assert first == second
      assert first == "($1,234,567.90)"
    end

    test "date/1 returns byte-identical strings on repeated calls" do
      d = ~D[2026-05-29]
      assert Format.date(d) == Format.date(d)
      assert Format.date(d) == "2026-05-29"
    end

    test "label/1 returns byte-identical strings on repeated calls" do
      assert Format.label(:carried_forward) == Format.label(:carried_forward)
    end
  end
end
