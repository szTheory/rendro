defmodule Rendro.Error do
  @moduledoc """
  Structured diagnostics for render failures.

  The pipeline wraps stage failures in this struct so callers receive
  actionable context (`what/where/why/next`) plus correlation metadata.
  """
  @moduledoc tags: [:stable]

  @enforce_keys [:what, :where, :why, :next, :stage]
  defstruct [:what, :where, :why, :next, :stage, :reason, :render_id, details: %{}]

  @type t :: %__MODULE__{
          what: String.t(),
          where: String.t(),
          why: String.t(),
          next: String.t(),
          stage: atom(),
          reason: term() | nil,
          render_id: String.t() | nil,
          details: map()
        }

  @spec from_stage(atom(), term(), map()) :: t()
  def from_stage(stage, reason, context \\ %{}) when is_atom(stage) do
    %__MODULE__{
      what: what(stage, reason),
      where: "Rendro.Pipeline.#{stage_module_suffix(stage)}",
      why: why(stage, reason),
      next: next_step(stage, reason),
      stage: stage,
      reason: reason,
      render_id: Map.get(context, :render_id),
      details:
        Map.merge(
          %{
            document_type: Map.get(context, :document_type),
            deterministic: Map.get(context, :deterministic)
          },
          Map.get(context, :details, %{})
        )
    }
  end

  defp what(:build, _reason), do: "Input document failed pipeline validation."
  defp what(:compose, _reason), do: "Document composition failed before measurement."
  defp what(:measure, _reason), do: "Block measurement failed while computing dimensions."
  defp what(:paginate, _reason), do: "Pagination failed while assigning content to pages."
  defp what(:render, _reason), do: "PDF serialization failed during render."
  defp what(:validate, _reason), do: "Post-render validation failed."
  defp what(:protect, _reason), do: "PDF protection failed while wrapping the rendered artifact."

  defp what(:prepare, _reason),
    do: "PDF signing preparation failed while wrapping the rendered artifact."

  defp what(:sign, _reason), do: "PDF signing failed while wrapping the rendered artifact."

  defp what(:augment, _reason),
    do: "PDF long-lived augmentation failed while wrapping the signed artifact."

  defp what(stage, _reason), do: "Render pipeline failed in stage #{inspect(stage)}."

  defp why(:prepare, {:missing_required_option, :field}),
    do: "Missing required signing preparation option: field"

  defp why(:sign, {:missing_required_option, :field}),
    do: "Missing required signing option: field"

  defp why(:augment, {:missing_required_option, :adapter}),
    do: "Missing required long-lived augmentation option: adapter"

  defp why(:prepare, {:invalid_option, :field, value}),
    do: "Invalid signing preparation option field: #{inspect(value)}"

  defp why(:sign, {:invalid_option, :field, value}),
    do: "Invalid signing option field: #{inspect(value)}"

  defp why(:augment, {:invalid_option, :adapter, value}),
    do: "Invalid long-lived augmentation option adapter: #{inspect(value)}"

  defp why(:augment, {:invalid_option, :adapter_opts, value}),
    do: "Invalid long-lived augmentation option adapter_opts: #{inspect(value)}"

  defp why(:augment, {:missing_required_adapter_option, option}),
    do: "Missing required long-lived adapter option: #{option}"

  defp why(:augment, {:invalid_adapter_option, option, value}),
    do: "Invalid long-lived adapter option #{option}: #{inspect(value)}"

  defp why(:prepare, {:field_not_preparable, field}),
    do: "Rendered artifact does not expose a preparable signature field named #{field}"

  defp why(:sign, {:field_not_preparable, field}),
    do: "Rendered artifact does not expose a signable signature field named #{field}"

  defp why(:validate, {:invalid_pdf, :no_signatures}),
    do: "Rendered artifact does not expose any signatures for validation"

  defp why(:validate, {:invalid_pdf, :structural_invalidity}),
    do: "Signed-artifact validation could not parse a structurally valid PDF"

  defp why(:validate, {:invalid_pdf, :tool_failure}),
    do: "Signed-artifact validation tool failed before returning posture details"

  defp why(:validate, {:missing_executable, "pyhanko"}),
    do: "Signed-artifact validation requires pyhanko for long-lived evidence inspection"

  defp why(:validate, {:missing_executable, "python"}),
    do: "Signed-artifact validation helper requires python on the host"

  defp why(:validate, {:missing_executable, "python3"}),
    do: "Signed-artifact validation helper requires python3 on the host"

  defp why(_stage, {:unsupported_glyph, char}), do: "Missing glyph for character: #{char}"

  defp why(_stage, {:shaping_required, script, _hint}),
    do:
      "Script #{inspect(script)} requires a shaping adapter; Shaper.Simple cannot produce correct output for this script."

  defp why(_stage, {:shaping_required, script}),
    do:
      "Script #{inspect(script)} requires a shaping adapter; Shaper.Simple cannot produce correct output for this script."

  defp why(_stage, {:unsupported_script, reason}) when is_atom(reason),
    do: "Unsupported script boundary: #{reason |> Atom.to_string() |> String.replace("_", " ")}"

  defp why(_stage, {:missing_required_option, :reserved_bytes}),
    do: "Missing required signing preparation option: reserved_bytes"

  defp why(_stage, {:missing_required_adapter_option, option}),
    do: "Missing required signing adapter option: #{option}"

  defp why(_stage, {:missing_required_option, option}),
    do: "Missing required protection option: #{option}"

  defp why(_stage, {:invalid_option, :reserved_bytes, value}),
    do: "Invalid signing preparation option reserved_bytes: #{inspect(value)}"

  defp why(_stage, {:invalid_option, :adapter_opts, value}),
    do: "Invalid signing option adapter_opts: #{inspect(value)}"

  defp why(_stage, {:invalid_option, option, value}),
    do: "Invalid protection option #{option}: #{inspect(value)}"

  defp why(_stage, {:invalid_adapter_option, option, value}),
    do: "Invalid signing adapter option #{option}: #{inspect(value)}"

  defp why(_stage, {:pyhanko_failed, exit_code}),
    do: "Signing adapter failed: pyhanko exited with status #{exit_code}"

  defp why(_stage, {:command_failed, error_module}),
    do: "Signing adapter command runner crashed with #{inspect(error_module)}"

  defp why(:validate, :temp_dir_unavailable),
    do: "Signed-artifact validation could not create a private temporary workspace"

  defp why(:validate, :artifact_io_failed),
    do:
      "Signed-artifact validation could not write the artifact into its private temporary workspace"

  defp why(_stage, :already_prepared),
    do: "Rendered artifact already appears to contain signature preparation placeholders"

  defp why(_stage, :already_signed),
    do: "Rendered artifact already appears to contain Rendro-managed signing metadata"

  defp why(_stage, :prepared_artifact_not_signable),
    do: "Prepared signature-placeholder artifacts are not signable through Rendro.Sign.sign/2"

  defp why(:augment, :unsigned_artifact_not_augmentable),
    do:
      "Rendered artifact must already be a signed artifact before long-lived augmentation can run"

  defp why(:augment, :prepared_artifact_not_augmentable),
    do:
      "Prepared signature-placeholder artifacts are not augmentable through Rendro.Sign.augment/2"

  defp why(:augment, :unsupported_artifact_state),
    do:
      "Rendered artifact is missing the signed-artifact metadata required for long-lived augmentation"

  defp why(:augment, :already_augmented),
    do:
      "Rendered artifact already appears to contain Rendro-managed long-lived augmentation metadata"

  defp why(_stage, {:unknown_permissions, permissions}),
    do: "Unknown advisory permissions: #{Enum.map_join(permissions, ", ", &to_string/1)}"

  defp why(_stage, {:missing_executable, executable}), do: "Missing executable: #{executable}"

  defp why(_stage, {:adapter_failure, adapter, {:qpdf_failed, exit_code}}),
    do: "Protection adapter #{inspect(adapter)} failed: qpdf exited with status #{exit_code}"

  defp why(:sign, {:adapter_failure, adapter, {:command_failed, error_module}}),
    do:
      "Signing adapter #{inspect(adapter)} failed: command runner crashed with #{inspect(error_module)}"

  defp why(:augment, {:adapter_failure, adapter, {:command_failed, error_module}}),
    do:
      "Long-lived adapter #{inspect(adapter)} failed: command runner crashed with #{inspect(error_module)}"

  defp why(:augment, {:adapter_failure, adapter, reason}),
    do: "Long-lived adapter #{inspect(adapter)} failed: #{inspect(reason)}"

  defp why(:augment, {:command_failed, error_module}),
    do: "Long-lived adapter command runner crashed with #{inspect(error_module)}"

  defp why(_stage, {:adapter_failure, adapter, {:command_failed, error_module}}),
    do:
      "Protection adapter #{inspect(adapter)} failed: command runner crashed with #{inspect(error_module)}"

  defp why(_stage, {:adapter_failure, adapter, {:pyhanko_failed, exit_code}}),
    do: "Signing adapter #{inspect(adapter)} failed: pyhanko exited with status #{exit_code}"

  defp why(:sign, {:adapter_failure, adapter, reason}),
    do: "Signing adapter #{inspect(adapter)} failed: #{inspect(reason)}"

  defp why(_stage, {:adapter_failure, adapter, reason}),
    do: "Protection adapter #{inspect(adapter)} failed: #{inspect(reason)}"

  defp why(_stage, :running_content_error),
    do: "A running-content function raised an unexpected error during page rendering."

  defp why(_stage, %{reason: reason}) when is_binary(reason),
    do: "Running-content function raised an error: #{reason}"

  defp why(_stage, reason) when is_atom(reason),
    do: reason |> Atom.to_string() |> String.replace("_", " ")

  defp why(_stage, reason) when is_binary(reason), do: reason
  defp why(_stage, reason), do: Exception.format_banner(:error, reason)

  defp next_step(:build, :no_pages) do
    "Add at least one page before rendering (Rendro.document(pages: [...]))."
  end

  defp next_step(:build, :invalid_page_dimensions) do
    "Ensure every page has positive width and height values."
  end

  defp next_step(:build, :invalid_document) do
    "Pass a %Rendro.Document{} struct to Rendro.render/1 or Rendro.render/2."
  end

  defp next_step(:measure, :no_body_capacity) do
    "Increase the body region height or reduce reserved header/footer regions so flow content has usable space."
  end

  defp next_step(:measure, {:unsupported_glyph, _char}) do
    "Register an appropriate fallback font that contains the missing character using the fallbacks: [...] option."
  end

  defp next_step(:measure, {:unsupported_script, _reason}) do
    "Rendro does not currently support complex text shaping or RTL boundaries. Ensure input text falls within supported Unicode boundaries."
  end

  defp next_step(:measure, {:shaping_required, script, hint}) do
    "Script #{inspect(script)} requires a shaping adapter. #{hint}"
  end

  defp next_step(:measure, {:shaping_required, script}) do
    if Code.ensure_loaded?(HarfbuzzEx) do
      "Script #{inspect(script)} requires a shaping adapter. Add to your config: config :rendro, shaper: Rendro.Adapters.HarfBuzz"
    else
      "Script #{inspect(script)} requires a shaping adapter. Add {:harfbuzz_ex, \"~> 1.2\", optional: true} to deps and: config :rendro, shaper: Rendro.Adapters.HarfBuzz"
    end
  end

  defp next_step(:paginate, :content_overflow) do
    "Reduce content size or expand the declared page/region bounds; Rendro does not auto-fit overflowing content."
  end

  defp next_step(:paginate, :invalid_flow_directive) do
    "Remove flow directives from fixed-position pages or switch the content to Rendro.flow/2 so pagination directives run in the flow engine."
  end

  defp next_step(:paginate, :unsupported_table_split_policy) do
    "Use split_policy: :row_atomic on Rendro.table/2 (temporary alias :atomic is also accepted) so table continuation semantics stay explicit."
  end

  defp next_step(:paginate, :running_content_error) do
    "Ensure the running-content function is a pure, terminating fn {page_number, total_pages} -> [Block.t()] | nil and does not raise."
  end

  defp next_step(:paginate, :max_pages_exceeded) do
    "Reduce document length or increase the :max_pages policy limit."
  end

  defp next_step(:render, :max_bytes_exceeded) do
    "Reduce content complexity or increase the :max_bytes policy limit."
  end

  defp next_step(:render, :timeout) do
    "Optimize document complexity or increase the :timeout policy limit."
  end

  defp next_step(:validate, :structural_corruption) do
    "PDF header/trailer missing — internal renderer bug, please report with the input document and render_id."
  end

  defp next_step(:validate, :page_count_mismatch) do
    "Rendered page count diverged from document page count — pipeline bug, please report with the input document and render_id."
  end

  defp next_step(:validate, :max_bytes_exceeded) do
    "Reduce content complexity or increase the :max_bytes policy limit."
  end

  defp next_step(:validate, {:missing_executable, "pdfsig"}) do
    "Install Poppler's `pdfsig` on the host or select a different validation adapter before calling Rendro.Sign.validate/2."
  end

  defp next_step(:validate, {:missing_executable, "pyhanko"}) do
    "Install the pyHanko CLI (`pyhanko-cli`) on the host before calling Rendro.Sign.validate/2 with the long-lived evidence adapter."
  end

  defp next_step(:validate, {:missing_executable, executable})
       when executable in ["python", "python3"] do
    "Install Python on the host so Rendro's pyHanko validation helper can inspect embedded validation evidence."
  end

  defp next_step(:validate, {:invalid_pdf, :no_signatures}) do
    "Pass a signed artifact to Rendro.Sign.validate/2 or use Rendro.Sign.sign/2 before validating signature posture."
  end

  defp next_step(:validate, {:invalid_pdf, :structural_invalidity}) do
    "Rerender or resign the artifact, then retry validation; Rendro exposes only structurally valid signed-artifact posture."
  end

  defp next_step(:validate, {:invalid_pdf, :tool_failure}) do
    "Retry after correcting the host-level pdfsig installation or runtime state; Rendro does not expose raw pdfsig output in the public contract."
  end

  defp next_step(:validate, :temp_dir_unavailable) do
    "Ensure the host temporary directory is writable, then retry signed-artifact validation."
  end

  defp next_step(:validate, :artifact_io_failed) do
    "Ensure the host temporary directory accepts private file writes, then retry signed-artifact validation."
  end

  defp next_step(:protect, {:missing_required_option, :open_password}) do
    "Pass a non-empty :open_password so the protected PDF has a password-to-open boundary."
  end

  defp next_step(:protect, {:missing_required_option, :owner_password}) do
    "Pass a non-empty :owner_password; Rendro requires an explicit owner password for AES-256 protection."
  end

  defp next_step(:protect, {:invalid_option, :algorithm, _value}) do
    "Use algorithm: :aes_256. External protection in this version does not expose weaker or legacy algorithms."
  end

  defp next_step(:protect, {:invalid_option, :advisory_permissions, _value}) do
    "Pass advisory_permissions as a list of atoms such as [:print, :copy]."
  end

  defp next_step(:protect, {:unknown_permissions, _permissions}) do
    "Use only supported advisory permissions: :print, :copy, :modify, :annotate, :fill_forms, :assemble."
  end

  defp next_step(:protect, {:missing_executable, "qpdf"}) do
    "Install qpdf on the host or select a different protection adapter before calling Rendro.Protect.password/2."
  end

  defp next_step(:protect, {:adapter_failure, _adapter, _reason}) do
    "Inspect the adapter stderr/output and rerun with the same protection options after correcting the host-level qpdf issue."
  end

  defp next_step(:prepare, {:missing_required_option, :field}) do
    "Pass field: \"signature_name\" so Rendro can target one rendered unsigned signature widget explicitly."
  end

  defp next_step(:prepare, {:missing_required_option, :reserved_bytes}) do
    "Pass reserved_bytes as a positive integer so Rendro can reserve deterministic signature-content capacity."
  end

  defp next_step(:prepare, {:invalid_option, :field, _value}) do
    "Pass field as a non-empty string naming one rendered unsigned signature widget."
  end

  defp next_step(:prepare, {:invalid_option, :reserved_bytes, :too_large}) do
    "Use reserved_bytes as a positive integer no larger than 1048576."
  end

  defp next_step(:prepare, {:invalid_option, :reserved_bytes, _value}) do
    "Use reserved_bytes as a positive integer so Rendro can reserve deterministic signature-content capacity."
  end

  defp next_step(:prepare, {:field_not_preparable, _field}) do
    "Render a document that includes the named unsigned signature widget, then call Rendro.Sign.prepare/2 against that artifact."
  end

  defp next_step(:prepare, :already_prepared) do
    "Prepare each rendered artifact once; rerender a fresh unsigned artifact before repeating signing preparation."
  end

  defp next_step(:prepare, {:adapter_failure, _adapter, _reason}) do
    "Inspect the adapter-local preparation output and rerun after correcting the external signer integration state."
  end

  defp next_step(:sign, {:missing_required_option, :field}) do
    "Pass field: \"signature_name\" so Rendro can target one rendered unsigned signature widget explicitly."
  end

  defp next_step(:augment, {:missing_required_option, :adapter}) do
    "Pass adapter: MyLongLivedAdapter so Rendro can run one explicit post-sign long-lived augmentation step."
  end

  defp next_step(:sign, {:invalid_option, :field, _value}) do
    "Pass field as a non-empty string naming one rendered unsigned signature widget."
  end

  defp next_step(:sign, {:field_not_preparable, _field}) do
    "Render a document that includes the named unsigned signature widget, then call Rendro.Sign.sign/2 against that original unsigned artifact."
  end

  defp next_step(:sign, {:invalid_option, :adapter_opts, _value}) do
    "Pass adapter_opts as a keyword list or map containing only adapter-local signing settings."
  end

  defp next_step(:augment, {:invalid_option, :adapter, _value}) do
    "Pass adapter as a loaded module that implements augment/2 on the Rendro.Sign.Adapter boundary."
  end

  defp next_step(:augment, {:invalid_option, :adapter_opts, _value}) do
    "Pass adapter_opts as a keyword list or map containing only adapter-local long-lived settings."
  end

  defp next_step(:augment, {:missing_required_adapter_option, :tsa_url}) do
    "Pass adapter_opts with a non-empty :tsa_url so Rendro can add a document timestamp during augmentation."
  end

  defp next_step(:augment, {:missing_required_adapter_option, :trust_roots}) do
    "Pass adapter_opts with one or more trust-root paths under :trust_roots so pyHanko can embed validation evidence."
  end

  defp next_step(:augment, {:missing_required_adapter_option, _option}) do
    "Pass the required adapter-local long-lived settings in adapter_opts before calling Rendro.Sign.augment/2."
  end

  defp next_step(:augment, {:invalid_adapter_option, _option, _value}) do
    "Use only the supported adapter-local long-lived options for Rendro.Adapters.PyHanko: :tsa_url, :trust_roots, and optional :other_certs."
  end

  defp next_step(:sign, {:missing_executable, "pyhanko"}) do
    "Install the pyHanko CLI (`pyhanko-cli`) on the host or select a different signing adapter before calling Rendro.Sign.sign/2."
  end

  defp next_step(:sign, {:missing_required_adapter_option, :key}) do
    "Pass adapter_opts with a readable PEM or DER private-key path under :key."
  end

  defp next_step(:sign, {:missing_required_adapter_option, :cert}) do
    "Pass adapter_opts with a readable PEM or DER certificate path under :cert."
  end

  defp next_step(:sign, {:invalid_adapter_option, _option, _value}) do
    "Use only the supported adapter-local options for Rendro.Adapters.PyHanko: :key, :cert, optional :passfile, optional :chain, and optional :reason."
  end

  defp next_step(:sign, {:pyhanko_failed, _exit_code}) do
    "Inspect the adapter stderr/output and rerun after correcting the external signer integration state."
  end

  defp next_step(:sign, {:command_failed, _error_module}) do
    "Inspect the adapter stderr/output and rerun after correcting the external signer integration state."
  end

  defp next_step(:augment, {:command_failed, _error_module}) do
    "Inspect the adapter-local runtime logs and rerun after correcting the external long-lived evidence integration state."
  end

  defp next_step(:sign, :already_signed) do
    "Sign each rendered artifact once; rerender a fresh unsigned artifact before repeating signing."
  end

  defp next_step(:sign, :prepared_artifact_not_signable) do
    "Call Rendro.Sign.sign/2 on the original unsigned rendered artifact; keep Rendro.Sign.prepare/2 for external placeholder-based workflows."
  end

  defp next_step(:augment, :unsigned_artifact_not_augmentable) do
    "Call Rendro.Sign.sign/2 first, then pass the resulting signed artifact to Rendro.Sign.augment/2."
  end

  defp next_step(:augment, :prepared_artifact_not_augmentable) do
    "Sign the original unsigned rendered artifact before augmentation; prepared placeholder artifacts stay on the external-signing seam."
  end

  defp next_step(:augment, :unsupported_artifact_state) do
    "Pass only artifacts returned from Rendro.Sign.sign/2; Rendro does not infer long-lived eligibility from raw bytes or caller-added metadata."
  end

  defp next_step(:augment, :already_augmented) do
    "Augment each signed artifact once; rerun signing on a fresh artifact before repeating long-lived augmentation."
  end

  defp next_step(:augment, {:adapter_failure, _adapter, _reason}) do
    "Inspect the adapter-local runtime logs and rerun after correcting the external long-lived evidence integration state."
  end

  defp next_step(:render, _reason) do
    "Inspect telemetry events for the same render_id and verify PDF object generation inputs."
  end

  defp next_step(_stage, _reason) do
    "Inspect stage inputs and rerun with telemetry attached for the same render_id."
  end

  defp stage_module_suffix(stage) do
    case stage do
      :protect ->
        "Protect"

      :prepare ->
        "Prepare"

      :sign ->
        "Sign"

      :augment ->
        "Augment"

      _ ->
        stage
        |> Atom.to_string()
        |> Macro.camelize()
    end
  end
end

defimpl String.Chars, for: Rendro.Error do
  def to_string(error) do
    """
    Rendro Error in #{error.stage} stage:

    What:  #{error.what}
    Where: #{error.where}
    Why:   #{error.why}

    Next:  #{error.next}
    """
  end
end
