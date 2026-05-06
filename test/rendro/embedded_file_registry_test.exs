defmodule Rendro.EmbeddedFileRegistryTest do
  use ExUnit.Case, async: true

  alias Rendro.EmbeddedFileRegistry

  describe "new/0" do
    test "returns an empty registry" do
      assert %EmbeddedFileRegistry{files: %{}} = EmbeddedFileRegistry.new()
    end
  end

  describe "register/4" do
    test "stores binary-backed embedded files with explicit metadata" do
      registry =
        EmbeddedFileRegistry.new()
        |> EmbeddedFileRegistry.register(:invoice_csv, {:binary, "a,b,c\n1,2,3\n"},
          filename: "invoice.csv",
          mime_type: "text/csv",
          description: "Exported invoice data"
        )

      assert {:ok,
              %{
                logical_name: :invoice_csv,
                source_kind: :binary,
                bytes: "a,b,c\n1,2,3\n",
                byte_size: 12,
                filename: "invoice.csv",
                mime_type: "text/csv",
                description: "Exported invoice data"
              }} = EmbeddedFileRegistry.fetch(registry, :invoice_csv)

      refute Map.has_key?(registry.files.invoice_csv, :created_at)
      refute Map.has_key?(registry.files.invoice_csv, :modified_at)
    end

    test "eagerly normalizes path-backed files into owned bytes" do
      path =
        Path.join(
          System.tmp_dir!(),
          "rendro-embedded-file-#{System.unique_integer([:positive])}.txt"
        )

      File.write!(path, "embed me")

      registry =
        EmbeddedFileRegistry.new()
        |> EmbeddedFileRegistry.register(:note, {:path, path},
          filename: "note.txt",
          mime_type: "text/plain"
        )

      assert {:ok,
              %{
                source_kind: :path,
                bytes: "embed me",
                byte_size: 8,
                filename: "note.txt",
                mime_type: "text/plain"
              }} = EmbeddedFileRegistry.fetch(registry, :note)

      refute get_in(registry.files[:note], [:path])

      File.rm!(path)
    end

    test "stores authored timestamps only when provided" do
      created_at = ~U[2026-05-05 14:00:00Z]
      modified_at = ~U[2026-05-05 14:30:00Z]

      registry =
        EmbeddedFileRegistry.new()
        |> EmbeddedFileRegistry.register(:statement, {:binary, "pdf-bytes"},
          filename: "statement.pdf",
          mime_type: "application/pdf",
          created_at: created_at,
          modified_at: modified_at
        )

      assert {:ok,
              %{
                created_at: ^created_at,
                modified_at: ^modified_at
              }} = EmbeddedFileRegistry.fetch(registry, :statement)
    end
  end
end
