defmodule Rendro.ViewerEvidence.ValidatorTest do
  use ExUnit.Case, async: true

  alias Rendro.ViewerEvidence.Matrix

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

  describe "lint" do
    @fixtures_dir "test/support/viewer_evidence/fixtures"

    @tag :lint
    test "Frontmatter.parse/1 splits YAML fences and returns body" do
      content = File.read!("#{@fixtures_dir}/invalid_evidence_image.md")

      assert {:ok, {frontmatter, body}} = Rendro.ViewerEvidence.Frontmatter.parse(content)
      assert frontmatter["schema_version"] == 1
      assert frontmatter["surface"] == "forms"
      assert body =~ "forbidden image embed"
    end

    @tag :lint
    test "path_alignment/2 errors when surface or viewer disagree with path" do
      frontmatter = %{"surface" => "forms", "viewer" => "apple_preview"}

      assert :ok =
               Rendro.ViewerEvidence.Frontmatter.path_alignment(
                 frontmatter,
                 "priv/viewer_evidence/forms/apple_preview.md"
               )

      assert {:error, reason} =
               Rendro.ViewerEvidence.Frontmatter.path_alignment(
                 frontmatter,
                 "priv/viewer_evidence/protection/apple_preview.md"
               )

      assert reason =~ "surface"
    end

    @tag :lint
    test "evidence_body/1 rejects image, secret, and home-path fixtures" do
      image = File.read!("#{@fixtures_dir}/invalid_evidence_image.md")
      {:ok, {_fm, image_body}} = Rendro.ViewerEvidence.Frontmatter.parse(image)
      assert {:error, _} = Rendro.ViewerEvidence.Lint.evidence_body(image_body)

      secret = File.read!("#{@fixtures_dir}/invalid_evidence_secret.md")
      {:ok, {_fm, secret_body}} = Rendro.ViewerEvidence.Frontmatter.parse(secret)
      assert {:error, _} = Rendro.ViewerEvidence.Lint.evidence_body(secret_body)

      home = File.read!("#{@fixtures_dir}/invalid_evidence_home_path.md")
      {:ok, {_fm, home_body}} = Rendro.ViewerEvidence.Frontmatter.parse(home)
      assert {:error, _} = Rendro.ViewerEvidence.Lint.evidence_body(home_body)
    end

    @tag :lint
    test "evidence_body/1 allows negated passphrase prose" do
      body = "The viewer shows no passphrase: prompt and no private_key: material."

      assert {:ok, :clean} = Rendro.ViewerEvidence.Lint.evidence_body(body)
    end

    @tag :lint
    test "deferral_reason/1 rejects TBD, vague, short, and leading deferred-for-later reasons" do
      fixture = File.read!("#{@fixtures_dir}/invalid_deferral_tbd.json")
      %{"evidence_deferred" => reason} = JSON.decode!(fixture)
      assert {:error, _} = Rendro.ViewerEvidence.Lint.deferral_reason(reason)

      assert {:error, _} = Rendro.ViewerEvidence.Lint.deferral_reason("not yet")
      assert {:error, _} = Rendro.ViewerEvidence.Lint.deferral_reason("deferred for later")
      assert {:error, _} = Rendro.ViewerEvidence.Lint.deferral_reason("   ")

      assert {:error, _} =
               Rendro.ViewerEvidence.Lint.deferral_reason(
                 "Deferred for later when pdf.js fixes widget rendering."
               )

      assert {:error, _} =
               Rendro.ViewerEvidence.Lint.deferral_reason("Still tracking TBD in issue tracker.")
    end

    @tag :lint
    test "deferral_reason/1 allows substantive and allowlisted phrases" do
      assert {:ok, :clean} =
               Rendro.ViewerEvidence.Lint.deferral_reason(
                 "mozilla/pdf.js#4202 — signature widget rendering deferred pending upstream fix."
               )

      assert {:ok, :clean} =
               Rendro.ViewerEvidence.Lint.deferral_reason(
                 "Apple Preview does not yet implement signature widget appearance for this fixture."
               )
    end

    @tag :lint
    test "byte_budget/1 rejects content over 65536 bytes" do
      assert {:ok, :clean} =
               Rendro.ViewerEvidence.Lint.byte_budget(
                 File.read!("#{@fixtures_dir}/oversized_evidence.md")
               )

      oversized = String.duplicate("x", 65_537)
      assert {:error, reason} = Rendro.ViewerEvidence.Lint.byte_budget(oversized)
      assert reason =~ "65536"
    end
  end

  describe "matrix_walker" do
    @tag :matrix_walker
    test "enumerate_viewer_cells returns 26 cells sorted by surface then viewer" do
      matrix = Matrix.load!()
      cells = Matrix.enumerate_viewer_cells(matrix)

      assert length(cells) == 26
      assert cells == Enum.sort_by(cells, fn cell -> {cell.surface, cell.viewer} end)
    end

    @tag :matrix_walker
    test "production matrix status split is 5 supported, 21 unverified, 0 explicit_deferral" do
      matrix = Matrix.load!()
      cells = Matrix.enumerate_viewer_cells(matrix)

      assert Enum.count(cells, &(&1.status == "supported")) == 5
      assert Enum.count(cells, &(&1.status == "unverified")) == 21
      assert Enum.count(cells, &(&1.status == "explicit_deferral")) == 0
    end

    @tag :matrix_walker
    test "surface mapping uses evidence-path segments not matrix family names" do
      matrix = Matrix.load!()
      cells = Matrix.enumerate_viewer_cells(matrix)

      assert Enum.find(cells, &(&1.viewer == "apple_preview" && &1.surface == "forms"))
      assert Enum.find(cells, &(&1.viewer == "pdfjs" && &1.surface == "signature_widget"))
      assert Enum.find(cells, &(&1.viewer == "pdfjs" && &1.surface == "signed_artifact"))
      assert Enum.find(cells, &(&1.viewer == "pdfjs" && &1.surface == "long_lived_signed_artifact"))

      refute Enum.any?(cells, &(&1.surface == "signing"))
      refute Enum.any?(cells, &(&1.surface == "long_lived"))
    end

    @tag :matrix_walker
    test "walker includes all eight viewer maps" do
      matrix = Matrix.load!()
      cells = Matrix.enumerate_viewer_cells(matrix)

      map_paths =
        cells
        |> Enum.map(& &1.matrix_path)
        |> Enum.map(fn path ->
          path
          |> String.split(".")
          |> Enum.drop(-1)
          |> case do
            ["forms", "signature_widget_viewers"] -> "forms.signature_widget_viewers"
            ["signing", "long_lived", "viewers"] -> "signing.long_lived.viewers"
            [family, "viewers"] -> "#{family}.viewers"
          end
        end)
        |> Enum.uniq()
        |> Enum.sort()

      assert map_paths == [
               "embedded_files.viewers",
               "forms.signature_widget_viewers",
               "forms.viewers",
               "links.viewers",
               "protection.viewers",
               "signing.long_lived.viewers",
               "signing.viewers",
               "signing_preparation.viewers"
             ]
    end
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
