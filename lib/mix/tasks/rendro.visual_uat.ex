defmodule Mix.Tasks.Rendro.VisualUat do
  use Mix.Task

  @shortdoc "Verify a branded PDF preview by Claude vision and update phase UAT"

  @moduledoc """
  Renders the branded invoice fixture, rasterises page 1 to PNG via `pdftoppm`,
  asks the Claude API to grade three visual criteria (logo present, header
  uses the embedded branded font, layout looks intentional), and writes the
  verdict back into the phase's UAT file.

  Replaces the manual visual UAT step for phase 29 (branded invoice preview).

      mix rendro.visual_uat            # phase 29 (default)
      mix rendro.visual_uat 29

  Requires:
    * `pdftoppm` on PATH (`brew install poppler` / `apt install poppler-utils`)
    * `ANTHROPIC_API_KEY` env var

  Optional env:
    * `RENDRO_VISUAL_UAT_MODEL` — defaults to `claude-opus-4-7`
  """

  @api_url "https://api.anthropic.com/v1/messages"
  @anthropic_version "2023-06-01"
  @default_model "claude-opus-4-7"
  @max_tokens 1024
  @raster_dpi 200
  @phases_root ".planning/phases"

  @invoice_fixture %{
    id: "INV-2026-001",
    date: ~D[2026-04-30],
    items: [
      %{name: "Consulting Services", qty: 10, price: 2_500},
      %{name: "Support Plan", qty: 1, price: 500}
    ],
    brand: %{font_name: :brand_heading, logo_name: :company_logo}
  }

  @impl Mix.Task
  def run(args) do
    phase = parse_phase(args)
    Mix.Task.run("app.start")

    with {:ok, api_key} <- fetch_api_key(),
         :ok <- ensure_pdftoppm(),
         {:ok, phase_dir} <- locate_phase_dir(phase),
         {:ok, uat_path} <- locate_uat_file(phase_dir),
         {:ok, png_path} <- render_and_rasterise(phase_dir),
         {:ok, verdict} <- grade_with_claude(png_path, api_key),
         :ok <- write_uat_result(uat_path, verdict, png_path) do
      print_verdict(verdict, png_path, uat_path)

      if verdict.overall_pass do
        :ok
      else
        Mix.shell().error("Visual UAT failed (overall_pass: false). See notes above.")
        exit({:shutdown, 1})
      end
    else
      {:error, msg} ->
        Mix.shell().error(msg)
        exit({:shutdown, 1})
    end
  end

  defp parse_phase([]), do: "29"
  defp parse_phase([raw | _]), do: raw

  defp fetch_api_key do
    case System.get_env("ANTHROPIC_API_KEY") do
      nil ->
        {:error,
         "ANTHROPIC_API_KEY is not set. Export it before running mix rendro.visual_uat."}

      "" ->
        {:error,
         "ANTHROPIC_API_KEY is empty. Export a real key before running mix rendro.visual_uat."}

      key ->
        {:ok, key}
    end
  end

  defp ensure_pdftoppm do
    case System.find_executable("pdftoppm") do
      nil ->
        {:error,
         "`pdftoppm` not found on PATH. Install poppler:\n" <>
           "  macOS:  brew install poppler\n" <>
           "  Debian: sudo apt-get install -y poppler-utils"}

      _path ->
        :ok
    end
  end

  defp locate_phase_dir(phase) do
    prefix = "#{@phases_root}/#{phase}-"

    case Path.wildcard("#{prefix}*") |> Enum.filter(&File.dir?/1) do
      [dir] -> {:ok, dir}
      [] -> {:error, "No phase directory found matching #{prefix}*"}
      many -> {:error, "Ambiguous phase directories: #{inspect(many)}"}
    end
  end

  defp locate_uat_file(phase_dir) do
    case Path.wildcard(Path.join(phase_dir, "*-UAT.md")) do
      [path] -> {:ok, path}
      [] -> {:error, "No *-UAT.md file under #{phase_dir}"}
      many -> {:error, "Ambiguous UAT files: #{inspect(many)}"}
    end
  end

  defp render_and_rasterise(phase_dir) do
    Mix.shell().info("Rendering branded invoice via Rendro.Recipes.BrandedInvoice...")
    doc = Rendro.Recipes.BrandedInvoice.document(@invoice_fixture)

    with {:ok, pdf_binary} <- Rendro.render(doc, deterministic: true) do
      tmp_pdf = Path.join(System.tmp_dir!(), "rendro-visual-uat-#{:erlang.unique_integer([:positive])}.pdf")
      File.write!(tmp_pdf, pdf_binary)

      png_basename = "29-branded-preview"
      out_prefix = Path.join(phase_dir, png_basename)

      Mix.shell().info("Rasterising page 1 to PNG (#{@raster_dpi} dpi) via pdftoppm...")

      case System.cmd("pdftoppm",
             ["-png", "-r", Integer.to_string(@raster_dpi), "-singlefile", tmp_pdf, out_prefix],
             stderr_to_stdout: true
           ) do
        {_out, 0} ->
          File.rm(tmp_pdf)
          {:ok, "#{out_prefix}.png"}

        {out, code} ->
          File.rm(tmp_pdf)
          {:error, "pdftoppm failed (code #{code}):\n#{out}"}
      end
    end
  end

  defp grade_with_claude(png_path, api_key) do
    Mix.shell().info("Submitting #{png_path} to Claude vision (#{model()})...")
    image_b64 = png_path |> File.read!() |> Base.encode64()
    payload = build_request_payload(image_b64)

    case Req.post(@api_url,
           json: payload,
           headers: [
             {"x-api-key", api_key},
             {"anthropic-version", @anthropic_version}
           ],
           receive_timeout: 60_000
         ) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        parse_verdict(body)

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, "Anthropic API returned HTTP #{status}:\n#{inspect(body)}"}

      {:error, exception} ->
        {:error, "HTTP request to Anthropic failed: #{Exception.message(exception)}"}
    end
  end

  defp model do
    System.get_env("RENDRO_VISUAL_UAT_MODEL", @default_model)
  end

  defp build_request_payload(image_b64) do
    %{
      model: model(),
      max_tokens: @max_tokens,
      tools: [verdict_tool()],
      tool_choice: %{type: "tool", name: "report_verdict"},
      messages: [
        %{
          role: "user",
          content: [
            %{
              type: "image",
              source: %{type: "base64", media_type: "image/png", data: image_b64}
            },
            %{type: "text", text: prompt_text()}
          ]
        }
      ]
    }
  end

  defp prompt_text do
    """
    This image is page 1 of a branded invoice PDF rendered by Rendro
    (a pure-Elixir PDF library). Grade it strictly against three criteria.

    Expected:
      1. A logo (rendro-logo.png, 64x64) appears in the upper-left logo region.
      2. The header text "Rendro, Inc." and "Invoice #INV-2026-001" is
         rendered in an embedded branded font (B612 Regular — a clean
         humanist sans-serif). The header should NOT be rendered in the
         default body font.
      3. The overall layout is readable and intentional: clear separation
         between logo, header, body table (Item / Qty / Price), and footer
         ("Thank you for your business!"). No overlapping text, missing
         glyphs, or obviously broken regions.

    Use the report_verdict tool. For each boolean, include short notes
    (one sentence) explaining what you actually saw. overall_pass must be
    true only if all three individual booleans are true.
    """
  end

  defp verdict_tool do
    %{
      name: "report_verdict",
      description:
        "Report the visual verification verdict for the branded invoice preview.",
      input_schema: %{
        type: "object",
        properties: %{
          logo_present: %{type: "boolean"},
          logo_notes: %{type: "string"},
          header_uses_branded_font: %{type: "boolean"},
          header_notes: %{type: "string"},
          layout_intentional: %{type: "boolean"},
          layout_notes: %{type: "string"},
          overall_pass: %{type: "boolean"},
          overall_notes: %{type: "string"}
        },
        required: [
          "logo_present",
          "logo_notes",
          "header_uses_branded_font",
          "header_notes",
          "layout_intentional",
          "layout_notes",
          "overall_pass",
          "overall_notes"
        ]
      }
    }
  end

  defp parse_verdict(decoded) when is_map(decoded) do
    case Enum.find(decoded["content"] || [], fn block -> block["type"] == "tool_use" end) do
      %{"input" => input} when is_map(input) ->
        {:ok,
         %{
           logo_present: input["logo_present"],
           logo_notes: input["logo_notes"] || "",
           header_uses_branded_font: input["header_uses_branded_font"],
           header_notes: input["header_notes"] || "",
           layout_intentional: input["layout_intentional"],
           layout_notes: input["layout_notes"] || "",
           overall_pass: input["overall_pass"],
           overall_notes: input["overall_notes"] || "",
           model: decoded["model"] || model()
         }}

      _ ->
        {:error,
         "Anthropic response did not contain a tool_use block:\n" <>
           inspect(decoded, limit: :infinity, printable_limit: :infinity)}
    end
  end

  defp write_uat_result(uat_path, verdict, png_path) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    artifact_basename = Path.basename(png_path)
    started = read_started(uat_path) || now
    {result_label, severity, gaps} = build_result_fields(verdict)

    contents = """
    ---
    status: complete
    phase: 29-branded-recipes-docs-and-proof-closure
    source: [29-VERIFICATION.md, mix rendro.visual_uat]
    started: #{started}
    updated: #{now}
    ---

    ## Current Test

    [testing complete]

    ## Tests

    ### 1. Branded preview visual quality
    expected: |
      Start the Phoenix example (`cd examples/phoenix_example && mix phx.server`),
      open `http://localhost:4000/branded/preview`, and visually inspect the rendered
      branded invoice PDF. The logo renders, the header uses the embedded branded
      font, and the overall branded invoice layout looks readable and intentional.
    result: #{result_label}#{severity_line(severity)}
    verifier: #{verdict.model} (mix rendro.visual_uat)
    artifact: #{artifact_basename}
    verdict:
      logo_present: #{verdict.logo_present}
      logo_notes: #{quote_notes(verdict.logo_notes)}
      header_uses_branded_font: #{verdict.header_uses_branded_font}
      header_notes: #{quote_notes(verdict.header_notes)}
      layout_intentional: #{verdict.layout_intentional}
      layout_notes: #{quote_notes(verdict.layout_notes)}
      overall_pass: #{verdict.overall_pass}
      overall_notes: #{quote_notes(verdict.overall_notes)}

    ## Summary

    total: 1
    passed: #{if verdict.overall_pass, do: 1, else: 0}
    issues: #{if verdict.overall_pass, do: 0, else: 1}
    pending: 0
    skipped: 0
    blocked: 0

    ## Gaps

    #{gaps}
    """

    File.write!(uat_path, contents)
    :ok
  end

  defp build_result_fields(%{overall_pass: true}), do: {"pass", nil, "None."}

  defp build_result_fields(verdict) do
    severity = infer_severity(verdict)
    failures = collect_failures(verdict)

    gap = """
    - truth: "Branded invoice preview renders logo, branded header font, and an intentional layout."
      status: failed
      reason: #{quote_notes(failures)}
      severity: #{severity}
      test: 1
      artifacts: [#{Path.basename("29-branded-preview.png")}]
      missing: []
    """

    {"issue", severity, String.trim_trailing(gap)}
  end

  defp infer_severity(verdict) do
    cond do
      not verdict.logo_present or not verdict.header_uses_branded_font -> "major"
      not verdict.layout_intentional -> "major"
      true -> "minor"
    end
  end

  defp collect_failures(verdict) do
    [
      {verdict.logo_present, "logo: #{verdict.logo_notes}"},
      {verdict.header_uses_branded_font, "header: #{verdict.header_notes}"},
      {verdict.layout_intentional, "layout: #{verdict.layout_notes}"},
      {verdict.overall_pass, "overall: #{verdict.overall_notes}"}
    ]
    |> Enum.reject(fn {ok, _} -> ok end)
    |> Enum.map_join(" | ", fn {_, msg} -> msg end)
  end

  defp severity_line(nil), do: ""
  defp severity_line(sev), do: "\nseverity: #{sev}"

  defp quote_notes(nil), do: "\"\""

  defp quote_notes(text) when is_binary(text) do
    escaped =
      text
      |> String.replace("\\", "\\\\")
      |> String.replace("\"", "\\\"")
      |> String.replace("\n", " ")

    "\"#{escaped}\""
  end

  defp read_started(uat_path) do
    case File.read(uat_path) do
      {:ok, contents} ->
        Regex.run(~r/^started:\s*(\S+)/m, contents, capture: :all_but_first)
        |> case do
          [value] -> value
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp print_verdict(verdict, png_path, uat_path) do
    Mix.shell().info("")
    Mix.shell().info("Visual UAT verdict (#{verdict.model})")
    Mix.shell().info("  logo_present:             #{verdict.logo_present}  (#{verdict.logo_notes})")

    Mix.shell().info(
      "  header_uses_branded_font: #{verdict.header_uses_branded_font}  (#{verdict.header_notes})"
    )

    Mix.shell().info(
      "  layout_intentional:       #{verdict.layout_intentional}  (#{verdict.layout_notes})"
    )

    Mix.shell().info(
      "  overall_pass:             #{verdict.overall_pass}  (#{verdict.overall_notes})"
    )

    Mix.shell().info("")
    Mix.shell().info("Artifact: #{png_path}")
    Mix.shell().info("UAT updated: #{uat_path}")
  end
end
