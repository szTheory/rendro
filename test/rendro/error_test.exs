defmodule Rendro.ErrorTest do
  use ExUnit.Case, async: true

  test "from_stage/3 builds actionable diagnostics" do
    error =
      Rendro.Error.from_stage(:build, :no_pages, %{
        render_id: "render-123",
        deterministic: true,
        document_type: :pdf
      })

    assert error.stage == :build
    assert error.reason == :no_pages
    assert error.render_id == "render-123"
    assert error.where == "Rendro.Pipeline.Build"
    assert error.what =~ "validation"
    assert error.why == "no pages"
    assert error.next =~ "Add at least one page"
    assert error.details == %{document_type: :pdf, deterministic: true}
  end

  test "render/1 returns Rendro.Error on invalid documents" do
    assert {:error, %Rendro.Error{} = error} = Rendro.render(%Rendro.Document{pages: []})
    assert error.stage == :build
    assert error.reason == :no_pages
    assert is_binary(error.render_id)
  end

  describe "from_stage/3 with stage :measure (Phase 27)" do
    test ":unsupported_glyph emits fallback guidance" do
      err = Rendro.Error.from_stage(:measure, {:unsupported_glyph, "A"}, %{})
      assert err.stage == :measure
      assert err.why == "Missing glyph for character: A"
      assert err.next =~ "appropriate fallback font"
    end

    test ":unsupported_script emits shaping boundary guidance" do
      err = Rendro.Error.from_stage(:measure, {:unsupported_script, :rtl_required}, %{})
      assert err.stage == :measure
      assert err.why == "Unsupported script boundary: rtl required"

      assert err.next =~
               "Rendro does not currently support complex text shaping or RTL boundaries"
    end
  end

  describe "from_stage/3 with stage :validate (Phase 6 D-09)" do
    test ":structural_corruption emits the structural-bug guidance" do
      err = Rendro.Error.from_stage(:validate, :structural_corruption, %{})
      assert err.stage == :validate
      assert err.reason == :structural_corruption
      assert err.where == "Rendro.Pipeline.Validate"
      assert err.what == "Post-render validation failed."
      assert err.next =~ "PDF header/trailer missing"
    end

    test ":page_count_mismatch emits the pipeline-bug guidance" do
      err = Rendro.Error.from_stage(:validate, :page_count_mismatch, %{})
      assert err.stage == :validate
      assert err.what == "Post-render validation failed."
      assert err.next =~ "Rendered page count diverged"
    end

    test ":max_bytes_exceeded emits the policy guidance" do
      err = Rendro.Error.from_stage(:validate, :max_bytes_exceeded, %{})
      assert err.stage == :validate
      assert err.next =~ ":max_bytes policy limit"
    end

    test ":validate stage where field uses Macro.camelize" do
      err = Rendro.Error.from_stage(:validate, :structural_corruption)
      assert err.where == "Rendro.Pipeline.Validate"
    end
  end

  describe "from_stage/3 with stage :protect" do
    test "missing executable emits qpdf guidance" do
      err = Rendro.Error.from_stage(:protect, {:missing_executable, "qpdf"})
      assert err.stage == :protect
      assert err.where == "Rendro.Pipeline.Protect"
      assert err.what == "PDF protection failed while wrapping the rendered artifact."
      assert err.next =~ "Install qpdf"
    end

    test "invalid algorithm emits AES-256 guidance" do
      err = Rendro.Error.from_stage(:protect, {:invalid_option, :algorithm, :aes_128})
      assert err.stage == :protect
      assert err.why == "Invalid protection option algorithm: :aes_128"
      assert err.next =~ "algorithm: :aes_256"
    end

    test "adapter qpdf failures stay actionable without surfacing raw stderr" do
      err =
        Rendro.Error.from_stage(
          :protect,
          {:adapter_failure, Rendro.Adapters.Qpdf, {:qpdf_failed, 2}}
        )

      assert err.stage == :protect

      assert err.why ==
               "Protection adapter Rendro.Adapters.Qpdf failed: qpdf exited with status 2"

      assert err.next =~ "adapter stderr/output"
    end
  end

  describe "from_stage/3 with stage :prepare" do
    test "missing field option emits signing-preparation guidance" do
      err = Rendro.Error.from_stage(:prepare, {:missing_required_option, :field})
      assert err.stage == :prepare
      assert err.where == "Rendro.Pipeline.Prepare"
      assert err.what == "PDF signing preparation failed while wrapping the rendered artifact."
      assert err.next =~ "Pass field: \"signature_name\""
    end

    test "invalid reserved byte sizing stays actionable and secret-free" do
      err = Rendro.Error.from_stage(:prepare, {:invalid_option, :reserved_bytes, 0})
      assert err.stage == :prepare
      assert err.why == "Invalid signing preparation option reserved_bytes: 0"
      assert err.next =~ "positive integer"
      refute err.why =~ "certificate"
      refute err.why =~ "private key"
    end

    test "missing signature widget guidance stays field-scoped without signer details" do
      err = Rendro.Error.from_stage(:prepare, {:field_not_preparable, "customer_signature"})
      assert err.stage == :prepare
      assert err.why == "Rendered artifact does not expose a preparable signature field named customer_signature"
      assert err.next =~ "unsigned signature widget"
      refute err.next =~ "certificate"
      refute err.next =~ "private key"
    end
  end
end
