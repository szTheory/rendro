defmodule Rendro.ViewerEvidence.FormsAcrobatProof do
  @moduledoc false

  alias Rendro.ViewerEvidence.{FormsPdfiumProof, ObservationEnvironment}

  def proof_ids, do: FormsPdfiumProof.proof_ids()

  def run(fixture_path, opts \\ []) do
    with {:ok, proof} <- FormsPdfiumProof.run(fixture_path, opts),
         {:ok, env} <- ObservationEnvironment.pdfium_cli(opts) do
      {:ok, %{environment: env, behaviors: acrobat_behaviors(proof.behaviors)}}
    end
  end

  defp acrobat_behaviors(behaviors) do
    Enum.map(behaviors, fn %{behavior: id} = entry ->
      note =
        case id do
          "open" ->
            "pdfium-cli info opened the forms fixture without parse errors (structural proxy for forms × Adobe Acrobat Reader — does not re-run Acrobat GUI)."

          "default_state_visible" ->
            "pdfium-cli form reported default AcroForm widget values for the representative forms fixture (structural bytes, not Acrobat field panel rendering)."

          "edit_or_toggle" ->
            "Automation proxy re-rendered edited fixture bytes; pdfium-cli form confirmed toggled widget values (structural round-trip, not Acrobat edit/toggle GUI)."

          "save" ->
            "pdfium-cli re-read persisted widget values after edited fixture write (structural round-trip, not Acrobat Save As GUI)."

          _ ->
            entry.note
        end

      Map.put(entry, :note, note)
    end)
  end
end
