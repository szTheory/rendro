defmodule Rendro.ViewerEvidence.ProtectionPopplerProof do
  @moduledoc false

  alias Rendro.Adapters.Poppler
  alias Rendro.ViewerEvidence.ObservationEnvironment

  @proof_ids ~w(
    opens_with_open_password
    displays_authored_content_correctly
    advisory_print_behavior
    advisory_copy_behavior
    save_and_reopen_readability
  )

  @spec proof_ids() :: [String.t()]
  def proof_ids, do: @proof_ids

  @spec run(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def run(fixture_path, opts \\ []) do
    open_password = open_password(opts)
    poppler_opts = [open_password: open_password]
    tmp_dir = temp_dir(opts)
    File.mkdir_p!(tmp_dir)
    copy_path = Path.join(tmp_dir, "protection_copy.pdf")

    try do
      with {:ok, metadata} <- Poppler.validate(fixture_path, poppler_opts),
           :ok <- step_displays_content(metadata),
           {:ok, encryption} <- show_encryption(fixture_path, open_password, opts),
           :ok <- step_advisory_print(encryption),
           :ok <- step_advisory_copy(encryption),
           :ok <- step_save_and_reopen(fixture_path, copy_path, poppler_opts),
           {:ok, env} <- ObservationEnvironment.pdfinfo_cli(opts) do
        {:ok, %{environment: env, behaviors: behavior_notes()}}
      end
    after
      if Keyword.get(opts, :cleanup, true) do
        File.rm_rf(tmp_dir)
      end
    end
  end

  defp open_password(opts) do
    Keyword.get_lazy(opts, :open_password, fn ->
      Application.get_env(:rendro, :protection_fixture_open_password, "open-secret")
    end)
  end

  defp temp_dir(opts) do
    Keyword.get_lazy(opts, :tmp_dir, fn ->
      Path.join(
        System.tmp_dir!(),
        "rendro-protection-proof-#{System.unique_integer([:positive, :monotonic])}"
      )
    end)
  end

  defp step_displays_content(metadata) do
    if Map.get(metadata, "Pages") != nil do
      :ok
    else
      {:error, :missing_pages_metadata}
    end
  end

  defp step_advisory_print(encryption) do
    if is_binary(encryption) and encryption != "" do
      :ok
    else
      {:error, :missing_encryption_output}
    end
  end

  defp step_advisory_copy(encryption) do
    if String.contains?(encryption, "R =") or String.contains?(encryption, "P =") do
      :ok
    else
      {:error, :missing_permission_flags}
    end
  end

  defp step_save_and_reopen(source, copy_path, poppler_opts) do
    File.mkdir_p!(Path.dirname(copy_path))
    File.cp!(source, copy_path)

    case Poppler.validate(copy_path, poppler_opts) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, {:save_and_reopen_failed, reason}}
    end
  end

  defp show_encryption(path, open_password, opts) do
    with {:ok, executable} <- find_qpdf(opts),
         {:ok, output} <-
           run_qpdf(executable, ["--show-encryption", "--password=#{open_password}", path], opts) do
      {:ok, output}
    end
  end

  defp find_qpdf(_opts) do
    finder = Application.get_env(:rendro, :qpdf_executable_finder, &System.find_executable/1)

    case finder.("qpdf") do
      nil -> {:error, {:missing_executable, "qpdf"}}
      executable -> {:ok, executable}
    end
  end

  defp run_qpdf(executable, args, opts) do
    runner = Application.get_env(:rendro, :qpdf_command_runner, &System.cmd/3)
    cmd_opts = Keyword.get(opts, :cmd_opts, stderr_to_stdout: true)

    try do
      case runner.(executable, args, cmd_opts) do
        {output, 0} -> {:ok, output}
        {output, exit_code} -> {:error, {:qpdf_failed, exit_code, output}}
      end
    rescue
      error -> {:error, {:command_failed, error.__struct__}}
    end
  end

  defp behavior_notes do
    [
      %{
        behavior: "opens_with_open_password",
        result: "pass",
        note:
          "pdfinfo opened the protected fixture when supplied the fixture open password at validation time (structural proxy — password not recorded in evidence; does not exercise Preview password prompt GUI)."
      },
      %{
        behavior: "displays_authored_content_correctly",
        result: "pass",
        note:
          "pdfinfo reported page count metadata after decrypting with the open password (structural readability proxy, not Preview rendered content GUI)."
      },
      %{
        behavior: "advisory_print_behavior",
        result: "pass",
        note:
          "qpdf --show-encryption reported permission flags observationally (advisory posture only — not Preview print UI behavior)."
      },
      %{
        behavior: "advisory_copy_behavior",
        result: "pass",
        note:
          "qpdf --show-encryption output includes P/R permission fields for observational advisory copy/print posture (not Preview copy UI behavior)."
      },
      %{
        behavior: "save_and_reopen_readability",
        result: "pass",
        note:
          "Copied protected fixture bytes to a temp path and pdfinfo re-opened successfully with the open password (structural round-trip, not Preview Save As GUI)."
      }
    ]
  end
end
