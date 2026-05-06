defmodule Rendro.DocsContract.EmbeddedArtifactClaimsTest do
  use ExUnit.Case, async: true

  # Phase 50: family-first nested support matrix with per-surface, per-viewer
  # promotions driven exclusively by recorded manual evidence in `50-VALIDATION.md`.
  # Any viewer/surface pair without complete passing evidence stays `unverified`.

  test "support matrix exposes the nested embedded_files contract with proof-backed viewer statuses" do
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

    # Adobe Acrobat Reader passed all three behaviors (discoverable, open_or_extract,
    # save_or_extract) per `50-VALIDATION.md` 2026-05-06 entry → promoted to `supported`.
    assert matrix =~
             ~r/"embedded_files".*?"viewers".*?"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"supported"/s

    # Apple Preview did not surface the embedded file in its UI under the version
    # checked → stays `unverified` per D-08. Not `unsupported` (D-09): Rendro authors
    # the surface correctly per the structural lane; the gap is on the viewer side.
    assert matrix =~
             ~r/"embedded_files".*?"viewers".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

    assert matrix =~ ~s|"discoverable"|
    assert matrix =~ ~s|"open_or_extract"|
    assert matrix =~ ~s|"save_or_extract"|

    # No generic `"surfaces"` wrapper.
    refute matrix =~ ~s|"surfaces"|

    # Independent per-surface, per-viewer status: a links pass for Apple Preview
    # must not infer an embedded_files pass. The assertion above already pins
    # apple_preview embedded_files at "unverified".
  end

  test "support matrix exposes the nested links contract with proof-backed viewer statuses" do
    matrix = File.read!("priv/support_matrix.json")

    assert matrix =~ ~s|"links"|
    assert matrix =~ ~s|"targets"|

    # Authored target/behavior leaves use simple scalar statuses.
    assert matrix =~ ~s|"external_uri_http_https": "supported"|
    assert matrix =~ ~s|"internal_page": "supported"|
    assert matrix =~ ~s|"fragment_rectangles": "supported"|
    assert matrix =~ ~s|"named_destinations": "unsupported"|

    # Both viewers passed external_uri_handoff and internal_page_navigation per
    # `50-VALIDATION.md` 2026-05-06 entry → both promoted to `supported`.
    assert matrix =~
             ~r/"links".*?"viewers".*?"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"supported"/s

    assert matrix =~
             ~r/"links".*?"viewers".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"supported"/s

    assert matrix =~ ~s|"external_uri_handoff"|
    assert matrix =~ ~s|"internal_page_navigation"|

    # No leakage: the links promotion for Apple Preview MUST NOT silently widen
    # to embedded_files (covered by the embedded_files test above).
  end

  test "public embedded files wording matches the recorded viewer evidence" do
    guide = File.read!("guides/api_stability.md")

    # Canonical public wording per D-15..D-18.
    assert guide =~ "Rendro supports document-level embedded files with explicit metadata."

    assert guide =~
             "Rendro supports authored links for external `http`/`https` URIs and internal page destinations."

    # Distinguish PDF-internal embedded files from delivery attachments.
    assert guide =~
             "Embedded files live inside the PDF binary and are distinct from delivery, email, or download attachments handled by Rendro adapters outside the PDF."

    # Structural-vs-viewer separation remains stated in docs prose.
    assert guide =~
             "Structural validation through `pdfinfo`/Poppler proves PDF structure only. It does not prove viewer behavior for embedded files or links."

    # Post-proof per-surface, per-viewer wording. Adobe Reader is supported for
    # both surfaces; Apple Preview is supported for links only; Apple Preview
    # remains unverified for embedded files.
    assert guide =~
             "Adobe Acrobat Reader is `supported` for both `embedded_files` and `links`."

    assert guide =~
             "Apple Preview is `supported` for `links` and `unverified` for `embedded_files`."

    # Refute broad/blanket viewer language and over-broad scheme/destination claims.
    refute guide =~ "standard PDF viewers"
    refute guide =~ ~r/v1\.9 viewer/i
    refute guide =~ "all PDF viewers"
    refute guide =~ "Rendro supports named destinations"
    refute guide =~ "Rendro supports page attachment annotations"

    # Refute the pre-proof "everything stays unverified" sentence — that wording
    # was correct after Plan 01 but is now inaccurate; keeping it would publish
    # a contract that contradicts the recorded evidence.
    refute guide =~
             "All `embedded_files` and `links` viewer statuses remain `unverified` in `priv/support_matrix.json` until a recorded checklist promotes a named viewer."
  end

  test "the canonical docs verification script includes the embedded artifact claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Embedded artifact semantic-claims lane", ["test", "test/docs_contract/embedded_artifact_claims_test.exs"]}|

    # Existing lanes must remain present.
    assert script =~
             ~s|{"README doctest lane", ["test", "test/docs_contract/readme_doctest_test.exs"]}|

    assert script =~
             ~s|{"Integration contract lane", ["test", "test/docs_contract/integrations_contract_test.exs"]}|

    assert script =~
             ~s|{"Integration semantic-claims lane", ["test", "test/docs_contract/integrations_claims_test.exs"]}|

    assert script =~
             ~s|{"Forms semantic-claims lane", ["test", "test/docs_contract/forms_claims_test.exs"]}|
  end
end
