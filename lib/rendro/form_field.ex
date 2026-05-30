defmodule Rendro.FormField do
  @moduledoc """
  Interactive form field content with deterministic authoring defaults.

  Supported widget families stay intentionally narrow: text fields, checkboxes,
  radio widgets, and unsigned signature placeholders only. Authoring-time
  editing appearance configuration is currently limited to the built-in
  Helvetica path. Signature-specific authored state beyond the visible
  placeholder contract is preserved only on a narrow rejection-only carrier so
  validation can fail it before render.
  """
  @moduledoc tags: [:stable]

  @typedoc "Supported AcroForm widget families exposed through Rendro's form-field builders."
  @type field_type :: :text | :checkbox | :radio | :signature
  @type editing_font :: String.t()
  @type signature_rejection_key ::
          :reason
          | :location
          | :contact
          | :signing_date
          | :lock
          | :seed_value
          | :certification
          | :filter
          | :subfilter
          | :byte_range
          | :contents
          | :reference
  @type signature_rejection :: {signature_rejection_key(), term()}
  @type signature_rejections :: [signature_rejection()]

  @enforce_keys [:name]
  defstruct [
    :name,
    type: :text,
    value: "",
    font: "Helvetica",
    size: 12,
    checked: false,
    group: nil,
    export_value: "Yes",
    signature_rejections: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          type: field_type(),
          value: String.t(),
          font: editing_font(),
          size: number(),
          checked: boolean(),
          group: String.t() | nil,
          export_value: String.t(),
          signature_rejections: signature_rejections()
        }
end
