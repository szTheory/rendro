defmodule Rendro.FormField do
  @moduledoc """
  Interactive form field content with deterministic authoring defaults.

  Supported widget families stay intentionally narrow: text fields, checkboxes,
  and radio widgets only. Authoring-time editing appearance configuration is
  currently limited to the built-in Helvetica path.
  """

  @typedoc "Supported AcroForm widget families exposed through `Rendro.form_field/3`."
  @type field_type :: :text | :checkbox | :radio
  @type editing_font :: String.t()

  @enforce_keys [:name]
  defstruct [
    :name,
    type: :text,
    value: "",
    font: "Helvetica",
    size: 12,
    checked: false,
    group: nil,
    export_value: "Yes"
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          type: field_type(),
          value: String.t(),
          font: editing_font(),
          size: number(),
          checked: boolean(),
          group: String.t() | nil,
          export_value: String.t()
        }
end
