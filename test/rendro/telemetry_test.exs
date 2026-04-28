defmodule Rendro.TelemetryTest do
  use ExUnit.Case, async: false

  alias Rendro.Test.TelemetryHelper

  setup do
    handler_id = TelemetryHelper.attach()
    on_exit(fn -> TelemetryHelper.detach(handler_id) end)
    :ok
  end

  # Tagged-pending tests: tags retired in Phase 6 Plan 03 once the canonical
  # stage order (build → compose → measure → paginate → render → validate)
  # landed in `Rendro.Pipeline.run_stages/3`. The full telemetry contract is
  # asserted live without exclusions.

  defp sample_document do
    text = %Rendro.Text{content: "Hello!", font: "Helvetica", size: 12, color: {0, 0, 0}}
    block = %Rendro.Block{content: text, x: 10, y: 20}
    page = %Rendro.Page{blocks: [block]}
    %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "Telemetry Test"}}
  end

  defp deterministic_document do
    doc = sample_document()
    %{doc | options: %{render: [deterministic: true]}}
  end

  defp failing_document do
    %Rendro.Document{pages: [], metadata: %Rendro.Metadata{}}
  end

  defp timeout_document do
    content = for i <- 1..200, do: Rendro.block(Rendro.text("timeout #{i}", size: 12))
    doc = Rendro.flow(content)
    put_in(doc.options[:policies], timeout: 0)
  end

  defp events_by_suffix(events, suffix) do
    Enum.filter(events, fn {event, _m, _meta} -> List.last(event) == suffix end)
  end

  defp stage_events(events, stage, suffix) do
    Enum.filter(events, fn {event, _m, _meta} -> event == [:rendro, :pipeline, stage, suffix] end)
  end

  defp render_events(events, suffix) do
    Enum.filter(events, fn {event, _m, _meta} -> event == [:rendro, :render, suffix] end)
  end

  describe "successful render emits start+stop for all stages" do
    test "all 6 pipeline stages emit start and stop events" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      for stage <- [:build, :compose, :measure, :paginate, :render, :validate] do
        starts = stage_events(events, stage, :start)
        stops = stage_events(events, stage, :stop)
        assert starts != [], "expected 1 start event for #{stage}, got 0"
        assert stops != [], "expected 1 stop event for #{stage}, got 0"
      end
    end

    test "top-level [:rendro, :render] span emits start and stop" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      starts = render_events(events, :start)
      stops = render_events(events, :stop)
      assert length(starts) == 1
      assert length(stops) == 1
    end

    test "total event count: 6 stages + 1 top-level = 14 (7 start + 7 stop)" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      start_events = events_by_suffix(events, :start)
      stop_events = events_by_suffix(events, :stop)
      exception_events = events_by_suffix(events, :exception)

      assert length(start_events) == 7
      assert length(stop_events) == 7
      assert exception_events == []
    end
  end

  describe "render_id consistency" do
    test "all events share the same render_id" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      render_ids =
        events
        |> Enum.map(fn {_event, _m, meta} -> meta.render_id end)
        |> Enum.uniq()

      assert length(render_ids) == 1, "expected 1 unique render_id, got: #{inspect(render_ids)}"
    end

    test "render_id is a valid UUID v4 string" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      [{_event, _m, meta} | _] = events
      uuid_regex = ~r/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
      assert meta.render_id =~ uuid_regex
    end

    test "different renders produce different render_ids" do
      {:ok, _pdf1} = Rendro.Pipeline.run(sample_document())
      events1 = TelemetryHelper.collect_events()

      {:ok, _pdf2} = Rendro.Pipeline.run(sample_document())
      events2 = TelemetryHelper.collect_events()

      [{_e1, _m1, meta1} | _] = events1
      [{_e2, _m2, meta2} | _] = events2

      assert meta1.render_id != meta2.render_id
    end
  end

  describe "stop event metadata" do
    test "stop events include duration in measurements" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      stop_events = events_by_suffix(events, :stop)

      for {_event, measurements, _meta} <- stop_events do
        assert Map.has_key?(measurements, :duration),
               "stop event missing :duration in measurements"

        assert is_integer(measurements.duration)
        assert measurements.duration >= 0
      end
    end

    test "stop events include status, page_count, byte_size in metadata" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      stop_events = events_by_suffix(events, :stop)

      for {_event, _measurements, meta} <- stop_events do
        assert Map.has_key?(meta, :status)
        assert Map.has_key?(meta, :page_count)
        assert Map.has_key?(meta, :byte_size)
      end
    end

    test "successful render has status: :ok on all stop events" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      stop_events = events_by_suffix(events, :stop)

      for {_event, _measurements, meta} <- stop_events do
        assert meta.status == :ok
      end
    end

    test "render stage stop event has non-zero byte_size" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      [render_stop] = stage_events(events, :render, :stop)
      {_event, _measurements, meta} = render_stop
      assert meta.byte_size > 0
    end

    test "page_count matches document pages on render stop" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      [render_stop] = stage_events(events, :render, :stop)
      {_event, _measurements, meta} = render_stop
      assert meta.page_count == 1
    end

    test "top-level render stop includes page_count and byte_size" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      [top_stop] = render_events(events, :stop)
      {_event, _measurements, meta} = top_stop
      assert meta.page_count == 1
      assert meta.byte_size > 0
      assert meta.status == :ok
    end
  end

  describe "start event metadata" do
    test "start events include render_id, stage, and document_type" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      start_events = events_by_suffix(events, :start)

      for {_event, _measurements, meta} <- start_events do
        assert Map.has_key?(meta, :render_id)
        assert Map.has_key?(meta, :stage)
        assert Map.has_key?(meta, :document_type)
        assert meta.document_type == :pdf
      end
    end

    test "each stage start event has the correct stage name" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      for stage <- [:build, :compose, :measure, :paginate, :render, :validate] do
        [start] = stage_events(events, stage, :start)
        {_event, _measurements, meta} = start
        assert meta.stage == stage
      end
    end
  end

  describe "deterministic flag" do
    test "deterministic: false when option not set" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      start_events = events_by_suffix(events, :start)

      for {_event, _measurements, meta} <- start_events do
        assert Map.has_key?(meta, :deterministic)
        assert meta.deterministic == false
      end
    end

    test "deterministic: true when option set" do
      {:ok, _pdf} = Rendro.Pipeline.run(deterministic_document())
      events = TelemetryHelper.collect_events()

      start_events = events_by_suffix(events, :start)

      for {_event, _measurements, meta} <- start_events do
        assert meta.deterministic == true
      end
    end
  end

  describe "failed render" do
    test "error in build stage emits stop with status: :error" do
      assert {:error, %Rendro.Error{reason: :no_pages}} = Rendro.Pipeline.run(failing_document())
      events = TelemetryHelper.collect_events()

      [build_stop] = stage_events(events, :build, :stop)
      {_event, _measurements, meta} = build_stop
      assert meta.status == :error
      assert meta.page_count == 0
      assert meta.byte_size == 0
    end

    test "error in build stage still emits top-level stop with status: :error" do
      assert {:error, %Rendro.Error{reason: :no_pages}} = Rendro.Pipeline.run(failing_document())
      events = TelemetryHelper.collect_events()

      [top_stop] = render_events(events, :stop)
      {_event, _measurements, meta} = top_stop
      assert meta.status == :error
    end

    test "stages after the failed stage do not emit events" do
      assert {:error, %Rendro.Error{reason: :no_pages}} = Rendro.Pipeline.run(failing_document())
      events = TelemetryHelper.collect_events()

      for stage <- [:compose, :measure, :paginate, :render, :validate] do
        starts = stage_events(events, stage, :start)
        assert starts == [], "#{stage} should not have started after build failure"
      end
    end

    test "failed render emits build start, build stop, top-level start, top-level stop" do
      assert {:error, %Rendro.Error{reason: :no_pages}} = Rendro.Pipeline.run(failing_document())
      events = TelemetryHelper.collect_events()

      event_names = Enum.map(events, fn {event, _m, _meta} -> event end)

      assert [:rendro, :render, :start] in event_names
      assert [:rendro, :render, :stop] in event_names
      assert [:rendro, :pipeline, :build, :start] in event_names
      assert [:rendro, :pipeline, :build, :stop] in event_names
    end

    test "timeout emits a top-level render stop with timeout error metadata" do
      assert {:error, %Rendro.Error{reason: :timeout}} = Rendro.Pipeline.run(timeout_document())
      events = TelemetryHelper.collect_events()

      starts = render_events(events, :start)
      stops = render_events(events, :stop)

      assert length(starts) == 1
      assert length(stops) == 1

      [{_event, measurements, meta}] = stops
      assert is_integer(measurements.duration)
      assert measurements.duration >= 0
      assert meta.status == :error
      assert meta.stage == :render
      assert %{kind: :timeout, stage: :render} = meta.error
    end
  end

  describe "exception handling" do
    test "exception in a stage emits exception event via telemetry.span" do
      defmodule RaisingBuild do
        def run(_doc), do: raise("boom")
      end

      doc = sample_document()
      render_id = Rendro.Telemetry.generate_render_id()
      meta = %{render_id: render_id, stage: :build, document_type: :pdf, deterministic: false}

      assert_raise RuntimeError, "boom", fn ->
        :telemetry.span([:rendro, :pipeline, :build], meta, fn ->
          RaisingBuild.run(doc)
        end)
      end

      events = TelemetryHelper.collect_events()
      exception_events = stage_events(events, :build, :exception)
      assert length(exception_events) == 1

      [{_event, measurements, meta}] = exception_events
      assert Map.has_key?(measurements, :duration)
      assert Map.has_key?(meta, :kind)
      assert Map.has_key?(meta, :reason)
      assert Map.has_key?(meta, :stacktrace)
    end
  end

  describe "event ordering" do
    test "events fire in pipeline stage order" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      stage_starts =
        events
        |> Enum.filter(fn {event, _m, _meta} ->
          match?([:rendro, :pipeline, _, :start], event)
        end)
        |> Enum.map(fn {[:rendro, :pipeline, stage, :start], _m, _meta} -> stage end)

      assert stage_starts == [:build, :compose, :measure, :paginate, :render, :validate]
    end

    test "top-level render start fires before all stage starts" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      event_names = Enum.map(events, fn {event, _m, _meta} -> event end)
      render_start_idx = Enum.find_index(event_names, &(&1 == [:rendro, :render, :start]))
      first_stage_idx = Enum.find_index(event_names, &match?([:rendro, :pipeline, _, :start], &1))

      assert render_start_idx < first_stage_idx
    end

    test "top-level render stop fires after all stage stops" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      event_names = Enum.map(events, fn {event, _m, _meta} -> event end)
      render_stop_idx = Enum.find_index(event_names, &(&1 == [:rendro, :render, :stop]))

      last_stage_stop_idx =
        event_names
        |> Enum.with_index()
        |> Enum.filter(fn {event, _i} -> match?([:rendro, :pipeline, _, :stop], event) end)
        |> Enum.map(fn {_event, i} -> i end)
        |> List.last()

      assert render_stop_idx > last_stage_stop_idx
    end

    test "each stage start fires before its stop" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      event_names = Enum.map(events, fn {event, _m, _meta} -> event end)

      for stage <- [:build, :compose, :measure, :paginate, :render, :validate] do
        start_idx = Enum.find_index(event_names, &(&1 == [:rendro, :pipeline, stage, :start]))
        stop_idx = Enum.find_index(event_names, &(&1 == [:rendro, :pipeline, stage, :stop]))
        assert start_idx < stop_idx, "#{stage} start should fire before stop"
      end
    end

    test ":validate stop event fires after :render stop" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      event_names = Enum.map(events, fn {event, _m, _meta} -> event end)

      render_stop_idx =
        Enum.find_index(event_names, &(&1 == [:rendro, :pipeline, :render, :stop]))

      validate_stop_idx =
        Enum.find_index(event_names, &(&1 == [:rendro, :pipeline, :validate, :stop]))

      assert render_stop_idx != nil, "render stop event missing"
      assert validate_stop_idx != nil, "validate stop event missing"

      assert validate_stop_idx > render_stop_idx,
             "expected :validate :stop after :render :stop"
    end

    test ":validate start event fires after :render stop" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      event_names = Enum.map(events, fn {event, _m, _meta} -> event end)

      render_stop_idx =
        Enum.find_index(event_names, &(&1 == [:rendro, :pipeline, :render, :stop]))

      validate_start_idx =
        Enum.find_index(event_names, &(&1 == [:rendro, :pipeline, :validate, :start]))

      assert render_stop_idx != nil
      assert validate_start_idx != nil
      assert validate_start_idx > render_stop_idx
    end
  end

  describe "stage_names contract (Phase 6 OBS-01)" do
    test "Rendro.Telemetry.stage_names/0 includes :validate in spec order" do
      assert Rendro.Telemetry.stage_names() ==
               [:build, :compose, :measure, :paginate, :render, :validate]
    end

    test "Rendro.Telemetry.all_event_names/0 includes :validate event names" do
      names = Rendro.Telemetry.all_event_names()
      assert [:rendro, :pipeline, :validate, :start] in names
      assert [:rendro, :pipeline, :validate, :stop] in names
      assert [:rendro, :pipeline, :validate, :exception] in names
    end
  end

  describe "unified stop_meta schema (Phase 6 D-11)" do
    test "all stop events carry full D-11 schema (render_id, document_type, deterministic, stage, status, page_count, byte_size)" do
      {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
      events = TelemetryHelper.collect_events()

      stop_events = events_by_suffix(events, :stop)
      assert stop_events != []

      expected_keys = [
        :render_id,
        :document_type,
        :deterministic,
        :stage,
        :status,
        :page_count,
        :byte_size
      ]

      for {_event, _measurements, meta} <- stop_events do
        for key <- expected_keys do
          assert Map.has_key?(meta, key),
                 "stop event missing key #{inspect(key)}: #{inspect(meta)}"
        end
      end
    end

    test "error-path stop_meta carries page_count from doc.pages, not 0 (MINOR-15 regression)" do
      # 1-page doc forced to fail at :validate by setting impossible max_bytes.
      # NOTE: until Plan 02 lands the :validate stage, this fails on the OLD
      # max_bytes path which is attributed to :render. Tagged pending until
      # Plan 02 ships.
      doc = sample_document() |> put_in([Access.key(:options), :policies], max_bytes: 1)

      assert {:error, %Rendro.Error{reason: :max_bytes_exceeded}} = Rendro.Pipeline.run(doc)
      events = TelemetryHelper.collect_events()

      # Find any failing stage stop and assert page_count is the doc's true page count.
      error_stops =
        events
        |> events_by_suffix(:stop)
        |> Enum.filter(fn {_e, _m, meta} -> meta.status == :error end)

      assert error_stops != []

      for {_e, _m, meta} <- error_stops do
        assert meta.page_count == 1,
               "expected page_count: 1 (length(doc.pages)) but got #{inspect(meta.page_count)} on stop meta #{inspect(meta)}"
      end
    end

    test "error-path stop_meta includes :error map with kind and stage (D-14)" do
      assert {:error, %Rendro.Error{}} = Rendro.Pipeline.run(failing_document())
      events = TelemetryHelper.collect_events()

      [build_stop] = stage_events(events, :build, :stop)
      {_event, _measurements, meta} = build_stop
      assert meta.status == :error
      assert %{kind: :no_pages, stage: :build} = meta.error
    end
  end
end
