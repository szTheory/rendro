---
quick_id: 260612-iqj
slug: automate-hexdocs-publish-and-public-url-
status: complete
created: 2026-06-12T17:29:26Z
---

# Quick Task: Automate HexDocs Publish And Public URL Verification

## Objective

Automate the launch public-proof path so pushes to `main` publish HexDocs with `HEX_API_KEY` and verify the live GitHub/HexDocs URLs without local Hex auth.

## Tasks

1. Add a main-branch HexDocs workflow that verifies docs readiness on PR/push and publishes docs-only on `main` pushes.
2. Add a public launch URL verification script with retry support for HexDocs propagation.
3. Add docs-contract tests so the workflow remains docs-only, secret-backed, no-approval, and wired to public URL verification.
4. Verify locally and commit the quick-task result.
