defmodule Rendro.ViewerEvidence.FormsApplePreviewProof do
  @moduledoc false

  alias Rendro.ViewerEvidence.{FormsPdfiumProof, ObservationEnvironment}

  @spec proof_ids() :: [String.t()]
  def proof_ids, do: FormsPdfiumProof.proof_ids()

  @spec run(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def run(fixture_path, opts \\ []) do
    with {:ok, proof} <- FormsPdfiumProof.run(fixture_path, opts),
         {:ok, env} <- ObservationEnvironment.pdfium_cli(opts) do
      {:ok,
       %{
         environment: env,
         behaviors: apple_preview_behaviors(proof.behaviors)
       }}
    end
  end

  defp apple_preview_behaviors(behaviors) do
    Enum.map(behaviors, fn %{behavior: id} = entry ->
      note =
        case id do
          "open" ->
            "pdfium-cli info opened the forms fixture without parse errors (structural proxy for the forms × Apple Preview matrix row — does not re-run Preview GUI)."

          "default_state_visible" ->
            "pdfium-cli form reported email, terms checkbox, and contact radio default widget values for the representative forms fixture (structural AcroForm bytes, not Preview widget rendering)."

          "edit_or_toggle" ->
            "Automation proxy re-rendered edited fixture bytes; pdfium-cli form confirmed toggled widget values (structural round-trip, not Preview edit/toggle GUI)."

          "save" ->
            "pdfium-cli re-read persisted widget values after edited fixture write (structural save round-trip, not Preview Save As GUI)."

          _ ->
            entry.note
        end

      Map.put(entry, :note, note)
    end)
  end
end
