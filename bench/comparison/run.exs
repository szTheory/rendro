defmodule Rendro.Comparison.Runner do
  @moduledoc false

  @comparators ~w(rendro chromic_pdf chromic_pdf_warm_pool pdf_generator typst_cli)
  @metric_ids ~w(cold_start_ms rss_mb container_image_mb dependency_count)
  @raw_dir "bench/results/raw"
  @tmp_dir Path.join(@raw_dir, "_tmp")
  @manifest_path "bench/results/comparison.json"
  @pins_path "bench/comparison/pins.json"
  @fixture_path "bench/comparison/fixtures/invoice_data.json"
  @docker_image "rendro-comparison-bookworm:local"
  @dockerfile "bench/comparison/Dockerfile"
  @repetitions 3

  def main(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args,
        strict: [help: :boolean, track: :string, all: :boolean, comparator: :string],
        aliases: [h: :help]
      )

    cond do
      opts[:help] ->
        IO.puts(help())
        System.halt(0)

      invalid != [] ->
        IO.puts(:stderr, "Invalid options: #{inspect(invalid)}")
        System.halt(64)

      rest != [] ->
        IO.puts(:stderr, "Unexpected arguments: #{Enum.join(rest, " ")}")
        System.halt(64)

      opts[:track] not in [nil, "normalized"] ->
        IO.puts(:stderr, "Only --track normalized is supported")
        System.halt(64)

      true ->
        run_selected(opts)
    end
  end

  defp run_selected(opts) do
    selected =
      cond do
        opts[:all] -> @comparators
        is_binary(opts[:comparator]) -> [opts[:comparator]]
        true -> []
      end

    cond do
      selected == [] ->
        IO.puts(:stderr, "Select --all or --comparator #{Enum.join(@comparators, "|")}")
        System.halt(64)

      Enum.any?(selected, &(&1 not in @comparators)) ->
        IO.puts(:stderr, "Unknown comparator. Expected one of: #{Enum.join(@comparators, ", ")}")
        System.halt(64)

      true ->
        run_benchmarks(selected)
    end
  end

  defp run_benchmarks(selected) do
    File.mkdir_p!(@raw_dir)
    File.rm_rf!(@tmp_dir)
    File.mkdir_p!(@tmp_dir)

    if Enum.any?(selected, &(&1 in ~w(chromic_pdf chromic_pdf_warm_pool pdf_generator))) do
      build_docker_image!()
    end

    unless System.find_executable("typst") || "typst_cli" not in selected do
      abort!("typst executable is required. Install it with `brew install typst`.")
    end

    if "rendro" in selected do
      compile_rendro!()
    end

    fixture = @fixture_path |> File.read!() |> JSON.decode!()
    html = render_html_fixtures!(fixture)
    docker_info = docker_image_info()

    raw_artifacts =
      selected
      |> Enum.map(&run_comparator(&1, html, docker_info))
      |> Map.new(fn artifact -> {artifact["comparator"], artifact} end)

    existing = read_existing_manifest()
    all_artifacts = merge_existing_artifacts(existing, raw_artifacts)
    manifest = build_manifest(fixture, all_artifacts, docker_info)
    pins = build_pins(docker_info)

    File.write!(@manifest_path, encode_json(manifest) <> "\n")
    File.write!(@pins_path, encode_json(pins) <> "\n")
    File.rm_rf!(@tmp_dir)

    IO.puts("Wrote #{@manifest_path}")
    IO.puts("Wrote #{@pins_path}")
  end

  defp run_comparator("rendro", _html, docker_info) do
    output = output_pdf_path("rendro")

    samples =
      for index <- 1..@repetitions do
        run_host_sample(
          "rendro",
          index,
          "mix",
          ["run", "bench/comparison/fixtures/invoice_rendro.exs"],
          [{"RENDRO_BENCH_OUTPUT", output}]
        )
      end

    write_raw_artifact("rendro", samples, output, docker_info)
  end

  defp run_comparator("chromic_pdf" = comparator, html, docker_info) do
    run_chromic_pdf_comparator(comparator, html.chromic, docker_info, "cold")
  end

  defp run_comparator("chromic_pdf_warm_pool" = comparator, html, docker_info) do
    run_chromic_pdf_comparator(comparator, html.chromic, docker_info, "warm_pool")
  end

  defp run_comparator("pdf_generator" = comparator, html, docker_info) do
    output = output_pdf_path(comparator)
    html_path = Path.relative_to_cwd(html.pdf_generator)

    samples =
      for index <- 1..@repetitions do
        run_docker_sample(
          comparator,
          index,
          "/usr/bin/time -v elixir bench/comparison/tools/pdf_generator_render.exs /work/#{html_path} /work/#{output}"
        )
      end

    write_raw_artifact(comparator, samples, output, docker_info)
  end

  defp run_comparator("typst_cli" = comparator, _html, docker_info) do
    output = output_pdf_path(comparator)

    samples =
      for index <- 1..@repetitions do
        run_host_sample(
          comparator,
          index,
          "typst",
          [
            "compile",
            "--input",
            "data-path=invoice_data.json",
            "bench/comparison/fixtures/invoice_typst.typ",
            output
          ],
          []
        )
      end

    write_raw_artifact(comparator, samples, output, docker_info)
  end

  defp run_chromic_pdf_comparator(comparator, html_path, docker_info, mode) do
    output = output_pdf_path(comparator)
    html_path = Path.relative_to_cwd(html_path)

    samples =
      for index <- 1..@repetitions do
        run_docker_sample(
          comparator,
          index,
          "/usr/bin/time -v elixir bench/comparison/tools/chromic_pdf_render.exs #{mode} /work/#{html_path} /work/#{output}"
        )
      end

    write_raw_artifact(comparator, samples, output, docker_info)
  end

  defp output_pdf_path(comparator) do
    path = Path.join(@raw_dir, "#{comparator}.pdf")
    File.rm(path)
    path
  end

  defp run_host_sample(comparator, index, command, args, env) do
    started_at = DateTime.utc_now()

    {output, status} =
      System.cmd("/usr/bin/time", ["-l", command | args],
        stderr_to_stdout: true,
        env: env
      )

    finished_at = DateTime.utc_now()

    %{
      "index" => index,
      "command" => Enum.join([command | args], " "),
      "started_at" => DateTime.to_iso8601(started_at),
      "finished_at" => DateTime.to_iso8601(finished_at),
      "duration_ms" => duration_ms(output, started_at, finished_at),
      "rss_mb" => parse_macos_rss_mb(output),
      "exit_status" => status,
      "output" => output
    }
    |> tap(fn _sample ->
      if status != 0, do: abort!("#{comparator} sample #{index} failed:\n#{output}")
    end)
  end

  defp run_docker_sample(comparator, index, shell_command) do
    started_at = DateTime.utc_now()

    args = [
      "run",
      "--rm",
      "-v",
      "#{File.cwd!()}:/work",
      "-w",
      "/work",
      @docker_image,
      "sh",
      "-lc",
      shell_command
    ]

    {output, status} = System.cmd("docker", args, stderr_to_stdout: true)
    finished_at = DateTime.utc_now()

    %{
      "index" => index,
      "command" => "docker #{Enum.join(args, " ")}",
      "started_at" => DateTime.to_iso8601(started_at),
      "finished_at" => DateTime.to_iso8601(finished_at),
      "duration_ms" => duration_ms(output, started_at, finished_at),
      "rss_mb" => parse_linux_rss_mb(output),
      "exit_status" => status,
      "output" => output
    }
    |> tap(fn _sample ->
      if status != 0, do: abort!("#{comparator} sample #{index} failed:\n#{output}")
    end)
  end

  defp write_raw_artifact(comparator, samples, output_path, docker_info) do
    File.exists?(output_path) || abort!("#{comparator} did not produce #{output_path}")

    pdf = File.read!(output_path)
    pdf_sha = sha256(pdf)
    durations = Enum.map(samples, & &1["duration_ms"])
    rss_values = Enum.map(samples, & &1["rss_mb"])

    artifact = %{
      "artifact_kind" => "phase_87_normalized_benchmark",
      "public" => true,
      "comparator" => comparator,
      "fixture_id" => "invoice_v1",
      "recorded_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "measurement_method" => measurement_method(comparator),
      "samples" => samples,
      "summary" => %{
        "cold_start_ms" => summarize(durations, "ms"),
        "rss_mb" => summarize(rss_values, "MB"),
        "container_image_mb" => %{
          "median" => container_image_mb(comparator, docker_info),
          "p95" => container_image_mb(comparator, docker_info),
          "unit" => "MB",
          "samples" => 1
        },
        "dependency_count" => %{
          "median" => dependency_count(comparator),
          "p95" => dependency_count(comparator),
          "unit" => "count",
          "samples" => 1
        }
      },
      "output_pdf" => %{
        "path" => Path.relative_to_cwd(output_path),
        "sha256" => pdf_sha,
        "bytes" => byte_size(pdf)
      }
    }

    raw_path = Path.join(@raw_dir, "#{comparator}.json")
    File.write!(raw_path, encode_json(artifact) <> "\n")

    Map.merge(artifact, %{
      "raw_artifact" => raw_path,
      "raw_sha256" => sha256(File.read!(raw_path))
    })
  end

  defp build_manifest(fixture, artifacts, docker_info) do
    results =
      for comparator <- @comparators,
          metric <- @metric_ids do
        artifact = Map.fetch!(artifacts, comparator)
        summary = artifact["summary"][metric]

        %{
          "comparator" => comparator,
          "metric" => metric,
          "median" => summary["median"],
          "p95" => summary["p95"],
          "samples" => summary["samples"],
          "unit" => summary["unit"],
          "raw_artifact" => artifact["raw_artifact"],
          "raw_sha256" => artifact["raw_sha256"],
          "public" => true
        }
      end

    %{
      "schema_version" => 1,
      "generated_by" => "mix rendro.comparison.gen",
      "run" => %{
        "id" => "phase-87-normalized-#{Date.utc_today()}",
        "recorded_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "git_sha" => git_sha(),
        "host" => host_info(),
        "container" => %{
          "image" => @docker_image,
          "digest" => docker_info.digest,
          "size_mb" => docker_info.size_mb
        },
        "commands" => [
          "elixir bench/comparison/run.exs --track normalized --all"
        ],
        "repetitions" => @repetitions
      },
      "scenario" => %{
        "id" => fixture["fixture_id"],
        "fixture" => @fixture_path,
        "paper" => fixture["paper"],
        "line_items" => length(fixture["items"]),
        "fonts" => ["Arial", "Helvetica", "built-in PDF base fonts"]
      },
      "comparators" => comparator_metadata(docker_info),
      "results" => results,
      "claims" => public_claims()
    }
  end

  defp comparator_metadata(docker_info) do
    [
      %{
        "id" => "rendro",
        "label" => "Rendro",
        "version" => "1.0.0",
        "external_runtime" => "none",
        "measurement" => measurement_method("rendro")
      },
      %{
        "id" => "chromic_pdf",
        "label" => "ChromicPDF cold",
        "version" => "1.17.1",
        "external_runtime" => docker_info.chromium_version,
        "measurement" => measurement_method("chromic_pdf")
      },
      %{
        "id" => "chromic_pdf_warm_pool",
        "label" => "ChromicPDF warm pool",
        "version" => "1.17.1",
        "external_runtime" => docker_info.chromium_version,
        "measurement" => measurement_method("chromic_pdf_warm_pool")
      },
      %{
        "id" => "pdf_generator",
        "label" => "pdf_generator",
        "version" => "0.6.2",
        "external_runtime" => docker_info.wkhtmltopdf_version,
        "measurement" => measurement_method("pdf_generator")
      },
      %{
        "id" => "typst_cli",
        "label" => "Typst CLI",
        "version" => typst_version(),
        "external_runtime" => "typst",
        "measurement" => measurement_method("typst_cli")
      }
    ]
  end

  defp public_claims do
    [
      %{
        "id" => "CMP-COLD-START",
        "public" => true,
        "text" => "The normalized invoice harness records timing for each comparator posture.",
        "scope" =>
          "Phase 87 pinned invoice_v1 harness on the recorded host/container only; cold rows include process startup, and the warm-pool row times a render after an untimed warm-up render.",
        "evidence" => [%{"metric" => "cold_start_ms", "operator" => "reported"}]
      },
      %{
        "id" => "CMP-RSS",
        "public" => true,
        "text" => "The normalized invoice harness records process memory for each comparator.",
        "scope" =>
          "RSS values are measured by platform time tools and should be read as harness evidence, not a universal memory promise.",
        "evidence" => [%{"metric" => "rss_mb", "operator" => "reported"}]
      },
      %{
        "id" => "CMP-RUNTIME-BURDEN",
        "public" => true,
        "text" =>
          "The normalized invoice harness records runtime image size and external runtime count as separate operational metrics.",
        "scope" =>
          "Runtime burden is separate from render timing and excludes dependency download/build time.",
        "evidence" => [
          %{"metric" => "container_image_mb", "operator" => "reported"},
          %{"metric" => "dependency_count", "operator" => "reported"}
        ]
      }
    ]
  end

  defp build_pins(docker_info) do
    %{
      "rendro" => %{"version" => "1.0.0", "source" => "local checkout"},
      "chromic_pdf" => %{
        "constraint" => "~> 1.17",
        "resolved_version" => "1.17.1",
        "external_runtime" => docker_info.chromium_version
      },
      "pdf_generator" => %{
        "constraint" => "~> 0.6.2",
        "resolved_version" => "0.6.2",
        "external_runtime" => docker_info.wkhtmltopdf_version
      },
      "typst_cli" => %{
        "version" => typst_version(),
        "binary_source" => "Homebrew typst formula"
      },
      "container" => %{
        "image" => @docker_image,
        "digest" => docker_info.digest,
        "size_mb" => docker_info.size_mb,
        "dockerfile" => @dockerfile
      },
      "fonts" => ["Arial", "Helvetica", "built-in PDF base fonts"],
      "tools" => %{
        "docker" => docker_version(),
        "chromium" => docker_info.chromium_version,
        "wkhtmltopdf" => docker_info.wkhtmltopdf_version,
        "typst" => typst_version()
      }
    }
  end

  defp render_html_fixtures!(fixture) do
    binding = [
      invoice: fixture["invoice"],
      issuer: fixture["issuer"],
      customer: fixture["customer"],
      items: fixture["items"],
      totals: fixture["totals"]
    ]

    chromic = Path.join(@tmp_dir, "invoice_chromic_pdf.html")
    pdf_generator = Path.join(@tmp_dir, "invoice_pdf_generator.html")

    File.write!(
      chromic,
      EEx.eval_file("bench/comparison/fixtures/invoice_chromic_pdf.html.eex", binding)
    )

    File.write!(
      pdf_generator,
      EEx.eval_file("bench/comparison/fixtures/invoice_pdf_generator.html.eex", binding)
    )

    %{chromic: chromic, pdf_generator: pdf_generator}
  end

  defp build_docker_image! do
    {output, status} =
      System.cmd("docker", ["build", "-f", @dockerfile, "-t", @docker_image, "."],
        stderr_to_stdout: true
      )

    if status != 0 do
      abort!("could not build #{@docker_image}:\n#{output}")
    end
  end

  defp compile_rendro! do
    case System.cmd("mix", ["compile"], stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, _status} -> abort!("could not compile Rendro before benchmark:\n#{output}")
    end
  end

  defp docker_image_info do
    if docker_image_exists?() do
      %{
        digest: docker_image_digest(),
        size_mb: docker_image_size_mb(),
        chromium_version: docker_tool_version("chromium", ["--version"]),
        wkhtmltopdf_version: docker_tool_version("wkhtmltopdf", ["--version"])
      }
    else
      %{
        digest: "not-built",
        size_mb: 0,
        chromium_version: "not-built",
        wkhtmltopdf_version: "not-built"
      }
    end
  end

  defp docker_image_exists? do
    case System.cmd("docker", ["image", "inspect", @docker_image], stderr_to_stdout: true) do
      {_output, 0} -> true
      _other -> false
    end
  end

  defp docker_image_digest do
    case System.cmd("docker", ["image", "inspect", @docker_image, "--format", "{{.Id}}"],
           stderr_to_stdout: true
         ) do
      {output, 0} -> String.trim(output)
      _other -> "unknown"
    end
  end

  defp docker_image_size_mb do
    case System.cmd("docker", ["image", "inspect", @docker_image, "--format", "{{.Size}}"],
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        output |> String.trim() |> String.to_integer() |> Kernel./(1_048_576) |> Float.round(1)

      _other ->
        0
    end
  end

  defp docker_tool_version(command, args) do
    docker_args = ["run", "--rm", @docker_image, command | args]

    case System.cmd("docker", docker_args, stderr_to_stdout: true) do
      {output, 0} -> String.trim(output)
      {output, _status} -> "unavailable: #{String.trim(output)}"
    end
  end

  defp docker_version do
    case System.cmd("docker", ["--version"], stderr_to_stdout: true) do
      {output, 0} -> String.trim(output)
      _other -> "unavailable"
    end
  end

  defp typst_version do
    case System.cmd("typst", ["--version"], stderr_to_stdout: true) do
      {output, 0} -> String.trim(output)
      _other -> "unavailable"
    end
  end

  defp host_info do
    %{
      "os" => system_output("uname", ["-s"]),
      "arch" => system_output("uname", ["-m"]),
      "cpu" => system_output("sysctl", ["-n", "machdep.cpu.brand_string"]),
      "memory_limit_mb" => host_memory_mb()
    }
  end

  defp host_memory_mb do
    case System.cmd("sysctl", ["-n", "hw.memsize"], stderr_to_stdout: true) do
      {output, 0} -> output |> String.trim() |> String.to_integer() |> div(1_048_576)
      _other -> 0
    end
  end

  defp system_output(command, args) do
    case System.cmd(command, args, stderr_to_stdout: true) do
      {output, 0} -> String.trim(output)
      _other -> "unknown"
    end
  end

  defp merge_existing_artifacts(existing, raw_artifacts) do
    existing
    |> Map.merge(raw_artifacts)
    |> then(fn artifacts ->
      missing = @comparators -- Map.keys(artifacts)
      if missing != [], do: abort!("missing benchmark artifacts for #{Enum.join(missing, ", ")}")
      artifacts
    end)
  end

  defp read_existing_manifest do
    if File.exists?(@manifest_path) do
      @manifest_path
      |> File.read!()
      |> JSON.decode!()
      |> Map.get("results", [])
      |> Enum.map(& &1["comparator"])
      |> Enum.uniq()
      |> Enum.flat_map(fn comparator ->
        raw_path = Path.join(@raw_dir, "#{comparator}.json")

        if File.exists?(raw_path) do
          [
            {comparator,
             raw_path
             |> File.read!()
             |> JSON.decode!()
             |> Map.put("raw_artifact", raw_path)
             |> Map.put("raw_sha256", sha256(File.read!(raw_path)))}
          ]
        else
          []
        end
      end)
      |> Map.new()
    else
      %{}
    end
  end

  defp measurement_method("rendro"),
    do: "mix run Rendro.Recipes.Invoice.document/1 with deterministic render"

  defp measurement_method("chromic_pdf"),
    do: "ChromicPDF.print_to_pdf/2 cold process in the pinned benchmark container"

  defp measurement_method("chromic_pdf_warm_pool"),
    do:
      "ChromicPDF.print_to_pdf/2 after an untimed warm-pool render in the pinned benchmark container"

  defp measurement_method("pdf_generator"),
    do: "PdfGenerator.generate_binary/2 through wkhtmltopdf in the pinned benchmark container"

  defp measurement_method("typst_cli"), do: "typst compile using the native Typst fixture"

  defp container_image_mb(comparator, docker_info)
       when comparator in ~w(chromic_pdf chromic_pdf_warm_pool pdf_generator),
       do: docker_info.size_mb

  defp container_image_mb(_comparator, _docker_info), do: 0

  defp dependency_count("rendro"), do: 0

  defp dependency_count(comparator)
       when comparator in ~w(chromic_pdf chromic_pdf_warm_pool pdf_generator), do: 2

  defp dependency_count(_comparator), do: 1

  defp summarize(values, unit) do
    sorted = Enum.sort(values)

    %{
      "median" => percentile(sorted, 0.50),
      "p95" => percentile(sorted, 0.95),
      "unit" => unit,
      "samples" => length(values)
    }
  end

  defp percentile([], _percentile), do: 0

  defp percentile(values, percentile) do
    index =
      ((length(values) - 1) * percentile)
      |> Float.ceil()
      |> trunc()

    values
    |> Enum.at(index)
    |> normalize_number()
  end

  defp normalize_number(value) when is_integer(value), do: value
  defp normalize_number(value) when is_float(value), do: Float.round(value, 2)
  defp normalize_number(_value), do: 0

  defp parse_macos_rss_mb(output) do
    case Regex.run(~r/(\d+)\s+maximum resident set size/, output) do
      [_, bytes] -> bytes |> String.to_integer() |> Kernel./(1_048_576) |> Float.round(1)
      _ -> 0
    end
  end

  defp parse_linux_rss_mb(output) do
    case Regex.run(~r/Maximum resident set size \(kbytes\):\s*(\d+)/, output) do
      [_, kb] -> kb |> String.to_integer() |> Kernel./(1024) |> Float.round(1)
      _ -> 0
    end
  end

  defp duration_ms(output, started_at, finished_at) do
    case Regex.run(~r/RENDRO_BENCH_DURATION_MS=(\d+)/, output) do
      [_, duration] -> String.to_integer(duration)
      _ -> DateTime.diff(finished_at, started_at, :millisecond)
    end
  end

  defp git_sha do
    case System.cmd("git", ["rev-parse", "--short", "HEAD"], stderr_to_stdout: true) do
      {output, 0} -> String.trim(output)
      _other -> "unknown"
    end
  end

  defp encode_json(term), do: JSON.encode!(term)
  defp sha256(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)

  defp abort!(message) do
    IO.puts(:stderr, message)
    System.halt(1)
  end

  defp help do
    """
    Rendro comparison benchmark runner

    Track:
      normalized       Fixed invoice_v1 workload used for quantitative claims

    Comparator IDs:
      #{Enum.join(@comparators, "\n      ")}

    Usage:
      elixir bench/comparison/run.exs --track normalized --all
      elixir bench/comparison/run.exs --track normalized --comparator rendro
    """
    |> String.trim()
  end
end

Rendro.Comparison.Runner.main(System.argv())
