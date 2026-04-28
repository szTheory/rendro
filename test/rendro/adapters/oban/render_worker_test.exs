defmodule Rendro.Adapters.Oban.RenderWorkerTest do
  use ExUnit.Case, async: true

  alias Rendro.Adapters.Oban.RenderWorker

  defmodule SampleBuilder do
    def build_document(%{"content" => content} = args) do
      blocks =
        for line <- List.wrap(content) do
          Rendro.block(Rendro.text(line, size: 12))
        end

      doc = Rendro.flow(blocks)

      case Map.get(args, "doc_policies") do
        nil -> doc
        policies ->
          normalized =
            Enum.map(policies, fn
              {key, value} when is_binary(key) -> {String.to_atom(key), value}
              pair -> pair
            end)

          put_in(doc.options[:policies], normalized)
      end
    end
  end

  test "injects max_pages, max_bytes, and timeout when the document does not define them" do
    assert {:error, :max_pages_exceeded} =
             perform_worker(%{
               "content" => many_lines(),
               "policies" => %{"max_pages" => 1},
               "output_path" => tmp_output_path("max-pages.pdf")
             })

    assert {:error, :max_bytes_exceeded} =
             perform_worker(%{
               "content" => ["hello"],
               "policies" => %{"max_bytes" => 100},
               "output_path" => tmp_output_path("max-bytes.pdf")
             })

    assert {:error, :timeout} =
             perform_worker(%{
               "content" => many_lines(),
               "policies" => %{"timeout" => 0},
               "output_path" => tmp_output_path("timeout.pdf")
             })
  end

  test "document-authored policies win over worker policies when already present" do
    output_path = tmp_output_path("preserve-doc-policy.pdf")

    assert :ok =
             perform_worker(%{
               "content" => many_lines(),
               "doc_policies" => %{"max_pages" => 10},
               "policies" => %{"max_pages" => 1},
               "output_path" => output_path
             })

    assert File.exists?(output_path)
  end

  test "unknown policy keys fail with a typed worker-boundary error" do
    assert {:error, {:unknown_worker_policy, "max_kilobytes"}} =
             perform_worker(%{
               "content" => ["hello"],
               "policies" => %{"max_kilobytes" => 10},
               "output_path" => tmp_output_path("unknown-policy.pdf")
             })
  end

  test "invalid policy values fail with a typed worker-boundary error" do
    assert {:error, {:invalid_worker_policy, :timeout, "fast"}} =
             perform_worker(%{
               "content" => ["hello"],
               "policies" => %{"timeout" => "fast"},
               "output_path" => tmp_output_path("bad-timeout.pdf")
             })

    assert {:error, {:invalid_worker_policy, :max_pages, -1}} =
             perform_worker(%{
               "content" => ["hello"],
               "policies" => %{"max_pages" => -1},
               "output_path" => tmp_output_path("bad-max-pages.pdf")
             })
  end

  test "malformed required worker fields do not crash" do
    assert {:error, {:missing_worker_field, :module}} =
             RenderWorker.perform(%Oban.Job{args: %{}})

    assert {:error, {:unknown_worker_module, "Missing.Builder"}} =
             perform_worker(%{
               "module" => "Missing.Builder",
               "args" => %{},
               "output_path" => tmp_output_path("unknown-module.pdf")
             })

    assert {:error, {:invalid_worker_field, :args, :bad_args}} =
             RenderWorker.perform(%Oban.Job{
               args: %{
                 "module" => Atom.to_string(SampleBuilder),
                 "args" => :bad_args,
                 "output_path" => tmp_output_path("bad-args.pdf")
               }
             })

    assert {:error, {:invalid_worker_field, :output_path, 123}} =
             perform_worker(%{
               "content" => ["hello"],
               "output_path" => 123
             })
  end

  defp perform_worker(overrides) do
    args =
      %{
        "module" => Atom.to_string(SampleBuilder),
        "args" => %{"content" => ["hello"]},
        "output_path" => tmp_output_path("default.pdf")
      }
      |> Map.merge(overrides)
      |> maybe_put_args(overrides)

    RenderWorker.perform(%Oban.Job{args: args})
  end

  defp maybe_put_args(args, %{"content" => content} = overrides) do
    builder_args =
      %{"content" => content}
      |> maybe_put_doc_policies(overrides)

    Map.put(args, "args", builder_args)
  end

  defp maybe_put_args(args, overrides) do
    builder_args =
      %{"content" => ["hello"]}
      |> maybe_put_doc_policies(overrides)

    Map.put_new(args, "args", builder_args)
  end

  defp maybe_put_doc_policies(builder_args, %{"doc_policies" => doc_policies}) do
    Map.put(builder_args, "doc_policies", doc_policies)
  end

  defp maybe_put_doc_policies(builder_args, _overrides), do: builder_args

  defp many_lines do
    for i <- 1..200, do: "Line #{i}"
  end

  defp tmp_output_path(filename) do
    base =
      Path.join(System.tmp_dir!(), "rendro-render-worker-#{System.unique_integer([:positive])}")

    on_exit(fn -> File.rm_rf(base) end)
    Path.join(base, filename)
  end
end
