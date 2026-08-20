defmodule Rendro.CatalogReviewPayloadContractTest do
  use ExUnit.Case, async: true

  alias Rendro.CatalogReviewPayload

  @ids [
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

  test "classifies one complete candidate manifest into final and separate multipage payloads" do
    manifest = candidate_manifest()
    proofs = multipage_proofs()

    assert {:ok, %{final: final, multipage: multipage}} =
             CatalogReviewPayload.classify(manifest, proofs)

    assert Enum.map(final, & &1["catalog_id"]) == @ids

    assert Enum.map(multipage, & &1["id"]) ==
             [
               "invoice-line-items-60-plus-page-first",
               "invoice-line-items-60-plus-page-final",
               "statement-line-items-60-plus-page-first",
               "statement-line-items-60-plus-page-final"
             ]

    assert Enum.all?(final, fn identity ->
             Enum.all?(
               ~w(catalog_id mode png_path png_sha256 source_pdf_sha256 renderer_version renderer_sha256 commit_sha run_id),
               &Map.has_key?(identity, &1)
             )
           end)

    refute Enum.any?(
             final ++ multipage,
             &(Map.has_key?(&1, "quality") or Map.has_key?(&1, "scores"))
           )

    assert manifest == candidate_manifest()
    assert proofs == multipage_proofs()
  end

  test "fails closed for incomplete, stale, reordered, or quality-bearing candidate identities" do
    manifest = candidate_manifest()

    invalid_manifests = [
      Map.update!(manifest, "cells", &List.replace_at(&1, 1, hd(&1))),
      Map.update!(manifest, "cells", &Enum.drop(&1, 1)),
      Map.update!(manifest, "cells", &(&1 ++ [hd(&1)])),
      Map.update!(manifest, "cells", &Enum.reverse/1),
      put_in(manifest, ["cells", Access.at(0), "mode"], "dark"),
      put_in(manifest, ["cells", Access.at(0), "png_path"], "../canonical.png"),
      put_in(manifest, ["cells", Access.at(0), "renderer_sha256"], String.duplicate("f", 64)),
      put_in(manifest, ["cells", Access.at(0), "source_pdf_sha256"], "not-a-sha"),
      put_in(manifest, ["candidate", "commit_sha"], "short"),
      put_in(manifest, ["candidate", "run_id"], " "),
      put_in(manifest, ["cells", Access.at(0), "quality"], %{"status" => "passed"}),
      put_in(manifest, ["candidate", "scores"], %{"content_hierarchy" => 5})
    ]

    for invalid <- invalid_manifests do
      assert {:error, _reason} = CatalogReviewPayload.classify(invalid, multipage_proofs())
    end

    assert {:error, _reason} =
             CatalogReviewPayload.classify(Map.delete(manifest, "candidate"), multipage_proofs())
  end

  test "fails closed for malformed, missing, extra, or unsafe multipage proof entries" do
    proofs = multipage_proofs()

    invalid_proofs = [
      Enum.drop(proofs, 1),
      proofs ++ [hd(proofs)],
      Enum.reverse(proofs),
      put_in(proofs, [Access.at(0), "png_path"], "/tmp/unsafe.png"),
      put_in(proofs, [Access.at(0), "png_sha256"], "not-a-sha"),
      put_in(proofs, [Access.at(0), "quality"], %{"status" => "passed"})
    ]

    for invalid <- invalid_proofs do
      assert {:error, _reason} = CatalogReviewPayload.classify(candidate_manifest(), invalid)
    end
  end

  defp candidate_manifest do
    %{
      "candidate" => %{
        "commit_sha" => String.duplicate("a", 40),
        "run_id" => "130-03-contract-run",
        "renderer" => %{
          "version" => "v0.11.0",
          "sha256" => String.duplicate("b", 64)
        }
      },
      "cells" =>
        Enum.map(@ids, fn id ->
          [family, _brand, _preset, mode] = String.split(id, "--")

          %{
            "id" => id,
            "family" => family,
            "mode" => mode,
            "page" => 1,
            "png_path" => "tmp/phase130-candidate/png/#{id}.png",
            "png_sha256" => String.duplicate("c", 64),
            "source_pdf_sha256" => String.duplicate("d", 64),
            "renderer_version" => "v0.11.0",
            "renderer_sha256" => String.duplicate("b", 64)
          }
        end)
    }
  end

  defp multipage_proofs do
    for {family, page} <- [
          invoice: "first",
          invoice: "final",
          statement: "first",
          statement: "final"
        ] do
      %{
        "id" => "#{family}-line-items-60-plus-page-#{page}",
        "family" => Atom.to_string(family),
        "page" => page,
        "png_path" => "tmp/phase130-candidate/multipage/#{family}-#{page}.png",
        "png_sha256" => String.duplicate("e", 64),
        "source_pdf_sha256" => String.duplicate("f", 64)
      }
    end
  end
end
