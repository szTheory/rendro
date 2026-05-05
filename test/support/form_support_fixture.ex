defmodule Rendro.Test.FormSupportFixture do
  @moduledoc false

  def document do
    %Rendro.Document{
      pages: [
        %Rendro.Page{
          width: 612,
          height: 792,
          margin_left: 72,
          margin_top: 72,
          blocks: [
            Rendro.form_field("email", "jon@example.test", x: 72, y: 96, width: 220, height: 24),
            Rendro.form_field("terms", "", type: :checkbox, checked: true, x: 72, y: 136, width: 20, height: 20),
            Rendro.form_field("contact_email", "",
              type: :radio,
              group: "contact",
              export_value: "email",
              checked: true,
              x: 72,
              y: 176,
              width: 20,
              height: 20
            ),
            Rendro.form_field("contact_phone", "",
              type: :radio,
              group: "contact",
              export_value: "phone",
              x: 112,
              y: 176,
              width: 20,
              height: 20
            )
          ]
        }
      ],
      metadata: %Rendro.Metadata{title: "Rendro Forms Support Fixture"}
    }
  end

  def render_pdf do
    Rendro.render(document(), deterministic: true)
  end

  def write_fixture(path) do
    {:ok, pdf} = render_pdf()
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, pdf)
    path
  end
end
