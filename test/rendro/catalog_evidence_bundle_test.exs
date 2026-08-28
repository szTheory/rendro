defmodule Rendro.CatalogEvidenceBundleTest do
  use ExUnit.Case, async: true

  alias Rendro.CatalogEvidenceBundle

  @candidate_sha String.duplicate("a", 40)
  @target_ids [
    "invoice--cedar-mutual--corporate-classic--dark",
    "statement--signal-ledger--minimal-mono--dark",
    "payslip--northline-logistics--swiss--light",
    "payslip--northline-logistics--swiss--dark",
    "ticket--aurora-live--brutalist--light",
    "ticket--aurora-live--brutalist--dark"
  ]
  @final_ids [
    "invoice--cedar-mutual--corporate-classic--light",
    "invoice--cedar-mutual--corporate-classic--dark",
    "statement--signal-ledger--minimal-mono--light",
    "statement--signal-ledger--minimal-mono--dark",
    "receipt--poppy-and-grain--humanist--light",
    "receipt--poppy-and-grain--humanist--dark",
    "certificate--meridian-arts-fellowship--editorial--light",
    "certificate--meridian-arts-fellowship--editorial--dark",
    "payslip--northline-logistics--swiss--light",
    "payslip--northline-logistics--swiss--dark",
    "ticket--aurora-live--brutalist--light",
    "ticket--aurora-live--brutalist--dark"
  ]
  @multipage_ids [
    "invoice-line-items-60-plus-page-first",
    "invoice-line-items-60-plus-page-final",
    "statement-line-items-60-plus-page-first",
    "statement-line-items-60-plus-page-final"
  ]
  @preset_ids [
    "brutalist_payslip_dark_page_1",
    "brutalist_receipt_light_page_1",
    "corporate_classic_branded_invoice_light_page_1",
    "corporate_classic_invoice_dark_page_1",
    "editorial_certificate_light_page_1",
    "editorial_ticket_dark_page_1",
    "humanist_payslip_dark_page_1",
    "humanist_receipt_light_page_1",
    "minimal_mono_statement_light_page_1",
    "minimal_mono_ticket_dark_page_1",
    "swiss_certificate_dark_page_1",
    "swiss_invoice_light_page_1"
  ]

  test "builds and validates a closed review bundle with candidate cells and image manifests" do
    root = temporary_root("review")

    assert :ok = CatalogEvidenceBundle.build(:review, review_sources(root), provenance(), root)
    assert :ok = CatalogEvidenceBundle.validate(root, :review, control_sha())

    manifest = root |> Path.join("manifest.json") |> File.read!() |> JSON.decode!()
    assert manifest["schema_version"] == 1
    assert manifest["operation"] == "review"
    assert manifest["candidate_sha"] == @candidate_sha

    assert Enum.map(manifest["payloads"], & &1["role"]) == [
             "candidate/catalog.json",
             "final-review/final.json",
             "multipage-review/multipage.json",
             "preset-review/preset.json"
           ]

    checksums =
      root |> Path.join("checksums.sha256") |> File.read!() |> String.split("\n", trim: true)

    assert checksums == Enum.sort(checksums)
  end

  test "builds exactly the canonical catalog role and count" do
    root = temporary_root("canonical")

    assert :ok =
             CatalogEvidenceBundle.build(:canonical, canonical_sources(root), provenance(), root)

    assert :ok = CatalogEvidenceBundle.validate(root, :canonical, control_sha())
  end

  test "rejects invalid operation, SHA binding, unsafe roles, and candidate approval" do
    root = temporary_root("invalid")

    assert {:error, reasons} =
             CatalogEvidenceBundle.build(:invalid, review_sources(root), provenance(), root)

    assert :invalid_operation in reasons

    assert {:error, reasons} =
             CatalogEvidenceBundle.build(
               :review,
               review_sources(root),
               %{provenance() | candidate_sha: "A" <> String.duplicate("a", 39)},
               root
             )

    assert :invalid_candidate_sha in reasons

    assert {:error, reasons} =
             CatalogEvidenceBundle.build(
               :review,
               [
                 %{
                   role: "../escape.json",
                   source: write_source(root, "bad", "x"),
                   media_type: "application/json",
                   count: 1
                 }
               ],
               provenance(),
               root
             )

    assert :invalid_payload_roles in reasons

    assert {:error, reasons} =
             CatalogEvidenceBundle.build(
               :review,
               review_sources(root),
               Map.put(provenance(), :reviewer_approval, true),
               root
             )

    assert :candidate_reviewer_approval_forbidden in reasons

    assert {:error, reasons} =
             CatalogEvidenceBundle.build(
               :review,
               review_sources(root),
               %{provenance() | run_id: "", run_attempt: 0},
               root
             )

    assert :invalid_provenance in reasons
  end

  test "fails closed on manifest, role, count, and payload hash drift" do
    root = temporary_root("drift")
    assert :ok = CatalogEvidenceBundle.build(:review, review_sources(root), provenance(), root)

    manifest_path = Path.join(root, "manifest.json")
    manifest = JSON.decode!(File.read!(manifest_path))

    for mutated <- [
          Map.put(manifest, "checked_out_head", String.duplicate("b", 40)),
          Map.update!(manifest, "payloads", &Enum.reverse/1),
          put_in(manifest, ["payloads", Access.at(0), "count"], 31)
        ] do
      File.write!(manifest_path, Jason.encode!(mutated, pretty: true))
      assert {:error, _reasons} = CatalogEvidenceBundle.validate(root, :review, control_sha())
    end

    File.write!(manifest_path, Jason.encode!(manifest, pretty: true))
    File.write!(Path.join(root, "candidate/catalog.json"), "tampered")
    assert {:error, reasons} = CatalogEvidenceBundle.validate(root, :review, control_sha())
    assert :payload_hash_mismatch in reasons
  end

  test "rejects a checksum-recomputed bundle whose control SHA differs from trusted control" do
    root = temporary_root("forged-control")
    assert :ok = CatalogEvidenceBundle.build(:review, review_sources(root), provenance(), root)
    forged_control_sha = String.duplicate("c", 40)

    rewrite_manifest_and_checksums(root, fn manifest ->
      put_in(manifest, ["control", "workflow_sha"], forged_control_sha)
    end)

    assert {:error, reasons} = CatalogEvidenceBundle.validate(root, :review, control_sha())
    assert :control_sha_mismatch in reasons

    assert {:error, reasons} = CatalogEvidenceBundle.validate(root, :review, forged_control_sha)
    assert :control_checkout_mismatch in reasons
  end

  test "rejects checksum-recomputed renderer version and digest drift" do
    root = temporary_root("forged-renderer")
    assert :ok = CatalogEvidenceBundle.build(:review, review_sources(root), provenance(), root)

    for renderer <- [
          %{"version" => "v9.9.9", "binary_sha256" => pin_sha(), "dpi" => 96},
          %{"version" => pin_version(), "binary_sha256" => String.duplicate("c", 64), "dpi" => 96}
        ] do
      rewrite_manifest_and_checksums(root, &Map.put(&1, "renderer", renderer))
      assert {:error, reasons} = CatalogEvidenceBundle.validate(root, :review, control_sha())
      assert :renderer_pin_mismatch in reasons
    end
  end

  test "derives every closed role count from its actual payload records" do
    root = temporary_root("actual-count")
    sources = review_sources(root)

    candidate = List.first(sources)
    File.write!(candidate.source, cells_json(31))

    assert {:error, reasons} = CatalogEvidenceBundle.build(:review, sources, provenance(), root)
    assert :invalid_payload_counts in reasons
  end

  test "validates exact semantic identities and joins one target through every review role" do
    root = temporary_root("semantic-review")
    sources = semantic_review_sources(root)

    assert :ok = CatalogEvidenceBundle.build(:review, sources, provenance(), root)
    assert {:ok, facts} = CatalogEvidenceBundle.inspect_review(root, control_sha())

    target = "ticket--aurora-live--brutalist--dark"
    candidate = Enum.find(facts.candidate["cells"], &(&1["id"] == target))
    final = Enum.find(facts.final["images"], &(&1["catalog_id"] == target))

    assert candidate["png_sha256"] == final["png_sha256"]
    assert candidate["source_pdf_sha256"] == final["source_pdf_sha256"]
    assert facts.candidate["candidate"]["commit_sha"] == @candidate_sha
    assert facts.final["run_attempt"] == 1
    assert facts.renderer["sha256"] == pin_sha()
  end

  test "rejects count-correct semantic forgeries and cross-payload identity drift" do
    root = temporary_root("semantic-forgery")
    sources = semantic_review_sources(root)
    candidate = List.first(sources)

    forged = semantic_candidate() |> put_in(["cells", Access.at(0), "id"], "arbitrary-item")
    File.write!(candidate.source, Jason.encode!(forged))

    assert {:error, reasons} = CatalogEvidenceBundle.build(:review, sources, provenance(), root)
    assert :invalid_candidate_payload in reasons

    sources = semantic_review_sources(root <> "-cross")
    final = Enum.at(sources, 1)
    payload = final.source |> File.read!() |> JSON.decode!()

    File.write!(
      final.source,
      Jason.encode!(
        put_in(payload, ["images", Access.at(0), "png_sha256"], String.duplicate("f", 64))
      )
    )

    assert {:error, reasons} =
             CatalogEvidenceBundle.build(:review, sources, provenance(), root <> "-cross-bundle")

    assert :cross_payload_identity_mismatch in reasons
  end

  test "fails closed for exact boundary, order, digest, path, renderer, commit, run, and attempt mutations" do
    root = temporary_root("semantic-matrix")

    mutations = [
      {:candidate, fn p -> update_in(p, ["cells"], &Enum.drop(&1, 1)) end},
      {:candidate, fn p -> update_in(p, ["cells"], &(&1 ++ [hd(&1)])) end},
      {:candidate, fn p -> update_in(p, ["cells"], &Enum.reverse/1) end},
      {:candidate, fn p -> put_in(p, ["diff", "changed_targets"], Enum.drop(@target_ids, 1)) end},
      {:candidate, fn p -> put_in(p, ["cells", Access.at(0), "png_path"], "../escape.png") end},
      {:candidate,
       fn p -> put_in(p, ["cells", Access.at(0), "png_sha256"], String.duplicate("a", 63)) end},
      {:candidate, fn p -> put_in(p, ["candidate", "commit_sha"], String.duplicate("b", 40)) end},
      {:candidate, fn p -> put_in(p, ["candidate", "run_id"], "999") end},
      {:candidate, fn p -> put_in(p, ["candidate", "run_attempt"], 2) end},
      {:final, fn p -> update_in(p, ["images"], &Enum.drop(&1, 1)) end},
      {:final, fn p -> update_in(p, ["images"], &Enum.reverse/1) end},
      {:multipage, fn p -> Enum.drop(p, 1) end},
      {:multipage,
       fn p ->
         List.replace_at(p, 0, {String.duplicate("A", 64), hd(@multipage_ids) <> ".png"})
       end},
      {:preset, fn p -> update_in(p, ["images"], &Enum.drop(&1, 1)) end},
      {:preset, fn p -> update_in(p, ["images"], &Enum.reverse/1) end},
      {:preset, fn p -> put_in(p, ["renderer", "sha256"], String.duplicate("b", 64)) end}
    ]

    for {role, mutate} <- mutations do
      case role do
        :multipage ->
          entries = mutate.(semantic_multipage_entries())
          assert_semantic_build_error(root, role, encode_checksum_entries(entries))

        _ ->
          payload = role |> semantic_payload() |> mutate.() |> Jason.encode!()
          assert_semantic_build_error(root, role, payload)
      end
    end
  end

  test "canonical role uses the exact ordered 32-cell catalog schema" do
    root = temporary_root("semantic-canonical")
    source = write_source(root, "canonical/catalog.json", Jason.encode!(semantic_canonical()))

    assert :ok =
             CatalogEvidenceBundle.build(
               :canonical,
               [
                 %{
                   role: "canonical/catalog.json",
                   source: source,
                   media_type: "application/json",
                   count: 32
                 }
               ],
               provenance(),
               root
             )

    for cells <- [
          [],
          Enum.drop(semantic_canonical()["cells"], 1),
          Enum.reverse(semantic_canonical()["cells"])
        ] do
      bad_root = temporary_root("bad-canonical")

      bad_source =
        write_source(
          bad_root,
          "canonical/catalog.json",
          Jason.encode!(%{semantic_canonical() | "cells" => cells})
        )

      assert {:error, reasons} =
               CatalogEvidenceBundle.build(
                 :canonical,
                 [
                   %{
                     role: "canonical/catalog.json",
                     source: bad_source,
                     media_type: "application/json",
                     count: 32
                   }
                 ],
                 provenance(),
                 bad_root
               )

      assert :invalid_payload_counts in reasons or :invalid_canonical_payload in reasons
    end
  end

  test "malformed renderer pins return structured errors" do
    root = temporary_root("pins")

    for contents <- ["not-json", Jason.encode!(%{"version" => 1, "sha256" => "short"})] do
      path = write_source(root, "pin-#{System.unique_integer([:positive])}.json", contents)
      assert {:error, [:invalid_renderer_pin]} = CatalogEvidenceBundle.validate_renderer_pin(path)
    end

    assert {:error, [:invalid_renderer_pin]} =
             CatalogEvidenceBundle.validate_renderer_pin(Path.join(root, "missing.json"))
  end

  defp provenance do
    %{
      candidate_sha: @candidate_sha,
      checked_out_head: @candidate_sha,
      control_sha: control_sha(),
      event: "workflow_dispatch",
      run_id: "12345",
      run_attempt: 1,
      dpi: 96
    }
  end

  defp review_sources(root) do
    [
      {"candidate/catalog.json", cells_json(32), 32},
      {"final-review/final.json", images_json(12), 12},
      {"multipage-review/multipage.json", checksums(4), 4},
      {"preset-review/preset.json", images_json(12), 12}
    ]
    |> Enum.map(fn {role, contents, count} ->
      %{
        role: role,
        source: write_source(root, role, contents),
        media_type: "application/json",
        count: count
      }
    end)
  end

  defp semantic_review_sources(root) do
    payloads = [
      {"candidate/catalog.json", Jason.encode!(semantic_candidate()), 32},
      {"final-review/final.json", Jason.encode!(semantic_final()), 12},
      {"multipage-review/multipage.json", encode_checksum_entries(semantic_multipage_entries()),
       4},
      {"preset-review/preset.json", Jason.encode!(semantic_preset()), 12}
    ]

    Enum.map(payloads, fn {role, contents, count} ->
      %{
        role: role,
        source: write_source(root, role, contents),
        media_type: "application/json",
        count: count
      }
    end)
  end

  defp semantic_candidate do
    ids = catalog_ids()

    %{
      "schema_version" => 1,
      "generated_by" => "mix rendro.catalog.candidate",
      "candidate" => %{
        "commit_sha" => @candidate_sha,
        "baseline_commit_sha" => control_sha(),
        "run_id" => "12345",
        "run_attempt" => 1,
        "renderer" => %{
          "kind" => "pdfium-render",
          "version" => pin_version(),
          "dpi" => 96,
          "pin_path" => "priv/pdfium_pin.json",
          "sha256" => pin_sha()
        }
      },
      "renderer" => %{
        "kind" => "pdfium-render",
        "version" => pin_version(),
        "dpi" => 96,
        "pin_path" => "priv/pdfium_pin.json",
        "pin_sha256" => pin_sha()
      },
      "cells" => Enum.map(ids, &candidate_cell/1),
      "multipage" => Enum.map(@multipage_ids, &candidate_multipage/1),
      "diff" => %{
        "changed_targets" => @target_ids,
        "changed_scored" => @target_ids,
        "changed_unscored" => [],
        "byte_stable" => Enum.reject(ids, &(&1 in @target_ids))
      }
    }
  end

  defp candidate_cell(id) do
    [family, _brand, _preset, mode] = String.split(id, "--")
    digest = digest_for(id)

    %{
      "id" => id,
      "family" => family,
      "mode" => mode,
      "page" => 1,
      "page_count" => 1,
      "png_path" => "tmp/phase130-candidate/png/#{id}.png",
      "png_sha256" => digest,
      "source_pdf_sha256" => digest_for("pdf:" <> id),
      "renderer_kind" => "pdfium-render",
      "renderer_version" => pin_version(),
      "renderer_sha256" => pin_sha(),
      "width_px" => 794,
      "height_px" => 1123,
      "review_status" => if(id in @target_ids, do: "review_required", else: "byte_stable")
    }
  end

  defp candidate_multipage(id) do
    [family | _] = String.split(id, "-")
    page = List.last(String.split(id, "-"))

    %{
      "id" => id,
      "family" => family,
      "page" => page,
      "png_path" => "tmp/phase130-candidate/multipage/#{id}.png",
      "png_sha256" => digest_for(id),
      "source_pdf_sha256" => digest_for("pdf:" <> id)
    }
  end

  defp semantic_final do
    %{
      "candidate_sha" => @candidate_sha,
      "control_sha" => control_sha(),
      "run_id" => "12345",
      "run_attempt" => 1,
      "renderer" => %{"version" => pin_version(), "sha256" => pin_sha()},
      "images" =>
        Enum.map(@final_ids, fn id ->
          cell = candidate_cell(id)

          %{
            "catalog_id" => id,
            "mode" => cell["mode"],
            "png_path" => cell["png_path"],
            "png_sha256" => cell["png_sha256"],
            "source_pdf_sha256" => cell["source_pdf_sha256"],
            "renderer_version" => pin_version(),
            "renderer_sha256" => pin_sha(),
            "commit_sha" => @candidate_sha,
            "control_sha" => control_sha(),
            "run_id" => "12345",
            "run_attempt" => 1
          }
        end)
    }
  end

  defp semantic_multipage_entries,
    do: Enum.map(@multipage_ids, &{digest_for(&1), &1 <> ".png"})

  defp semantic_preset do
    %{
      "candidate_sha" => @candidate_sha,
      "renderer" => %{"version" => pin_version(), "sha256" => pin_sha()},
      "images" =>
        Enum.map(@preset_ids, fn id ->
          %{"id" => id, "path" => "preset-review/#{id}.png", "sha256" => digest_for(id)}
        end)
    }
  end

  defp semantic_canonical do
    baseline = "assets/rendro/catalog.json" |> File.read!() |> JSON.decode!()
    Map.put(baseline, "source_commit_sha", control_sha())
  end

  defp semantic_payload(:candidate), do: semantic_candidate()
  defp semantic_payload(:final), do: semantic_final()
  defp semantic_payload(:preset), do: semantic_preset()

  defp assert_semantic_build_error(root, role, contents) do
    suffix = "#{role}-#{System.unique_integer([:positive])}"
    local_root = root <> "-" <> suffix
    sources = semantic_review_sources(local_root)
    index = %{candidate: 0, final: 1, multipage: 2, preset: 3}[role]
    File.write!(Enum.at(sources, index).source, contents)

    assert {:error, _reasons} =
             CatalogEvidenceBundle.build(:review, sources, provenance(), local_root <> "-bundle")
  end

  defp encode_checksum_entries(entries),
    do: Enum.map_join(entries, "\n", fn {digest, path} -> "#{digest}  #{path}" end) <> "\n"

  defp catalog_ids, do: Enum.map(Rendro.Catalog.catalog_specs(), & &1.id)

  defp digest_for(value),
    do: value |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)

  defp canonical_sources(root) do
    [
      %{
        role: "canonical/catalog.json",
        source: write_source(root, "canonical", Jason.encode!(semantic_canonical())),
        media_type: "application/json",
        count: 32
      }
    ]
  end

  defp write_source(root, name, contents) do
    path = Path.join([root <> "-inputs", name])
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, contents)
    path
  end

  defp images_json(count),
    do: Jason.encode!(%{"images" => Enum.map(1..count, &%{"id" => "item-#{&1}"})})

  defp cells_json(count),
    do: Jason.encode!(%{"cells" => Enum.map(1..count, &%{"id" => "item-#{&1}"})})

  defp checksums(count) do
    Enum.map_join(1..count, "\n", fn index ->
      "#{String.duplicate("a", 64)}  page-#{index}.png"
    end) <> "\n"
  end

  defp temporary_root(label) do
    root =
      Path.join(
        System.tmp_dir!(),
        "rendro-catalog-evidence-#{label}-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)
    root
  end

  defp rewrite_manifest_and_checksums(root, mutate_manifest) do
    manifest_path = Path.join(root, "manifest.json")
    manifest = manifest_path |> File.read!() |> JSON.decode!() |> mutate_manifest.()
    File.write!(manifest_path, Jason.encode!(manifest, pretty: true))

    root
    |> Path.join("checksums.sha256")
    |> File.write!(
      ["README.md", "manifest.json" | Enum.map(manifest["payloads"], & &1["path"])]
      |> Enum.sort()
      |> Enum.map_join("\n", fn path -> "#{sha256!(Path.join(root, path))}  #{path}" end)
      |> Kernel.<>("\n")
    )
  end

  defp control_sha do
    {sha, 0} = System.cmd("git", ["rev-parse", "HEAD"])
    String.trim(sha)
  end

  defp pin_version, do: pin()["version"]
  defp pin_sha, do: pin()["sha256"]
  defp pin, do: "priv/pdfium_pin.json" |> File.read!() |> JSON.decode!()

  defp sha256!(path) do
    path
    |> File.read!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
