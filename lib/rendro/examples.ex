defmodule Rendro.Examples do
  @moduledoc false

  @base_dir "priv/examples"

  @doc """
  Reads and JSON-decodes a fixture under `priv/examples/`.

  `relative_path` is resolved defensively via `Path.safe_relative/1`; any
  attempt to escape the base directory raises `ArgumentError` before the
  filesystem is touched.
  """
  @spec load!(String.t()) :: map()
  def load!(relative_path) do
    safe = safe!(relative_path)

    :rendro
    |> Application.app_dir(@base_dir)
    |> Path.join(safe)
    |> File.read!()
    |> JSON.decode!()
  end

  @doc """
  Lists the absolute paths of every `.json` fixture under a domain directory.

  `domain` is resolved defensively via `Path.safe_relative/1` before the
  wildcard pattern is built.
  """
  @spec list(String.t()) :: [String.t()]
  def list(domain) do
    safe = safe!(domain)

    :rendro
    |> Application.app_dir(@base_dir)
    |> Path.join(safe)
    |> Path.join("**/*.json")
    |> Path.wildcard()
  end

  defp safe!(input) do
    case Path.safe_relative(input) do
      {:ok, safe} ->
        safe

      :error ->
        raise ArgumentError,
              "unsafe example path rejected (escapes #{@base_dir}): #{inspect(input)}"
    end
  end
end
