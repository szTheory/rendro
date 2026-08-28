defmodule Mix.Tasks.Rendro.Catalog.Gallery do
  use Mix.Task

  @shortdoc "Build or validate the authority-none eight-image catalog review packet"
  @moduledoc false

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          candidate_manifest: :string,
          final_manifest: :string,
          output: :string,
          validate_intake: :string,
          bundle: :string,
          control_sha: :string,
          validate_receipt: :string,
          require_complete_receipt: :string,
          validate_review_receipt: :string,
          require_qualified_review_receipt: :string
        ]
      )

    if rest != [] or invalid != [] do
      Mix.raise("Unexpected catalog gallery arguments")
    end

    case operation(opts) do
      {:build, candidate, final, output} ->
        report(
          Rendro.CatalogVisualGallery.build(candidate, final, output),
          "Generated authority-none eight-image review packet at #{output}/index.html"
        )

      {:validate_packet, packet, bundle, control_sha} ->
        report(
          Rendro.CatalogVisualGallery.validate(packet, bundle, control_sha),
          "Validated packet binding to the closed evidence bundle"
        )

      {:validate_intake, path} ->
        report(
          Rendro.CatalogVisualGallery.validate_intake(path),
          "Validated fresh review-intake document"
        )

      {:validate_receipt, path} ->
        report(
          Rendro.CatalogVisualGallery.validate_receipt(path),
          "Validated closed evidence receipt"
        )

      {:require_complete_receipt, path} ->
        report(
          Rendro.CatalogVisualGallery.require_complete_receipt(path),
          "Validated fresh complete evidence receipt"
        )

      {:validate_review_receipt, path} ->
        report(
          Rendro.CatalogVisualGallery.validate_review_receipt(path),
          "Validated closed review receipt"
        )

      {:require_qualified_review_receipt, path} ->
        report(
          Rendro.CatalogVisualGallery.require_qualified_review_receipt(path),
          "Validated qualified review receipt"
        )

      :error ->
        Mix.raise("Choose exactly one complete catalog gallery operation")
    end
  end

  defp operation(opts) do
    operations =
      [
        build_operation(opts),
        intake_operation(opts),
        unary_operation(opts, :validate_receipt),
        unary_operation(opts, :require_complete_receipt),
        unary_operation(opts, :validate_review_receipt),
        unary_operation(opts, :require_qualified_review_receipt)
      ]
      |> Enum.reject(&is_nil/1)

    case operations do
      [operation] -> operation
      _ -> :error
    end
  end

  defp build_operation(opts) do
    output = Keyword.get(opts, :output)
    candidate = Keyword.get(opts, :candidate_manifest)
    final = Keyword.get(opts, :final_manifest)

    if Enum.all?([candidate, final, output], &is_binary/1),
      do: {:build, candidate, final, output},
      else: nil
  end

  defp intake_operation(opts) do
    packet = Keyword.get(opts, :validate_intake)
    bundle = Keyword.get(opts, :bundle)
    control_sha = Keyword.get(opts, :control_sha)

    case {packet, bundle, control_sha} do
      {packet, nil, nil} when is_binary(packet) ->
        {:validate_intake, packet}

      {packet, bundle, control_sha}
      when is_binary(packet) and is_binary(bundle) and is_binary(control_sha) ->
        {:validate_packet, packet, bundle, control_sha}

      _ ->
        nil
    end
  end

  defp unary_operation(opts, key) do
    case Keyword.get(opts, key) do
      path when is_binary(path) -> {key, path}
      _ -> nil
    end
  end

  defp report(result, success) do
    case result do
      {:ok, path} ->
        Mix.shell().info(success <> ": #{path}")

      :ok ->
        Mix.shell().info(success)

      {:error, reason} ->
        Mix.raise("Catalog gallery operation failed: #{inspect(reason)}")
    end
  end
end
