defmodule Rendro.Comparison do
  @moduledoc false
  @compile {:no_warn_undefined, {Jason, :encode!, 2}}

  @manifest_path "bench/results/comparison.json"
  @guide_path "guides/comparison.md"

  @fit_start "<!-- rendro-comparison-fit-start -->"
  @fit_end "<!-- rendro-comparison-fit-end -->"
  @results_start "<!-- rendro-comparison-results-start -->"
  @results_end "<!-- rendro-comparison-results-end -->"
  @evidence_start "<!-- rendro-comparison-evidence-start -->"
  @evidence_end "<!-- rendro-comparison-evidence-end -->"

  @schema_version 1
  @generated_by "mix rendro.comparison.gen"
  @required_comparator_ids ~w(rendro chromic_pdf chromic_pdf_warm_pool pdf_generator typst_cli)
  @required_metric_ids ~w(cold_start_ms rss_mb container_image_mb dependency_count)
  @result_required_keys ~w(comparator metric median p95 samples unit raw_artifact raw_sha256)
  @claim_required_keys ~w(id text scope evidence)
  @sha256_regex ~r/^[0-9a-f]{64}$/
  @claim_id_regex ~r/^CMP-[A-Z0-9-]+$/

  @metric_labels %{
    "cold_start_ms" => "Render time",
    "rss_mb" => "RSS",
    "container_image_mb" => "Runtime image",
    "dependency_count" => "Runtime dependencies"
  }

  @spec manifest_path() :: String.t()
  def manifest_path, do: @manifest_path

  @spec guide_path() :: String.t()
  def guide_path, do: @guide_path

  @spec fit_markers() :: {String.t(), String.t()}
  def fit_markers, do: {@fit_start, @fit_end}

  @spec results_markers() :: {String.t(), String.t()}
  def results_markers, do: {@results_start, @results_end}

  @spec evidence_markers() :: {String.t(), String.t()}
  def evidence_markers, do: {@evidence_start, @evidence_end}

  @spec read_manifest!() :: map()
  def read_manifest! do
    @manifest_path
    |> File.read!()
    |> JSON.decode!()
  end

  @spec write_manifest!(map()) :: :ok
  def write_manifest!(manifest) when is_map(manifest) do
    File.write!(@manifest_path, encode_manifest(manifest) <> "\n")
  end

  @spec encode_manifest(map()) :: String.t()
  def encode_manifest(manifest) when is_map(manifest) do
    manifest
    |> normalize_for_json()
    |> encode_json!()
  end

  @spec check() :: :ok | {:error, [String.t()]}
  def check do
    case static_contract_errors() do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  @spec generate(keyword()) :: :ok | {:error, [String.t()]}
  def generate(opts \\ []) do
    if Keyword.get(opts, :skip_external, false) do
      manifest = read_manifest!()

      case public_claims(manifest) do
        [] ->
          write_manifest!(manifest)

        _claims ->
          {:error, ["--skip-external cannot write a manifest with public claims"]}
      end
    else
      {:error,
       [
         "benchmark execution is handled by bench/comparison/run.exs; run the documented pinned command"
       ]}
    end
  end

  @spec static_contract_errors() :: [String.t()]
  def static_contract_errors do
    if File.exists?(@manifest_path) do
      static_contract_errors(read_manifest!())
    else
      ["missing comparison manifest: #{@manifest_path}"]
    end
  end

  @spec static_contract_errors(map()) :: [String.t()]
  def static_contract_errors(manifest) when is_map(manifest) do
    []
    |> collect_manifest_shape_errors(manifest)
    |> collect_result_errors(manifest)
    |> collect_claim_errors(manifest)
  end

  def static_contract_errors(_manifest), do: ["comparison manifest must be a map"]

  @spec fit_block(map()) :: String.t()
  def fit_block(manifest) when is_map(manifest) do
    citations = all_public_claim_citations(manifest)

    """
    #{@fit_start}
    | Job | Rendro | ChromicPDF | pdf_generator | Typst CLI | Reason |
    |---|---|---|---|---|---|
    | Documents authored from Elixir data | Best fit | Good fit | Use another tool | Good fit | Native data-driven layout, deterministic pagination, and telemetry-oriented operation#{citation_suffix(citations)} |
    | Existing HTML/CSS source of truth | Use another tool | Best fit | Good fit | Use another tool | Browser or wkhtmltopdf renderers preserve HTML/CSS workflows |
    | Typst-native template workflow | Use another tool | Use another tool | Use another tool | Best fit | Typst is strongest when its template language is already the document source |

    #{render_public_claims(manifest)}
    #{@fit_end}
    """
    |> String.trim()
  end

  @spec results_block(map()) :: String.t()
  def results_block(manifest) when is_map(manifest) do
    rows =
      @required_metric_ids
      |> Enum.map(fn metric ->
        values =
          @required_comparator_ids
          |> Enum.map(fn comparator ->
            manifest
            |> result_for(comparator, metric)
            |> format_result()
          end)

        evidence = metric_claim_citations(manifest, metric)

        [
          Map.fetch!(@metric_labels, metric)
          | values ++ [evidence]
        ]
        |> table_row()
      end)
      |> Enum.join("\n")

    """
    #{@results_start}
    Measured in this harness.

    | Metric | Rendro | ChromicPDF cold | ChromicPDF warm pool | pdf_generator | Typst CLI | Evidence |
    |---|---:|---:|---:|---:|---:|---|
    #{rows}
    #{@results_end}
    """
    |> String.trim()
  end

  @spec evidence_block(map()) :: String.t()
  def evidence_block(manifest) when is_map(manifest) do
    run = manifest |> Map.get("run") |> map_or_empty()
    scenario = manifest |> Map.get("scenario") |> map_or_empty()
    raw_paths = raw_artifact_paths(manifest)

    raw_lines =
      raw_paths
      |> Enum.map(&"- `#{&1}`")
      |> Enum.join("\n")

    """
    #{@evidence_start}
    | Field | Value |
    |---|---|
    | Run id | `#{run["id"]}` |
    | Recorded at | `#{run["recorded_at"]}` |
    | Git SHA | `#{run["git_sha"]}` |
    | Scenario | `#{scenario["id"]}` from `#{scenario["fixture"]}` |
    | Host | #{format_host(run["host"])} |
    | Container | #{format_container(run["container"])} |
    | Comparator versions | #{format_comparators(manifest)} |
    | Repetitions | #{run["repetitions"]} |

    Result summaries:
    #{result_summary_lines(manifest)}

    Raw artifacts:
    #{raw_lines}

    #{render_public_claims(manifest)}
    #{@evidence_end}
    """
    |> String.trim()
  end

  defp collect_manifest_shape_errors(errors, manifest) do
    run = manifest |> Map.get("run") |> map_or_empty()
    scenario = manifest |> Map.get("scenario") |> map_or_empty()
    comparators = manifest |> Map.get("comparators") |> list_or_empty()
    comparator_ids = Enum.map(comparators, &entry_id/1)
    missing_comparators = @required_comparator_ids -- comparator_ids

    errors
    |> add_error_unless(
      Map.get(manifest, "schema_version") == @schema_version,
      "schema_version must be #{@schema_version}"
    )
    |> add_error_unless(
      Map.get(manifest, "generated_by") == @generated_by,
      "generated_by must be #{@generated_by}"
    )
    |> add_error_unless(is_map(Map.get(manifest, "run")), "manifest run must be a map")
    |> add_error_unless(is_map(Map.get(manifest, "scenario")), "manifest scenario must be a map")
    |> add_error_unless(
      is_list(Map.get(manifest, "comparators")),
      "manifest comparators must be a list"
    )
    |> add_error_unless(is_list(Map.get(manifest, "results")), "manifest results must be a list")
    |> add_error_unless(is_list(Map.get(manifest, "claims")), "manifest claims must be a list")
    |> add_error_unless(
      missing_comparators == [],
      "manifest comparators missing required ids: #{Enum.join(missing_comparators, ", ")}"
    )
    |> Enum.concat(
      required_map_field_errors(
        run,
        "run",
        ~w(id recorded_at git_sha host container commands repetitions)
      )
    )
    |> Enum.concat(required_map_field_errors(scenario, "scenario", ~w(id fixture)))
  end

  defp collect_result_errors(errors, manifest) do
    results = manifest |> Map.get("results") |> list_or_empty()
    metrics = results |> Enum.filter(&is_map/1) |> Enum.map(& &1["metric"])
    missing_metrics = @required_metric_ids -- metrics

    errors
    |> add_error_unless(
      missing_metrics == [],
      "manifest results missing required metric ids: #{Enum.join(missing_metrics, ", ")}"
    )
    |> Enum.concat(Enum.flat_map(Enum.with_index(results), &result_errors/1))
  end

  defp result_errors({result, index}) when is_map(result) do
    label = result_label(result, index)

    @result_required_keys
    |> Enum.reject(&Map.has_key?(result, &1))
    |> Enum.map(&"#{label} missing #{&1}")
    |> add_error_unless(
      is_number(result["median"]),
      "#{label} median must be numeric"
    )
    |> add_error_unless(
      is_number(result["p95"]),
      "#{label} p95 must be numeric"
    )
    |> add_error_unless(
      is_integer(result["samples"]) and result["samples"] > 0,
      "#{label} samples must be a positive integer"
    )
    |> Enum.concat(raw_artifact_errors(result, label))
  end

  defp result_errors({result, index}),
    do: ["result #{index + 1} must be a map: #{inspect(result)}"]

  defp raw_artifact_errors(result, label) do
    path = result["raw_artifact"]
    expected = result["raw_sha256"]

    []
    |> add_error_unless(
      is_binary(path) and String.trim(path) != "",
      "#{label} raw_artifact must be a non-empty path"
    )
    |> add_error_unless(
      sha256_hex?(expected),
      "#{label} raw_sha256 must be a lowercase 64-character SHA-256 hex digest"
    )
    |> Enum.concat(file_hash_errors(path, expected, "#{label} raw artifact"))
  end

  defp collect_claim_errors(errors, manifest) do
    claims = manifest |> Map.get("claims") |> list_or_empty()
    errors ++ Enum.flat_map(claims, &claim_errors/1)
  end

  defp claim_errors(claim) when is_map(claim) do
    id = claim["id"]

    errors =
      []
      |> add_error_unless(claim_id?(id), "claim id must match CMP-[A-Z0-9-]+: #{inspect(id)}")

    if public_claim?(claim) do
      errors
      |> Enum.concat(required_map_field_errors(claim, "claim #{id}", @claim_required_keys))
      |> add_error_unless(
        is_binary(claim["text"]) and String.trim(claim["text"]) != "",
        "claim #{id} text must be a non-empty string"
      )
      |> add_error_unless(
        is_binary(claim["scope"]) and String.trim(claim["scope"]) != "",
        "claim #{id} scope must be a non-empty string"
      )
      |> add_error_unless(
        is_list(claim["evidence"]) and claim["evidence"] != [],
        "claim #{id} evidence must be a non-empty list"
      )
    else
      errors
    end
  end

  defp claim_errors(claim), do: ["claim must be a map: #{inspect(claim)}"]

  defp required_map_field_errors(map, label, keys) do
    keys
    |> Enum.reject(&Map.has_key?(map, &1))
    |> Enum.map(&"#{label} missing #{&1}")
  end

  defp file_hash_errors(path, _expected, label) when not is_binary(path) do
    ["#{label} path missing in manifest"]
  end

  defp file_hash_errors(_path, expected, label) when not is_binary(expected) do
    ["#{label} sha256 missing in manifest"]
  end

  defp file_hash_errors(path, expected, label) do
    if File.exists?(path) do
      actual = path |> File.read!() |> sha256()

      if actual == expected do
        []
      else
        ["#{label} hash drift for #{path}: expected #{expected}, got #{actual}"]
      end
    else
      ["#{label} file missing: #{path}"]
    end
  end

  defp result_for(manifest, comparator, metric) do
    manifest
    |> Map.get("results")
    |> list_or_empty()
    |> Enum.find(fn
      %{"comparator" => ^comparator, "metric" => ^metric} -> true
      _other -> false
    end)
  end

  defp format_result(nil), do: "not recorded"

  defp format_result(result) do
    "#{format_number(result["median"])} #{result["unit"]} median / #{format_number(result["p95"])} #{result["unit"]} p95"
  end

  defp metric_claim_citations(manifest, metric) do
    manifest
    |> public_claims()
    |> Enum.filter(fn claim ->
      claim
      |> Map.get("evidence")
      |> list_or_empty()
      |> Enum.any?(fn
        %{"metric" => ^metric} -> true
        _other -> false
      end)
    end)
    |> Enum.map(&"[bench:#{&1["id"]}]")
    |> case do
      [] -> "No public claim"
      citations -> Enum.join(citations, ", ")
    end
  end

  defp render_public_claims(manifest) do
    case public_claims(manifest) do
      [] ->
        "_No public comparison claims are published from this manifest._"

      claims ->
        claims
        |> Enum.map(fn claim ->
          "- [bench:#{claim["id"]}] #{claim["text"]} Scope: #{claim["scope"]}"
        end)
        |> Enum.join("\n")
    end
  end

  defp all_public_claim_citations(manifest) do
    manifest
    |> public_claims()
    |> Enum.map(&"[bench:#{&1["id"]}]")
  end

  defp citation_suffix([]), do: ""
  defp citation_suffix(citations), do: " #{Enum.join(citations, ", ")}"

  defp public_claims(manifest) do
    manifest
    |> Map.get("claims")
    |> list_or_empty()
    |> Enum.filter(fn
      claim when is_map(claim) -> public_claim?(claim)
      _other -> false
    end)
  end

  defp public_claim?(claim), do: Map.get(claim, "public", true) != false

  defp raw_artifact_paths(manifest) do
    manifest
    |> Map.get("results")
    |> list_or_empty()
    |> Enum.filter(&is_map/1)
    |> Enum.map(& &1["raw_artifact"])
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
  end

  defp format_comparators(manifest) do
    manifest
    |> Map.get("comparators")
    |> list_or_empty()
    |> Enum.filter(&is_map/1)
    |> Enum.map(fn comparator ->
      id = comparator["id"] || "unknown"
      version = comparator["version"] || "unknown"
      runtime = comparator["external_runtime"] || "none"

      "`#{id}` #{version} (#{runtime})"
    end)
    |> Enum.join("; ")
  end

  defp result_summary_lines(manifest) do
    @required_comparator_ids
    |> Enum.flat_map(fn comparator ->
      Enum.map(@required_metric_ids, fn metric -> {comparator, metric} end)
    end)
    |> Enum.map(fn {comparator, metric} ->
      manifest
      |> result_for(comparator, metric)
      |> format_result_summary(comparator, metric)
    end)
    |> Enum.join("\n")
  end

  defp format_result_summary(nil, comparator, metric) do
    "- `#{comparator}/#{metric}`: not recorded"
  end

  defp format_result_summary(result, comparator, metric) do
    "- `#{comparator}/#{metric}`: median #{format_number(result["median"])} #{result["unit"]}, p95 #{format_number(result["p95"])} #{result["unit"]}, samples #{result["samples"]}, raw `#{result["raw_artifact"]}`"
  end

  defp table_row(values), do: "| #{Enum.join(values, " | ")} |"

  defp format_host(host) when is_map(host) do
    memory =
      case host["memory_limit_mb"] do
        nil -> nil
        mb -> "#{mb} MB"
      end

    [host["os"], host["arch"], host["cpu"], memory]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(", ")
  end

  defp format_host(_host), do: "not recorded"

  defp format_container(container) when is_map(container) do
    size =
      case container["size_mb"] do
        nil -> nil
        mb -> "#{mb} MB"
      end

    [container["image"], container["digest"], size]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp format_container(_container), do: "not recorded"

  defp format_number(value) when is_integer(value), do: Integer.to_string(value)
  defp format_number(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 2)
  defp format_number(value), do: to_string(value)

  defp result_label(result, index) do
    case {result["comparator"], result["metric"]} do
      {comparator, metric} when is_binary(comparator) and is_binary(metric) ->
        "result #{comparator}/#{metric}"

      _other ->
        "result #{index + 1}"
    end
  end

  defp sha256_hex?(value), do: is_binary(value) and value =~ @sha256_regex
  defp claim_id?(value), do: is_binary(value) and value =~ @claim_id_regex
  defp sha256(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)
  defp add_error_unless(errors, true, _message), do: errors
  defp add_error_unless(errors, false, message), do: errors ++ [message]

  defp normalize_for_json(map) when is_map(map) do
    map
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.map(fn {key, value} -> {key, normalize_for_json(value)} end)
    |> ordered_object()
  end

  defp normalize_for_json(list) when is_list(list), do: Enum.map(list, &normalize_for_json/1)
  defp normalize_for_json(value), do: value
  defp encode_json!(value), do: Jason.encode!(value, pretty: true)
  defp ordered_object(values), do: struct!(Module.concat(Jason, OrderedObject), values: values)

  defp map_or_empty(value) when is_map(value), do: value
  defp map_or_empty(_value), do: %{}
  defp list_or_empty(value) when is_list(value), do: value
  defp list_or_empty(_value), do: []
  defp entry_id(entry) when is_map(entry), do: entry["id"]
  defp entry_id(_entry), do: nil
end
