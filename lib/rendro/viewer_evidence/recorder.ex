defmodule Rendro.ViewerEvidence.Recorder do
  @moduledoc false

  alias Rendro.Adapters.{
    SignedArtifactPdfiumProof,
    SignatureWidgetPdfiumProof
  }

  alias Rendro.ViewerEvidence.{
    EmbeddedFilesPdfiumProof,
    FormsApplePreviewProof,
    FormsPdfiumProof,
    LinksPdfiumProof,
    ProtectionPopplerProof
  }

  @default_fixture "test/fixtures/forms_support_fixture.pdf"
  @embedded_fixture "test/fixtures/embedded_artifact_support_fixture.pdf"
  @protection_fixture "test/fixtures/protection_support_fixture.pdf"
  @signature_widget_fixture "test/fixtures/signature_widget_support_fixture.pdf"
  @signed_artifact_fixture "test/fixtures/signed_artifact_viewer_proof.pdf"

  @spec record!(String.t(), String.t(), keyword()) :: map()
  def record!(surface, viewer, opts \\ []) do
    case record(surface, viewer, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, inspect(reason)
    end
  end

  @spec record(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def record(surface, viewer, opts \\ []) do
    case Map.fetch(recordings(), {surface, viewer}) do
      {:ok, config} -> record_with_config(surface, viewer, config, opts)
      :error -> {:error, {:unsupported_recording, surface, viewer}}
    end
  end

  @spec record_forms_chrome_pdfium!(keyword()) :: map()
  def record_forms_chrome_pdfium!(opts \\ []), do: record!("forms", "chrome_pdfium", opts)

  @spec record_forms_chrome_pdfium(keyword()) :: {:ok, map()} | {:error, term()}
  def record_forms_chrome_pdfium(opts \\ []), do: record("forms", "chrome_pdfium", opts)

  defp recordings do
    %{
      {"forms", "chrome_pdfium"} => %{
        proof: FormsPdfiumProof,
        fixture: @default_fixture,
        evidence_path: "priv/viewer_evidence/forms/chrome_pdfium.md",
        body: &forms_chrome_pdfium_body/1
      },
      {"forms", "apple_preview"} => %{
        proof: FormsApplePreviewProof,
        fixture: @default_fixture,
        evidence_path: "priv/viewer_evidence/forms/apple_preview.md",
        body: &forms_apple_preview_body/1
      },
      {"embedded_files", "adobe_acrobat_reader"} => %{
        proof: EmbeddedFilesPdfiumProof,
        fixture: @embedded_fixture,
        evidence_path: "priv/viewer_evidence/embedded_files/adobe_acrobat_reader.md",
        body: &embedded_files_acrobat_body/1
      },
      {"links", "adobe_acrobat_reader"} => %{
        proof: LinksPdfiumProof,
        fixture: @embedded_fixture,
        evidence_path: "priv/viewer_evidence/links/adobe_acrobat_reader.md",
        proof_opts: [viewer: "adobe_acrobat_reader"],
        body: &links_acrobat_body/1
      },
      {"links", "apple_preview"} => %{
        proof: LinksPdfiumProof,
        fixture: @embedded_fixture,
        evidence_path: "priv/viewer_evidence/links/apple_preview.md",
        proof_opts: [viewer: "apple_preview"],
        body: &links_preview_body/1
      },
      {"protection", "apple_preview"} => %{
        proof: ProtectionPopplerProof,
        fixture: @protection_fixture,
        evidence_path: "priv/viewer_evidence/protection/apple_preview.md",
        body: &protection_preview_body/1
      },
      {"signature_widget", "chrome_pdfium"} => %{
        proof: SignatureWidgetPdfiumProof,
        fixture: @signature_widget_fixture,
        evidence_path: "priv/viewer_evidence/signature_widget/chrome_pdfium.md",
        body: &signature_widget_chrome_pdfium_body/1
      },
      {"signed_artifact", "chrome_pdfium"} => %{
        proof: SignedArtifactPdfiumProof,
        fixture: @signed_artifact_fixture,
        evidence_path: "priv/viewer_evidence/signed_artifact/chrome_pdfium.md",
        body: &signed_artifact_chrome_pdfium_body/1
      }
    }
  end

  defp record_with_config(surface, viewer, config, opts) do
    fixture = Keyword.get(opts, :fixture, config.fixture)
    recorded_at = Keyword.get(opts, :recorded_at, Date.utc_today() |> Date.to_iso8601())
    recorded_by = Keyword.get(opts, :recorded_by, "ci:viewer-evidence-live-proof")
    evidence_path = Keyword.get(opts, :evidence_path, config.evidence_path)

    proof_opts =
      Keyword.merge(
        Map.get(config, :proof_opts, []),
        Keyword.take(opts, [:password, :open_password, :cleanup, :tmp_dir])
      )

    with {:ok, proof} <- config.proof.run(fixture, proof_opts),
         content =
           build_markdown(
             surface,
             viewer,
             proof,
             fixture,
             recorded_at,
             recorded_by,
             config.body.(fixture)
           ),
         :ok <- write_evidence(evidence_path, content) do
      {:ok,
       %{
         evidence_path: evidence_path,
         recorded_at: recorded_at,
         viewer_version: proof.environment.viewer_version,
         platform: proof.environment.platform,
         content: content
       }}
    end
  end

  defp build_markdown(surface, viewer, proof, fixture, recorded_at, recorded_by, body) do
    behaviors_yaml =
      proof.behaviors
      |> Enum.map(&behavior_yaml/1)
      |> Enum.join("\n")

    content =
      """
      ---
      schema_version: 1
      surface: #{surface}
      viewer: #{viewer}
      viewer_version: "#{escape_yaml(proof.environment.viewer_version)}"
      platform: "#{escape_yaml(proof.environment.platform)}"
      recorded_at: "#{recorded_at}"
      recorded_by: "#{escape_yaml(recorded_by)}"
      fixture: "#{fixture}"
      behaviors:
      #{behaviors_yaml}
      ---

      #{body}
      """
      |> String.trim()

    content <> "\n"
  end

  defp behavior_yaml(%{behavior: id, result: result, note: note}) do
    """
      - behavior: #{id}
        result: #{result}
        note: "#{escape_yaml(note)}"
    """
    |> String.trim_trailing()
  end

  defp escape_yaml(value) do
    value
    |> to_string()
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
  end

  defp write_evidence(path, content) do
    absolute = Path.expand(path)
    File.mkdir_p!(Path.dirname(absolute))
    File.write!(absolute, content)
    :ok
  end

  defp forms_chrome_pdfium_body(_fixture) do
    """
    This evidence records **forms × chrome_pdfium** using pdfium-cli on Linux/macOS CI.
    PDFium CLI structural and form-field extraction is an automation proxy — it does not
    validate GUI Apple Preview or Adobe Acrobat behavior.

    Fixture regeneration:

    ```elixir
    MIX_ENV=test mix run -e 'Rendro.Test.FormSupportFixture.write_fixture("test/fixtures/forms_support_fixture.pdf")'
    ```

    Boundary: Poppler/pdfinfo structural proof and pdfium-cli form extraction prove authored
    AcroForm bytes and field values only. Promoting this cell does not promote other viewers
    or surfaces.
    """
    |> String.trim()
  end

  defp forms_apple_preview_body(_fixture) do
    """
    This evidence records **forms × Apple Preview** using pdfium-cli structural re-attestation on Linux CI.
    Original v1.8 Phase 47 GUI validation date **2026-05-05** is cited here for provenance only — CI does
    not re-run Apple Preview GUI in this lane.

    pdfium-cli form extraction is an automation proxy — it does not validate Apple Preview GUI behavior
    and does not inherit `forms × chrome_pdfium` automation as Preview GUI proof (cross-boundary negation).

    Fixture regeneration:

    ```elixir
    MIX_ENV=test mix run -e 'Rendro.Test.FormSupportFixture.write_fixture("test/fixtures/forms_support_fixture.pdf")'
    ```
    """
    |> String.trim()
  end

  defp embedded_files_acrobat_body(_fixture) do
    """
    This evidence records **embedded_files × Adobe Acrobat Reader** using pdfium-cli and authored-byte
    structural checks on Linux CI. Original v1.9 Phase 50 validation date **2026-05-06** is cited for
    provenance only — CI does not re-run Acrobat Attachments pane GUI.

    Structural markers prove document-level embedded file bytes only; they do not validate Attachments pane
    discoverability, extract, or save-to-disk GUI behavior.

    Fixture regeneration:

    ```elixir
    MIX_ENV=test mix run -e 'Rendro.Test.EmbeddedArtifactSupportFixture.write_fixture("test/fixtures/embedded_artifact_support_fixture.pdf")'
    ```
    """
    |> String.trim()
  end

  defp links_acrobat_body(_fixture) do
    """
    This evidence records **links × Adobe Acrobat Reader** using pdfium-cli and authored-byte structural
    checks on the shared embedded-artifact fixture. Original v1.9 Phase 50 validation date **2026-05-06**
    is cited for provenance only — CI does not re-run Acrobat URI handoff or internal navigation GUI.

    Fixture regeneration:

    ```elixir
    MIX_ENV=test mix run -e 'Rendro.Test.EmbeddedArtifactSupportFixture.write_fixture("test/fixtures/embedded_artifact_support_fixture.pdf")'
    ```
    """
    |> String.trim()
  end

  defp links_preview_body(_fixture) do
    """
    This evidence records **links × Apple Preview** using pdfium-cli and authored-byte structural checks
    on the shared embedded-artifact fixture. Original v1.9 Phase 50 validation date **2026-05-06** is cited
    for provenance only — CI does not re-run Preview link GUI.

    This row covers **links only**. Apple Preview remains `unverified` for `embedded_files` discoverability
    (D-07 independence) — structural link bytes here do not promote embedded_files × Preview.

    Fixture regeneration:

    ```elixir
    MIX_ENV=test mix run -e 'Rendro.Test.EmbeddedArtifactSupportFixture.write_fixture("test/fixtures/embedded_artifact_support_fixture.pdf")'
    ```
    """
    |> String.trim()
  end

  defp protection_preview_body(_fixture) do
    """
    This evidence records **protection × Apple Preview** using pdfinfo and qpdf structural checks on Linux CI.
    Original v1.10 Phase 54 protection audit is cited for provenance only — CI does not re-run Preview password
    prompt, advisory print/copy UI, or Save As GUI.

    Regenerating the fixture produces **new bytes** and requires re-running this structural proof lane:

    ```bash
    mix run scripts/protected_viewer_proof_fixture.exs --output test/fixtures/protection_support_fixture.pdf
    ```

    Open passwords are supplied to validators at runtime only — never recorded in this evidence file.
    """
    |> String.trim()
  end

  defp signature_widget_chrome_pdfium_body(_fixture) do
    """
    This evidence records **signature_widget × chrome_pdfium** using pdfium-cli on Linux/macOS CI.
    PDFium CLI structural and form-field extraction is an automation proxy — it does not
    validate GUI Apple Preview or Adobe Acrobat signature panel behavior.

    Fixture regeneration:

    ```elixir
    MIX_ENV=test mix run -e 'Rendro.Test.SigningViewerSupportFixture.write_signature_widget_fixture("test/fixtures/signature_widget_support_fixture.pdf")'
    ```

    Boundary: pdfium-cli form extraction and pdfsig integrity posture prove authored unsigned
    `/Sig` widget bytes only. Promoting this cell does not promote manual GUI viewers or other surfaces.
    """
    |> String.trim()
  end

  defp signed_artifact_chrome_pdfium_body(_fixture) do
    """
    This evidence records **signed_artifact × chrome_pdfium** using pdfium-cli plus pdfsig on Linux/macOS CI.
    PDFium CLI open and form extraction is an automation proxy — it does not validate GUI signature panels
    in Apple Preview or Adobe Acrobat Reader.

    Fixture regeneration:

    ```bash
    mix run scripts/signed_artifact_viewer_proof_fixture.exs --output test/fixtures/signed_artifact_viewer_proof.pdf
    ```

    Boundary: pdfium-cli proves open/parse and widget presence; pdfsig lane supplies integrity and trust
    posture separately with honest "no validation panel" notes for PDFium CLI itself.
    """
    |> String.trim()
  end
end
