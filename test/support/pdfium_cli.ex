defmodule Rendro.TestSupport.PdfiumCli do
  @moduledoc false

  @spec find_executable() :: String.t() | nil
  def find_executable do
    env_path = System.get_env("PDFIUM_CLI_PATH")

    if is_binary(env_path) and env_path != "" and File.exists?(env_path) do
      env_path
    else
      finder = fn name -> System.find_executable(name) end
      finder.("pdfium-cli") || finder.("pdfium")
    end
  end
end
