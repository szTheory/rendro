defmodule Rendro.Adapters.LongLivedAcrobatProof do
  @moduledoc false

  alias Rendro.Adapters.{Pdfium, PyHanko}
  alias Rendro.ViewerEvidence.ObservationEnvironment

  @proof_ids ~w(
    opens_long_lived_artifact_without_corruption
    timestamp_recognized_or_silent
    revocation_evidence_recognized_or_silent
    posture_reported_truthfully
    expiry_behavior_honest
  )

  def proof_ids, do: @proof_ids

  def run(fixture_path, opts \\ []) do
    pdfium_opts = Keyword.take(opts, [:password])

    with :ok <- step_open(fixture_path, pdfium_opts),
         {:ok, posture} <- PyHanko.validate(fixture_path),
         :ok <- step_posture(posture),
         {:ok, env} <- ObservationEnvironment.pyhanko_cli(opts) do
      {:ok, %{environment: env, behaviors: behavior_notes(posture)}}
    end
  end

  defp step_open(path, opts) do
    case Pdfium.info(path, opts) do
      {:ok, _info} -> :ok
      {:error, {:missing_executable, _}} = error -> error
      {:error, reason} -> {:error, {:open_failed, reason}}
    end
  end

  defp step_posture(%{signatures: [signature | _]}) do
    cond do
      signature.integrity != :valid -> {:error, {:integrity_not_valid, signature.integrity}}
      signature.timestamp != :present -> {:error, {:timestamp_missing, signature.timestamp}}
      signature.revocation != :embedded -> {:error, {:revocation_missing, signature.revocation}}
      true -> :ok
    end
  end

  defp step_posture(_), do: {:error, :missing_signature_posture}

  defp behavior_notes(%{signatures: [signature | _]}) do
    [
      %{
        behavior: "opens_long_lived_artifact_without_corruption",
        result: "pass",
        note:
          "pdfium-cli info opened test/fixtures/long_lived_viewer_proof.pdf without parse errors (structural proxy for long_lived_signed_artifact × Adobe Acrobat Reader — does not re-run Acrobat LTV GUI)."
      },
      %{
        behavior: "timestamp_recognized_or_silent",
        result: "pass",
        note:
          "pyHanko validation lane reports document timestamp #{signature.timestamp} on the certomancer-backed long-lived fixture (adapter posture, not Acrobat timestamp panel UI)."
      },
      %{
        behavior: "revocation_evidence_recognized_or_silent",
        result: "pass",
        note:
          "pyHanko validation lane reports revocation #{signature.revocation} embedded in the augmented artifact (adapter posture, not Acrobat revocation UI)."
      },
      %{
        behavior: "posture_reported_truthfully",
        result: "pass",
        note:
          "pyHanko validation reports integrity #{signature.integrity} and embedded validation evidence posture without conflating certificate trust (#{signature.trust})."
      },
      %{
        behavior: "expiry_behavior_honest",
        result: "pass",
        note:
          "pyHanko validation completed on the representative long-lived fixture; expiry and trust-store policy remain external to Rendro and are not claimed via Acrobat GUI observation."
      }
    ]
  end
end
