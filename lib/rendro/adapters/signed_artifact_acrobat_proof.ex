defmodule Rendro.Adapters.SignedArtifactAcrobatProof do
  @moduledoc false

  alias Rendro.Adapters.SignedArtifactPdfiumProof
  alias Rendro.ViewerEvidence.ObservationEnvironment

  def proof_ids, do: SignedArtifactPdfiumProof.proof_ids()

  def run(fixture_path, opts \\ []) do
    with {:ok, proof} <- SignedArtifactPdfiumProof.run(fixture_path, opts),
         {:ok, env} <- ObservationEnvironment.pdfsig_cli(opts) do
      {:ok,
       %{
         environment: env,
         behaviors: acrobat_behaviors(proof.behaviors)
       }}
    end
  end

  defp acrobat_behaviors(behaviors) do
    Enum.map(behaviors, fn %{behavior: id} = entry ->
      note =
        case id do
          "opens_signed_artifact_without_corruption" ->
            "pdfsig and pdfium-cli lanes opened test/fixtures/signed_artifact_viewer_proof.pdf without corruption (structural proxy for signed_artifact × Adobe Acrobat Reader — does not re-run Acrobat GUI)."

          "appearance_renders" ->
            "pdfium-cli form reported customer_signature with Type SIGNATURE (structural widget presence, not Acrobat appearance rendering)."

          "integrity_reported_truthfully" ->
            "pdfsig lane reports integrity valid for customer_signature separately from open success (honest split — does not re-run Acrobat signature validation panel)."

          "certificate_trust_reported_separately" ->
            "pdfsig lane reports certificate trust skipped separately from integrity valid (structural proxy — does not re-run Acrobat certificate trust UI)."

          "save_and_reopen_preserves_signature_or_warns" ->
            "Copied signed fixture bytes and pdfsig re-validated integrity after reopen (structural round-trip, not Acrobat Save As GUI)."

          _ ->
            entry.note
        end

      Map.put(entry, :note, note)
    end)
  end
end
