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
end
