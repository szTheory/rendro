defmodule Rendro.Rules.CheckEmbeddedFilesTest do
  use ExUnit.Case, async: true

  alias Rendro.{Document, EmbeddedFileRegistry}
  alias Rendro.Pipeline.Validate
  alias Rendro.Rules.CheckEmbeddedFiles

  describe "check/2" do
    test "returns :ok for documents without embedded files" do
      assert :ok = CheckEmbeddedFiles.check(%Document{}, %Document{})
    end

    test "rejects duplicate embedded filenames on the document" do
      doc =
        embedded_file_document(%{
          invoice_csv: %{
            logical_name: :invoice_csv,
            source_kind: :binary,
            bytes: "a,b\n1,2\n",
            byte_size: 8,
            filename: "invoice.csv",
            mime_type: "text/csv"
          },
          backup_csv: %{
            logical_name: :backup_csv,
            source_kind: :binary,
            bytes: "x,y\n3,4\n",
            byte_size: 8,
            filename: "invoice.csv",
            mime_type: "text/csv"
          }
        })

      assert {:errors, [duplicate]} = CheckEmbeddedFiles.check(doc, doc)
      assert duplicate == {:duplicate_embedded_file_name, "invoice.csv"}
    end

    test "rejects malformed embedded-file metadata tuples" do
      doc =
        embedded_file_document(%{
          bad_file: %{
            logical_name: :bad_file,
            source_kind: :binary,
            bytes: "bad",
            byte_size: 3,
            filename: "",
            mime_type: nil,
            description: :invalid,
            created_at: ~N[2026-05-05 14:00:00],
            modified_at: "2026-05-05T14:30:00Z"
          }
        })

      assert {:errors, errors} = CheckEmbeddedFiles.check(doc, doc)

      assert {:invalid_embedded_file_filename, ""} in errors
      assert {:invalid_embedded_file_mime_type, nil} in errors
      assert {:invalid_embedded_file_description, :invalid} in errors
      assert {:invalid_embedded_file_timestamp, :created_at, ~N[2026-05-05 14:00:00]} in errors
      assert {:invalid_embedded_file_timestamp, :modified_at, "2026-05-05T14:30:00Z"} in errors
    end
  end

  describe "Validate.run/1" do
    test "aggregates embedded-file validation tuples in the validate-stage error envelope" do
      doc =
        embedded_file_document(%{
          invoice_csv: %{
            logical_name: :invoice_csv,
            source_kind: :binary,
            bytes: "a,b\n1,2\n",
            byte_size: 8,
            filename: "invoice.csv",
            mime_type: "text/csv"
          },
          backup_csv: %{
            logical_name: :backup_csv,
            source_kind: :binary,
            bytes: "x,y\n3,4\n",
            byte_size: 8,
            filename: "invoice.csv",
            mime_type: ""
          }
        })

      assert {:error,
              %Rendro.Error{
                stage: :validate,
                reason: :structural_corruption,
                details: %{errors: errors}
              }} = Validate.run(doc)

      assert {:duplicate_embedded_file_name, "invoice.csv"} in errors
      assert {:invalid_embedded_file_mime_type, ""} in errors
    end
  end

  defp embedded_file_document(files) do
    %Document{embedded_file_registry: %EmbeddedFileRegistry{files: files}}
  end
end
