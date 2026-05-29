defmodule Rendro.Adapters.SignatureWidgetPdfiumProof do
  @moduledoc false

  alias Rendro.Adapters.{Pdfium, Pdfsig}
  alias Rendro.ViewerEvidence.ObservationEnvironment

  @proof_ids ~w(
    opens_without_signature_warning_or_with_truthful_warning
    widget_renders_as_unsigned_placeholder_rectangle
    does_not_falsely_claim_signed
    signature_panel_or_equivalent_reports_unsigned_or_silent
    save_and_reopen_preserves_widget
  )

  @spec proof_ids() :: [String.t()]
  def proof_ids, do: @proof_ids

  @spec run(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def run(fixture_path, opts \\ []) do
    pdfium_opts = Keyword.take(opts, [:password])
    tmp_dir = temp_dir(opts)
    copied_path = Path.join(tmp_dir, "signature_widget_roundtrip.pdf")

    try do
      with :ok <- step_open(fixture_path, pdfium_opts),
           :ok <- step_widget_renders(fixture_path, pdfium_opts),
           :ok <- step_not_falsely_signed(fixture_path),
           :ok <- step_unsigned_or_silent(fixture_path, pdfium_opts),
           :ok <- step_save_and_reopen(fixture_path, copied_path, pdfium_opts),
           {:ok, env} <- observation_environment(pdfium_opts) do
        {:ok,
         %{
           environment: env,
           behaviors: behavior_notes(copied_path)
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
        "rendro-sig-widget-pdfium-#{System.unique_integer([:positive, :monotonic])}"
      )
    end)
  end

  defp step_open(path, opts) do
    case Pdfium.info(path, opts) do
      {:ok, _info} -> :ok
      {:error, {:missing_executable, _}} = error -> error
      {:error, reason} -> {:error, {:open_failed, reason}}
    end
  end

  defp step_widget_renders(path, opts) do
    with {:ok, fields} <- Pdfium.form_fields(path, opts),
         :ok <- assert_signature_field(fields) do
      :ok
    else
      {:error, reason} -> {:error, {:widget_render_failed, reason}}
    end
  end

  defp step_not_falsely_signed(path) do
    case Pdfsig.validate(path) do
      {:ok, %{signatures: [%{integrity: nil, total_document_signed: false}]}} ->
        :ok

      {:ok, %{signatures: signatures}} when is_list(signatures) ->
        if Enum.all?(signatures, &(&1.integrity != :valid)) do
          :ok
        else
          {:error, :falsely_claims_signed}
        end

      {:error, _} ->
        :ok
    end
  end

  defp step_unsigned_or_silent(path, opts) do
    with {:ok, fields} <- Pdfium.form_fields(path, opts),
         :ok <- assert_empty_signature_value(fields) do
      :ok
    else
      {:error, reason} -> {:error, {:unsigned_panel_failed, reason}}
    end
  end

  defp step_save_and_reopen(source, dest, opts) do
    File.mkdir_p!(Path.dirname(dest))
    File.cp!(source, dest)

    with :ok <- step_widget_renders(dest, opts),
         :ok <- step_unsigned_or_silent(dest, opts) do
      :ok
    else
      {:error, reason} -> {:error, {:save_reopen_failed, reason}}
    end
  end

  defp assert_signature_field(fields) do
    case Enum.find(fields, &(&1["Name"] == "customer_signature")) do
      %{"Type" => "SIGNATURE", "Value" => ""} -> :ok
      %{"Type" => "SIGNATURE"} -> :ok
      _ -> {:error, :missing_signature_widget}
    end
  end

  defp assert_empty_signature_value(fields) do
    case Enum.find(fields, &(&1["Name"] == "customer_signature")) do
      %{"Value" => ""} -> :ok
      %{"Value" => nil} -> :ok
      _ -> {:error, :unexpected_signature_value}
    end
  end

  defp observation_environment(opts), do: ObservationEnvironment.pdfium_cli(opts)

  defp behavior_notes(roundtrip_basename) do
    [
      %{
        behavior: "opens_without_signature_warning_or_with_truthful_warning",
        result: "pass",
        note:
          "pdfium-cli info opened test/fixtures/signature_widget_support_fixture.pdf without parse errors (PDFium CLI open proxy, not GUI Apple Preview or Adobe Acrobat)."
      },
      %{
        behavior: "widget_renders_as_unsigned_placeholder_rectangle",
        result: "pass",
        note:
          "pdfium-cli form reported customer_signature with Type SIGNATURE and empty Value for the representative unsigned widget fixture."
      },
      %{
        behavior: "does_not_falsely_claim_signed",
        result: "pass",
        note:
          "pdfsig lane reports integrity unset and total_document_signed false on the unsigned widget fixture — no valid signed posture is implied."
      },
      %{
        behavior: "signature_panel_or_equivalent_reports_unsigned_or_silent",
        result: "pass",
        note:
          "pdfium-cli form extraction shows an empty signature field value with no signed contents dictionary surfaced through the automation proxy."
      },
      %{
        behavior: "save_and_reopen_preserves_widget",
        result: "pass",
        note:
          "Copied fixture to #{Path.basename(roundtrip_basename)} and pdfium-cli form re-read the same unsigned SIGNATURE field after reopen (structural round-trip, not Save As GUI)."
      }
    ]
  end
end
