defmodule Rendro.Test.EmbeddedArtifactSupportFixture do
  @moduledoc false

  @creation_timestamp ~U[2026-05-05 14:00:00Z]

  @doc """
  Returns a deterministic `%Rendro.Document{}` exercising the
  supported v1.9 embedded-files and links surface in a single PDF.
  """
  @spec document() :: Rendro.Document.t()
  def document do
    external_link_block =
      Rendro.block(
        Rendro.text("Rendro documentation", font: "Helvetica", size: 12),
        x: 72,
        y: 96,
        width: 240,
        height: 24
      )
      |> Rendro.link(uri: "https://example.com/docs")

    internal_link_block =
      Rendro.block(
        Rendro.text("Continued on page 2", font: "Helvetica", size: 12),
        x: 72,
        y: 144,
        width: 240,
        height: 24
      )
      |> Rendro.link(page: 2)

    cover_page = %Rendro.Page{
      width: 612,
      height: 792,
      margin_left: 72,
      margin_top: 72,
      blocks: [external_link_block, internal_link_block]
    }

    target_page = %Rendro.Page{
      width: 612,
      height: 792,
      margin_left: 72,
      margin_top: 72,
      blocks: [
        Rendro.block(
          Rendro.text("Target of internal page link.", font: "Helvetica", size: 12),
          x: 72,
          y: 96,
          width: 240,
          height: 24
        )
      ]
    }

    %Rendro.Document{
      pages: [cover_page, target_page],
      metadata: %Rendro.Metadata{title: "Rendro Embedded-Artifact Support Fixture"}
    }
    |> Rendro.register_embedded_file(:invoice_csv, {:binary, "a,b\n1,2\n"},
      filename: "invoice.csv",
      mime_type: "text/csv",
      description: "Billing export",
      created_at: @creation_timestamp
    )
  end

  @doc """
  Renders the representative fixture as a deterministic PDF binary.
  """
  @spec render_pdf() :: {:ok, binary()} | {:error, term()}
  def render_pdf do
    Rendro.render(document(), deterministic: true)
  end

  @doc """
  Writes the representative fixture to `path` and returns `path`.

  Creates parent directories as needed. Used by both the automated
  Poppler structural proof lane and the manual viewer proof lane.
  """
  @spec write_fixture(Path.t()) :: Path.t()
  def write_fixture(path) do
    {:ok, pdf} = render_pdf()
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, pdf)
    path
  end
end
