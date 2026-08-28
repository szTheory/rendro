defmodule Rendro.CatalogTest do
  use ExUnit.Case, async: true

  alias Rendro.Catalog
  alias Rendro.Test.EdgeFixtures

  test "the default invoice catalog entry is a truthful deterministic source PDF" do
    spec = Enum.find(Catalog.catalog_specs(), &(&1.id == "invoice--default--default--light"))

    assert spec.id == "invoice--default--default--light"
    assert spec.fixture_ref == "invoice/acme-phoenix-saas/invoice.json"
    assert spec.brand == nil
    assert spec.preset == nil
    assert spec.accent == nil
    assert spec.theme == "default"
    assert spec.mode == "light"

    assert {:ok, first} = Catalog.render_source_pdf(spec)
    assert {:ok, second} = Catalog.render_source_pdf(spec)
    assert first == second
    assert byte_size(first) > 0
    assert first =~ "%PDF-"
  end

  test "closed catalog modes render without runtime atom conversion" do
    for id <- [
          "invoice--northline-logistics--swiss--light",
          "invoice--northline-logistics--swiss--dark"
        ] do
      spec = Enum.find(Catalog.catalog_specs(), &(&1.id == id))
      assert {:ok, pdf} = Catalog.render_source_pdf(spec)
      assert pdf =~ "%PDF-"
    end
  end

  test "the dev-only visual target map contains only the six ordered target IDs" do
    source = File.read!("dev/rendro/catalog.ex")

    expected_ids = [
      "invoice--cedar-mutual--corporate-classic--dark",
      "statement--signal-ledger--minimal-mono--dark",
      "payslip--northline-logistics--swiss--light",
      "payslip--northline-logistics--swiss--dark",
      "ticket--aurora-live--brutalist--light",
      "ticket--aurora-live--brutalist--dark"
    ]

    assert source =~ "@visual_target_profiles"

    assert Enum.map(expected_ids, &(String.split(source, &1, parts: 2) |> hd() |> byte_size())) ==
             Enum.sort(
               Enum.map(
                 expected_ids,
                 &(String.split(source, &1, parts: 2) |> hd() |> byte_size())
               )
             )

    assert Enum.all?(expected_ids, &String.contains?(source, &1))
    assert length(Regex.scan(~r/--(?:dark|light)"\s*=>\s*%\{/, source)) == 6
    assert source =~ "Map.get(@visual_target_profiles, spec.id)"
  end

  test "only the Corporate Classic Invoice dark catalog render receives generic semantic ink" do
    target =
      Enum.find(
        Catalog.catalog_specs(),
        &(&1.id == "invoice--cedar-mutual--corporate-classic--dark")
      )

    control =
      Enum.find(
        Catalog.catalog_specs(),
        &(&1.id == "invoice--cedar-mutual--corporate-classic--light")
      )

    target_doc = Catalog.source_document_for(target)
    control_doc = Catalog.source_document_for(control)

    assert inspect(target_doc, limit: :infinity, printable_limit: :infinity) =~ "Date:"
    assert inspect(control_doc, limit: :infinity, printable_limit: :infinity) =~ "Date:"

    assert {:ok, first} = Catalog.render_source_pdf(target)
    assert {:ok, second} = Catalog.render_source_pdf(target)
    assert first == second
  end

  test "catalog identity literals remain outside core recipes" do
    recipe_sources =
      Path.wildcard("lib/rendro/recipes/*.ex")
      |> Enum.map(&File.read!/1)
      |> Enum.join("\n")

    for id <- [
          "invoice--cedar-mutual--corporate-classic--dark",
          "statement--signal-ledger--minimal-mono--dark",
          "payslip--northline-logistics--swiss--light",
          "payslip--northline-logistics--swiss--dark",
          "ticket--aurora-live--brutalist--light",
          "ticket--aurora-live--brutalist--dark"
        ] do
      refute recipe_sources =~ id
    end
  end

  test "catalog paths reject traversal before I/O" do
    assert_raise ArgumentError, ~r/unsafe catalog/, fn ->
      Catalog.source_document_for(%{
        id: "invoice--default--default--light",
        fixture_ref: "../secret.json"
      })
    end
  end

  test "candidate generation fails closed and removes only its fixed temporary root" do
    candidate_root = "tmp/phase130-candidate"
    staging_root = "tmp/phase130-candidate.staging"
    File.mkdir_p!(candidate_root)
    File.write!(Path.join(candidate_root, "sentinel"), "candidate-only")

    assert {:error, _reason} = Catalog.generate_candidate(pdfium: "/not/a/pdfium-cli")
    refute File.exists?(candidate_root)
    refute File.exists?(staging_root)
  end

  test "failed canonical generation leaves committed catalog and reviewer-owned evidence untouched" do
    tracked_paths = [
      "assets/rendro/catalog.json",
      "priv/quality/rubric_scores.json",
      "priv/quality/SIGN-OFF.md"
    ]

    before = Map.new(tracked_paths, &{&1, File.read!(&1)})

    assert {:error, _reason} = Catalog.generate(pdfium: "/not/a/pdfium-cli")

    assert before == Map.new(tracked_paths, &{&1, File.read!(&1)})
    refute File.exists?("assets/rendro/catalog.staging")
    refute File.exists?("assets/rendro/catalog.json.staging")
  end

  test "candidate manifest permits exactly the ordered six target changes without reviewer judgment" do
    baseline = Catalog.read_manifest!()
    rubric = JSON.decode!(File.read!("priv/quality/rubric_scores.json"))
    target_ids = visual_target_ids(baseline)
    candidate_cells = candidate_cells_with_changed_targets(baseline["cells"], target_ids)

    assert {:ok, manifest} =
             Catalog.candidate_manifest(
               candidate_cells,
               baseline,
               rubric,
               "v0.11.0",
               String.duplicate("a", 40),
               candidate_multipage_proofs()
             )

    assert manifest["diff"] == %{
             "changed_scored" => target_ids,
             "changed_unscored" => [],
             "byte_stable" => Enum.map(baseline["cells"], & &1["id"]) -- target_ids
           }

    assert Enum.all?(manifest["cells"], fn cell ->
             not Map.has_key?(cell, "quality") and not Map.has_key?(cell, "passed") and
               not Map.has_key?(cell, "dimension_scores")
           end)
  end

  test "candidate manifest rejects missing targets and either changed control hash" do
    baseline = Catalog.read_manifest!()
    rubric = JSON.decode!(File.read!("priv/quality/rubric_scores.json"))
    target_ids = visual_target_ids(baseline)

    missing_target =
      candidate_cells_with_changed_targets(baseline["cells"], Enum.drop(target_ids, 1))

    assert {:error, :invalid_candidate_scope} =
             candidate_manifest(missing_target, baseline, rubric)

    [control | _] = Enum.reject(baseline["cells"], &(&1["id"] in target_ids))

    changed_control_pdf =
      candidate_cells_with_changed_targets(baseline["cells"], target_ids)
      |> Enum.map(fn cell ->
        if cell["id"] == control["id"],
          do: %{cell | "source_pdf_sha256" => String.duplicate("f", 64)},
          else: cell
      end)

    assert {:error, :invalid_candidate_scope} =
             candidate_manifest(changed_control_pdf, baseline, rubric)

    changed_control_png =
      candidate_cells_with_changed_targets(baseline["cells"], target_ids)
      |> Enum.map(fn cell ->
        if cell["id"] == control["id"],
          do: %{cell | "png_sha256" => String.duplicate("e", 64)},
          else: cell
      end)

    assert {:error, :invalid_candidate_scope} =
             candidate_manifest(changed_control_png, baseline, rubric)
  end

  test "catalog dispositions remain explicit 32-cell, 20-unscored dark screen-only records" do
    manifest = Catalog.read_manifest!()
    rubric = JSON.decode!(File.read!("priv/quality/rubric_scores.json"))
    dispositions = rubric["catalog_dispositions"]

    assert is_integer(length(manifest["cells"]))
    assert length(manifest["cells"]) == 32
    assert is_integer(length(Enum.filter(dispositions, &(&1["review_status"] == "unscored"))))
    assert Enum.count(dispositions, &(&1["review_status"] == "unscored")) == 20

    assert Enum.all?(dispositions, fn disposition ->
             disposition["review_status"] in ["scored", "unscored"]
           end)

    dark_dispositions = Enum.filter(dispositions, &(&1["mode"] == "dark"))

    assert Enum.all?(dark_dispositions, fn
             %{"review_status" => "scored", "gate_results" => %{"print_safety" => false}} ->
               true

             %{"review_status" => "unscored", "reason" => reason} when is_binary(reason) ->
               true

             _ ->
               false
           end)
  end

  test "candidate generation includes the separate four-image multipage proof collection" do
    source = File.read!("dev/rendro/catalog.ex")

    assert source =~ "build_multipage_proofs"
    assert source =~ "\"multipage\" => multipage"
    assert source =~ "invoice-line-items-60-plus-page-first"
    assert source =~ "statement-line-items-60-plus-page-final"
  end

  test "the literal registry is the locked ordered 32-cell catalog" do
    expected_ids = ~w(
      invoice--default--default--light invoice--northline-logistics--swiss--light invoice--northline-logistics--swiss--dark invoice--cedar-mutual--corporate-classic--light invoice--cedar-mutual--corporate-classic--dark
      statement--default--default--light statement--signal-ledger--minimal-mono--light statement--signal-ledger--minimal-mono--dark statement--aster-research-fund--editorial--light statement--aster-research-fund--editorial--dark
      receipt--default--default--light receipt--poppy-and-grain--humanist--light receipt--poppy-and-grain--humanist--dark receipt--circuit-supply-co--minimal-mono--light receipt--circuit-supply-co--minimal-mono--dark
      certificate--default--default--light certificate--aster-institute--swiss--light certificate--aster-institute--swiss--dark certificate--meridian-arts-fellowship--editorial--light certificate--meridian-arts-fellowship--editorial--dark
      payslip--default--default--light payslip--northline-logistics--swiss--light payslip--northline-logistics--swiss--dark payslip--cedar-mutual--corporate-classic--light payslip--cedar-mutual--corporate-classic--dark
      ticket--default--default--light ticket--field-notes-conference--minimal-mono--light ticket--field-notes-conference--minimal-mono--dark ticket--the-letterpress-hall--editorial--light ticket--the-letterpress-hall--editorial--dark ticket--aurora-live--brutalist--light ticket--aurora-live--brutalist--dark
    )

    specs = Catalog.catalog_specs()
    assert Enum.map(specs, & &1.id) == expected_ids
    assert length(specs) == 32
    assert Catalog.catalog_contract_errors(specs) == []
    assert Enum.uniq(Enum.map(specs, & &1.png_path)) |> length() == 32

    assert Enum.any?(
             Catalog.catalog_contract_errors(Enum.take(specs, 31)),
             &String.contains?(&1, "exactly 32")
           )

    errors = Catalog.catalog_contract_errors(specs ++ [List.last(specs)])
    assert Enum.any?(errors, &String.contains?(&1, "exactly 32"))
    assert Enum.any?(errors, &String.contains?(&1, "ceiling"))

    aurora = Enum.find(specs, &(&1.id == "ticket--aurora-live--brutalist--light"))
    assert aurora.brand == "aurora-live"
    assert aurora.preset == "brutalist"
    assert aurora.accent == "#C78600"
  end

  test "static catalog checks are read-only against the committed manifest" do
    before = File.read!(__ENV__.file)
    assert Catalog.static_contract_errors() == []
    assert File.read!(__ENV__.file) == before
  end

  test "page count excludes the PDF Pages tree and recognizes multiple physical pages" do
    spec = Enum.find(Catalog.catalog_specs(), &(&1.id == "invoice--default--default--light"))
    assert {:ok, single_page_pdf} = Catalog.render_source_pdf(spec)
    assert Catalog.page_count(single_page_pdf) == 1

    multi_page_document = EdgeFixtures.document(:invoice, :line_items_60_plus)
    assert {:ok, multi_page_pdf} = Rendro.render(multi_page_document, deterministic: true)
    assert Catalog.page_count(multi_page_pdf) > 1
  end

  test "artifact checks fail for missing files and hash drift without rasterizing PDFs" do
    manifest = Catalog.read_manifest!()
    assert Catalog.artifact_contract_errors(manifest) == []

    [first | rest] = manifest["cells"]

    hash_drift =
      put_in(manifest, ["cells"], [%{first | "png_sha256" => String.duplicate("0", 64)} | rest])

    assert Catalog.artifact_contract_errors(hash_drift)
           |> Enum.any?(&String.contains?(&1, "#{first["id"]}: PNG hash drift"))

    missing =
      put_in(manifest, ["cells"], [
        %{first | "png_path" => "assets/rendro/catalog/missing.png"} | rest
      ])

    assert Catalog.artifact_contract_errors(missing)
           |> Enum.any?(&String.contains?(&1, "#{first["id"]}: PNG missing"))
  end

  test "required catalog check invokes artifact validation for every committed PNG guard" do
    manifest = Catalog.read_manifest!()
    [first | rest] = manifest["cells"]

    assert_check_error(
      put_in(manifest, ["cells"], [
        %{first | "png_path" => "assets/rendro/catalog/missing.png"} | rest
      ]),
      "#{first["id"]}: PNG missing"
    )

    assert_check_error(
      put_in(manifest, ["cells"], [%{first | "png_sha256" => String.duplicate("0", 64)} | rest]),
      "#{first["id"]}: PNG hash drift"
    )

    assert_check_error(
      put_in(manifest, ["cells"], [%{first | "width_px" => first["width_px"] + 1} | rest]),
      "#{first["id"]}: PNG width drift"
    )

    assert_check_error(
      put_in(manifest, ["cells"], [%{first | "height_px" => first["height_px"] + 1} | rest]),
      "#{first["id"]}: PNG height drift"
    )
  end

  test "required catalog check rejects passed catalog dispositions without closure evidence" do
    manifest = Catalog.read_manifest!()
    rubric = JSON.decode!(File.read!("priv/quality/rubric_scores.json"))
    promoted = passing_disposition(rubric)

    promoted_manifest =
      put_in(
        manifest,
        ["cells"],
        Enum.map(manifest["cells"], fn cell ->
          if cell["id"] == promoted["catalog_id"] do
            Map.put(cell, "quality", %{
              "status" => "passes",
              "label" => "Scored — passes current rubric"
            })
          else
            cell
          end
        end)
      )

    for {field, expected_error} <- [
          {"supersedes_evidence_ref", "concrete prior or superseded evidence reference"},
          {"resolution_ref", "non-empty behavioral resolution_ref"}
        ] do
      mutated_rubric =
        put_in(
          rubric,
          ["catalog_dispositions"],
          replace_disposition(rubric["catalog_dispositions"], Map.delete(promoted, field))
        )

      assert {:error, errors} = Catalog.check(manifest: promoted_manifest, rubric: mutated_rubric)
      assert Enum.any?(errors, &String.contains?(&1, expected_error))
    end
  end

  defp assert_check_error(manifest, expected_error) do
    assert {:error, errors} = Catalog.check(manifest: manifest, rubric: rebind_rubric(manifest))
    assert Enum.any?(errors, &String.contains?(&1, expected_error))
  end

  defp rebind_rubric(manifest) do
    [first | _] = manifest["cells"]
    rubric = JSON.decode!(File.read!("priv/quality/rubric_scores.json"))

    dispositions =
      Enum.map(rubric["catalog_dispositions"], fn disposition ->
        if disposition["catalog_id"] == first["id"] do
          Map.merge(disposition, %{
            "evidence_ref" => first["png_path"],
            "png_sha256" => first["png_sha256"],
            "source_pdf_sha256" => first["source_pdf_sha256"]
          })
        else
          disposition
        end
      end)

    %{rubric | "catalog_dispositions" => dispositions}
  end

  defp passing_disposition(rubric) do
    rubric["catalog_dispositions"]
    |> Enum.find(&(&1["review_status"] == "scored"))
    |> Map.merge(%{
      "dimension_scores" => %{
        "information_architecture" => 5,
        "content_hierarchy" => 5,
        "domain_fit" => 5,
        "reader_affordances" => 5,
        "typographic_craft" => 5,
        "restraint_cohesion" => 5
      },
      "gate_results" => %{"reading_order" => true, "print_safety" => true},
      "passed" => true,
      "supersedes_evidence_ref" => "priv/quality/rubric_scores.json#catalog-dispositions",
      "resolution_ref" => "priv/quality/rubric_scores.json#catalog-dispositions"
    })
  end

  defp replace_disposition(dispositions, replacement) do
    Enum.map(dispositions, fn disposition ->
      if disposition["catalog_id"] == replacement["catalog_id"],
        do: replacement,
        else: disposition
    end)
  end

  defp candidate_multipage_proofs do
    for {family, page} <- [
          {"invoice", "first"},
          {"invoice", "final"},
          {"statement", "first"},
          {"statement", "final"}
        ] do
      %{
        "id" => "#{family}-line-items-60-plus-page-#{page}",
        "family" => family,
        "page" => page,
        "png_path" => "tmp/phase130-candidate/multipage/#{family}-#{page}.png",
        "png_sha256" => String.duplicate("d", 64),
        "source_pdf_sha256" => String.duplicate("e", 64)
      }
    end
  end

  defp candidate_manifest(cells, baseline, rubric) do
    Catalog.candidate_manifest(
      cells,
      baseline,
      rubric,
      "v0.11.0",
      String.duplicate("a", 40),
      candidate_multipage_proofs()
    )
  end

  defp candidate_cells_with_changed_targets(cells, target_ids) do
    Enum.map(cells, fn cell ->
      cell = %{
        cell
        | "png_path" =>
            String.replace(cell["png_path"], "assets/rendro", "tmp/phase130-candidate")
      }

      if cell["id"] in target_ids do
        %{
          cell
          | "png_sha256" => String.duplicate("c", 64),
            "source_pdf_sha256" => String.duplicate("d", 64)
        }
      else
        cell
      end
    end)
  end

  defp visual_target_ids(%{"cells" => cells}) do
    cells
    |> Enum.map(& &1["id"])
    |> Enum.filter(
      &(&1 in [
          "invoice--cedar-mutual--corporate-classic--dark",
          "statement--signal-ledger--minimal-mono--dark",
          "payslip--northline-logistics--swiss--light",
          "payslip--northline-logistics--swiss--dark",
          "ticket--aurora-live--brutalist--light",
          "ticket--aurora-live--brutalist--dark"
        ])
    )
  end
end
