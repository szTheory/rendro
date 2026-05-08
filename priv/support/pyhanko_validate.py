#!/usr/bin/env python3
"""Emit a narrow JSON validation payload for Rendro's pyHanko adapter."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def _status(value: bool | None, *, valid: str, invalid: str) -> str:
    if value is True:
        return valid
    if value is False:
        return invalid
    return "unknown"


def _trust(status) -> str:
    if getattr(status, "validation_path", None) is not None and getattr(
        status, "trust_problem_indic", None
    ) is None:
        return "valid"
    if getattr(status, "trust_problem_indic", None) is not None:
        return "untrusted"
    return "unknown"


def _coverage(status) -> bool:
    coverage = getattr(status, "coverage", None)
    if coverage is None:
        return False
    return str(coverage).endswith("ENTIRE_FILE") or str(coverage).endswith(
        "ENTIRE_REVISION"
    )


def _signature_kind(embedded_sig) -> str:
    kind = getattr(embedded_sig, "sig_object_type", None)
    return str(kind) if kind is not None else ""


def _document_timestamp_present(embedded_signatures) -> bool:
    return any(_signature_kind(sig).endswith("DocTimeStamp") for sig in embedded_signatures)


def _dss_revocation_presence(reader: PdfFileReader) -> bool:
    try:
        dss = DocumentSecurityStore.read_dss(reader)
    except Exception:
        return False
    return bool(getattr(dss, "ocsps", [])) or bool(getattr(dss, "crls", []))


def _compliance(timestamp: bool, revocation: bool) -> dict[str, object]:
    gaps: list[str] = []
    if not timestamp:
        gaps.append("document_timestamp")
    if not revocation:
        gaps.append("revocation_info")

    return {
        "level": "present" if not gaps else "incomplete",
        "proofs": {
            "document_timestamp": timestamp,
            "revocation_info": revocation,
        },
        "gaps": gaps,
    }


def _validation_payload(pdf_path: Path) -> dict[str, object]:
    from pyhanko.pdf_utils.reader import PdfFileReader
    from pyhanko.sign.validation import DocumentSecurityStore, validate_pdf_signature

    with pdf_path.open("rb") as handle:
        reader = PdfFileReader(handle)
        embedded_signatures = list(reader.embedded_signatures)
        if not embedded_signatures:
            raise ValueError("no signatures")

        document_timestamp = _document_timestamp_present(embedded_signatures)
        revocation_info = _dss_revocation_presence(reader)
        payloads = []

        for embedded_sig in embedded_signatures:
            if _signature_kind(embedded_sig).endswith("DocTimeStamp"):
                continue

            status = validate_pdf_signature(embedded_sig, skip_diff=True)
            payloads.append(
                {
                    "field": getattr(embedded_sig, "fq_name", None),
                    "integrity": _status(
                        bool(getattr(status, "valid", False)),
                        valid="valid",
                        invalid="invalid",
                    ),
                    "trust": _trust(status),
                    "timestamp": "present" if document_timestamp else "missing",
                    "revocation": "embedded" if revocation_info else "missing",
                    "compliance": _compliance(document_timestamp, revocation_info),
                    "total_document_signed": _coverage(status),
                }
            )

    return {"signatures": payloads}


def main() -> int:
    if len(sys.argv) != 2:
        print(json.dumps({"error": "expected_pdf_path"}))
        return 2

    try:
        payload = _validation_payload(Path(sys.argv[1]))
    except Exception:
        return 1

    print(json.dumps(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
