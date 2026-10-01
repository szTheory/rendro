#!/usr/bin/env python3
"""Validate the closed source-PDF archive used by Phase 136 Plan 58."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import stat
import tempfile
import zipfile
from pathlib import Path, PurePosixPath
from typing import Any


PHASE_DIR = Path(__file__).resolve().parent
CANDIDATE_SHA = "82c1a40f5d0bb432ec8b465af2c5232ea7fa4c8c"
HISTORICAL_RUN_ID = "33223247569"
TARGETS = (
    (
        "invoice--cedar-mutual--corporate-classic--dark",
        "tmp/phase130-candidate/invoice/cedar-mutual/corporate-classic-dark.pdf",
    ),
    (
        "statement--signal-ledger--minimal-mono--dark",
        "tmp/phase130-candidate/statement/signal-ledger/minimal-mono-dark.pdf",
    ),
    (
        "payslip--northline-logistics--swiss--light",
        "tmp/phase130-candidate/payslip/northline-logistics/swiss-light.pdf",
    ),
    (
        "payslip--northline-logistics--swiss--dark",
        "tmp/phase130-candidate/payslip/northline-logistics/swiss-dark.pdf",
    ),
    (
        "ticket--aurora-live--brutalist--light",
        "tmp/phase130-candidate/ticket/aurora-live/brutalist-light.pdf",
    ),
    (
        "ticket--aurora-live--brutalist--dark",
        "tmp/phase130-candidate/ticket/aurora-live/brutalist-dark.pdf",
    ),
)
MAX_PDF_BYTES = 10 * 1024 * 1024
MAX_TOTAL_BYTES = 40 * 1024 * 1024
SHA40 = re.compile(r"^[0-9a-f]{40}$")
SHA64 = re.compile(r"^[0-9a-f]{64}$")


class InvalidSourceArchive(ValueError):
    """The archive or its run metadata failed a closed-contract check."""


def reject_duplicate_json_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise InvalidSourceArchive(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def safe_member_name(name: str) -> bool:
    path = PurePosixPath(name)
    return (
        bool(name)
        and "\\" not in name
        and not name.startswith("/")
        and path.as_posix() == name
        and all(part not in ("", ".", "..") for part in path.parts)
        and not (path.parts and re.match(r"^[A-Za-z]:", path.parts[0]))
    )


def validate_archive(
    archive_path: Path,
    *,
    expected_identity: dict[str, Any],
    targets: tuple[tuple[str, str], ...] = TARGETS,
    candidate_manifest: Path | None = None,
) -> dict[str, Any]:
    expected_paths = [path for _, path in targets]
    if len(set(expected_paths)) != len(expected_paths) or len(
        {catalog_id for catalog_id, _ in targets}
    ) != len(targets):
        raise InvalidSourceArchive("expected target mapping contains duplicates")
    if any(not safe_member_name(path) for path in expected_paths):
        raise InvalidSourceArchive("expected target mapping contains an unsafe archive path")

    if archive_path.stat().st_size > MAX_TOTAL_BYTES + 1024 * 1024:
        raise InvalidSourceArchive("compressed archive exceeds the bounded size")

    expected_members = {"run-metadata.json", *expected_paths}
    try:
        with zipfile.ZipFile(archive_path) as archive:
            infos = archive.infolist()
            names = [info.filename for info in infos]
            if len(names) != len(set(names)):
                raise InvalidSourceArchive("archive contains duplicate member names")
            if set(names) != expected_members or len(names) != len(expected_members):
                raise InvalidSourceArchive("archive members do not match the closed contract")

            for info in infos:
                if not safe_member_name(info.filename):
                    raise InvalidSourceArchive(f"unsafe archive member: {info.filename}")
                mode = info.external_attr >> 16
                if stat.S_ISLNK(mode) or info.is_dir():
                    raise InvalidSourceArchive(f"non-regular archive member: {info.filename}")
                if mode and stat.S_IFMT(mode) not in (0, stat.S_IFREG):
                    raise InvalidSourceArchive(f"non-regular archive member: {info.filename}")
                if info.flag_bits & 0x1:
                    raise InvalidSourceArchive("encrypted archive members are not accepted")

            by_name = {info.filename: info for info in infos}
            metadata_bytes = archive.read(by_name["run-metadata.json"])
            try:
                metadata = json.loads(
                    metadata_bytes.decode("utf-8"),
                    object_pairs_hook=reject_duplicate_json_keys,
                )
            except (UnicodeDecodeError, json.JSONDecodeError) as error:
                raise InvalidSourceArchive("run metadata is not valid UTF-8 JSON") from error

            required_metadata_keys = {
                "schema_version",
                "candidate_sha",
                "control_sha",
                "checked_out_head",
                "run_id",
                "run_attempt",
                "renderer",
                "candidate_manifest_sha256",
                "pdfs",
            }
            if not isinstance(metadata, dict) or set(metadata) != required_metadata_keys:
                raise InvalidSourceArchive("run metadata has an unexpected shape")
            if metadata["schema_version"] != 1:
                raise InvalidSourceArchive("unsupported source metadata schema")
            if metadata["candidate_sha"] != expected_identity["candidate_sha"]:
                raise InvalidSourceArchive("candidate SHA does not match the expected run")
            if metadata["control_sha"] != expected_identity["control_sha"]:
                raise InvalidSourceArchive("control SHA does not match the expected run")
            if metadata["checked_out_head"] != metadata["candidate_sha"]:
                raise InvalidSourceArchive("checked-out HEAD is not the candidate SHA")
            if metadata["run_id"] != str(expected_identity["run_id"]):
                raise InvalidSourceArchive("run ID does not match the expected run")
            if metadata["run_attempt"] != expected_identity["run_attempt"]:
                raise InvalidSourceArchive("run attempt does not match the expected run")
            if not metadata["run_id"].isdecimal() or metadata["run_attempt"] < 1:
                raise InvalidSourceArchive("run identity is malformed")
            if metadata["run_id"] == HISTORICAL_RUN_ID:
                raise InvalidSourceArchive("expired historical run cannot supply fresh PDFs")
            if not SHA40.fullmatch(metadata["candidate_sha"]):
                raise InvalidSourceArchive("candidate SHA is malformed")
            if not SHA40.fullmatch(metadata["control_sha"]):
                raise InvalidSourceArchive("control SHA is malformed")
            if not SHA64.fullmatch(metadata["candidate_manifest_sha256"]):
                raise InvalidSourceArchive("candidate manifest digest is malformed")
            if candidate_manifest is not None:
                manifest_bytes = candidate_manifest.read_bytes()
                if hashlib.sha256(manifest_bytes).hexdigest() != metadata[
                    "candidate_manifest_sha256"
                ]:
                    raise InvalidSourceArchive("candidate manifest digest disagrees")
                manifest = json.loads(
                    manifest_bytes.decode("utf-8"),
                    object_pairs_hook=reject_duplicate_json_keys,
                )
                validate_candidate_manifest(manifest, metadata, targets)

            renderer = metadata["renderer"]
            if (
                not isinstance(renderer, dict)
                or set(renderer) != {"version", "executable_sha256"}
                or not isinstance(renderer["version"], str)
                or not renderer["version"]
                or not SHA64.fullmatch(str(renderer["executable_sha256"]))
            ):
                raise InvalidSourceArchive("renderer identity is malformed")

            rows = metadata["pdfs"]
            if not isinstance(rows, list) or len(rows) != len(targets):
                raise InvalidSourceArchive("metadata does not enumerate every expected PDF")
            if [row.get("path") if isinstance(row, dict) else None for row in rows] != expected_paths:
                raise InvalidSourceArchive("PDF metadata is not in canonical target order")
            if [row.get("id") if isinstance(row, dict) else None for row in rows] != [
                catalog_id for catalog_id, _ in targets
            ]:
                raise InvalidSourceArchive("PDF metadata IDs are not in canonical target order")

            total_size = 0
            verified = []
            for row, (_, path) in zip(rows, targets, strict=True):
                if not isinstance(row, dict) or set(row) != {"id", "path", "sha256", "size"}:
                    raise InvalidSourceArchive("PDF metadata row has an unexpected shape")
                info = by_name[path]
                if info.file_size <= 0 or info.file_size > MAX_PDF_BYTES:
                    raise InvalidSourceArchive(f"PDF size is out of bounds: {path}")
                data = archive.read(info)
                if not data.startswith(b"%PDF-"):
                    raise InvalidSourceArchive(f"PDF magic is missing: {path}")
                digest = hashlib.sha256(data).hexdigest()
                if digest != row["sha256"] or len(data) != row["size"]:
                    raise InvalidSourceArchive(f"PDF metadata digest or size disagrees: {path}")
                if not SHA64.fullmatch(digest):
                    raise InvalidSourceArchive(f"PDF digest is malformed: {path}")
                total_size += len(data)
                verified.append({"id": row["id"], "path": path, "sha256": digest, "size": len(data)})

            if total_size > MAX_TOTAL_BYTES:
                raise InvalidSourceArchive("PDF archive total exceeds the bounded size")

            return {"status": "valid", "metadata": metadata, "pdfs": verified}
    except zipfile.BadZipFile as error:
        raise InvalidSourceArchive("source artifact is not a valid ZIP archive") from error


def validate_candidate_manifest(
    manifest: dict[str, Any], metadata: dict[str, Any], targets: tuple[tuple[str, str], ...]
) -> None:
    candidate = manifest.get("candidate", {})
    if (
        candidate.get("commit_sha") != metadata["candidate_sha"]
        or candidate.get("baseline_commit_sha") != metadata["control_sha"]
        or candidate.get("run_id") != metadata["run_id"]
        or candidate.get("run_attempt") != metadata["run_attempt"]
        or candidate.get("renderer", {}).get("version") != metadata["renderer"]["version"]
        or candidate.get("renderer", {}).get("sha256")
        != metadata["renderer"]["executable_sha256"]
    ):
        raise InvalidSourceArchive("candidate manifest identity disagrees with run metadata")
    cells = manifest.get("cells")
    if not isinstance(cells, list) or len(cells) != 32:
        raise InvalidSourceArchive("candidate manifest does not contain exactly 32 cells")
    diff = manifest.get("diff", {})
    ids = [catalog_id for catalog_id, _ in targets]
    all_ids = [cell.get("id") for cell in cells if isinstance(cell, dict)]
    changed = diff.get("changed_scored", []) + diff.get("changed_unscored", [])
    stable = diff.get("byte_stable", [])
    if (
        diff.get("changed_targets") != ids
        or sorted(changed) != sorted(ids)
        or len(stable) != 26
        or len(set(stable)) != 26
        or sorted(stable + ids) != sorted(all_ids)
        or len(set(all_ids)) != 32
    ):
        raise InvalidSourceArchive("candidate manifest target/control partition disagrees")
    target_cells = [cell for cell in cells if cell.get("id") in ids]
    expected_paths = {catalog_id: path.removesuffix(".pdf") + ".png" for catalog_id, path in targets}
    if [cell.get("id") for cell in target_cells] != ids:
        raise InvalidSourceArchive("candidate manifest target order disagrees")
    for cell in target_cells:
        if cell.get("png_path") != expected_paths[cell["id"]]:
            raise InvalidSourceArchive(f"candidate manifest path disagrees: {cell['id']}")
        if not SHA64.fullmatch(str(cell.get("source_pdf_sha256", ""))):
            raise InvalidSourceArchive(f"candidate manifest PDF digest is malformed: {cell['id']}")


def validate_decision(path: Path) -> dict[str, Any]:
    decision = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=reject_duplicate_json_keys)
    required = {
        "choice",
        "chosen_by",
        "workflow_commit",
        "default_branch",
        "candidate_sha",
        "validation_results",
        "max_review_dispatches",
    }
    if not isinstance(decision, dict) or set(decision) != required:
        raise InvalidSourceArchive("decision record has an unexpected shape")
    if decision["choice"] not in ("authorize", "defer") or not decision["chosen_by"]:
        raise InvalidSourceArchive("decision does not record an owner's choice")
    if not SHA40.fullmatch(str(decision["workflow_commit"])):
        raise InvalidSourceArchive("decision is not bound to a full workflow commit")
    if decision["default_branch"] != "main" or decision["candidate_sha"] != CANDIDATE_SHA:
        raise InvalidSourceArchive("decision is not bound to the exact branch and candidate")
    if decision["max_review_dispatches"] != 1 or not isinstance(
        decision["validation_results"], dict
    ):
        raise InvalidSourceArchive("decision dispatch limit or validation evidence is invalid")
    return decision


def validate_outcome(path: Path) -> dict[str, Any]:
    receipt = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=reject_duplicate_json_keys)
    if not isinstance(receipt, dict) or receipt.get("candidate_sha") != CANDIDATE_SHA:
        raise InvalidSourceArchive("source receipt is absent or bound to another candidate")
    if receipt.get("run_id") in (None, HISTORICAL_RUN_ID) or receipt.get("run_attempt", 0) < 1:
        raise InvalidSourceArchive("source receipt does not name one new run attempt")
    rows = receipt.get("cells")
    if not isinstance(rows, list) or [row.get("id") for row in rows] != [
        catalog_id for catalog_id, _ in TARGETS
    ]:
        raise InvalidSourceArchive("source receipt does not contain the six ordered targets")
    equal = []
    for row in rows:
        pdfs_match = (
            row.get("fresh_pdf_sha256") == row.get("historical_pdf_sha256")
            and row.get("fresh_pdf_sha256") == row.get("packet_source_pdf_sha256")
        )
        pngs_match = row.get("fresh_packet_png_sha256") == row.get("restored_packet_png_sha256")
        equal.append(pdfs_match and pngs_match)
    expected_status = "complete" if all(equal) else "halted"
    if receipt.get("status") != expected_status:
        raise InvalidSourceArchive("source receipt status contradicts per-cell hash results")
    return receipt


def self_test() -> dict[str, Any]:
    sample_targets = (("sample--target", "sample/target.pdf"),)
    identity = {"candidate_sha": CANDIDATE_SHA, "control_sha": "e" * 40, "run_id": "987654321", "run_attempt": 2}
    pdf = b"%PDF-1.7\nsynthetic source pdf\n"
    metadata = {
        "schema_version": 1,
        **identity,
        "checked_out_head": identity["candidate_sha"],
        "renderer": {"version": "v0.11.0", "executable_sha256": "a" * 64},
        "candidate_manifest_sha256": "b" * 64,
        "pdfs": [{"id": sample_targets[0][0], "path": sample_targets[0][1], "sha256": hashlib.sha256(pdf).hexdigest(), "size": len(pdf)}],
    }

    def build_archive(path: Path, *, members: list[tuple[str, bytes]] | None = None, metadata_override: dict[str, Any] | None = None) -> None:
        payload = json.dumps(metadata_override or metadata, separators=(",", ":")).encode()
        file_members = members if members is not None else [(sample_targets[0][1], pdf)]
        with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            archive.writestr("run-metadata.json", payload)
            for name, data in file_members:
                archive.writestr(name, data)

    with tempfile.TemporaryDirectory(prefix="rendro-source-self-test-") as directory:
        root = Path(directory)
        valid = root / "valid.zip"
        build_archive(valid)
        result = validate_archive(valid, expected_identity=identity, targets=sample_targets)
        if result["status"] != "valid" or len(result["pdfs"]) != 1:
            raise InvalidSourceArchive("one-PDF self-test fixture did not validate end to end")

        extra = root / "extra.zip"
        build_archive(extra, members=[(sample_targets[0][1], pdf), ("extra.txt", b"extra")])
        expect_rejected(extra, identity, sample_targets, "extra archive member")

        missing = root / "missing.zip"
        build_archive(missing, members=[])
        expect_rejected(missing, identity, sample_targets, "missing PDF member")

        unsafe = root / "unsafe.zip"
        build_archive(unsafe, members=[("../target.pdf", pdf)])
        expect_rejected(unsafe, identity, sample_targets, "unsafe archive path")

        mismatch = root / "identity.zip"
        bad_identity = {**metadata, "run_id": "987654322"}
        build_archive(mismatch, metadata_override=bad_identity)
        expect_rejected(mismatch, identity, sample_targets, "run identity mismatch")

        bad_hash = root / "hash.zip"
        bad_metadata = {**metadata, "pdfs": [{**metadata["pdfs"][0], "sha256": "c" * 64}]}
        build_archive(bad_hash, metadata_override=bad_metadata)
        expect_rejected(bad_hash, identity, sample_targets, "PDF digest mismatch")

        oversized = root / "oversized.zip"
        oversized_pdf = b"%PDF-" + b"x" * MAX_PDF_BYTES
        oversized_metadata = {
            **metadata,
            "pdfs": [
                {
                    "id": sample_targets[0][0],
                    "path": sample_targets[0][1],
                    "sha256": hashlib.sha256(oversized_pdf).hexdigest(),
                    "size": len(oversized_pdf),
                }
            ],
        }
        build_archive(
            oversized,
            members=[(sample_targets[0][1], oversized_pdf)],
            metadata_override=oversized_metadata,
        )
        expect_rejected(oversized, identity, sample_targets, "oversized PDF member")

        symlink = root / "symlink.zip"
        with zipfile.ZipFile(symlink, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            archive.writestr("run-metadata.json", json.dumps(metadata))
            link = zipfile.ZipInfo(sample_targets[0][1])
            link.external_attr = (stat.S_IFLNK | 0o777) << 16
            archive.writestr(link, "target")
        expect_rejected(symlink, identity, sample_targets, "symlink archive member")

        if any(safe_member_name(name) for name in ("../target.pdf", "/target.pdf", "a\\target.pdf")):
            raise InvalidSourceArchive("self-test did not reject unsafe member path forms")

    return {"status": "passed", "checks": 9}


def expect_rejected(
    archive: Path,
    identity: dict[str, Any],
    targets: tuple[tuple[str, str], ...],
    label: str,
) -> None:
    try:
        validate_archive(archive, expected_identity=identity, targets=targets)
    except (InvalidSourceArchive, KeyError, TypeError):
        return
    raise InvalidSourceArchive(f"self-test did not reject {label}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--stage", choices=("archive", "decision", "outcome"), default="archive")
    parser.add_argument("--archive", type=Path)
    parser.add_argument("--candidate-sha", default=CANDIDATE_SHA)
    parser.add_argument("--control-sha", default=None)
    parser.add_argument("--run-id", default=None)
    parser.add_argument("--run-attempt", type=int, default=None)
    parser.add_argument("--candidate-manifest", type=Path)
    args = parser.parse_args()

    try:
        if args.self_test:
            result = self_test()
        elif args.stage == "decision":
            result = validate_decision(PHASE_DIR / "136-58-DECISION.json")
        elif args.stage == "outcome":
            result = validate_outcome(PHASE_DIR / "136-58-SOURCE-RECEIPT.json")
        else:
            if (
                args.archive is None
                or args.control_sha is None
                or args.run_id is None
                or args.run_attempt is None
                or args.candidate_manifest is None
            ):
                parser.error(
                    "archive stage needs --archive, --control-sha, --run-id, --run-attempt, and --candidate-manifest"
                )
            if args.candidate_sha != CANDIDATE_SHA or not SHA40.fullmatch(args.control_sha):
                raise InvalidSourceArchive("archive expectation does not use valid exact SHAs")
            if args.run_attempt < 1 or not args.run_id.isdecimal():
                raise InvalidSourceArchive("archive expectation has an invalid run identity")
            result = validate_archive(
                args.archive,
                expected_identity={
                    "candidate_sha": args.candidate_sha,
                    "control_sha": args.control_sha,
                    "run_id": args.run_id,
                    "run_attempt": args.run_attempt,
                },
                candidate_manifest=args.candidate_manifest,
            )
        print(json.dumps(result, sort_keys=True))
        return 0
    except (InvalidSourceArchive, OSError, KeyError, TypeError, ValueError) as error:
        parser.exit(1, f"source verifier: {error}\n")


if __name__ == "__main__":
    raise SystemExit(main())
