defmodule RendroComparison.PdfGeneratorRender do
  @moduledoc false

  @deps [{:pdf_generator, "~> 0.6.2"}]

  def main([html_path, output_path]) do
    Application.put_env(:pdf_generator, :wkhtml_path, "/usr/bin/wkhtmltopdf")
    Application.put_env(:pdf_generator, :raise_on_missing_wkhtmltopdf_binary, true)

    Mix.install(@deps, consolidate_protocols: false)

    html = File.read!(html_path)

    case PdfGenerator.generate_binary(html,
           generator: :wkhtmltopdf,
           page_size: "letter",
           delete_temporary: true
         ) do
      {:ok, pdf} when is_binary(pdf) ->
        File.write!(output_path, pdf)

      {:error, reason} ->
        raise "pdf_generator render failed: #{inspect(reason)}"
    end
  end

  def main(_args) do
    IO.puts(:stderr, "usage: pdf_generator_render.exs HTML_PATH OUTPUT_PDF")
    System.halt(64)
  end
end

RendroComparison.PdfGeneratorRender.main(System.argv())
