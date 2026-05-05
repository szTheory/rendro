defmodule Rendro.Rules.CheckFormFieldsTest do
  use ExUnit.Case, async: true

  alias Rendro.{Block, Document, FormField, Page}
  alias Rendro.Pipeline.Validate
  alias Rendro.Rules.CheckFormFields

  describe "FormField struct" do
    test "requires name and provides defaults" do
      field = %FormField{name: "first_name"}

      assert field.name == "first_name"
      assert field.value == ""
      assert field.font == "Helvetica"
      assert field.size == 12
    end

    test "raises without name" do
      assert_raise ArgumentError, ~r/the following keys must also be given/, fn ->
        struct!(FormField, [])
      end
    end
  end

  describe "check/2" do
    test "returns :ok for non-empty field names" do
      assert :ok = CheckFormFields.check(%FormField{name: "email"}, %Document{})
    end

    test "returns an error for nil names" do
      assert {:error, {:missing_required_key, :name}} =
               CheckFormFields.check(%FormField{name: nil}, %Document{})
    end

    test "returns an error for empty names" do
      assert {:error, {:missing_required_key, :name}} =
               CheckFormFields.check(%FormField{name: ""}, %Document{})
    end
  end

  describe "Validate.run/1" do
    test "applies the form-field rule during document validation" do
      doc = %Document{pages: [%Page{blocks: [%Block{content: %FormField{name: ""}}]}]}

      assert {:error,
              %Rendro.Error{
                stage: :validate,
                reason: :structural_corruption,
                details: %{errors: errors}
              }} = Validate.run(doc)

      assert {:missing_required_key, :name} in errors
    end
  end
end
