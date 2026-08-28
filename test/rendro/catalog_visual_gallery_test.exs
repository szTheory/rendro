defmodule Rendro.CatalogVisualGalleryTest do
  use ExUnit.Case, async: false

  alias Rendro.CatalogVisualGallery

  @targets [
    "invoice--cedar-mutual--corporate-classic--dark",
    "statement--signal-ledger--minimal-mono--dark",
    "payslip--northline-logistics--swiss--light",
    "payslip--northline-logistics--swiss--dark",
    "ticket--aurora-live--brutalist--light",
    "ticket--aurora-live--brutalist--dark"
  ]
  @review_roles [
    {"invoice_light_control", "invoice--cedar-mutual--corporate-classic--light", "control"},
    {"invoice_dark_target", "invoice--cedar-mutual--corporate-classic--dark", "target"},
    {"statement_light_control", "statement--signal-ledger--minimal-mono--light", "control"},
    {"statement_dark_target", "statement--signal-ledger--minimal-mono--dark", "target"},
    {"payslip_light_target", "payslip--northline-logistics--swiss--light", "target"},
    {"payslip_dark_target", "payslip--northline-logistics--swiss--dark", "target"},
    {"ticket_light_target", "ticket--aurora-live--brutalist--light", "target"},
    {"ticket_dark_target", "ticket--aurora-live--brutalist--dark", "target"}
  ]

  test "builds the exact eight-image family-paired packet without authority" do
    root = "tmp/catalog-visual-gallery-test-#{System.unique_integer([:positive])}"
    candidate_root = "tmp/phase130-candidate/gallery-test-#{System.unique_integer([:positive])}"
    File.mkdir_p!(candidate_root)

    on_exit(fn ->
      File.rm_rf(root)
      File.rm_rf(candidate_root)
    end)

    manifest = manifest(candidate_root)
    manifest_path = Path.join(candidate_root, "candidate-manifest.json")
    File.write!(manifest_path, Jason.encode!(manifest))
    final_path = Path.join(candidate_root, "final-manifest.json")
    File.write!(final_path, Jason.encode!(final_manifest(manifest)))

    assert {:ok, ^root} = CatalogVisualGallery.build(manifest_path, final_path, root)

    assert File.ls!(Path.join(root, "images")) |> Enum.sort() ==
             @review_roles
             |> Enum.map(fn {role, _id, _kind} -> role <> ".png" end)
             |> Enum.sort()

    assert %{"authority" => "none", "images" => images} =
             root |> Path.join("manifest.json") |> File.read!() |> JSON.decode!()

    assert Enum.map(images, & &1["review_role"]) == Enum.map(@review_roles, &elem(&1, 0))
    assert Enum.map(images, & &1["catalog_id"]) == Enum.map(@review_roles, &elem(&1, 1))

    assert Enum.map(images, & &1["kind"]) |> Enum.frequencies() == %{
             "control" => 2,
             "target" => 6
           }

    assert Enum.map(images, & &1["ordinal"]) == Enum.to_list(1..8)
    assert Enum.uniq_by(images, & &1["path"]) == images
    assert Enum.all?(images, &(&1["bundle_role"] == "final-review/final.json"))

    html = File.read!(Path.join(root, "index.html"))
    assert html =~ "Review packet / eight full-size surfaces"
    assert html =~ "no evidence, review, approval, disposition, or canonical authority"
  end

  test "rejects reordered targets, non-targets, and hash-mismatched pixels" do
    root = "tmp/catalog-visual-gallery-invalid-#{System.unique_integer([:positive])}"

    candidate_root =
      "tmp/phase130-candidate/gallery-invalid-#{System.unique_integer([:positive])}"

    File.mkdir_p!(candidate_root)

    on_exit(fn ->
      File.rm_rf(root)
      File.rm_rf(candidate_root)
    end)

    for invalid <- [
          put_in(manifest(candidate_root), ["diff", "changed_scored"], Enum.reverse(@targets)),
          put_in(
            manifest(candidate_root),
            ["diff", "changed_scored"],
            List.replace_at(@targets, 0, "not-a-target")
          ),
          hash_mismatch_manifest(candidate_root)
        ] do
      path = Path.join(candidate_root, "#{System.unique_integer([:positive])}.json")
      File.write!(path, Jason.encode!(invalid))
      final_path = Path.join(candidate_root, "final-#{System.unique_integer([:positive])}.json")
      File.write!(final_path, Jason.encode!(final_manifest(invalid)))
      assert {:error, _reason} = CatalogVisualGallery.build(path, final_path, root)
      refute File.exists?(root)
    end
  end

  test "rejects six-image, omitted-control, duplicate, reordered, stale, and cross-run packets" do
    packet = packet_manifest()

    mutations = [
      update_in(packet, ["images"], &Enum.drop(&1, 2)),
      update_in(packet, ["images"], &List.delete_at(&1, 0)),
      update_in(packet, ["images"], &List.replace_at(&1, 1, hd(&1))),
      update_in(packet, ["images"], &Enum.reverse/1),
      put_in(packet, ["images", Access.at(0), "png_sha256"], String.duplicate("f", 64)),
      Map.put(packet, "run_id", "999")
    ]

    for invalid <- mutations do
      assert {:error, _reasons} = CatalogVisualGallery.validate_manifest(invalid, packet_facts())
    end
  end

  test "accepts every truthful receipt status but keeps completion and qualification separate" do
    complete = receipt("complete")
    unavailable = receipt("unavailable")

    assert :ok = CatalogVisualGallery.validate_receipt(complete)
    assert :ok = CatalogVisualGallery.validate_receipt(unavailable)
    assert {:error, _} = CatalogVisualGallery.require_complete_receipt(unavailable)

    for status <- ~w(qualified missed incomplete unavailable) do
      review = review_receipt(status)
      assert :ok = CatalogVisualGallery.validate_review_receipt(review)

      if status == "qualified" do
        assert :ok = CatalogVisualGallery.require_qualified_review_receipt(review)
      else
        assert {:error, _} = CatalogVisualGallery.require_qualified_review_receipt(review)
      end
    end
  end

  test "receipt validators reject unknown fields, contradictory statuses, and stale fresh paths" do
    assert {:error, _} =
             CatalogVisualGallery.validate_receipt(Map.put(receipt("complete"), "extra", true))

    assert {:error, _} =
             CatalogVisualGallery.validate_receipt(%{
               receipt("unavailable")
               | "review_images" => [hd(packet_manifest()["images"])]
             })

    assert {:error, _} =
             CatalogVisualGallery.validate_review_receipt(
               put_in(review_receipt("missed"), ["failed_target_ids"], [])
             )

    assert {:error, _} =
             CatalogVisualGallery.require_complete_receipt(
               put_in(receipt("complete"), ["validation", "download_nonce"], "stale")
             )
  end

  defp manifest(candidate_root) do
    review_ids = Enum.map(@review_roles, &elem(&1, 1))

    cells =
      Enum.map(review_ids, fn id ->
        png =
          <<137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, "IHDR", 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0,
            0, 0>>

        path = Path.join(candidate_root, "#{id}.png")
        File.write!(path, png)
        [_, _, _, mode] = String.split(id, "--")

        %{
          "id" => id,
          "mode" => mode,
          "png_path" => path,
          "png_sha256" => sha256(png),
          "source_pdf_sha256" => String.duplicate("a", 64)
        }
      end)

    all_ids = Enum.map(Rendro.Catalog.catalog_specs(), & &1.id)

    controls =
      all_ids
      |> Enum.reject(&(&1 in review_ids))
      |> Enum.map(fn id -> %{"id" => id, "mode" => List.last(String.split(id, "--"))} end)

    %{
      "candidate" => %{
        "commit_sha" => String.duplicate("b", 40),
        "baseline_commit_sha" => String.duplicate("c", 40),
        "run_id" => "123",
        "run_attempt" => 1,
        "renderer" => %{"version" => "v0.11.0", "sha256" => String.duplicate("d", 64)}
      },
      "cells" =>
        Enum.map(all_ids, &Enum.find(cells ++ controls, fn cell -> cell["id"] == &1 end)),
      "diff" => %{
        "changed_targets" => @targets,
        "changed_scored" => @targets,
        "changed_unscored" => [],
        "byte_stable" => Enum.reject(all_ids, &(&1 in @targets))
      }
    }
  end

  defp final_manifest(manifest) do
    by_id = Map.new(manifest["cells"], &{&1["id"], &1})

    %{
      "candidate_sha" => get_in(manifest, ["candidate", "commit_sha"]),
      "control_sha" => get_in(manifest, ["candidate", "baseline_commit_sha"]),
      "run_id" => get_in(manifest, ["candidate", "run_id"]),
      "run_attempt" => get_in(manifest, ["candidate", "run_attempt"]),
      "renderer" => get_in(manifest, ["candidate", "renderer"]),
      "images" =>
        Enum.map(@review_roles, fn {_role, id, _kind} ->
          cell = by_id[id]

          %{
            "catalog_id" => id,
            "mode" => cell["mode"],
            "png_path" => cell["png_path"],
            "png_sha256" => cell["png_sha256"],
            "source_pdf_sha256" => cell["source_pdf_sha256"],
            "renderer_version" => "v0.11.0",
            "renderer_sha256" => String.duplicate("d", 64),
            "commit_sha" => String.duplicate("b", 40),
            "control_sha" => String.duplicate("c", 40),
            "run_id" => "123",
            "run_attempt" => 1
          }
        end)
    }
  end

  defp packet_manifest do
    images =
      Enum.with_index(@review_roles, 1)
      |> Enum.map(fn {{role, id, kind}, ordinal} ->
        %{
          "review_role" => role,
          "ordinal" => ordinal,
          "catalog_id" => id,
          "kind" => kind,
          "path" => "images/#{role}.png",
          "png_sha256" => sha256("png:" <> id),
          "source_pdf_sha256" => sha256("pdf:" <> id),
          "bundle_role" => "final-review/final.json",
          "bundle_path" => "tmp/phase130-candidate/#{id}.png"
        }
      end)

    %{
      "schema_version" => 1,
      "authority" => "none",
      "authority_statement" =>
        "Navigation and review presentation only; no evidence, review, approval, disposition, or canonical authority.",
      "candidate_sha" => String.duplicate("b", 40),
      "control_sha" => String.duplicate("c", 40),
      "run_id" => "123",
      "run_attempt" => 1,
      "renderer" => %{"version" => "v0.11.0", "sha256" => String.duplicate("d", 64)},
      "images" => images
    }
  end

  defp packet_facts do
    %{
      candidate_sha: String.duplicate("b", 40),
      control_sha: String.duplicate("c", 40),
      run_id: "123",
      run_attempt: 1,
      renderer: %{"version" => "v0.11.0", "sha256" => String.duplicate("d", 64)},
      images:
        Enum.map(packet_manifest()["images"], fn image ->
          %{
            "catalog_id" => image["catalog_id"],
            "png_path" => image["bundle_path"],
            "png_sha256" => image["png_sha256"],
            "source_pdf_sha256" => image["source_pdf_sha256"]
          }
        end)
    }
  end

  defp receipt("complete") do
    %{
      "schema_version" => 1,
      "receipt_id" => "receipt-complete-1",
      "status" => "complete",
      "candidate" => %{"sha" => String.duplicate("b", 40)},
      "control" => %{"ref" => "main", "sha" => String.duplicate("c", 40)},
      "run" => %{"id" => "123", "attempt" => 1},
      "renderer" => %{
        "version" => "v0.11.0",
        "binary_sha256" => String.duplicate("d", 64),
        "dpi" => 96
      },
      "artifacts" => artifact_pair(),
      "roles" => evidence_roles(),
      "review_images" => packet_manifest()["images"],
      "validation" => fresh_validation()
    }
  end

  defp receipt("unavailable") do
    %{
      "schema_version" => 1,
      "receipt_id" => "receipt-unavailable-1",
      "status" => "unavailable",
      "candidate" => %{"sha" => String.duplicate("b", 40)},
      "control" => %{"ref" => "main", "sha" => String.duplicate("c", 40)},
      "run" => nil,
      "renderer" => nil,
      "artifacts" => nil,
      "failure" => %{
        "stage" => "provider",
        "code" => "run_failed",
        "message" => "run unavailable",
        "expected" => %{},
        "observed" => %{},
        "next_action" => "retry exact candidate"
      },
      "targets_unpromoted" => @targets,
      "review_images" => [],
      "revision_gate" => %{
        "iteration" => 1,
        "cap" => 3,
        "status" => "retry_required",
        "prior_receipt_ids" => []
      }
    }
  end

  defp review_receipt(status) do
    reviews = Enum.map(@targets, &review_record(&1, status != "missed" or &1 != hd(@targets)))
    reviews = if status == "incomplete", do: Enum.drop(reviews, 1), else: reviews
    reviews = if status == "unavailable", do: [], else: reviews

    %{
      "schema_version" => 1,
      "review_receipt_id" => "review-#{status}-1",
      "parent_receipt_id" => "receipt-complete-1",
      "review_status" => status,
      "candidate_sha" => String.duplicate("b", 40),
      "control_sha" => String.duplicate("c", 40),
      "run_id" => "123",
      "run_attempt" => 1,
      "renderer" => %{"version" => "v0.11.0", "sha256" => String.duplicate("d", 64)},
      "artifacts" => artifact_pair(),
      "failed_target_ids" => if(status == "missed", do: [hd(@targets)], else: []),
      "missing_target_ids" =>
        if(status in ["incomplete", "unavailable"], do: [hd(@targets)], else: []),
      "reviews" => reviews,
      "failure" =>
        if(status == "unavailable",
          do: %{
            "stage" => "review",
            "code" => "reviewer_unavailable",
            "message" => "review unavailable",
            "expected" => %{},
            "observed" => %{},
            "next_action" => "retry review"
          },
          else: nil
        ),
      "revision_gate" => %{
        "iteration" => 1,
        "cap" => 3,
        "status" => if(status == "qualified", do: "not_required", else: "retry_required"),
        "prior_receipt_ids" => []
      }
    }
  end

  defp review_record(id, qualifies?) do
    %{
      "catalog_id" => id,
      "scores" => %{
        "content_hierarchy" => if(qualifies?, do: 5, else: 4),
        "layout_balance" => 4,
        "typography" => 4,
        "color_contrast" => 4,
        "content_integrity" => 4,
        "visual_cohesion" => 4
      },
      "reading_order" => true,
      "print_safety" => String.ends_with?(id, "--light"),
      "rationale" => "Independent full-size review",
      "reviewer" => "Reviewer One",
      "review_date" => "2026-08-28",
      "png_sha256" => sha256("png:" <> id),
      "source_pdf_sha256" => sha256("pdf:" <> id),
      "packet_path" => "images/#{id}.png"
    }
  end

  defp artifact_pair do
    %{
      "evidence" => %{
        "id" => "1",
        "name" => "evidence",
        "url" => "https://api.github.test/1",
        "provider_digest" => "sha256:" <> String.duplicate("e", 64),
        "archive_sha256" => String.duplicate("e", 64)
      },
      "reviewer_packet" => %{
        "id" => "2",
        "name" => "packet",
        "url" => "https://api.github.test/2",
        "provider_digest" => "sha256:" <> String.duplicate("f", 64),
        "archive_sha256" => String.duplicate("f", 64)
      }
    }
  end

  defp evidence_roles do
    for {role, count} <- [
          {"candidate/catalog.json", 32},
          {"final-review/final.json", 12},
          {"multipage-review/multipage.json", 4},
          {"preset-review/preset.json", 12}
        ] do
      %{"role" => role, "path" => role, "sha256" => sha256(role), "count" => count}
    end
  end

  defp fresh_validation do
    %{
      "control_checkout_sha" => String.duplicate("c", 40),
      "closed_bundle_result" => "ok",
      "packet_binding_result" => "ok",
      "download_nonce" => "nonce-123",
      "validated_at" => "2026-08-28T20:00:00Z",
      "evidence_archive_path" => "/tmp/nonexistent-evidence.zip",
      "packet_archive_path" => "/tmp/nonexistent-packet.zip",
      "evidence_bundle_root" => "/tmp/nonexistent-evidence",
      "packet_root" => "/tmp/nonexistent-packet"
    }
  end

  defp hash_mismatch_manifest(candidate_root) do
    manifest = manifest(candidate_root)
    index = Enum.find_index(manifest["cells"], &(&1["id"] == hd(@targets)))
    put_in(manifest, ["cells", Access.at(index), "png_sha256"], String.duplicate("f", 64))
  end

  defp sha256(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)
end
