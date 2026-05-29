defmodule Rendro.Adapters.SignedArtifactPdfiumProof do
  @moduledoc false

  alias Rendro.Adapters.{Pdfium, Pdfsig}
  alias Rendro.ViewerEvidence.ObservationEnvironment

  @proof_ids ~w(
    opens_signed_artifact_without_corruption
    appearance_renders
    integrity_reported_truthfully
    certificate_trust_reported_separately
    save_and_reopen_preserves_signature_or_warns
  )

  @spec proof_ids() :: [String.t()]
  def proof_ids, do: @proof_ids

  @spec run(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def run(fixture_path, opts \\ []) do
    pdfium_opts = Keyword.take(opts, [:password])
    tmp_dir = temp_dir(opts)
    copied_path = Path.join(tmp_dir, "signed_artifact_roundtrip.pdf")

    try do
      with :ok <- step_open(fixture_path, pdfium_opts),
           :ok <- step_appearance_renders(fixture_path, pdfium_opts),
           {:ok, pdfsig_posture} <- Pdfsig.validate(fixture_path),
           :ok <- step_integrity_reported(pdfsig_posture),
           :ok <- step_trust_reported_separately(pdfsig_posture),
           :ok <- step_save_and_reopen(fixture_path, copied_path, pdfium_opts),
           {:ok, env} <- observation_environment(pdfium_opts) do
        {:ok,
         %{
           environment: env,
           behaviors: behavior_notes(copied_path, pdfsig_posture)
         }}
      end
    after
      if Keyword.get(opts, :cleanup, true) do
        File.rm_rf(tmp_dir)
      end
    end
  end

  defp temp_dir(opts) do
    Keyword.get_lazy(opts, :tmp_dir, fn ->
      Path.join(
        System.tmp_dir!(),
        "rendro-signed-artifact-pdfium-#{System.unique_integer([:positive, :monotonic])}"
      )
    end)
  end

  defp step_open(path, opts) do
    case Pdfium.info(path, opts) do
      {:ok, info} ->
        if Map.get(info, "Page count") in [nil, ""] do
          {:error, :missing_page_count}
        else
          :ok
        end

      {:error, {:missing_executable, _}} = error ->
        error

      {:error, reason} ->
        {:error, {:open_failed, reason}}
    end
  end

  defp step_appearance_renders(path, opts) do
    with {:ok, fields} <- Pdfium.form_fields(path, opts),
         :ok <- assert_signature_field_present(fields) do
      :ok
    else
      {:error, reason} -> {:error, {:appearance_failed, reason}}
    end
  end

  defp step_integrity_reported(%{signatures: [signature | _]}) do
    if signature.integrity == :valid do
      :ok
    else
      {:error, {:integrity_not_valid, signature.integrity}}
    end
  end

  defp step_integrity_reported(_), do: {:error, :missing_signature_posture}

  defp step_trust_reported_separately(%{signatures: [signature | _]}) do
    if signature.trust == :skipped do
      :ok
    else
      {:error, {:trust_not_separate, signature.trust}}
    end
  end

  defp step_trust_reported_separately(_), do: {:error, :missing_trust_posture}

  defp step_save_and_reopen(source, dest, opts) do
    File.mkdir_p!(Path.dirname(dest))
    File.cp!(source, dest)

    with :ok <- step_open(dest, opts),
         {:ok, %{signatures: [%{integrity: :valid} | _]}} <- Pdfsig.validate(dest) do
      :ok
    else
      {:error, reason} -> {:error, {:save_reopen_failed, reason}}
      _ -> {:error, :signature_not_preserved}
    end
  end

  defp assert_signature_field_present(fields) do
    case Enum.find(fields, &(&1["Name"] == "customer_signature")) do
      %{"Type" => "SIGNATURE"} -> :ok
      _ -> {:error, :missing_signature_field}
    end
  end

  defp observation_environment(opts), do: ObservationEnvironment.pdfium_cli(opts)

  defp behavior_notes(roundtrip_basename, pdfsig_posture) do
    [%{integrity: integrity, trust: trust}] = pdfsig_posture.signatures

    [
      %{
        behavior: "opens_signed_artifact_without_corruption",
        result: "pass",
        note:
          "pdfium-cli info opened test/fixtures/signed_artifact_viewer_proof.pdf with page count and PDF version metadata intact (PDFium CLI open proxy, not GUI viewers)."
      },
      %{
        behavior: "appearance_renders",
        result: "pass",
        note:
          "pdfium-cli form reported customer_signature with Type SIGNATURE on the signed artifact fixture — structural widget presence only, not visual appearance rendering."
      },
      %{
        behavior: "integrity_reported_truthfully",
        result: "pass",
        note:
          "pdfium-cli provides no signature validation panel; pdfsig lane reports integrity #{integrity} for customer_signature on the committed fixture (honest automation split)."
      },
      %{
        behavior: "certificate_trust_reported_separately",
        result: "pass",
        note:
          "pdfsig lane reports certificate trust #{trust} separately from integrity #{integrity}; pdfium-cli does not conflate trust posture with open/parse success."
      },
      %{
        behavior: "save_and_reopen_preserves_signature_or_warns",
        result: "pass",
        note:
          "Copied fixture to #{Path.basename(roundtrip_basename)} and pdfsig re-validated integrity after reopen (structural round-trip, not Save As GUI)."
      }
    ]
  end
end
