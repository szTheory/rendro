defmodule Rendro.Test.SigningViewerSupportFixture do
  @moduledoc false

  alias Rendro.Sign

  @signature_field "customer_signature"

  def document do
    Rendro.fixed([
      Rendro.page(
        width: 612,
        height: 792,
        margin_left: 72,
        margin_top: 72,
        blocks: [
          Rendro.signature_field(@signature_field,
            x: 10,
            y: 20,
            width: 180,
            height: 48
          )
        ]
      )
    ])
  end

  def render_artifact do
    {:ok, artifact} = Rendro.render_to_artifact(document(), deterministic: true)
    artifact
  end

  def write_signature_widget_fixture(path) do
    {:ok, pdf} = Rendro.render(document(), deterministic: true)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, pdf)
    path
  end

  def write_signing_preparation_fixture(path) do
    {:ok, prepared} =
      Sign.prepare(render_artifact(),
        field: @signature_field,
        reserved_bytes: 8192
      )

    File.mkdir_p!(Path.dirname(path))
    File.write!(path, prepared.binary)
    path
  end
end
