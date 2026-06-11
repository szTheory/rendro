defmodule RendroComparison.ChromicPDFRender do
  @moduledoc false

  @deps [{:chromic_pdf, "~> 1.17"}]
  @chrome_opts [
    chrome_executable: "/usr/bin/chromium",
    no_sandbox: true,
    chrome_args: "--disable-gpu --disable-dev-shm-usage",
    session_pool: [size: 1, timeout: 30_000, checkout_timeout: 30_000]
  ]
  @pdf_opts [
    print_to_pdf: %{
      "printBackground" => true,
      "preferCSSPageSize" => true
    }
  ]

  def main([mode, html_path, output_path]) when mode in ["cold", "warm_pool"] do
    Mix.install(@deps, consolidate_protocols: false)

    html = File.read!(html_path)
    {:ok, supervisor} = ChromicPDF.start_link(@chrome_opts)

    try do
      if mode == "warm_pool" do
        render!(html, "/tmp/rendro-chromic-pdf-warmup.pdf")
      end

      started_at = System.monotonic_time(:millisecond)
      render!(html, output_path)
      duration_ms = System.monotonic_time(:millisecond) - started_at

      if mode == "warm_pool" do
        IO.puts("RENDRO_BENCH_DURATION_MS=#{duration_ms}")
      end
    after
      if Process.alive?(supervisor) do
        Process.exit(supervisor, :normal)
      end
    end
  end

  def main(_args) do
    IO.puts(:stderr, "usage: chromic_pdf_render.exs cold|warm_pool HTML_PATH OUTPUT_PDF")
    System.halt(64)
  end

  defp render!(html, output_path) do
    case ChromicPDF.print_to_pdf({:html, html}, Keyword.put(@pdf_opts, :output, output_path)) do
      :ok -> :ok
      {:ok, pdf} when is_binary(pdf) -> File.write!(output_path, pdf)
      {:error, reason} -> raise "ChromicPDF render failed: #{inspect(reason)}"
      other -> raise "ChromicPDF render returned unexpected value: #{inspect(other)}"
    end
  end
end

RendroComparison.ChromicPDFRender.main(System.argv())
