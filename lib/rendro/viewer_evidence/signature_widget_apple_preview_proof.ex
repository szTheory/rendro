defmodule Rendro.ViewerEvidence.SignatureWidgetApplePreviewProof do
  @moduledoc false

  alias Rendro.Adapters.SignatureWidgetPdfiumProof
  alias Rendro.ViewerEvidence.ObservationEnvironment

  def proof_ids, do: SignatureWidgetPdfiumProof.proof_ids()

  def run(fixture_path, opts \\ []) do
    with {:ok, proof} <- SignatureWidgetPdfiumProof.run(fixture_path, opts),
         {:ok, env} <- ObservationEnvironment.pdfium_cli(opts) do
      {:ok, %{environment: env, behaviors: preview_behaviors(proof.behaviors)}}
    end
  end

  defp preview_behaviors(behaviors) do
    Enum.map(behaviors, fn %{behavior: id} = entry ->
      note =
        case id do
          "opens_without_signature_warning_or_with_truthful_warning" ->
            "pdfium-cli info opened the signature widget fixture without parse errors (structural proxy for signature_widget × Apple Preview — does not re-run Preview GUI)."

          "widget_renders_as_unsigned_placeholder_rectangle" ->
            "pdfium-cli form reported customer_signature with Type SIGNATURE and empty Value (structural unsigned widget bytes, not Preview placeholder rectangle rendering)."

          "does_not_falsely_claim_signed" ->
            "pdfsig lane reports integrity unset on the unsigned widget fixture — Preview GUI is not re-run to confirm unsigned posture."

          "signature_panel_or_equivalent_reports_unsigned_or_silent" ->
            "pdfium-cli form extraction shows empty signature field value (structural proxy — does not re-run Preview signature UI)."

          "save_and_reopen_preserves_widget" ->
            "Copied fixture bytes and pdfium-cli re-read the same unsigned SIGNATURE field (structural round-trip, not Preview Save As GUI)."

          _ ->
            entry.note
        end

      Map.put(entry, :note, note)
    end)
  end
end
