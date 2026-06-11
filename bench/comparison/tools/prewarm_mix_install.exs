case System.argv() do
  ["chromic_pdf"] ->
    Mix.install([{:chromic_pdf, "~> 1.17"}], consolidate_protocols: false)
    IO.puts("prewarmed chromic_pdf benchmark dependency")

  ["pdf_generator"] ->
    Application.put_env(:pdf_generator, :wkhtml_path, "/usr/bin/wkhtmltopdf")
    Application.put_env(:pdf_generator, :raise_on_missing_wkhtmltopdf_binary, true)

    Mix.install([{:pdf_generator, "~> 0.6.2"}], consolidate_protocols: false)
    IO.puts("prewarmed pdf_generator benchmark dependency")

  other ->
    IO.puts(:stderr, "usage: prewarm_mix_install.exs chromic_pdf|pdf_generator")
    IO.puts(:stderr, "received: #{inspect(other)}")
    System.halt(64)
end
