defmodule Rendro.Phase71.SigningViewerProofFixtures do
  @moduledoc false

  @usage """
  Usage:
    mix run scripts/signing_viewer_proof_fixtures.exs
    mix run scripts/signing_viewer_proof_fixtures.exs --help

  Regenerates all Phase 71 signing-surface viewer proof fixtures:

    1. test/fixtures/signature_widget_support_fixture.pdf
       MIX_ENV=test mix run -e 'Rendro.Test.SigningViewerSupportFixture.write_signature_widget_fixture("test/fixtures/signature_widget_support_fixture.pdf")'

    2. test/fixtures/signing_preparation_support_fixture.pdf
       MIX_ENV=test mix run -e 'Rendro.Test.SigningViewerSupportFixture.write_signing_preparation_fixture("test/fixtures/signing_preparation_support_fixture.pdf")'

    3. test/fixtures/signed_artifact_viewer_proof.pdf
       mix run scripts/signed_artifact_viewer_proof_fixture.exs --output test/fixtures/signed_artifact_viewer_proof.pdf

    4. test/fixtures/long_lived_viewer_proof.pdf
       mix run scripts/long_lived_viewer_proof_fixture.exs --output test/fixtures/long_lived_viewer_proof.pdf
  """

  @widget_path "test/fixtures/signature_widget_support_fixture.pdf"
  @preparation_path "test/fixtures/signing_preparation_support_fixture.pdf"
  @signed_path "test/fixtures/signed_artifact_viewer_proof.pdf"
  @long_lived_path "test/fixtures/long_lived_viewer_proof.pdf"

  def main(argv) do
    {opts, args, invalid} =
      OptionParser.parse(argv, strict: [help: :boolean], aliases: [h: :help])

    cond do
      invalid != [] ->
        IO.puts(:stderr, "Invalid options")
        print_usage()
        exit({:shutdown, 1})

      args != [] ->
        IO.puts(:stderr, "Unexpected positional arguments: #{Enum.join(args, " ")}")
        print_usage()
        exit({:shutdown, 1})

      opts[:help] ->
        print_usage()

      true ->
        regenerate_all!()
    end
  end

  defp print_usage, do: IO.puts(@usage)

  defp regenerate_all! do
    IO.puts("Regenerating Phase 71 signing viewer proof fixtures...")
    IO.puts("")

    regenerate_widget!()
    regenerate_preparation!()
    regenerate_signed!()
    regenerate_long_lived!()

    IO.puts("")
    IO.puts("All fixtures regenerated.")
  end

  defp regenerate_widget! do
    IO.puts("→ #{@widget_path}")

    {_, 0} =
      System.cmd("mix", [
        "run",
        "-e",
        ~s|Rendro.Test.SigningViewerSupportFixture.write_signature_widget_fixture("#{@widget_path}")|,
        env: [{"MIX_ENV", "test"}]
      ])
  end

  defp regenerate_preparation! do
    IO.puts("→ #{@preparation_path}")

    {_, 0} =
      System.cmd("mix", [
        "run",
        "-e",
        ~s|Rendro.Test.SigningViewerSupportFixture.write_signing_preparation_fixture("#{@preparation_path}")|,
        env: [{"MIX_ENV", "test"}]
      ])
  end

  defp regenerate_signed! do
    IO.puts("→ #{@signed_path}")
    run_script!("scripts/signed_artifact_viewer_proof_fixture.exs", @signed_path)
  end

  defp regenerate_long_lived! do
    IO.puts("→ #{@long_lived_path}")
    run_script!("scripts/long_lived_viewer_proof_fixture.exs", @long_lived_path)
  end

  defp run_script!(script, output) do
    {output_text, status} =
      System.cmd("mix", ["run", script, "--output", output], stderr_to_stdout: true)

    if status != 0 do
      IO.puts(:stderr, output_text)
      exit({:shutdown, status})
    end

    IO.puts(output_text)
  end
end

Rendro.Phase71.SigningViewerProofFixtures.main(System.argv())
