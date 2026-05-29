defmodule Rendro.ViewerEvidence.ObservationEnvironment do
  @moduledoc false

  alias Rendro.Adapters.Pdfium

  @spec pdfium_cli(keyword()) :: {:ok, map()} | {:error, term()}
  def pdfium_cli(opts \\ []) do
    with {:ok, viewer_version} <- Pdfium.version(opts) do
      {:ok, %{viewer_version: viewer_version, platform: platform_string()}}
    end
  end

  @spec pdfinfo_cli(keyword()) :: {:ok, map()} | {:error, term()}
  def pdfinfo_cli(_opts \\ []) do
    version =
      case System.cmd("pdfinfo", ["-v"], stderr_to_stdout: true) do
        {output, 0} ->
          output |> String.trim() |> String.split("\n") |> List.first() |> to_string()

        _ ->
          "pdfinfo"
      end

    {:ok, %{viewer_version: version, platform: platform_string()}}
  end

  def pdfsig_cli(_opts \\ []) do
    version =
      case System.cmd("pdfsig", ["-v"], stderr_to_stdout: true) do
        {output, 0} ->
          output |> String.trim() |> String.split("\n") |> List.first() |> to_string()

        _ ->
          "pdfsig"
      end

    {:ok, %{viewer_version: version, platform: platform_string()}}
  end

  def pyhanko_cli(_opts \\ []) do
    version =
      case System.find_executable("pyhanko") do
        nil ->
          "pyhanko"

        executable ->
          case System.cmd(executable, ["--version"], stderr_to_stdout: true) do
            {output, 0} -> String.trim(output)
            _ -> "pyhanko"
          end
      end

    {:ok, %{viewer_version: version, platform: platform_string()}}
  end

  @spec platform_string() :: String.t()
  def platform_string do
    os_name =
      case :os.type() do
        {:unix, :darwin} -> "macOS"
        {:unix, _} -> "Linux"
        {:win32, _} -> "Windows"
      end

    arch_string = List.to_string(:erlang.system_info(:system_architecture))

    arch =
      cond do
        String.contains?(arch_string, "arm64") -> "arm64"
        String.contains?(arch_string, "aarch64") -> "arm64"
        String.contains?(arch_string, "x86_64") -> "x86_64"
        true -> arch_string
      end

    "#{os_name} (#{arch})"
  end
end
