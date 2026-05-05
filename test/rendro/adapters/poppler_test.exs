defmodule Rendro.Adapters.PopplerTest do
  use ExUnit.Case, async: true
  alias Rendro.Adapters.Poppler

  describe "validate/1" do
    test "returns missing executable when pdfinfo is not installed, or skips if installed" do
      case System.find_executable("pdfinfo") do
        nil ->
          assert {:error, {:missing_executable, "pdfinfo"}} = Poppler.validate("dummy.pdf")

        _ ->
          IO.puts("Skipping missing executable test: pdfinfo is installed")
          :ok
      end
    end

    test "returns invalid_pdf for corrupt file" do
      case System.find_executable("pdfinfo") do
        nil ->
          IO.puts("Skipping corrupt file test: pdfinfo not installed")
          :ok

        _executable ->
          path = Path.join(System.tmp_dir!(), "corrupt_#{System.unique_integer([:positive])}.pdf")
          File.write!(path, "not a pdf")

          assert {:error, {:invalid_pdf, error_msg}} = Poppler.validate(path)
          assert is_binary(error_msg)

          File.rm!(path)
      end
    end

    test "returns metadata map for valid pdf" do
      case System.find_executable("pdfinfo") do
        nil ->
          IO.puts("Skipping valid pdf test: pdfinfo not installed")
          :ok

        _executable ->
          path = Path.join(System.tmp_dir!(), "valid_#{System.unique_integer([:positive])}.pdf")

          # Minimal valid PDF
          valid_pdf = """
          %PDF-1.4
          1 0 obj
          << /Type /Catalog /Pages 2 0 R >>
          endobj
          2 0 obj
          << /Type /Pages /Kids [3 0 R] /Count 1 >>
          endobj
          3 0 obj
          << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >>
          endobj
          xref
          0 4
          0000000000 65535 f 
          0000000009 00000 n 
          0000000058 00000 n 
          0000000115 00000 n 
          trailer
          << /Size 4 /Root 1 0 R >>
          startxref
          186
          %%EOF
          """

          File.write!(path, valid_pdf)

          assert {:ok, metadata} = Poppler.validate(path)
          assert is_map(metadata)

          File.rm!(path)
      end
    end
  end
end
