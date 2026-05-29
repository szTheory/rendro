defmodule Rendro.ViewerEvidence.EmbeddedFilesPdfiumProof do
  @moduledoc false

  alias Rendro.Adapters.Pdfium
  alias Rendro.ViewerEvidence.ObservationEnvironment

  @proof_ids ~w(discoverable open_or_extract save_or_extract)

  @spec proof_ids() :: [String.t()]
  def proof_ids, do: @proof_ids

  @spec run(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def run(fixture_path, opts \\ []) do
    pdfium_opts = Keyword.take(opts, [:password])

    with :ok <- step_open(fixture_path, pdfium_opts),
         {:ok, pdf} <- read_fixture(fixture_path),
         :ok <- step_discoverable(pdf),
         :ok <- step_open_or_extract(pdf),
         :ok <- step_save_or_extract(fixture_path),
         {:ok, env} <- ObservationEnvironment.pdfium_cli(pdfium_opts) do
      {:ok, %{environment: env, behaviors: behavior_notes()}}
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

  defp step_discoverable(pdf) do
    if pdf =~ "/EmbeddedFiles <<" and pdf =~ "(invoice.csv)" do
      :ok
    else
      {:error, :embedded_files_not_discoverable_in_bytes}
    end
  end

  defp step_open_or_extract(pdf) do
    if pdf =~ "/Type /EmbeddedFile" and pdf =~ "/Desc (Billing export)" do
      :ok
    else
      {:error, :embedded_file_stream_missing}
    end
  end

  defp step_save_or_extract(path) do
    if File.regular?(path) and File.stat!(path).size > 0 do
      :ok
    else
      {:error, :fixture_not_on_disk}
    end
  end

  defp behavior_notes do
    [
      %{
        behavior: "discoverable",
        result: "pass",
        note:
          "Committed fixture bytes include /EmbeddedFiles and invoice.csv Filespec markers (structural proxy — not Acrobat Attachments pane GUI)."
      },
      %{
        behavior: "open_or_extract",
        result: "pass",
        note:
          "EmbeddedFile stream and Billing export description present in authored PDF bytes (structural open/extract proxy, not Attachments pane extract GUI)."
      },
      %{
        behavior: "save_or_extract",
        result: "pass",
        note:
          "Committed fixture path resolves on disk with non-zero size after generation (structural save/extract proxy, not Save to disk GUI)."
      }
    ]
  end
end
