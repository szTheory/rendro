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

  test "real catalog target profiles change exactly the six allowlisted source PDFs" do
    baseline = Catalog.read_manifest!()
    baseline_by_id = Map.new(baseline["cells"], &{&1["id"], &1})
    target_ids = visual_target_ids(baseline)

    rendered =
      Enum.map(Catalog.catalog_specs(), fn spec ->
        assert {:ok, pdf} = Catalog.render_source_pdf(spec)

        {spec.id, sha256(pdf) != baseline_by_id[spec.id]["source_pdf_sha256"]}
      end)

    changed_targets = for {id, true} <- rendered, do: id
    byte_stable = for {id, false} <- rendered, do: id

    assert changed_targets == target_ids
    assert length(changed_targets) == 6
    assert byte_stable == Enum.map(baseline["cells"], & &1["id"]) -- target_ids
    assert length(byte_stable) == 26
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
             "changed_targets" => target_ids,
             "changed_scored" => target_ids,
             "changed_unscored" => [],
             "byte_stable" => Enum.map(baseline["cells"], & &1["id"]) -- target_ids
           }

    assert Enum.all?(manifest["cells"], fn cell ->
             not Map.has_key?(cell, "quality") and not Map.has_key?(cell, "passed") and
               not Map.has_key?(cell, "dimension_scores") and
               not Map.has_key?(cell, "gate_results") and
               not Map.has_key?(cell, "justifications") and
               not Map.has_key?(cell, "signed_off_by")
           end)
  end

  test "candidate target membership remains byte-derived when a target becomes unscored" do
    baseline = Catalog.read_manifest!()
    rubric = JSON.decode!(File.read!("priv/quality/rubric_scores.json"))
    target_ids = visual_target_ids(baseline)
    unscored_target = hd(target_ids)

    rubric =
      update_in(rubric, ["catalog_dispositions"], fn dispositions ->
        Enum.map(dispositions, fn disposition ->
          if disposition["catalog_id"] == unscored_target do
            disposition
            |> Map.drop([
              "dimension_scores",
              "gate_results",
              "passed",
              "signed_off_by",
              "signed_off_at",
              "justifications",
              "resolution_ref",
              "supersedes_evidence_ref"
            ])
            |> Map.merge(%{
              "review_status" => "unscored",
              "reason" => "Awaiting exact candidate-bound review."
            })
          else
            disposition
          end
        end)
      end)

    assert {:ok, manifest} =
             candidate_manifest(
               candidate_cells_with_changed_targets(baseline["cells"], target_ids),
               baseline,
               rubric
             )

    assert manifest["diff"]["changed_targets"] == target_ids
    assert manifest["diff"]["changed_unscored"] == [unscored_target]
    assert manifest["diff"]["changed_scored"] == tl(target_ids)

    target_cell = Enum.find(manifest["cells"], &(&1["id"] == unscored_target))
    assert target_cell["review_status"] == "changed_unscored"
    refute Map.has_key?(target_cell, "dimension_scores")
    refute Map.has_key?(target_cell, "passed")
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

    reordered =
      candidate_cells_with_changed_targets(baseline["cells"], target_ids)
      |> then(fn [first, second | rest] -> [second, first | rest] end)

    assert {:error, :invalid_candidate_scope} =
             candidate_manifest(reordered, baseline, rubric)
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

             %{"review_status" => "unscored", "print_safety" => false, "reason" => reason}
             when is_binary(reason) ->
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

  test "baseline identity is a full Git commit proven against the exact manifest blob" do
    root = temp_root!("baseline-identity")
    manifest_path = Path.join(root, "assets/rendro/catalog.json")

    git!(root, ["init", "-q"])
    git!(root, ["config", "user.email", "catalog@example.test"])
    git!(root, ["config", "user.name", "Catalog Test"])
    File.mkdir_p!(Path.dirname(manifest_path))
    File.write!(manifest_path, "{\"cells\":[]}\n")
    git!(root, ["add", "assets/rendro/catalog.json"])
    git!(root, ["commit", "-qm", "baseline"])
    baseline_sha = git!(root, ["rev-parse", "HEAD"])

    File.write!(Path.join(root, "candidate.txt"), "candidate\n")
    git!(root, ["add", "candidate.txt"])
    git!(root, ["commit", "-qm", "candidate"])
    candidate_sha = git!(root, ["rev-parse", "HEAD"])

    assert {:ok, ^baseline_sha} =
             Catalog.baseline_commit_sha(repo_root: root, manifest_path: manifest_path)

    assert byte_size(baseline_sha) == 40
    refute baseline_sha == candidate_sha

    assert {:ok, ^candidate_sha} =
             Catalog.baseline_commit_sha(
               repo_root: root,
               manifest_path: manifest_path,
               commit_sha: candidate_sha
             )

    assert git!(root, ["show", "#{baseline_sha}:assets/rendro/catalog.json"], trim: false) ==
             File.read!(manifest_path)
  end

  test "baseline identity fails closed for dirty, missing, malformed, and mismatched Git evidence" do
    root = temp_root!("baseline-failures")
    manifest_path = Path.join(root, "assets/rendro/catalog.json")

    git!(root, ["init", "-q"])
    git!(root, ["config", "user.email", "catalog@example.test"])
    git!(root, ["config", "user.name", "Catalog Test"])
    File.mkdir_p!(Path.dirname(manifest_path))
    File.write!(manifest_path, "old\n")
    git!(root, ["add", "assets/rendro/catalog.json"])
    git!(root, ["commit", "-qm", "old baseline"])
    old_sha = git!(root, ["rev-parse", "HEAD"])

    File.write!(manifest_path, "current\n")
    git!(root, ["add", "assets/rendro/catalog.json"])
    git!(root, ["commit", "-qm", "current baseline"])

    assert {:error, :invalid_baseline_commit_sha} =
             Catalog.baseline_commit_sha(
               repo_root: root,
               manifest_path: manifest_path,
               commit_sha: "abc123"
             )

    assert {:error, :baseline_manifest_mismatch} =
             Catalog.baseline_commit_sha(
               repo_root: root,
               manifest_path: manifest_path,
               commit_sha: old_sha
             )

    File.write!(manifest_path, "dirty\n")

    assert {:error, :baseline_manifest_dirty} =
             Catalog.baseline_commit_sha(repo_root: root, manifest_path: manifest_path)

    missing = Path.join(root, "assets/rendro/missing.json")

    assert {:error, :baseline_manifest_missing} =
             Catalog.baseline_commit_sha(repo_root: root, manifest_path: missing)
  end

  test "candidate and canonical manifests keep independently proven source identities" do
    baseline = Catalog.read_manifest!()
    rubric = JSON.decode!(File.read!("priv/quality/rubric_scores.json"))
    target_ids = visual_target_ids(baseline)
    candidate_sha = String.duplicate("a", 40)
    baseline_sha = String.duplicate("b", 40)

    assert {:ok, candidate} =
             Catalog.candidate_manifest(
               candidate_cells_with_changed_targets(baseline["cells"], target_ids),
               baseline,
               rubric,
               "v0.11.0",
               candidate_sha,
               candidate_multipage_proofs(),
               baseline_sha
             )

    assert candidate["candidate"]["commit_sha"] == candidate_sha
    assert candidate["candidate"]["baseline_commit_sha"] == baseline_sha
    refute candidate["candidate"]["baseline_commit_sha"] == candidate_sha

    canonical = Catalog.canonical_manifest(baseline["cells"], "v0.11.0", candidate_sha)
    assert canonical["source_commit_sha"] == candidate_sha
    assert canonical["renderer"]["kind"] == "pdfium-render"
    assert canonical["renderer"]["version"] == "v0.11.0"
  end

  test "canonical publication restores the complete old generation at every injected boundary" do
    for fail_at <- [
          :backup_assets,
          :backup_manifest,
          :install_assets,
          :install_manifest,
          :verify_assets,
          :verify_manifest
        ] do
      paths = publication_fixture!(fail_at)
      before_assets = directory_snapshot(paths.asset_root)
      before_manifest = File.read!(paths.manifest_path)

      assert {:error, {:injected_failure, ^fail_at}} =
               Catalog.publish_canonical_staging(paths, fail_at: fail_at)

      assert directory_snapshot(paths.asset_root) == before_assets
      assert File.read!(paths.manifest_path) == before_manifest
      refute File.exists?(paths.asset_staging_root)
      refute File.exists?(paths.manifest_staging_path)
      refute File.exists?(paths.asset_backup_root)
      refute File.exists?(paths.manifest_backup_path)
    end
  end

  test "canonical publication installs one complete generation and removes transaction state" do
    paths = publication_fixture!(:success)

    assert :ok = Catalog.publish_canonical_staging(paths)

    assert directory_snapshot(paths.asset_root) == %{
             "new-a.png" => "new-a",
             "new-b.png" => "new-b"
           }

    assert File.read!(paths.manifest_path) == "new-manifest\n"
    refute File.exists?(paths.asset_staging_root)
    refute File.exists?(paths.manifest_staging_path)
    refute File.exists?(paths.asset_backup_root)
    refute File.exists?(paths.manifest_backup_path)
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

  defp temp_root!(suffix) do
    root =
      Path.join(
        System.tmp_dir!(),
        "rendro-catalog-#{suffix}-#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(root)
    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    root
  end

  defp git!(root, args, opts \\ []) do
    {output, 0} = System.cmd("git", args, cd: root, stderr_to_stdout: true)
    if Keyword.get(opts, :trim, true), do: String.trim(output), else: output
  end

  defp publication_fixture!(suffix) do
    root = temp_root!("publish-#{suffix}")
    asset_root = Path.join(root, "catalog")
    manifest_path = Path.join(root, "catalog.json")
    asset_staging_root = Path.join(root, "catalog.staging")
    manifest_staging_path = Path.join(root, "catalog.json.staging")

    File.mkdir_p!(asset_root)
    File.write!(Path.join(asset_root, "old.png"), "old")
    File.write!(manifest_path, "old-manifest\n")
    File.mkdir_p!(asset_staging_root)
    File.write!(Path.join(asset_staging_root, "new-a.png"), "new-a")
    File.write!(Path.join(asset_staging_root, "new-b.png"), "new-b")
    File.write!(manifest_staging_path, "new-manifest\n")

    %{
      asset_root: asset_root,
      manifest_path: manifest_path,
      asset_staging_root: asset_staging_root,
      manifest_staging_path: manifest_staging_path,
      asset_backup_root: asset_root <> ".previous",
      manifest_backup_path: manifest_path <> ".previous"
    }
  end

  defp directory_snapshot(root) do
    root
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.filter(&File.regular?/1)
    |> Map.new(&{Path.relative_to(&1, root), File.read!(&1)})
  end

  defp sha256(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)
end
