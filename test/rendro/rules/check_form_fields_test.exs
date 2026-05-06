defmodule Rendro.Rules.CheckFormFieldsTest do
  use ExUnit.Case, async: true

  alias Rendro.{Block, Document, FormField, Page}
  alias Rendro.Pipeline.Validate
  alias Rendro.Rules.CheckFormFields

  describe "FormField struct" do
    test "requires name and provides defaults" do
      field = %FormField{name: "first_name"}

      assert field.name == "first_name"
      assert field.type == :text
      assert field.value == ""
      assert field.font == "Helvetica"
      assert field.size == 12
      refute field.checked
      assert field.export_value == "Yes"
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

    test "rejects dotted field names" do
      assert {:error, {:unsupported_form_field_name, "billing.email"}} =
               CheckFormFields.check(%FormField{name: "billing.email"}, %Document{})
    end

    test "returns an error for unsupported widget types" do
      assert {:error, {:invalid_form_field_type, :signature}} =
               CheckFormFields.check(%FormField{name: "sig", type: :signature}, %Document{})
    end

    test "rejects non-binary text values" do
      assert {:error, {:invalid_form_field_value, 123}} =
               CheckFormFields.check(%FormField{name: "email", value: 123}, %Document{})
    end

    test "rejects unsupported editing fonts" do
      assert {:error, {:invalid_form_field_font, :body}} =
               CheckFormFields.check(%FormField{name: "email", font: :body}, %Document{})
    end

    test "rejects non-positive sizes" do
      assert {:error, {:invalid_form_field_size, 0}} =
               CheckFormFields.check(%FormField{name: "email", size: 0}, %Document{})
    end

    test "returns an error for non-boolean checked values" do
      assert {:error, {:invalid_form_field_checked, "yes"}} =
               CheckFormFields.check(%FormField{name: "agree", checked: "yes"}, %Document{})
    end

    test "returns an error for nil names" do
      assert {:error, {:missing_required_key, :name}} =
               CheckFormFields.check(%FormField{name: nil}, %Document{})
    end

    test "returns an error for empty names" do
      assert {:error, {:missing_required_key, :name}} =
               CheckFormFields.check(%FormField{name: ""}, %Document{})
    end

    test "returns an error for radio fields missing a group" do
      assert {:error, {:missing_required_key, :group}} =
               CheckFormFields.check(
                 %FormField{name: "contact", type: :radio, group: nil, export_value: "email"},
                 %Document{}
               )
    end

    test "returns an error for radio fields with dotted group names" do
      assert {:error, {:unsupported_form_field_name, "contact.primary"}} =
               CheckFormFields.check(
                 %FormField{
                   name: "contact_email",
                   type: :radio,
                   group: "contact.primary",
                   export_value: "email"
                 },
                 %Document{}
               )
    end

    test "returns an error for empty button export values" do
      assert {:error, {:invalid_form_field_export_value, ""}} =
               CheckFormFields.check(
                 %FormField{name: "contact", type: :radio, group: "contact", export_value: ""},
                 %Document{}
               )
    end

    test "returns an error for non-binary button export values" do
      assert {:error, {:invalid_form_field_export_value, :email}} =
               CheckFormFields.check(
                 %FormField{
                   name: "contact",
                   type: :checkbox,
                   export_value: :email,
                   value: ""
                 },
                 %Document{}
               )
    end
  end

  describe "document-level checks" do
    test "rejects duplicate standalone field names" do
      doc =
        form_document([
          %FormField{name: "email"},
          %FormField{name: "email"}
        ])

      assert {:errors, [duplicate]} = CheckFormFields.check(doc, doc)
      assert duplicate == {:duplicate_form_field_name, "email"}
    end

    test "rejects radio group names that collide with an existing field identity" do
      doc =
        form_document([
          %FormField{name: "contact"},
          %FormField{name: "contact_email", type: :radio, group: "contact", export_value: "email"}
        ])

      assert {:errors, [duplicate]} = CheckFormFields.check(doc, doc)
      assert duplicate == {:duplicate_form_field_name, "contact"}
    end

    test "rejects duplicate radio export values in one group" do
      doc =
        form_document([
          %FormField{
            name: "contact_email",
            type: :radio,
            group: "contact",
            export_value: "email"
          },
          %FormField{name: "contact_phone", type: :radio, group: "contact", export_value: "email"}
        ])

      assert {:errors, [duplicate]} = CheckFormFields.check(doc, doc)
      assert duplicate == {:duplicate_radio_export_value, "contact", "email"}
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

    test "aggregates document-wide form semantics through the validate-stage error envelope" do
      doc =
        form_document([
          %FormField{name: "contact"},
          %FormField{name: "billing.email"},
          %FormField{
            name: "contact_email",
            type: :radio,
            group: "contact",
            export_value: "email"
          },
          %FormField{
            name: "contact_phone",
            type: :radio,
            group: "contact",
            export_value: "email"
          },
          %FormField{
            name: "contact_sms",
            type: :radio,
            group: "contact",
            export_value: "sms",
            checked: true
          },
          %FormField{
            name: "contact_post",
            type: :radio,
            group: "contact",
            export_value: "post",
            checked: true
          }
        ])

      assert {:error,
              %Rendro.Error{
                stage: :validate,
                reason: :structural_corruption,
                details: %{errors: errors}
              }} = Validate.run(doc)

      assert {:unsupported_form_field_name, "billing.email"} in errors
      assert {:duplicate_form_field_name, "contact"} in errors
      assert {:duplicate_radio_export_value, "contact", "email"} in errors
      assert {:radio_group_multiple_checked_defaults, "contact"} in errors
    end
  end

  defp form_document(fields) do
    %Document{
      pages: [
        %Page{
          blocks: Enum.map(fields, &%Block{content: &1})
        }
      ]
    }
  end
end
