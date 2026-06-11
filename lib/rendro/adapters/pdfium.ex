defmodule Rendro.Adapters.Pdfium do
  @moduledoc """
  Optional runtime adapter for [pdfium-cli](https://github.com/klippa-app/pdfium-cli).

  pdfium-cli is an external executable, not a Hex dependency. Rendro uses it only for
  automatable viewer-evidence observation (`viewer_kind: pdfium-cli`), not for core rendering.
  """
  @moduledoc tags: [:adapter]

  @page_range_pattern ~r/\A[1-9][0-9]*(?:-[1-9][0-9]*)?(?:,[1-9][0-9]*(?:-[1-9][0-9]*)?)*\z/
  @tmp_dir_attempts 5

  @type form_field :: %{
          optional(String.t()) => term()
        }

  @doc """
  Returns PDF metadata from `pdfium info`.

  On success returns `{:ok, metadata_map}` with string keys (for example `"PDF Version"`).
  """
  @spec info(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def info(file_path, opts \\ []) do
    with {:ok, executable} <- find_executable(),
         {:ok, output} <- run_command(executable, info_args(file_path, opts)) do
      {:ok, parse_info_output(output)}
    end
  end

  @doc """
  Returns form field observations from `pdfium form --output-type json`.
  """
  @spec form_fields(String.t(), keyword()) :: {:ok, [form_field()]} | {:error, term()}
  def form_fields(file_path, opts \\ []) do
    with {:ok, executable} <- find_executable(),
         {:ok, output} <-
           run_command(executable, form_args(file_path, opts) ++ ["-"]) do
      decode_form_json(output)
    end
  end

  @doc """
  Returns the pdfium-cli version string (for example `"v0.10.3"`).
  """
  @spec version(keyword()) :: {:ok, String.t()} | {:error, term()}
  def version(opts \\ []) do
    with {:ok, executable} <- find_executable(),
         {:ok, output} <- run_command(executable, ["--version"], opts) do
      version =
        output
        |> String.trim()
        |> String.replace_prefix("pdfium version ", "")

      {:ok, version}
    end
  end

  @doc """
  Rasterizes a PDF binary to a list of PNG binaries using pdfium-cli.

  Accepts a PDF binary and keyword opts:
  - `dpi:` — dots per inch (positive integer, default 150)
  - `pages:` — page range string passed to pdfium-cli `--pages` (non-empty string, default nil = all pages)

  Writes the PDF to an isolated tmp directory (chmod 0o700 dir, chmod 0o600 file),
  invokes `pdfium-cli render` with list-form args (no shell interpolation), collects
  output PNG binaries sorted by page number, and cleans up the tmp directory unconditionally.

  Returns `{:ok, [png_binary]}` on success, or `{:error, term()}` on failure.
  """
  @spec render(binary(), keyword()) :: {:ok, [binary()]} | {:error, term()}
  def render(pdf_binary, opts \\ []) do
    dpi = Keyword.get(opts, :dpi, 150)
    pages = Keyword.get(opts, :pages, nil)

    with :ok <- validate_dpi(dpi),
         :ok <- validate_pages(pages),
         {:ok, executable} <- find_executable(),
         {:ok, tmp_dir} <- make_tmp_dir_for_raster() do
      try do
        render_in_tmp(executable, tmp_dir, pdf_binary, opts)
      after
        File.rm_rf(tmp_dir)
      end
    end
  end

  defp validate_dpi(dpi) when is_integer(dpi) and dpi > 0, do: :ok

  defp validate_dpi(_),
    do: {:error, {:invalid_option, :dpi, "must be a positive integer"}}

  defp validate_pages(nil), do: :ok

  defp validate_pages(pages) when is_binary(pages) do
    if Regex.match?(@page_range_pattern, pages) do
      :ok
    else
      {:error, {:invalid_option, :pages, "must be a page range like \"1-3,5\""}}
    end
  end

  defp validate_pages(_),
    do: {:error, {:invalid_option, :pages, "must be a page range like \"1-3,5\""}}

  defp make_tmp_dir_for_raster(attempts \\ @tmp_dir_attempts)

  defp make_tmp_dir_for_raster(0), do: {:error, :eexist}

  defp make_tmp_dir_for_raster(attempts) do
    path =
      Path.join(
        System.tmp_dir!(),
        "rendro-raster-#{random_suffix()}"
      )

    with :ok <- File.mkdir(path),
         :ok <- File.chmod(path, 0o700) do
      {:ok, path}
    else
      {:error, :eexist} -> make_tmp_dir_for_raster(attempts - 1)
      {:error, reason} -> {:error, reason}
    end
  end

  defp random_suffix do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end

  defp write_private_file(path, contents) do
    with :ok <- File.write(path, contents, [:write, :exclusive, :binary]),
         :ok <- File.chmod(path, 0o600) do
      :ok
    end
  end

  defp render_in_tmp(executable, tmp_dir, pdf_binary, opts) do
    input_path = Path.join(tmp_dir, "input.pdf")
    output_pattern = Path.join(tmp_dir, "page_%d.png")
    dpi = Keyword.get(opts, :dpi, 150)
    pages = Keyword.get(opts, :pages, nil)

    with :ok <- write_private_file(input_path, pdf_binary),
         {:ok, _output} <- run_render(executable, input_path, output_pattern, dpi, pages) do
      collect_pngs(tmp_dir)
    end
  end

  defp run_render(executable, input_path, output_pattern, dpi, pages) do
    args =
      render_args(input_path, output_pattern, dpi) ++
        if pages, do: ["--pages", pages], else: []

    run_command(executable, args)
  end

  defp render_args(input_path, output_pattern, dpi) do
    ["render", input_path, output_pattern, "--dpi", Integer.to_string(dpi), "--file-type", "png"]
  end

  defp collect_pngs(tmp_dir) do
    pngs =
      Path.wildcard(Path.join(tmp_dir, "page_*.png"))
      |> Enum.sort_by(&page_number_from_path/1)
      |> Enum.map(&File.read!/1)

    if Enum.empty?(pngs) do
      {:error, {:no_pages_rendered, "pdfium-cli produced no output files"}}
    else
      {:ok, pngs}
    end
  end

  defp page_number_from_path(path) do
    path
    |> Path.basename()
    |> then(fn "page_" <> rest -> String.trim_trailing(rest, ".png") end)
    |> String.to_integer()
  end

  defp find_executable do
    finder =
      Application.get_env(:rendro, :pdfium_cli_executable_finder, &default_finder/1)

    case finder.("pdfium-cli") || finder.("pdfium") do
      nil -> {:error, {:missing_executable, "pdfium-cli"}}
      executable -> {:ok, executable}
    end
  end

  defp default_finder(name), do: System.find_executable(name)

  defp info_args(file_path, opts) do
    password_args(opts) ++ ["info", file_path]
  end

  defp form_args(file_path, opts) do
    password_args(opts) ++ ["form", file_path, "--output-type", "json"]
  end

  defp password_args(opts) do
    case Keyword.get(opts, :password) do
      password when is_binary(password) and password != "" -> ["-p", password]
      _ -> []
    end
  end

  defp run_command(executable, args, opts \\ []) do
    runner = Application.get_env(:rendro, :pdfium_cli_command_runner, &System.cmd/3)
    cmd_opts = Keyword.get(opts, :cmd_opts, stderr_to_stdout: true)

    try do
      case runner.(executable, args, cmd_opts) do
        {output, 0} -> {:ok, output}
        {output, exit_code} -> {:error, {:pdfium_cli_failed, exit_code, output}}
      end
    rescue
      error -> {:error, {:command_failed, error.__struct__}}
    end
  end

  defp parse_info_output(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.reduce(%{}, fn line, acc ->
      case String.split(line, ":", parts: 2) do
        [key, value] -> Map.put(acc, String.trim(key), String.trim(value))
        _ -> acc
      end
    end)
  end

  defp decode_form_json(output) do
    case JSON.decode(output) do
      {:ok, %{"Fields" => fields}} when is_list(fields) ->
        {:ok, fields}

      {:ok, _} ->
        {:error, {:invalid_form_json, "missing Fields array"}}

      {:error, reason} ->
        {:error, {:invalid_form_json, reason}}
    end
  end
end
