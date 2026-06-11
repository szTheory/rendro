defmodule Rendro.ViewerEvidence.Validator do
  @moduledoc false

  alias Rendro.ViewerEvidence.{Frontmatter, Lint, Matrix}

  @matrix_schema_path "priv/schemas/support_matrix.schema.json"
  @evidence_schema_path "priv/schemas/viewer_evidence.schema.json"
  @default_matrix_path "priv/support_matrix.json"
  @default_evidence_root "priv/viewer_evidence"
  @evidence_path_pattern ~r/^priv\/viewer_evidence\/[a-z0-9_]+\/[a-z0-9_]+\.md$/
  @staleness_days 180

  @promotion_keys ~w(evidence recorded_at viewer_kind)
  @deferral_conflict_keys ~w(evidence recorded_at viewer_kind)
  # GUI-viewer promotion row kinds only. `pdfium-render` is reserved for
  # top-level raster.evidence and must never validate a viewer_map row.
  @viewer_kinds ~w(manual pdfium-cli pdfjs-dist)

  @spec validate_matrix_structure!(map()) :: :ok
  def validate_matrix_structure!(matrix) do
    case validate_matrix_structure(matrix) do
      :ok -> :ok
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @spec validate_matrix_structure(map()) :: :ok | {:error, String.t()}
  def validate_matrix_structure(matrix) do
    root = matrix_schema_root()

    case JSV.validate(matrix, root) do
      {:ok, _} -> :ok
      {:error, err} -> {:error, format_jsv_error(err)}
    end
  end

  @spec validate_promotion_complete(map(), keyword()) :: :ok | {:error, [String.t()]}
  def validate_promotion_complete(matrix, opts \\ []) do
    strict? = Keyword.get(opts, :strict, true)

    matrix
    |> Matrix.enumerate_viewer_cells()
    |> Enum.flat_map(&promotion_violations(&1, matrix, strict?))
    |> case do
      [] -> :ok
      violations -> {:error, violations}
    end
  end

  @spec validate_evidence_file(String.t(), [String.t()], keyword()) ::
          :ok | {:error, String.t()}
  def validate_evidence_file(path, proof_ids, opts \\ []) do
    repo_root = Keyword.get(opts, :repo_root, File.cwd!())
    absolute = Path.join(repo_root, path)
    skip_path_alignment? = Keyword.get(opts, :skip_path_alignment, template_path?(path))

    with {:ok, content} <- read_file(absolute, path),
         {:ok, :clean} <- Lint.byte_budget(content),
         {:ok, {frontmatter, body}} <- Frontmatter.parse(content),
         :ok <- validate_frontmatter_schema(frontmatter),
         :ok <-
           if(skip_path_alignment?,
             do: :ok,
             else: Frontmatter.path_alignment(frontmatter, path)
           ),
         :ok <- validate_behaviors(frontmatter, proof_ids),
         {:ok, :clean} <- Lint.evidence_body(body) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec list_orphan_evidence(String.t()) :: [String.t()]
  def list_orphan_evidence(evidence_root \\ @default_evidence_root) do
    referenced =
      Matrix.load!()
      |> referenced_evidence_paths()
      |> MapSet.new()

    evidence_root
    |> Path.join("**/*.md")
    |> Path.wildcard()
    |> Enum.map(&normalize_repo_path/1)
    |> Enum.reject(fn path ->
      orphan_excluded?(path) or MapSet.member?(referenced, path)
    end)
    |> Enum.sort()
  end

  @spec staleness_warnings(map()) :: [String.t()]
  def staleness_warnings(matrix) do
    today = Date.utc_today()

    matrix
    |> Matrix.enumerate_viewer_cells()
    |> Enum.flat_map(fn cell ->
      row = fetch_row(matrix, cell)

      with "supported" <- cell.status,
           recorded_at when is_binary(recorded_at) <- Map.get(row, "recorded_at"),
           {:ok, date} <- Date.from_iso8601(recorded_at) do
        if Date.diff(today, date) > @staleness_days do
          [
            "#{cell.matrix_path}: recorded_at #{recorded_at} is older than #{@staleness_days} days"
          ]
        else
          []
        end
      else
        _ -> []
      end
    end)
  end

  @spec run_full(String.t(), String.t(), keyword()) ::
          {:ok, [String.t()]} | {:error, [String.t()]}
  def run_full(
        matrix_path \\ @default_matrix_path,
        evidence_root \\ @default_evidence_root,
        opts \\ []
      ) do
    repo_root = Keyword.get(opts, :repo_root, File.cwd!())

    with {:ok, matrix} <- load_matrix(matrix_path, repo_root),
         :ok <- validate_matrix_structure(matrix) do
      warnings =
        []
        |> Kernel.++(legacy_supported_warnings(matrix))
        |> Kernel.++(validate_referenced_evidence(matrix, repo_root))
        |> Kernel.++(orphan_violations(matrix, evidence_root, repo_root))
        |> Kernel.++(staleness_warnings(matrix))

      {:ok, warnings}
    else
      {:error, violations} when is_list(violations) -> {:error, violations}
      {:error, reason} -> {:error, [reason]}
    end
  end

  defp load_matrix(path, repo_root) do
    absolute = Path.join(repo_root, path)

    case File.read(absolute) do
      {:ok, content} ->
        {:ok, JSON.decode!(content)}

      {:error, reason} ->
        {:error, ["unable to read matrix #{path}: #{inspect(reason)}"]}
    end
  end

  defp legacy_supported_warnings(matrix) do
    matrix
    |> Matrix.enumerate_viewer_cells()
    |> Enum.flat_map(fn cell ->
      row = fetch_row(matrix, cell)

      if cell.status == "supported" and not promotion_complete_row?(row) do
        ["#{cell.matrix_path}: supported row missing promotion-complete evidence metadata"]
      else
        []
      end
    end)
  end

  defp validate_referenced_evidence(matrix, repo_root) do
    matrix
    |> referenced_evidence_paths()
    |> Enum.flat_map(fn path ->
      cell = find_cell_by_evidence(matrix, path)

      case validate_evidence_file(path, cell.proof, repo_root: repo_root) do
        :ok -> []
        {:error, reason} -> ["#{path}: #{reason}"]
      end
    end)
    |> Kernel.++(validate_template(repo_root))
  end

  defp validate_template(repo_root) do
    path = Path.join(@default_evidence_root, "_template.md")
    proof = ["open", "default_state_visible", "edit_or_toggle", "save"]

    case validate_evidence_file(path, proof, repo_root: repo_root) do
      :ok -> []
      {:error, reason} -> ["#{path}: #{reason}"]
    end
  end

  defp orphan_violations(_matrix, evidence_root, repo_root) do
    evidence_root
    |> Path.join(repo_root)
    |> list_orphan_evidence_from_root()
    |> Enum.map(&"orphan evidence file #{&1} is not referenced by the support matrix")
  end

  defp list_orphan_evidence_from_root(absolute_root) do
    referenced =
      Matrix.load!()
      |> referenced_evidence_paths()
      |> MapSet.new()

    absolute_root
    |> Path.join("**/*.md")
    |> Path.wildcard()
    |> Enum.map(&normalize_repo_path/1)
    |> Enum.reject(fn path ->
      orphan_excluded?(path) or MapSet.member?(referenced, path)
    end)
  end

  defp promotion_violations(cell, matrix, strict?) do
    row = fetch_row(matrix, cell)

    case cell.status do
      "supported" ->
        supported_violations(cell, row, strict?)

      "explicit_deferral" ->
        deferral_violations(cell, row)

      "unverified" ->
        unverified_violations(cell, row)

      other ->
        ["#{cell.matrix_path}: unknown status #{inspect(other)}"]
    end
  end

  defp supported_violations(cell, row, strict?) do
    if strict? and not promotion_complete_row?(row) do
      ["#{cell.matrix_path}: supported row requires evidence, recorded_at, and viewer_kind"]
    else
      []
    end
  end

  defp deferral_violations(cell, row) do
    violations = []

    violations =
      if Map.has_key?(row, "evidence_deferred") do
        case Lint.deferral_reason(row["evidence_deferred"]) do
          {:ok, :clean} -> violations
          {:error, reason} -> violations ++ ["#{cell.matrix_path}: #{reason}"]
        end
      else
        violations ++ ["#{cell.matrix_path}: explicit_deferral requires evidence_deferred"]
      end

    Enum.reduce(@deferral_conflict_keys, violations, fn key, acc ->
      if Map.has_key?(row, key) do
        acc ++ ["#{cell.matrix_path}: explicit_deferral must not include #{key}"]
      else
        acc
      end
    end)
  end

  defp unverified_violations(cell, row) do
    Enum.reduce(@promotion_keys ++ ["evidence_deferred"], [], fn key, acc ->
      if Map.has_key?(row, key) do
        acc ++ ["#{cell.matrix_path}: unverified row must not include #{key}"]
      else
        acc
      end
    end)
  end

  defp promotion_complete_row?(row) do
    with evidence when is_binary(evidence) <- Map.get(row, "evidence"),
         true <- Regex.match?(@evidence_path_pattern, evidence),
         recorded_at when is_binary(recorded_at) <- Map.get(row, "recorded_at"),
         {:ok, _} <- Date.from_iso8601(recorded_at),
         viewer_kind when is_binary(viewer_kind) <- Map.get(row, "viewer_kind"),
         true <- viewer_kind in @viewer_kinds do
      true
    else
      _ -> false
    end
  end

  defp validate_behaviors(frontmatter, proof_ids) do
    behaviors = Map.get(frontmatter, "behaviors", [])

    invalid =
      behaviors
      |> Enum.map(&Map.get(&1, "behavior"))
      |> Enum.reject(&(&1 in proof_ids))

    cond do
      not is_list(behaviors) or behaviors == [] ->
        {:error, "behaviors must be a non-empty array"}

      invalid != [] ->
        {:error, "behaviors contain ids not in matrix proof list: #{Enum.join(invalid, ", ")}"}

      true ->
        :ok
    end
  end

  defp validate_frontmatter_schema(frontmatter) do
    root = evidence_schema_root()

    case JSV.validate(frontmatter, root) do
      {:ok, _} -> :ok
      {:error, err} -> {:error, format_jsv_error(err)}
    end
  end

  defp referenced_evidence_paths(matrix) do
    matrix
    |> Matrix.enumerate_viewer_cells()
    |> Enum.flat_map(fn cell ->
      matrix
      |> fetch_row(cell)
      |> Map.get("evidence")
      |> List.wrap()
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp find_cell_by_evidence(matrix, path) do
    matrix
    |> Matrix.enumerate_viewer_cells()
    |> Enum.find_value(fn cell ->
      row = fetch_row(matrix, cell)
      if Map.get(row, "evidence") == path, do: cell
    end)
  end

  defp fetch_row(matrix, %{matrix_path: path}) do
    case String.split(path, ".") do
      ["forms", "viewers", viewer] ->
        get_in(matrix, ["forms", "viewers", viewer])

      ["forms", "signature_widget_viewers", viewer] ->
        get_in(matrix, ["forms", "signature_widget_viewers", viewer])

      ["signing_preparation", "viewers", viewer] ->
        get_in(matrix, ["signing_preparation", "viewers", viewer])

      ["signing", "viewers", viewer] ->
        get_in(matrix, ["signing", "viewers", viewer])

      ["signing", "long_lived", "viewers", viewer] ->
        get_in(matrix, ["signing", "long_lived", "viewers", viewer])

      ["embedded_files", "viewers", viewer] ->
        get_in(matrix, ["embedded_files", "viewers", viewer])

      ["links", "viewers", viewer] ->
        get_in(matrix, ["links", "viewers", viewer])

      ["protection", "viewers", viewer] ->
        get_in(matrix, ["protection", "viewers", viewer])
    end
  end

  defp read_file(absolute, display_path) do
    case File.read(absolute) do
      {:ok, content} ->
        {:ok, content}

      {:error, reason} ->
        {:error, "unable to read evidence file #{display_path}: #{inspect(reason)}"}
    end
  end

  defp orphan_excluded?(path) do
    path in ["priv/viewer_evidence/_template.md"] or String.ends_with?(path, "/.gitkeep")
  end

  defp template_path?(path), do: Path.basename(path) == "_template.md"

  defp normalize_repo_path(path) do
    path
    |> Path.expand(File.cwd!())
    |> String.replace_prefix(Path.expand(File.cwd!()) <> "/", "")
  end

  defp matrix_schema_root do
    @matrix_schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()
  end

  defp evidence_schema_root do
    @evidence_schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()
  end

  defp format_jsv_error(err) do
    err
    |> JSV.normalize_error()
    |> inspect(limit: :infinity)
  end
end
