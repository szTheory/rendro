defmodule Rendro.ViewerEvidence.ValidatorTest do
  use ExUnit.Case, async: true

  @matrix_schema_path "priv/schemas/support_matrix.schema.json"
  @evidence_schema_path "priv/schemas/viewer_evidence.schema.json"
  @matrix_path "priv/support_matrix.json"
  defp load_matrix do
    @matrix_path |> File.read!() |> JSON.decode!()
  end

  defp matrix_schema_root do
    @matrix_schema_path
    |> File.read!()
    |> JSON.decode!()
    |> JSV.build!()
  end

  defp evidence_schema_root do
    @evidence_schema_path
    |> File.read!()
    |> JSON.decode!()
    |> JSV.build!()
  end

  defp viewer_row_schema_root do
    schema = @matrix_schema_path |> File.read!() |> JSON.decode!()

    %{
      "$schema" => schema["$schema"],
      "$defs" => %{"viewer_row" => schema["$defs"]["viewer_row"]},
      "$ref" => "#/$defs/viewer_row"
    }
    |> JSV.build!()
  end

  describe "schema_contract" do
    @tag :schema_contract
    test "production support matrix passes Tier-A JSV validation" do
      matrix = load_matrix()
      root = matrix_schema_root()

      assert {:ok, _} = JSV.validate(matrix, root)
    end

    @tag :schema_contract
    test "production matrix has expected viewer cell status split" do
      matrix = load_matrix()
      statuses = collect_viewer_statuses(matrix)

      assert length(statuses) == 26
      assert Enum.count(statuses, &(&1 == "supported")) == 5
      assert Enum.count(statuses, &(&1 == "unverified")) == 21
      assert Enum.count(statuses, &(&1 == "explicit_deferral")) == 0
    end

    @tag :schema_contract
    test "viewer row rejects forbidden promotion keys via additionalProperties" do
      matrix = load_matrix()
      root = matrix_schema_root()

      invalid =
        put_in(
          matrix,
          ["forms", "viewers", "apple_preview", "compliance_tier"],
          "enterprise"
        )

      assert {:error, _} = JSV.validate(invalid, root)
    end

    @tag :schema_contract
    test "explicit_deferral requires evidence_deferred and forbids promotion keys" do
      root = viewer_row_schema_root()

      valid = %{
        "status" => "explicit_deferral",
        "evidence_deferred" =>
          "mozilla/pdf.js#4202 — signature widget rendering deferred pending upstream fix."
      }

      assert {:ok, _} = JSV.validate(valid, root)

      missing_reason = %{"status" => "explicit_deferral"}
      assert {:error, _} = JSV.validate(missing_reason, root)

      conflicting = %{
        "status" => "explicit_deferral",
        "evidence_deferred" =>
          "mozilla/pdf.js#4202 — signature widget rendering deferred pending upstream fix.",
        "evidence" => "priv/viewer_evidence/signature_widget/pdfjs.md"
      }

      assert {:error, _} = JSV.validate(conflicting, root)
    end

    @tag :schema_contract
    test "unverified forbids evidence and deferral keys" do
      root = viewer_row_schema_root()

      assert {:ok, _} = JSV.validate(%{"status" => "unverified"}, root)

      assert {:error, _} =
               JSV.validate(
                 %{
                   "status" => "unverified",
                   "evidence_deferred" => "some reason that is long enough to pass min length"
                 },
                 root
               )
    end

    @tag :schema_contract
    test "supported legacy rows pass without promotion keys (Tier-A carve-out)" do
      root = viewer_row_schema_root()

      legacy = %{
        "status" => "supported",
        "proof" => ["open", "default_state_visible", "edit_or_toggle", "save"]
      }

      assert {:ok, _} = JSV.validate(legacy, root)
    end

    @tag :schema_contract
    test "viewer evidence frontmatter schema accepts valid fixture reference" do
      root = evidence_schema_root()

      frontmatter = %{
        "schema_version" => 1,
        "surface" => "forms",
        "viewer" => "apple_preview",
        "viewer_version" => "15.0",
        "platform" => "macOS 15 (example)",
        "recorded_at" => "2026-01-01",
        "fixture" => "test/fixtures/example.pdf",
        "behaviors" => [
          %{
            "behavior" => "open",
            "result" => "pass",
            "note" => "Opened without error."
          }
        ]
      }

      assert {:ok, _} = JSV.validate(frontmatter, root)
    end

    @tag :schema_contract
    test "viewer evidence frontmatter schema rejects forbidden matrix keys" do
      root = evidence_schema_root()

      frontmatter = %{
        "schema_version" => 1,
        "surface" => "forms",
        "viewer" => "apple_preview",
        "viewer_version" => "15.0",
        "platform" => "macOS 15 (example)",
        "recorded_at" => "2026-01-01",
        "fixture" => "test/fixtures/example.pdf",
        "status" => "supported",
        "behaviors" => [
          %{
            "behavior" => "open",
            "result" => "pass",
            "note" => "Opened without error."
          }
        ]
      }

      assert {:error, _} = JSV.validate(frontmatter, root)
    end

    @tag :schema_contract
    test "schema descriptions document 65536 byte budget" do
      evidence_schema = File.read!(@evidence_schema_path)
      assert evidence_schema =~ "65536"
    end
  end

  defp collect_viewer_statuses(matrix) do
    [
      matrix["forms"]["viewers"],
      matrix["forms"]["signature_widget_viewers"],
      matrix["signing_preparation"]["viewers"],
      matrix["signing"]["viewers"],
      matrix["signing"]["long_lived"]["viewers"],
      matrix["embedded_files"]["viewers"],
      matrix["links"]["viewers"],
      matrix["protection"]["viewers"]
    ]
    |> Enum.flat_map(&Map.values/1)
    |> Enum.map(& &1["status"])
  end
end
