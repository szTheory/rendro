defmodule Rendro.Adapters.ProtectedValidationLiveTest do
  use ExUnit.Case, async: false

  alias Rendro.Adapters.Poppler
  alias Rendro.Protect

  @tag live_pdf_tools: true
  test "real qpdf plus pdfinfo prove protected structural validation" do
    qpdf = System.find_executable("qpdf")
    pdfinfo = System.find_executable("pdfinfo")

    cond do
      is_nil(qpdf) ->
        IO.puts("Skipping live protected validation test: qpdf is not installed")
        :ok

      is_nil(pdfinfo) ->
        IO.puts("Skipping live protected validation test: pdfinfo is not installed")
        :ok

      true ->
        tmp_dir =
          Path.join(
            System.tmp_dir!(),
            "rendro-live-protected-#{System.unique_integer([:positive, :monotonic])}"
          )

        File.mkdir_p!(tmp_dir)
        on_exit(fn -> File.rm_rf(tmp_dir) end)

        open_password = "open-secret"
        owner_password = "owner-secret"
        wrong_password = "wrong-secret"

        {:ok, artifact} = Rendro.render_to_artifact(sample_document(), deterministic: true)

        {:ok, protected} =
          Protect.password(artifact,
            open_password: open_password,
            owner_password: owner_password,
            advisory_permissions: [:copy, :print]
          )

        protected_path = Path.join(tmp_dir, "protected.pdf")
        File.write!(protected_path, protected.binary)

        assert {_, 0} =
                 System.cmd(qpdf, ["--is-encrypted", protected_path], stderr_to_stdout: true)

        assert {_, 0} =
                 System.cmd(qpdf, ["--requires-password", protected_path], stderr_to_stdout: true)

        assert {:error, {:invalid_pdf, :password_required}} = Poppler.validate(protected_path)

        assert {:error, {:invalid_pdf, :incorrect_password}} =
                 Poppler.validate(protected_path, open_password: wrong_password)

        assert {:ok, metadata} = Poppler.validate(protected_path, open_password: open_password)
        assert String.starts_with?(metadata["Encrypted"], "yes")
        assert metadata["Pages"] == "1"

        {:ok, owner_fallback_artifact} =
          Protect.password(artifact,
            open_password: "fallback-open-secret",
            owner_password: owner_password,
            advisory_permissions: [:copy]
          )

        owner_fallback_path = Path.join(tmp_dir, "owner-fallback.pdf")
        File.write!(owner_fallback_path, owner_fallback_artifact.binary)

        assert {:ok, owner_metadata} =
                 Poppler.validate(owner_fallback_path, owner_password: owner_password)

        assert String.starts_with?(owner_metadata["Encrypted"], "yes")
    end
  end

  defp sample_document do
    Rendro.fixed([
      Rendro.page(
        blocks: [
          Rendro.block(
            Rendro.text("Protected validation", size: 12),
            x: 36,
            y: 72
          ),
          Rendro.block(
            Rendro.text("Phase 52 live structural proof", size: 10),
            x: 36,
            y: 96
          )
        ]
      )
    ])
  end
end
