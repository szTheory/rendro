defmodule Rendro.Recipes.TicketTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Ticket

  # 2x2 PNG -- reused verbatim from test/rendro/image_parser_test.exs, a
  # proven-valid fixture the codebase already trusts for ImageParser.parse/1.
  @valid_png_bytes Base.decode64!(
                      "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVQIW2NkYGD4z8DAwMgAI0AMADjKAu09+3WTAAAAAElFTkSuQmCC"
                    )

  # ---------------------------------------------------------------------------
  # Test Fixture Helpers
  # ---------------------------------------------------------------------------

  # Fictional-only ticket fixture -- Aurora Live, the milestone's canonical
  # live-events fixture business (D-01). No code.image by default.
  defp fixture_data(opts \\ []) do
    overrides = Map.new(opts)

    base = %{
      issuer: %{name: "Aurora Live"},
      title: "Indie Night: The Lumen Set",
      placement: [
        %{label: "Section", value: "GA"},
        %{label: "Row", value: "H"},
        %{label: "Seat", value: "24"}
      ],
      code: %{reference: "AUR-88213-GA"}
    }

    Map.merge(base, overrides)
  end

  # ---------------------------------------------------------------------------
  # page_template/1 (D-03 geometry)
  # ---------------------------------------------------------------------------

  describe "page_template/1" do
    test "returns a %Rendro.PageTemplate{} with :main/:stub/:terms regions, correct role/anchor" do
      template = Ticket.page_template()
      assert %Rendro.PageTemplate{} = template

      by_name = Map.new(template.regions, &{&1.name, &1})

      assert %{anchor: :fixed} = by_name[:main]
      assert %{anchor: :fixed} = by_name[:stub]
      assert Map.has_key?(by_name, :terms)

      for region <- [by_name[:main], by_name[:stub], by_name[:terms]] do
        refute region.role in [:header, :footer, :sidebar]
      end

      assert by_name[:main].role == :custom
      assert by_name[:stub].role == :custom
    end

    test "page_size: :us_letter yields different geometry than the :a4 default" do
      a4 = Ticket.page_template()
      letter = Ticket.page_template(page_size: :us_letter)

      refute {a4.width, a4.height} == {letter.width, letter.height}
    end
  end

  # ---------------------------------------------------------------------------
  # validate_data!/1 (via Ticket.document/2) -- D-04/D-10 shape/type checks
  # ---------------------------------------------------------------------------

  describe "validate_data!/1 (D-04/D-10 shape/type checks)" do
    test "does NOT raise for a well-formed minimal payload with code.image: nil" do
      data = Map.put(fixture_data(), :code, %{reference: "AUR-1", image: nil})
      assert %Rendro.Document{} = Ticket.document(data)
    end

    test "does NOT raise for the same payload with code.image omitted entirely" do
      data = fixture_data()
      assert %Rendro.Document{} = Ticket.document(data)
    end

    test "does NOT raise for a valid PNG binary in code.image" do
      data =
        Map.put(fixture_data(), :code, %{
          reference: "AUR-1",
          image: {:binary, @valid_png_bytes}
        })

      assert %Rendro.Document{} = Ticket.document(data)
    end

    test "raises an instructive ArgumentError for missing :title" do
      data = fixture_data() |> Map.delete(:title)

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Ticket.document(data)
      end
    end

    test "raises an instructive ArgumentError for empty :placement" do
      data = fixture_data(placement: [])

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Ticket.document(data)
      end
    end

    test "raises an instructive ArgumentError for a 5-entry :placement (over the D-02 cap)" do
      placement = for i <- 1..5, do: %{label: "L#{i}", value: "V#{i}"}
      data = fixture_data(placement: placement)

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Ticket.document(data)
      end
    end

    test "raises an instructive ArgumentError for a :placement entry missing :label" do
      data = fixture_data(placement: [%{value: "GA"}])

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Ticket.document(data)
      end
    end

    test "raises an instructive ArgumentError for a :placement entry missing :value" do
      data = fixture_data(placement: [%{label: "Section"}])

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Ticket.document(data)
      end
    end

    test "raises an instructive ArgumentError for missing code.reference" do
      data = Map.put(fixture_data(), :code, %{})

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Ticket.document(data)
      end
    end

    test "raises an instructive ArgumentError for a blank code.reference" do
      data = Map.put(fixture_data(), :code, %{reference: ""})

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Ticket.document(data)
      end
    end

    test "raises an instructive ArgumentError for a :title exceeding its byte guard" do
      data = fixture_data(title: String.duplicate("x", 201))

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Ticket.document(data)
      end
    end

    test "raises an instructive ArgumentError for malformed code.image bytes, naming data.code.image, never leaking InvalidAssetError" do
      data =
        Map.put(fixture_data(), :code, %{
          reference: "AUR-1",
          image: {:binary, "not a real image"}
        })

      error =
        assert_raise ArgumentError, fn ->
          Ticket.document(data)
        end

      assert error.message =~ "data.code.image"
      refute error.message =~ "InvalidAssetError"
      assert error.message =~ ~r/What:.*Where:.*Why:.*Next:/s
    end
  end
end
