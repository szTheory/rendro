defmodule Rendro.DocsContract.EmbeddedArtifactClaimsTest do
  use ExUnit.Case, async: true

  # Phase 50 Plan 01: family-first nested support matrix.
  # `embedded_files` and `links` are siblings of the existing `forms` family —
  # NOT wrapped in a generic `"surfaces"` key, NOT given BCD-style per-leaf
  # statement objects, and NOT promoted to "supported" for any viewer until
  # Plan 03 records manual evidence in `50-VALIDATION.md`.

  test "support matrix exposes the nested embedded_files contract with provisional viewer statuses" do
    matrix = File.read!("priv/support_matrix.json")

    # Family is a top-level sibling of `forms`, not wrapped in `"surfaces"`.
    assert matrix =~ ~s|"embedded_files"|
    assert matrix =~ ~s|"capabilities"|

    # Authored capability/behavior leaves use simple scalar statuses.
    assert matrix =~ ~s|"document_level": "supported"|
    assert matrix =~ ~s|"explicit_metadata": "supported"|
    assert matrix =~ ~s|"authored_timestamps": "supported"|
    assert matrix =~ ~s|"page_attachment_annotations": "unsupported"|

    # Existing `forms` family must remain unchanged at the top level.
    assert matrix =~ ~s|"forms"|
    assert matrix =~ ~s|"text": "supported"|
    assert matrix =~ ~s|"checkbox": "supported"|
    assert matrix =~ ~s|"radio": "supported"|
    assert matrix =~ ~s|"signature": "unsupported"|

    # Existing validators block must remain unchanged.
    assert matrix =~ ~s|"validators"|
    assert matrix =~ ~s|"pdfinfo"|

    # Per-surface viewer entries with proof checklist for embedded files.
    assert matrix =~
             ~r/"embedded_files".*?"viewers".*?"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

    assert matrix =~
             ~r/"embedded_files".*?"viewers".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

    assert matrix =~ ~s|"discoverable"|
    assert matrix =~ ~s|"open_or_extract"|
    assert matrix =~ ~s|"save_or_extract"|

    # No generic `"surfaces"` wrapper; no premature `supported` for new viewers.
    refute matrix =~ ~s|"surfaces"|

    refute matrix =~
             ~r/"embedded_files".*?"viewers".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"supported"/s

    refute matrix =~
             ~r/"embedded_files".*?"viewers".*?"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"supported"/s
  end

  test "support matrix exposes the nested links contract with provisional viewer statuses" do
    matrix = File.read!("priv/support_matrix.json")

    assert matrix =~ ~s|"links"|
    assert matrix =~ ~s|"targets"|

    # Authored target/behavior leaves use simple scalar statuses.
    assert matrix =~ ~s|"external_uri_http_https": "supported"|
    assert matrix =~ ~s|"internal_page": "supported"|
    assert matrix =~ ~s|"fragment_rectangles": "supported"|
    assert matrix =~ ~s|"named_destinations": "unsupported"|

    # Per-surface viewer entries with proof checklist for links.
    assert matrix =~
             ~r/"links".*?"viewers".*?"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

    assert matrix =~
             ~r/"links".*?"viewers".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

    assert matrix =~ ~s|"external_uri_handoff"|
    assert matrix =~ ~s|"internal_page_navigation"|

    # Refute premature promotion to "supported" for either named viewer.
    refute matrix =~
             ~r/"links".*?"viewers".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"supported"/s

    refute matrix =~
             ~r/"links".*?"viewers".*?"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"supported"/s
  end

  test "public embedded files wording stays narrow and matches the provisional matrix posture" do
    guide = File.read!("guides/api_stability.md")

    # Canonical public wording per D-15..D-18.
    assert guide =~ "Rendro supports document-level embedded files with explicit metadata."

    assert guide =~
             "Rendro supports authored links for external `http`/`https` URIs and internal page destinations."

    # Distinguish PDF-internal embedded files from delivery attachments.
    assert guide =~
             "Embedded files live inside the PDF binary and are distinct from delivery, email, or download attachments handled by Rendro adapters outside the PDF."

    # Structural-vs-viewer separation, reused from forms wording but stated again
    # for the new artifact surfaces so the boundary is unambiguous in docs.
    assert guide =~
             "Structural validation through `pdfinfo`/Poppler proves PDF structure only. It does not prove viewer behavior for embedded files or links."

    # Viewer claims for the new families remain unverified until Plan 03 records evidence.
    assert guide =~
             "All `embedded_files` and `links` viewer statuses remain `unverified` in `priv/support_matrix.json` until a recorded checklist promotes a named viewer."

    # Refute broad/blanket viewer language and over-broad scheme/destination claims.
    refute guide =~ "standard PDF viewers"
    refute guide =~ ~r/v1\.9 viewer/i
    refute guide =~ "all PDF viewers"
    refute guide =~ "Rendro supports named destinations"
    refute guide =~ "Rendro supports page attachment annotations"
  end

  test "the canonical docs verification script includes the embedded artifact claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Embedded artifact semantic-claims lane", ["test", "test/docs_contract/embedded_artifact_claims_test.exs"]}|

    # Existing lanes must remain present.
    assert script =~ ~s|{"README doctest lane", ["test", "test/docs_contract/readme_doctest_test.exs"]}|
    assert script =~ ~s|{"Integration contract lane", ["test", "test/docs_contract/integrations_contract_test.exs"]}|
    assert script =~ ~s|{"Integration semantic-claims lane", ["test", "test/docs_contract/integrations_claims_test.exs"]}|
    assert script =~ ~s|{"Forms semantic-claims lane", ["test", "test/docs_contract/forms_claims_test.exs"]}|
  end
end
