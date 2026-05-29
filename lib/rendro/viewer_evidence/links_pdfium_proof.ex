defmodule Rendro.ViewerEvidence.LinksPdfiumProof do
  @moduledoc false

  alias Rendro.Adapters.Pdfium
  alias Rendro.ViewerEvidence.ObservationEnvironment

  @proof_ids ~w(external_uri_handoff internal_page_navigation)

  @spec proof_ids() :: [String.t()]
  def proof_ids, do: @proof_ids

  @spec run(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def run(fixture_path, opts \\ []) do
    viewer = Keyword.fetch!(opts, :viewer)
    pdfium_opts = Keyword.take(opts, [:password])

    with :ok <- step_open(fixture_path, pdfium_opts),
         {:ok, pdf} <- read_fixture(fixture_path),
         :ok <- step_external_uri(pdf),
         :ok <- step_internal_page(pdf),
         {:ok, env} <- ObservationEnvironment.pdfium_cli(pdfium_opts) do
      {:ok, %{environment: env, behaviors: behavior_notes(viewer)}}
    end
  end

  defp step_open(path, opts) do
    case Pdfium.info(path, opts) do
      {:ok, _} -> :ok
      {:error, {:missing_executable, _}} = error -> error
      {:error, reason} -> {:error, {:open_failed, reason}}
    end
  end

  defp read_fixture(path) do
    case File.read(path) do
      {:ok, pdf} -> {:ok, pdf}
      {:error, reason} -> {:error, {:read_fixture_failed, reason}}
    end
  end

  defp step_external_uri(pdf) do
    if pdf =~ "/URI (https://example.com/docs)" do
      :ok
    else
      {:error, :external_uri_missing}
    end
  end

  defp step_internal_page(pdf) do
    if pdf =~ ~r|/Dest \[\d+ 0 R /Fit\]| do
      :ok
    else
      {:error, :internal_page_dest_missing}
    end
  end

  defp behavior_notes("apple_preview") do
    [
      %{
        behavior: "external_uri_handoff",
        result: "pass",
        note:
          "Authored /URI (https://example.com/docs) link annotation present in fixture bytes (structural proxy for links × Apple Preview — does not exercise Preview URI handoff GUI)."
      },
      %{
        behavior: "internal_page_navigation",
        result: "pass",
        note:
          "Authored internal /Dest page link annotation present in fixture bytes (structural proxy only). This row covers links only — embedded_files × Apple Preview remains unverified (D-07 independence)."
      }
    ]
  end

  defp behavior_notes("adobe_acrobat_reader") do
    [
      %{
        behavior: "external_uri_handoff",
        result: "pass",
        note:
          "Authored /URI (https://example.com/docs) link annotation present in fixture bytes (structural proxy — not Acrobat external link handoff GUI)."
      },
      %{
        behavior: "internal_page_navigation",
        result: "pass",
        note:
          "Authored internal /Dest page link annotation present in fixture bytes (structural proxy — not Acrobat internal navigation GUI)."
      }
    ]
  end
end
