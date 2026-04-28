defmodule Rendro.Adapters.ThreadlineTest do
  use ExUnit.Case, async: false

  alias Rendro.Adapters.Threadline, as: Adapter
  alias Rendro.Test.Mocks

  setup do
    Mocks.reset_threadline()
    :ok = Adapter.attach()
    on_exit(fn -> Adapter.detach() end)
    :ok
  end

  defp sample_document do
    text = %Rendro.Text{content: "Audit me", font: "Helvetica", size: 12, color: {0, 0, 0}}
    block = %Rendro.Block{content: text, x: 10, y: 20}
    page = %Rendro.Page{blocks: [block]}
    %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "Audit Test"}}
  end

  defp failing_document do
    %Rendro.Document{pages: [], metadata: %Rendro.Metadata{}}
  end

  defp timeout_document do
    content = for i <- 1..200, do: Rendro.block(Rendro.text("timeout #{i}", size: 12))
    doc = Rendro.flow(content)
    put_in(doc.options[:policies], timeout: 0)
  end

  describe "telemetry to Threadline mapping" do
    test "successful render forwards :render_succeeded with PII-safe metadata" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())

      calls = Mocks.threadline_calls()
      assert [{action, metadata} | _] = calls
      assert action == :render_succeeded

      # Required metadata fields propagated from telemetry stop metadata
      for key <- [:render_id, :status, :page_count, :byte_size] do
        assert Map.has_key?(metadata, key), "missing metadata key #{inspect(key)}"
      end

      assert metadata.status == :ok
      assert metadata.page_count == 1
      assert metadata.byte_size > 0
      assert is_binary(metadata.render_id)

      # PII-safety: no document body / pages / blocks / binaries should leak.
      refute Map.has_key?(metadata, :pages)
      refute Map.has_key?(metadata, :content)
      refute Map.has_key?(metadata, :binary)
      refute Map.has_key?(metadata, :document)
    end

    test "failed render forwards :render_failed" do
      assert {:error, %Rendro.Error{}} = Rendro.Pipeline.run(failing_document())

      calls = Mocks.threadline_calls()
      assert [{action, metadata} | _] = calls
      assert action == :render_failed
      assert metadata.status == :error
    end

    test "render_id from telemetry is preserved into the audit call" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())

      [{_action, metadata} | _] = Mocks.threadline_calls()
      uuid_regex = ~r/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
      assert metadata.render_id =~ uuid_regex
    end

    test "duration is forwarded from measurements" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())

      [{_action, metadata} | _] = Mocks.threadline_calls()
      assert is_integer(metadata.duration)
      assert metadata.duration >= 0
    end

    test "timeout failures forward :render_failed with timeout subtype metadata" do
      assert {:error, %Rendro.Error{reason: :timeout}} = Rendro.Pipeline.run(timeout_document())

      calls = Mocks.threadline_calls()
      assert [{action, metadata} | _] = calls
      assert action == :render_failed
      assert metadata.status == :error
      assert metadata.stage == :render
      assert %{kind: :timeout, stage: :render} = metadata.error
    end
  end

  describe "attach/detach" do
    test "attach is idempotent" do
      assert :ok = Adapter.attach()
      assert :ok = Adapter.attach()
    end

    test "detach is idempotent and safe when not attached" do
      assert :ok = Adapter.detach()
      assert :ok = Adapter.detach()
    end

    test "after detach, no further events are forwarded" do
      :ok = Adapter.detach()
      Mocks.reset_threadline()

      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())

      assert Mocks.threadline_calls() == []
    end
  end

  describe "track_render/2 directly" do
    test "returns :ok when Threadline.record_action returns :ok" do
      assert :ok = Adapter.track_render("render-id-1", %{action: :render_succeeded})
    end

    test "returns backend errors from Threadline.record_action/2" do
      Mocks.set_threadline_result({:error, :backend_unavailable})

      assert {:error, :backend_unavailable} =
               Adapter.track_render("render-id-2", %{action: :render_failed})
    end

    test "wraps unexpected Threadline return shapes" do
      Mocks.set_threadline_result(:maybe)

      assert {:error, {:unexpected_return, :maybe}} =
               Adapter.track_render("render-id-3", %{action: :render_failed})
    end
  end
end
